// Probe the ambiguity check used by attribute_quotes.mjs against a surname that is also an
// ordinary English word. Kaohly Her is the case: the pattern `([A-Z][a-z]+)\s+Her` can be
// satisfied by any title-case headline ("Mayor Backs Her Budget Plan"), which would exclude her
// articles as "naming a different Her" — the false-zero failure, not the false-attribution one.
const STOP = new Set(['In', 'When', 'Like', 'But', 'And', 'The', 'For', 'If', 'As', 'At', 'With', 'That', 'This']);

function ambiguousNames(text, surname, ownFirst) {
  const re = new RegExp(`\\b([A-Z][a-z]+)\\s+(?:[A-Z]\\.\\s+){0,2}${surname}\\b`, 'g');
  const fulls = new Set([...text.matchAll(re)].map((m) => m[1]));
  for (const w of [...fulls]) if (STOP.has(w) || w === ownFirst) fulls.delete(w);
  return fulls;
}

const cases = [
  // 🔴 POSITIVE CONTROL FIRST — the check must FIRE here, or every "ok" below is meaningless.
  ['Kennedy', 'Janet', 'Robert Kennedy spoke in Duluth, and Janet Kennedy voted against the measure.', true],
  ['Coleman', 'Molly', 'Former mayor Chris Coleman attended, as did Molly Coleman.', true],
  ['Her', 'Kaohly', 'Mayor Backs Her Budget Plan as Council Pushes Back', null],
  ['Her', 'Kaohly', 'Residents Told Her They Wanted More Shelter Beds', null],
  ['Her', 'Kaohly', 'Advocates Praised Her Decision to Fund the Program', null],
  ['Her', 'Kaohly', 'The council gave Her office until Friday to respond.', null],
  ['Her', 'Kaohly', 'St. Paul Mayor Kaohly Her unveiled the 2027 budget on Tuesday.', false],
];

let controlsFired = 0, controlsExpected = 0;
for (const [surname, first, text, expect] of cases) {
  const hits = ambiguousNames(text, surname, first);
  const fired = hits.size > 0;
  if (expect === true) { controlsExpected++; if (fired) controlsFired++; }
  const tag = expect === true ? (fired ? '✅ CONTROL FIRED' : '🔴 CONTROL DID NOT FIRE')
    : expect === false ? (fired ? '🔴 FALSE POSITIVE' : '✅ correctly clean')
      : (fired ? `🔴 WOULD EXCLUDE -> ${[...hits].join(', ')}` : '   clean');
  console.log(`${tag.padEnd(26)} [${surname}] ${text}`);
}
console.log(`\npositive controls: ${controlsFired}/${controlsExpected} fired`);
if (controlsFired !== controlsExpected) {
  console.error('🔴 THE DETECTOR IS BROKEN — every clean result above is meaningless.');
  process.exit(2);
}
