#!/usr/bin/env node
/**
 * nd-legislature-member-sweep.mjs — Knight program, wave ND-2.
 *
 * Reads every North Dakota legislator's OWN biography page and extracts the facts the roster
 * pages cannot give: the dated status of their service in the 69th Legislative Assembly.
 *
 * 🟢 NORTH DAKOTA DATES ITS ARRIVALS AND DEPARTURES TO THE DAY, ON THE MEMBER'S OWN PAGE.
 * The "Assembly Sessions by Year" block carries lines such as `Resigned August 4, 2026`,
 * `Deceased April 25, 2026`, `Active August 5, 2026` and `Effective 1/7/25 - 8/4/26`. This is
 * the body's own record, and it is strictly better than the roster: MI-2 closed with 148
 * undated arrivals and MN-2 with 200 unknowns because no member page there published one.
 *
 * 🔴🔴 THE REGULAR-SESSION ROSTER IS CUMULATIVE AND READS AS 148 MEMBERS. Seven districts list
 * FOUR members on `/assembly/69-2025/regular/members/members-by-district`, because that page
 * retains everyone who held the seat during the assembly. North Dakota's House is legitimately
 * TWO-per-district, so "four in a district" reads as 2x2 and survives a naive shape check that
 * would have caught it instantly in a single-member state. Seat from the CURRENT convening's
 * roster (Sep 2026 special session, 141 members) and use this sweep to date the changes.
 *
 * 🔴 A DEPARTURE IS A FACT ABOUT THE CURRENT ASSEMBLY ROW, NOT ABOUT THE PAGE. Every member who
 * ever served has session rows going back years; a `Resigned` line on a 2015 row says nothing
 * about today. This script reads the status only from the 69th Assembly's rows.
 *
 * Usage:
 *   node scripts/nd-legislature-member-sweep.mjs --roster data/seed-nd-2026/nd-roster-special-2.json \
 *        --out data/seed-nd-2026/nd-members.json [--delay 250]
 */
import fs from 'fs';
import path from 'path';
import https from 'https';

const argv = process.argv.slice(2);
const argOf = (f) => { const i = argv.indexOf(f); return i >= 0 ? argv[i + 1] : undefined; };
const ROSTER = argOf('--roster');
const OUT = argOf('--out');
const DELAY = Number(argOf('--delay') ?? 250);
if (!ROSTER || !OUT) {
  console.error('usage: --roster <roster.json> --out <members.json> [--delay ms]');
  process.exit(1);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function get(url, redirects = 0) {
  return new Promise((resolve, reject) => {
    https
      .get(url, { headers: { 'User-Agent': 'ev-accounts/nd-slice12' } }, (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location && redirects < 5) {
          res.resume();
          const next = new URL(res.headers.location, url).toString();
          return get(next, redirects + 1).then(resolve, reject);
        }
        if (res.statusCode !== 200) {
          res.resume();
          return reject(new Error(`HTTP ${res.statusCode}`));
        }
        let body = '';
        res.setEncoding('utf8');
        res.on('data', (c) => (body += c));
        res.on('end', () => resolve(body));
      })
      .on('error', reject);
  });
}

function decodeEntities(s) {
  return s
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
    .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#039;|&apos;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>');
}
const text = (s) => decodeEntities(s.replace(/<[^>]+>/g, ' ')).replace(/\s+/g, ' ').trim();

/**
 * Status phrases the Legislative Branch uses on a session row. Anything matching the
 * departure set means the person no longer holds the seat.
 * 🔴 The list is closed on purpose: an UNRECOGNISED status is reported, never ignored.
 */
const DEPARTURE = /\b(Resigned|Deceased|Died|Removed|Expelled|Vacated|Withdrew)\b/i;
const ARRIVAL = /\bActive\s+([A-Z][a-z]+ \d{1,2}, \d{4})/;
const EFFECTIVE_RANGE = /\bEffective\s+(\d{1,2}\/\d{1,2}\/\d{2,4})\s*[-–]\s*(\d{1,2}\/\d{1,2}\/\d{2,4})/;
const DEPARTURE_DATED = /\b(Resigned|Deceased|Died|Removed|Expelled|Vacated|Withdrew)\s+([A-Z][a-z]+ \d{1,2}, \d{4})/i;
/** Leadership and other benign phrases that appear in the same block. */
const BENIGN = /^(Majority|Minority|Assistant|Speaker|President|Pro Tempore|Caucus|Leader|Chairman|Whip|Republican|Democrat|Independent|Effective after)/i;

function parseBio(html, member) {
  const clean = html.replace(/<(script|style)[^>]*>[\s\S]*?<\/\1>/g, '');

  // Service summary bullets, e.g. "Senate since 1987" or "House 2013-24; Senate 2025-26".
  const bodyBlock = /field--name-body[\s\S]*?<div class="field__item">([\s\S]*?)<\/div>/.exec(clean);
  const bio = bodyBlock ? text(bodyBlock[1]) : '';
  const since = /\b(Senate|House)\s+since\s+(\d{4})/i.exec(bio);
  const spans = [...bio.matchAll(/\b(Senate|House)\s+(\d{4})\s*-\s*(\d{2,4})/gi)].map(
    (m) => `${m[1]} ${m[2]}-${m[3]}`,
  );

  // 🔴 Only the 69th Assembly's rows. Each tab pane is keyed by the assembly heading.
  const rows = [...clean.matchAll(
    /<div class="legislator-history-wrapper[\s\S]*?<h3>([\s\S]*?)<\/h3>([\s\S]*?)<\/div><\/div><\/div><\/div>/g,
  )];
  const current = [];
  for (const [, headingRaw, rowRaw] of rows) {
    const heading = text(headingRaw);
    if (!/69th/.test(heading)) continue;
    const row = text(rowRaw);
    current.push({ heading, row });
  }

  const joined = current.map((c) => c.row).join(' ⏐ ');
  const departure = DEPARTURE_DATED.exec(joined) ?? DEPARTURE.exec(joined);
  const arrival = ARRIVAL.exec(joined);
  const effective = EFFECTIVE_RANGE.exec(joined);

  // Anything in a status position we do not recognise gets surfaced rather than dropped.
  const statusCandidates = current
    .flatMap((c) => c.row.split('⏐'))
    .flatMap((s) => s.split(/\s{2,}/))
    .map((s) => s.trim())
    .filter((s) => /\b(Active|Effective|Resigned|Deceased|Died|Appointed|Sworn|Removed|Expelled|Vacated|Withdrew|Replaced)\b/i.test(s))
    .filter((s) => !BENIGN.test(s));

  return {
    ...member,
    bio_summary: bio.slice(0, 400),
    service_since: since ? { chamber: since[1], year: Number(since[2]) } : null,
    service_spans: spans,
    assembly_69_rows: current.length,
    arrival_date: arrival ? arrival[1] : null,
    effective_from: effective ? effective[1] : null,
    effective_to: effective ? effective[2] : null,
    departure: departure ? { kind: departure[1], date: departure[2] ?? null } : null,
    status_lines: [...new Set(statusCandidates)],
  };
}

const roster = JSON.parse(fs.readFileSync(ROSTER, 'utf8'));
const out = [];
const failures = [];
let n = 0;
for (const m of roster) {
  n++;
  if (!m.bio_url) {
    failures.push({ ...m, error: 'no bio_url on the roster row' });
    continue;
  }
  try {
    const html = await get(m.bio_url);
    // 🔴 A 404 on this host is a 70 KB styled page, so size proves nothing. Assert the page is
    // the one we asked for: it must name this member in its <h1>.
    const h1 = text(/<h1 class="page-title">([\s\S]*?)<\/h1>/.exec(html)?.[1] ?? '');
    if (!h1 || !h1.includes(m.name)) {
      failures.push({ ...m, error: `page <h1> is ${JSON.stringify(h1)}, which does not name ${m.name}` });
      continue;
    }
    out.push(parseBio(html, m));
  } catch (e) {
    failures.push({ ...m, error: String(e.message ?? e) });
  }
  if (n % 20 === 0) console.log(`  … ${n}/${roster.length}`);
  await sleep(DELAY);
}

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify({ swept_at: new Date().toISOString(), members: out, failures }, null, 2));

const departed = out.filter((m) => m.departure);
const dated = out.filter((m) => m.arrival_date);
const unknownStatus = out.filter((m) => m.status_lines.length && !m.departure && !m.arrival_date);

console.log(`\nswept ${out.length} of ${roster.length} member pages, ${failures.length} failure(s)`);
console.log(`  carrying a DEPARTURE marker on a 69th-Assembly row: ${departed.length}`);
for (const m of departed) console.log(`    🔴 ${m.chamber} ${m.name} (D${m.district}) — ${m.departure.kind} ${m.departure.date ?? '(undated)'}`);
console.log(`  carrying a dated ARRIVAL ("Active <date>"): ${dated.length}`);
for (const m of dated) console.log(`    🟢 ${m.chamber} ${m.name} (D${m.district}) — active ${m.arrival_date}`);
console.log(`  with an unrecognised status line: ${unknownStatus.length}`);
for (const m of unknownStatus) console.log(`    ⚠ ${m.chamber} ${m.name} (D${m.district}) — ${JSON.stringify(m.status_lines)}`);
if (failures.length) {
  console.log('  failures:');
  for (const f of failures) console.log(`    🔴 ${f.name}: ${f.error}`);
}
console.log(`\nwrote ${OUT}`);
