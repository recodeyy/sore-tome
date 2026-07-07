/**
 * Business-hours SLA math (pure, deterministic — no DB).
 *
 * Business time is a daily window [dayStartMinutes, dayEndMinutes] on configured
 * workdays, in the society's local timezone (expressed as a fixed UTC offset).
 * Holidays are excluded. India has no DST, so a civil day is a flat 24h here;
 * regions with DST would need a tz library — noted as a limitation.
 */
export interface SlaConfig {
  tzOffsetMinutes: number; // e.g. 330 for IST (UTC+5:30)
  workdays: number[]; // 0=Sun .. 6=Sat, e.g. [1,2,3,4,5,6]
  dayStartMinutes: number; // minutes from local midnight, e.g. 540 = 09:00
  dayEndMinutes: number; // e.g. 1080 = 18:00
  holidays?: string[]; // local 'YYYY-MM-DD'
}

const DAY_MS = 24 * 60 * 60 * 1000;

function startOfLocalDay(localMs: number): number {
  const d = new Date(localMs);
  return Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
}

function isWorkingDay(dayBaseMs: number, cfg: SlaConfig): boolean {
  const d = new Date(dayBaseMs);
  const dateStr = d.toISOString().slice(0, 10);
  return cfg.workdays.includes(d.getUTCDay()) && !(cfg.holidays || []).includes(dateStr);
}

/** Due instant (UTC) after consuming `targetBusinessMinutes` of business time from `start`. */
export function computeDueAt(start: Date, targetBusinessMinutes: number, cfg: SlaConfig): Date {
  const offsetMs = cfg.tzOffsetMinutes * 60000;
  let remaining = targetBusinessMinutes;
  let cursor = start.getTime() + offsetMs; // local ms

  for (let guard = 0; guard < 100000 && remaining > 0; guard++) {
    const dayBase = startOfLocalDay(cursor);
    const winStart = dayBase + cfg.dayStartMinutes * 60000;
    const winEnd = dayBase + cfg.dayEndMinutes * 60000;

    if (!isWorkingDay(dayBase, cfg) || cursor >= winEnd) {
      cursor = startOfLocalDay(dayBase + DAY_MS) + cfg.dayStartMinutes * 60000;
      continue;
    }
    if (cursor < winStart) cursor = winStart;

    const availMinutes = (winEnd - cursor) / 60000;
    if (availMinutes >= remaining) {
      cursor += remaining * 60000;
      remaining = 0;
    } else {
      remaining -= availMinutes;
      cursor = startOfLocalDay(dayBase + DAY_MS) + cfg.dayStartMinutes * 60000;
    }
  }

  return new Date(cursor - offsetMs); // back to UTC
}

/** Business minutes elapsed between two UTC instants (clamped to business windows). */
export function businessMinutesBetween(start: Date, end: Date, cfg: SlaConfig): number {
  if (end <= start) return 0;
  const offsetMs = cfg.tzOffsetMinutes * 60000;
  const startLocal = start.getTime() + offsetMs;
  const endLocal = end.getTime() + offsetMs;

  let total = 0;
  let dayBase = startOfLocalDay(startLocal);
  for (let guard = 0; guard < 100000 && dayBase <= endLocal; guard++) {
    if (isWorkingDay(dayBase, cfg)) {
      const winStart = dayBase + cfg.dayStartMinutes * 60000;
      const winEnd = dayBase + cfg.dayEndMinutes * 60000;
      const overlapStart = Math.max(winStart, startLocal);
      const overlapEnd = Math.min(winEnd, endLocal);
      if (overlapEnd > overlapStart) total += (overlapEnd - overlapStart) / 60000;
    }
    dayBase = startOfLocalDay(dayBase + DAY_MS);
  }
  return Math.round(total);
}

/**
 * Due instant accounting for paused intervals: the SLA clock stops during each
 * pause, so we add back the business-minutes that fell inside pauses.
 */
export function computeDueAtWithPauses(
  start: Date,
  targetBusinessMinutes: number,
  pauses: { from: Date; to: Date }[],
  cfg: SlaConfig
): Date {
  const naiveDue = computeDueAt(start, targetBusinessMinutes, cfg);
  let extra = 0;
  for (const p of pauses) {
    // Only count pause time that overlaps the active SLA span.
    const from = p.from < start ? start : p.from;
    const to = p.to > naiveDue ? naiveDue : p.to;
    if (to > from) extra += businessMinutesBetween(from, to, cfg);
  }
  return extra > 0 ? computeDueAt(start, targetBusinessMinutes + extra, cfg) : naiveDue;
}
