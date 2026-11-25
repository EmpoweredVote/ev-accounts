#!/usr/bin/env node
// verify-collect.mjs — checks every cities/<slug>.json the collectors wrote.
//
// For each city it checks:
//   1. structure is internally consistent (district + at-large = council size);
//   2. the holder list has one Mayor, one clerk, and exactly the council seats the structure names;
//   3. EVERY holder name appears in the saved page it cites (raw/<slug>/...). WebFetch and search
//      summaries invent names, so a name that is not in a saved page is refused. Matching folds
//      case, HTML entities, tags and whitespace, and accepts the surname + first name in either order
//      only as a WARNING, never as a pass.
//   4. a positive control and a negative control run first, so a blind matcher cannot report "all found".
//
// Prints every row it checked, not only failures. Exit 1 if any city has a FAIL.
// Usage: node verify-collect.mjs [slug ...]
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const DIR = path.dirname(new URL(import.meta.url).pathname);

function pageText(file) {
  // PDFs are read through pdftotext; HTML is read as UTF-8 (latin1 turned non-breaking spaces into 'Â ' and
  // hid 'Brett Weddell'), and image alt text is kept, because some city pages name a member only there.
  if (/\.pdf$/i.test(file)) return fold(execFileSync('pdftotext', ['-layout', file, '-'], { maxBuffer: 64 << 20 }).toString('utf8'));
  const buf = fs.readFileSync(file);
  const raw = buf.toString('utf8').includes('\uFFFD') ? buf.toString('latin1') : buf.toString('utf8');
  let t = raw.replace(/<(script|style)[\s\S]*?<\/\1>/gi, ' ').replace(/<img[^>]*\balt="([^"]*)"[^>]*>/gi, ' $1 ').replace(/<[^>]+>/g, ' ');
  t = t.replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
       .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
       .replace(/&nbsp;|\u00a0/g, ' ').replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&apos;|&#39;|&rsquo;|&lsquo;/g, "'");
  return fold(t);
}
function fold(s) {
  return s.normalize('NFKD').replace(/[̀-ͯ]/g, '').replace(/[‘’]/g, "'")
          .toLowerCase().replace(/[^a-z0-9'.\- ]+/g, ' ').replace(/\s+/g, ' ').trim();
}
function nameIn(name, text) {
  const n = fold(name);
  if (text.includes(n)) return 'exact';
  // Loose: drop middle initials and suffixes, require first + last as words.
  const parts = n.replace(/\b[a-z]\.\s*/g, '').replace(/\b(jr|sr|ii|iii|iv)\.?\b/g, '').split(' ').filter(Boolean);
  if (parts.length < 2) return null;
  const first = parts[0], last = parts[parts.length - 1];
  const re = new RegExp(`\\b${first}\\b.{0,20}?\\b${last}\\b|\\b${last}\\b,?\\s+${first}\\b`);
  return re.test(text) ? 'loose' : null;
}

// ─── Controls: the matcher must find a planted name and must NOT find an absent one ───
{
  const text = pageText(writeTmp('<p>Council&nbsp;Member <b>Jane&#32;Q. Doe</b>, District 2</p>'));
  // Absent-name check first, so a matcher that accepts too much is caught by THIS gate, not shadowed.
  if (nameIn('John Smith', text) !== null) { console.error('CONTROL FAILED: absent name matched'); process.exit(2); }
  if (nameIn('Jane Q. Doe', text) !== 'exact') { console.error('CONTROL FAILED: planted name not found'); process.exit(2); }
  if (nameIn('Jane Doe', text) !== 'loose') { console.error('CONTROL FAILED: loose match missed'); process.exit(2); }
}
function writeTmp(html) { const f = path.join(DIR, '.control.html'); fs.writeFileSync(f, html); const r = f; process.on('exit', () => { try { fs.unlinkSync(r); } catch {} }); return f; }

const cities = JSON.parse(fs.readFileSync(path.join(DIR, 'wave-b-cities.json'), 'utf8'));
const want = process.argv.slice(2);
let anyFail = false;
for (const c of cities) {
  if (want.length && !want.includes(c.slug)) continue;
  const f = path.join(DIR, 'cities', `${c.slug}.json`);
  console.log(`\n=== ${c.slug}`);
  if (!fs.existsSync(f)) { console.log('  MISSING  no cities/<slug>.json yet'); continue; }
  const j = JSON.parse(fs.readFileSync(f, 'utf8'));
  const s = j.structure || {};
  const fails = [], warns = [];
  if (s.district_seats + s.at_large_seats !== s.council_size) fails.push(`structure: ${s.district_seats}+${s.at_large_seats} != ${s.council_size}`);
  console.log(`  structure  council ${s.council_size} = ${s.district_seats} district + ${s.at_large_seats} at-large · ${s.clerk_title} · judge ${s.city_court_judge}`);
  const H = j.holders || [];
  const count = (re) => H.filter((h) => re.test(h.office)).length;
  if (count(/^Mayor$/) !== 1) fails.push(`holders: ${count(/^Mayor$/)} Mayor rows`);
  if (count(/^(City Clerk|Clerk-Treasurer|City Clerk-Treasurer)$/) !== 1) fails.push(`holders: ${count(/^(City Clerk|Clerk-Treasurer|City Clerk-Treasurer)$/)} clerk rows`);
  const dist = H.filter((h) => /District \d+$/.test(h.office)).map((h) => Number(h.office.match(/(\d+)$/)[1]));
  const distSet = new Set(dist);
  if (dist.length !== s.district_seats || distSet.size !== dist.length) fails.push(`holders: districts ${JSON.stringify(dist)} vs ${s.district_seats} seats`);
  for (let i = 1; i <= s.district_seats; i++) if (!distSet.has(i)) fails.push(`holders: no District ${i}`);
  if (count(/At Large$/i) !== s.at_large_seats) fails.push(`holders: ${count(/At Large$/i)} at-large vs ${s.at_large_seats}`);
  for (const h of H) {
    let verdict;
    if (!h.name) verdict = 'BLANK';
    else if (!h.source_file || !fs.existsSync(path.join(DIR, h.source_file))) verdict = 'NO-FILE';
    else verdict = nameIn(h.name, pageText(path.join(DIR, h.source_file))) ?? 'NOT-IN-PAGE';
    const mark = verdict === 'exact' ? 'ok  ' : verdict === 'loose' ? 'warn' : 'FAIL';
    if (mark === 'FAIL') fails.push(`${h.office}: ${h.name} ${verdict}`);
    if (mark === 'warn') warns.push(`${h.office}: ${h.name} loose`);
    console.log(`  ${mark} ${h.office.padEnd(28)} ${String(h.name).padEnd(28)} ${verdict.padEnd(11)} ${h.source_file ?? ''}${h.note ? '  · ' + h.note : ''}`);
  }
  const m = j.council_map || {};
  console.log(`  map        ${m.kind} · count ${m.feature_count} · field ${m.district_field} · ${m.url}`);
  if (m.kind === 'arcgis' && m.feature_count !== s.district_seats) warns.push(`map: ${m.feature_count} features vs ${s.district_seats} districts`);
  for (const w of warns) console.log(`  WARN  ${w}`);
  for (const x of fails) console.log(`  FAIL  ${x}`);
  if (fails.length) anyFail = true;
  console.log(`  => ${fails.length ? 'FAIL' : 'PASS'} (${H.length} holders, ${warns.length} warnings)`);
}
process.exit(anyFail ? 1 : 0);
