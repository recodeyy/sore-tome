import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";

/**
 * Staff, attendance, roster, leave, payroll (Phase 5, capabilities 70–79).
 *
 * Integrity guarantees enforced here + at the DB:
 *  - One attendance row per (staff, day): UNIQUE prevents duplicate check-ins.
 *  - Check-out computes worked_minutes; overnight shifts handled by date math.
 *  - Leave approval decrements balance under a row lock (no balance race).
 *  - Payroll run is unique per (society, period): re-run protection.
 *  - Payroll approval is maker-checker: approver must differ from creator.
 * Money is in integer minor units. Tenant-scoped by society_id throughout.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

export const StaffService = {
  // ---- Staff profiles ---------------------------------------------------
  async createStaff(
    societyId: string,
    input: {
      name: string; role?: string; department?: string; isContractor?: boolean;
      phone?: string; userId?: string; joiningDate?: string; assignedAreas?: string[];
      monthlyWageMinor?: number; kycExpiresAt?: string;
    }
  ) {
    const { rows } = await db.query(
      `INSERT INTO staff (society_id, name, role, department, is_contractor, phone, user_id,
                          joining_date, assigned_areas, monthly_wage_minor, kyc_expires_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
      [societyId, input.name, input.role || null, input.department || null, input.isContractor || false,
       input.phone || null, input.userId || null, input.joiningDate || null,
       input.assignedAreas || [], input.monthlyWageMinor || 0, input.kycExpiresAt || null]
    );
    logger.info({ societyId, staffId: rows[0].id }, "Staff created");
    return rows[0];
  },

  async listStaff(societyId: string, opts: { status?: string; limit?: number } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) { params.push(opts.status); where += ` AND status = $${params.length}`; }
    params.push(Math.min(opts.limit || 100, 500));
    const { rows } = await db.query(
      `SELECT * FROM staff WHERE ${where} ORDER BY name ASC LIMIT $${params.length}`, params
    );
    return rows;
  },

  async setStatus(societyId: string, staffId: string, status: "active" | "suspended" | "terminated", leavingDate?: string) {
    const { rows } = await db.query(
      `UPDATE staff SET status = $3, leaving_date = COALESCE($4, leaving_date),
              version = version + 1, updated_at = now()
       WHERE id = $1 AND society_id = $2 RETURNING *`,
      [staffId, societyId, status, status === "terminated" ? (leavingDate || new Date().toISOString().slice(0, 10)) : null]
    );
    if (!rows[0]) throw err("Staff not found", "NOT_FOUND");
    return rows[0];
  },

  // ---- Attendance -------------------------------------------------------
  /** Check in for the day. Duplicate check-in is rejected by the unique row. */
  async checkIn(societyId: string, staffId: string, workDate: string, source = "manual") {
    const staff = await db.query(`SELECT status FROM staff WHERE id = $1 AND society_id = $2`, [staffId, societyId]);
    if (!staff.rows[0]) throw err("Staff not found", "NOT_FOUND");
    if (staff.rows[0].status === "terminated") throw err("Staff is terminated", "INVALID_STATE");
    try {
      const { rows } = await db.query(
        `INSERT INTO attendance_entries (society_id, staff_id, work_date, check_in_at, status, source)
         VALUES ($1,$2,$3, now(), 'present', $4) RETURNING *`,
        [societyId, staffId, workDate, source]
      );
      return rows[0];
    } catch (e: any) {
      if (e.code === "23505") throw err("Already checked in for this date", "ALREADY_CHECKED_IN");
      throw e;
    }
  },

  /** Check out; computes worked minutes (supports overnight via timestamp diff). */
  async checkOut(societyId: string, staffId: string, workDate: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM attendance_entries WHERE society_id = $1 AND staff_id = $2 AND work_date = $3 FOR UPDATE`,
        [societyId, staffId, workDate]
      );
      const att = rows[0];
      if (!att) throw err("No check-in found for this date", "NOT_FOUND");
      if (att.check_out_at) throw err("Already checked out", "INVALID_STATE");
      const upd = await client.query(
        `UPDATE attendance_entries
            SET check_out_at = now(),
                worked_minutes = GREATEST(0, EXTRACT(EPOCH FROM (now() - check_in_at)) / 60)::int,
                updated_at = now()
          WHERE id = $1 RETURNING *`,
        [att.id]
      );
      return upd.rows[0];
    });
  },

  /** Admin manual correction with an audit (before/after) + approval field. */
  async adjustAttendance(
    societyId: string,
    attendanceId: string,
    patch: { status?: string; checkInAt?: string; checkOutAt?: string; workedMinutes?: number },
    reason: string,
    adjustedBy: string
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM attendance_entries WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [attendanceId, societyId]
      );
      const before = rows[0];
      if (!before) throw err("Attendance not found", "NOT_FOUND");
      const upd = await client.query(
        `UPDATE attendance_entries
            SET status = COALESCE($3, status),
                check_in_at = COALESCE($4, check_in_at),
                check_out_at = COALESCE($5, check_out_at),
                worked_minutes = COALESCE($6, worked_minutes),
                updated_at = now()
          WHERE id = $1 AND society_id = $2 RETURNING *`,
        [attendanceId, societyId, patch.status || null, patch.checkInAt || null, patch.checkOutAt || null,
         patch.workedMinutes ?? null]
      );
      await client.query(
        `INSERT INTO attendance_adjustments (society_id, attendance_id, reason, before, after, adjusted_by)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [societyId, attendanceId, reason, JSON.stringify(before), JSON.stringify(upd.rows[0]), adjustedBy]
      );
      return upd.rows[0];
    });
  },

  // ---- Roster -----------------------------------------------------------
  async assignRoster(societyId: string, input: { staffId: string; dutyDate: string; shiftTemplateId?: string; area?: string }) {
    try {
      const { rows } = await db.query(
        `INSERT INTO duty_rosters (society_id, staff_id, duty_date, shift_template_id, area)
         VALUES ($1,$2,$3,$4,$5) RETURNING *`,
        [societyId, input.staffId, input.dutyDate, input.shiftTemplateId || null, input.area || null]
      );
      return rows[0];
    } catch (e: any) {
      if (e.code === "23505") throw err("Staff already rostered for this shift/day", "ROSTER_CONFLICT");
      if (e.code === "23503") throw err("Staff or shift not found", "NOT_FOUND");
      throw e;
    }
  },

  // ---- Leave ------------------------------------------------------------
  async ensureLeaveBalance(societyId: string, staffId: string, leaveTypeId: string, year: number) {
    const { rows } = await db.query(
      `INSERT INTO leave_balances (society_id, staff_id, leave_type_id, year, balance_days)
       SELECT $1,$2,$3,$4, COALESCE((SELECT annual_quota_days FROM leave_types WHERE id = $3), 0)
       ON CONFLICT (staff_id, leave_type_id, year) DO UPDATE SET balance_days = leave_balances.balance_days
       RETURNING *`,
      [societyId, staffId, leaveTypeId, year]
    );
    return rows[0];
  },

  async requestLeave(
    societyId: string,
    input: { staffId: string; leaveTypeId: string; fromDate: string; toDate: string; reason?: string }
  ) {
    const from = new Date(input.fromDate + "T00:00:00Z");
    const to = new Date(input.toDate + "T00:00:00Z");
    if (to < from) throw err("toDate before fromDate", "INVALID_INPUT");
    const days = Math.floor((to.getTime() - from.getTime()) / 86400000) + 1;
    const { rows } = await db.query(
      `INSERT INTO leave_requests (society_id, staff_id, leave_type_id, from_date, to_date, days, reason)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [societyId, input.staffId, input.leaveTypeId, input.fromDate, input.toDate, days, input.reason || null]
    );
    return rows[0];
  },

  /** Approve/reject. Approval decrements the balance under a lock (no race). */
  async decideLeave(
    societyId: string,
    leaveId: string,
    decision: "approved" | "rejected",
    decidedBy: string,
    comment?: string
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM leave_requests WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [leaveId, societyId]
      );
      const lr = rows[0];
      if (!lr) throw err("Leave request not found", "NOT_FOUND");
      if (lr.status !== "pending") throw err(`Leave already ${lr.status}`, "INVALID_STATE");

      if (decision === "approved") {
        const year = new Date(lr.from_date).getUTCFullYear();
        const bal = await client.query(
          `SELECT * FROM leave_balances WHERE staff_id = $1 AND leave_type_id = $2 AND year = $3 FOR UPDATE`,
          [lr.staff_id, lr.leave_type_id, year]
        );
        const available = bal.rows[0] ? Number(bal.rows[0].balance_days) : 0;
        if (available < Number(lr.days)) throw err("Insufficient leave balance", "INSUFFICIENT_BALANCE");
        await client.query(
          `UPDATE leave_balances SET balance_days = balance_days - $4
             WHERE staff_id = $1 AND leave_type_id = $2 AND year = $3`,
          [lr.staff_id, lr.leave_type_id, year, lr.days]
        );
      }

      const upd = await client.query(
        `UPDATE leave_requests SET status = $3, decided_by = $4, decision_comment = $5,
                version = version + 1, updated_at = now()
          WHERE id = $1 AND society_id = $2 RETURNING *`,
        [leaveId, societyId, decision, decidedBy, comment || null]
      );
      logger.info({ societyId, leaveId, decision, decidedBy }, "Leave decided");
      return upd.rows[0];
    });
  },

  // ---- Payroll ----------------------------------------------------------
  /**
   * Generate a draft payroll run for a period. Unique(society, period) makes a
   * second generation for the same period fail (re-run protection). Earnings are
   * pro-rated by present days in the period when attendance exists, else full wage.
   */
  async generatePayroll(societyId: string, period: string, createdBy?: string) {
    return withTx(async (client) => {
      let run;
      try {
        const ins = await client.query(
          `INSERT INTO payroll_runs (society_id, period, created_by) VALUES ($1,$2,$3) RETURNING *`,
          [societyId, period, createdBy || null]
        );
        run = ins.rows[0];
      } catch (e: any) {
        if (e.code === "23505") throw err(`Payroll for ${period} already exists`, "ALREADY_EXISTS");
        throw e;
      }

      const staff = await client.query(`SELECT * FROM staff WHERE society_id = $1 AND status = 'active'`, [societyId]);
      // Days in the period for proration.
      const [y, m] = period.split("-").map(Number);
      const daysInMonth = new Date(Date.UTC(y, m, 0)).getUTCDate();

      let gross = 0, deductions = 0, net = 0;
      for (const s of staff.rows) {
        const att = await client.query(
          `SELECT count(*) FILTER (WHERE status IN ('present','half_day'))::int AS present_days
             FROM attendance_entries
            WHERE society_id = $1 AND staff_id = $2 AND to_char(work_date, 'YYYY-MM') = $3`,
          [societyId, s.id, period]
        );
        const presentDays = att.rows[0].present_days as number;
        const wage = Number(s.monthly_wage_minor);
        // If no attendance recorded at all, assume full month; else prorate.
        const earnings = presentDays > 0 ? Math.round((wage * presentDays) / daysInMonth) : wage;
        const ded = 0;
        const itemNet = earnings - ded;
        await client.query(
          `INSERT INTO payroll_items (society_id, payroll_run_id, staff_id, earnings_minor, deductions_minor, net_minor, present_days)
           VALUES ($1,$2,$3,$4,$5,$6,$7)`,
          [societyId, run.id, s.id, earnings, ded, itemNet, presentDays]
        );
        gross += earnings; deductions += ded; net += itemNet;
      }

      const upd = await client.query(
        `UPDATE payroll_runs SET gross_minor = $2, deductions_minor = $3, net_minor = $4, updated_at = now()
           WHERE id = $1 RETURNING *`,
        [run.id, gross, deductions, net]
      );
      logger.info({ societyId, period, staff: staff.rows.length, net }, "Payroll generated (draft)");
      return upd.rows[0];
    });
  },

  /** Maker-checker approval: approver must differ from the run's creator. */
  async approvePayroll(societyId: string, runId: string, approverId: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM payroll_runs WHERE id = $1 AND society_id = $2 FOR UPDATE`, [runId, societyId]
      );
      const run = rows[0];
      if (!run) throw err("Payroll run not found", "NOT_FOUND");
      if (run.status !== "draft") throw err(`Payroll already ${run.status}`, "INVALID_STATE");
      if (run.created_by && run.created_by === approverId) {
        throw err("You cannot approve a payroll run you created", "MAKER_CHECKER");
      }
      const upd = await client.query(
        `UPDATE payroll_runs SET status = 'approved', approved_by = $3, updated_at = now()
           WHERE id = $1 AND society_id = $2 RETURNING *`,
        [runId, societyId, approverId]
      );
      logger.info({ societyId, runId, approverId }, "Payroll approved");
      return upd.rows[0];
    });
  },

  async getPayroll(societyId: string, runId: string) {
    const { rows } = await db.query(`SELECT * FROM payroll_runs WHERE id = $1 AND society_id = $2`, [runId, societyId]);
    if (!rows[0]) return null;
    const items = await db.query(`SELECT * FROM payroll_items WHERE payroll_run_id = $1 ORDER BY created_at ASC`, [runId]);
    return { run: rows[0], items: items.rows };
  },

  // ---- Incidents / leave types -----------------------------------------
  async createLeaveType(societyId: string, input: { name: string; annualQuotaDays?: number; isPaid?: boolean }) {
    const { rows } = await db.query(
      `INSERT INTO leave_types (society_id, name, annual_quota_days, is_paid) VALUES ($1,$2,$3,$4)
       ON CONFLICT (society_id, name) DO UPDATE SET annual_quota_days = EXCLUDED.annual_quota_days RETURNING *`,
      [societyId, input.name, input.annualQuotaDays || 0, input.isPaid ?? true]
    );
    return rows[0];
  },

  async createShiftTemplate(societyId: string, input: { name: string; startMinutes: number; endMinutes: number }) {
    const { rows } = await db.query(
      `INSERT INTO shift_templates (society_id, name, start_minutes, end_minutes) VALUES ($1,$2,$3,$4)
       ON CONFLICT (society_id, name) DO UPDATE SET start_minutes = EXCLUDED.start_minutes, end_minutes = EXCLUDED.end_minutes RETURNING *`,
      [societyId, input.name, input.startMinutes, input.endMinutes]
    );
    return rows[0];
  },

  async recordIncident(
    societyId: string,
    input: { staffId: string; type?: "incident" | "performance" | "disciplinary"; title: string; details?: string; isPrivate?: boolean },
    recordedBy?: string
  ) {
    const owns = await db.query(`SELECT id FROM staff WHERE id = $1 AND society_id = $2`, [input.staffId, societyId]);
    if (!owns.rows[0]) throw err("Staff not found", "NOT_FOUND");
    const { rows } = await db.query(
      `INSERT INTO staff_incidents (society_id, staff_id, type, title, details, is_private, recorded_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [societyId, input.staffId, input.type || "incident", input.title, input.details || null, input.isPrivate ?? true, recordedBy || null]
    );
    return rows[0];
  },
};
