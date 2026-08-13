#!/usr/bin/env node
/**
 * Rank each row's candidate bills against the SEATED CHAIR — not against the topic.
 *
 * 🔑 THE TEST (CLAUDE.md): to seat a politician in a chair you need evidence describing THAT chair.
 * A topic net finds bills about healthcare; it cannot tell chair 2 ("everyone has affordable
 * coverage through a mix of public programs and regulated private insurance") from chair 1 ("free
 * and run by the public sector"). So each candidate title is scored against the seated chair's own
 * text AND against the four rival chairs. A bill only counts as evidence if it matches the seated
 * chair BETTER THAN ANY RIVAL — otherwise it is topical, not chair-specific.
 *
 * ⚠ This still only builds a READING QUEUE, ranked. A human read decides; the score never does.
 * ⚠ CHAIR GATE: a sponsorship can only evidence a chair on the ACTION side of that ladder, so rows
 * seated on the minimum-action side are marked REFUSE rather than given candidates.
 * 🔴 THE GATE MUST READ THE LADDER, NOT ASSUME IT. "chair >= 4 is the anti pole" is false for the
 * two reversed ladders — on AI Oversight chair 1 is "allow AI companies to develop freely" and
 * chair 5 is "ban AI systems that could cause serious harm", so its action side is 4-5. Hardcoding
 * 4-5 as anti refused Katie Fry Hester's AI row, which is exactly the defect this workstream fixes.
 *
 * 🔴 Reads only.
 *   node scripts/md-chair-candidates.mjs [--state MD] [--out <sheet.json>] [--top 5]
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const STATE = flag('--state', 'MD');
const TOP = Number(flag('--top', 5));
const OUT = flag('--out', `data/stance-retirement/2026-08-12-chair-candidates-${STATE}.json`);
const LEG = flag('--leg', 'data/stance-retirement/2026-08-12-chairs-owed-md-legislation.json');
const WORK = flag('--work', 'data/stance-retirement/2026-08-12-chairs-owed-evidence.json');

// The two ladders whose ACTION side is 4-5, not 1-2 (audited 2026-08-12, mig 1730).
const REVERSED = new Set([
  '666bf03d-81fc-4138-ab15-69ae734c9023', // Artificial Intelligence Oversight
  '683c8084-2281-4920-a07c-18439b2dd413', // Tariffs
]);

const STOP = new Set(('the a an and or of to in for on with by at from as is are be been being that this those these ' +
  'it its their his her not no all any some most more less than while so such other others only just also can could ' +
  'should would may might will shall must who whom which what when where how why into out up down over under again ' +
  'further then once here there both each few nor own same too very s t don now government public state local people ' +
  'programs program new make making made keep keeping let letting everyone anyone').split(/\s+/));
const toks = (s) => [...new Set((s || '').toLowerCase().replace(/[^a-z0-9\s-]/g, ' ').split(/\s+/)
  .filter((w) => w.length > 3 && !STOP.has(w)))];

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const { rows: stanceRows } = await pool.query(
  'SELECT topic_id, value, text FROM inform.compass_stances ORDER BY topic_id, value');
await pool.end();
const ladder = {};
for (const s of stanceRows) (ladder[s.topic_id] ??= {})[s.value] = s.text;

const leg = JSON.parse(fs.readFileSync(LEG, 'utf8')).rows;
const work = JSON.parse(fs.readFileSync(WORK, 'utf8')).rows.filter((r) => r.state === STATE);
const chairOf = {};
for (const w of work) chairOf[`${w.politician_id}|${w.topic_id}`] = w.chair_seated;

const sheet = [];
for (const r of leg) {
  const key = `${r.politician_id}|${r.topic_id}`;
  const chair = chairOf[key];
  if (chair == null) continue;
  const lad = ladder[r.topic_id] || {};
  const seatedToks = toks(lad[chair]);
  const rivalToks = {};
  for (const v of [1, 2, 3, 4, 5]) if (v !== chair) rivalToks[v] = toks(lad[v]);

  const scored = (r.candidates || []).map((c) => {
    const t = (c.title || '').toLowerCase();
    const hit = (list) => list.filter((w) => t.includes(w)).length;
    const seated = hit(seatedToks);
    let bestRival = 0, bestRivalChair = null;
    for (const [v, list] of Object.entries(rivalToks)) {
      const h = hit(list);
      if (h > bestRival) { bestRival = h; bestRivalChair = Number(v); }
    }
    return { ...c, seated, bestRival, bestRivalChair, discriminating: seated > 0 && seated > bestRival };
  }).sort((a, b) => (b.seated - b.bestRival) - (a.seated - a.bestRival) || b.seated - a.seated);

  const disc = scored.filter((c) => c.discriminating);
  sheet.push({
    politician_id: r.politician_id, topic_id: r.topic_id, name: r.name, topic: r.topic,
    chair, chair_text: lad[chair] || null,
    refuse_chair_gate: REVERSED.has(r.topic_id) ? chair <= 2 : chair >= 4,
    reasoning: r.reasoning,
    n_candidates: (r.candidates || []).length,
    n_discriminating: disc.length,
    sessions_unreadable: r.sessions_unreadable || [],
    top: (disc.length ? disc : scored).slice(0, TOP)
      .map((c) => ({ number: c.number, session: c.session, title: c.title, url: c.url, seated: c.seated, rival: c.bestRival, rival_chair: c.bestRivalChair })),
  });
}

fs.writeFileSync(OUT, JSON.stringify({ pass: `chair-specific candidate ranking — ${STATE}`, n: sheet.length, rows: sheet }, null, 1));
const withDisc = sheet.filter((s) => s.n_discriminating > 0 && !s.refuse_chair_gate);
const none = sheet.filter((s) => s.n_discriminating === 0 && !s.refuse_chair_gate);
const refused = sheet.filter((s) => s.refuse_chair_gate);
console.log(`${sheet.length} ${STATE} rows`);
console.log(`  with a chair-discriminating candidate: ${withDisc.length}`);
console.log(`  none — blank-spoke candidates:         ${none.length}`);
console.log(`  refused by the chair gate (seated 4-5): ${refused.length}`);
console.log(`wrote ${OUT}`);
