/**
 * OREGON PRE-SEATING SWEEP
 *
 * Finds published stance rows that cite a legislative session the politician did
 * not serve in — i.e. a vote attributed to someone who was not yet in office.
 * These are fabrications regardless of how real the cited URL is, which is why
 * neither the Phase 149 "0-unsourced" gate nor the quote-matcher catches them.
 *
 * Ground truth is the OLIS OData `Legislators` table: it lists every session each
 * member actually served, so no hand-collected term_start list is needed.
 *
 *   node scripts/sweep-or-preseating.mjs            # report only
 *   node scripts/sweep-or-preseating.mjs --json out.json
 *
 * Writes nothing to the DB. Retirement is a separate, explicit step.
 */
import 'dotenv/config';
import { writeFileSync, readFileSync, existsSync } from 'fs';
import { Pool } from 'pg';

const OD = 'https://api.oregonlegislature.gov/odata/ODataService.svc';
const SESSION_RE = /\b((?:19|20)\d{2})\s?([RSI]\d)\b/g;

// Normalise a person name for matching: drop punctuation, then drop bare middle
// initials so "James I. Manning Jr." == OLIS's "James" + "Manning Jr.".
// Suffixes (jr/sr/ii/iii) are KEPT — they distinguish real people.
// NFKD then DELETE the combining marks (not replace with space) — otherwise
// "Nguyễn" decomposes and becomes "nguye n", which no longer matches OLIS's
// "Nguyen" and shows up as a spurious unmatched row.
const norm = (s) => (s || '').toLowerCase().normalize('NFKD')
  .replace(/[̀-ͯ]/g, '')
  .replace(/[^a-z ]/g, ' ').replace(/\s+/g, ' ').trim();
const nameKey = (s) => {
  const parts = norm(s).split(' ').filter((w) => w.length > 1);
  return parts.join(' ');
};

// ---- 1. OLIS ground truth -------------------------------------------------
// Cached + retried: the OData host intermittently drops connections, and a
// half-fetched roster would silently mark served sessions as "not served".
const CACHE = 'data/stance-research/or-bend-stateleg/.olis-legislators.json';
async function olisRoster() {
  if (existsSync(CACHE)) {
    const c = JSON.parse(readFileSync(CACHE, 'utf8'));
    if (c?.value?.length > 2000) {
      console.log(`OLIS roster from cache (${CACHE})`);
      return c.value;
    }
  }
  let lastErr;
  for (let i = 1; i <= 4; i++) {
    try {
      const res = await fetch(`${OD}/Legislators?$format=json`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const j = await res.json();
      if (!(j?.value?.length > 2000)) throw new Error(`short roster: ${j?.value?.length}`);
      writeFileSync(CACHE, JSON.stringify(j));
      return j.value;
    } catch (e) {
      lastErr = e;
      console.log(`  OLIS fetch attempt ${i} failed (${e.message}); retrying...`);
      await new Promise((r) => setTimeout(r, 1500 * i));
    }
  }
  throw new Error(`could not fetch OLIS roster: ${lastErr?.message}`);
}
const legs = await olisRoster();
const byName = new Map();           // "first last" -> {sessions:Set, codes:Set, meta}
const byLast = new Map();           // "last" -> [entries]
for (const l of legs) {
  const key = nameKey(`${l.FirstName} ${l.LastName}`);
  if (!byName.has(key)) {
    byName.set(key, { sessions: new Set(), codes: new Set(), first: l.FirstName,
                      last: l.LastName, chambers: new Set(), districts: new Set(),
                      parties: new Set() });
  }
  const e = byName.get(key);
  e.sessions.add(l.SessionKey);
  if (l.LegislatorCode) e.codes.add(l.LegislatorCode);
  if (l.Chamber) e.chambers.add(l.Chamber);
  if (l.DistrictNumber) e.districts.add(String(l.DistrictNumber));
  if (l.Party) e.parties.add(l.Party);
  const lk = nameKey(l.LastName);
  if (!byLast.has(lk)) byLast.set(lk, new Set());
  byLast.get(lk).add(key);
}
console.log(`OLIS: ${legs.length} legislator-session rows -> ${byName.size} distinct people`);

// ---- 2. candidate rows from the DB ---------------------------------------
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows } = await pool.query(`
  SELECT p.external_id, p.full_name, p.id AS pid,
         o.title, o.representing_state,
         t.topic_key, pa.value, pc.sources, pc.reasoning
    FROM inform.politician_context pc
    JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
    JOIN inform.compass_topics t     ON t.id = pc.topic_id
    JOIN essentials.politicians p    ON p.id = pc.politician_id
    LEFT JOIN essentials.offices o   ON o.politician_id = p.id
   -- Deliberately POSIX classes, no backslash escapes: this SQL sits in a JS
   -- template literal, where 'y' and 'd' collapse to 'y' and 'd' and silently
   -- match nothing. SESSION_RE below does the precise extraction, so a slightly
   -- loose prefilter here is safe.
   WHERE (array_to_string(pc.sources,' ') || ' ' || coalesce(pc.reasoning,''))
           ~ '(19|20)[0-9]{2}[[:space:]]?[RSI][0-9]'
     -- Oregon STATE legislature only. Without this, other states leak in and get
     -- mis-matched to an Oregon homonym: a Utah rep named Jason E. Thompson was
     -- matched to Oregon's Jim Thompson (both district 23) and wrongly flagged.
     AND o.representing_state = 'OR'
     AND o.title IN ('Representative', 'Senator')
   ORDER BY p.full_name, t.topic_key`);
console.log(`DB: ${rows.length} context rows cite a session code\n`);

// ---- 3. classify ---------------------------------------------------------
const out = { generated_for: 'oregon pre-seating sweep', bad: [], unmatched: [], clean: 0 };
const seenUnmatched = new Map();

for (const r of rows) {
  const blob = `${(r.sources || []).join(' ')} ${r.reasoning || ''}`;
  const cited = [...new Set([...blob.matchAll(SESSION_RE)].map((m) => `${m[1]}${m[2]}`))];
  if (!cited.length) { out.clean++; continue; }

  const key = nameKey(r.full_name);
  let entry = byName.get(key);
  if (!entry) {
    // Last-name fallback ONLY with corroboration. A bare "one candidate with
    // this surname" rule is what mis-matched the Utah Jason E. Thompson onto
    // Oregon's Jim Thompson. Require the first initial to agree.
    const parts = nameKey(r.full_name).split(' ');
    const cands = byLast.get(parts[parts.length - 1]) || byLast.get(parts.slice(-2).join(' '));
    if (cands) {
      const ok = [...cands].map((k) => byName.get(k))
        .filter((e) => nameKey(e.first)[0] === parts[0][0]);
      if (ok.length === 1) entry = ok[0];
    }
  }
  if (!entry) {
    const k = `${r.full_name}|${r.title || ''}`;
    if (!seenUnmatched.has(k)) {
      seenUnmatched.set(k, true);
      out.unmatched.push({ external_id: r.external_id, full_name: r.full_name,
                           title: r.title, state: r.representing_state, cited });
    }
    continue;
  }
  const notServed = cited.filter((c) => !entry.sessions.has(c));
  if (notServed.length) {
    const served = [...entry.sessions].sort();
    out.bad.push({
      external_id: r.external_id, full_name: r.full_name, title: r.title,
      topic_key: r.topic_key, value: Number(r.value),
      cited, not_served: notServed,
      earliest_served: served[0], served_count: served.length,
      olis: `${[...entry.chambers].join('/')} dist ${[...entry.districts].join('/')} ${[...entry.parties].join('/')}`,
      sources: r.sources, reasoning: (r.reasoning || '').slice(0, 240),
    });
  } else out.clean++;
}

// ---- 4. report -----------------------------------------------------------
console.log(`PRE-SEATING FAILURES: ${out.bad.length} rows across ` +
            `${new Set(out.bad.map((b) => b.external_id)).size} politicians`);
const byPerson = new Map();
for (const b of out.bad) {
  if (!byPerson.has(b.full_name)) byPerson.set(b.full_name, []);
  byPerson.get(b.full_name).push(b);
}
for (const [name, list] of [...byPerson].sort((a, b) => b[1].length - a[1].length)) {
  const e = list[0];
  console.log(`\n  ${name}  (${e.olis}; earliest session served ${e.earliest_served})`);
  for (const b of list) {
    console.log(`     ${b.topic_key} = ${b.value}  cites ${b.not_served.join(',')} ` +
                `<- NOT SERVED`);
  }
}
console.log(`\nCLEAN (every cited session was served): ${out.clean}`);
console.log(`UNMATCHED against OLIS (likely federal or a name variant): ${out.unmatched.length}`);
for (const u of out.unmatched) console.log(`   ${u.full_name} | ${u.title} | ${u.state} | cites ${u.cited.join(',')}`);

const jsonIdx = process.argv.indexOf('--json');
if (jsonIdx > -1 && process.argv[jsonIdx + 1]) {
  writeFileSync(process.argv[jsonIdx + 1], JSON.stringify(out, null, 2));
  console.log(`\nwrote ${process.argv[jsonIdx + 1]}`);
}
await pool.end();
