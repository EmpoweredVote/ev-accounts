// Positive AND negative control for the attribution matcher.
// Usage: node _attr_selftest.mjs
// 🔴 Run after ANY change to the quote regex, the TITLE list or the stoplist. Each of those has
// silently reduced the yield to something indistinguishable from "this member is rarely quoted".
// It imports the real matcher — a control that re-implements its subject is not a control.
import { findAttributed, parseName } from './attribution.mjs';

const LQ = String.fromCharCode(8220), RQ = String.fromCharCode(8221);

const NAMEPARSE = [
  ['Lynn Marie Nephew', 'Lynn', ['Marie'], 'Nephew'],
  ['Arik Forsman', 'Arik', [], 'Forsman'],
  ['Mary Jo Van Der Berg', 'Mary', ['Jo','Van','Der'], 'Berg'],
];
for (const [full, f2, m2, s2] of NAMEPARSE) {
  const p = parseName(full);
  const ok = p.first === f2 && p.surname === s2 && p.middles.join(' ') === m2.join(' ');
  console.log(`${ok ? 'PASS' : '🔴 FAIL'}  parseName  ${full} -> ${p.first} | ${p.middles.join(' ')} | ${p.surname}`);
  if (!ok) process.exitCode = 1;
}

const CASES = [
  ['real WDIO passage, stray quoted phrase before it (the pairing bug)',
    '3rd District Councilor Roz Randorf arguing in favor of the "Right to Repair ordinance". "Tenants do have protections already under the state of Minnesota," said Councilor Durwachter. "I think that should be considered."',
    'Wendy', 'Durwachter', true],
  ['straight quotes, Duluth title after the verb',
    '"Tenants do have protections already under the state of Minnesota," said Councilor Durwachter. "I think that should be considered."',
    'Wendy', 'Durwachter', true],
  ['curly quotes, name before the verb',
    `${LQ}We want this project done now. We need it,${RQ} Randorf said. ${LQ}We need a safe place for them to go.${RQ}`,
    'Roz', 'Randorf', true],
  ['straight quotes, name before the verb',
    '"This is the exact same funding. So $200,000. And the thing that I like the most about it is real," Randorf said.',
    'Roz', 'Randorf', true],
  ['NEGATIVE — quoted, on topic, but attributed to nobody',
    '"Something entirely unrelated was said here by a person with no name attached at all," the report noted.',
    'Roz', 'Randorf', false],
  ['NEGATIVE — the next sentence merely BEGINS with the name (the school-principal bug)',
    '"If a kid missed the bus, she would be willing to take them home for the evening." Nelsie Yang, who is now a council member, got to know her at school.',
    'Nelsie', 'Yang', false],
  ['three-token name: the middle name must NOT break the match',
    'Council President Lynn Marie Nephew said the policy needs work. "I do think there are holes in this and it is a place to start for now," Nephew said.',
    'Lynn', ['Marie'], 'Nephew', true],
  ['NEGATIVE — quote belongs to someone else, member named after it (the Grondahl bug)',
    '"Duluthians are clear that passing this common-sense policy is the next step renters deserve," Grondahl said. Durwachter said she has remained in contact.',
    'Wendy', 'Durwachter', false],
];

let pass = 0, fail = 0;
for (const [label, text, first, a, b, c] of CASES) {
  const middles = Array.isArray(a) ? a : [];
  const surname = Array.isArray(a) ? b : a;
  const must = Array.isArray(a) ? c : b;
  const found = findAttributed(text, first, middles, surname).length > 0;
  const ok = found === must;
  console.log(`${ok ? 'PASS' : '🔴 FAIL'}  ${must ? 'must find   ' : 'must NOT find'}  ${label}`);
  ok ? pass++ : fail++;
}
console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
