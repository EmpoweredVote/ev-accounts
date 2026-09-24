/**
 * run-fec-review-enrich.ts — enrich the needs_research FEC review queue.
 *
 * For each needs_research FEC source, parse its stored candidate options and fetch
 * rich FEC context for every candidate_id in ONE batched call (FEC /candidates/
 * accepts repeated candidate_id params) — cheap enough to slip under a busy key.
 *
 * Writes a JSON review file consumed by the HTML review view. No DB writes.
 *
 * Usage: tsx scripts/run-fec-review-enrich.ts <outfile.json>
 */

import 'dotenv/config';
import { pool } from '../src/lib/db.js';

const OUT = process.argv[2] ?? 'fec-review.json';

interface Option { candidate_id: string; name: string; party?: string; score?: number }

interface FecDetail {
  candidate_id: string;
  name: string;
  office_full?: string;
  state?: string;
  district?: string;
  party_full?: string;
  incumbent_challenge_full?: string;
  election_years?: number[];
  cycles?: number[];
  first_file_date?: string;
  last_file_date?: string;
}

async function fetchDetails(ids: string[], apiKey: string): Promise<Map<string, FecDetail>> {
  const map = new Map<string, FecDetail>();
  const CHUNK = 50;
  for (let i = 0; i < ids.length; i += CHUNK) {
    const chunk = ids.slice(i, i + CHUNK);
    const params = new URLSearchParams({ api_key: apiKey, per_page: '100' });
    for (const id of chunk) params.append('candidate_id', id);
    let delay = 1000;
    for (let attempt = 0; attempt <= 4; attempt++) {
      const resp = await fetch(`https://api.open.fec.gov/v1/candidates/?${params.toString()}`, {
        signal: AbortSignal.timeout(30_000),
      });
      if (resp.status === 429) {
        if (attempt === 4) throw new Error('429 after retries — key saturated; retry later');
        await new Promise(r => setTimeout(r, delay));
        delay = Math.min(delay * 2, 60_000);
        continue;
      }
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      const data = await resp.json() as { results?: FecDetail[] };
      for (const c of data.results ?? []) map.set(c.candidate_id, c);
      break;
    }
    if (i + CHUNK < ids.length) await new Promise(r => setTimeout(r, 1500));
  }
  return map;
}

async function main() {
  const apiKey = process.env.FEC_API_KEY;
  if (!apiKey) { console.error('ERROR: FEC_API_KEY not set'); process.exit(1); }

  const rows = await pool.query<{
    source_id: string; politician_id: string; full_name: string; bioguide_id: string | null;
    source_system: string; representing_state: string; chamber: string; district_id: string | null;
    notes: string;
  }>(`
    -- One case per source. Occupancy resolves via office_current_holder (ADR 0002
    -- phase 5); a politician-rooted join fans out when someone holds two offices,
    -- so pick one: the seat in the source's own chamber, a held seat before a
    -- "Candidate for" placeholder, then lowest id for determinism.
    SELECT * FROM (
      SELECT DISTINCT ON (ps.id)
             ps.id AS source_id, ps.essentials_politician_id AS politician_id, p.full_name,
             p.bioguide_id, ps.source_system, o.representing_state, c.name AS chamber,
             o.district_id, ps.notes
      FROM transparent_motivations.politician_sources ps
      JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
      JOIN essentials.office_current_holder och ON och.politician_id = p.id
      JOIN essentials.offices o ON o.id = och.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      WHERE ps.source_system LIKE 'fec%' AND ps.research_status='needs_research'
        AND p.is_active=true AND p.is_vacant=false
        AND (c.name LIKE 'U.S. House%' OR c.name LIKE 'U.S. Senate%')
      ORDER BY ps.id,
               ((c.name LIKE 'U.S. Senate%') = (ps.source_system = 'fec_senate')) DESC,
               (COALESCE(o.title, '') ILIKE 'Candidate for%') ASC,
               o.id
    ) cases
    ORDER BY representing_state, full_name
  `);

  const cases = rows.rows.map(r => {
    let options: Option[] = [];
    try { const p = JSON.parse(r.notes || '[]'); if (Array.isArray(p)) options = p; } catch { /* non-JSON */ }
    return { ...r, options };
  });

  const allIds = [...new Set(cases.flatMap(c => c.options.map(o => o.candidate_id)).filter(Boolean))];
  console.log(`[enrich] cases=${cases.length} distinct candidate_ids=${allIds.length}`);

  const details = await fetchDetails(allIds, apiKey);
  console.log(`[enrich] fetched FEC detail for ${details.size}/${allIds.length} candidates`);

  const out = cases.map(c => ({
    source_id: c.source_id,
    politician_id: c.politician_id,
    full_name: c.full_name,
    bioguide_id: c.bioguide_id,
    source_system: c.source_system,
    representing_state: c.representing_state,
    chamber: c.chamber,
    district_id: c.district_id,
    options: c.options.map(o => {
      const d = details.get(o.candidate_id);
      return {
        candidate_id: o.candidate_id,
        fec_name: o.name,
        party: d?.party_full ?? o.party ?? null,
        score: o.score ?? null,
        office_full: d?.office_full ?? null,
        state: d?.state ?? null,
        district: d?.district ?? null,
        incumbent_challenge: d?.incumbent_challenge_full ?? null,
        cycles: (d?.cycles ?? d?.election_years ?? []).slice().sort((a, b) => b - a),
      };
    }),
  }));

  const fs = await import('node:fs/promises');
  await fs.writeFile(OUT, JSON.stringify(out, null, 2), 'utf8');
  console.log(`[enrich] wrote ${out.length} cases -> ${OUT}`);
  await pool.end();
  process.exit(0);
}

main().catch(err => { console.error('[enrich] Fatal:', err instanceof Error ? err.message : String(err)); process.exit(1); });
