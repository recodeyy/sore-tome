import { describe, it, expect } from "@jest/globals";
import { computeDueAt, businessMinutesBetween, computeDueAtWithPauses, SlaConfig } from "../src/services/sla/SlaCalculator";
import { canTransition, assertTransition, isReopen } from "../src/services/complaints/ComplaintStateMachine";

// IST, Mon–Sat, 09:00–18:00 (9 business hours/day).
const cfg: SlaConfig = {
  tzOffsetMinutes: 330,
  workdays: [1, 2, 3, 4, 5, 6],
  dayStartMinutes: 540,
  dayEndMinutes: 1080,
};

// Helper: build a UTC Date from an IST wall-clock time.
const ist = (iso: string) => new Date(new Date(`${iso}+05:30`).toISOString());

describe("SlaCalculator", () => {
  it("stays within the same business day when there is enough time", () => {
    // Thu 2026-06-18 10:00 IST + 4h = 14:00 IST.
    const due = computeDueAt(ist("2026-06-18T10:00:00"), 240, cfg);
    expect(due.toISOString()).toBe(ist("2026-06-18T14:00:00").toISOString());
  });

  it("rolls over to the next business day when the window is exhausted", () => {
    // Thu 16:00 IST + 4h: 2h today (to 18:00) then 2h next morning -> Fri 11:00 IST.
    const due = computeDueAt(ist("2026-06-18T16:00:00"), 240, cfg);
    expect(due.toISOString()).toBe(ist("2026-06-19T11:00:00").toISOString());
  });

  it("skips Sunday (non-workday)", () => {
    // Sat 2026-06-20 16:00 IST + 4h: 2h Sat, skip Sun, 2h Mon -> Mon 2026-06-22 11:00 IST.
    const due = computeDueAt(ist("2026-06-20T16:00:00"), 240, cfg);
    expect(due.toISOString()).toBe(ist("2026-06-22T11:00:00").toISOString());
  });

  it("skips a configured holiday", () => {
    const withHoliday: SlaConfig = { ...cfg, holidays: ["2026-06-19"] };
    // Thu 16:00 + 4h: 2h Thu, skip Fri holiday, skip Sun, 2h Sat -> Sat 2026-06-20 11:00 IST.
    const due = computeDueAt(ist("2026-06-18T16:00:00"), 240, withHoliday);
    expect(due.toISOString()).toBe(ist("2026-06-20T11:00:00").toISOString());
  });

  it("clamps before-hours start to the window open", () => {
    // Thu 07:00 IST + 1h -> 10:00 IST (clock starts at 09:00).
    const due = computeDueAt(ist("2026-06-18T07:00:00"), 60, cfg);
    expect(due.toISOString()).toBe(ist("2026-06-18T10:00:00").toISOString());
  });

  it("counts business minutes between two instants", () => {
    expect(businessMinutesBetween(ist("2026-06-18T10:00:00"), ist("2026-06-18T12:30:00"), cfg)).toBe(150);
    // Across the overnight gap: Thu 17:00 -> Fri 10:00 = 1h Thu + 1h Fri = 120.
    expect(businessMinutesBetween(ist("2026-06-18T17:00:00"), ist("2026-06-19T10:00:00"), cfg)).toBe(120);
  });

  it("adds paused business time back to the due date", () => {
    // 4h target from Thu 10:00 = due 14:00. Pause 11:00-12:00 (1 business hour) -> 15:00.
    const due = computeDueAtWithPauses(
      ist("2026-06-18T10:00:00"),
      240,
      [{ from: ist("2026-06-18T11:00:00"), to: ist("2026-06-18T12:00:00") }],
      cfg
    );
    expect(due.toISOString()).toBe(ist("2026-06-18T15:00:00").toISOString());
  });
});

describe("ComplaintStateMachine", () => {
  it("allows valid transitions", () => {
    expect(canTransition("open", "in_progress")).toBe(true);
    expect(canTransition("in_progress", "resolved")).toBe(true);
    expect(canTransition("resolved", "closed")).toBe(true);
    expect(canTransition("closed", "in_progress")).toBe(true); // reopen
  });

  it("rejects invalid transitions", () => {
    expect(canTransition("open", "closed")).toBe(true);
    expect(canTransition("resolved", "open")).toBe(false);
    expect(() => assertTransition("resolved", "open")).toThrow(/Invalid complaint transition/);
  });

  it("treats a same-state update as a no-op", () => {
    expect(() => assertTransition("open", "open")).not.toThrow();
  });

  it("identifies reopen transitions", () => {
    expect(isReopen("closed", "in_progress")).toBe(true);
    expect(isReopen("resolved", "in_progress")).toBe(true);
    expect(isReopen("open", "in_progress")).toBe(false);
  });
});
