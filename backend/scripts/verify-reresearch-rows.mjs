// Verify a re-research CSV before it becomes a migration:
//  1. it parses into exactly the expected 7 columns
//  2. value is a discrete integer 1-5 (never fractional — the CHECK permits 0.5 steps, so the guard
//     has to live outside the schema)
//  3. the politician resolves to exactly one essentials.politicians row, and the topic_key to one
//     topic the OPEN SEASON asks, whose compass_topic_roles admit THAT politician's tier
//  4. every cited URL is fetched and every distinctive claim term in the reasoning appears in its RAW
//     HTML — the standard migration 1542 established after a row cited a CRS summary for a claim the
//     bill text did not carry
//
// 🔴 CHECK 3 USED TO REFUSE EVERY NON-LOCAL ROW, AND EVERY SEASON 2 TOPIC. Corrected 2026-09-04.
// This script was written for a local roster and had both halves of check 3 hardcoded to that
// cohort. Neither failure was visible while it was only ever pointed at local CSVs:
//
//   · TIER. It asserted `scopes.includes('local')` — literally "would never display" for any topic
//     that excludes the local tier. Border Security, Defense Spending, Foreign Military
//     Intervention and U.S. Military Aid to Israel are federal-only, so a federal batch failed
//     every row with a message claiming the TOPIC was misconfigured. The check now resolves the
//     politician's own tier and asks whether the topic admits it, which is what the message
//     always claimed to be testing.
//
//   · LIVENESS. It gated on `compass_topics.is_live`, and 17 of the 60 topics season 2 asks carry
//     is_live = false — every new season 2 topic, including all four federal-only ones. This is
//     the same defect `CC_0066` fixed in `upsert_compass_answer`: a global boolean cannot notice
//     a season. compassService names it twice, CC_0066 was its third instance, and this script was
//     the fourth. The gate is now membership of `inform.compass_topics_promoted` — the set the
//     read path serves. is_live and is_active are still PRINTED, because they are useful context,
//     but they no longer decide anything.
//
// ⚠ TIER RESOLUTION LIVES IN scripts/lib/office-tiers.mjs and is NOT restated here. This script
// held its own copy for exactly one commit, which was already one more copy than the rule can
// survive — office-tiers.mjs exists because the same CASE kept being re-derived slightly
// differently, most consequentially over the two title formats sitting U.S. senators carry.
// It does NOT resolve for a politician with no district — about a quarter of the researched
// corpus — so pass --tier=<federal|state|local|judicial> to declare the batch's cohort. A row
// whose tier cannot be established FAILS rather than passing unchecked; a declared tier that
// disagrees with the resolved one WARNS and the declared value wins, since the operator knows
// which cohort they assembled.
import 'dotenv/config';
import { readFileSync } from 'fs';
import { Pool } from 'pg';
import { crawlSite } from './lib/site-crawl.mjs';
import { COMPASS_TIER_SQL, COMPASS_TIERS as TIERS } from './lib/office-tiers.mjs';

const args = process.argv.slice(2);
const file = args.find((a) => !a.startsWith('--'));
if (!file) {
  console.error('usage: node scripts/verify-reresearch-rows.mjs <csv> [--tier=federal|state|local|judicial]');
  process.exit(1);
}

/** The cohort's tier, declared by the operator. Null means "resolve it per row". */
const declaredTier = (() => {
  const hit = args.find((a) => a.startsWith('--tier='));
  if (!hit) return null;
  const t = hit.slice('--tier='.length);
  if (!TIERS.includes(t)) {
    console.error(`verify-reresearch-rows: --tier must be one of ${TIERS.join(', ')} — got "${t}".`);
    process.exit(1);
  }
  return t;
})();

/**
 * Does a topic's compass_topic_roles admit this tier?
 *
 * The no-rows fallback is NOT symmetric, and copying that asymmetry from compassService is the
 * point: a topic with no role rows is cross-cutting across federal/state/local, but judicial is
 * false, because existing cross-cutting topics must never appear on a judicial profile.
 */
function admitsTier(scopes, tier) {
  if (!scopes || scopes.length === 0) return tier !== 'judicial';
  return scopes.includes(tier);
}

function parseCsv(text) {
  const rows = [];
  let row = [], field = '', inQ = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQ) {
      if (c === '"' && text[i + 1] === '"') { field += '"'; i++; }
      else if (c === '"') inQ = false;
      else field += c;
    } else if (c === '"') inQ = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n') { row.push(field); if (row.some((f) => f.trim())) rows.push(row); row = []; field = ''; }
    else if (c !== '\r') field += c;
  }
  row.push(field);
  if (row.some((f) => f.trim())) rows.push(row);
  return rows;
}

/**
 * Two accepted shapes. The 8-column one leads with `politician_id` and is what
 * cohort-worksheet.mjs emits; the 7-column one is the original and still works.
 *
 * 🔴 WHY THE ID COLUMN EXISTS: full_name IS NOT UNIQUE, AND THE COLLISION IS REAL.
 * Two active people are named "Alex Padilla" — California's U.S. Senator and an
 * Inglewood city councilmember. Name-keyed rows for him resolve to 2 politicians
 * and are refused, which is the correct outcome and also an unfixable one: the
 * 7-column format has no way to say which person is meant. One of the 100 sitting
 * senators collides today, and the number only grows as local rosters load.
 *
 * The refusal is the point. A name that silently matched the FIRST row would put a
 * senator's stance on a city councilmember's compass, and nothing downstream would
 * ever notice — the row is well-formed, well-sourced and about the wrong person.
 */
const COLS_7 = ['full_name', 'topic_key', 'value', 'reasoning', 'source_url_1', 'source_url_2', 'source_url_3'];
const COLS_8 = ['politician_id', ...COLS_7];

const parsed = parseCsv(readFileSync(file, 'utf8'));
const header = parsed[0].map((h) => h.trim());
const shape = header.join(',') === COLS_8.join(',') ? COLS_8
            : header.join(',') === COLS_7.join(',') ? COLS_7
            : null;
if (!shape) {
  console.error(`FAIL header: got ${header.join(',')}`);
  console.error(`  expected either:\n    ${COLS_8.join(',')}\n    ${COLS_7.join(',')}`);
  process.exit(1);
}
const rows = parsed.slice(1).map((r) => Object.fromEntries(shape.map((k, i) => [k, (r[i] ?? '').trim()])));
const KEYED_BY_ID = shape === COLS_8;
console.log(`parsed ${rows.length} row(s), ${header.length} columns — keyed by ${KEYED_BY_ID ? 'politician_id' : 'full_name'}\n`);

// stopwords so "the/and/city" are not treated as distinctive claim terms
const STOP = new Set(('the a an and or of to in on at for with by from as is was were be been it its this that '
  + 'said says which who whom whose what when where while than then there their they them he she his her out into '
  + 'up down over under about after before more most half no not any all each city council plan would could should').split(' '));

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
let failures = 0;

for (const r of rows) {
  console.log('='.repeat(90));
  console.log(`${r.full_name} / ${r.topic_key} = ${r.value}`);

  const v = Number(r.value);
  if (!Number.isInteger(v) || v < 1 || v > 5) { console.log(`  🔴 FAIL value not a discrete 1-5: ${r.value}`); failures++; }

  // Keyed by id, one politician can still have several office_terms rows, so that
  // path collapses to the CURRENT seat (open term first, then latest start) rather
  // than counting rows. Keyed by name, the row count IS the ambiguity check and
  // stays exactly as it was.
  const SELECT_POL = `SELECT p.id, p.full_name, g.name AS government, g.type AS gov_type, o.title, d.ocd_id,
            ${COMPASS_TIER_SQL} AS tier
       FROM essentials.politicians p
       LEFT JOIN essentials.office_terms ot ON ot.politician_id = p.id
       LEFT JOIN essentials.offices o  ON o.id = ot.office_id
       LEFT JOIN essentials.districts d ON d.id = o.district_id
       LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
       LEFT JOIN essentials.governments g ON g.id = c.government_id`;

  const byId = KEYED_BY_ID && r.politician_id;
  let pol = [];
  if (byId) {
    if (!/^[0-9a-f-]{36}$/i.test(r.politician_id)) {
      console.log(`  🔴 FAIL politician_id is not a uuid: ${r.politician_id}`);
      failures++;
    } else {
      // Current seat first: an open term, then the latest start. Several rows here
      // are one person's term history, not an ambiguity, so they collapse rather
      // than fail — which is the whole reason the id column is safer than the name.
      ({ rows: pol } = await pool.query(
        `${SELECT_POL} WHERE p.id = $1::uuid
          ORDER BY (ot.term_end IS NULL) DESC, ot.term_start DESC NULLS LAST`,
        [r.politician_id],
      ));
      if (pol.length === 0) { console.log('  🔴 FAIL politician_id matches no politician'); failures++; }
      else if (pol.length > 1) {
        console.log(`  ⚠ ${pol.length} office terms for this person — using the current seat`);
        pol = [pol[0]];
      }
    }
  } else {
    ({ rows: pol } = await pool.query(`${SELECT_POL} WHERE lower(p.full_name) = lower($1)`, [r.full_name]));
    if (pol.length !== 1) {
      console.log(`  🔴 FAIL politician resolves to ${pol.length} rows`);
      if (pol.length > 1) {
        console.log('     full_name is not unique, and no name can disambiguate it — re-emit this CSV with the');
        console.log('     8-column politician_id shape (cohort-worksheet.mjs produces it). Candidates:');
        for (const c of pol) console.log(`       ${c.id}  ${c.title ?? '(no office)'}  ${c.ocd_id ?? ''}`);
      }
      failures++;
    }
  }

  if (pol.length === 1) {
    console.log(`  politician ${pol[0].id}  ${pol[0].government} — ${pol[0].title}  tier=${pol[0].tier ?? '(unresolved)'}`);
    // The id decides who the row is about; the name is then a cross-check on the
    // row having been assembled correctly, and a mismatch means it was not.
    if (byId && r.full_name && r.full_name.toLowerCase() !== (pol[0].full_name ?? '').toLowerCase()) {
      console.log(`  🔴 FAIL name/id mismatch — id is "${pol[0].full_name}", row says "${r.full_name}"`);
      failures++;
    }
  }

  // The declared cohort wins: the operator knows which set they assembled, and a quarter of the
  // corpus has no district to resolve from. Disagreement is worth saying out loud either way.
  const resolvedTier = pol.length === 1 ? pol[0].tier : null;
  if (declaredTier && resolvedTier && declaredTier !== resolvedTier) {
    console.log(`  ⚠ --tier=${declaredTier} but this politician resolves to ${resolvedTier} — using ${declaredTier}`);
  }
  const tier = declaredTier ?? resolvedTier;

  const { rows: topic } = await pool.query(
    `SELECT t.id, t.title, t.is_live, t.is_active,
            (SELECT array_agg(role_scope) FROM inform.compass_topic_roles WHERE topic_id = t.id) AS scopes,
            EXISTS (SELECT 1 FROM inform.compass_topics_promoted pr WHERE pr.id = t.id) AS promoted
       FROM inform.compass_topics t WHERE t.topic_key = $1`,
    [r.topic_key],
  );
  if (topic.length !== 1) { console.log(`  🔴 FAIL topic_key resolves to ${topic.length} rows`); failures++; }
  else {
    const t = topic[0];
    console.log(`  topic ${t.id}  ${t.title}  promoted=${t.promoted} (live=${t.is_live} active=${t.is_active}) tiers=${(t.scopes || []).join('+') || '(all)'}`);
    // The open season's question set, not is_live — see the header. A topic the season does not
    // ask is not served, whatever the boolean says; a topic it does ask is served even when the
    // boolean is false, which is true of all 17 new season 2 topics.
    if (!t.promoted) {
      console.log('  🔴 FAIL topic is not in the open season — nothing would serve this answer');
      failures++;
    }
    if (!tier) {
      console.log('  🔴 FAIL cannot establish this politician\'s tier (no district) — pass --tier=<federal|state|local|judicial> to declare the batch cohort');
      failures++;
    } else if (!admitsTier(t.scopes, tier)) {
      console.log(`  🔴 FAIL topic excludes the ${tier} tier — would never display for this politician`);
      failures++;
    }
    const { rows: existing } = await pool.query(
      'SELECT value FROM inform.politician_answers WHERE politician_id = $1 AND topic_id = $2',
      [pol[0]?.id, t.id],
    );
    console.log(existing.length ? `  ⚠ row already exists at value ${existing[0].value} — this is an UPDATE, not an INSERT` : '  no existing answer — INSERT');
  }

  const urls = [r.source_url_1, r.source_url_2, r.source_url_3].filter(Boolean);
  if (!urls.length) { console.log('  🔴 FAIL no sources'); failures++; }

  const terms = [...new Set(r.reasoning.toLowerCase().replace(/[^a-z0-9\s-]/g, ' ').split(/\s+/)
    .filter((w) => w.length > 4 && !STOP.has(w)))];

  // raw = tags-stripped HTML with only <script>/<style> removed, the same standard read-site.mjs uses:
  // a miss in an extracted body is a report about the extractor, a miss in raw is a real absence
  const rawOf = (html) => (html || '')
    .replace(/<(script|style)[\s\S]*?<\/\1>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;|&#160;/g, ' ')
    .replace(/&#8217;|&rsquo;/g, "'")
    .replace(/&#8220;|&#8221;|&ldquo;|&rdquo;/g, '"')
    .replace(/\s+/g, ' ')
    .toLowerCase();

  const allRaw = [];
  for (const u of urls) {
    let res;
    try { res = await crawlSite(u, { maxPages: 1 }); } catch (e) { console.log(`  🔴 FAIL fetch ${u}: ${e.message}`); failures++; continue; }
    if (!res.ok) {
      // classify before reading anything as absence: 403 = bot block, 202/429/503 = throttled,
      // 404/410 = gone, thin body = paywall or JS shell. Only "gone" is a citation defect.
      console.log(`  🔴 FAIL unreadable ${u} — ${res.reason}${res.dead ? ' (DEAD)' : ' (UNREADABLE, not proof of absence)'}`);
      failures++;
      continue;
    }
    const raw = res.pages.map((p) => rawOf(p.html)).join(' ');
    allRaw.push(raw);
    const miss = terms.filter((t) => !raw.includes(t));
    console.log(`  ${miss.length ? '⚠' : '✅'} ${u}  raw=${raw.length}c  terms ${terms.length - miss.length}/${terms.length}`);
    if (miss.length) console.log(`     absent here: ${miss.join(', ')}`);
  }
  // a term is satisfied if ANY cited source carries it
  const union = allRaw.join(' ');
  const uncovered = terms.filter((t) => !union.includes(t));
  if (uncovered.length) { console.log(`  🔴 FAIL ${uncovered.length} claim term(s) on NO cited page: ${uncovered.join(', ')}`); failures++; }
  else console.log(`  ✅ all ${terms.length} distinctive claim terms carried by the cited pages`);
}

console.log('='.repeat(90));
console.log(failures ? `🔴 ${failures} failure(s)` : '✅ all checks passed');
await pool.end();
process.exit(failures ? 1 : 0);
