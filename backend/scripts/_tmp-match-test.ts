function normalize(s: string): string {
  return s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[.,/#!$%^&*;:{}=\-_`~()]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function extractNameParts(fullName: string): { first: string; last: string } | null {
  const cleaned = fullName
    .replace(/^(Dr\.|Mr\.|Ms\.|Mrs\.)\s+/i, '')
    .replace(/\s+(Jr\.|Sr\.|II|III|IV)$/i, '')
    .trim();
  const parts = cleaned.split(/\s+/).filter(Boolean);
  if (parts.length < 2) return null;
  return {
    first: normalize(parts[0]),
    last: normalize(parts[parts.length - 1]),
  };
}

const committeeName = 'ROY FOR LOS ANGELES CITY ATTORNEY 2026; MARISSA';
const politicianName = 'Marissa Roy';

console.log('Committee name:', committeeName);
console.log('extractNameParts:', extractNameParts(committeeName));
console.log('Politician:', politicianName, '->', normalize(politicianName));

const np = extractNameParts(committeeName);
if (np) {
  const lastRe = new RegExp(`\b${np.last.replace(/[.*+?^${}()|[\]\]/g, '\$&')}\b`);
  const firstRe = new RegExp(`\b${np.first.replace(/[.*+?^${}()|[\]\]/g, '\$&')}\b`);
  const politNorm = normalize(politicianName);
  console.log('last regex:', lastRe, 'test:', lastRe.test(politNorm));
  console.log('first regex:', firstRe, 'test:', firstRe.test(politNorm));
}

// Test the committee name normalization
console.log('\nNormalized committee name:', normalize(committeeName));
console.log('Committee extractNameParts:', extractNameParts(normalize(committeeName)));
