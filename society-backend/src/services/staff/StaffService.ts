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

/**
 * Idempotent runtime schema patch. There is no migration-on-deploy for this
 * column, so we add it the first time create/list runs. The once-guard keeps it
 * to a single ALTER per process; `IF NOT EXISTS` makes repeat runs safe.
 */
let ensured = false;
async function ensureSchema() {
  if (ensured) return;
  await db.query(`ALTER TABLE staff ADD COLUMN IF NOT EXISTS image_url text`);
  ensured = true;
}

export const StaffService = {
  // ---- Staff profiles ---------------------------------------------------
  async createStaff(
    societyId: string,
    input: {
      name: string; role?: string; department?: string; isContractor?: boolean;
      phone?: string; userId?: string; joiningDate?: string; assignedAreas?: string[];
      monthlyWageMinor?: number; kycExpiresAt?: string; imageUrl?: string;
      permissions?: string[]; overtimeRateMinor?: number; standardShiftMinutes?: number; lateGraceMinutes?: number;
    }
  ) {
    await ensureSchema();
    const { rows } = await db.query(
      `INSERT INTO staff (society_id, name, role, department, is_contractor, phone, user_id,
                          joining_date, assigned_areas, monthly_wage_minor, kyc_expires_at,
                          permissions, overtime_rate_minor, standard_shift_minutes, late_grace_minutes,
                          image_url)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16) RETURNING *`,
      [societyId, input.name, input.role || null, input.department || null, input.isContractor || false,
       input.phone || null, input.userId || null, input.joiningDate || null,
       input.assignedAreas || [], input.monthlyWageMinor || 0, input.kycExpiresAt || null,
       input.permissions || [], input.overtimeRateMinor || 0,
       input.standardShiftMinutes ?? 480, input.lateGraceMinutes ?? 0,
       input.imageUrl || null]
    );
    logger.info({ societyId, staffId: rows[0].id }, "Staff created");
    return rows[0];
  },

  async listStaff(societyId: string, opts: { status?: string; limit?: number } = {}) {
    await ensureSchema();
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

  // ---- List/read helpers (admin governance screens) --------------------
  /** Leave requests for the society, newest first. Optional [status] filter
   *  ("pending" | "approved" | "rejected"). Joins staff + leave_type names so
   *  the admin list is human-readable without N+1 lookups. */
  async listLeaveRequests(societyId: string, status?: string) {
    const params: any[] = [societyId];
    let where = `lr.society_id = $1`;
    if (status) { params.push(status); where += ` AND lr.status = $${params.length}`; }
    const { rows } = await db.query(
      `SELECT lr.*, s.name AS staff_name, s.role AS staff_role, lt.name AS leave_type_name
         FROM leave_requests lr
         JOIN staff s ON s.id = lr.staff_id
         LEFT JOIN leave_types lt ON lt.id = lr.leave_type_id
        WHERE ${where}
        ORDER BY lr.created_at DESC
        LIMIT 200`,
      params
    );
    return rows;
  },

  /** Duty roster entries, optionally for a single [dutyDate] (YYYY-MM-DD).
   *  Defaults to today onward so the admin sees upcoming duties. */
  async listRoster(societyId: string, dutyDate?: string) {
    const params: any[] = [societyId];
    let where = `dr.society_id = $1`;
    if (dutyDate) {
      params.push(dutyDate);
      where += ` AND dr.duty_date = $${params.length}`;
    } else {
      where += ` AND dr.duty_date >= CURRENT_DATE`;
    }
    const { rows } = await db.query(
      `SELECT dr.*, s.name AS staff_name, s.role AS staff_role,
              st.name AS shift_name, st.start_minutes, st.end_minutes
         FROM duty_rosters dr
         JOIN staff s ON s.id = dr.staff_id
         LEFT JOIN shift_templates st ON st.id = dr.shift_template_id
        WHERE ${where}
        ORDER BY dr.duty_date ASC, s.name ASC
        LIMIT 300`,
      params
    );
    return rows;
  },

  /** Payroll runs for the society, newest period first. */
  async listPayrollRuns(societyId: string) {
    const { rows } = await db.query(
      `SELECT * FROM payroll_runs WHERE society_id = $1 ORDER BY period DESC LIMIT 60`,
      [societyId]
    );
    return rows;
  },

  /** Active leave types (for the leave-request form dropdown). */
  async listLeaveTypes(societyId: string) {
    const { rows } = await db.query(
      `SELECT * FROM leave_types WHERE society_id = $1 ORDER BY name ASC`,
      [societyId]
    );
    return rows;
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

  // ---- 71 Permissions / restricted app access --------------------------
  async setPermissions(societyId: string, staffId: string, permissions: string[]) {
    const { rows } = await db.query(
      `UPDATE staff SET permissions = $3, version = version + 1, updated_at = now()
        WHERE id = $1 AND society_id = $2 RETURNING *`,
      [staffId, societyId, permissions]
    );
    if (!rows[0]) throw err("Staff not found", "NOT_FOUND");
    return rows[0];
  },

  /** Returns true if the staff member holds the given permission key. */
  async hasPermission(societyId: string, staffId: string, permission: string): Promise<boolean> {
    const { rows } = await db.query(
      `SELECT 1 FROM staff WHERE id = $1 AND society_id = $2 AND $3 = ANY(permissions)`,
      [staffId, societyId, permission]
    );
    return rows.length > 0;
  },

  // ---- 76 Holidays + overtime / late-arrival calculations --------------
  async addHoliday(societyId: string, holidayDate: string, name: string) {
    const { rows } = await db.query(
      `INSERT INTO society_holidays (society_id, holiday_date, name) VALUES ($1,$2,$3)
       ON CONFLICT (society_id, holiday_date) DO UPDATE SET name = EXCLUDED.name RETURNING *`,
      [societyId, holidayDate, name]
    );
    return rows[0];
  },

  /**
   * Recompute overtime/late/holiday for a completed attendance row using the
   * staff baseline (standard shift, grace) and the holiday calendar, against an
   * optional shift start expressed in minutes-from-midnight.
   */
  async computeOvertimeAndLate(
    societyId: string,
    attendanceId: string,
    opts: { shiftStartMinutes?: number } = {}
  ) {
    return withTx(async (client) => {
      const a = await client.query(
        `SELECT * FROM attendance_entries WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [attendanceId, societyId]
      );
      const att = a.rows[0];
      if (!att) throw err("Attendance not found", "NOT_FOUND");
      if (!att.check_out_at) throw err("Attendance not checked out", "INVALID_STATE");
      const s = await client.query(
        `SELECT standard_shift_minutes, late_grace_minutes FROM staff WHERE id = $1 AND society_id = $2`,
        [att.staff_id, societyId]
      );
      const std = Number(s.rows[0]?.standard_shift_minutes ?? 480);
      const grace = Number(s.rows[0]?.late_grace_minutes ?? 0);

      const hol = await client.query(
        `SELECT 1 FROM society_holidays WHERE society_id = $1 AND holiday_date = $2`,
        [societyId, att.work_date]
      );
      const isHoliday = hol.rows.length > 0;

      const worked = Number(att.worked_minutes);
      const overtime = Math.max(0, worked - std);

      let late = 0;
      if (opts.shiftStartMinutes != null && att.check_in_at) {
        const ci = new Date(att.check_in_at);
        const minutesIntoDay = ci.getUTCHours() * 60 + ci.getUTCMinutes();
        late = Math.max(0, minutesIntoDay - opts.shiftStartMinutes - grace);
      }

      const upd = await client.query(
        `UPDATE attendance_entries
            SET overtime_minutes = $3, late_minutes = $4, is_holiday = $5, updated_at = now()
          WHERE id = $1 AND society_id = $2 RETURNING *`,
        [attendanceId, societyId, overtime, late, isHoliday]
      );
      return upd.rows[0];
    });
  },

  // ---- 77 KYC / contracts / training / certifications ------------------
  async addDocument(
    societyId: string,
    input: {
      staffId: string; docType: "kyc" | "contract" | "training" | "certification";
      title: string; reference?: string; fileUrl?: string; issuedOn?: string; expiresOn?: string;
    },
    createdBy?: string
  ) {
    const owns = await db.query(`SELECT id FROM staff WHERE id = $1 AND society_id = $2`, [input.staffId, societyId]);
    if (!owns.rows[0]) throw err("Staff not found", "NOT_FOUND");
    const { rows } = await db.query(
      `INSERT INTO staff_documents (society_id, staff_id, doc_type, title, reference, file_url, issued_on, expires_on, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
      [societyId, input.staffId, input.docType, input.title, input.reference || null,
       input.fileUrl || null, input.issuedOn || null, input.expiresOn || null, createdBy || null]
    );
    return rows[0];
  },

  async listDocuments(societyId: string, staffId: string) {
    const { rows } = await db.query(
      `SELECT * FROM staff_documents WHERE society_id = $1 AND staff_id = $2 ORDER BY created_at DESC`,
      [societyId, staffId]
    );
    return rows;
  },

  /** Documents (and staff KYC) expiring within `days` days, or already expired. */
  async expiringDocuments(societyId: string, withinDays = 30) {
    const { rows } = await db.query(
      `SELECT d.*, st.name AS staff_name,
              (d.expires_on < CURRENT_DATE) AS is_expired
         FROM staff_documents d
         JOIN staff st ON st.id = d.staff_id
        WHERE d.society_id = $1 AND d.status <> 'revoked'
          AND d.expires_on IS NOT NULL
          AND d.expires_on <= (CURRENT_DATE + ($2::int * INTERVAL '1 day'))
        ORDER BY d.expires_on ASC`,
      [societyId, withinDays]
    );
    return rows;
  },

  // ---- 79 Reports (aggregations) ---------------------------------------
  /** Attendance summary per staff for a YYYY-MM period. */
  async attendanceReport(societyId: string, period: string) {
    const { rows } = await db.query(
      `SELECT st.id AS staff_id, st.name,
              count(a.*) FILTER (WHERE a.status = 'present')::int AS present_days,
              count(a.*) FILTER (WHERE a.status = 'absent')::int AS absent_days,
              count(a.*) FILTER (WHERE a.status = 'half_day')::int AS half_days,
              count(a.*) FILTER (WHERE a.status = 'on_leave')::int AS leave_days,
              COALESCE(sum(a.worked_minutes),0)::int AS worked_minutes,
              COALESCE(sum(a.overtime_minutes),0)::int AS overtime_minutes,
              COALESCE(sum(a.late_minutes),0)::int AS late_minutes
         FROM staff st
         LEFT JOIN attendance_entries a
           ON a.staff_id = st.id AND a.society_id = st.society_id
          AND to_char(a.work_date, 'YYYY-MM') = $2
        WHERE st.society_id = $1
        GROUP BY st.id, st.name
        ORDER BY st.name ASC`,
      [societyId, period]
    );
    return rows;
  },

  /** Leave report: requests grouped by status for a year. */
  async leaveReport(societyId: string, year: number) {
    const { rows } = await db.query(
      `SELECT lr.status, count(*)::int AS requests, COALESCE(sum(lr.days),0)::numeric AS total_days
         FROM leave_requests lr
        WHERE lr.society_id = $1 AND EXTRACT(YEAR FROM lr.from_date) = $2
        GROUP BY lr.status ORDER BY lr.status`,
      [societyId, year]
    );
    return rows;
  },

  /** Payroll report: per-run totals. */
  async payrollReport(societyId: string) {
    const { rows } = await db.query(
      `SELECT period, status, gross_minor, deductions_minor, net_minor
         FROM payroll_runs WHERE society_id = $1 ORDER BY period DESC`,
      [societyId]
    );
    return rows;
  },

  /** Overtime report: total OT minutes/value per staff for a period. */
  async overtimeReport(societyId: string, period: string) {
    const { rows } = await db.query(
      `SELECT st.id AS staff_id, st.name,
              COALESCE(sum(a.overtime_minutes),0)::int AS overtime_minutes,
              (COALESCE(sum(a.overtime_minutes),0) * st.overtime_rate_minor / 60)::bigint AS overtime_value_minor
         FROM staff st
         LEFT JOIN attendance_entries a
           ON a.staff_id = st.id AND a.society_id = st.society_id
          AND to_char(a.work_date, 'YYYY-MM') = $2
        WHERE st.society_id = $1
        GROUP BY st.id, st.name, st.overtime_rate_minor
        HAVING COALESCE(sum(a.overtime_minutes),0) > 0
        ORDER BY overtime_minutes DESC`,
      [societyId, period]
    );
    return rows;
  },

  /** Staffing summary: counts by status/department/contractor. */
  async staffingReport(societyId: string) {
    const { rows } = await db.query(
      `SELECT count(*)::int AS total,
              count(*) FILTER (WHERE status = 'active')::int AS active,
              count(*) FILTER (WHERE status = 'suspended')::int AS suspended,
              count(*) FILTER (WHERE status = 'terminated')::int AS terminated,
              count(*) FILTER (WHERE is_contractor)::int AS contractors
         FROM staff WHERE society_id = $1`,
      [societyId]
    );
    return rows[0];
  },
};

/** CSV-safe export: escapes formula-injection and quotes fields. */
export function toCsv(rows: Record<string, any>[]): string {
  if (rows.length === 0) return "";
  const cols = Object.keys(rows[0]);
  const esc = (v: any) => {
    let s = v == null ? "" : String(v);
    if (/^[=+\-@]/.test(s)) s = "'" + s; // neutralize CSV injection
    return `"${s.replace(/"/g, '""')}"`;
  };
  return [cols.join(","), ...rows.map((r) => cols.map((c) => esc(r[c])).join(","))].join("\n");
}
