#!/usr/bin/env node
// Re-verify, from the COUNTY'S OWN RAW CANDIDATE LIST, that each named person took out
// nomination papers and never returned them.
//
// 🔴 THIS DELETES NOTHING. It exists because the disposition is a DELETE against production and
//   "the earlier pass said so" is not evidence. The RR/CC publishes two dates per candidate row
//   — nom_issue (papers taken out) and nom_file (papers returned and ACCEPTED) — and only the
//   second is a candidacy. ONE date means issued and never filed; TWO means filed.
// 🔴 IT READS THE RAW HTML, not this wave's own derived nominations-*.json. Re-checking a
//   derivation against the thing it was derived from proves only that the derivation is stable.
//
// Two parser traps met while writing it, both of which first read as findings about the data:
// 🔴 THE CONTEST IS INSIDE THE ROW, NOT IN A HEADING ABOVE IT. Looking backwards for the
//   nearest heading put Radabaugh in Whittier Union and Morales in La Cañada — both wrong, and
//   both plausible.
// 🔴 A BARE SUBSTRING MATCH ON A SURNAME IS NOT A NAME MATCH: "Ector" is inside "Director",
//   so it matched 118 rows. Every name here is matched on word boundaries.
import fs from 'node:fs';

const file = process.argv[2] || 'la-candidate-list-2026-11-08.html';
const html = fs.readFileSync(file, 'utf8');
if (html.length < 100000) throw new Error(file + ' is ' + html.length + ' bytes - too small to be the full list');

const decode = (s) => s
  .replace(/<[^>]+>/g, ' ')
  .replace(/&nbsp;/g, ' ')
  .replace(/&amp;/g, '&')
  .replace(/&#x([0-9A-Fa-f]+);/g, (_, c) => String.fromCodePoint(parseInt(c, 16)))
  .replace(/&#(\d+);/g, (_, c) => String.fromCodePoint(parseInt(c, 10)))
  .replace(/\s+/g, ' ').trim();

const rows = [...html.matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/gi)]
  .map((m) => decode(m[1]))
  .map((txt) => ({ txt, dates: txt.match(/\d{1,2}\/\d{1,2}\/\d{4}/g) || [] }))
  .filter((r) => r.dates.length > 0);

// POSITIVE CONTROL: the parse must be able to SEE a filing, or "no second date" below means
// only that this script reads no dates.
const filed = rows.filter((r) => r.dates.length >= 2);
const issuedOnly = rows.filter((r) => r.dates.length === 1);
if (filed.length < 100) throw new Error('only ' + filed.length + ' rows show a filing - the parse cannot see filings, so every "never filed" below would be vacuous');

console.log('candidate rows parsed: ' + rows.length);
console.log('  showing a filing (two dates), the positive control: ' + filed.length);
console.log('  issued only (one date): ' + issuedOnly.length);
console.log('');

const TARGETS = [
  { name: 'Tavia Lorese Lawson', surname: 'LAWSON', contest: 'AZUSA UNIFIED' },
  { name: 'Carissa Oldenburg', surname: 'OLDENBURG', contest: 'BURBANK UNIFIED' },
  { name: 'Alan Reynolds', surname: 'REYNOLDS', contest: 'SOUTH PASADENA UNIFIED' },
  { name: 'Joe Radabaugh', surname: 'RADABAUGH', contest: 'LA CAÑADA UNIFIED' },
  { name: 'Alfonso Morales', surname: 'MORALES', contest: 'LYNWOOD UNIFIED' },
  { name: 'Rick Phillips', surname: 'PHILLIPS', contest: 'PALOS VERDES' },
  { name: 'Tomas Ursua', surname: 'URSUA', contest: 'POMONA UNIFIED' },
  { name: 'Raycine Ector', surname: 'ECTOR', contest: 'PALMDALE' },
];

const word = (s) => new RegExp('(^|[^A-Za-z])' + s + '([^A-Za-z]|$)', 'i');
let bad = 0;
for (const t of TARGETS) {
  const first = t.name.split(' ')[0];
  const hits = rows.filter((r) => word(t.surname).test(r.txt) && word(first).test(r.txt));
  if (hits.length !== 1) {
    bad++;
    console.log('  🔴 ' + t.name.padEnd(21) + ' matches ' + hits.length + ' rows — ambiguous, DO NOT DELETE');
    for (const h of hits) console.log('        ' + h.txt.slice(0, 150));
    continue;
  }
  const r = hits[0];
  const contestOk = r.txt.toUpperCase().includes(t.contest.toUpperCase());
  const neverFiled = r.dates.length === 1;
  if (!neverFiled || !contestOk) bad++;
  console.log('  ' + (neverFiled && contestOk ? 'ok' : '🔴') + ' ' + t.name.padEnd(21)
    + ' dates=' + JSON.stringify(r.dates)
    + (neverFiled ? '  issued, NEVER FILED' : '  FILED — DO NOT DELETE')
    + (contestOk ? '' : '  🔴 contest does not contain "' + t.contest + '"'));
  console.log('        ' + r.txt.replace(/\s+/g, ' ').slice(0, 170));
}

console.log('');
console.log(bad === 0
  ? 'VERIFIED: all ' + TARGETS.length + ' took out nomination papers and not one returned them.'
  : bad + ' row(s) do NOT support a delete');
process.exit(bad ? 1 : 0);
