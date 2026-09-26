/**
 * s1Leads — pure types and helpers for a "Season 1 lead": what a person's newest closed-season
 * answer was, offered to the human collector as a re-check hint. COLLECTOR-ONLY (spec §7 P1 fresh/
 * stale seed): information for the person assembling a batch, never for a coder — a coder's whole
 * judgement is "what does the evidence say", and showing it the old answer would anchor that
 * judgement. See build-s1-leads.ts (which produces these) and coderPrompt.ts (which never reads
 * them).
 */

export interface S1Lead {
  topic_id: string;
  topic_key: string;
  season_number: number;
  value: number;
  pin_revision_id: string;
  reasoning: string | null;
  sources: string[];
  seed: 'fresh' | 'stale';
}

/**
 * The seasons design's seed state (2026-08-25-compass-seasons-design.md, "seed state"): 'fresh' when
 * the older season and the open season PIN the same revision — the same question, so the lead is a
 * starting point to confirm or change; 'stale' when the pins differ — the ladder moved, and the lead
 * may answer a sentence that no longer exists. Compare pin to pin, never to the open season's served
 * revision: a clarifying revision re-words the served text inside one pin, and comparing against it
 * made every lead 'stale' (2026-09-25: 14 of 14, although abortion's S1 and S2 pins are the same).
 */
export function seedState(olderPinRevisionId: string, openPinRevisionId: string): 'fresh' | 'stale' {
  return olderPinRevisionId === openPinRevisionId ? 'fresh' : 'stale';
}

/** Leads keyed by topic_id, for a fast per-row lookup. */
export function leadsById(leads: S1Lead[]): Map<string, S1Lead> {
  return new Map(leads.map((l) => [l.topic_id, l]));
}
