import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { PollService } from "../src/services/polls/PollService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-poll-${Date.now()}`;
const SOC_B = `test-poll-b-${Date.now()}`;

afterAll(async () => {
  for (const s of [SOC, SOC_B]) {
    // votes/options/eligibility cascade from polls.
    await db.query(`DELETE FROM polls WHERE society_id = $1`, [s]);
  }
  await dbManager.close();
});

async function makeOpenPoll(soc: string, overrides: any = {}) {
  const poll = await PollService.createPoll(
    soc,
    {
      title: "Repaint the lobby?",
      options: [{ label: "Yes" }, { label: "No" }],
      resultsVisibility: "always",
      ...overrides,
    },
    "u-admin"
  );
  const opened = await PollService.open(soc, poll.id);
  const detail = await PollService.getPoll(soc, poll.id);
  return { poll: opened, options: detail!.options };
}

describe("PollService (integration)", () => {
  it("creates a draft and opens it (requires >= 2 options)", async () => {
    const poll = await PollService.createPoll(
      SOC,
      { title: "Single option", options: [{ label: "Only" }] as any },
      "u-admin"
    );
    expect(poll.status).toBe("draft");
    // Opening with < 2 options is rejected.
    await expect(PollService.open(SOC, poll.id)).rejects.toMatchObject({ code: "INVALID_STATE" });

    const ok = await makeOpenPoll(SOC);
    expect(ok.poll.status).toBe("open");
    expect(ok.poll.starts_at).toBeTruthy();
  });

  it("casts a vote once, then rejects a second vote by the same voter (atomic)", async () => {
    const { poll, options } = await makeOpenPoll(SOC);
    const v = await PollService.castVote(SOC, poll.id, { optionId: options[0].id, voterId: "u-1" });
    expect(v.option_id).toBe(options[0].id);

    await expect(
      PollService.castVote(SOC, poll.id, { optionId: options[1].id, voterId: "u-1" })
    ).rejects.toMatchObject({ code: "ALREADY_VOTED" });
  });

  it("lets exactly one of two concurrent votes by the same voter win", async () => {
    const { poll, options } = await makeOpenPoll(SOC);

    const results = await Promise.allSettled([
      PollService.castVote(SOC, poll.id, { optionId: options[0].id, voterId: "u-concurrent" }),
      PollService.castVote(SOC, poll.id, { optionId: options[1].id, voterId: "u-concurrent" }),
    ]);
    const fulfilled = results.filter((r) => r.status === "fulfilled");
    const rejected = results.filter((r) => r.status === "rejected");
    expect(fulfilled.length).toBe(1);
    expect(rejected.length).toBe(1);

    const { rows } = await db.query(
      `SELECT count(*)::int n FROM votes WHERE poll_id = $1 AND society_id = $2`,
      [poll.id, SOC]
    );
    expect(rows[0].n).toBe(1);
  });

  it("scopes one vote per unit when vote_scope='unit'", async () => {
    const { poll, options } = await makeOpenPoll(SOC, { voteScope: "unit" });
    await PollService.castVote(SOC, poll.id, { optionId: options[0].id, voterId: "u-a", unitId: "A-101" });
    // Different voter, same unit -> rejected.
    await expect(
      PollService.castVote(SOC, poll.id, { optionId: options[1].id, voterId: "u-b", unitId: "A-101" })
    ).rejects.toMatchObject({ code: "ALREADY_VOTED" });
    // Different unit is fine.
    const ok = await PollService.castVote(SOC, poll.id, { optionId: options[0].id, voterId: "u-c", unitId: "A-102" });
    expect(ok.option_id).toBe(options[0].id);
  });

  it("anonymous poll results never include voter ids", async () => {
    const { poll, options } = await makeOpenPoll(SOC, { isAnonymous: true });
    await PollService.castVote(SOC, poll.id, { optionId: options[0].id, voterId: "secret-voter" });

    const results: any = await PollService.results(SOC, poll.id, true);
    expect(results.talliesVisible).toBe(true);
    expect(results.isAnonymous).toBe(true);
    const serialized = JSON.stringify(results);
    expect(serialized).not.toContain("secret-voter");
    expect(results.options.every((o: any) => !("voterId" in o) && !("voter_id" in o))).toBe(true);
  });

  it("hides tallies for after_close visibility while open (non-admin)", async () => {
    const { poll } = await makeOpenPoll(SOC, { resultsVisibility: "after_close" });
    const asUser: any = await PollService.results(SOC, poll.id, false);
    expect(asUser.talliesVisible).toBe(false);
    const asAdmin: any = await PollService.results(SOC, poll.id, true);
    expect(asAdmin.talliesVisible).toBe(true);
  });

  it("does not leak polls or votes across tenants", async () => {
    const { poll } = await makeOpenPoll(SOC);
    const fromB = await PollService.getPoll(SOC_B, poll.id);
    expect(fromB).toBeNull();
    const listB = await PollService.listPolls(SOC_B, {});
    expect(listB.find((p: any) => p.id === poll.id)).toBeUndefined();
  });
});
