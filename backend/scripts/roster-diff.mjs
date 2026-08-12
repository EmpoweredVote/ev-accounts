#!/usr/bin/env node
/**
 * Diff our seated state-legislature roster against an external current-roster source, per chamber.
 *
 * WHY THIS EXISTS: TX SD-22 carried Brian Birdwell for 77 days after he resigned (migration 1712).
 * Nothing errored — an officeholder who has left just keeps resolving through
 * essentials.office_current_holder. The only thing that catches it is comparing our roster against
 * somebody else's.
 *
 * 🔑 THE PRIMARY CHECK IS A NAME-SET DIFF PER CHAMBER, NOT A PER-DISTRICT JOIN.
 * District labels are wildly heterogeneous across states — MA uses named districts
 * ("Barnstable-Dukes-Nantucket District"), MD has A/B/C subdistricts, AZ's House is two members to
 * a district, and our own labels drift ("State Senate District 9" vs "California State Senate
 * district 20"). Joining on district would need per-state mapping and would fail closed on the
 * states most likely to be wrong. A set difference over names answers the question that actually
 * matters — do we hold the right PEOPLE — and needs no mapping at all:
 *   - in theirs, not ours  -> we are missing someone, or hold a predecessor
 *   - in ours, not theirs  -> we hold someone who has LEFT   <-- the Birdwell class
 * A per-district multiset check runs as a SECOND pass, to catch a right-person-wrong-seat error
 * that the name set alone cannot see. districtKey() normalizes both sides' district naming — MA's
 * place names included — so no state is excluded from it.
 *
 * 🔴 THIS IS A DETECTOR, NOT AN ORACLE. Open States is a third party; "their roster disagrees" is a
 * reading queue, not a verdict. Every hit must be confirmed against the chamber's OWN roster before
 * anyone writes to office_terms. Name-form variance is rampant and expected (Ben/Benjamin,
 * R.D. "Bobby"/Robert, dropped diacritics) — the script classifies those separately so they do not
 * drown the real findings, but the classifier is a triage aid and nothing more.
 *
 *   node scripts/roster-diff.mjs                # all states we hold a full chamber for
 *   node scripts/roster-diff.mjs tx ca          # just these
 *   node scripts/roster-diff.mjs --verbose      # also list the cosmetic name-form differences
 */
import 'dotenv/config';
import { Pool } from 'pg';

const ALL_STATES = ['az', 'ca', 'ma', 'md', 'me', 'nv', 'or', 'tx', 'ut', 'va', 'wi'];

const argv = process.argv.slice(2);
const VERBOSE = argv.includes('--verbose');
const states = argv.filter((a) => !a.startsWith('--')).map((s) => s.toLowerCase());
const TARGETS = states.length ? states : ALL_STATES;

/** Reported per chamber so the output says which naming scheme districtKey() resolved to. */
const kindOf = (keys) =>
  keys.every((k) => k == null || /^\d+[A-Z]?$/.test(k)) ? 'numeric' : 'named';

// ---------------------------------------------------------------------------------------------
// name normalization -- proven against benign variations and real differences before use
// ---------------------------------------------------------------------------------------------
const SUFFIX = /\b(jr|sr|ii|iii|iv|v|md|phd|dds|esq)\b/g;

/**
 * 🔴 ORDER IS LOAD-BEARING. NFD decomposes "ñ" into "n" + U+0303, so the combining marks must be
 * DELETED (empty string) before the non-letter strip. Replacing them with a space instead turns
 * Muñoz into "mun oz" and Gámez into "ga mez", which then fail to match our already-ASCII rows —
 * 8 false positives in the TX control, every one of them a real sitting member.
 */
function normName(s) {
  return String(s || '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')   // delete combining marks, do NOT space them
    .toLowerCase()
    .replace(/[^a-z ]/g, ' ')          // punctuation, quotes, digits
    .replace(SUFFIX, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** "Last, First" -> "First Last". Open States ships "First Last" already; our rows vary. */
function flip(name) {
  const i = String(name).indexOf(',');
  if (i < 0) return String(name).trim();
  return `${String(name).slice(i + 1).trim()} ${String(name).slice(0, i).trim()}`.trim();
}

const key = (n) => normName(flip(n));

/** Last token = family name, for the cosmetic-vs-real triage. */
const family = (k) => k.split(' ').filter(Boolean).slice(-1)[0] || '';
const givens = (k) => k.split(' ').filter(Boolean).slice(0, -1);

/**
 * Same human, different rendering? Family name must match exactly; then accept if any given-name
 * pair shares a first initial and one is a prefix of the other (Ben/Benjamin, Wes/Wesley), or if
 * one side's given names are a subset of the other's (dropped middle name / added nickname).
 * Deliberately CONSERVATIVE -- when unsure it returns false, so the row surfaces as real.
 */
function looksCosmetic(a, b) {
  if (family(a) !== family(b)) return false;
  const ga = givens(a);
  const gb = givens(b);
  if (!ga.length || !gb.length) return false;
  const setA = new Set(ga);
  const setB = new Set(gb);
  if ([...setA].every((x) => setB.has(x)) || [...setB].every((x) => setA.has(x))) return true;
  return ga.some((x) =>
    gb.some((y) => x[0] === y[0] && (x.startsWith(y) || y.startsWith(x))));
}

// ---------------------------------------------------------------------------------------------
// sources
// ---------------------------------------------------------------------------------------------
async function fetchOfficial(state) {
  const url = `https://data.openstates.org/people/current/${state}.csv`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${state}: openstates returned HTTP ${res.status}`);
  const text = await res.text();
  // A WAF rejection can be HTTP 200 -- never judge by res.ok alone.
  if (!/^id,name,current_party,current_district,current_chamber/.test(text)) {
    throw new Error(`${state}: unexpected payload (first 120 chars): ${text.slice(0, 120)}`);
  }
  return parseCsv(text);
}

/** Minimal RFC4180 parser -- fields contain commas and quotes (addresses, nicknames). */
function parseCsv(text) {
  const rows = [];
  let row = [];
  let f = '';
  let q = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (q) {
      if (c === '"') {
        if (text[i + 1] === '"') { f += '"'; i++; } else { q = false; }
      } else f += c;
    } else if (c === '"') q = true;
    else if (c === ',') { row.push(f); f = ''; }
    else if (c === '\n') { row.push(f); rows.push(row); row = []; f = ''; }
    else if (c !== '\r') f += c;
  }
  if (f.length || row.length) { row.push(f); rows.push(row); }
  const head = rows.shift();
  return rows
    .filter((r) => r.length > 1)
    .map((r) => Object.fromEntries(head.map((h, i) => [h, r[i] ?? ''])));
}

const CHAMBER = { upper: 'STATE_UPPER', lower: 'STATE_LOWER' };

async function fetchOurs(pool, stateList) {
  const { rows } = await pool.query(
    `SELECT lower(d.state) AS state,
            d.district_type AS chamber,
            d.label,
            p.full_name AS name
       FROM essentials.offices o
       JOIN essentials.districts d ON d.id = o.district_id
       JOIN essentials.office_current_holder och ON och.office_id = o.id
       JOIN essentials.politicians p ON p.id = och.politician_id
      WHERE d.district_type IN ('STATE_UPPER','STATE_LOWER')
        AND lower(d.state) = ANY($1)
        -- office_current_holder LEFT JOINs from offices: a vacancy is a NULL politician_id, not an
        -- absent row. Without this the vacant seats would join in as phantom holders.
        AND och.politician_id IS NOT NULL`,
    [stateList],
  );
  return rows;
}

/**
 * One district key for BOTH sides, covering every naming scheme in play:
 *   ours "State House District 19" / theirs "19"                      -> "19"
 *   ours "State Legislative Subdistrict 9B" / theirs "9B"             -> "9B"
 *   ours "California State Senate district 20" / theirs "20"          -> "20"
 *   ours "10th Bristol District" / theirs "10th Bristol"              -> "10th bristol"
 *   ours "Barnstable-Dukes-Nantucket District"
 *        / theirs "Barnstable, Dukes and Nantucket"                   -> "barnstable dukes nantucket"
 * Chamber words and connectives are dropped, then tokens are SORTED so that hyphen-vs-comma-and
 * orderings collapse to the same key. This is what lets MA -- whose districts are place names --
 * use the same same-seat logic as the numeric states instead of being excluded from it.
 */
const DISTRICT_STOPWORDS = new Set([
  'state', 'house', 'senate', 'assembly', 'legislative', 'district', 'subdistrict', 'districts',
  'representative', 'representatives', 'general', 'court', 'and', 'of', 'the', 'in',
  // state names leak into a few of our labels
  'california', 'texas', 'massachusetts', 'maryland', 'maine', 'virginia', 'wisconsin',
  'arizona', 'nevada', 'oregon', 'utah',
]);

/**
 * `state` is required so the state's OWN USPS code can be dropped: our TX labels read
 * "TX Senate District 22", and leaving "tx" in produced the key "1 tx" instead of "1" — which made
 * all 181 TX districts mismatch at once. Caught only because the TX control was re-run after the
 * change. Dropping the one relevant code beats blanket-listing all 50, which would eat a district
 * whose place name happens to be two letters.
 */
function districtKey(raw, state) {
  const toks = String(raw || '')
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim()
    .split(' ')
    .filter((t) => t && !DISTRICT_STOPWORDS.has(t) && t !== state);
  if (!toks.length) return null;
  // A lone number, or a number with a subdistrict letter ("9b", or "9" + "b").
  const joined = toks.join('');
  const num = joined.match(/^(\d+)([a-z])?$/);
  if (num) return num[1] + (num[2] ? num[2].toUpperCase() : '');
  return toks.slice().sort().join(' ');
}

// ---------------------------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------------------------
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const ours = await fetchOurs(pool, TARGETS);
await pool.end();
if (!ours.length) {
  console.error(`no seated rows found for: ${TARGETS.join(', ')}`);
  process.exit(1);
}

const findings = [];
let cosmeticTotal = 0;
const summary = [];

for (const state of TARGETS) {
  let official;
  try {
    official = await fetchOfficial(state);
  } catch (e) {
    summary.push({ state, chamber: '-', note: `SOURCE FAILED: ${e.message}` });
    continue;
  }

  for (const [osCham, ourCham] of Object.entries(CHAMBER)) {
    const theirs = official
      .filter((r) => r.current_chamber === osCham && r.name)
      .map((r) => ({ name: r.name, district: districtKey(r.current_district, state) }));
    const mine = ours
      .filter((r) => r.state === state && r.chamber === ourCham)
      .map((r) => ({ name: r.name, district: districtKey(r.label, state), label: r.label }));

    if (!theirs.length && !mine.length) continue;

    // ---- pass 1: name sets ----
    const byKeyTheirs = new Map();
    for (const r of theirs) {
      const k = key(r.name);
      if (!byKeyTheirs.has(k)) byKeyTheirs.set(k, []);
      byKeyTheirs.get(k).push(r);
    }
    const byKeyMine = new Map();
    for (const r of mine) {
      const k = key(r.name);
      if (!byKeyMine.has(k)) byKeyMine.set(k, []);
      byKeyMine.get(k).push(r);
    }

    let onlyTheirs = [...byKeyTheirs.keys()].filter((k) => !byKeyMine.has(k));
    let onlyMine = [...byKeyMine.keys()].filter((k) => !byKeyTheirs.has(k));

    // Pair off cosmetic renderings of the same person so they do not read as a departure plus an
    // arrival. Greedy first match is fine: family name must already be identical.
    const cosmetic = [];
    for (const a of [...onlyMine]) {
      const hit = onlyTheirs.find((b) => looksCosmetic(a, b));
      if (hit) {
        cosmetic.push([a, hit]);
        onlyMine = onlyMine.filter((x) => x !== a);
        onlyTheirs = onlyTheirs.filter((x) => x !== hit);
      }
    }
    // Second pairing pass: same surname AND same district. A nickname substitution
    // (Armando/"Mando", R.D./"Bobby", Elizabeth/"Liz") shares no first initial, so the prefix rule
    // above cannot catch it -- but two people of the same surname holding the same seat is not a
    // thing. Kept as its own reported class rather than folded into cosmetic: the evidence is
    // strong, not conclusive, and silently swallowing it would be the wrong kind of confident.
    const nicknames = [];
    {
      for (const a of [...onlyMine]) {
        const mineRows = byKeyMine.get(a);
        const hit = onlyTheirs.find((b) =>
          family(a) === family(b)
          && byKeyTheirs.get(b).some((tr) => mineRows.some((mr) => mr.district === tr.district)));
        if (hit) {
          nicknames.push([a, hit]);
          onlyMine = onlyMine.filter((x) => x !== a);
          onlyTheirs = onlyTheirs.filter((x) => x !== hit);
        }
      }
    }

    cosmeticTotal += cosmetic.length;
    for (const [a, b] of nicknames) {
      const d = byKeyMine.get(a)[0];
      findings.push({
        state, chamber: ourCham, issue: 'NICKNAME? same seat, same surname',
        ours: byKeyMine.get(a).map((r) => r.name)[0],
        official: byKeyTheirs.get(b).map((r) => r.name)[0],
        where: d.label,
      });
    }

    for (const k of onlyMine) {
      for (const r of byKeyMine.get(k)) {
        findings.push({
          state, chamber: ourCham, issue: 'WE HOLD SOMEONE THEY DO NOT LIST',
          ours: r.name, official: '-', where: r.label,
        });
      }
    }
    for (const k of onlyTheirs) {
      for (const r of byKeyTheirs.get(k)) {
        // Say who WE have in that seat. If it is VACANT, the likeliest reading is that their
        // snapshot is STALE and we are already correct -- which is exactly what TX SD-22 shows
        // after migration 1712. Without this column that case is indistinguishable from a
        // successor we failed to seat.
        const inSeat = mine.filter((m) => m.district === r.district).map((m) => m.name);
        findings.push({
          state, chamber: ourCham, issue: 'THEY LIST SOMEONE WE DO NOT HOLD',
          ours: inSeat.length ? inSeat.join(' + ') : '** WE HAVE THIS SEAT VACANT **',
          official: r.name, where: `district ${r.district}`,
        });
      }
    }

    // ---- pass 2: per-district multiset, numeric-district states only ----
    let seatMismatch = 0;
    {
      const groupT = new Map();
      for (const r of theirs) {
        const d = r.district;
        if (!groupT.has(d)) groupT.set(d, []);
        groupT.get(d).push(key(r.name));
      }
      const groupM = new Map();
      for (const r of mine) {
        const d = r.district;
        if (d == null) continue;
        if (!groupM.has(d)) groupM.set(d, []);
        groupM.get(d).push(key(r.name));
      }
      const cosMap = new Map(cosmetic.map(([mineK, theirK]) => [mineK, theirK]));
      for (const [d, mineKeys] of groupM) {
        const theirKeys = (groupT.get(d) || []).slice();
        for (const mk of mineKeys) {
          const want = cosMap.get(mk) || mk;         // compare through the cosmetic pairing
          const at = theirKeys.indexOf(want);
          if (at >= 0) { theirKeys.splice(at, 1); continue; }
          // Only a real finding if they DO list this person, just in another district.
          const elsewhere = theirs.find((r) => key(r.name) === want && r.district !== d);
          if (elsewhere) {
            seatMismatch++;
            findings.push({
              state, chamber: ourCham, issue: 'RIGHT PERSON, DIFFERENT DISTRICT',
              ours: mk, official: `${elsewhere.name} @ district ${elsewhere.district}`,
              where: `we have district ${d}`,
            });
          }
        }
      }
    }

    summary.push({
      state,
      chamber: ourCham === 'STATE_UPPER' ? 'upper' : 'lower',
      ours: mine.length,
      theirs: theirs.length,
      cosmetic: cosmetic.length,
      flagged: onlyMine.length + onlyTheirs.length + seatMismatch,
      districts: kindOf(mine.map((m) => m.district)),
    });

    if (VERBOSE && cosmetic.length) {
      for (const [a, b] of cosmetic) {
        console.log(`   cosmetic  ${state} ${osCham}: ours "${a}"  vs theirs "${b}"`);
      }
    }
  }
}

console.log('\n=== per-chamber summary ===');
console.table(summary);

console.log(`\ncosmetic name-form differences (same person, not reported): ${cosmeticTotal}`);
console.log(`REAL findings needing verification against the chamber's own roster: ${findings.length}`);
if (findings.length) {
  console.log('\n=== findings ===');
  console.table(findings);
  console.log(
    '\n🔴 Each row above is a READING QUEUE ENTRY, not a verdict. Confirm against the chamber\'s\n'
    + '   own roster before touching office_terms. "They list someone we do not hold" is often a\n'
    + '   successor we simply have not seated; "we hold someone they do not list" is the Birdwell\n'
    + '   class and the one that renders a departed member as sitting.',
  );
}
