function normalize(s: string): string {
  return s
    .normalize('NFD')
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
const np = extractNameParts(committeeName);
console.log('nameParts from committee name:', np);
console.log('politician normalized:', normalize(politicianName));

if (np) {
  const { first, last } = np;
  const escapedLast = last.replace(/[.*+?^${}()|[\]\]/g, '\\$&');
  const escapedFirst = first.replace(/[.*+?^${}()|[\]\]/g, '\\$&');
  const lastRe = new RegExp('\\b' + escapedLast + '\\b');
  const firstRe = new RegExp('\\b' + escapedFirst + '\\b');
  const politNorm = normalize(politicianName);
  console.log('lastRe source:', lastRe.source, '| test:', lastRe.test(politNorm));
  console.log('firstRe source:', firstRe.source, '| test:', firstRe.test(politNorm));
}
