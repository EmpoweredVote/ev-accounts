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
 *   node scripts/audit-district-urls.mjs --state or --type COUNTY --geo 41069  # re-run one unit
 *   node scripts/audit-district-urls.mjs --state ca --no-registry              # skip the .gov registry
 *
 * ── THE .gov REGISTRY IS PART OF THE METHOD, NOT AN EXTRA ──────────────────────────────────────
 * On every run this fetches CISA's dotgov-data (cached 7 days) and uses it twice: as a CANDIDATE
 * SOURCE, because no hostname template reaches `lacity.gov` / `agourahillscity.gov` /
 * `forestgrove-or.gov`; and as a VERIFICATION step, because the registrant name settles identity
 * better than page vocabulary can and works even when a WAF blocks the page entirely. See the block
 * above `candidatesFor()` for the four limits — silence is not "no .gov", owning is not serving,
 * registered is not even resolving, and the org match must be exact.
 *
 * Requires DATABASE_URL and a Playwright chromium. Network is optional: without it the registry is
 * skipped loudly and the audit continues with weaker evidence. Exits 0 always — a report, not a gate.
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
const NO_ROOT = argv.includes('--no-canonical');
const NO_REGISTRY = argv.includes('--no-registry');
// Loaded once in main(); null when unavailable or disabled. classify() reads it directly because the
// registrant check applies to every probe, including candidates generated from it.
let REGISTRY = null;
// Re-run just the units a previous pass left unresolved, without re-rendering the ones it settled.
const GEO = (arg('geo') || '').split(',').map(s => s.trim()).filter(Boolean);
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
const NONGOV = /\b(visitor|visit |tourism|travel guide|things to do|lodging|winery|wineries|chamber of commerce|business directory|real estate listings|book your stay|vacation rental|domain (is )?for sale|buy this domain)\b/i;

// 🔴🔴 COUNTY AND CITY NAMES REPEAT ACROSS STATES, AND THE NAME TEST CANNOT SEE THE DIFFERENCE.
// Probing Grant County OREGON, this script recommended `https://www.in.gov/counties/grant/` — Grant
// County INDIANA. The page names "Grant" and shows "County Commissioners", so every marker passed.
// 33 states have a Washington County; Oregon, Indiana, Kentucky, Wisconsin, Arkansas, Kansas,
// Minnesota, Nebraska, New Mexico, North Dakota, Oklahoma, South Dakota, West Virginia and
// Washington all have a Grant County. A destination must therefore be placed in the RIGHT STATE, and
// naming a different state is a hard rejection, not a caveat.
const STATE_FULL_NAMES = {
  alabama: 'al', alaska: 'ak', arizona: 'az', arkansas: 'ar', california: 'ca', colorado: 'co',
  connecticut: 'ct', delaware: 'de', florida: 'fl', georgia: 'ga', hawaii: 'hi', idaho: 'id',
  illinois: 'il', indiana: 'in', iowa: 'ia', kansas: 'ks', kentucky: 'ky', louisiana: 'la',
  maine: 'me', maryland: 'md', massachusetts: 'ma', michigan: 'mi', minnesota: 'mn',
  mississippi: 'ms', missouri: 'mo', montana: 'mt', nebraska: 'ne', nevada: 'nv',
  'new hampshire': 'nh', 'new jersey': 'nj', 'new mexico': 'nm', 'new york': 'ny',
  'north carolina': 'nc', 'north dakota': 'nd', ohio: 'oh', oklahoma: 'ok', oregon: 'or',
  pennsylvania: 'pa', 'rhode island': 'ri', 'south carolina': 'sc', 'south dakota': 'sd',
  tennessee: 'tn', texas: 'tx', utah: 'ut', vermont: 'vt', virginia: 'va', washington: 'wa',
  'west virginia': 'wv', wisconsin: 'wi', wyoming: 'wy',
};

/**
 * Which states does this page/host place itself in? Returns { own, others }.
 * `own` is true if our state is named or the host sits in its namespace; `others` lists other
 * states positively named. "Washington" is skipped as a bare word when it could be the place name
 * itself — it is a county in 33 states and a city everywhere.
 */
function stateEvidence(hay, url, st, place) {
  let host = '';
  try { host = new URL(url).host.toLowerCase(); } catch { /* keep '' */ }
  const full = Object.keys(STATE_FULL_NAMES).find(k => STATE_FULL_NAMES[k] === st) || '';
  const placeLc = String(place || '').toLowerCase();
  let own = false;
  if (host) {
    const bare = full.replace(/\s+/g, '');
    if (new RegExp(`\\.${st}\\.(gov|us)$`).test(host)) own = true;
    else if (bare && host.includes(bare)) own = true;
    else if (new RegExp(`(county|city)${st}\\.`).test(host)) own = true;
  }
  if (!own && full) {
    const esc = full.replace(/\s+/g, '\\s+');
    if (new RegExp(`\\b${esc}\\b`, 'i').test(hay)) own = true;
    // 🔴 CASE-SENSITIVE, and never with the /i flag. Matching `,\s*or\b` case-INSENSITIVELY matches
    // the ordinary English word "or" in ", or" — which occurs on virtually every page — so `own`
    // came back true for any state whose abbreviation is a word (OR, IN, IT, ME, HI, OH, OK, DE,
    // LA, MS, MT, PA, SC, MD...). That silently disabled the mismatch check below and let
    // `lincolncountync.gov` (NORTH CAROLINA) be recommended, VERIFIED, for Lincoln County OREGON.
    if (new RegExp(`,\\s*${st.toUpperCase()}\\b`).test(hay)) own = true;   // "Bend, OR"
  }
  const others = [];
  for (const [name, abbr] of Object.entries(STATE_FULL_NAMES)) {
    if (abbr === st) continue;
    if (placeLc && name.includes(placeLc)) continue;                     // the place IS a state name
    const esc = name.replace(/\s+/g, '\\s+');
    if (new RegExp(`\\bstate of ${esc}\\b|\\b${esc}\\.gov\\b|\\b${esc} (county|state) (government|of)\\b`, 'i').test(hay)) others.push(name);
    // Mirror of the `own` host test above — `lincolncountync.gov` glues the abbreviation on with no
    // separating dot, so `\.nc\.gov` never sees it.
    else if (new RegExp(`\\.${abbr}\\.(gov|us)\\b`, 'i').test(host) || new RegExp(`^(www\\.)?${abbr}\\.gov$`, 'i').test(host)
             || new RegExp(`(county|city|gov)${abbr}\\.`, 'i').test(host)) others.push(name);
  }
  return { own, others: [...new Set(others)] };
}
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

// 🔴 Some jurisdictions brand with the state SPELLED OUT, and no `<name>county<abbr>` pattern ever
// reaches them. Two are already sitting in this corpus — `wheelercountyoregon.gov` and
// `morrowcountyoregon.com` — and Grant County OR was reported FAIL with `(none)` recommended purely
// because every generated candidate used `or` rather than `oregon`.
const STATE_NAMES = {
  ak: 'alaska', al: 'alabama', ar: 'arkansas', az: 'arizona', ca: 'california', co: 'colorado',
  ct: 'connecticut', de: 'delaware', fl: 'florida', ga: 'georgia', hi: 'hawaii', ia: 'iowa',
  id: 'idaho', il: 'illinois', in: 'indiana', ks: 'kansas', ky: 'kentucky', la: 'louisiana',
  ma: 'massachusetts', md: 'maryland', me: 'maine', mi: 'michigan', mn: 'minnesota', mo: 'missouri',
  ms: 'mississippi', mt: 'montana', nc: 'northcarolina', nd: 'northdakota', ne: 'nebraska',
  nh: 'newhampshire', nj: 'newjersey', nm: 'newmexico', nv: 'nevada', ny: 'newyork', oh: 'ohio',
  ok: 'oklahoma', or: 'oregon', pa: 'pennsylvania', ri: 'rhodeisland', sc: 'southcarolina',
  sd: 'southdakota', tn: 'tennessee', tx: 'texas', ut: 'utah', va: 'virginia', vt: 'vermont',
  wa: 'washington', wi: 'wisconsin', wv: 'westvirginia', wy: 'wyoming',
};

// ── 🔴🔴 THE .gov REGISTRY: THE ONE AUTHORITY THAT BEATS READING THE PAGE ──────────────────────
//
// CISA publishes every federal `.gov` with its REGISTRANT ORGANISATION, city and state. Because the
// namespace is administered, a domain listed as "City of Pomona / Pomona, CA" cannot belong to anyone
// else — a stronger identity guarantee than any page read, and the property that makes the preference
// order favour `.gov` at all (Sierra County's lapsed `.ws` had no such backstop).
//
// It answers the two failures that defeat rendering outright:
//   1. **A WAF hides a live site.** `pomonaca.gov`, `monroviaca.gov`, `glendaleca.gov` return ~200
//      bytes of "Access Denied" to headless. The registry names the owner with no page at all, so a
//      blocked destination can be accepted on the registry rather than on the block — which the
//      standing rule still forbids.
//   2. **No template can invent a brand.** Los Angeles is `lacity.gov`, Agoura Hills is
//      `agourahillscity.gov`, Pasadena is `pasadena.gov`, Forest Grove is `forestgrove-or.gov`. None
//      is reachable from the place name by any pattern below. Searching by ORGANISATION finds them.
//
// 🔴 FOUR LIMITS, EVERY ONE LEARNED BY BEING WRONG. Do not quietly relax any of them:
//
//   a. **Silence is not "no .gov".** `.ca.gov` is administered by the STATE of California and is
//      absent from this federal list — Duarte is `cityofduarte.ca.gov`, La Cañada Flintridge is
//      `lcf.ca.gov`. Migration 1675 treated absence as proof a city had none; 1676 and 1680 are the
//      counterexamples.
//   b. **Owning a .gov is not serving from it.** Four CA cities own one that REDIRECTS BACK to their
//      own non-.gov host (`weho.gov`->`weho.org`); `hawthorneca.gov` returns 522 and
//      `paramountcity.gov` times out. Always check where a .gov actually goes.
//   c. **Registered does not even mean RESOLVES.** `wheelercountyor.gov` is in this file and has no
//      DNS at all — not bare, not `www`. So a registry hit is a claim about OWNERSHIP only; liveness
//      still has to be probed.
//   d. **Match the organisation EXACTLY (a `, <state>` suffix aside). NEVER substring.** "La Habra"
//      is a strict prefix of "La Habra Heights", so a LIKE match hands `lahabraca.gov` to the wrong,
//      adjacent city — confident and verifiable-looking and wrong. But strict `city of <name>` misses
//      "City of Tigard, **Oregon**", so the trailing state is allowed and nothing else is.
const DOTGOV_URL = 'https://raw.githubusercontent.com/cisagov/dotgov-data/main/current-full.csv';
const DOTGOV_CACHE = 'data/.dotgov-cache.csv';
const CACHE_MAX_AGE_MS = 7 * 24 * 60 * 60 * 1000;
// Department domains are not a jurisdiction's homepage. El Segundo owns six (`elsegundopd.gov`,
// `elsegundolibrary.gov`, …), Rolling Hills Estates four, Los Angeles a dozen.
const DEPT_DOMAIN = /(pd|police|sheriff|fire|fd|library|recparks|parks|court|clerk|vote|votes|election|911|water|transit|airport|schools?|usd|health|dwp|ready|climate)\d*\.gov$/i;

function parseCsvLine(line) {
  const out = []; let cur = '', q = false;
  for (const ch of line) {
    if (ch === '"') q = !q;
    else if (ch === ',' && !q) { out.push(cur); cur = ''; }
    else cur += ch;
  }
  out.push(cur);
  return out;
}

async function loadRegistry() {
  const { readFileSync, writeFileSync, statSync, mkdirSync } = await import('node:fs');
  const { dirname } = await import('node:path');
  let csv = null;
  try {
    const age = Date.now() - statSync(DOTGOV_CACHE).mtimeMs;
    if (age < CACHE_MAX_AGE_MS) csv = readFileSync(DOTGOV_CACHE, 'utf8');
  } catch { /* no cache yet */ }
  if (!csv) {
    try {
      const res = await fetch(DOTGOV_URL, { signal: AbortSignal.timeout(60000) });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      csv = await res.text();
      try { mkdirSync(dirname(DOTGOV_CACHE), { recursive: true }); writeFileSync(DOTGOV_CACHE, csv); } catch { /* cache is optional */ }
    } catch (e) {
      // Offline is not fatal: the audit still runs, it just loses this instrument. Say so loudly
      // rather than silently degrading, because the verdicts are weaker without it.
      console.log(`🔴 could not load the .gov registry (${String(e.message).slice(0, 60)}).`);
      console.log('   Continuing WITHOUT it: no registrant verification and no registry-sourced');
      console.log('   candidates, so a WAF-blocked or oddly-branded destination may read as absent.');
      return null;
    }
  }
  const rows = [];
  const lines = csv.split(/\r?\n/);
  for (const line of lines.slice(1)) {
    if (!line) continue;
    const c = parseCsvLine(line);
    rows.push({ domain: (c[0] || '').toLowerCase(), type: c[1] || '', org: c[2] || '', city: c[4] || '', state: (c[5] || '').toUpperCase() });
  }
  const byDomain = new Map(rows.map(r => [r.domain, r]));
  const norm = (s) => String(s).toLowerCase().replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();

  /** Domains whose registrant IS this jurisdiction. Exact org match, `, <state>` suffix allowed. */
  const forPlace = (place, type, state) => {
    const st = String(state || STATE || '').toUpperCase();
    const p = norm(place);
    if (!p || !st) return [];
    const full = norm(STATE_NAMES[st.toLowerCase()] || '');
    const forms = type === 'COUNTY'
      ? [`${p} county`, `county of ${p}`, p]
      : [`city of ${p}`, `town of ${p}`, `village of ${p}`, `borough of ${p}`, `township of ${p}`, `city and county of ${p}`, p];
    const want = new Set();
    for (const f of forms) { want.add(f); want.add(`${f} ${st.toLowerCase()}`); if (full) want.add(`${f} ${full}`); }
    const hits = rows.filter(r => r.state === st && want.has(norm(r.org)));
    // Prefer a non-department domain; keep the rest so a caller can see the whole set.
    return [...hits].sort((a, b) => (DEPT_DOMAIN.test(a.domain) ? 1 : 0) - (DEPT_DOMAIN.test(b.domain) ? 1 : 0));
  };

  const owner = (url) => {
    try { return byDomain.get(new URL(url).host.toLowerCase().replace(/^www\./, '')) || null; }
    catch { return null; }
  };

  return { size: rows.length, forPlace, owner };
}

function candidatesFor(place, type, state, registryDomains = []) {
  const slug = String(place || '').toLowerCase().replace(/[^a-z]/g, '');
  if (!slug && !registryDomains.length) return [];
  const st = (state || STATE || 'ca').toLowerCase();
  const full = STATE_NAMES[st] || st;
  // Registry-sourced hosts go FIRST: they are the only ones backed by a registrant name, and they
  // reach brands no template can (lacity.gov, forestgrove-or.gov, agourahillscity.gov).
  const fromRegistry = registryDomains.flatMap(d => [`https://www.${d}/`, `https://${d}/`]);
  if (!slug) return fromRegistry;
  if (type === 'COUNTY') {
    return [
      ...fromRegistry,
      `https://www.${slug}county.${st}.gov/`, `https://www.${slug}county${st}.gov/`,
      `https://www.${slug}county.gov/`, `https://www.countyof${slug}.gov/`,
      `https://www.countyof${slug}${st}.gov/`, `https://www.${slug}.${st}.gov/`,
      `https://www.${slug}county${full}.gov/`, `https://www.${slug}county${full}.org/`,
      `https://www.${slug}county${full}.net/`, `https://www.${slug}county${full}.com/`,
      `https://www.${slug}county.org/`, `https://www.${slug}county.us/`,
      `https://www.${slug}county.com/`, `https://www.${slug}county.net/`,
      `https://${slug}gov.org/`, `https://www.co.${slug}.${st}.us/`,
    ];
  }
  return [
    ...fromRegistry,
    `https://www.${slug}.${st}.gov/`, `https://www.cityof${slug}.gov/`,
    `https://www.${slug}.gov/`, `https://www.cityof${slug}.org/`,
    `https://www.${slug}${st}.gov/`, `https://www.ci.${slug}.${st}.us/`,
    `https://www.${slug}${full}.gov/`, `https://www.cityof${slug}.com/`,
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

function nameAmbiguous(url, place, type, stateOwn) {
  let host = '';
  try { host = new URL(url).host.toLowerCase(); } catch { return false; }
  const slug = String(place || '').toLowerCase().replace(/[^a-z]/g, '');
  if (!slug) return false;
  const bareName = new RegExp(`^(www\\.)?${slug}\\.(gov|org|us|com|net)$`).test(host);

  // 🔴 THIS TEST MEANS DIFFERENT THINGS FOR A COUNTY AND A CITY, so it cannot be shared as-is.
  //
  // For a COUNTY, a bare place-name host cannot say whether it is the county or the like-named city:
  // `yuba.gov` and `sutter.gov` are both real county sites, but YUBA CITY IS IN SUTTER COUNTY, so
  // neither could be accepted from its name. That ambiguity is real and stays flagged.
  //
  // For a CITY, a bare place name is the NORMAL form — `beverlyhills.org`, `longbeach.gov`,
  // `torranceca.gov`. Applying the county rule to municipal rows flags nearly every correct answer:
  // it would have marked most of California's 95 municipal units for a human read and buried the few
  // that need one. The genuine ambiguity for a city is a same-named city in ANOTHER STATE (Pasadena
  // CA/TX, Glendale CA/AZ, Lancaster CA/PA, Ontario CA/Canada), which stateEvidence() now decides
  // directly — so for a city this is ambiguous only when the state was NOT confirmed.
  if (type !== 'COUNTY') return bareName && !stateOwn;

  // `^co\.` must survive a `www.` prefix — `www.co.wallowa.or.us` is a county host and was flagged
  // ambiguous in 1673 purely because the anchor could not see past `www.`.
  return bareName || !/county|countyof|(^|\.)co\./.test(host);
}

async function classify(page, url, place, type, st) {
  const rules = ENTITY_RULES[type] || ENTITY_RULES.COUNTY;
  const rec = { url, finalUrl: null, status: null, textLen: 0, title: '', verdict: 'FAIL', why: null };
  try {
    const resp = await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
    rec.status = resp ? resp.status() : null;
    await page.waitForTimeout(2500);                       // let client-rendered nav paint
    // 🔴 A BARELY-PAINTED PAGE IS NOT A PAGE WITHOUT A GOVERNING BODY. Oregon's Jefferson (311
    // chars) and Morrow (482) counties classified NAME_ONLY on the CORRECT `.gov` sites their stored
    // URLs already redirect to, purely because 2.5s was not enough. Give a thin render a second
    // chance before drawing any conclusion from its silence.
    let text = (await page.evaluate(() => (document.body ? document.body.innerText : '')).catch(() => '')) || '';
    if (text.length < 1200) {
      await page.waitForLoadState('networkidle', { timeout: 15000 }).catch(() => {});
      await page.waitForTimeout(2500);
      const again = (await page.evaluate(() => (document.body ? document.body.innerText : '')).catch(() => '')) || '';
      if (again.length > text.length) { text = again; rec.reRendered = true; }
    }
    rec.finalUrl = page.url().replace(/#.*$/, '');
    rec.title = (await page.title().catch(() => '')).slice(0, 140);
    rec.textLen = text.length;                             // 🔴 always report what was searched
    // 🔴 SEARCH THE NAVIGATION, NOT JUST THE PROSE. A county homepage reliably LINKS to "Board of
    // Commissioners" while its body copy says nothing of the kind — judging on innerText alone
    // produced a wall of NAME_ONLY across Oregon on sites that were correct all along.
    const links = (await page.evaluate(() => Array.from(document.querySelectorAll('a'))
      .slice(0, 400).map(a => `${a.textContent || ''} ${a.getAttribute('href') || ''}`).join(' \n')).catch(() => '')) || '';
    rec.linkLen = links.length;
    // 🔴 PROSE AND NAVIGATION ARE SEPARATE EVIDENCE AND MUST BE WEIGHED SEPARATELY. Folding link
    // text into one haystack let `lakecountyor.org` — a tourism site this script had correctly
    // called NOT_GOVERNMENT — reach VERIFIED, because some nav link satisfied the governing-body
    // marker and the NONGOV test sits below the VERIFIED branch and never got a say. Nav evidence
    // still rescues a county homepage whose prose omits its own Board of Commissioners; it just
    // cannot outvote prose that is plainly selling lodging.
    const hayText = `${text} ${rec.title}`;
    const hayNav = links.replace(/[-_/]+/g, ' ');
    const hay = `${hayText} ${hayNav}`;
    // 🔴 An EMPTY place name must never read as "the page names the place" — `\b\b` matches every
    // string, so a unit with no resolvable name would VERIFY against literally any live page.
    const norm = (s) => String(s).normalize('NFD').replace(/[̀-ͯ]/g, '');
    const esc = norm(place).replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/\s+/g, '\\s+');
    const hasName = esc.length > 0 && new RegExp(`\\b${esc}\\b`, 'i').test(norm(hay));
    const rightText = rules.right.test(hayText);
    const rightNav = rules.right.test(hayNav);
    const right = rightText || rightNav;
    const wrong = rules.wrong.test(hayText) || rules.wrong.test(hayNav);
    const nongov = NONGOV.test(hayText);
    rec.rightFromNavOnly = !rightText && rightNav;

    const want = (st || STATE || 'ca').toLowerCase();
    const stEv = stateEvidence(hay, rec.finalUrl || url, want, place);
    rec.stateOwn = stEv.own;
    rec.stateOthers = stEv.others;

    // 🔴 THE REGISTRANT OUTRANKS THE PAGE. If this host is a federal `.gov`, who owns it is a matter
    // of record, not of vocabulary — so it settles the state question in both directions and does not
    // care whether a WAF let us read anything. This is what separates `glendaleca.gov` from
    // `glendaleaz.gov` and `lacity.gov` from `lacounty.gov`, neither of which page text can do.
    const reg = REGISTRY ? REGISTRY.owner(rec.finalUrl || url) : null;
    if (reg) {
      rec.registrant = { org: reg.org, city: reg.city, state: reg.state, type: reg.type };
      if (reg.state.toLowerCase() === want) {
        rec.stateOwn = true;
        stEv.own = true;
        stEv.others = [];                       // a matching registrant overrides page-derived noise
      } else {
        rec.verdict = 'STATE_MISMATCH';
        rec.why = `.gov registrant is ${reg.org} (${reg.city}, ${reg.state}), not ${want.toUpperCase()}`;
        return rec;                             // record beats content; nothing else to weigh
      }
    }

    if (SPAM.test(hay)) { rec.verdict = 'SPAM'; rec.why = 'gambling/pharma keywords'; }
    else if (WAFTITLE.test(rec.title) || (rec.textLen < 400 && rec.status === 403)) {
      rec.verdict = 'BLOCKED'; rec.why = `WAF (${rec.textLen} chars) — confirm by hand, do NOT repoint on this`;
    } else if (rec.textLen < 300 && rec.linkLen < 300) { rec.verdict = 'EMPTY'; rec.why = `only ${rec.textLen} chars of text and ${rec.linkLen} of links rendered`; }
    // 🔴 Naming ANOTHER state outranks every positive marker — see stateEvidence(). This is what
    // stops Grant County Indiana from being recommended for Grant County Oregon.
    else if (!stEv.own && stEv.others.length) {
      rec.verdict = 'STATE_MISMATCH';
      rec.why = `names ${stEv.others.join('/')}, not ${(st || STATE).toUpperCase()}`;
    }
    // 🔴 Tourism/for-sale PROSE outranks a governing-body marker found only in NAVIGATION.
    else if (nongov && !rightText) { rec.verdict = 'NOT_GOVERNMENT'; rec.why = `tourism / chamber / directory vocabulary in prose${rightNav ? ' (a nav link matched a government marker — not enough)' : ''}`; }
    else if (hasName && right && !wrong) {
      rec.verdict = 'VERIFIED';
      if (!stEv.own) rec.stateUnconfirmed = true;
      if (rec.rightFromNavOnly) rec.why = 'governing body found in navigation only, not in page prose';
    }
    else if (hasName && right && wrong) { rec.verdict = 'VERIFIED_MIXED'; rec.why = 'both entity markers present (normal for a consolidated city-county such as San Francisco)'; }
    else if (wrong && !right) { rec.verdict = 'WRONG_ENTITY'; rec.why = rules.wrongLabel; }
    else if (nongov) { rec.verdict = 'NOT_GOVERNMENT'; rec.why = 'tourism / chamber / directory vocabulary'; }
    else if (hasName) { rec.verdict = 'NAME_ONLY'; rec.why = 'names the place but shows no governing body'; }
    else { rec.verdict = 'UNRELATED'; rec.why = 'does not name the place'; }

    if (rec.verdict.startsWith('VERIFIED') && nameAmbiguous(rec.finalUrl || url, place, type, stEv.own)) {
      rec.nameAmbiguous = true;                            // yuba.gov / sutter.gov class
    }
  } catch (e) {
    rec.why = String(e.message || e).split('\n')[0].slice(0, 100);
    // 🔴 A DEAD BROWSER MUST NOT LOOK LIKE A DEAD WEBSITE. This catch used to fold both into FAIL,
    // so when the browser died partway through a unit's candidate list every remaining candidate was
    // recorded FAIL, no candidate reached VERIFIED, and the unit printed `-> (none)` — which on this
    // task reads as "no site exists for this county, leave it broken". Oregon's Washington County
    // reported exactly that while `washingtoncountyor.gov` was up the whole time.
    if (/target (page|closed)|browser has been closed|session closed|page crashed|websocket/i.test(rec.why)) {
      rec.verdict = 'CONTEXT_LOST';
    } else if (/ERR_NAME_NOT_RESOLVED|ENOTFOUND/i.test(rec.why)) {
      rec.verdict = 'NXDOMAIN';
    } else {
      rec.verdict = 'FAIL';
    }
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
  if (!NO_REGISTRY) {
    REGISTRY = await loadRegistry();
    if (REGISTRY) console.log(`.gov registry loaded: ${REGISTRY.size} domains (cached ${DOTGOV_CACHE}, 7d TTL).`);
  }

  let units = buildUnits(rows);
  // Attach each place's registry-owned domains: a candidate source no template can match, and the
  // reason a WAF-blocked destination can still be identified.
  for (const u of units) {
    const hits = REGISTRY ? REGISTRY.forPlace(u.place, u.district_type, u.state) : [];
    u.registryDomains = hits.map(h => h.domain);
    u.registryEntries = hits;
  }
  const allUnits = units.length;
  if (GEO.length) {
    units = units.filter(u => GEO.includes(u.geo_id));
    const missing = GEO.filter(g => !units.some(u => u.geo_id === g));
    if (missing.length) console.log(`🔴 --geo named ${missing.length} geo_id(s) with no matching unit: ${missing.join(', ')}`);
  }
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

  const launch = () => chromium.launch({ headless: true });
  let browser = await launch();
  const queue = [];
  const out = [];

  // 🔴 THESE VERDICTS DESCRIBE THE PROBE, NOT THE URL, SO THEY MUST BE RETRIED.
  // Two consecutive runs over Oregon disagreed: Wasco went VERIFIED -> FAIL and Washington
  // NAME_ONLY -> FAIL, purely because a browser context died mid-run and took its neighbours with
  // it. An unretried FAIL reads on this task as "the site is gone, repoint it" — the single most
  // dangerous error here, and it would have been indistinguishable from Wallowa's real NXDOMAIN.
  // EMPTY is deliberately NOT retried: 26 rendered chars is a finding about the page.
  const TRANSPORT_VERDICTS = new Set(['FAIL', 'CONTEXT_LOST']);

  const newCtx = () => browser.newContext({ userAgent: UA, viewport: { width: 1280, height: 900 }, ignoreHTTPSErrors: true });

  async function worker() {
    let ctx = await newCtx();
    while (queue.length) {
      const unit = queue.shift(); if (!unit) break;
      // 🔴 A dead browser context must cost ONE unit, not the whole report. A crashed context used
      // to reject out of the worker, reject Promise.all, and abort main() before it wrote anything —
      // 35 classified Oregon counties (including a gambling squat on sherman-county.com) were
      // printed to the terminal and then thrown away. Re-establish the context and carry on; a unit
      // that still cannot be probed is recorded as CONTEXT_LOST so it shows up as work remaining
      // rather than silently vanishing from the tally.
      let page;
      try { page = await ctx.newPage(); }
      catch {
        await ctx.close().catch(() => {});
        try { ctx = await newCtx(); page = await ctx.newPage(); }
        catch (e) {
          out.push({
            geo_id: unit.geo_id, place: unit.place, placeSource: unit.placeSource,
            district_type: unit.district_type, types: unit.types, state: unit.state,
            appliesTo: unit.rows.map(r => ({ label: r.label, district_type: r.district_type, stored: r.official_web_url })),
            rowCount: unit.rows.length, stored: unit.stored, storedVerdict: 'CONTEXT_LOST',
            storedWhy: String(e.message || e).split('\n')[0].slice(0, 100), storedTextLen: 0, storedTitle: '',
            recommended: null, needsHumanRead: true, rejected: [], probes: [],
          });
          console.log(`${unit.district_type.padEnd(10)} ${unit.geo_id.padEnd(8)} ${String(unit.place || '(no name)').slice(0, 24).padEnd(24)} ` +
                      `${String(unit.rows.length).padStart(2)}r CONTEXT_LOST   — not probed, re-run this unit ⚠ READ`);
          continue;
        }
      }
      const stored = await classify(page, unit.stored, unit.place, unit.district_type, unit.state);
      const probes = [stored];
      const needsWork = !stored.verdict.startsWith('VERIFIED')
        || /^http:\/\//i.test(unit.stored)
        || (stored.finalUrl && stored.finalUrl.replace(/\/$/, '') !== unit.stored.replace(/\/$/, ''));
      // 🔴 `candidatesTried < candidatesPlanned` is NOT evidence the sweep was cut short: the loop
      // legitimately skips a candidate already reached by an earlier redirect, and stops early once
      // two destinations verify. Counting those as untried labelled 7 COMPLETE Oregon sweeps
      // "SEARCH INCOMPLETE". Only an actual break-out is truncation, so record that directly.
      let candidatesTried = 0, candidatesSkipped = 0, candidatesPlanned = 0, sweepTruncated = false;
      if (needsWork && !NO_CAND) {
        const cands = candidatesFor(unit.place, unit.district_type, unit.state, unit.registryDomains);
        candidatesPlanned = cands.length;
        for (const c of cands) {
          if (probes.filter(p => p.verdict.startsWith('VERIFIED')).length >= 2) break;
          if (probes.some(p => (p.finalUrl || '').replace(/\/$/, '') === c.replace(/\/$/, ''))) { candidatesSkipped++; continue; }
          // A fresh page per candidate: one crashed navigation used to poison every later candidate
          // probed on the same page.
          let cp = page;
          try { cp = await ctx.newPage(); } catch { /* reuse `page`; the guard below records the loss */ }
          probes.push(await classify(cp, c, unit.place, unit.district_type, unit.state));
          candidatesTried++;
          if (cp !== page) await cp.close().catch(() => {});
          if (!browser.isConnected()) { sweepTruncated = true; break; }   // stop pretending to probe a dead browser
        }
      }
      await page.close().catch(() => {});
      const verified = probes.filter(p => p.verdict.startsWith('VERIFIED'));
      // 🔴 A destination that never placed itself in our state must not compete with one that did.
      // Probing Jackson County OREGON, `jacksongov.org` — Jackson County MISSOURI — reached VERIFIED
      // with own=false; it lost only because score() happens to prefer the `.gov` of the correct
      // `jacksoncountyor.gov`. Ranking is the wrong place to settle a question of identity, so
      // state-confirmed destinations win outright whenever any exist.
      const confirmed = verified.filter(p => p.stateOwn);
      const pool = confirmed.length ? confirmed : verified;
      let settled = [...new Set(pool.map(p => p.finalUrl).filter(Boolean))].sort((a, b) => score(b) - score(a) || a.length - b.length);

      // ── 🔴 THE CASE THE REGISTRY EXISTS FOR: NOTHING RENDERED, BUT A REGISTRANT NAMES THE OWNER ──
      //
      // A WAF can hide a live site from headless on EVERY path, so the sweep verifies nothing and the
      // unit reports `(none)` — which on this task reads as "no site exists". Pomona, Monrovia,
      // Rolling Hills Estates, Calabasas and Glendale all did exactly that, and each was settled by
      // hand against the registry in 1675/1676/1679. That is now automatic.
      //
      // The standing rule is intact: this is NOT repointing on the strength of a block. The basis is
      // the registrant — an administered namespace saying this domain belongs to this jurisdiction —
      // with the block noted only as evidence a server answered at all. Flagged for a human either
      // way, and it never outranks something that actually rendered.
      let registryFallback = null;
      if (!settled.length && REGISTRY && (unit.registryDomains || []).length) {
        const answered = probes.find(p =>
          p.verdict === 'BLOCKED' && p.registrant && unit.registryDomains.includes(
            (() => { try { return new URL(p.finalUrl || p.url).host.toLowerCase().replace(/^www\./, ''); } catch { return ''; } })()
          ));
        if (answered) {
          const host = new URL(answered.finalUrl || answered.url).host.toLowerCase();
          registryFallback = {
            url: `https://${host}/`,
            why: `WAF-blocked, accepted on the .gov registrant: ${answered.registrant.org} (${answered.registrant.city}, ${answered.registrant.state})`,
          };
          settled = [registryFallback.url];
        }
      }

      // ── 🔴 CANONICALISE THE DESTINATION. `finalUrl` IS WHERE A REDIRECT LANDED, NOT A HOMEPAGE. ──
      //
      // This column is a jurisdiction's official web address, so it must be the site root. Storing
      // the landing URL verbatim was about to write, for Rancho Palos Verdes:
      //     https://www.rpvca.gov/search/?searchPhrase=&pageNumber=1&perPage=10&departmentId=-1
      // — a SEARCH QUERY — plus `/Home` on six cities and `/index.php` on Carson.
      //
      // And a redirect can land on http: Monterey Park's chain ends at
      // `http://www.montereypark.ca.gov/` and Artesia's at `http://www.cityofartesia.us/`, so the
      // "upgrade" would not have upgraded anything.
      //
      // So: try `https://<host>/` and accept it only if it VERIFIES on its own. Never rewrite a URL
      // to a root that was not itself rendered and checked — that would be assuming a homepage exists
      // because a subpage did, which is the same class of error as assuming a `.gov` exists because
      // the county does.
      let canonical = settled[0] || null;
      let canonicalNote = null;
      if (canonical && !NO_ROOT) {
        try {
          const u = new URL(canonical);
          const root = `https://${u.host}/`;
          const needsRoot = u.protocol !== 'https:' || u.pathname !== '/' || u.search || u.hash;
          if (needsRoot && root !== canonical) {
            let rp = page;
            try { rp = await ctx.newPage(); } catch { /* fall back to the unit page */ }
            const probe = await classify(rp, root, unit.place, unit.district_type, unit.state);
            if (rp !== page) await rp.close().catch(() => {});
            probes.push(probe);
            if (probe.verdict.startsWith('VERIFIED') && (!confirmed.length || probe.stateOwn)) {
              canonicalNote = `canonicalised from ${canonical}`;
              canonical = probe.finalUrl && new URL(probe.finalUrl).host === u.host ? root : root;
            } else {
              canonicalNote = `root ${root} did NOT verify (${probe.verdict}) — kept the landing URL, READ IT`;
            }
          }
        } catch { /* unparseable: leave the destination exactly as found */ }
      }
      // 🔴 `(none)` is only a finding if the search actually RAN. If the browser died mid-sweep, or any
      // candidate came back CONTEXT_LOST, the sweep is incomplete and its silence means nothing.
      const lostProbes = probes.filter(p => p.verdict === 'CONTEXT_LOST').length;
      const candidatesIncomplete = !NO_CAND && needsWork && !settled.length && (lostProbes > 0 || sweepTruncated);

      // 🔴 A BLOCKED PROBE ONLY MATTERS IF IT IS THE ANSWER. Flagging a unit because *any* probe was
      // blocked marked all 9 of Oregon's WAF-caveat counties for a human read, and on inspection the
      // blocked page was a GoDaddy parked-domain lander every time — a destination already being
      // rejected. (Two were thin non-candidates, one was `currycountynm.gov`: Curry County NEW
      // MEXICO.) The recommendation itself was VERIFIED and state-confirmed on all 9. Over-warning
      // is not free: it spends the reviewer's attention on rows that need none, which is how a real
      // warning gets skimmed past. So a block counts when it IS the recommendation, or when nothing
      // verified at all — in that case the blocked page might have been the right site, and the
      // header's rule stands: a BLOCKED row is not a licence to repoint.
      const blockedProbes = probes.filter(p => p.verdict === 'BLOCKED');
      const blockedRecommendation = blockedProbes.some(p => (p.finalUrl || p.url) === settled[0]);
      const blockedMatters = blockedRecommendation || (!settled.length && blockedProbes.length > 0);
      const rec = {
        geo_id: unit.geo_id, place: unit.place, placeSource: unit.placeSource,
        district_type: unit.district_type, types: unit.types, state: unit.state,
        // Every row this verdict applies to. The migration author needs the fan-out, not a count.
        appliesTo: unit.rows.map(r => ({ label: r.label, district_type: r.district_type, stored: r.official_web_url })),
        rowCount: unit.rows.length,
        stored: unit.stored, storedVerdict: stored.verdict, storedWhy: stored.why,
        storedTextLen: stored.textLen, storedTitle: stored.title,
        recommended: canonical,
        landingUrl: settled[0] || null, canonicalNote,
        candidatesIncomplete, candidatesTried, candidatesSkipped, candidatesPlanned, lostProbes, sweepTruncated,
        stateUnconfirmed: verified.some(p => p.stateUnconfirmed && (p.finalUrl || p.url) === settled[0]),
        blockedRecommendation, blockedOtherCandidates: blockedProbes.length - (blockedRecommendation ? 1 : 0),
        // A destination still on http, or one whose root refused to verify, is not ready to store.
        stillHttp: !!canonical && /^http:\/\//i.test(canonical),
        registryDomains: unit.registryDomains || [],
        registryFallback: registryFallback ? registryFallback.why : null,
        registrant: (probes.find(p => (p.finalUrl || p.url) === settled[0]) || {}).registrant || null,
        needsHumanRead: !settled.length || verified.some(p => p.nameAmbiguous) || blockedMatters
          || unit.placeSource === 'NONE' || candidatesIncomplete
          || verified.some(p => p.stateUnconfirmed || p.rightFromNavOnly)
          || (!!canonicalNote && canonicalNote.includes('did NOT verify'))
          || (!!canonical && /^http:\/\//i.test(canonical))
          || !!registryFallback,   // registrant-only evidence always gets a human glance
        rejected: probes.filter(p => ['WRONG_ENTITY', 'NOT_GOVERNMENT', 'SPAM', 'STATE_MISMATCH'].includes(p.verdict))
          .map(p => ({ url: p.finalUrl || p.url, verdict: p.verdict, why: p.why, title: p.title })),
        probes,
      };
      out.push(rec);
      const flag = rec.needsHumanRead ? ' ⚠ READ' : '';
      const dest = rec.recommended
        || (candidatesIncomplete ? `(SEARCH INCOMPLETE — ${candidatesTried}/${candidatesPlanned} candidates, ${lostProbes} lost; NOT evidence no site exists)` : '(none)');
      console.log(`${unit.district_type.padEnd(10)} ${unit.geo_id.padEnd(8)} ${String(unit.place || '(no name)').slice(0, 24).padEnd(24)} ` +
                  `${String(unit.rowCount ?? unit.rows.length).padStart(2)}r ${rec.storedVerdict.padEnd(14)} len=${String(rec.storedTextLen).padStart(6)} -> ${dest}${flag}`);
      if (rec.registrant) console.log(`           ↳ .gov registrant: ${rec.registrant.org} (${rec.registrant.city}, ${rec.registrant.state})`);
      if (rec.registryFallback) console.log(`           🔴 ${rec.registryFallback}`);
      if (rec.canonicalNote) console.log(`           ↳ ${rec.canonicalNote}`);
      if (rec.stillHttp) console.log('           🔴 destination is STILL http — not an upgrade, read it');
      for (const r of rec.rejected) console.log(`           🔴 rejected ${r.url} — ${r.verdict}: ${r.why}`);
    }
    await ctx.close().catch(() => {});
  }
  // allSettled, not all: a worker that dies anyway must not discard the units already classified.
  const keyOf = (u) => `${u.geo_id}|${u.stored}`;

  async function runRound(toProbe) {
    // The BROWSER itself can die, not just a context — then every worker fails on newContext and the
    // round probes nothing. Relaunch before assuming the round can run at all.
    if (!browser.isConnected()) {
      console.log('🔴 the browser had died — relaunching before this round.');
      try { browser = await launch(); } catch (e) { console.log(`🔴 relaunch failed: ${e.message}`); return; }
    }
    queue.length = 0;
    queue.push(...toProbe);
    const settledWorkers = await Promise.allSettled(Array.from({ length: CONC }, () => worker()));
    for (const w of settledWorkers.filter(w => w.status === 'rejected')) {
      console.log(`🔴 a probe worker died: ${String(w.reason && w.reason.message || w.reason).split('\n')[0].slice(0, 120)}`);
    }
    if (queue.length) console.log(`🔴 ${queue.length} unit(s) were never probed in this round.`);
  }

  await runRound(units);

  const flaky = out.filter(r => TRANSPORT_VERDICTS.has(r.storedVerdict) || r.candidatesIncomplete);
  if (flaky.length) {
    console.log(`\n--- retry round: ${flaky.length} unit(s) whose verdict described the PROBE, not the URL ---`);
    const keys = new Set(flaky.map(keyOf));
    const before = new Map(flaky.map(r => [keyOf(r), r]));
    for (let i = out.length - 1; i >= 0; i--) if (keys.has(keyOf(out[i]))) out.splice(i, 1);
    await runRound(units.filter(u => keys.has(keyOf(u))));
    // 🔴 A unit pulled out for retry and then never re-probed would VANISH from the report — and the
    // "resolved on retry" line would count that vanishing as a success. Put the original verdict
    // back, and count only units that actually produced a new record.
    const reprobed = new Set(out.filter(r => keys.has(keyOf(r))).map(keyOf));
    for (const [k, rec] of before) if (!reprobed.has(k)) { out.push(rec); console.log(`🔴 ${k} was NOT re-probed — its original ${rec.storedVerdict} stands.`); }
    const resolved = [...reprobed].filter((k) => {
      const r = out.find(x => keyOf(x) === k);
      return !TRANSPORT_VERDICTS.has(r.storedVerdict) && !r.candidatesIncomplete;
    });
    console.log(`--- retried ${reprobed.size} of ${flaky.length}; ${resolved.length} produced a complete result ---`);
  }
  await browser.close().catch(() => {});

  out.sort((a, b) => a.district_type.localeCompare(b.district_type) || a.geo_id.localeCompare(b.geo_id));
  if (out.length !== units.length) console.log(`\n🔴 classified ${out.length} of ${units.length} planned unit(s).`);
  const tally = out.reduce((m, r) => (m[r.storedVerdict] = (m[r.storedVerdict] || 0) + 1, m), {});
  const rowsOf = (pred) => out.filter(pred).reduce((n, r) => n + r.rowCount, 0);
  console.log('\n=== stored-URL verdicts (units, and the rows they cover) ===');
  for (const [k, v] of Object.entries(tally).sort((a, b) => b[1] - a[1]))
    console.log(`  ${k.padEnd(16)} ${String(v).padStart(4)} unit(s)  ${String(rowsOf(r => r.storedVerdict === k)).padStart(4)} row(s)`);
  const changed = (r) => r.recommended && r.recommended.replace(/\/$/, '') !== r.stored.replace(/\/$/, '');
  console.log(`\n  changes proposed : ${out.filter(changed).length} unit(s) / ${rowsOf(changed)} row(s)`);
  console.log(`  need a human read: ${out.filter(r => r.needsHumanRead).length} unit(s) / ${rowsOf(r => r.needsHumanRead)} row(s)  ⚠`);
  const inc = out.filter(r => r.candidatesIncomplete);
  if (inc.length) {
    console.log(`  🔴 SEARCH INCOMPLETE on ${inc.length} unit(s) / ${rowsOf(r => r.candidatesIncomplete)} row(s) — a dead browser truncated the`);
    console.log('     candidate sweep. Their "(none)" is NOT a finding. Re-run them with --geo:');
    console.log(`       --geo ${inc.map(r => r.geo_id).join(',')}`);
  }
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
