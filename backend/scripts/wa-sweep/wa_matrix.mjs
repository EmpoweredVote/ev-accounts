import { readFileSync } from 'node:fs';
const C = process.env.TEMP + '/ev-stance-cache/wa-leg';
const IDX = JSON.parse(readFileSync(C + '/sponsorship-index-full.json', 'utf8'));
const LINK = JSON.parse(readFileSync(C + '/member-link.json', 'utf8')).link;
const BY = Object.fromEntries(Object.values(LINK).map((v) => [v.memberId, v]));
const cohortBill = process.argv[2];
const cols = process.argv.slice(3);
const sponsorsOf = (id) => {
  const s = new Set();
  for (const [mid, v] of Object.entries(IDX.members)) {
    if (!BY[mid]) continue;
    for (const role of ['primary', 'secondary']) for (const b of v[role]) if (b.billId === id) s.add(mid);
  }
  return s;
};
const base = [...sponsorsOf(cohortBill)].sort((a, b) => BY[a].name.localeCompare(BY[b].name));
const sets = Object.fromEntries(cols.map((c) => [c, sponsorsOf(c)]));
console.log('member'.padEnd(22) + cols.map((c) => c.replace('SB ', '')).join(' '));
for (const m of base) {
  const row = cols.map((c) => (sets[c].has(m) ? ' ✓  ' : ' .  ')).join('');
  console.log(`${(BY[m].name + ' (' + BY[m].party + ')').padEnd(22)}${row}`);
}
