/**
 * Complaint status state machine (pure). Only these transitions are valid;
 * anything else throws so a complaint can never jump to an illegal state.
 */
export type ComplaintStatus = "open" | "in_progress" | "resolved" | "closed";

const TRANSITIONS: Record<ComplaintStatus, ComplaintStatus[]> = {
  open: ["in_progress", "resolved", "closed"],
  in_progress: ["resolved", "closed", "open"],
  resolved: ["closed", "in_progress"], // reopen -> in_progress
  closed: ["in_progress"], // reopen -> in_progress
};

export function canTransition(from: ComplaintStatus, to: ComplaintStatus): boolean {
  return TRANSITIONS[from]?.includes(to) ?? false;
}

export function assertTransition(from: ComplaintStatus, to: ComplaintStatus): void {
  if (from === to) return; // no-op is allowed (idempotent updates)
  if (!canTransition(from, to)) {
    throw Object.assign(
      new Error(`Invalid complaint transition: ${from} -> ${to}`),
      { code: "INVALID_TRANSITION" }
    );
  }
}

export function isReopen(from: ComplaintStatus, to: ComplaintStatus): boolean {
  return (from === "resolved" || from === "closed") && to === "in_progress";
}
