/**
 * Every Duluth councilor page states "Term Expires: <date>". Read all nine.
 *
 * 🔴🔴 THIS IS THE CHANGE-CHECK SIGNAL FOR A CITY COUNCIL, AND A LANGUAGE SCANNER IS BLIND TO IT.
 * sweep-member-pages.mjs looks for words -- resigned, vacant, appointed, sworn in -- and reported
 * exactly one benign hit across all 18 pages. It could not see that Terese Tomanek's page says
 * "Term Expires: January 5, 2026", a date eight months in the PAST. Nothing on the page is worded
 * as a problem. The defect is a number, and only comparing it to today finds it.
 *
 * A past expiry is not itself proof that the seat changed hands -- an incumbent may have been
 * re-elected and the page simply not updated. It is a READING QUEUE, and each one is settled
 * against the election result, never assumed either way.
 *
 *   node read-duluth-terms.mjs
 */
import fs from 'fs';

const strip = (h) =>
  h
    .replace(/<script[\s\S]*?<\/script>/g, ' ')
    .replace(/<style[\s\S]*?<\/style>/g, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
    .replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ');

const TODAY = new Date('2026-09-14T00:00:00Z');
const rows = JSON.parse(fs.readFileSync('_member-pages-index.json', 'utf8')).filter((r) => r.city === 'Duluth');

const out = [];
for (const r of rows) {
  const t = strip(fs.readFileSync(r.file, 'utf8'));
  const m = /Term Expires:\s*([A-Z][a-z]+ \d{1,2}, \d{4})/.exec(t);
  const seatLine = /((?:First|Second|Third|Fourth|Fifth) Council District|Councilor At Large)/.exec(t);
  const precincts = /Precincts:\s*([\d\-, ]+?)\s+Term/.exec(t);
  out.push({
    seat: r.seat,
    name: r.name,
    page_seat: seatLine ? seatLine[1] : null,
    precincts: precincts ? precincts[1].trim() : null,
    expires: m ? m[1] : null,
    expires_iso: m ? new Date(`${m[1]} UTC`).toISOString().slice(0, 10) : null,
  });
}

console.log('seat         member                page says              precincts  term expires   status');
for (const o of out) {
  const past = o.expires_iso && new Date(o.expires_iso + 'T00:00:00Z') < TODAY;
  console.log(
    `${String(o.seat).padEnd(12)} ${String(o.name).padEnd(20)} ${String(o.page_seat ?? '-').padEnd(22)} ${String(o.precincts ?? '-').padEnd(10)} ${String(o.expires ?? 'NONE STATED').padEnd(14)} ${past ? '🔴 EXPIRED -- read it' : o.expires_iso ? 'current' : '⚠ no date on page'}`,
  );
}

const expired = out.filter((o) => o.expires_iso && new Date(o.expires_iso + 'T00:00:00Z') < TODAY);
console.log(`\nseats whose stated term has ALREADY EXPIRED as at ${TODAY.toISOString().slice(0, 10)}: ${expired.length}`);
for (const e of expired) console.log(`  ${e.seat} ${e.name} -- expired ${e.expires_iso}`);

// A count of nine "current" would be a uniform answer; show the distribution instead.
const byYear = {};
for (const o of out) if (o.expires_iso) byYear[o.expires_iso] = (byYear[o.expires_iso] || 0) + 1;
console.log('\nexpiry distribution (Duluth staggers its council, so this must NOT be uniform):');
for (const k of Object.keys(byYear).sort()) console.log(`  ${k}  ${byYear[k]} seat(s)`);

fs.writeFileSync('_duluth-terms.json', JSON.stringify(out, null, 1));
