/**
 * Change-check sweep: does either chamber's OWN per-member page say the member has left?
 *
 * The roster LIST pages do not answer this. house.mn.gov/members/ still lists Joe Schomacker
 * (21A) three months after he resigned; neither chamber publishes a "vacant" marker anywhere.
 * The only in-band signal is a banner on the individual profile, so every seat is fetched.
 *
 * A zero is not trusted: --control plants each defect shape into a copy of one page and
 * requires it to be reported.
 */
import fs from 'fs';

const strip = (h) =>
  h
    .replace(/<script[\s\S]*?<\/script>/g, ' ')
    .replace(/<style[\s\S]*?<\/style>/g, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ');

const PATTERNS = [
  /\bresign\w*[^.]{0,130}/gi,
  /\bvacan\w*[^.]{0,90}/gi,
  /\bdeceased\b[^.]{0,90}/gi,
  /\bpassed away[^.]{0,90}/gi,
  /\bsworn in[^.]{0,90}/gi,
  /\bspecial election[^.]{0,90}/gi,
];

function scan(text) {
  const out = [];
  for (const re of PATTERNS) {
    const hits = text.match(re);
    if (hits) for (const h of hits) out.push(h.trim().replace(/\s+/g, ' ').slice(0, 150));
  }
  return out;
}

const seats = [];
for (const r of JSON.parse(fs.readFileSync('_house-profiles-index.json', 'utf8'))) {
  seats.push({ chamber: 'House', label: r.dist, name: r.name, file: `_house-profiles/${r.pid}.html` });
}
for (const r of JSON.parse(fs.readFileSync('_senate-bios-index.json', 'utf8'))) {
  seats.push({ chamber: 'Senate', label: String(Number(r.dist)), name: r.name, file: `_senate-bios/${r.mem_id}.html` });
}

// --- the page really is this member's page -------------------------------------------------
const HOUSE_HDR = /Back to Members List\s+Rep\.\s+([^(]{1,60}?)\s+Rep\./;
const SENATE_HDR = /Senator\s+([^()]{1,60}?)\s*\((\d{1,2}),\s*([A-Z]+)\)/;
let identityFailures = 0;
const notes = [];
for (const s of seats) {
  const text = strip(fs.readFileSync(s.file, 'utf8'));
  s.text = text;
  const m = s.chamber === 'House' ? HOUSE_HDR.exec(text) : SENATE_HDR.exec(text);
  if (!m) {
    identityFailures++;
    console.log(`IDENTITY: no header parsed  ${s.chamber} ${s.label} ${s.name}`);
    continue;
  }
  const pageName = m[1].trim();
  if (pageName !== s.name.trim()) {
    identityFailures++;
    console.log(`IDENTITY: ${s.chamber} ${s.label} roster="${s.name}" page="${pageName}"`);
  }
  for (const n of scan(text)) notes.push({ ...s, note: n, text: undefined });
}

console.log(`seats swept: ${seats.length} (House ${seats.filter((s) => s.chamber === 'House').length}, Senate ${seats.filter((s) => s.chamber === 'Senate').length})`);
console.log(`identity failures: ${identityFailures}`);
console.log(`status-language hits: ${notes.length}`);
for (const n of notes) console.log(`  ${n.chamber} ${n.label.padEnd(4)} ${n.name.padEnd(26)} :: ${n.note}`);

if (process.argv.includes('--control')) {
  console.log('\n-- POSITIVE CONTROLS (the detector must FAIL before the fix is believed) ------');
  const base = seats.find((s) => s.chamber === 'Senate' && s.label === '35');
  const shapes = [
    ['resignation banner', 'Resigning effective 11:59 p.m. Sunday, June 21st 2026'],
    ['vacancy wording', 'This seat is currently vacant'],
    ['death wording', 'Senator Control passed away on March 1, 2026'],
    ['successor wording', 'was sworn in on February 3, 2026 following a special election'],
  ];
  for (const [label, planted] of shapes) {
    const n = scan(base.text + ' ' + planted).length;
    console.log(`  ${label.padEnd(20)} planted into SD-35 -> ${n} hit(s) ${n > 0 ? 'OK' : 'FAILED'}`);
  }
  const untouched = scan(base.text).length;
  console.log(`  unmodified SD-35            -> ${untouched} hit(s) ${untouched === 0 ? 'OK (baseline)' : 'baseline is NOT clean'}`);
}
