#!/usr/bin/env node
/**
 * Propose ONE citation per row, then print them all for reading.
 *
 * 🔑 THE MACHINE PROPOSES, A HUMAN READS EVERY ONE. 53 rows is too many to hand-pick candidate by
 * candidate, but "read every finding" does not mean "hand-pick every candidate" — it means nothing
 * ships unread. So the ranking picks the single best-supported bill per row and this prints the
 * proposed citation, its synopsis and its identity check together, in a form short enough that all of
 * them actually get read before anything is written.
 *
 * Ranking, in order: the member LEADS it > it is enacted (a chapter number) > it matches the tighter
 * CORE pattern for the topic > most recent.
 *
 * ⚠ A proposal is not a decision. Rows whose best proposal is off-topic, or whose identity is not
 * confirmed by the sponsor slug, are flagged and must be rejected or replaced by hand.
 */
import fs from 'node:fs';
import { TOPIC_STRICT } from './lib/md-topic-nets.mjs';

/**
 * 🔴 THE CHAIR GATE. On these 1-5 scales 1-2 is the PRO pole and 4-5 the ANTI pole, so a citation to
 * a bill the member SPONSORED can only ever evidence a PRO chair. Attaching one to a row at chair 4-5
 * makes the row worse than it was: the dot would say "roll back public coverage" while the text cites
 * the member expanding it. This workstream already shipped that mistake once (Sara Love / Same-Sex
 * Marriage, mig 1712) and had to revert it.
 *
 * Chair 3 is the middle option and is excluded too — a pro-side sponsorship does not evidence it, and
 * both chair-3 rows here belong to members whose best matches are unrelated bills anyway.
 *
 * ⚠ Rows at chair >= 3 are NOT thereby "fine". Two of them (Kramer, Waldstreicher — both chair 5 with
 * pro-worded reasoning) look like the migration-1714 inversion defect surviving in rows that cohort
 * never covered. They need the CHAIR pass, not a sourcing pass.
 */
const MAX_CHAIR_FOR_SPONSORSHIP = 2;

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in', 'data/stance-retirement/2026-08-12-md-medicaid-dossier.json');
const OUT = flag('--out', 'data/stance-retirement/2026-08-12-md-medicaid-proposals.json');

const R = JSON.parse(fs.readFileSync(IN, 'utf8'));
const chapterOf = (s) => { const m = (s || '').match(/Chapter\s+(\d+)/i); return m ? parseInt(m[1], 10) : null; };

const out = [];
for (const r of R.rows) {
  const strict = TOPIC_STRICT[r.topic];
  const chairBlocked = Number(r.chair) > MAX_CHAIR_FOR_SPONSORSHIP;
  // identity must be confirmed by the bill page's own sponsor link, and the title must pass STRICT
  const usable = (r.picks || []).filter((p) => !p.error && p.slug_confirms && strict && strict.test(p.title));
  const scored = usable.map((p) => ({ ...p, chapter: chapterOf(p.status) }))
    .sort((a, b) => (b.lead - a.lead)
      || ((b.chapter ? 1 : 0) - (a.chapter ? 1 : 0))
      || b.session.localeCompare(a.session));
  const best = chairBlocked ? null : (scored[0] || null);
  const blockedReason = chairBlocked ? `chair ${r.chair} is at or past the anti pole — sponsorship cannot evidence it`
    : !scored.length ? 'no bill passed the STRICT title test with a confirmed sponsor slug' : null;
  out.push({
    politician_id: r.politician_id, topic_id: r.topic_id, name: r.name, topic: r.topic, chair: r.chair,
    member_slug: r.member_slug, old_reasoning: r.reasoning, old_sources: r.sources,
    sessions_unreadable: r.sessions_unreadable, n_candidates: r.n_candidates,
    proposal: best ? {
      key: best.key, session: best.session, number: best.number, title: best.title,
      role: best.lead ? 'lead' : 'cosp', chapter: best.chapter, isCore: best.isCore,
      slug_confirms: best.slug_confirms, synopsis: best.synopsis,
      url: `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${best.slug}?ys=${best.session}`,
    } : null,
    blocked_reason: blockedReason,
    alternates: scored.slice(1).map((p) => `${p.lead ? 'LEAD' : 'cosp'} ${p.session} ${p.number} ${p.title.slice(0, 60)}`),
  });
}

for (const r of out) {
  const p = r.proposal;
  console.log(`\n### ${r.name} | ${r.topic} | ch${r.chair}${r.sessions_unreadable.length ? ` ⚠unread${r.sessions_unreadable.length}` : ''}`);
  if (!p) { console.log('   NO PROPOSAL — ' + (r.blocked_reason || '?')); continue; }
  console.log(`   ${p.role.toUpperCase()} ${p.slug_confirms ? 'slug✓' : 'slug✗'} ${p.isCore ? 'core' : '    '} ${p.chapter ? `Ch.${p.chapter}` : 'not enacted'} ${p.session} ${p.number}`);
  console.log(`   ${p.title}`);
  console.log(`   ${(p.synopsis || '').slice(0, 260)}`);
}
const flagged = out.filter((r) => r.proposal && (!r.proposal.slug_confirms || !r.proposal.isCore));
console.log(`\n${out.length} proposals; ${out.filter((r) => !r.proposal).length} with none; ${flagged.length} FLAGGED (identity unconfirmed or off-core) — must be read hardest.`);
fs.writeFileSync(OUT, JSON.stringify({ pass: 'MD medicaid-template citation proposals', rows: out }, null, 1));
console.log(`wrote ${OUT}`);
