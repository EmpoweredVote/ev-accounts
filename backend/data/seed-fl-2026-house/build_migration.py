#!/usr/bin/env python3
"""Generate 1116_seed_fl_2026_house_candidates.sql from 151-03-fl-reconciliation.csv."""
import csv

CSV='151-03-fl-reconciliation.csv'
OUT='../../migrations/1116_seed_fl_2026_house_candidates.sql'

def esc(s): return s.replace("'", "''")
def split_name(full):
    t=full.split()
    if len(t)==1: return full,''
    return t[0], ' '.join(t[1:])

rows=list(csv.DictReader(open(CSV,encoding='utf-8')))
new=[r for r in rows if r['decision']=='NEW']
# de-dupe new by external_id (each new external_id unique already)
pol_vals=[]
for r in new:
    fn,ln=split_name(r['full_name'])
    pol_vals.append(f"({r['assign_external_id']}, '{esc(r['full_name'])}', '{esc(fn)}', '{esc(ln)}')")

rc_vals=[]
for r in rows:
    fn,ln=split_name(r['full_name'])
    reuse = r['target_politician_id'].strip()
    reuse_sql = f"'{reuse}'" if reuse else 'NULL'
    ext = r['assign_external_id'] if r['decision']=='NEW' else 'NULL'
    src = esc(r['source_url'])[:300]
    rc_vals.append(f"('{r['race_id']}', {reuse_sql}, {ext}, '{esc(r['full_name'])}', '{esc(fn)}', '{esc(ln)}', {r['is_incumbent']}, '{src}')")

sql=f"""-- 1116_seed_fl_2026_house_candidates.sql
-- Phase 151 Wave 2 (151-03): seed the FULL PROVISIONAL Nov-3 field onto the 28 FL House races
-- (151-01 scaffold). Inserts {len(new)} NEW essentials.politicians + {len(rows)} race_candidates
-- (one per qualified candidate; multiple same-party preserved — D-02). 23 REUSE (20 sitting
-- renominated incumbents is_incumbent=true + 3 cross-district redistricted incumbents
-- is_incumbent=false: Frankel -12022->FL-23, Moskowitz -12023->FL-25, Wasserman Schultz -12025->FL-20).
--
-- FIELD SOURCE: 148-field-table.csv FL section (Wikipedia per-district URLs; FL DoE extract empty for
-- 2026 today per RESEARCH Q1). DEDUP (D-03, live-verified 2026-06-29): the ONLY reuse targets are the
-- 20 home incumbents (148 incumbent_pid) + 3 cross-district (exact external_id). Sheila
-- Cherfilus-McCormick + all other "new" names = genuinely NEW (0 prior records). 3 common-name
-- collisions inspected and kept NEW (unrelated people): "Mike Johnson" (FL-7, NOT Speaker -22004),
-- "James Martin" (FL-21, null-ext noise), "Michael Thompson" (FL-22, different officeholder).
-- ANTIPARTISAN (D-05): party NOT stored on the card; no essentials.offices rows for challengers
-- (feed resolves via race_candidates.politician_id); FL-20 office stays politician_id NULL.
--
-- Idempotent: politicians guarded by NOT EXISTS(external_id); race_candidates by NOT EXISTS(race_id, full_name).

BEGIN;

-- 1) {len(new)} new FL candidate politicians (negative external_id band -(1210000+cd*100+seq)).
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_active)
SELECT gen_random_uuid(), v.ext, v.full_name, v.first_name, v.last_name, true
FROM (VALUES
    {",\n    ".join(pol_vals)}
  ) AS v(ext, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.ext);

-- 2) {len(rows)} race_candidates across the 28 FL races (reuse pid or lookup new by external_id).
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT gen_random_uuid(), v.race_id::uuid,
       COALESCE(v.reuse_pid::uuid, (SELECT id FROM essentials.politicians WHERE external_id = v.ext::int)),
       v.full_name, v.first_name, v.last_name, v.is_incumbent::boolean, 'active', v.source
FROM (VALUES
    {",\n    ".join(rc_vals)}
  ) AS v(race_id, reuse_pid, ext, full_name, first_name, last_name, is_incumbent, source)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = v.race_id::uuid AND rc.full_name = v.full_name
);

COMMIT;
"""
open(OUT,'w',encoding='utf-8').write(sql)
print(f"wrote {OUT}: {len(new)} new politicians, {len(rows)} race_candidates")
