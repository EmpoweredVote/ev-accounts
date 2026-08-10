#!/usr/bin/env node
/**
 * Classify `essentials.districts.official_web_url` — is it live, and is it THE RIGHT ENTITY?
 *
 * READ-ONLY. This never writes. It produces a report you act on with a migration.
 *
 * WHY THIS EXISTS. Every `official_web_url` in the corpus came from the migration-1619 import and
 * most were never revisited. Two of them turned out to point at organisations that are not
 * government at all:
 *
 *   Sonoma County  `sonomacounty.org`  ->  winecountry.com, a commercial tourism site   (fixed 1644)
 *   Sierra County  `sierracounty.ws`   ->  mampir123.org, an expired-domain squat       (fixed 1646)
 *
 * Both answered HTTP 200 the whole way. **A URL that resolves is not evidence that it resolves to
 * the entity whose record holds it**, and that — not liveness — is the hard part of this job.
 *
 * ── 🔴🔴 THE DISCRIMINATOR INVERTS BY ENTITY KIND. THIS IS THE WHOLE TRICK. ────────────────────
 * Migration 1667 classified California's 58 COUNTY rows using: *a California county is governed by
 * a BOARD OF SUPERVISORS; a city is governed by a CITY COUNCIL.* That is what separated
 * `sandiegocounty.gov` from `sandiego.gov`, and `countyofmonterey.gov` from `monterey.gov`.
 *
 * **For a LOCAL / LOCAL_EXEC row that rule runs backwards.** Those rows are CITIES, so "City
 * Council" / "Mayor" is the CORRECT signal and "Board of Supervisors" is the wrong-entity signal —
 * a city record pointed at its county's website is exactly the same defect as a county record
 * pointed at its city's. Applying 1667's county rule to municipal rows would reject every correct
 * answer. So the marker set here is chosen per `district_type`; see ENTITY_RULES.
 *
 * 🔴 **AND THE COUNTY GOVERNING BODY IS NAMED DIFFERENTLY IN EVERY STATE.** The first smoke test of
 * this script, run against Oregon with only California's "Board of Supervisors", reported 4 of 6
 * counties as NAME_ONLY — which on this task reads as "repoint it". Oregon counties have a **Board
 * of Commissioners**. ENTITY_RULES.COUNTY now carries the union of the American forms. If you point
 * this at a new state and see a wall of NAME_ONLY, suspect that regex before you suspect the data.
 *
 * ── 🔴 WHY THIS RENDERS PAGES INSTEAD OF FETCHING THEM ─────────────────────────────────────────
 * Three detector failures, all found the hard way while doing California:
 *
 *   1. A raw-HTML (curl) classifier called **Sierra County NOT_COUNTY** and **Santa Barbara
 *      EMPTY**. Both are correct county sites; their government vocabulary lives in client-rendered
 *      nav. Judging a civic site from unrendered HTML produces false NEGATIVES, which on this task
 *      look like "the URL is broken, repoint it" — the most dangerous possible error.
 *   2. **A WAF rejection can be HTTP 200 or 202**, and Cloudflare can block on the TLS fingerprint
 *      so a full browser header set does not help. Never classify by status code; classify by body.
 *   3. **Headless Chromium is itself blocked** by some WAFs with a hard "Access Denied" on every
 *      path — eight California counties returned ~200 bytes to headless while rendering perfectly
 *      in a normal browser profile. Those are reported as BLOCKED, NOT as broken, and must be
 *      confirmed by hand. A BLOCKED row is not a licence to repoint.
 *
 * ── 🔴 THE CANDIDATE GENERATOR HAS HOLES BY CONSTRUCTION ───────────────────────────────────────
 * Derived hostnames (`<name>county.ca.gov`, `countyof<name>.gov`, …) never find an entity that
 * brands differently. Humboldt County's site is `humboldtgov.org`; no pattern generates that. It was
 * found by hand and then verified hardest of any row (69,673 chars, Board of Supervisors present).
 * Treat `(none)` as "look yourself", never as "no site exists".
 *
 * ── 🔴 BARE PLACE-NAME `.gov` HOSTS NEED SPECIFIC DISAMBIGUATION ───────────────────────────────
 * `yuba.gov` and `sutter.gov` are both real county sites — but **Yuba City is in SUTTER county**, so
 * neither could be accepted from its name. Any host whose name is a bare place rather than
 * "<place> county" is flagged NAME_AMBIGUOUS so a human reads it.
 *
 * PREFERENCE ORDER when several destinations verify:
 *   1. `.gov` / `.ca.gov` wins. The namespace is administered, so a lapsed registration cannot be
 *      picked up by a squatter — precisely what Sierra's `.ws` lacked.
 *   2. A non-`.gov` host only where the entity genuinely has none (many small counties/cities).
 *   3. `http://` -> `https://` on the same verified host is always worth taking.
 *
 * ── 🔴 ONE PROBE PER PLACE, NOT PER ROW ────────────────────────────────────────────────────────
 * A municipality holds its council seats as N `LOCAL` rows and its executive as a `LOCAL_EXEC` row,
 * and **every one of them stores the same `official_web_url`**. Probing per row renders the same
 * homepage up to 13 times (Long Beach) and invites 13 chances to classify it inconsistently. Rows
 * are therefore collapsed into probe units keyed on `geo_id` + host before any browser opens; the
 * verdict is then applied to every row in the unit. On the current CA+OR backlog that is **291 rows
 * -> 143 probes**. The key includes the host so that a place whose rows *disagree* about their URL
 * still gets each distinct host probed rather than one silently winning.
 *
 * ── 🔴 THE PLACE NAME IS NOT IN A `LOCAL` ROW'S LABEL ──────────────────────────────────────────
 * `classify()` decides VERIFIED partly on "does the page name this place", so it needs the place
 * name. A COUNTY label supplies it (`Baker County`) and a LOCAL_EXEC label supplies it
 * (`Torrance Mayor`) — but a **LOCAL label is `District 1` / `At-Large`**, which names nothing.
 * Deriving the name from that label yields the slug `district`, so `candidatesFor()` generated
 * `https://www.district.ca.gov/` and every name test failed for a reason that had nothing to do with
 * the row. The name comes from `ocd_id`'s trailing `place:`/`county:` slug, falling back to a
 * LOCAL_EXEC sibling in the same unit, falling back to the label. `placeSource` records which, so a
 * NAME-based verdict can always be traced to where the name came from. `districts.city` is NULL on
 * every row in this corpus and is not a usable source.
 *
 * USAGE
 *   node scripts/audit-district-urls.mjs --state or --type COUNTY
 *   node scripts/audit-district-urls.mjs --state ca --type LOCAL,LOCAL_EXEC --json out.json
 *   node scripts/audit-district-urls.mjs --state or --no-candidates      # classify stored only
 *   node scripts/audit-district-urls.mjs --state ca --type LOCAL --plan-only   # show units, no probe
 *
 * Requires DATABASE_URL and a Playwright chromium. Exits 0 always — it is a report, not a gate.
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { Pool } from 'pg';

const argv = process.argv.slice(2);
const arg = (name, dflt = null) => {
  const i = argv.indexOf(`--${name}`);
  return i > -1 && argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[i + 1] : dflt;
};
const STATE = (arg('state') || '').toLowerCase();
const TYPES = (arg('type') || 'COUNTY').split(',').map(s => s.trim().toUpperCase()).filter(Boolean);
const LIMIT = parseInt(arg('limit', '0'), 10) || 0;
const JSON_OUT = arg('json');
const NO_CAND = argv.includes('--no-candidates');
const PLAN_ONLY = argv.includes('--plan-only');
const CONC = parseInt(arg('concurrency', '4'), 10) || 4;

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36';

// 🔴 Per-entity marker sets. See the header — this is the part that inverts.
//
// 🔴🔴 AND THE COUNTY GOVERNING BODY IS NAMED DIFFERENTLY IN EVERY STATE. The first smoke test of
// this script used only California's "Board of Supervisors" and reported 4 of 6 OREGON counties as
// NAME_ONLY — i.e. "live but shows no governing body", which on this task reads as "repoint it".
// Oregon counties have a **Board of Commissioners** (a few still have a County Court); Wisconsin has
// a County Board; Tennessee has a County Commission and a County Mayor; Texas has a Commissioners
// Court and a County Judge. So the `right` pattern below is the UNION of the American forms, not
// California's. If you add a state and see a wall of NAME_ONLY, suspect this regex before you
// suspect the data.
const ENTITY_RULES = {
  COUNTY: {
    right: /board of (supervisors|commissioners)|supervisorial district|commissioners court|county (administrator|executive|board|commission|commissioners|council|court|judge|manager|mayor)/i,
    wrong: /\b(city council|city manager|city hall|mayor's office)\b/i,
    wrongLabel: 'looks like a CITY',
  },
  LOCAL: {
    right: /city council|town council|city manager|city hall|mayor|village board|borough council/i,
    wrong: /board of supervisors|supervisorial district/i,
    wrongLabel: 'looks like a COUNTY',
  },
};
ENTITY_RULES.LOCAL_EXEC = ENTITY_RULES.LOCAL;

// Non-government lookalikes seen on real rows. Not exhaustive; these are the ones already caught.
const NONGOV = /\b(visitor|visit |tourism|travel guide|things to do|lodging|winery|wineries|chamber of commerce|business directory|real estate listings|book your stay|vacation rental)\b/i;
const SPAM = /\b(gacor|slot|judi|togel|casino|bandar|maxwin|situs|toto|pkv|rtp live|winrate|jackpot|viagra|cialis|escort|bokep)\b/i;
const WAFTITLE = /just a moment|attention required|access denied|request rejected|cloudflare|incapsula|pardon our interruption|unusual traffic|are you a robot/i;

function placeOf(label) {
  return String(label || '')
    .replace(/\s+(County|City|Town|Village|Borough)$/i, '')
    .replace(/\s+(city council|board of supervisors|mayor).*$/i, '')
    .trim();
}

function hostOf(url) {
  try { return new URL(url).host.toLowerCase().replace(/^www\./, ''); } catch { return `!unparseable:${url}`; }
}

// `ocd-division/country:us/state:ca/place:hermosa_beach` -> `Hermosa Beach`
function placeFromOcd(ocdId) {
  const m = /\/(?:place|county|city|town|village|borough|township):([a-z0-9_\-~.]+)$/i.exec(String(ocdId || ''));
  if (!m) return null;
  const name = decodeURIComponent(m[1]).replace(/[_~]/g, ' ').replace(/\s+/g, ' ').trim();
  if (!name) return null;
  return name.replace(/\b[a-z]/g, (c) => c.toUpperCase());
}

// 🔴 A LOCAL label ("District 1", "At-Large", "Ward 3") names no place. Recognise those so they are
// never mistaken for a place name — that is what produced the slug `district`.
const SEAT_ONLY_LABEL = /^(at[-\s]?large|district\s*\d+[a-z]?|ward\s*\d+[a-z]?|position\s*\d+|seat\s*\d+|division\s*\d+|subdistrict\s*\d+|zone\s*\d+)$/i;

/**
 * Resolve the place name for a probe unit, preferring the most independent source available.
 * Returns { place, placeSource } — placeSource is reported so a name-based verdict is traceable.
 */
function resolvePlace(rows) {
  for (const r of rows) {                                        // 1. ocd_id slug
    const p = placeFromOcd(r.ocd_id);
    if (p) return { place: p, placeSource: 'ocd_id' };
  }
  for (const r of rows) {                                        // 2. a sibling label that names one
    if (!SEAT_ONLY_LABEL.test(String(r.label || '').trim())) {
      const p = placeOf(r.label);
      if (p && !SEAT_ONLY_LABEL.test(p)) return { place: p, placeSource: `label:${r.district_type}` };
    }
  }
  return { place: '', placeSource: 'NONE' };                     // 3. nothing — see report
}

/** Collapse rows sharing a place AND a host into one probe unit. */
function buildUnits(rows) {
  const units = new Map();
  for (const r of rows) {
    const key = `${r.geo_id}|${hostOf(r.official_web_url)}`;
    if (!units.has(key)) units.set(key, []);
    units.get(key).push(r);
  }
  return [...units.values()].map((rs) => {
    const { place, placeSource } = resolvePlace(rs);
    // COUNTY wins the type vote — its marker set is the strict one and misapplying LOCAL's rules to
    // a county row is the wrong-entity error this whole script exists to catch.
    const types = [...new Set(rs.map((r) => r.district_type))];
    return {
      geo_id: rs[0].geo_id, state: rs[0].state, host: hostOf(rs[0].official_web_url),
      stored: rs[0].official_web_url, place, placeSource,
      district_type: types.includes('COUNTY') ? 'COUNTY' : types[0],
      types: types.sort(), rows: rs,
    };
  }).sort((a, b) => a.district_type.localeCompare(b.district_type) || a.geo_id.localeCompare(b.geo_id));
}

function candidatesFor(place, type) {
  const slug = String(place || '').toLowerCase().replace(/[^a-z]/g, '');
  if (!slug) return [];
  const st = (STATE || 'ca').toLowerCase();
  if (type === 'COUNTY') {
    return [
      `https://www.${slug}county.${st}.gov/`, `https://www.${slug}county${st}.gov/`,
      `https://www.${slug}county.gov/`, `https://www.countyof${slug}.gov/`,
      `https://www.countyof${slug}${st}.gov/`, `https://www.${slug}.${st}.gov/`,
      `https://www.${slug}county.org/`, `https://www.${slug}county.us/`,
      `https://www.${slug}county.com/`, `https://www.${slug}county.net/`,
      `https://${slug}gov.org/`,
    ];
  }
  return [
    `https://www.${slug}.${st}.gov/`, `https://www.cityof${slug}.gov/`,
    `https://www.${slug}.gov/`, `https://www.cityof${slug}.org/`,
    `https://www.${slug}ca.gov/`, `https://www.ci.${slug}.${st}.us/`,
    `https://www.${slug}.org/`, `https://www.${slug}.us/`,
  ];
}

function score(url) {
  let host = '';
  try { host = new URL(url).host.toLowerCase(); } catch { return -1000; }
  let s = 0;
  // 🔴 Do NOT reward "county"/"city" in the hostname on its own. Ranking by that is what
  // recommended orangecounty.net (a visitor guide) and sanfranciscocounty.us (a 611-byte shell).
  // The entity check below is what earns trust; this only breaks ties among VERIFIED hosts.
  if (/\.gov$/.test(host)) s += /\.[a-z]{2}\.gov$/.test(host) ? 110 : 100;
  else if (/\.[a-z]{2}\.us$/.test(host)) s += 30;
  else s += 10;
  if (/^https:/i.test(url)) s += 25;
  if (/^www\./.test(host)) s += 3;
  return s;
}

function nameAmbiguous(url, place, type) {
  let host = '';
  try { host = new URL(url).host.toLowerCase(); } catch { return false; }
  const slug = String(place || '').toLowerCase().replace(/[^a-z]/g, '');
  if (!slug) return false;
  // A host that is the bare place name cannot say which entity it is (yuba.gov / sutter.gov).
  return new RegExp(`^(www\\.)?${slug}\\.(gov|org|us|com|net)$`).test(host)
      || (type === 'COUNTY' && !/county|countyof|^co\./.test(host));
}

async function classify(page, url, place, type) {
  const rules = ENTITY_RULES[type] || ENTITY_RULES.COUNTY;
  const rec = { url, finalUrl: null, status: null, textLen: 0, title: '', verdict: 'FAIL', why: null };
  try {
    const resp = await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
    rec.status = resp ? resp.status() : null;
    await page.waitForTimeout(2500);                       // let client-rendered nav paint
    rec.finalUrl = page.url().replace(/#.*$/, '');
    rec.title = (await page.title().catch(() => '')).slice(0, 140);
    const text = (await page.evaluate(() => (document.body ? document.body.innerText : '')).catch(() => '')) || '';
    rec.textLen = text.length;                             // 🔴 always report what was searched
    const hay = `${text} ${rec.title}`;
    // 🔴 An EMPTY place name must never read as "the page names the place" — `\b\b` matches every
    // string, so a unit with no resolvable name would VERIFY against literally any live page.
    const norm = (s) => String(s).normalize('NFD').replace(/[̀-ͯ]/g, '');
    const esc = norm(place).replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/\s+/g, '\\s+');
    const hasName = esc.length > 0 && new RegExp(`\\b${esc}\\b`, 'i').test(norm(hay));
    const right = rules.right.test(hay);
    const wrong = rules.wrong.test(hay);

    if (SPAM.test(hay)) { rec.verdict = 'SPAM'; rec.why = 'gambling/pharma keywords'; }
    else if (WAFTITLE.test(rec.title) || (rec.textLen < 400 && rec.status === 403)) {
      rec.verdict = 'BLOCKED'; rec.why = `WAF (${rec.textLen} chars) — confirm by hand, do NOT repoint on this`;
    } else if (rec.textLen < 300) { rec.verdict = 'EMPTY'; rec.why = `only ${rec.textLen} chars rendered`; }
    else if (hasName && right && !wrong) { rec.verdict = 'VERIFIED'; }
    else if (hasName && right && wrong) { rec.verdict = 'VERIFIED_MIXED'; rec.why = 'both entity markers present (normal for a consolidated city-county such as San Francisco)'; }
    else if (wrong && !right) { rec.verdict = 'WRONG_ENTITY'; rec.why = rules.wrongLabel; }
    else if (NONGOV.test(hay)) { rec.verdict = 'NOT_GOVERNMENT'; rec.why = 'tourism / chamber / directory vocabulary'; }
    else if (hasName) { rec.verdict = 'NAME_ONLY'; rec.why = 'names the place but shows no governing body'; }
    else { rec.verdict = 'UNRELATED'; rec.why = 'does not name the place'; }

    if (rec.verdict.startsWith('VERIFIED') && nameAmbiguous(rec.finalUrl || url, place, type)) {
      rec.nameAmbiguous = true;                            // yuba.gov / sutter.gov class
    }
  } catch (e) {
    rec.why = String(e.message || e).split('\n')[0].slice(0, 100);
    rec.verdict = /ERR_NAME_NOT_RESOLVED|ENOTFOUND/i.test(rec.why) ? 'NXDOMAIN' : 'FAIL';
  }
  return rec;
}

async function main() {
  if (!process.env.DATABASE_URL) {
    console.log('SKIP: DATABASE_URL not set — this audit needs a live database.');
    return;
  }
  let chromium;
  try { ({ chromium } = await import('playwright')); }
  catch { console.error('playwright is required: npm i -D playwright && npx playwright install chromium'); process.exitCode = 1; return; }

  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  const params = [TYPES];
  let where = 'official_web_url IS NOT NULL AND district_type = ANY($1)';
  if (STATE) { params.push(STATE); where += ` AND lower(state) = $${params.length}`; }
  const { rows } = await pool.query(
    `SELECT geo_id, ocd_id, label, district_type, lower(state) AS state, official_web_url
       FROM essentials.districts WHERE ${where} ORDER BY district_type, geo_id`, params);
  await pool.end();

  if (!rows.length) { console.log('No rows matched.'); return; }

  // 🔴 Collapse to one probe per place+host BEFORE opening a browser. --limit caps PROBES, not rows.
  let units = buildUnits(rows);
  const allUnits = units.length;
  if (LIMIT) units = units.slice(0, LIMIT);
  const coveredRows = units.reduce((n, u) => n + u.rows.length, 0);

  console.log(`state=${STATE || 'ALL'} type=${TYPES.join(',')}`);
  console.log(`${rows.length} row(s) collapse to ${allUnits} probe unit(s) keyed on geo_id+host` +
              `${LIMIT ? ` — probing ${units.length} of them` : ''} (covering ${coveredRows} row(s)).`);
  const noName = units.filter((u) => u.placeSource === 'NONE');
  if (noName.length) {
    console.log(`🔴 ${noName.length} unit(s) have NO resolvable place name — the name test is SKIPPED for`);
    console.log('   them, so they can never reach VERIFIED. They are listed at the end; read them by hand.');
  }
  console.log('🔴 BLOCKED means a WAF hid the page from an automated browser. It is NOT evidence the');
  console.log('   URL is wrong — confirm those by hand before changing anything.\n');

  if (PLAN_ONLY) {
    for (const u of units) {
      console.log(`${u.district_type.padEnd(10)} ${u.geo_id.padEnd(8)} ${String(u.place || '(no name)').padEnd(24)} ` +
                  `${String(u.rows.length).padStart(2)} row(s) [${u.types.join('+')}] src=${u.placeSource.padEnd(17)} ${u.stored}`);
    }
    console.log(`\n${units.length} probe unit(s). --plan-only: nothing was probed.`);
    return;
  }

  const browser = await chromium.launch({ headless: true });
  const queue = units.slice();
  const out = [];

  async function worker() {
    const ctx = await browser.newContext({ userAgent: UA, viewport: { width: 1280, height: 900 }, ignoreHTTPSErrors: true });
    while (queue.length) {
      const unit = queue.shift(); if (!unit) break;
      const page = await ctx.newPage();
      const stored = await classify(page, unit.stored, unit.place, unit.district_type);
      const probes = [stored];
      const needsWork = !stored.verdict.startsWith('VERIFIED')
        || /^http:\/\//i.test(unit.stored)
        || (stored.finalUrl && stored.finalUrl.replace(/\/$/, '') !== unit.stored.replace(/\/$/, ''));
      if (needsWork && !NO_CAND) {
        for (const c of candidatesFor(unit.place, unit.district_type)) {
          if (probes.filter(p => p.verdict.startsWith('VERIFIED')).length >= 2) break;
          if (probes.some(p => (p.finalUrl || '').replace(/\/$/, '') === c.replace(/\/$/, ''))) continue;
          probes.push(await classify(page, c, unit.place, unit.district_type));
        }
      }
      await page.close().catch(() => {});
      const verified = probes.filter(p => p.verdict.startsWith('VERIFIED'));
      const settled = [...new Set(verified.map(p => p.finalUrl).filter(Boolean))].sort((a, b) => score(b) - score(a) || a.length - b.length);
      const rec = {
        geo_id: unit.geo_id, place: unit.place, placeSource: unit.placeSource,
        district_type: unit.district_type, types: unit.types, state: unit.state,
        // Every row this verdict applies to. The migration author needs the fan-out, not a count.
        appliesTo: unit.rows.map(r => ({ label: r.label, district_type: r.district_type, stored: r.official_web_url })),
        rowCount: unit.rows.length,
        stored: unit.stored, storedVerdict: stored.verdict, storedWhy: stored.why,
        storedTextLen: stored.textLen, storedTitle: stored.title,
        recommended: settled[0] || null,
        needsHumanRead: !settled.length || verified.some(p => p.nameAmbiguous) || probes.some(p => p.verdict === 'BLOCKED')
          || unit.placeSource === 'NONE',
        rejected: probes.filter(p => ['WRONG_ENTITY', 'NOT_GOVERNMENT', 'SPAM'].includes(p.verdict))
          .map(p => ({ url: p.finalUrl || p.url, verdict: p.verdict, why: p.why, title: p.title })),
        probes,
      };
      out.push(rec);
      const flag = rec.needsHumanRead ? ' ⚠ READ' : '';
      console.log(`${unit.district_type.padEnd(10)} ${unit.geo_id.padEnd(8)} ${String(unit.place || '(no name)').slice(0, 24).padEnd(24)} ` +
                  `${String(unit.rowCount ?? unit.rows.length).padStart(2)}r ${rec.storedVerdict.padEnd(14)} len=${String(rec.storedTextLen).padStart(6)} -> ${rec.recommended || '(none)'}${flag}`);
      for (const r of rec.rejected) console.log(`           🔴 rejected ${r.url} — ${r.verdict}: ${r.why}`);
    }
    await ctx.close();
  }
  await Promise.all(Array.from({ length: CONC }, () => worker()));
  await browser.close();

  out.sort((a, b) => a.district_type.localeCompare(b.district_type) || a.geo_id.localeCompare(b.geo_id));
  const tally = out.reduce((m, r) => (m[r.storedVerdict] = (m[r.storedVerdict] || 0) + 1, m), {});
  const rowsOf = (pred) => out.filter(pred).reduce((n, r) => n + r.rowCount, 0);
  console.log('\n=== stored-URL verdicts (units, and the rows they cover) ===');
  for (const [k, v] of Object.entries(tally).sort((a, b) => b[1] - a[1]))
    console.log(`  ${k.padEnd(16)} ${String(v).padStart(4)} unit(s)  ${String(rowsOf(r => r.storedVerdict === k)).padStart(4)} row(s)`);
  const changed = (r) => r.recommended && r.recommended.replace(/\/$/, '') !== r.stored.replace(/\/$/, '');
  console.log(`\n  changes proposed : ${out.filter(changed).length} unit(s) / ${rowsOf(changed)} row(s)`);
  console.log(`  need a human read: ${out.filter(r => r.needsHumanRead).length} unit(s) / ${rowsOf(r => r.needsHumanRead)} row(s)  ⚠`);
  console.log(`  wrong-entity destinations rejected: ${out.reduce((n, r) => n + r.rejected.length, 0)}`);

  const nameless = out.filter(r => r.placeSource === 'NONE');
  if (nameless.length) {
    console.log(`\n🔴 ${nameless.length} unit(s) had NO place name, so the name test was skipped — a verdict here`);
    console.log('   rests on the governing-body marker alone. Read each one:');
    for (const r of nameless) console.log(`     ${r.geo_id} ${r.stored}  [${r.appliesTo.map(a => a.label).join(', ')}]`);
  }

  if (JSON_OUT) { writeFileSync(JSON_OUT, JSON.stringify(out, null, 1)); console.log(`\nwrote ${JSON_OUT}`); }
  console.log('\nThis is a REPORT. Nothing was written. Act on it with a migration, and re-read every');
  console.log('row marked ⚠ READ before including it.');
}

main().catch(e => { console.error('audit failed:', e.message); process.exitCode = 1; });
