import { readFileSync } from 'node:fs';
const C = process.env.TEMP + '/ev-stance-cache/wa-leg';
const IDX = JSON.parse(readFileSync(C + '/sponsorship-index-full.json', 'utf8'));
const LINK = JSON.parse(readFileSync(C + '/member-link.json', 'utf8')).link;
const BY = Object.fromEntries(Object.values(LINK).map((v) => [v.memberId, v]));
const pat = new RegExp(process.argv[2], 'i');
for (const name of process.argv.slice(3)) {
  const mid = Object.keys(BY).find((m) => BY[m].name === name);
  const v = IDX.members[mid];
  console.log(`\n### ${name}`);
  for (const role of ['primary', 'secondary'])
    for (const b of v[role])
      if (pat.test(`${b.desc} ${b.long}`))
        console.log(`   ${role === 'primary' ? 'PRIME' : 'co   '} ${b.enacted ? 'ENACT' : 'died '} ${b.billId.padEnd(9)} ${b.long.slice(0, 82)}`);
}
