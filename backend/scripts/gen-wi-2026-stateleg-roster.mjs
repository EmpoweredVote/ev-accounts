// Roster export for the WI 2026 state-legislature stance wave.
// Usage (DATABASE_URL must be in env — prefix with `set -a && source .env && set +a`):
//   node scripts/gen-wi-2026-stateleg-roster.mjs
//
// Writes three CSVs into data/stance-research/wi-2026-state-leg/:
//   roster_full.csv        — every candidate on the 2026-08-11 partisan primary ballot (state leg)
//   roster_contested.csv   — subset whose primary is contested (>=2 candidates in the same party race)
//   roster_incumbents.csv  — every sitting member per office_current_holder, on the ballot or not
//
// Read-only. Writes no database rows.
import { Pool } from 'pg';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const OUT_DIR = join('data', 'stance-research', 'wi-2026-state-leg');
const PRIMARY_DATE = '2026-08-11';

const CANDIDATE_SQL = `
WITH field AS (
  SELECT rc.politician_id,
         r.id                AS race_id,
         r.primary_party,
         o.id                AS office_id,
         o.title             AS office_title,
         d.district_type,
         -- districts.district_id is NULL for WI state leg; the number lives in ocd_id (sldl:N / sldu:N)
         split_part(d.ocd_id, ':', 4)::int AS district_no,
         d.label             AS district_label,
         d.geo_id,
         rc.full_name        AS ballot_name,
         rc.is_incumbent,
         rc.website_url,
         count(*) OVER (PARTITION BY r.id) AS cands_in_primary
    FROM essentials.races r
    JOIN essentials.elections e      ON e.id = r.election_id
    JOIN essentials.offices o        ON o.id = r.office_id
    JOIN essentials.districts d      ON d.id = o.district_id
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE lower(d.state) = 'wi'
     AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     AND e.election_date = $1
)
SELECT f.politician_id,
       p.external_id,
       p.full_name,
       f.ballot_name,
       p.party,
       CASE f.district_type WHEN 'STATE_LOWER' THEN 'Assembly' ELSE 'Senate' END AS chamber,
       f.district_no,
       f.primary_party,
       f.cands_in_primary,
       (f.cands_in_primary >= 2)                            AS primary_contested,
       f.is_incumbent,
       f.office_id,
       f.geo_id,
       coalesce(f.website_url, '')                          AS website_url,
       coalesce(array_to_string(p.urls, ' | '), '')          AS politician_urls,
       (SELECT count(*) FROM inform.politician_answers pa  WHERE pa.politician_id = f.politician_id) AS answers,
       (SELECT count(*) FROM inform.politician_context pc   WHERE pc.politician_id = f.politician_id) AS ctx,
       (SELECT count(*) FROM essentials.politician_images pi WHERE pi.politician_id = f.politician_id) AS headshots,
       p.last_stances_researched_at::date                   AS last_researched
  FROM field f
  JOIN essentials.politicians p ON p.id = f.politician_id
 ORDER BY chamber, f.district_no, f.primary_party, p.full_name
`;

const INCUMBENT_SQL = `
SELECT och.politician_id,
       p.external_id,
       p.full_name,
       p.party,
       CASE d.district_type WHEN 'STATE_LOWER' THEN 'Assembly' ELSE 'Senate' END AS chamber,
       split_part(d.ocd_id, ':', 4)::int AS district_no,
       o.id          AS office_id,
       d.geo_id,
       o.is_vacant,
       (SELECT count(*) FROM inform.politician_answers pa  WHERE pa.politician_id = och.politician_id) AS answers,
       (SELECT count(*) FROM inform.politician_context pc   WHERE pc.politician_id = och.politician_id) AS ctx,
       (SELECT count(*) FROM essentials.politician_images pi WHERE pi.politician_id = och.politician_id) AS headshots,
       EXISTS (
         SELECT 1 FROM essentials.races r
         JOIN essentials.elections e ON e.id = r.election_id
         JOIN essentials.race_candidates rc ON rc.race_id = r.id
        WHERE r.office_id = o.id AND e.election_date = $1
          AND rc.politician_id = och.politician_id
       ) AS on_2026_primary_ballot
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
 WHERE lower(d.state) = 'wi'
   AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
 ORDER BY chamber, split_part(d.ocd_id, ':', 4)::int
`;

function toCsv(rows) {
  if (rows.length === 0) return '';
  const cols = Object.keys(rows[0]);
  const esc = (v) => {
    if (v === null || v === undefined) return '';
    const s = String(v);
    return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  return [cols.join(','), ...rows.map((r) => cols.map((c) => esc(r[c])).join(','))].join('\n') + '\n';
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
try {
  mkdirSync(OUT_DIR, { recursive: true });

  const cands = (await pool.query(CANDIDATE_SQL, [PRIMARY_DATE])).rows;
  const contested = cands.filter((r) => r.primary_contested);
  const incumbents = (await pool.query(INCUMBENT_SQL, [PRIMARY_DATE])).rows;

  writeFileSync(join(OUT_DIR, 'roster_full.csv'), toCsv(cands));
  writeFileSync(join(OUT_DIR, 'roster_contested.csv'), toCsv(contested));
  writeFileSync(join(OUT_DIR, 'roster_incumbents.csv'), toCsv(incumbents));

  const zero = cands.filter((r) => Number(r.answers) === 0).length;
  const noPhoto = cands.filter((r) => Number(r.headshots) === 0).length;
  const orphanIncumbents = incumbents.filter((r) => !r.on_2026_primary_ballot).length;

  console.log(`roster_full.csv        ${cands.length} candidates (${zero} at zero stances, ${noPhoto} without a headshot)`);
  console.log(`roster_contested.csv   ${contested.length} candidates in contested primaries`);
  console.log(`roster_incumbents.csv  ${incumbents.length} sitting members (${orphanIncumbents} NOT on the 2026 primary ballot)`);
} finally {
  await pool.end();
}
