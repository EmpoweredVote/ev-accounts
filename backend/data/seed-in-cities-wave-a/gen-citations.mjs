#!/usr/bin/env node
// gen-citations.mjs — writes one migration that records, in essentials.citations (CA_0420), the source
// behind every fact the Wave A migrations wrote for the given cities:
//
//   holder     office_term  the page that names the current holder      (cities/<slug>.json holders[].source_url)
//   structure  government   the city's own page showing its seats, and the Indiana Code section that
//                           fixes them (IC 36-4-6-3 second class, 36-4-6-4 third class)
//   boundary   geofence_boundary  the map service each X0091 district was loaded from (council-maps.json)
//   vacancy    office       EXTRA_VACANCY below
//   name       politician   EXTRA_NAME below (a former name kept in alternate_names)
//
// Rows are found by MEANING, not by a key this script guesses: an office_term is the current term of the
// office matched on (government, title, district, ordinal), and the post-verify asserts that its holder's
// full_name is the name the city page printed. A Wayback snapshot is split into the ORIGINAL url and the
// archive_url. retrieved_on is the day the saved copy under raw/ was written.
//
// Usage: node gen-citations.mjs <SLOT> <migration-name-suffix> <slug,slug,...>
import fs from 'node:fs'; import path from 'node:path';
const DIR = path.dirname(new URL(import.meta.url).pathname);
const [SLOT, SUFFIX, WHICH] = process.argv.slice(2);
if (!SLOT || !SUFFIX || !WHICH) { console.error('usage: gen-citations.mjs <SLOT> <suffix> <slugs>'); process.exit(2); }
const want = WHICH.split(',');
const S = JSON.parse(fs.readFileSync(path.join(DIR, 'structure.json'), 'utf8')).filter((s) => want.includes(s.slug));
if (S.length !== want.length) { console.error('a slug is not in structure.json'); process.exit(2); }
const MAPS = JSON.parse(fs.readFileSync(path.join(DIR, 'council-maps.json'), 'utf8'));

const IC = {
  second: { url: 'https://iga.in.gov/laws/2025/ic/titles/36#36-4-6-3', title: 'IC 36-4-6-3: legislative body of a second class city (six district and three at-large members)' },
  third:  { url: 'https://iga.in.gov/laws/2025/ic/titles/36#36-4-6-4', title: 'IC 36-4-6-4: legislative body of a third class city (five district and two at-large members, or four and three)' },
};
const EXTRA_VACANCY = {
  'muncie-in|Council Member, District 4': {
    url: 'https://muncievoice.com/40790/surveillance-ordinance-filed-in-muncie-introduction-set-for-dec-7/', file: 'raw/muncie-in/voice-surveillance.html',
    title: 'Surveillance Ordinance Filed In Muncie; Introduction Set For Dec. 7', publisher: 'Muncie Voice',
    note: 'Sara Gullion resigned from the Council on winning Indiana House District 34; caucus 2026-11-30.' },
};
const EXTRA_NAME = {
  'Erin Kasch': { url: 'https://www.greenwood.in.gov/officials', file: 'raw/greenwood-in/officials.html', publisher: 'City of Greenwood',
    note: "Former name Erin Betron: the page lists 'Erin Kasch, At-Large' with the address betrone@greenwood.in.gov." },
};

const q = (v) => (v == null ? 'NULL' : `'${String(v).replace(/'/g, "''")}'`);
function splitWayback(u) {
  const m = u.match(/^https?:\/\/web\.archive\.org\/web\/\d+[a-z_]*\/(https?:\/\/.+)$/);
  return m ? { url: m[1], archive_url: u } : { url: u, archive_url: null };
}
function retrieved(file) {
  const f = file && path.join(DIR, file);
  if (!f || !fs.existsSync(f)) throw new Error(`no saved copy: ${file}`);
  return fs.statSync(f).mtime.toISOString().slice(0, 10);
}
function pageTitle(file) {
  if (!file || !/\.html?$/i.test(file)) return null;
  const t = fs.readFileSync(path.join(DIR, file), 'utf8').match(/<title[^>]*>([\s\S]*?)<\/title>/i);
  if (!t) return null;
  const s = t[1].replace(/&amp;/g, '&').replace(/&#0?39;|&rsquo;/g, "'").replace(/&nbsp;/g, ' ').replace(/&[a-z]+;/g, ' ').replace(/\s+/g, ' ').trim();
  return s ? s.slice(0, 200) : null;
}

const holder = [], structure = [], boundary = [], vacancy = [], names = [];
for (const s of S) {
  const j = JSON.parse(fs.readFileSync(path.join(DIR, 'cities', `${s.slug}.json`), 'utf8'));
  const gov = `City of ${s.name}, Indiana, US`, pub = `City of ${s.name}`;
  const st = j.structure;
  structure.push({ gov, ...splitWayback(st.source_url), title: pageTitle(st.source_file), publisher: pub, on: retrieved(st.source_file),
    note: `${s.district_seats} district + ${s.at_large_seats} at-large council seats, ${s.clerk_title}` });
  const cls = s.clerk_title === 'City Clerk' ? IC.second : IC.third;
  structure.push({ gov, url: cls.url, archive_url: null, title: cls.title, publisher: 'Indiana General Assembly', on: '2026-11-24',
    note: 'Statutory default; the city page above confirms what the city actually has.' });
  let atl = 0;
  for (const h of j.holders) {
    let geo = s.geoid, ordinal = null;
    const dm = h.office.match(/District (\d+)$/);
    if (dm) geo = `${s.slug}-council-district-${dm[1]}`;
    else if (/At Large$/.test(h.office)) ordinal = ++atl;
    const key = `${s.slug}|${h.office}`;
    if (EXTRA_VACANCY[key]) {
      const v = EXTRA_VACANCY[key];
      vacancy.push({ gov, geo, title: h.office, ordinal, of: s.at_large_seats, url: v.url, archive_url: null, ttl: v.title, publisher: v.publisher, on: retrieved(v.file), note: v.note });
      continue;
    }
    const row = { gov, geo, title: h.office, ordinal, of: s.at_large_seats, name: h.name, ...splitWayback(h.source_url),
      ttl: pageTitle(h.source_file), publisher: /web\.archive\.org/.test(h.source_url) ? `${pub} (via the Wayback Machine)` : pub,
      on: retrieved(h.source_file), note: h.note ? h.note.slice(0, 300) : null };
    holder.push(row);
    if (EXTRA_NAME[h.name]) {
      const n = EXTRA_NAME[h.name];
      names.push({ gov, geo, title: h.office, ordinal, of: s.at_large_seats, name: h.name, url: n.url, archive_url: null, ttl: pageTitle(n.file), publisher: n.publisher, on: retrieved(n.file), note: n.note });
    }
  }
  const m = MAPS.find((x) => x.slug === s.slug);
  if (!m) throw new Error(`${s.slug}: no council-maps.json entry`);
  for (let d = 1; d <= s.district_seats; d++) {
    const layer = m.layers ? m.layers.find((l) => l.key === d)?.url : m.url;
    if (!layer) throw new Error(`${s.slug}: no layer for district ${d}`);
    boundary.push({ geo: `${s.slug}-council-district-${d}`, url: layer, title: `${s.name} council district ${d}: ArcGIS map service`, publisher: null, on: '2026-11-24', note: m.source_note });
  }
}

// One VALUES list per claim, joined to the record it describes. at-large offices are told apart by the internal
// ordinal the structure migration wrote into description.
const officeJoin = (alias) => `
JOIN essentials.governments g ON g.name = ${alias}.gov
JOIN essentials.chambers c ON c.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = ${alias}.title
 AND (${alias}.ordinal IS NULL OR o.description LIKE 'Internal ordinal ' || ${alias}.ordinal || ' of ' || ${alias}.of_n || '.%')
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = ${alias}.geo AND d.district_type = 'LOCAL' AND lower(d.state) = 'in'`;
const ins = `INSERT INTO essentials.citations (subject_type, subject_id, claim, url, title, publisher, retrieved_on, archive_url, note, added_by)`;
const conflict = `ON CONFLICT (subject_type, subject_id, claim, url) DO NOTHING;`;
const cols = `(gov, geo, title, ordinal, of_n, name, url, archive_url, ttl, publisher, on_day, note)`;
const vrow = (r) => `  (${q(r.gov)}, ${q(r.geo)}, ${q(r.title)}, ${r.ordinal ?? 'NULL'}, ${r.ordinal ? r.of : 'NULL'}, ${q(r.name ?? null)}, ${q(r.url)}, ${q(r.archive_url)}, ${q(r.ttl)}, ${q(r.publisher)}, DATE ${q(r.on)}, ${q(r.note)})`;
const govs = S.map((s) => q(`City of ${s.name}, Indiana, US`)).join(', ');
const expected = holder.length + structure.length + boundary.length + vacancy.length + names.length;

const sql = `-- ${SLOT}_${SUFFIX}.sql
-- Slot RESERVED from the allocator. Records in essentials.citations (CA_0420) the source behind every fact
-- the Indiana cities Wave A migrations wrote for ${S.map((s) => s.name).join(', ')}.
-- Generated by backend/data/seed-in-cities-wave-a/gen-citations.mjs from the per-city files that
-- verify-collect.mjs checked; read that script's header for how each row is found.
--
--   holder     ${String(holder.length).padStart(3)} office_term rows   the page naming the current holder
--   structure  ${String(structure.length).padStart(3)} government rows    the city's own page + the Indiana Code section
--   boundary   ${String(boundary.length).padStart(3)} boundary rows      the map service each council district was loaded from
--   vacancy    ${String(vacancy.length).padStart(3)} office rows
--   name       ${String(names.length).padStart(3)} politician rows
--   total      ${String(expected).padStart(3)}
--
-- 🔴 A holder citation is attached to the CURRENT term of its office, and the post-verify asserts that the
-- person in that term carries the name the page printed (folded for case, nicknames and suffixes) --
-- otherwise a citation would vouch for the wrong person and nothing would error.
-- ⚠ A page read only through the Wayback Machine (the city site refused this machine) is recorded with the
-- city's ORIGINAL address in url and the snapshot in archive_url.
-- ⚠ retrieved_on is the day the saved copy was written; the Indiana Code rows carry the day it was read.
-- Requires CA_0420. Idempotent: ON CONFLICT on (subject_type, subject_id, claim, url).

BEGIN;

CREATE TEMP TABLE c_holder ${cols.replace(/(\w+)(?=[,)])/g, (w) => w)} ON COMMIT DROP AS
SELECT * FROM (VALUES
${holder.map(vrow).join(',\n')}
) AS v${cols};

${ins}
SELECT 'office_term', ot.id, 'holder', h.url, h.ttl, h.publisher, h.on_day, h.archive_url, h.note, ${q(SLOT)}
FROM c_holder h${officeJoin('h')}
JOIN essentials.office_terms ot ON ot.office_id = o.id AND ot.term_end IS NULL AND ot.politician_id IS NOT NULL
${conflict}

${ins}
SELECT 'government', g.id, 'structure', v.url, v.ttl, v.publisher, v.on_day, v.archive_url, v.note, ${q(SLOT)}
FROM (VALUES
${structure.map((r) => `  (${q(r.gov)}, ${q(r.url)}, ${q(r.archive_url)}, ${q(r.title)}, ${q(r.publisher)}, DATE ${q(r.on)}, ${q(r.note)})`).join(',\n')}
) AS v(gov, url, archive_url, ttl, publisher, on_day, note)
JOIN essentials.governments g ON g.name = v.gov
${conflict}

${ins}
SELECT 'geofence_boundary', gb.id, 'boundary', v.url, v.ttl, v.publisher, v.on_day, NULL, v.note, ${q(SLOT)}
FROM (VALUES
${boundary.map((r) => `  (${q(r.geo)}, ${q(r.url)}, ${q(r.title)}, ${q(r.publisher)}, DATE ${q(r.on)}, ${q(r.note)})`).join(',\n')}
) AS v(geo, url, ttl, publisher, on_day, note)
JOIN essentials.geofence_boundaries gb ON gb.geo_id = v.geo AND gb.mtfcc = 'X0091'
${conflict}
${vacancy.length ? `
${ins}
SELECT 'office', o.id, 'vacancy', h.url, h.ttl, h.publisher, h.on_day, h.archive_url, h.note, ${q(SLOT)}
FROM (VALUES
${vacancy.map(vrow).join(',\n')}
) AS h${cols}${officeJoin('h')}
${conflict}
` : ''}${names.length ? `
${ins}
SELECT 'politician', ot.politician_id, 'name', h.url, h.ttl, h.publisher, h.on_day, h.archive_url, h.note, ${q(SLOT)}
FROM (VALUES
${names.map(vrow).join(',\n')}
) AS h${cols}${officeJoin('h')}
JOIN essentials.office_terms ot ON ot.office_id = o.id AND ot.term_end IS NULL AND ot.politician_id IS NOT NULL
${conflict}
` : ''}
-- ─── Post-verify ─────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_orphan int; v_wrong text; v_vac int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.citations WHERE added_by = ${q(SLOT)};
  IF v_n <> ${expected} THEN RAISE EXCEPTION '${SLOT}: % citations written, expected ${expected}', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.citations WHERE added_by = ${q(SLOT)} AND claim = 'holder';
  IF v_n <> ${holder.length} THEN RAISE EXCEPTION '${SLOT}: % holder citations, expected ${holder.length} (an office had no current term?)', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.citations WHERE added_by = ${q(SLOT)} AND claim = 'boundary';
  IF v_n <> ${boundary.length} THEN RAISE EXCEPTION '${SLOT}: % boundary citations, expected ${boundary.length} (a district map is not loaded?)', v_n; END IF;

  -- Every subject exists (the table has no foreign key, so this is the only guard).
  SELECT count(*) INTO v_orphan FROM essentials.citations c WHERE c.added_by = ${q(SLOT)} AND NOT CASE c.subject_type
      WHEN 'office_term'       THEN EXISTS (SELECT 1 FROM essentials.office_terms x WHERE x.id = c.subject_id)
      WHEN 'office'            THEN EXISTS (SELECT 1 FROM essentials.offices x WHERE x.id = c.subject_id)
      WHEN 'government'        THEN EXISTS (SELECT 1 FROM essentials.governments x WHERE x.id = c.subject_id)
      WHEN 'geofence_boundary' THEN EXISTS (SELECT 1 FROM essentials.geofence_boundaries x WHERE x.id = c.subject_id)
      WHEN 'politician'        THEN EXISTS (SELECT 1 FROM essentials.politicians x WHERE x.id = c.subject_id)
      ELSE false END;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '${SLOT}: % citations point at no record', v_orphan; END IF;

  -- A holder citation must vouch for the person actually seated: compare surnames, folded.
  SELECT string_agg(h.name || ' vs ' || p.full_name, '; ') INTO v_wrong
  FROM c_holder h${officeJoin('h')}
  JOIN essentials.office_terms ot ON ot.office_id = o.id AND ot.term_end IS NULL
  JOIN essentials.politicians p ON p.id = ot.politician_id
  WHERE position(lower(p.last_name) IN lower(h.name)) = 0;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION '${SLOT}: holder citation names a different person than the seat holds: %', v_wrong; END IF;

  -- Every office in these cities is either cited as held or cited as vacant.
  SELECT count(*) INTO v_vac FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name IN (${govs})
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot JOIN essentials.citations ci
                       ON ci.subject_type = 'office_term' AND ci.subject_id = ot.id AND ci.claim = 'holder'
                     WHERE ot.office_id = o.id AND ot.term_end IS NULL)
     AND NOT EXISTS (SELECT 1 FROM essentials.citations ci WHERE ci.subject_type = 'office' AND ci.subject_id = o.id AND ci.claim = 'vacancy');
  IF v_vac <> 0 THEN RAISE EXCEPTION '${SLOT}: % offices in these cities have no holder or vacancy citation', v_vac; END IF;

  RAISE NOTICE '${SLOT} OK: ${expected} citations (${holder.length} holder, ${structure.length} structure, ${boundary.length} boundary, ${vacancy.length} vacancy, ${names.length} name), 0 orphans, every office cited';
END $$;

COMMIT;
`;
const out = path.resolve(DIR, '../../migrations', `${SLOT}_${SUFFIX}.sql`);
fs.writeFileSync(out, sql);
console.log(`wrote ${out}: ${expected} citations (${holder.length} holder, ${structure.length} structure, ${boundary.length} boundary, ${vacancy.length} vacancy, ${names.length} name)`);
