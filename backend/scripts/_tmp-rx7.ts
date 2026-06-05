function normalize(s: string): string {
  return s.normalize('NFD').toLowerCase().replace(/\s+/g, ' ').trim();
}

const committeeName = 'ROY FOR LOS ANGELES CITY ATTORNEY 2026; MARISSA';
const politicianName = 'Marissa Roy';
const parts = committeeName.split(/\s+/).filter(Boolean);
const first = normalize(parts[0]);   // 'roy'
const last = normalize(parts[parts.length - 1]);  // 'marissa'
console.log('first:', first, 'last:', last);

const politNorm = normalize(politicianName);  // 'marissa roy'
console.log('politNorm:', politNorm);

// Test with String.raw for explicit \b
const lastPat = String.raw`\b` + last + String.raw`\b`;
const firstPat = String.raw`\b` + first + String.raw`\b`;
const lastRe2 = new RegExp(lastPat);
const firstRe2 = new RegExp(firstPat);
console.log('lastRe2 source:', lastRe2.source, 'test:', lastRe2.test(politNorm));
console.log('firstRe2 source:', firstRe2.source, 'test:', firstRe2.test(politNorm));
