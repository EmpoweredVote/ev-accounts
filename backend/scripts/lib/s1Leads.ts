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
 * 'fresh' when the lead's answer was recorded against the same ladder text the topic serves now
 * (its pin revision equals the topic's served revision); 'stale' when the ladder has moved since —
 * a re-check should read the lead skeptically, because it may be an answer to a sentence that no
 * longer exists.
 */
export function seedState(pinRevisionId: string, servedRevisionId: string): 'fresh' | 'stale' {
  return pinRevisionId === servedRevisionId ? 'fresh' : 'stale';
}

/** Leads keyed by topic_id, for a fast per-row lookup. */
export function leadsById(leads: S1Lead[]): Map<string, S1Lead> {
  return new Map(leads.map((l) => [l.topic_id, l]));
}
