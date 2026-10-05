// Bucket a member's attributed quotes by the ladder each one might bear on, so the reading pass
// starts where the evidence is. Usage: node _triage_quotes.mjs <slug> [--topic <key>]
//
// This does NOT decide anything. A keyword bucket is a reading order, never a finding — the rule
// that attribute_quotes.mjs produces misattributions and every quote must be opened in context
// still holds, and `quote_context.mjs` is still how a row gets settled.
//
// It exists because a re-swept member can carry 128 attributed quotes across 20 live ladders, and
// reading them in corpus order wastes the pass on the 60% that touch no ladder at all.
import fs from 'node:fs';
import path from 'node:path';

const SLUG = process.argv[2];
const ONLY = process.argv.includes('--topic') ? process.argv[process.argv.indexOf('--topic') + 1] : null;
if (!SLUG) { console.error('usage: _triage_quotes.mjs <slug> [--topic <key>]'); process.exit(1); }

const DIR = path.join(process.env.SWEEP_OUT || 'data/stance-news', SLUG);
const att = JSON.parse(fs.readFileSync(path.join(DIR, '_attributed.json'), 'utf8'));

// Keyed to the 20 ladders that are LIVE for a Saint Paul officeholder. The 15 scope blanks are
// facts about Minnesota law and need no evidence, so they are deliberately absent.
const TOPICS = {
  housing: /\b(affordable housing|housing (crisis|units|stock|supply)|subsidi|tax break|public housing|homeowner|renters?)\b/i,
  'rent-regulation': /\b(rent (control|stabiliz|cap)|rent-stabiliz|exemption|landlord|lease)\b/i,
  'residential-zoning': /\b(zoning|upzon|density|duplex|fourplex|accessory dwelling|single-family|setback|lot size)\b/i,
  'growth-and-development': /\b(growth|development pace|infrastructure capacity|build out|expansion)\b/i,
  'economic-development': /\b(incentive|subsid|tax increment|TIF|business|employer|downtown|conversion|vacancy)\b/i,
  homelessness: /\b(encampment|camping|sleeping (in|on) public|shelter bed|clear(ing)? the camp)\b/i,
  'homelessness-response': /\b(homeless|shelter|drop-in|outreach|supportive housing|services)\b/i,
  'public-safety-approach': /\b(police|officer|public safety|crime|patrol|co-responder|mental health call)\b/i,
  'local-immigration': /\b(immigration|ICE|detainer|separation ordinance|undocumented|federal agents?)\b/i,
  'transportation-priorities': /\b(transit|bus|bike|pedestrian|street|road|parking|streetcar|sidewalk)\b/i,
  'local-environment': /\b(environment|pollution|river|green space|tree canopy|watershed|contamina)\b/i,
  'climate-change': /\b(climate|carbon|clean energy|emissions|solar|renewable)\b/i,
  'city-sanitation': /\b(trash|garbage|refuse|recycling|sanitation|litter|collection)\b/i,
  childcare: /\b(child ?care|daycare|early (childhood|learning)|provider)\b/i,
  'minimum-wage': /\b(minimum wage|wage floor|earned sick|paid leave|\$15)\b/i,
  'ranked-choice-voting': /\b(ranked[- ](choice|voting)|ranked ballot|instant runoff)\b/i,
  'civil-rights': /\b(civil rights|discriminat|racial equity|equity office)\b/i,
  'data-centers': /\b(data cent(er|re)|server farm)\b/i,
  'religious-freedom': /\b(religious|faith-based|church|exemption on religious)\b/i,
  '2020-election': /\b(2020 election|stolen election|election fraud|Biden won)\b/i,
};

const buckets = new Map();
const untouched = [];
for (const a of att) {
  const hits = Object.entries(TOPICS).filter(([, re]) => re.test(a.quote));
  if (!hits.length) { untouched.push(a); continue; }
  for (const [k] of hits) {
    if (!buckets.has(k)) buckets.set(k, []);
    buckets.get(k).push(a);
  }
}

if (ONLY) {
  const list = buckets.get(ONLY) || [];
  console.log(`=== ${SLUG} / ${ONLY}: ${list.length} quote(s)\n`);
  list.forEach((a, i) => {
    console.log(`[${i + 1}] ${a.url.replace(/^https?:\/\/(www\.)?/, '').slice(0, 96)}`);
    console.log(`    ${a.quote.slice(0, 420)}\n`);
  });
  process.exit(0);
}

console.log(`=== ${SLUG}: ${att.length} attributed quotes`);
const rows = [...buckets.entries()].sort((a, b) => b[1].length - a[1].length);
for (const [k, v] of rows) console.log(`  ${k.padEnd(27)} ${String(v.length).padStart(3)}`);
console.log(`  ${'(no ladder keyword)'.padEnd(27)} ${String(untouched.length).padStart(3)}`);
const covered = rows.length;
console.log(`\nladders with at least one candidate quote: ${covered} of ${Object.keys(TOPICS).length}`);
console.log('⚠ A bucket is a READING ORDER, not a finding. Open each quote in context before it becomes a row.');
