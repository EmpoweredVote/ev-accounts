/**
 * fecCycle — FEC two-year election cycles.
 *
 * A cycle is named for its even year and holds the odd year before it, so an
 * odd-year special election (2025) belongs to cycle 2026.
 *
 * A leaf module on purpose: fecResearch needs the cycle, and importing it from
 * campaignFinanceScheduler would load Redis, SQS and every adapter with it.
 */

/** The FEC cycle an election year belongs to: 2025 -> 2026, 2026 -> 2026. */
export function fecCycleOf(year: number): number {
  return year % 2 !== 0 ? year + 1 : year;
}

/**
 * currentFecCycle returns the current FEC election cycle year as a string.
 * FEC cycles are even years; odd years round up to next even year.
 * e.g. 2025 -> "2026", 2026 -> "2026"
 */
export function currentFecCycle(): string {
  return String(fecCycleOf(new Date().getFullYear()));
}
