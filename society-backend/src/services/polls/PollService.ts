import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";

/**
 * Polls & voting. Tenant-scoped by society_id; times are UTC timestamps.
 *
 * Lifecycle: draft -> open -> closed.
 * Vote integrity: each cast vote carries a `vote_key` (unit_id when the poll's
 * vote_scope='unit', else voter_id). A UNIQUE(poll_id, vote_key) constraint makes
 * "one eligible vote per user OR per unit" atomic — a duplicate raises pg 23505
 * which we surface as ALREADY_VOTED.
 */
export const PollService = {
  /** Create a draft poll with its options and eligibility snapshot. */
  async createPoll(
    societyId: string,
    input: {
      title: string;
      description?: string;
      isAnonymous?: boolean;
      voteScope?: "user" | "unit";
      resultsVisibility?: "always" | "after_close" | "admins_only";
      startsAt?: string;
      endsAt?: string;
      options: { label: string; position?: number }[];
      eligibility?: { audienceType: "all" | "role" | "wing" | "block" | "unit"; audienceValue?: string }[];
    },
    createdBy?: string
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `INSERT INTO polls
           (society_id, title, description, is_anonymous, vote_scope, results_visibility, starts_at, ends_at, created_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         RETURNING *`,
        [
          societyId,
          input.title,
          input.description || null,
          input.isAnonymous ?? false,
          input.voteScope || "user",
          input.resultsVisibility || "after_close",
          input.startsAt || null,
          input.endsAt || null,
          createdBy || null,
        ]
      );
      const poll = rows[0];

      let pos = 0;
      for (const opt of input.options) {
        await client.query(
          `INSERT INTO poll_options (society_id, poll_id, label, position) VALUES ($1, $2, $3, $4)`,
          [societyId, poll.id, opt.label, opt.position ?? pos]
        );
        pos += 1;
      }

      const elig = input.eligibility && input.eligibility.length ? input.eligibility : [{ audienceType: "all" as const }];
      for (const e of elig) {
        await client.query(
          `INSERT INTO poll_eligibility (society_id, poll_id, audience_type, audience_value) VALUES ($1, $2, $3, $4)`,
          [societyId, poll.id, e.audienceType, e.audienceValue || null]
        );
      }

      logger.info({ societyId, pollId: poll.id }, "Poll created (draft)");
      return poll;
    });
  },

  /** draft -> open. Requires >= 2 options. Sets starts_at if not already set. */
  async open(societyId: string, pollId: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM polls WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [pollId, societyId]
      );
      const poll = rows[0];
      if (!poll) throw Object.assign(new Error("Poll not found"), { code: "NOT_FOUND" });
      if (poll.status !== "draft") {
        throw Object.assign(new Error(`Poll already ${poll.status}`), { code: "INVALID_STATE" });
      }
      const { rows: optRows } = await client.query(
        `SELECT count(*)::int n FROM poll_options WHERE poll_id = $1 AND society_id = $2`,
        [pollId, societyId]
      );
      if (optRows[0].n < 2) {
        throw Object.assign(new Error("A poll needs at least 2 options to open"), { code: "INVALID_STATE" });
      }
      const upd = await client.query(
        `UPDATE polls
            SET status = 'open',
                starts_at = COALESCE(starts_at, now()),
                version = version + 1,
                updated_at = now()
          WHERE id = $1 AND society_id = $2
        RETURNING *`,
        [pollId, societyId]
      );
      logger.info({ societyId, pollId }, "Poll opened");
      return upd.rows[0];
    });
  },

  /** open -> closed. Sets ends_at. */
  async close(societyId: string, pollId: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM polls WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [pollId, societyId]
      );
      const poll = rows[0];
      if (!poll) throw Object.assign(new Error("Poll not found"), { code: "NOT_FOUND" });
      if (poll.status !== "open") {
        throw Object.assign(new Error(`Poll is ${poll.status}, cannot close`), { code: "INVALID_STATE" });
      }
      const upd = await client.query(
        `UPDATE polls
            SET status = 'closed', ends_at = now(), version = version + 1, updated_at = now()
          WHERE id = $1 AND society_id = $2
        RETURNING *`,
        [pollId, societyId]
      );
      logger.info({ societyId, pollId }, "Poll closed");
      return upd.rows[0];
    });
  },

  /**
   * Cast a vote. Atomic: verifies the poll is open & within its window, computes
   * the vote_key per scope, and relies on UNIQUE(poll_id, vote_key) for integrity.
   * A unique violation (pg 23505) becomes ALREADY_VOTED.
   */
  async castVote(
    societyId: string,
    pollId: string,
    input: { optionId: string; voterId: string; unitId?: string }
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM polls WHERE id = $1 AND society_id = $2 FOR SHARE`,
        [pollId, societyId]
      );
      const poll = rows[0];
      if (!poll) throw Object.assign(new Error("Poll not found"), { code: "NOT_FOUND" });
      if (poll.status !== "open") {
        throw Object.assign(new Error("Poll is not open for voting"), { code: "INVALID_STATE" });
      }
      const now = Date.now();
      if (poll.starts_at && new Date(poll.starts_at).getTime() > now) {
        throw Object.assign(new Error("Voting has not started yet"), { code: "INVALID_STATE" });
      }
      if (poll.ends_at && new Date(poll.ends_at).getTime() < now) {
        throw Object.assign(new Error("Voting has ended"), { code: "INVALID_STATE" });
      }

      // Option must belong to this poll/tenant.
      const { rows: optRows } = await client.query(
        `SELECT id FROM poll_options WHERE id = $1 AND poll_id = $2 AND society_id = $3`,
        [input.optionId, pollId, societyId]
      );
      if (!optRows[0]) {
        throw Object.assign(new Error("Option does not belong to this poll"), { code: "NOT_FOUND" });
      }

      // Compute vote_key per scope. Unit scope requires a unit id.
      if (poll.vote_scope === "unit" && !input.unitId) {
        throw Object.assign(new Error("A unit is required to vote on this poll"), { code: "NOT_ELIGIBLE" });
      }
      const voteKey = poll.vote_scope === "unit" ? String(input.unitId) : String(input.voterId);

      try {
        const ins = await client.query(
          `INSERT INTO votes (society_id, poll_id, option_id, voter_id, unit_id, vote_key)
           VALUES ($1, $2, $3, $4, $5, $6)
           RETURNING id, poll_id, option_id, created_at`,
          [societyId, pollId, input.optionId, input.voterId, input.unitId || null, voteKey]
        );
        logger.info({ societyId, pollId, scope: poll.vote_scope }, "Vote cast");
        return ins.rows[0];
      } catch (err: any) {
        if (err && err.code === "23505") {
          throw Object.assign(new Error("Already voted"), { code: "ALREADY_VOTED" });
        }
        throw err;
      }
    });
  },

  /**
   * Tallies per option. Respects results_visibility:
   *   - admins_only: only admins ever see tallies.
   *   - after_close: tallies hidden while the poll is still open (unless admin).
   *   - always: visible to everyone.
   * Individual votes / voter ids are never returned (especially for anonymous polls).
   */
  async results(societyId: string, pollId: string, requesterIsAdmin: boolean) {
    const { rows } = await db.query(
      `SELECT * FROM polls WHERE id = $1 AND society_id = $2`,
      [pollId, societyId]
    );
    const poll = rows[0];
    if (!poll) throw Object.assign(new Error("Poll not found"), { code: "NOT_FOUND" });

    const visible = (() => {
      if (requesterIsAdmin) return true;
      switch (poll.results_visibility) {
        case "always":
          return true;
        case "after_close":
          return poll.status === "closed";
        case "admins_only":
        default:
          return false;
      }
    })();

    const { rows: optRows } = await db.query(
      `SELECT o.id, o.label, o.position,
              (SELECT count(*)::int FROM votes v WHERE v.option_id = o.id AND v.society_id = $2) AS count
         FROM poll_options o
        WHERE o.poll_id = $1 AND o.society_id = $2
        ORDER BY o.position ASC`,
      [pollId, societyId]
    );

    if (!visible) {
      // Hide tallies but still list the options.
      return {
        pollId: poll.id,
        status: poll.status,
        isAnonymous: poll.is_anonymous,
        resultsVisibility: poll.results_visibility,
        talliesVisible: false,
        options: optRows.map((o: any) => ({ id: o.id, label: o.label, position: o.position })),
      };
    }

    const totalVotes = optRows.reduce((s: number, o: any) => s + Number(o.count), 0);
    return {
      pollId: poll.id,
      status: poll.status,
      isAnonymous: poll.is_anonymous,
      resultsVisibility: poll.results_visibility,
      talliesVisible: true,
      totalVotes,
      // Never expose individual voter ids.
      options: optRows.map((o: any) => ({ id: o.id, label: o.label, position: o.position, count: Number(o.count) })),
    };
  },

  async listPolls(societyId: string, opts: { status?: string; limit?: number } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) {
      params.push(opts.status);
      where += ` AND status = $${params.length}`;
    }
    params.push(Math.min(opts.limit || 50, 200));
    const { rows } = await db.query(
      `SELECT * FROM polls WHERE ${where} ORDER BY created_at DESC LIMIT $${params.length}`,
      params
    );
    return rows;
  },

  /** Poll detail with options and whether the requester (user/unit) has voted. */
  async getPoll(
    societyId: string,
    pollId: string,
    requester?: { voterId?: string; unitId?: string }
  ) {
    const { rows } = await db.query(
      `SELECT * FROM polls WHERE id = $1 AND society_id = $2`,
      [pollId, societyId]
    );
    const poll = rows[0];
    if (!poll) return null;

    const { rows: options } = await db.query(
      `SELECT id, label, position FROM poll_options WHERE poll_id = $1 AND society_id = $2 ORDER BY position ASC`,
      [pollId, societyId]
    );
    const { rows: eligibility } = await db.query(
      `SELECT audience_type, audience_value FROM poll_eligibility WHERE poll_id = $1 AND society_id = $2`,
      [pollId, societyId]
    );

    let hasVoted = false;
    if (requester && (requester.voterId || requester.unitId)) {
      const voteKey = poll.vote_scope === "unit" ? requester.unitId : requester.voterId;
      if (voteKey) {
        const { rows: vRows } = await db.query(
          `SELECT 1 FROM votes WHERE poll_id = $1 AND society_id = $2 AND vote_key = $3 LIMIT 1`,
          [pollId, societyId, String(voteKey)]
        );
        hasVoted = vRows.length > 0;
      }
    }

    return { poll, options, eligibility, hasVoted };
  },
};
