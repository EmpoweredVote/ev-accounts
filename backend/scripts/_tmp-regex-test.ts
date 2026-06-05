function normalize(s: string): string {
  return s
    .normalize('NFD')
    .toLowerCase()
    .replace(/[.,/#!$%^&*;:{}=\-_`~()]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

const politNorm = normalize('Marissa Roy');
console.log('politNorm:', JSON.stringify(politNorm));

const lastRe = new RegExp(`\bmarissa\b`);
const firstRe = new RegExp(`\broy\b`);

console.log('lastRe:', lastRe.toString());
console.log('lastRe.test(politNorm):', lastRe.test(politNorm));
console.log('firstRe.test(politNorm):', firstRe.test(politNorm));
