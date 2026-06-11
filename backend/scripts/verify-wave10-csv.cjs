const fs = require('fs');
const content = fs.readFileSync('backend/data/stance-research/2026-06-10-112-va-delegates-wave10.csv', 'utf8');
const lines = content.replace(/\r\n/g,'\n').split('\n').filter(l => l.trim());
const allowed = new Set(['Gretchen M. Bulova','Holly M. Seibold','Marcus B. Simon','Vivian E. Watts','Laura Jane Cohen','Paul E. Krizek']);

function parseRow(line) {
  const fields = [];
  let cur = '', inQ = false;
  for (let i = 0; i < line.length; i++) {
    if (line[i] === '"') inQ = !inQ;
    else if (line[i] === ',' && !inQ) { fields.push(cur); cur = ''; }
    else cur += line[i];
  }
  fields.push(cur);
  return fields;
}

let bad = 0, unsourced = 0;
for (const line of lines.slice(1)) {
  const f = parseRow(line);
  const name = f[0] || '';
  if (!allowed.has(name)) { console.error('BAD NAME: ' + name); bad++; }
  const src = (f[4] || '').trim();
  if (!src) { console.error('NO SOURCE: ' + name + ' / ' + (f[1]||'')); unsourced++; }
}
if (bad === 0 && unsourced === 0) {
  console.log('wave10 CSV OK: ' + (lines.length-1) + ' rows across 6 delegates, all sourced');
} else {
  console.error('FAIL: bad=' + bad + ' unsourced=' + unsourced);
  process.exit(1);
}
