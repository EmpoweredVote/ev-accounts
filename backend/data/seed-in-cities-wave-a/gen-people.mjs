#!/usr/bin/env node
// gen-people.mjs — writes CA_0417: seats the holders verified by verify-collect.mjs into the offices
// CA_0416 created, for the cities in structure.json.
//
// Name handling: a quoted nickname ('James "Jim" Chalos') becomes preferred_name and is dropped from
// full_name; a trailing Jr./Sr./II-IV becomes name_suffix and stays in full_name; a parenthetical
// maiden name ('Deborah S. (Ladyga) Block') is dropped from full_name and kept in alternate_names.
//
// REUSE lists people already in production, matched by match-people.mjs and checked one by one.
// SKIP lists holders on a city page who no longer hold the seat (the office is flagged vacant instead).
import fs from 'node:fs'; import path from 'node:path';
const DIR = path.dirname(new URL(import.meta.url).pathname);
// Usage: node gen-people.mjs <SLOT> <BAND_TOP> <slug,slug,...>
//   BAND_TOP: external_id band runs DOWN from here; the migration asserts it is empty first.
const [SLOT, BAND_ARG, WHICH] = process.argv.slice(2);
if (!SLOT || !BAND_ARG || !WHICH) { console.error('usage: gen-people.mjs <SLOT> <BAND_TOP> <slugs>'); process.exit(2); }
const BAND_TOP = Number(BAND_ARG);

const REUSE = {
  'Mary Allen':      { id: '97243dc4-1b2c-4e37-b480-264f47b3f1bd', why: "same person: the at-large Evansville councilor ran for Indiana's 8th Congressional District in 2026 (row holds that candidacy)" },
  'Heidi Beidinger': { id: '5c85d165-6c32-415b-a220-d51b42668cf6', why: 'inactive indiana_discovery stub (Indiana elected officials), deactivated by CC_0101; no other row' },
  'Dale Basham':     { id: '245d3807-f6ee-44be-a321-bd597d0aab7a', why: 'inactive indiana_discovery stub, deactivated by CC_0101; no other row' },
  'Aaron Mishler':   { id: 'c2cfdf00-d537-4c57-92a8-27dadf7a0274', why: 'inactive indiana_discovery stub, deactivated by CC_0101; no other row' },
  'Scott Hawkins':   { id: '856009a9-d2f9-4984-bbe9-76c261c72f94', why: 'inactive indiana_discovery stub, deactivated by CC_0101; no other row' },
  'Ray Collins':     { id: 'f0e871d5-01a2-4fa3-81f7-479855896f16', why: 'inactive indiana_discovery stub, deactivated by CC_0101; no other row, no race' },
};
const SKIP = { 'muncie-in|Council Member, District 4': 'Sara Gullion' };
// Former names, kept in alternate_names. Each one is evidenced on the city's own page.
const ALT = { 'Erin Kasch': { names: ['Erin Betron'], why: "Greenwood's officials page lists 'Erin Kasch, At-Large' with the email betrone@greenwood.in.gov; she was caucused in and elected as Erin Betron" } };
// Same name as an existing row, but a different person (the duplicate-name guard stops on these).
const DUP_OK = { 'Mike Moore': "existing row c554cb1f (source sos_excel) is a 2026 Republican primary candidate for Indiana House District 60 (Morgan/Monroe counties); this one is the sitting Mayor of Jeffersonville, Clark County" };

function parseName(raw) {
  let s = raw.trim(), preferred = null, suffix = null, alt = [];
  const q = s.match(/\s*["“]([^"”]+)["”]\s*/);
  if (q) { preferred = q[1]; s = s.replace(q[0], ' ').replace(/\s+/g, ' ').trim(); }
  const par = s.match(/\s*\(([^)]+)\)\s*/);
  if (par) { s = s.replace(par[0], ' ').replace(/\s+/g, ' ').trim(); }
  const sx = s.match(/,?\s+(Jr\.?|Sr\.?|II|III|IV)$/);
  if (sx) suffix = sx[1];
  const core = (sx ? s.slice(0, sx.index) : s).split(' ');
  const first = core[0], last = core[core.length - 1];
  if (par) alt.push(`${first} ${par[1]}`);
  return { full: s, first, last, preferred, suffix, alt };
}
const q = (v) => v == null ? 'NULL' : `'${String(v).replace(/'/g, "''")}'`;
const arr = (a) => `'{${a.map((x) => '"' + x.replace(/"/g, '\\"') + '"').join(',')}}'`;

const S = JSON.parse(fs.readFileSync(path.join(DIR, 'structure.json'), 'utf8')).filter((s) => WHICH.split(',').includes(s.slug));
const people = [], terms = [], vacants = [];
let ext = BAND_TOP;
for (const s of S) {
  const j = JSON.parse(fs.readFileSync(path.join(DIR, 'cities', s.slug + '.json'), 'utf8'));
  const gov = `City of ${s.name}, Indiana, US`;
  let atl = 0;
  for (const h of j.holders) {
    let geo, title = h.office, ordinal = null;
    const dm = h.office.match(/District (\d+)$/);
    if (dm) geo = `${s.slug}-council-district-${dm[1]}`;
    else if (/At Large$/.test(h.office)) { geo = s.geoid; ordinal = ++atl; }
    else geo = s.geoid;
    if (SKIP[`${s.slug}|${h.office}`] === h.name) { vacants.push({ gov, geo, title, name: h.name }); continue; }
    const n = parseName(h.name);
    if (ALT[h.name]) n.alt.push(...ALT[h.name].names);
    const reuse = REUSE[h.name];
    const key = reuse ? `id:${reuse.id}` : `ext:${ext}`;
    if (!reuse) people.push({ ext: ext--, ...n, slug: s.slug, src: h.source_url });
    terms.push({ key, gov, geo, title, ordinal, of: s.at_large_seats, slug: s.slug, name: n.full, src: h.source_url, reuse });
  }
}
const extLow = ext + 1;
const nTerms = terms.length, nNew = people.length, nReuse = terms.filter((t) => t.reuse).length;
const totalOffices = S.reduce((a, s) => a + s.council_size + 2, 0);
const govs = S.map((s) => `'City of ${s.name}, Indiana, US'`).join(', ');
const usedReuse = Object.entries(REUSE).filter(([n]) => terms.some((t) => t.reuse && t.reuse === REUSE[n]));
const usedDup = Object.entries(DUP_OK).filter(([n]) => people.some((p) => p.full === n));
const usedAlt = Object.entries(ALT).filter(([n]) => people.some((p) => p.full === n) || usedReuse.some(([m]) => m === n));
const reuseIds = usedReuse.map(([, r]) => q(r.id)).join(', ');
// Per-migration prose (city-specific caveats) lives in people-notes/<SLOT>.txt, one comment line per line.
const notesFile = path.join(DIR, 'people-notes', `${SLOT}.txt`);
const notes = fs.existsSync(notesFile) ? fs.readFileSync(notesFile, 'utf8').trimEnd().split('\n').map((l) => `-- ${l}`.trimEnd()).join('\n') + '\n--\n' : '';

let sql = `-- ${SLOT}_indiana_cities_wave_a_people.sql
-- Indiana cities Wave A, occupancy half, for ${S.map((s) => s.name).join(', ')}. Slot RESERVED from the
-- allocator. Follows the structure migration that created these ${S.length} governments and ${totalOffices} offices.
--
-- 🔴 APPLY IT THE SAME DAY AS THE STRUCTURE MIGRATION: an office with a polygon and no holder that is not
-- flagged vacant is DEAD_GEOGRAPHY to check:reachability. The post-verify below gates that at zero.
--
-- Seats ${nTerms} of ${totalOffices} offices: ${nNew} new people (external_id ${BAND_TOP} .. ${extLow},
-- asserted empty below) and ${nReuse} existing rows reused. ${vacants.length} office(s) flagged vacant.
--
-- 🟢 EVERY NAME WAS CHECKED AGAINST A SAVED COPY OF ITS SOURCE PAGE (verify-collect.mjs in
-- backend/data/seed-in-cities-wave-a/, which runs an absent-name and a planted-name control first).
--
-- 🔴 TERM START IS 'unknown', NOT GUESSED. Most holders began on 2024-01-01 after the 2023 election, but
-- re-elected incumbents began earlier (re-election does not end an occupancy) and caucus appointees began
-- mid-term on dates the pages do not give. term_start is NULL with start_precision 'unknown' -- the
-- shape migration 1459's backfill used -- rather than a sourced-looking date that is false for some.
--
-- 🔴 NO term_end IS WRITTEN. These terms run to 2027-12-31; a future term_end would vacate every seat on
-- that date with no successor.
--
${notes}${usedReuse.length ? `-- REUSED PEOPLE (matched by surname + first name in match-people.mjs, whose positive control is
-- Sharon Tucker, then checked by hand):
${usedReuse.map(([n, r]) => `--   ${n.padEnd(16)} ${r.id}  ${r.why}`).join('\n')}
--   Each is set is_active = true: an inactive person in a seat is hidden by the reps feed, which
--   check:reachability counts as REPS_FILTER_HIDDEN.
` : `-- NO EXISTING PERSON IS REUSED: match-people.mjs found no same-name row for any holder here (its positive
-- control, Sharon Tucker, matched).
`}${usedDup.length ? `-- SAME NAME, DIFFERENT PERSON (new row made, existing one untouched):
${usedDup.map(([n, w]) => `--   ${n}: ${w}`).join('\n')}
` : ''}${usedAlt.length ? `-- FORMER NAMES kept in alternate_names:
${usedAlt.map(([n, a]) => `--   ${n} (${a.names.join(', ')}): ${a.why}`).join('\n')}
` : ''}--
-- 🔴 PARTY IS NOT WRITTEN (it lives on races.primary_party). alternate_names is never NULL.
-- 🔴 The at-large seats share one title, so they are matched on the internal ordinal the structure
-- migration wrote into description. Which person gets which ordinal is arbitrary and means nothing.
--
-- Idempotent: people NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).

BEGIN;
${usedDup.length ? `
-- The duplicate-name guard stops on ${usedDup.map(([n]) => n).join(', ')}, a different person (see the header).
SET LOCAL essentials.allow_duplicate_name = 'on';
` : ''}
-- ─── 0. Pre-flight ───────────────────────────────────────────────────────────
DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM essentials.politicians WHERE external_id BETWEEN ${extLow} AND ${BAND_TOP};
  IF v NOT IN (0, ${nNew}) THEN RAISE EXCEPTION '${SLOT} pre-flight: external_id band holds % rows, expected 0 (or ${nNew} on a re-run)', v; END IF;
${usedReuse.map(([n, r]) => `  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = ${q(r.id)} AND full_name = ${q(n)}) THEN
    RAISE EXCEPTION '${SLOT} pre-flight: reused row ${r.id} is missing or no longer named ${n.replace(/'/g, "''")}'; END IF;`).join('\n')}
  SELECT count(*) INTO v FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name IN (${govs});
  IF v <> ${totalOffices} THEN RAISE EXCEPTION '${SLOT} pre-flight: % offices in these cities, expected ${totalOffices} (is the structure migration applied?)', v; END IF;
END $$;

-- ─── 1. ${nNew} new people ─────────────────────────────────────────────────────
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, preferred_name, name_suffix, source, alternate_names, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, n.preferred_name, n.name_suffix, n.source, n.alternate_names::text[], true
FROM (VALUES
${people.map((p) => `  (${p.ext}, ${q(p.full)}, ${q(p.first)}, ${q(p.last)}, ${q(p.preferred)}, ${q(p.suffix)}, ${q(`${SLOT} Indiana cities Wave A: ${p.src}, read 2026-11-24`)}, ${arr(p.alt)})`).join(',\n')}
) AS n(external_id, full_name, first_name, last_name, preferred_name, name_suffix, source, alternate_names)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

${usedReuse.length ? `-- ─── 2. Re-activate reused people ────────────────────────────────────────────
UPDATE essentials.politicians SET is_active = true
 WHERE id IN (${reuseIds}) AND is_active IS DISTINCT FROM true;` : '-- ─── 2. (no reused people) ───────────────────────────────────────────────────'}

-- ─── 3. ${nTerms} terms ──────────────────────────────────────────────────────────
CREATE TEMP TABLE w_terms(ext bigint, pid uuid, gov text, geo_id text, title text, ordinal int, of_n int, src text) ON COMMIT DROP;
INSERT INTO w_terms VALUES
${terms.map((t) => `  (${t.key.startsWith('ext:') ? t.key.slice(4) : 'NULL'}, ${t.key.startsWith('id:') ? q(t.key.slice(3)) : 'NULL'}, ${q(t.gov)}, ${q(t.geo)}, ${q(t.title)}, ${t.ordinal ?? 'NULL'}, ${t.ordinal ? t.of : 'NULL'}, ${q(t.src)})`).join(',\n')};

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, 'unknown', 'unknown',
       '${SLOT} Indiana cities Wave A: holder named on ' || t.src || ', read 2026-11-24; start date not published'
FROM w_terms t
JOIN essentials.governments g ON g.name = t.gov
JOIN essentials.chambers c ON c.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = t.title
 AND (t.ordinal IS NULL OR o.description LIKE 'Internal ordinal ' || t.ordinal || ' of ' || t.of_n || '.%')
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = t.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'in'
JOIN essentials.politicians p ON (t.pid IS NOT NULL AND p.id = t.pid) OR (t.ext IS NOT NULL AND p.external_id = t.ext)
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── 4. Vacancy ──────────────────────────────────────────────────────────────
${vacants.map((v) => `UPDATE essentials.offices o SET is_vacant = true, vacant_since = NULL
  FROM essentials.chambers c, essentials.governments g, essentials.districts d
 WHERE c.id = o.chamber_id AND g.id = c.government_id AND d.id = o.district_id
   AND g.name = ${q(v.gov)} AND o.title = ${q(v.title)} AND d.geo_id = ${q(v.geo)};`).join('\n')}

-- ─── 5. Post-verify ──────────────────────────────────────────────────────────
DO $$
DECLARE v_off int; v_seat int; v_vac int; v_dead int; v_held_vac int; v_dupe int; v_inact int; v_ended int; v_terms int;
BEGIN
  -- count(och.politician_id), never count(*): the view LEFT JOINs from offices.
  SELECT count(o.id), count(och.politician_id), count(*) FILTER (WHERE o.is_vacant),
         count(*) FILTER (WHERE och.politician_id IS NULL AND NOT coalesce(o.is_vacant, false)),
         count(*) FILTER (WHERE och.politician_id IS NOT NULL AND o.is_vacant)
    INTO v_off, v_seat, v_vac, v_dead, v_held_vac
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE g.name IN (${govs});
  IF v_off <> ${totalOffices} OR v_seat <> ${nTerms} OR v_vac <> ${vacants.length} OR v_dead <> 0 OR v_held_vac <> 0 THEN
    RAISE EXCEPTION '${SLOT}: offices %/${totalOffices}, seated %/${nTerms}, vacant %/${vacants.length}, unseated-unflagged % (want 0), seated-and-flagged % (want 0)',
      v_off, v_seat, v_vac, v_dead, v_held_vac;
  END IF;

  -- No person holds two seats in these cities (a loose at-large match would seat one person three times).
  SELECT count(*) INTO v_dupe FROM (
    SELECT och.politician_id FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    WHERE g.name IN (${govs}) GROUP BY och.politician_id HAVING count(*) > 1) s;
  IF v_dupe <> 0 THEN RAISE EXCEPTION '${SLOT}: % people hold more than one seat in these cities', v_dupe; END IF;

  SELECT count(*) FILTER (WHERE NOT p.is_active), count(*) FILTER (WHERE ot.term_end IS NOT NULL), count(*)
    INTO v_inact, v_ended, v_terms
  FROM essentials.office_terms ot
  JOIN essentials.politicians p ON p.id = ot.politician_id
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name IN (${govs});
  IF v_inact <> 0 OR v_ended <> 0 OR v_terms <> ${nTerms} THEN
    RAISE EXCEPTION '${SLOT}: % inactive holders, % ended terms, % terms (want 0, 0, ${nTerms})', v_inact, v_ended, v_terms;
  END IF;

  RAISE NOTICE '${SLOT} OK: ${totalOffices} offices, ${nTerms} seated (${nNew} new + ${nReuse} reused), ${vacants.length} vacant, 0 dead, 0 doubled';
END $$;

COMMIT;
`;
const out = path.join(DIR, '..', '..', 'migrations', `${SLOT}_indiana_cities_wave_a_people.sql`);
fs.writeFileSync(out, sql);
console.log(`wrote ${out}: ${nNew} new, ${nReuse} reused, ${nTerms} terms, ${vacants.length} vacant, band ${BAND_TOP}..${extLow}`);
for (const p of people.filter((p) => p.preferred || p.suffix || p.alt.length)) console.log(`  name: ${p.full} | first ${p.first} | last ${p.last} | pref ${p.preferred} | sfx ${p.suffix} | alt ${p.alt}`);
