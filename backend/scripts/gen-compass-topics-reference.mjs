#!/usr/bin/env node
/**
 * Regenerate data/stance-research/compass-topics-reference.md from the LIVE ladders.
 *
 * WHY THIS EXISTS
 * ---------------
 * The reference file used to be hand-maintained paraphrases of the compass answer options. It drifted
 * from `inform.compass_stances` and, because it is the file every stance-research run reads, the drift
 * became wrong voter-facing positions:
 *
 *   - `ai-regulation` was recorded as "1 = strongly favors comprehensive federal AI regulation".
 *     The live chair 1 is "Allow AI companies to develop and deploy technology freely". Backwards.
 *     That inversion is what migration 1729 had to fix for 9 legislators who had WRITTEN AI-safety law
 *     and were seated at the laissez-faire end.
 *   - `judicial-government-deference` was recorded as "1 = favors judicial deference to agency
 *     expertise". The live chair 1 is "The citizen, almost always." Also backwards.
 *   - The file's global header claimed "1 = strong progressive / 5 = strong conservative". The live
 *     convention is "chair 1 = maximum government action", which is NOT the same thing, and on
 *     `residential-zoning`, `growth-and-development` and `housing` chair 4 the progressive position
 *     sits at the HIGH end. Migration 1730 fixed 10 rows from that class.
 *   - Three live topics (`data-centers`, `local-immigration`, `transportation-priorities`) were listed
 *     under "Excluded Topics (do NOT use)" as deprecated. All three are live and active, and they are
 *     the three that matter most for city and county officials.
 *
 * So: never hand-edit the reference again. Edit this generator, or the ladders themselves, and re-run.
 *
 * Usage: node scripts/gen-compass-topics-reference.mjs [--check]
 *   --check exits 1 if the committed file differs from what the DB would produce (for CI).
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import { Pool } from 'pg';

const OUT = 'data/stance-research/compass-topics-reference.md';
const checkOnly = process.argv.includes('--check');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const { rows } = await pool.query(`
  SELECT t.topic_key, t.short_title, t.question_text, t.judicial_role,
         s.value AS chair, s.text AS chair_text
  FROM inform.compass_topics t
  JOIN inform.compass_stances s ON s.topic_id::text = t.id::text
  WHERE t.is_live AND t.is_active
  ORDER BY t.topic_key, s.value
`);
await pool.end();

if (!rows.length) throw new Error('no live ladders returned - refusing to write an empty reference');

const topics = new Map();
for (const r of rows) {
  if (!topics.has(r.topic_key)) {
    topics.set(r.topic_key, {
      key: r.topic_key,
      title: r.short_title,
      question: r.question_text,
      judicial: r.judicial_role,
      chairs: [],
    });
  }
  topics.get(r.topic_key).chairs.push({ n: r.chair, text: r.chair_text });
}

const incomplete = [...topics.values()].filter((t) => t.chairs.length !== 5);
if (incomplete.length) {
  throw new Error(`ladders without exactly 5 chairs: ${incomplete.map((t) => `${t.key}(${t.chairs.length})`).join(', ')}`);
}

const lines = [];
const p = (s = '') => lines.push(s);

p('# Compass Topics Reference');
p();
p('**GENERATED FILE - DO NOT HAND-EDIT.** Regenerate with:');
p();
p('```');
p('node scripts/gen-compass-topics-reference.mjs');
p('```');
p();
p(`Source of truth: \`inform.compass_stances\` joined to \`inform.compass_topics\` (is_live AND is_active).`);
p(`${topics.size} live topics. The chair text below is verbatim from the database - it is what the voter sees.`);
p();
p('## The rule for seating anyone in a chair');
p();
p('A chair requires evidence describing **THAT chair**. The five chairs are five distinct stances, not');
p('a polarization rating. Direction is not a chair: evidence that establishes only pro/anti under-');
p('determines which of the two or three chairs on that side the person occupies, and seating them anyway');
p('is an unevidenced voter-facing claim.');
p();
p('- A polarization score, an endorsement grade, or an advocacy-group rating is **never** a chair.');
p('- "Least extreme option the reasoning supports" is a **tiebreaker, not evidence**. Reaching for it is');
p('  the signal that the row is not evidenced.');
p('- The honest alternative to a guessed chair is a **blank spoke**. A blank spoke is a correct answer.');
p('- A citation to legislation the member CO-SPONSORED can only ever evidence the chair that legislation');
p('  describes. Co-sponsorship counts as much as authorship.');
p('- Before calling a chair pair unevidenceable, check *which word* differs between them:');
p('  **pace/magnitude only** (taxes 1 "significantly raise" vs 2 "moderately raise") cannot be settled by');
p('  a sponsorship - blank it; an **end-state** difference (climate 2 "phase out" vs 3 "gradually reducing');
p('  reliance on") is elimination vs reduction and can be evidenced.');
p('- Consistency check: the same instrument cannot seat two co-sponsors in two different chairs.');
p();
p('## Orientation: read chair 1, every time');
p();
p('**Do not assume 1 = progressive.** The prevailing convention is *chair 1 = maximum government action,');
p('chair 5 = minimum*, which is a different axis from left-to-right, and several ladders do not follow');
p('either reading:');
p();
p('- **Reversed** - `ai-regulation` chair 1 is "allow AI companies to develop freely" and chair 5 is the');
p('  ban. `tariffs` chair 1 is complete free trade. On these, the pro-regulation politician is at the');
p('  HIGH chair.');
p('- **Off-axis** - on `residential-zoning` (chair 5 eliminates single-family-only zoning),');
p('  `growth-and-development`, and `housing` chair 4 ("cut regulations so private developers can build"),');
p('  the deregulatory and the progressive-housing positions sit at the SAME end. `housing` chair 4 is');
p('  right for a YIMBY and wrong for a tenant-protection member: same chair, opposite verdicts, decided');
p('  per row.');
p('- **Not an intervention axis at all** - `judicial-government-deference` chair 1 is "the citizen,');
p('  almost always". No political lexicon maps onto it; do not scan it with one.');
p('- `misinformation` chair 5 ("ban any government involvement in content moderation") is a free-speech');
p('  position held across the spectrum.');
p();
p('Orientation is **not** stored on `compass_topics`, so nothing in the code derives it and no scan can');
p('infer it. The authoritative test is the chair text printed below. Read chair 1 and chair 5 and decide');
p('which end your evidence describes before picking a number.');
p();
p('## Output format');
p();
p('Emit the chair number **1-5 directly**, matching the option number below. Apply scripts use');
p('`parseInt(value)` with no conversion formula. CSV: `politician_id,topic_id,topic_key,value,notes`;');
p('keep notes under 120 chars and use semicolons, not commas.');
p();
p('## Scope');
p();
p('`office_scope` is NULL on every live topic, so scope is a judgment call, not a lookup. Pick the topics');
p('the office actually acts on. `data-centers`, `local-immigration` and `transportation-priorities` are');
p('live and are usually the WRONG choice for a federal or statewide official and the RIGHT choice for a');
p('city or county one. (An earlier version of this file listed those three as deprecated. They are not.)');
p();
p('---');
p();
p('## Topics');
p();

for (const t of [...topics.values()].sort((a, b) => a.key.localeCompare(b.key))) {
  p(`### ${t.key}`);
  if (t.judicial) p(`**Judicial role:** ${t.judicial}`);
  p(`**Title:** ${t.title}`);
  p(`**Question:** ${t.question}`);
  p('**Chairs (verbatim):**');
  for (const c of t.chairs.sort((a, b) => a.n - b.n)) p(`- ${c.n} = ${c.text}`);
  p();
  p('---');
  p();
}

const out = lines.join('\n');

if (checkOnly) {
  let current = '';
  try { current = readFileSync(OUT, 'utf8'); } catch {}
  if (current !== out) {
    console.error(`${OUT} is STALE - regenerate with: node scripts/gen-compass-topics-reference.mjs`);
    process.exit(1);
  }
  console.log(`${OUT} is up to date (${topics.size} topics).`);
} else {
  writeFileSync(OUT, out, 'utf8');
  console.log(`wrote ${OUT} - ${topics.size} topics, ${rows.length} chairs`);
}
