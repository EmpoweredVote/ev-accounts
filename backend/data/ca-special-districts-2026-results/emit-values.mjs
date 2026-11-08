#!/usr/bin/env node
// Emit the migration's VALUES list straight from the analysis, so no row is retyped by hand.
import fs from 'node:fs';
const a = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const q = (s) => "'" + String(s).replace(/'/g, "''") + "'";
let won = 0, lost = 0;
const lines = [];
for (const r of a.report.filter((x) => x.callable).sort((x, y) => x.district.localeCompare(y.district))) {
  lines.push(`  -- ${r.district} — ${r.office_title}, ${r.seats} seat(s); margin ${r.count.margin} vs bound ${r.count.bound}`);
  for (const k of r.ranked) {
    if (k.outcome === 'won') won++; else lost++;
    lines.push(`  (${q(r.district)}, ${q(r.office_title)}, '${r.race_id}'::uuid, '${k.rc_id}'::uuid, ${q(k.name)}, ${k.votes}, ${k.rank}, ${q(k.outcome)}),`);
  }
}
lines[lines.length - 1] = lines[lines.length - 1].replace(/,$/, ';');
console.log(lines.join('\n'));
console.error(`-- ${won} won / ${lost} lost across ${a.report.filter((x) => x.callable).length} races`);
