/**
 * governorTerms — each politician's terms as a state governor, from essentials.office_terms, for the
 * LegiScan signing line (legiscanEvidence.ts). Only the dates are read; an undated start is kept as
 * null, and the check that uses it (heldGovernorship) refuses it.
 */
import type { GovernorTerm } from './legiscanEvidence.js';

type Query = (sql: string, params: unknown[]) => Promise<{ rows: Record<string, unknown>[] }>;

export async function loadGovernorTerms(query: Query, politicianIds: string[]): Promise<Map<string, GovernorTerm[]>> {
  const out = new Map<string, GovernorTerm[]>();
  if (!politicianIds.length) return out;
  const { rows } = await query(
    `SELECT t.politician_id::text AS id, o.representing_state AS state,
            to_char(t.term_start, 'YYYY-MM-DD') AS start, to_char(t.term_end, 'YYYY-MM-DD') AS "end"
       FROM essentials.office_terms t
       JOIN essentials.offices o ON o.id = t.office_id
      WHERE o.role_canonical = 'governor' AND t.politician_id::text = ANY($1::text[])`,
    [politicianIds],
  );
  for (const r of rows) {
    const id = String(r.id);
    out.set(id, [...(out.get(id) ?? []), {
      state: String(r.state ?? '').toUpperCase(), start: (r.start as string | null) ?? null, end: (r.end as string | null) ?? null,
    }]);
  }
  return out;
}
