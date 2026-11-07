// Build the 47 people to seed: name split, and a source URL that really names them.
//
// 🔴 THERE IS NO AP SURNAME FIELD HERE. CC_0359 could assert every split against AP's own
//    `last`; AP publishes none of these offices, so Ballotpedia is alone and nothing outside
//    the name itself says where the surname starts. 44 of the 47 are two words and have only
//    one possible split. The other three were read off their own articles one at a time, and
//    are listed below rather than guessed — "Stephanie Garcia Richard" is not ("Stephanie
//    Garcia", "Richard") and a last-token rule would say it is.
//
// 🔴 AND TWO "PERSONAL" LINKS WERE NOT PERSONAL. On a ticket row the second link is supposed to
//    be the running mate's article; for David M. Gallegos and John Thomas it is an ANCHOR INTO
//    THE GOVERNOR CANDIDATE'S page (#Campaign_themes). Citing it would attribute one person's
//    page to another — a fabricated citation in the only field that carries provenance. A slug
//    check catches it, and those two cite the state page instead, which does name them.
import fs from 'node:fs';
const SP = process.argv[2];
const R = JSON.parse(fs.readFileSync(`${SP}/resolved-bp.json`, 'utf8'));
const STATES = JSON.parse(fs.readFileSync(`${SP}/all-states.json`, 'utf8'));
const FETCHED = '2026-11-06';

const SPLIT = {
  // read from ballotpedia.org/Stephanie_Garcia_Richard — New Mexico's Commissioner of Public
  // Lands; the surname is the pair "Garcia Richard", not "Richard".
  'Stephanie Garcia Richard': ['Stephanie', 'Garcia Richard'],
  // a middle initial, not a middle name
  'David M. Gallegos': ['David M.', 'Gallegos'],
  // an initial plus a given name, and a hyphenated surname
  'V. Alonzo Echavarria-Garza': ['V. Alonzo', 'Echavarria-Garza'],
};

const nmk = s => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z]/g, '');
const statePage = st => `https://ballotpedia.org/${(STATES[st] || '').replace(/ /g, '_')}_state_executive_official_elections,_2026`;

const seeds = [], notes = [];
for (const c of R.creates.filter(x => !x.politicianId)) {
  let first, last;
  if (SPLIT[c.name]) { [first, last] = SPLIT[c.name]; }
  else {
    const t = c.name.split(/\s+/);
    if (t.length !== 2) throw new Error(`no split rule for "${c.name}" (${t.length} tokens) — read the article, do not guess`);
    [first, last] = t;
  }
  if (!c.name.startsWith(first) || !c.name.endsWith(last)) throw new Error(`split does not reconstruct "${c.name}"`);

  // the URL must be this person's own article: no fragment, and the slug must be their name
  const slug = c.url ? decodeURIComponent(c.url.split('/').pop().split('#')[0]).replace(/_/g, ' ').replace(/\s*\(.*\)$/, '') : '';
  const own = c.url && !c.url.includes('#') && nmk(slug) === nmk(c.name);
  const src = own
    ? `${c.url} (Ballotpedia, read ${FETCHED})`
    : `${statePage(c.st)} (Ballotpedia, read ${FETCHED} — this person has no article of their own; the state page's ${c.office} table names them)`;
  if (!own) notes.push(`${c.st} ${c.office}: ${c.name} — cited to the state page (${c.url ? 'its "personal" link was ' + c.url : 'no link'})`);

  seeds.push({ ...c, first_name: first, last_name: last, source: `${src}; outcome from the same page's winner flag (CC_0360)` });
}
fs.writeFileSync(`${SP}/seeds-bp.json`, JSON.stringify(seeds, null, 1));
console.log(`seeds: ${seeds.length}`);
console.log(`  split by rule (two tokens): ${seeds.length - Object.keys(SPLIT).filter(k => seeds.some(s => s.name === k)).length}`);
console.log(`  split read off their article: ${Object.keys(SPLIT).filter(k => seeds.some(s => s.name === k)).length}`);
console.log(`  cited to their own article: ${seeds.filter(s => /\(Ballotpedia, read .*\)$/.test(s.source.split(';')[0])).length}`);
console.log(`\n${notes.length} seed(s) NOT cited to a personal article:`);
for (const n of notes) console.log('  ⚠ ' + n);
const dup = Object.entries(seeds.reduce((a, s) => { a[s.name] = (a[s.name] || 0) + 1; return a; }, {})).filter(([, v]) => v > 1);
console.log(`\nnames appearing twice among the seeds: ${dup.length}`);
for (const [n, v] of dup) console.log(`  ${n} x${v}`);
