#!/usr/bin/env node
/**
 * Test each class-C template row against the member's OWN Maryland sponsorship record.
 *
 * 🔑 THE QUESTION EACH ROW ASKS. "X co-sponsored civil rights legislation including
 * anti-discrimination protections" is a checkable claim once you have full sponsor lists. Either the
 * member's name appears on such a bill or it does not, and the two answers point OPPOSITE ways:
 * a hit means RE-SOURCE to the bills, a miss means the row was written from a template.
 *
 * ⚠ IDENTITY IS THE WHOLE RISK HERE. mgaleg prints bare surnames. This workstream has already been
 * bitten twice by exactly that — "Senator Washington, M." is Mary and not Alonzo, and "Delegate
 * Love" is two different people. So a surname shared by more than one member in the index is
 * reported AMBIGUOUS and credited to nobody, and a hit is only accepted when the token is either
 * unique or carries a matching initial.
 *
 * ⚠ A HIT IS NOT AUTOMATICALLY A SOURCE either — the bill's TITLE still has to be on the row's
 * topic. Same-Sex Marriage is not evidenced by a pay-equity bill. Per-topic filters below.
 *
 * 🔴 Reads only. Emits a reading queue with a proposed disposition per row.
 *   node scripts/match-class-c-sponsors.mjs
 */
import fs from 'node:fs';

const IDX = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-md-cr-sponsor-index.json', 'utf8'));
const C = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-the-197-class-c.json', 'utf8'));

// Which bill titles can evidence which topic. Narrower than the crawl net on purpose.
const TOPIC_FILTER = {
  'Civil Rights and Social Justice': /discriminat|civil right|human relations|hate crime|hate-bias|equal pay|racial|reparation|lynching|civil liberties/i,
  'Same-Sex Marriage': /sexual orientation|gender identity|LGBTQ|conversion therapy|domestic partner|same-?sex/i,
  'Religious Freedom': /religious (freedom|liberty|exercise|exemption)|conscience|clergy|faith-based/i,
  'Transgender Athletes': /transgender|gender identity/i,
  'Immigration and Treatment of Immigrants': /immigra|sanctuary|undocumented|287\(g\)/i,
};

/**
 * 🔴 THE FIRST CUT OVER-FIRED, exactly as every first cut in this workstream has. Matching the topic
 * word is not matching the topic: "Dogs - Discrimination Based on Breed, Type, or Heritage" is not a
 * civil-rights position, "Family Law - Marriage - Age Requirements" is child marriage and not
 * same-sex marriage, and "Marriage Ceremony - Designation of Deputy Clerk" is clerical. On topic by
 * VOCABULARY is not on topic by RATIONALE.
 */
const NOT_REALLY = /\bdogs?\b|breed|animal|veterinar|long-?term care insurance|reading instruction|security upgrades|compounded preparation|marriage\s*-\s*age|age requirements|marriage ceremony|deputy clerk|marriage license fee|boycott of israel/i;

const norm = (s) => s.toLowerCase().replace(/\./g, '').replace(/\s+/g, ' ').trim();
const surnameOf = (n) => n.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)$/i, '').trim().split(/\s+/).pop();
const firstOf = (n) => n.trim().split(/\s+/)[0];

// Group index tokens by bare surname so collisions are visible.
const bySurname = {};
for (const token of Object.keys(IDX.index)) {
  const parts = token.split(' ');
  const sn = parts[parts.length - 1];
  (bySurname[sn] ||= []).push(token);
}

// Only Maryland legislators can be tested this way.
const NON_MD = new Set(['Christopher R. Deluzio', 'Mike Ezell', 'Seth Magaziner']);

const results = [];
for (const r of C.class_c) {
  if (NON_MD.has(r.full_name)) { results.push({ ...r, verdict: 'NOT_MARYLAND' }); continue; }
  const sn = norm(surnameOf(r.full_name));
  const initial = norm(firstOf(r.full_name))[0];
  const tokens = bySurname[sn] || [];
  if (!tokens.length) { results.push({ ...r, verdict: 'NO_SPONSORSHIP_FOUND', tokens: [], bills: [] }); continue; }

  // ⚠ Collision handling. "washington" and "a washington" both end in the surname; if more than one
  // DISTINCT person is represented, only an initialled token may be credited.
  const initialled = tokens.filter((t) => t !== sn);
  const distinctInitials = new Set(initialled.map((t) => t.split(' ')[0][0]));
  let use, idNote;
  if (initialled.length && distinctInitials.size > 1) {
    const mine = initialled.filter((t) => t.split(' ')[0][0] === initial);
    if (!mine.length) { results.push({ ...r, verdict: 'AMBIGUOUS_SURNAME', tokens, bills: [] }); continue; }
    use = mine; idNote = `initial '${initial}' disambiguates among ${[...distinctInitials].join('/')}`;
  } else if (initialled.length && distinctInitials.size === 1 && [...distinctInitials][0] !== initial && tokens.includes(sn)) {
    // the only initialled form belongs to SOMEONE ELSE; the bare surname could be either
    results.push({ ...r, verdict: 'AMBIGUOUS_SURNAME', tokens, bills: [],
      id_note: `index carries '${initialled[0]}' but this politician's initial is '${initial}'` });
    continue;
  } else {
    use = tokens; idNote = tokens.length === 1 ? 'single token, no collision' : `tokens ${tokens.join(' / ')} all read as one person`;
  }

  const all = use.flatMap((t) => IDX.index[t]);
  const filt = TOPIC_FILTER[r.topic];
  const onTopic = (filt ? all.filter((b) => filt.test(b.title)) : all).filter((b) => !NOT_REALLY.test(b.title));
  const uniq = [...new Map(onTopic.map((b) => [b.session + b.number, b])).values()]
    .sort((a, b) => a.session.localeCompare(b.session));
  results.push({ ...r, verdict: uniq.length ? 'SPONSORED_ON_TOPIC' : 'NO_ON_TOPIC_BILL',
    tokens: use, id_note: idNote, n_all: all.length, bills: uniq });
}

const tally = results.reduce((m, r) => { m[r.verdict] = (m[r.verdict] || 0) + 1; return m; }, {});
console.log(JSON.stringify(tally, null, 2));
for (const v of ['SPONSORED_ON_TOPIC', 'NO_ON_TOPIC_BILL', 'NO_SPONSORSHIP_FOUND', 'AMBIGUOUS_SURNAME', 'NOT_MARYLAND']) {
  const g = results.filter((r) => r.verdict === v);
  if (!g.length) continue;
  console.log(`\n${'='.repeat(78)}\n${v} (${g.length})\n${'='.repeat(78)}`);
  for (const r of g.sort((a, b) => a.full_name.localeCompare(b.full_name))) {
    console.log(`\n${r.full_name} | ${r.topic} | chair ${r.answer_value}`);
    if (r.id_note) console.log(`   identity: ${r.id_note}`);
    if (r.tokens?.length) console.log(`   tokens: ${r.tokens.join(', ')}  (${r.n_all ?? 0} bills on any CR topic)`);
    if (r.bills?.length) {
      console.log(`   ON-TOPIC BILLS (${r.bills.length}):`);
      for (const b of r.bills.slice(0, 4)) console.log(`     ${b.session} ${b.number} :: ${b.title.slice(0, 88)}`);
      if (r.bills.length > 6) console.log(`     … and ${r.bills.length - 6} more`);
    }
  }
}
fs.writeFileSync('data/stance-retirement/2026-08-12-class-c-sponsor-match.json',
  JSON.stringify({ pass: 'class C rows vs their own MD sponsorship record', tally, rows: results }, null, 1));
console.log('\nwrote data/stance-retirement/2026-08-12-class-c-sponsor-match.json');
