// Fetch every distinct WI roll-call vote page referenced by wi_legis_votes.csv and extract the
// bill, subject heading, motion and tally.
//
// Usage:  node scripts/scrape-wi-rollcalls.mjs [--limit N]
//
// Writes data/stance-research/wi-2026-state-leg/wi_rollcalls.csv
//
// Why: the member pages give each legislator's Yes/No but only a bare bill number. The roll-call
// page carries the SUBJECT LINE ("PROVISION OF MILITARY FUNERAL HONORS"), which is what lets a
// roll call be triaged to a compass topic. Each av####/sv#### is one roll call, so this is the
// canonical key to join member positions on — bill number alone collapses Assembly and Senate
// votes on the same bill into one bucket.
//
// This also repairs the ~3-per-member rows the member pages render with an EMPTY bill reference.
//
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
    const res = await fetch(url, { headers: { 'User-Agent': UA } });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.text();
  } catch (err) {
    if (attempt >= 4) throw new Error(`${url} failed after ${attempt} attempts: ${err.message}`, { cause: err });
    await sleep(500 * attempt);
    return get(url, attempt + 1);
  }
}

function parseCsv(text) {
  const rows = [];
  let row = [], field = '', inQ = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQ) {
      if (c === '"') { if (text[i + 1] === '"') { field += '"'; i++; } else inQ = false; }
      else field += c;
    } else if (c === '"') inQ = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n') { row.push(field); rows.push(row); row = []; field = ''; }
    else if (c !== '\r') field += c;
  }
  if (field || row.length) { row.push(field); rows.push(row); }
  const cols = rows.shift();
  return rows.filter((r) => r.length === cols.length).map((r) => Object.fromEntries(cols.map((c, i) => [c, r[i]])));
}

// Strip tags to SPACES (not empty) so adjacent elements don't fuse into one word.
const flatten = (html) =>
  html.replace(/<script[\s\S]*?<\/script>/gi, ' ')
      .replace(/<style[\s\S]*?<\/style>/gi, ' ')
      .replace(/<[^>]+>/g, ' ')
      .replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&')
      .replace(/\s+/g, ' ').trim();

const BILL_RE = /\b(?:MY\d+\s+)?(?:AB|SB|AJR|SJR|AR|SR)\s?\d+\b/;

function parseRollcall(html, voteUrl) {
  const flat = flatten(html);
  // The two chambers render differently: the Assembly uses an all-caps "WISCONSIN ASSEMBLY" banner
  // and one combined tally line; the Senate uses mixed-case "Wisconsin Senate Roll Call" and emits
  // AYES/NAYS/NOT VOTING separately with no PAIRED line. Anchor on what BOTH share: the <title>
  // and the "NNNN Regular Session" line.
  const chamber = html.match(/<title>\s*\d{4}\s+(Assembly|Senate)\s+Vote/i)?.[1] || '';
  const num = (re) => {
    const m = flat.match(re);
    return m ? Number(m[1]) : null;
  };
  const ayes = num(/AYES\s*-\s*(\d+)/i);
  const nays = num(/NAYS?\s*-\s*(\d+)/i);
  const notVoting = num(/NOT VOTING\s*-\s*(\d+)/i);
  const paired = num(/PAIRED\s*-\s*(\d+)/i);

  const tallyAt = flat.search(/AYES\s*-\s*\d+/i);
  // Anchor on the breadcrumb "NNNN <Chamber> Vote N", which is present regardless of session type.
  // (Anchoring on "Regular Session" silently dropped all 45 Extraordinary Session roll calls.)
  const crumb = [...flat.matchAll(/\d{4}\s+(?:Assembly|Senate)\s+Vote\s+\d+/gi)]
    .map((m) => m.index)
    .filter((i) => tallyAt < 0 || i < tallyAt)
    .pop();
  const header = crumb !== undefined && tallyAt > crumb ? flat.slice(crumb, tallyAt) : '';
  const cleanHeader = header
    .replace(/^\d{4}\s+(?:Assembly|Senate)\s+Vote\s+\d+/i, '')
    .replace(/WISCONSIN (?:ASSEMBLY|SENATE)/i, '')
    .replace(/Wisconsin Senate Roll Call/i, '')
    // Session descriptors: "2025 Regular Session", "July 2025 Extraordinary Session", etc.
    .replace(/\b(?:[A-Z][a-z]+\s+)?\d{4}\s+(?:Regular|Extraordinary|Special|Veto Review)\s+Session\b/gi, '')
    .replace(/^\s*(Speaker|President|Presiding Officer)\s+\S+/i, '')
    .replace(/\s+/g, ' ').trim();
  const bill = cleanHeader.match(BILL_RE)?.[0].replace(/\s+/g, ' ') || '';
  // Subject = header minus the bill token. The leading "BY <AUTHORS>" clause is deliberately LEFT
  // IN: author names and subject words are both bare uppercase here, so any split heuristic
  // truncates surnames ("BY WITTKE CHANGES..." -> "ITTKE CHANGES..."). The author is useful
  // context for triage anyway.
  const subject = cleanHeader.replace(BILL_RE, '').replace(/\s+/g, ' ').trim();
  return {
    vote_id: voteUrl.split('/').pop(),
    vote_url: voteUrl,
    chamber,
    bill,
    heading: cleanHeader,
    subject,
    ayes,
    nays,
    not_voting: notVoting,
    paired,
    minority: ayes !== null && nays !== null ? Math.min(ayes, nays) : null,
  };
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

const votes = parseCsv(readFileSync(join(DIR, 'wi_legis_votes.csv'), 'utf8'));
let urls = [...new Set(votes.map((v) => v.vote_url).filter(Boolean))].sort();
console.log(`${votes.length} member-vote rows reference ${urls.length} distinct roll calls`);
if (limit !== Infinity) urls = urls.slice(0, limit);

let done = 0;
const rollcalls = await mapLimit(urls, CONCURRENCY, async (u) => {
  const rc = parseRollcall(await get(u), u);
  if (++done % 50 === 0 || done === urls.length) console.log(`  fetched ${done}/${urls.length}`);
  return rc;
});

writeFileSync(join(DIR, 'wi_rollcalls.csv'), toCsv(rollcalls));

const noBill = rollcalls.filter((r) => !r.bill);
const noTally = rollcalls.filter((r) => r.ayes === null);
const divided = rollcalls.filter((r) => r.minority !== null && r.minority >= 10);
console.log(`\nwi_rollcalls.csv  ${rollcalls.length} roll calls`);
console.log(`  by chamber: Assembly ${rollcalls.filter((r) => r.chamber === 'Assembly').length}, Senate ${rollcalls.filter((r) => r.chamber === 'Senate').length}`);
console.log(`  divided (losing side >= 10): ${divided.length}`);
console.log(`  near-unanimous:              ${rollcalls.length - divided.length}`);
if (noBill.length) console.log(`  WARN ${noBill.length} with no parsed bill: ${noBill.slice(0, 8).map((r) => r.vote_id).join(', ')}`);
if (noTally.length) console.log(`  WARN ${noTally.length} with no parsed tally: ${noTally.slice(0, 8).map((r) => r.vote_id).join(', ')}`);
