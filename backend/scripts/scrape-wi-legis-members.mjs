// Scrape the Wisconsin Legislature's own 2025-26 session record for all 132 sitting members.
//
// Usage:  node scripts/scrape-wi-legis-members.mjs [--limit N] [--skip-details]
//
// Writes into data/stance-research/wi-2026-state-leg/:
//   wi_legis_members.csv   — chamber, district, legis_id, name, party, home city, member site, official headshot URL
//   wi_legis_votes.csv     — one row per (member, floor vote): date, bill, motion, the member's own Yes/No/No Vote
//   wi_legis_authored.csv  — one row per (member, proposal) for authored / co-authored / cosponsored / amendments
//
// Why this shape: WI does not publish a per-member vote *feed*, but each member's detail page
// renders their complete floor record with their own position already resolved. So 132 page
// fetches yield the entire chamber's roll-call history keyed by member — no per-bill fan-out and
// no API spend. Bill -> compass-chair mapping is done ONCE per bill downstream and reused across
// every member who voted on it.
//
// TRAP: the member-vote vocabulary is `Yes` / `No` / `No Vote`, where "No Vote" means ABSENT, not
// opposition. Never fold it into `No`.
//
// Read-only against the public site. Touches no database.
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const OUT_DIR = join('data', 'stance-research', 'wi-2026-state-leg');
const BASE = 'https://docs.legis.wisconsin.gov';
const SESSION = '2025';
const UA = 'Mozilla/5.0 (compatible; EmpoweredVote civic-data/1.0)';
const CONCURRENCY = 4;

const argv = process.argv.slice(2);
const limit = argv.includes('--limit') ? Number(argv[argv.indexOf('--limit') + 1]) : Infinity;
const skipDetails = argv.includes('--skip-details');

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function get(url, attempt = 1) {
  try {
    const res = await fetch(url, { headers: { 'User-Agent': UA } });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.text();
  } catch (err) {
    if (attempt >= 4) throw new Error(`${url} failed after ${attempt} attempts: ${err.message}`, { cause: err });
    await sleep(500 * attempt);
    return get(url, attempt + 1);
  }
}

const strip = (s) => s.replace(/<[^>]+>/g, '').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').trim();

function parseIndex(html, chamber) {
  // The member site lives in the <a> that WRAPS the roster photo, i.e. immediately BEFORE the <img>
  // we split on. Capture the (site, id) pair with one regex over the adjacent markup so they can
  // never be mismatched, then look up the site by id while walking the chunks.
  // Schemes are mixed across members — older entries use http://, newer ones https:// with a
  // trailing slash. Hardcoding http:// silently left 85 of 132 blank.
  const sitesById = new Map();
  const altById = new Map();
  const pairRe = new RegExp(
    `<a href="(https?://legis\\.wisconsin\\.gov/${chamber}/\\d+/[^"]*)">\\s*` +
      `<img class="picture"[^>]*alt="([^"]*)"[^>]*src="[^"]*/(\\d+)\\.jpg"`,
    'g'
  );
  for (const m of html.matchAll(pairRe)) {
    sitesById.set(m[3], m[1]);
    // alt is "Picture of Representative Nate L. Gustafson" — the OFFICIAL full name, including
    // middle initial, which the "Last, First" roster string drops.
    altById.set(m[3], m[2].replace(/^Picture of (Representative|Senator)\s*/i, '').trim());
  }

  // Each member block starts at their roster photo; split there so fields can't bleed across members.
  const chunks = html.split('<img class="picture"').slice(1);
  const out = [];
  for (const chunk of chunks) {
    const id = chunk.match(new RegExp(`/${SESSION}/legislators/${chamber}/(\\d+)\\.jpg`))?.[1];
    if (!id) continue;
    const site = sitesById.get(id) || '';
    const nm = chunk.match(/<strong>\s*<a[^>]*>([^<]+)<\/a>\s*<\/strong>\s*<small>\(([^)]*)\)<\/small>/);
    const district = chunk.match(/<small>District (\d+)<\/small>/)?.[1];
    const rawName = nm ? strip(nm[1]) : '';
    const [party, homeCity] = nm ? nm[2].split(' - ').map((s) => s.trim()) : ['', ''];
    // Roster renders "Last, First" (sometimes "Last, First Middle").
    const [last, first] = rawName.includes(',') ? rawName.split(',').map((s) => s.trim()) : ['', rawName];
    out.push({
      chamber: chamber === 'assembly' ? 'Assembly' : 'Senate',
      district: district ? Number(district) : null,
      legis_id: id,
      roster_name: rawName,
      official_name: altById.get(id) || '',
      first_name: first || '',
      last_name: last || '',
      party: party || '',
      home_city: homeCity || '',
      member_site: site,
      // The roster thumbnail is only 150x200 — too small for the 600x750 production target.
      // Treated as a LAST-RESORT fallback; the high-res portrait lives on the member's own site.
      roster_thumb_url: `${BASE}/${SESSION}/legislators/${chamber}/${id}.jpg`,
      detail_url: `${BASE}/${SESSION}/legislators/${chamber}/${id}`,
    });
  }
  return out;
}

const VOTE_RE = /<div class="searchFloorMemberVoteResult">\s*<span[^>]*>(.*?)<\/span>\s*<span[^>]*>(.*?)<\/span>\s*<span>([^<]*)<\/span>\s*<\/div>/gs;

function parseVotes(html, m) {
  const rows = [];
  for (const mm of html.matchAll(VOTE_RE)) {
    const left = mm[1];
    const date = strip(left).match(/^(\d{1,2}\/\d{1,2}\/\d{4})/)?.[1] || '';
    const bill = strip(left).replace(/^\d{1,2}\/\d{1,2}\/\d{4}\s*vote on\s*/i, '').trim();
    const motion = strip(mm[2]);
    const voteUrl = mm[2].match(/href="([^"]*\/votes\/[^"]*)"/)?.[1] || '';
    const position = strip(mm[3]);
    rows.push({
      chamber: m.chamber,
      district: m.district,
      legis_id: m.legis_id,
      member: m.roster_name,
      party: m.party,
      vote_date: date,
      bill,
      motion,
      position, // Yes | No | No Vote  <- "No Vote" is ABSENT
      vote_url: voteUrl ? BASE + voteUrl : '',
    });
  }
  return rows;
}

// Tab-pane ids as the site actually renders them.
const SECTIONS = [
  ['authored', /id="authoredProposals"[^>]*>(.*?)(?=<div class="tab-pane|$)/s],
  ['coauthored', /id="coauthoredProposals"[^>]*>(.*?)(?=<div class="tab-pane|$)/s],
  ['cosponsored', /id="cosponsoredProposals"[^>]*>(.*?)(?=<div class="tab-pane|$)/s],
  ['amendments', /id="amendments"[^>]*>(.*?)(?=<div class="tab-pane|$)/s],
];

function parseAuthored(html, m) {
  const rows = [];
  for (const [role, re] of SECTIONS) {
    const block = html.match(re)?.[1];
    if (!block) continue;
    for (const link of block.matchAll(/<a href="([^"]*\/(?:proposals|amendments)\/[^"]+)"[^>]*>([^<]+)<\/a>/g)) {
      const label = strip(link[2]);
      // Labels render as "2025 Assembly Bill 1024" / "2025 Senate Joint Resolution 12".
      if (!/\b(Bill|Resolution|Amendment)\b/i.test(label)) continue;
      rows.push({
        chamber: m.chamber,
        district: m.district,
        legis_id: m.legis_id,
        member: m.roster_name,
        party: m.party,
        role,
        proposal: label,
        url: BASE + link[1],
      });
    }
  }
  return rows;
}

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

async function mapLimit(items, n, fn) {
  const out = new Array(items.length);
  let i = 0;
  await Promise.all(
    Array.from({ length: Math.min(n, items.length) }, async () => {
      while (i < items.length) {
        const idx = i++;
        out[idx] = await fn(items[idx], idx);
        await sleep(150);
      }
    })
  );
  return out;
}

mkdirSync(OUT_DIR, { recursive: true });

const [asmHtml, senHtml] = await Promise.all([
  get(`${BASE}/${SESSION}/legislators/assembly`),
  get(`${BASE}/${SESSION}/legislators/senate`),
]);
let members = [...parseIndex(asmHtml, 'assembly'), ...parseIndex(senHtml, 'senate')];

const badIdx = members.filter((m) => !m.district || !m.last_name);
if (badIdx.length) console.warn(`WARN ${badIdx.length} index rows missing district or surname`);
console.log(`index: ${members.filter((m) => m.chamber === 'Assembly').length} Assembly + ${members.filter((m) => m.chamber === 'Senate').length} Senate = ${members.length} members`);
writeFileSync(join(OUT_DIR, 'wi_legis_members.csv'), toCsv(members));
const allMembersCount = members.length;

if (skipDetails) {
  console.log('--skip-details set; stopping after the roster.');
  process.exit(0);
}

if (limit !== Infinity) members = members.slice(0, limit);

let done = 0;
const results = await mapLimit(members, CONCURRENCY, async (m) => {
  const html = await get(m.detail_url);
  const votes = parseVotes(html, m);
  const authored = parseAuthored(html, m);
  if (++done % 20 === 0 || done === members.length) console.log(`  fetched ${done}/${members.length}`);
  return { m, votes, authored, bytes: html.length };
});

const allVotes = results.flatMap((r) => r.votes);
const allAuthored = results.flatMap((r) => r.authored);
writeFileSync(join(OUT_DIR, 'wi_legis_votes.csv'), toCsv(allVotes));
writeFileSync(join(OUT_DIR, 'wi_legis_authored.csv'), toCsv(allAuthored));

const noVotes = results.filter((r) => r.votes.length === 0).map((r) => `${r.m.chamber}${r.m.district} ${r.m.roster_name}`);
const positions = allVotes.reduce((a, v) => ((a[v.position] = (a[v.position] || 0) + 1), a), {});
const distinctBills = new Set(allVotes.map((v) => v.bill)).size;

console.log(`\nwi_legis_members.csv   ${allMembersCount} members (details fetched for ${members.length})`);
console.log(`wi_legis_votes.csv     ${allVotes.length} member-vote rows over ${distinctBills} distinct bill/motion subjects`);
console.log(`  positions: ${JSON.stringify(positions)}   ("No Vote" = absent, NOT opposition)`);
console.log(`wi_legis_authored.csv  ${allAuthored.length} authorship rows`);
if (noVotes.length) console.log(`\nWARN ${noVotes.length} members parsed with ZERO votes: ${noVotes.join('; ')}`);
