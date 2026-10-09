// Control-test for isTitleCase() in attribute_quotes.mjs.
//
// A surname that is also an ordinary English word turns every title-case headline into a phantom
// second person — "Mayor Backs Her Budget Plan" reads as a person called Backs Her. No stoplist can
// enumerate every English verb, so the discriminator is the SHAPE of the surrounding text: in a
// headline nearly every word is capitalised, in prose almost none are.
//
// 🔴 This file exists because three attempts to test this through `node -e` were silently mangled
// by shell escaping and returned a uniform answer — the broken-detector signature, twice in one
// session. Regex tests go in a file.
//
// The predicate below MUST be kept identical to the one in attribute_quotes.mjs.
function isTitleCase(text, i, len) {
  const before = text.slice(Math.max(0, i - 60), i).split(/\s+/).filter(Boolean).slice(-4);
  const after = text.slice(i + len, i + len + 60).split(/\s+/).filter(Boolean).slice(0, 4);
  const words = [...before, ...after].filter((w) => /^[A-Za-z]{4,}$/.test(w));
  if (words.length < 3) return false;
  const caps = words.filter((w) => /^[A-Z]/.test(w)).length;
  return caps / words.length >= 0.75;
}

const cases = [
  ['Her', 'HEADLINE must be IGNORED', 'Saint Paul Minnesota Mayor Backs Her Budget Plan as Council Pushes Back Again', true],
  ['Her', 'HEADLINE must be IGNORED', 'Local News Residents Told Her They Wanted More Shelter Beds Downtown Soon', true],
  ['Her', 'HEADLINE must be IGNORED', 'Opinion Editorial Advocates Praised Her Decision to Fund Shelter Programs', true],
  ['Her', 'PROSE, REAL PERSON must be KEPT', 'The council heard from Ilean Her, who directed the state council, before members voted on the measure', false],
  ['Her', 'PROSE, REAL PERSON must be KEPT', 'A longtime advocate named Lo Her told reporters that the plan would help families across this city', false],
  ['Kennedy', 'PROSE CONTROL must be KEPT', 'Robert Kennedy spoke in Duluth today, and Janet Kennedy voted against the measure tonight', false],
  ['Coleman', 'PROSE CONTROL must be KEPT', 'Former mayor Chris Coleman attended the event, as did councilmember Molly Coleman yesterday', false],
];

let bad = 0, matched = 0;
for (const [surname, label, text, expect] of cases) {
  const re = new RegExp(`\\b([A-Z][a-z]+)\\s+${surname}\\b`, 'g');
  const m = [...text.matchAll(re)][0];
  if (!m) { console.log(`🔴 ${label.padEnd(32)} NO MATCH — the probe itself is broken, not the predicate`); bad++; continue; }
  matched++;
  const got = isTitleCase(text, m.index, m[0].length);
  const ok = got === expect;
  if (!ok) bad++;
  console.log(`${ok ? '✅' : '🔴'} ${label.padEnd(32)} "${m[1]} ${surname}"  titleCase=${got} (want ${expect})`);
}
// 🔴 The probe must be shown to have MATCHED something. A regex that matches nothing reports a
// clean sweep for free — which is exactly how the three shell-mangled attempts "passed".
console.log(`\nmatches found: ${matched}/${cases.length}`);
if (matched !== cases.length) { console.error('🔴 THE PROBE DID NOT MATCH EVERY CASE — results above are meaningless.'); process.exit(2); }
console.log(bad ? `🔴 ${bad} FAILED` : '✅ all pass — headlines ignored, real people in prose kept');
process.exit(bad ? 1 : 0);
