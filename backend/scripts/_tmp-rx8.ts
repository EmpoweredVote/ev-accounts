function normalize(s: string): string {
  return s.normalize('NFD').toLowerCase().replace(/\s+/g, ' ').trim();
}

function extractNameParts(fullName: string) {
  const cleaned = fullName.replace(/^(Dr\.|Mr\.|Ms\.|Mrs\.)\s+/i, '').replace(/\s+(Jr\.|Sr\.|II|III|IV)$/i, '').trim();
  const parts = cleaned.split(/\s+/).filter(Boolean);
  if (parts.length < 2) return null;
  return { first: normalize(parts[0]), last: normalize(parts[parts.length - 1]) };
}

const committeeName = 'ROY FOR LOS ANGELES CITY ATTORNEY 2026; MARISSA';
const np = extractNameParts(committeeName);
console.log('nameParts:', np);

if (np) {
  const lastRe = new RegExp(String.raw`\b` + np.last + String.raw`\b`);
  const firstRe = new RegExp(String.raw`\b` + np.first + String.raw`\b`);
  const politNorm = normalize('Marissa Roy');
  console.log('lastRe source:', lastRe.source, 'test on politNorm:', lastRe.test(politNorm));
  console.log('firstRe source:', firstRe.source, 'test on politNorm:', firstRe.test(politNorm));
}
