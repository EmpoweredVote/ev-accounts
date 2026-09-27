"""Write migrations/CA_0297_legislative_service_ca_in_az.sql from the reviewed proposal files
(backend/data/legislative-service/2026-09-27-{CA,IN,AZ}-proposal.json). Name-only matches must be listed
in VERIFIED with the independent source that confirmed the identity, or the script stops."""
import json
VERIFIED = {
  'Wendy Carrillo': 'https://en.wikipedia.org/wiki/Wendy_Carrillo, https://www.wendycarrillo.com/press/launch',
  'Aaron Lieberman': 'https://en.wikipedia.org/wiki/Aaron_Lieberman, https://www.aaron4az.com/',
  'Jamescita Peshlakai': 'https://en.wikipedia.org/wiki/Jamescita_Peshlakai, navajotimes.com (Ta’neeszahnii ticket, 2026)',
  'David Cook Sr.': 'https://ballotpedia.org/David_Cook_(Arizona), paysonroundup.com (2026 District 7 primary)',
  'Christine Marsh': 'https://en.wikipedia.org/wiki/Christine_Marsh, https://ballotpedia.org/Christine_Marsh',
}
q = lambda s: 'NULL' if s is None else "'" + str(s).replace("'", "''") + "'"
rows, counts = [], {}
for st in ['CA', 'IN', 'AZ']:
  d = json.load(open(f'data/legislative-service/2026-09-27-{st}-proposal.json'))
  for p in d['proposals']:
    if not p['openstates_id']: continue
    src = p['source'] + f" | proposal backend/data/legislative-service/2026-09-27-{st}-proposal.json | CA_0297"
    if 'unique' in (p['match'] or ''):
      assert p['full_name'] in VERIFIED, f"name-only match not verified: {p['full_name']}"
      src += f" | identity checked 2026-09-27 against {VERIFIED[p['full_name']]}"
    for s in p['spans']:
      assert s['start_precision'] != 'bad' and s['end_precision'] != 'bad'
      assert not (s['service_start'] and s['service_end'] and s['service_start'] > s['service_end'])
      rows.append(f"  ({q(p['politician_id'])}::uuid, {q(st)}, {q(s['chamber'])}, {q(s['district'])}, {q(s['service_start'])}::date, "
                  f"{q(s['start_precision'])}, {q(s['service_end'])}::date, {q(s['end_precision'])}, {q(src)})")
      counts[st] = counts.get(st, 0) + 1
total = len(rows)
MATCH = """ SELECT 1 FROM essentials.legislative_service s
                    WHERE s.politician_id = r.politician_id AND s.state_usps = r.state_usps AND s.chamber = r.chamber
                      AND coalesce(s.district_label, '') = coalesce(r.district_label, '')
                      AND s.service_start IS NOT DISTINCT FROM r.service_start AND s.service_end IS NOT DISTINCT FROM r.service_end"""
sql = f"""BEGIN;

-- =============================================================================
-- CA_0297: essentials.legislative_service rows for CA / IN / AZ (codebook V5 option B)
-- =============================================================================
-- Scope (ruling 2026-09-27, Chris Andrews): the people stance research covers — the seated state
-- legislators of CA, IN and AZ, and the current candidates for their state-legislature seats.
-- Source: OpenStates `people` @ bf4caf10 (2026-09-24), the commit CA_0293 / CA_0295 used, via
-- backend/scripts/legislative-service-openstates.ts; this file by backend/scripts/legislative-service-sql.py.
-- Matching: seat (chamber + district) + surname; otherwise a UNIQUE family + given-name match in the
-- state. The 5 name-only matches (all candidates) were each checked against an independent source on
-- 2026-09-27; the source note names it. Unmatched people get no rows (most never served).
-- Every role of type upper/lower becomes one span, dates as the source gives them: a role with no
-- start is start_precision 'unknown' ("Don't invent dates"). CONFIRM covers an unknown start only for
-- the span's last regular term (decision 2026-09-27 (b)). A role that ends before it starts is a
-- source error and is left out (1: Harold Slager, IN House 15).
-- Rows: {total} (CA {counts['CA']}, IN {counts['IN']}, AZ {counts['AZ']}). Idempotent: a span already on file is skipped.
-- Requires CA_0296.
-- =============================================================================

CREATE TEMP TABLE ca0297_rows (politician_id uuid, state_usps text, chamber text, district_label text, service_start date,
  start_precision text, service_end date, end_precision text, source text) ON COMMIT DROP;
INSERT INTO ca0297_rows VALUES
""" + ",\n".join(rows) + f""";

INSERT INTO essentials.legislative_service (politician_id, state_usps, chamber, district_label, service_start, start_precision, service_end, end_precision, source)
SELECT r.politician_id, r.state_usps, r.chamber, r.district_label, r.service_start, r.start_precision, r.service_end, r.end_precision, r.source
  FROM ca0297_rows r
 WHERE NOT EXISTS ({MATCH});

DO $$
DECLARE v int; missing int;
BEGIN
  SELECT count(*) INTO missing FROM ca0297_rows r WHERE NOT EXISTS ({MATCH});
  IF missing <> 0 THEN RAISE EXCEPTION 'CA_0297: % proposed span(s) are not on file after the insert', missing; END IF;
  SELECT count(*) INTO v FROM essentials.legislative_service WHERE source LIKE '%CA_0297%';
  IF v <> {total} THEN RAISE EXCEPTION 'CA_0297: expected {total} rows from this migration, found %', v; END IF;
END $$;

COMMIT;
"""
open('migrations/CA_0297_legislative_service_ca_in_az.sql', 'w').write(sql)
print(total, counts)
