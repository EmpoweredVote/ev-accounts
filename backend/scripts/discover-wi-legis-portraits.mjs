// Discover the high-resolution official portrait for each sitting WI legislator.
//
// Usage: node scripts/discover-wi-legis-portraits.mjs [--limit N]
//
// WHY: the docs.legis roster thumbnail is only 150x200 — upscaling that to the 600x750 production
// target is a 4x enlargement and looks visibly soft. Each member's own site (legis.wisconsin.gov)
// hosts the real portrait in an Umbraco media library whose resizer honours ?width=/&height=, so the
// same image is available at full resolution. Those URLs also carry `rxy=x,y` — Umbraco's official
// focal point — which maps onto essentials.politician_images.focal_point.
//
// Writes data/stance-research/wi-2026-state-leg/wi_portrait_sources.csv
// Read-only against the public site. Touches no database.
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const DIR = join('data', 'stance-research', 'wi-2026-state-leg');
const UA = 'Mozilla/5.0 (compatible; EmpoweredVote civic-data/1.0)';
const CONCURRENCY = 4;

const argv = process.argv.slice(2);
const limit = argv.includes('--limit') ? Number(argv[argv.indexOf('--limit') + 1]) : Infinity;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function get(url, attempt = 1) {
  try {
    const res = await fetch(url, { headers: { 'User-Agent': UA }, redirect: 'follow' });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.text();
  } catch (err) {
    if (attempt >= 3) throw new Error(`${url}: ${err.message}`, { cause: err });
    await sleep(400 * attempt);
    return get(url, attempt + 1);
  }
}

function parseCsv(t) {
  const rows = []; let row = [], f = '', q = false;
  for (let i = 0; i < t.length; i++) { const c = t[i];
    if (q) { if (c === '"') { if (t[i+1] === '"') { f += '"'; i++; } else q = false; } else f += c; }
    else if (c === '"') q = true;
    else if (c === ',') { row.push(f); f = ''; }
    else if (c === '\n') { row.push(f); rows.push(row); row = []; f = ''; }
    else if (c !== '\r') f += c; }
  if (f || row.length) { row.push(f); rows.push(row); }
  const cols = rows.shift();
  return rows.filter(r => r.length === cols.length).map(r => Object.fromEntries(cols.map((c, i) => [c, r[i]])));
}

const norm = (s) => (s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z]/g, '');

// Collect every distinct Umbraco media image on the page, keeping the rxy focal point if present.
function mediaCandidates(html, origin) {
  const found = new Map();
  for (const m of html.matchAll(/["'(]((?:https?:\/\/[^"'()\s]+)?\/[^"'()\s]*?\/media\/[^"'()\s]+?\.(?:jpg|jpeg|png))([^"'()\s]*)/gi)) {
    const path = m[1];
    const qs = (m[2] || '').replace(/&amp;/g, '&');
    const abs = path.startsWith('http') ? path : origin + path;
    const rxy = qs.match(/[?&]rxy=([0-9.]+,[0-9.]+)/)?.[1] || '';
    const prev = found.get(abs);
    // Keep whichever occurrence carries a focal point.
    if (!prev || (!prev.rxy && rxy)) found.set(abs, { url: abs, rxy });
  }
  return [...found.values()];
}

// Score candidates: the portrait is the media file named after the member. Capitol/event/flag
// imagery is explicitly demoted so a generic banner is never mistaken for a headshot.
const NEGATIVE = /capitol|rotunda|chamber|flag|logo|banner|seal|building|aerial|inaugurat|group|event|coffee|park|city|map|placeholder|desk|floor|session|award|visit|tour|constituent|school|farm/i;
// Threshold matters: scoring anything above zero let a Capitol rotunda photo win on the strength of
// having a focal point alone. Require a genuine name or portrait signal.
const MIN_SCORE = 8;
function pickPortrait(cands, member) {
  const last = norm(member.last_name);
  const first = norm(member.first_name.split(/\s+/)[0]);
  let best = null;
  for (const c of cands) {
    const file = norm(decodeURIComponent(c.url.split('/').pop().split('?')[0]));
    let score = 0;
    if (last.length > 2 && file.includes(last)) score += 10;
    // Filenames often use a short form ("clint" for Clinton), so credit a prefix match too.
    if (first.length > 3 && (file.includes(first) || file.includes(first.slice(0, 5)))) score += 4;
    if (/headshot|portrait|official/.test(file)) score += 8;
    if (/\b(rep|sen|asm)/.test(file)) score += 3;
    if (c.rxy) score += 2;
    if (NEGATIVE.test(file)) score -= 20;
    if (score >= MIN_SCORE && (!best || score > best.score)) best = { ...c, score, file };
  }
  return best;
}

// Candidates rejected by VISUAL inspection, loaded from the tracked reject list. That file is the
// single source of truth — do not inline a copy here, or the two will drift.
//
// Filename matching alone had a 29% defect rate (23 of 79 hits were signature graphics, district
// wordmarks, family photos, website icons or press-conference shots). A signature graphic and an
// official portrait are both "<surname>.png", so no filename, aspect or file-size rule separates
// them — only looking at the images does. Rejected members fall back to the official 150x200
// docs.legis roster portrait, which is always a genuine tight headshot of the right person.
const REJECT_FILE = join(DIR, 'wi-headshot-visual-rejects.json');
let VISUAL_REJECT = {};
try {
  const parsed = JSON.parse(readFileSync(REJECT_FILE, 'utf8'));
  for (const [seat, r] of Object.entries(parsed.rejects || {})) {
    VISUAL_REJECT[seat] = `${r.reason}${r.file ? ` (${r.file})` : ''}`;
  }
  console.log(`loaded ${Object.keys(VISUAL_REJECT).length} visual rejects from ${REJECT_FILE}`);
} catch (e) {
  // Fail loud. Silently continuing would re-admit every rejected signature graphic and wordmark.
  console.error(`FATAL: could not read the visual reject list at ${REJECT_FILE}: ${e.message}`);
  console.error('Without it, previously-rejected non-headshots would be selected again. Aborting.');
  process.exit(1);
}

async function mapLimit(items, n, fn) {
  const out = new Array(items.length);
  let i = 0;
  await Promise.all(Array.from({ length: Math.min(n, items.length) }, async () => {
    while (i < items.length) { const idx = i++; out[idx] = await fn(items[idx], idx); await sleep(150); }
  }));
  return out;
}

let members = parseCsv(readFileSync(join(DIR, 'wi_legis_members.csv'), 'utf8'));
if (limit !== Infinity) members = members.slice(0, limit);

let done = 0;
const results = await mapLimit(members, CONCURRENCY, async (m) => {
  const base = { chamber: m.chamber, district: m.district, legis_id: m.legis_id,
                 roster_name: m.roster_name, official_name: m.official_name, party: m.party };
  if (!m.member_site) {
    if (++done % 20 === 0) console.log(`  ${done}/${members.length}`);
    return { ...base, portrait_url: '', rxy: '', source: 'none (no member site)', fallback: m.roster_thumb_url };
  }
  const rejectReason = VISUAL_REJECT[`${m.chamber}-${Number(m.district)}`];
  if (rejectReason) {
    if (++done % 20 === 0) console.log(`  ${done}/${members.length}`);
    return { ...base, portrait_url: '', rxy: '', source: `visually rejected: ${rejectReason}`, fallback: m.roster_thumb_url };
  }
  try {
    const origin = new URL(m.member_site).origin;
    const html = await get(m.member_site);
    const pick = pickPortrait(mediaCandidates(html, origin), m);
    if (++done % 20 === 0) console.log(`  ${done}/${members.length}`);
    if (!pick) return { ...base, portrait_url: '', rxy: '', source: 'no portrait match', fallback: m.roster_thumb_url };
    // Ask Umbraco for the largest render; it fits within the box and preserves aspect ratio.
    const big = `${pick.url.split('?')[0]}?width=1600&height=1600`;
    return { ...base, portrait_url: big, rxy: pick.rxy, source: `member_site (score ${pick.score}, ${pick.file})`, fallback: m.roster_thumb_url };
  } catch (e) {
    if (++done % 20 === 0) console.log(`  ${done}/${members.length}`);
    return { ...base, portrait_url: '', rxy: '', source: `ERROR ${e.message}`, fallback: m.roster_thumb_url };
  }
});

const cols = Object.keys(results[0]);
const esc = (v) => { const s = v == null ? '' : String(v); return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s; };
writeFileSync(join(DIR, 'wi_portrait_sources.csv'),
  [cols.join(','), ...results.map(r => cols.map(c => esc(r[c])).join(','))].join('\n') + '\n');

const withPortrait = results.filter(r => r.portrait_url);
const withRxy = withPortrait.filter(r => r.rxy);
console.log(`\nhigh-res portrait found: ${withPortrait.length}/${results.length}`);
console.log(`  with official focal point (rxy): ${withRxy.length}`);
console.log(`  needing the 150x200 fallback:    ${results.length - withPortrait.length}`);
for (const r of results.filter(x => !x.portrait_url)) console.log(`    ${r.chamber}${r.district} ${r.roster_name} — ${r.source}`);
console.log(`\nwrote wi_portrait_sources.csv`);
