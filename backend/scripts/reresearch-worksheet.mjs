import 'dotenv/config';
import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { Pool } from 'pg';

// Emit a per-cluster re-research worksheet: for every owed (politician, topic) pair, the topic's
// verbatim question + all five chair texts, the retired chair, the retired (never-existed) sources
// that must NOT be returned to, and the topic's tier scoping.
//
// Tier scoping matters: inform.compass_topic_roles is the live tier model. A topic with NO role rows
// defaults to ALL tiers true; otherwise the frontend's deriveScopedTopics filters a profile's compass
// by office tier. Re-researching a topic that cannot display for this office would recreate the
// out-of-tier backlog that migrations 1543-1545 were spent shrinking.

const CLUSTER = process.argv[2];
const OUTDIR = process.argv[3];
if (!CLUSTER || !OUTDIR) {
  console.error('usage: node scripts/_tmp-reresearch-worksheet.mjs "<government name substring>" <outdir>');
  process.exit(1);
}

const wl = JSON.parse(readFileSync('data/stance-retirement/2026-08-03-reresearch-worklist.json', 'utf8'));
const clusters = JSON.parse(readFileSync('data/stance-retirement/2026-08-03-reresearch-clusters.json', 'utf8'));

const people = clusters.politicians.filter(
  (p) => (p.government || '').toLowerCase().includes(CLUSTER.toLowerCase()),
);
if (!people.length) {
  console.error(`no politicians matched cluster "${CLUSTER}"`);
  process.exit(1);
}
const ids = new Set(people.map((p) => p.politician_id));
const rows = wl.rows.filter((r) => ids.has(r.politician_id) && r.defect_class !== 'pretenure');

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const topicIds = [...new Set(rows.map((r) => r.topic_id))];

const { rows: scales } = await pool.query(
  `SELECT t.id AS topic_id, t.topic_key, t.title, t.question_text, t.is_live, t.is_active,
          s.value, s.text
     FROM inform.compass_topics t
     JOIN inform.compass_stances s ON s.topic_id = t.id
    WHERE t.id = ANY($1::uuid[])
    ORDER BY t.title, s.value`,
  [topicIds],
);

const { rows: roles } = await pool.query(
  `SELECT topic_id, role_scope, is_required FROM inform.compass_topic_roles WHERE topic_id = ANY($1::uuid[])`,
  [topicIds],
);

// live answers each of these people still holds, so the worksheet can show what survived
const { rows: kept } = await pool.query(
  `SELECT a.politician_id, t.title, a.value, c.reasoning, c.sources
     FROM inform.politician_answers a
     JOIN inform.compass_topics t ON t.id = a.topic_id
     LEFT JOIN inform.politician_context c ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
    WHERE a.politician_id = ANY($1::uuid[])
    ORDER BY t.title`,
  [[...ids]],
);

const roleMap = topicIds.reduce((m, id) => {
  const rs = roles.filter((r) => r.topic_id === id);
  m[id] = {
    scopes: rs.map((r) => r.role_scope),
    // a topic with no role rows defaults to every tier true
    applies_local: rs.length ? rs.some((r) => r.role_scope === 'local') : true,
  };
  return m;
}, {});

const byTopic = topicIds.reduce((m, id) => {
  const ss = scales.filter((s) => s.topic_id === id);
  if (ss.length) m[id] = { meta: ss[0], chairs: ss.map((s) => ({ value: Number(s.value), text: s.text })) };
  return m;
}, {});

mkdirSync(OUTDIR, { recursive: true });

const inScope = [];
const outOfScope = [];
for (const r of rows) (roleMap[r.topic_id].applies_local ? inScope : outOfScope).push(r);

let out = `# Re-research worksheet — ${people[0].government}\n\n`;
out += `Generated ${new Date().toISOString().slice(0, 10)} by scripts/_tmp-reresearch-worksheet.mjs.\n\n`;
out += `**${rows.length} owed rows across ${people.length} politicians.** `;
out += `${inScope.length} in tier-scope for a local office; ${outOfScope.length} out of scope.\n\n`;

out += `## The rules this worksheet exists to enforce\n\n`;
out += `1. **Do not return to the retired sources.** They are listed per row precisely so they can be avoided:\n`;
out += `   these URLs never existed (hard 404 today, never captured by Wayback, while Wayback holds thousands\n`;
out += `   of sibling URLs in the same directory). There is nothing to recover at them.\n`;
out += `2. **Evidence-only, no defaults.** A blank spoke is a correct outcome. Never write a chair the source\n`;
out += `   does not carry, and never average two chairs — if two adjacent chairs both fit, SKIP.\n`;
out += `3. **Never cite a URL you have not fetched**, and classify every non-200 before reading it as absence\n`;
out += `   (403 = bot block, 202/429/503 = throttled, 404 = gone). A 200 is not identity confirmation.\n`;
out += `4. **The reasoning is voter-facing** (rendered under "Why this position?"), so a claim it makes must be\n`;
out += `   carried by the source cited beside it — not merely true.\n\n`;

out += `## Politicians\n\n| politician | office | answers still held | rows owed |\n|---|---|---|---|\n`;
for (const p of people.sort((a, b) => b.rows_owed - a.rows_owed)) {
  out += `| ${p.full_name} | ${p.office_title || '—'} | ${p.answers_now} | ${p.rows_owed} |\n`;
}
out += `\n⚠ \`essentials.office_terms.term_end\` is NULL for every one of these people, so occupancy is NOT\n`;
out += `verified by the database — confirm each person still holds the seat from a live official page before\n`;
out += `publishing anything under their name.\n`;

if (outOfScope.length) {
  out += `\n## ⛔ Out of tier-scope — do NOT research (${outOfScope.length} rows)\n\n`;
  out += `\`compass_topic_roles\` excludes the local tier for these topics, so the answer would never display\n`;
  out += `on a city officeholder's compass. Record as BLANK_OUT_OF_SCOPE and close permanently.\n\n`;
  out += `| politician | topic | tiers allowed |\n|---|---|---|\n`;
  for (const r of outOfScope) {
    out += `| ${r.politician} | ${r.topic} | ${roleMap[r.topic_id].scopes.join('+') || '(none)'} |\n`;
  }
}

out += `\n## Owed rows, grouped by politician\n`;
for (const p of people.sort((a, b) => b.rows_owed - a.rows_owed)) {
  const mine = inScope.filter((r) => r.politician_id === p.politician_id);
  if (!mine.length) continue;
  out += `\n### ${p.full_name} — ${p.office_title || 'office unknown'} (${mine.length} in-scope rows)\n\n`;
  const survived = kept.filter((k) => k.politician_id === p.politician_id);
  out += survived.length
    ? `Still holds ${survived.length} answer(s): ${survived.map((s) => `${s.title}=${Number(s.value)}`).join(', ')}\n\n`
    : `Holds **zero** answers — emptied entirely, so this person currently reads as unresearched.\n\n`;
  for (const r of mine) {
    const t = byTopic[r.topic_id];
    out += `- **${r.topic}** — retired chair was **${Number(r.retired_chair)}** (do not treat as a prior; it was unsupported)\n`;
    out += `  - retired sources (NEVER existed — do not revisit): ${r.retired_sources.map((s) => `\`${s}\``).join(' · ')}\n`;
  }
}

out += `\n## Topic scales — verbatim from inform.compass_topics + inform.compass_stances\n\n`;
out += `The value assigned MUST be the chair whose text the evidence supports. Discrete 1-5, never fractional.\n`;
for (const id of Object.keys(byTopic)) {
  const { meta, chairs } = byTopic[id];
  const rm = roleMap[id];
  out += `\n### ${meta.title} (\`${meta.topic_key}\`)\n\n`;
  out += `**Q:** ${meta.question_text}\n\n`;
  out += `tiers: ${rm.scopes.join('+') || '(no role rows → all tiers)'}${rm.applies_local ? '' : '  ⛔ NOT local'}\n\n`;
  for (const c of chairs) out += `- **${c.value}** — ${c.text}\n`;
}

const path = `${OUTDIR}/WORKSHEET.md`;
writeFileSync(path, out);
writeFileSync(
  `${OUTDIR}/owed-rows.json`,
  JSON.stringify({ generated: new Date().toISOString().slice(0, 10), cluster: people[0].government, in_scope: inScope, out_of_scope: outOfScope }, null, 2),
);
console.log(`wrote ${path}`);
console.log(`${rows.length} owed rows · ${inScope.length} in scope · ${outOfScope.length} out of tier-scope`);
console.log(`topics: ${Object.keys(byTopic).length} of ${topicIds.length} resolved from compass_topics`);
const missing = topicIds.filter((id) => !byTopic[id]);
if (missing.length) console.log(`⚠ ${missing.length} topic ids had no live stance texts: ${missing.join(', ')}`);
await pool.end();
