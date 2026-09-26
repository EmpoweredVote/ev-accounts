/**
 * build-s1-leads.ts — Season 1 leads for one politician's stance-research batch (spec §7 P1).
 *
 * 🔴 COLLECTOR-ONLY. Its output, <dir>/s1-leads.json, is a hint for the human assembling a batch —
 * "here is what a prior closed season last recorded for this topic, worth a re-check" — and must
 * NEVER be passed to a coder. A coder's whole job is to judge what the evidence in front of it
 * says; showing it the old answer would anchor that judgement instead of testing it. build-coder-
 * inputs.ts does not read this file, and no coder-inputs/coder-N.md may ever mention it.
 *
 * Read-only: no writes, anywhere. For each topic in <dir>/topics.json, it takes the person's newest
 * answer in a season whose status is NOT 'open' and NOT 'draft' (the season being researched right
 * now, and one not yet published, are both excluded — only a closed or superseded season counts),
 * together with that season's politician_context row (reasoning, sources) by the same season_id.
 * `seed` says whether that lead's ladder text still matches what this topic serves today
 * ('fresh') or has moved on ('stale') — see s1Leads.ts's seedState.
 *
 * Usage (from backend/):
 *   npx tsx scripts/build-s1-leads.ts --dir <batch> --politician <uuid>
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { pool } from '../src/lib/db.js';
import { seedState, type S1Lead } from './lib/s1Leads.js';

const arg = (n: string) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : undefined; };
const dir = arg('--dir'); const politicianId = arg('--politician');
if (!dir || !politicianId) { console.error('usage: --dir <batch> --politician <uuid>'); process.exit(2); }

const topics = JSON.parse(readFileSync(join(dir, 'topics.json'), 'utf8')) as
  { topic_id: string; topic_key: string; served_revision_id: string }[];

const leads: S1Lead[] = [];
try {
  for (const t of topics) {
    // 🔴 The `value <> 0` filter sits OUTSIDE the newest-season collapse (the inner LIMIT 1), never
    // inside it (CLAUDE.md's blanks-in-the-collapse trap). Filtering inside would let a blank
    // (value = 0) newest closed season fall through to an OLDER season's rung — serving a lead the
    // person no longer holds, from a season that isn't even the newest one that touched this topic.
    // The correct read is: take the newest closed-season row, blank or not, tied to ONE season_id
    // (so the context join below is honest) — then decide whether it counts as a lead at all.
    const { rows } = await pool.query(
      `SELECT * FROM (
         SELECT s.number AS season_number, a.value::float8 AS value, a.topic_revision_id::text AS pin_revision_id,
                a.season_id::text AS season_id
           FROM inform.politician_answers a
           JOIN inform.seasons s ON s.id = a.season_id AND s.status NOT IN ('open', 'draft')
          WHERE a.politician_id = $1 AND a.topic_id = $2
          ORDER BY s.number DESC
          LIMIT 1
       ) x WHERE x.value <> 0
       -- @season-scope: all-seasons — collector lead: the newest closed-season answer, read to be re-checked, never displayed`,
      [politicianId, t.topic_id],
    );
    if (rows.length === 0) continue; // no closed-season answer, or the newest one is a blank (value = 0) — no lead
    const a = rows[0] as { season_number: number; value: number; pin_revision_id: string; season_id: string };
    const { rows: ctxRows } = await pool.query(
      `SELECT reasoning, sources
         FROM inform.politician_context
        WHERE politician_id = $1 AND topic_id = $2 AND season_id = $3`,
      [politicianId, t.topic_id, a.season_id],
    );
    const ctx = ctxRows[0] as { reasoning: string | null; sources: string[] } | undefined;
    leads.push({
      topic_id: t.topic_id,
      topic_key: t.topic_key,
      season_number: a.season_number,
      value: a.value,
      pin_revision_id: a.pin_revision_id,
      reasoning: ctx?.reasoning ?? null,
      sources: ctx?.sources ?? [],
      seed: seedState(a.pin_revision_id, t.served_revision_id),
    });
  }
} finally {
  await pool.end();
}

writeFileSync(join(dir, 's1-leads.json'), JSON.stringify({ politician_id: politicianId, leads }, null, 2));
const fresh = leads.filter((l) => l.seed === 'fresh').length;
const stale = leads.length - fresh;
console.log(`${leads.length} leads (${fresh} fresh / ${stale} stale)`);
