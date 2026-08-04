import 'dotenv/config';
import { readFileSync, writeFileSync } from 'fs';
import { Pool } from 'pg';

// Prioritization report for the 2026-08-03 re-research worklist.
// Resolves the worklist's null `government` values through essentials.office_terms
// (NOT politicians.office_id — ADR 0002 phase 5 dropped that link; see mig 1538 notes)
// and records whether each politician is currently seated.

const w = JSON.parse(readFileSync('data/stance-retirement/2026-08-03-reresearch-worklist.json', 'utf8'));
const rows = w.rows.filter((r) => r.defect_class !== 'pretenure'); // pretenure closed by migs 1541/1542
const ids = [...new Set(rows.map((r) => r.politician_id))];

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const { rows: occ } = await pool.query(
  `SELECT p.id                AS politician_id,
          p.full_name,
          g.name              AS government,
          g.type              AS gov_type,
          g.geo_id,
          o.title             AS office_title,
          ot.term_start,
          ot.term_end,
          (ot.term_end IS NULL OR ot.term_end > now()) AS seated,
          (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = p.id) AS answers_now
     FROM essentials.politicians p
     LEFT JOIN essentials.office_terms ot ON ot.politician_id = p.id
     LEFT JOIN essentials.offices     o  ON o.id = ot.office_id
     LEFT JOIN essentials.chambers    c  ON c.id = o.chamber_id
     LEFT JOIN essentials.governments g  ON g.id = c.government_id
    WHERE p.id = ANY($1::uuid[])
    ORDER BY p.full_name, ot.term_start DESC NULLS LAST`,
  [ids],
);

// collapse to one record per politician: prefer a currently-seated term
const best = new Map();
for (const r of occ) {
  const cur = best.get(r.politician_id);
  if (!cur || (r.seated && !cur.seated)) best.set(r.politician_id, r);
}

const owed = rows.reduce((m, r) => {
  m[r.politician_id] = (m[r.politician_id] || 0) + 1;
  return m;
}, {});

const recs = ids.map((id) => {
  const b = best.get(id) || {};
  const wl = rows.find((r) => r.politician_id === id);
  return {
    politician_id: id,
    full_name: b.full_name || wl.politician,
    government: b.government || null,
    gov_type: b.gov_type || null,
    geo_id: b.geo_id || null,
    office_title: b.office_title || null,
    seated: b.seated === true,
    term_end: b.term_end || null,
    answers_now: b.answers_now == null ? null : Number(b.answers_now),
    rows_owed: owed[id],
    worklist_government: wl.government || null,
    defect_classes: [...new Set(rows.filter((r) => r.politician_id === id).map((r) => r.defect_class))],
  };
});

const clusters = recs.reduce((m, r) => {
  const k = r.government || 'UNRESOLVED';
  (m[k] = m[k] || []).push(r);
  return m;
}, {});

let out = `# Re-research worklist — cluster + occupancy report\n\n`;
out += `Generated ${new Date().toISOString().slice(0, 10)} by scripts/_tmp-reresearch-cluster-report.mjs.\n`;
out += `Scope: **${rows.length} rows / ${ids.length} politicians** (the 36 pretenure rows are excluded — closed by migrations 1541/1542).\n\n`;
out += `Occupancy joined through \`essentials.office_terms\`. \`answers_now\` is live: 0 means the politician was emptied.\n\n`;
out += `| cluster | rows owed | politicians | seated | not seated | zero-answer people |\n|---|---|---|---|---|---|\n`;
for (const [k, v] of Object.entries(clusters).sort((a, b) => sum(b[1]) - sum(a[1]))) {
  out += `| ${k} | ${sum(v)} | ${v.length} | ${v.filter((r) => r.seated).length} | ${v.filter((r) => !r.seated).length} | ${v.filter((r) => r.answers_now === 0).length} |\n`;
}
out += `\n## Per-politician detail\n\n`;
out += `| politician | cluster | office | seated | answers now | rows owed | class |\n|---|---|---|---|---|---|---|\n`;
for (const r of recs.sort((a, b) => b.rows_owed - a.rows_owed || a.full_name.localeCompare(b.full_name))) {
  out += `| ${r.full_name} | ${r.government || '🔴 UNRESOLVED'} | ${r.office_title || '—'} | ${r.seated ? '✅' : '⛔'} | ${r.answers_now} | ${r.rows_owed} | ${r.defect_classes.join('+')} |\n`;
}

writeFileSync('data/stance-retirement/2026-08-03-reresearch-clusters.md', out);
writeFileSync('data/stance-retirement/2026-08-03-reresearch-clusters.json', JSON.stringify({ generated: new Date().toISOString().slice(0, 10), scope: { rows: rows.length, politicians: ids.length }, politicians: recs }, null, 2));

function sum(v) {
  return v.reduce((n, r) => n + r.rows_owed, 0);
}

console.log(`politicians: ${recs.length}  seated: ${recs.filter((r) => r.seated).length}  not seated: ${recs.filter((r) => !r.seated).length}`);
console.log(`zero-answer (emptied): ${recs.filter((r) => r.answers_now === 0).length}`);
console.log(`unresolved government: ${recs.filter((r) => !r.government).length}`);
console.log('\nclusters by rows owed:');
for (const [k, v] of Object.entries(clusters).sort((a, b) => sum(b[1]) - sum(a[1]))) {
  console.log(`  ${String(sum(v)).padStart(3)} rows / ${String(v.length).padStart(2)} pols  ${v.filter((r) => r.seated).length} seated  ${k}`);
}
await pool.end();
