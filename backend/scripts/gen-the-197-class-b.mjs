#!/usr/bin/env node
/**
 * Class B of "the 197" — rows whose OWN REASONING declares no evidence was found.
 *
 * 🔑 THE POINT: this looked like the cleanest retirement class in the set, because the author had
 * already searched and reported the absence. Searching independently moved 3 of 14 OUT of it — the
 * standard working exactly as intended. Retirement is what is left after looking, not the first move.
 *
 * RE-SOURCED (3): Hyde-Smith and Wicker both have RECORDED SENATE VOTES on exactly the subjects
 * their rows said nothing could be found for. Hyde-Smith's row even said her record "suggests
 * opposition to DISCLOSE Act" — she voted against cloture on it.
 *
 * RETIRED (9): the chair rests on a party, caucus or district prior plus a declared absence, and an
 * independent search found nothing on topic.
 *
 * ⚠ NOT RETIRED, deliberately:
 *   · Joyce / Medicare — real votes exist (IRA nay, OBBBA aye). They are omnibus votes that pin no
 *     chair, and if anything cut AGAINST the stored chair 3. A partial sample is not a search.
 *   · Ron Reynolds / Climate — capitol.texas.gov redirects to its search form today, so his bill
 *     record could not be read at all. UNASSESSED is not verified-absent (the JS-shell rule).
 *   · Carrie Isaac / Civil Rights — LEFT ALONE: "critical race theory" IS on her cited page. The
 *     lexicon missed it because "race" is not "racial". A near-miss stem, not an absent topic.
 *   · Gimenez / Reproductive Rights — the affirmative claim cites ISideWith, which is not in the
 *     sources array. That is a CITATION GAP needing re-sourcing, not an absent stance.
 *   · Paxton / Medicare and McClain / Same-Sex Marriage — their "no evidence" clause NARROWS a chair
 *     on a row already carried by real evidence. The opposite of this defect.
 *
 *   node scripts/gen-the-197-class-b.mjs --out <migration.sql> --rollback <rollback.json>
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out'), ROLLBACK = flag('--rollback');
if (!OUT || !ROLLBACK) { console.error('need --out --rollback'); process.exit(2); }

const V = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-classb-vote-verdicts.json', 'utf8')).results;
const vote = (label) => {
  const r = V.find((x) => x.label === label && x.status === 'FOUND');
  if (!r) throw new Error(`no verified verdict for ${label}`);
  return r;
};
const senateUrl = (r) => `https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=${r.congress}&session=${r.sess}&vote=${String(r.roll).padStart(5, '0')}`;

const disclose = vote('Hyde-Smith / DISCLOSE Act cloture');
const discloseW = vote('Wicker / DISCLOSE Act cloture');
const ftvHS = vote('Hyde-Smith / Freedom to Vote Act cloture');
const ftvW = vote('Wicker / Freedom to Vote Act cloture');
const ftpHS = vote('Hyde-Smith / For the People Act cloture');
const s1HS = vote('Hyde-Smith / S.1 motion to discharge');

const RESOURCE = [
  { name: 'Cindy Hyde-Smith', topic: 'Campaign Finance Reform',
    pid: '4d83f985-9248-4905-a9b6-5742e2df77a8', tid: '92730f69-ae57-401c-8ad1-2d07834a895d',
    sources: [senateUrl(disclose), senateUrl(ftvHS)],
    why: `Voted ${disclose.member.vote.toUpperCase()} on cloture to proceed to S.4822, the DISCLOSE Act, on 22 September 2022 (Senate roll call ${disclose.roll}, ${disclose.tally}); the bill would have added disclosure requirements for corporate and dark-money political spending. Also voted ${ftvHS.member.vote.toUpperCase()} on cloture to proceed to S.2747, the Freedom to Vote Act, on 20 October 2021 (roll call ${ftvHS.roll}, ${ftvHS.tally}), which carried further political-spending disclosure provisions.`,
    note: 'stored text said her record "suggests opposition to DISCLOSE Act" — she voted against cloture on it' },
  { name: 'Roger Wicker', topic: 'Campaign Finance Reform',
    pid: 'd53cbad2-d166-4f8d-87a2-f7e5ddc7a237', tid: '92730f69-ae57-401c-8ad1-2d07834a895d',
    sources: [senateUrl(discloseW), senateUrl(ftvW)],
    why: `Voted ${discloseW.member.vote.toUpperCase()} on cloture to proceed to S.4822, the DISCLOSE Act, on 22 September 2022 (Senate roll call ${discloseW.roll}, ${discloseW.tally}); the bill would have added disclosure requirements for corporate and dark-money political spending. Also voted ${ftvW.member.vote.toUpperCase()} on cloture to proceed to S.2747, the Freedom to Vote Act, on 20 October 2021 (roll call ${ftvW.roll}, ${ftvW.tally}), which carried further political-spending disclosure provisions.`,
    note: 'stored text said "No bill sponsorships or floor statements … were found"; two recorded votes exist' },
  { name: 'Cindy Hyde-Smith', topic: 'State Redistricting and Gerrymandering',
    pid: '4d83f985-9248-4905-a9b6-5742e2df77a8', tid: '48cc9585-ec22-4f53-8d42-6839828dd36f',
    sources: [senateUrl(ftpHS), senateUrl(s1HS)],
    why: `Voted ${ftpHS.member.vote.toUpperCase()} on cloture to proceed to S.2093, the For the People Act, on 22 June 2021 (Senate roll call ${ftpHS.roll}, ${ftpHS.tally}), and ${s1HS.member.vote.toUpperCase()} on the motion to discharge S.1 on 11 August 2021 (roll call ${s1HS.roll}, ${s1HS.tally}). Both bills would have required states to draw congressional districts through independent commissions. These are omnibus voting bills, so the votes show opposition to a federal mandate for independent commissions rather than a stated preference between legislature-drawn maps with court oversight and unrestricted legislative control.`,
    note: 'omnibus votes — they evidence opposition to mandated commissions, and the reasoning says so rather than over-claiming' },
];

// (politician, topic) pairs to retire, with the reason the absence was accepted.
const RETIRE = [
  { name: 'David Schweikert', topic: 'United States Tariff Policy', pid: '17e59190-17e2-4a90-8353-b5ea8d083480', tid: '683c8084-2281-4920-a07c-18439b2dd413',
    reason: 'chair 1 is "eliminate all tariffs and pursue completely free trade" — the most absolute position on the scale — and rested on "Ballotpedia and Wikipedia document no support for broad tariffs". The cited page contains no occurrence of "tariff"; its only "trade" hit is the word "trademark" in the Wikipedia footer. No tariff vote appears in the Clerk indexes for 2019, 2022, 2025 or 2026; his one trade vote is USMCA (385-41), near-unanimous and not tariff elimination.' },
  { name: 'Derek Tran', topic: 'School Vouchers & Public Education Funding', pid: 'b7612f49-c914-4ea7-a6da-559d71f313c2', tid: '00b95a6a-75db-4521-b523-3326bba938de',
    reason: 'the row opens "No evidence of Derek Tran supporting school voucher programs was found" and derives the chair from New Democrat Coalition membership. Caucus membership is not a position. No recorded House vote on vouchers or school choice in 2025 or 2026.' },
  { name: 'Derek Tran', topic: 'Data Center Development & Energy Costs', pid: 'b7612f49-c914-4ea7-a6da-559d71f313c2', tid: '4559b513-0fd8-4ed1-babd-f3b554162f40',
    reason: 'the row opens "No direct statement by Tran on data center policy was found" and derives the chair from Fusion Energy Caucus and New Democrat Coalition membership. No recorded House vote on data centers in 2025 or 2026.' },
  { name: 'Derek Tran', topic: 'Artificial Intelligence Oversight', pid: 'b7612f49-c914-4ea7-a6da-559d71f313c2', tid: '666bf03d-81fc-4138-ab15-69ae734c9023',
    reason: 'the row states "No specific AI safety bill sponsorship found" and rests on caucus membership plus a subcommittee role. No recorded House vote on artificial intelligence in 2025 or 2026.' },
  { name: 'Elissa Slotkin', topic: 'Artificial Intelligence Oversight', pid: 'ebe10065-0025-46e5-897e-7a81e4c77ecf', tid: '666bf03d-81fc-4138-ab15-69ae734c9023',
    reason: 'the row states she "has not introduced major AI governance legislation and holds no clear public position", then places her at the midpoint anyway on the basis of a CIA background. Her cited page contains no occurrence of "artificial intelligence" or "algorithm"; no recorded AI vote in 2025 or 2026.' },
  { name: 'Kelly A. Dooner', topic: 'Religious Freedom', pid: '247cf8e5-426a-4104-9027-6a2a0b1b61c9', tid: '6b9ba6d9-1001-43f5-b073-4d37130696fd',
    reason: 'the whole row is "Republican with no evidence of restricting religious exemptions" plus national party positions. Her complete 194th General Court record — 49 sponsored and 40 cosponsored bills — contains nothing on religion, faith, conscience or clergy.' },
  { name: 'Kelly A. Dooner', topic: 'Campaign Finance Reform', pid: '247cf8e5-426a-4104-9027-6a2a0b1b61c9', tid: '92730f69-ae57-401c-8ad1-2d07834a895d',
    reason: 'the whole row is "Republican Assistant Minority Leader with no evidence of support for campaign finance restrictions" plus national party positions. Her 89 bills include one election bill, on uniform treatment of vote-by-mail ballots, which is election administration and says nothing about donations or spending.' },
  { name: 'Kelly A. Dooner', topic: 'Same-Sex Marriage', pid: '247cf8e5-426a-4104-9027-6a2a0b1b61c9', tid: 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
    reason: 'the row reasons from an absence to a guess — "No evidence of Dooner publicly opposing same-sex marriage … she most likely defers to state-level decisions". Her 89 bills contain nothing on marriage, sexual orientation or gender identity.' },
  { name: 'Kelly A. Dooner', topic: 'Reproductive Rights and Abortion Access', pid: '247cf8e5-426a-4104-9027-6a2a0b1b61c9', tid: 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
    reason: 'the chair rests on "Republican affiliation and district profile" after stating "No MA legislative record of supporting abortion access". The bills the row does name (S.972-976, S.121-123) are emergency-housing and EBT measures. Her 89 bills contain nothing on abortion, reproduction, pregnancy or contraception.' },
];

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const rollback = [];
for (const w of [...RESOURCE, ...RETIRE]) {
  const { rows } = await pool.query(
    `SELECT c.reasoning, c.sources, a.value, p.full_name, t.title,
            (SELECT count(*) FROM inform.politician_answers x WHERE x.politician_id=c.politician_id) AS total_answers
     FROM inform.politician_context c
     JOIN essentials.politicians p ON p.id=c.politician_id
     LEFT JOIN inform.compass_topics t ON t.id=c.topic_id
     LEFT JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
     WHERE c.politician_id=$1::uuid AND c.topic_id=$2::uuid`, [w.pid, w.tid]);
  if (rows.length !== 1) throw new Error(`expected 1 row for ${w.name} / ${w.topic}, got ${rows.length}`);
  const r = rows[0];
  if (r.full_name !== w.name || r.title !== w.topic) throw new Error(`identity mismatch: ${r.full_name} / ${r.title}`);
  rollback.push({ ...w, action: w.reason ? 'retire' : 're-source',
    old_reasoning: r.reasoning, old_sources: r.sources, old_value: r.value, total_answers_before: Number(r.total_answers) });
}
// 🔑 Nobody may be emptied by this pass. A politician at zero answers with a SET research timestamp
// reads as "we looked and found nothing" — a real finding that must never be created by accident.
const byPol = {};
for (const r of rollback.filter((x) => x.action === 'retire')) (byPol[r.pid] ||= { name: r.name, n: 0, total: r.total_answers_before }).n++;
for (const [pid, v] of Object.entries(byPol)) {
  const left = v.total - v.n;
  console.log(`  ${v.name}: ${v.total} answers − ${v.n} retired = ${left} left`);
  if (left < 1) throw new Error(`${v.name} would be emptied by this pass (${v.total} - ${v.n})`);
}
await pool.end();
fs.writeFileSync(ROLLBACK, JSON.stringify({ pass: 'the-197 class B', rows: rollback }, null, 1));

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const arr = (a) => `ARRAY[${a.map(q).join(',')}]::text[]`;
const L = [];
L.push(`-- ${OUT.split(/[\\/]/).pop()}`);
L.push(`-- "The 197", class B — rows whose OWN reasoning declares that no evidence was found.`);
L.push(`--`);
L.push(`-- 🔑 THIS LOOKED LIKE THE CLEANEST RETIREMENT CLASS IN THE SET, because the author had already`);
L.push(`-- searched and reported the absence. Searching independently moved 3 of 14 rows OUT of it.`);
L.push(`-- Retirement is what is left after looking, not the first move.`);
L.push(`--`);
L.push(`-- RE-SOURCED (${RESOURCE.length}): Hyde-Smith and Wicker have recorded Senate votes on exactly the subjects`);
L.push(`-- their rows said nothing could be found for. Hyde-Smith's row said her record "suggests`);
L.push(`-- opposition to DISCLOSE Act" — she voted against cloture on it (S.4822, 117-2 roll 346).`);
L.push(`--`);
L.push(`-- RETIRED (${RETIRE.length}): chair rests on a party, caucus or district prior plus a declared absence, and`);
L.push(`-- an independent search of the member's own record found nothing on topic. Per the standing`);
L.push(`-- rule, where no source supports a chair the answer is NO STANCE — not a weaker chair.`);
L.push(`-- ⚠ The standard applied is VERIFIED ABSENT, never UNSURE. Rows that were merely hard to check`);
L.push(`-- are left alone, below.`);
L.push(`--`);
L.push(`-- ⚠ NOT RETIRED, deliberately:`);
L.push(`--   · Joyce / Medicare — real votes exist (IRA nay, OBBBA aye) but they are omnibus votes that`);
L.push(`--     pin no chair and if anything cut AGAINST the stored chair 3. A partial sample is not a search.`);
L.push(`--   · Ron Reynolds / Climate — capitol.texas.gov redirects to its search form, so his bill record`);
L.push(`--     could not be read at all. UNASSESSED IS NOT VERIFIED-ABSENT.`);
L.push(`--   · Carrie Isaac / Civil Rights — "critical race theory" IS on her cited page, in prose. The`);
L.push(`--     lexicon missed it because "race" is not "racial". A near-miss stem, not an absent topic.`);
L.push(`--   · Gimenez / Reproductive Rights — its affirmative claim cites ISideWith, which is not in the`);
L.push(`--     sources array. A CITATION GAP needing re-sourcing, not an absent stance.`);
L.push(`--   · Paxton / Medicare, McClain / Same-Sex Marriage — their "no evidence" clause NARROWS a chair`);
L.push(`--     on a row already carried by real evidence. The opposite of this defect, and the reason the`);
L.push(`--     detector keys on the row's ONLY claim being an absence rather than on the phrase.`);
L.push(`--`);
L.push(`-- Nobody is emptied: ${Object.values(byPol).map((v) => `${v.name} ${v.total}->${v.total - v.n}`).join(', ')}.`);
L.push(`-- Rollback (the only surviving copy of the retired rows): ${ROLLBACK}`);
L.push(`BEGIN;`);
L.push(``);
L.push(`CREATE TEMP TABLE classb_snapshot ON COMMIT DROP AS`);
L.push(`SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,`);
L.push(`       (SELECT count(*) FROM inform.politician_answers) AS ans_before;`);
L.push(``);
L.push(`-- ── RE-SOURCE ──────────────────────────────────────────────────────────────────────────────`);
for (const w of RESOURCE) {
  L.push(`-- ${w.name} / ${w.topic}`);
  L.push(`--   ${w.note}`);
  L.push(`UPDATE inform.politician_context SET sources = ${arr(w.sources)}, reasoning = ${q(w.why)}`);
  L.push(`WHERE politician_id = ${q(w.pid)}::uuid AND topic_id = ${q(w.tid)}::uuid;`);
  L.push(``);
}
L.push(`-- ── RETIRE ─────────────────────────────────────────────────────────────────────────────────`);
L.push(`CREATE TEMP TABLE _retire_classb (politician_id uuid, topic_id uuid) ON COMMIT DROP;`);
L.push(`INSERT INTO _retire_classb (politician_id, topic_id) VALUES`);
// ⚠ The comma must precede the trailing comment. Joining with ",\n" put it AFTER the comment, so
// every separator was commented out and the whole INSERT became a syntax error.
L.push(RETIRE.map((w, i) => `  (${q(w.pid)}, ${q(w.tid)})${i < RETIRE.length - 1 ? ',' : ';'}  -- ${w.name}: ${w.topic}`).join('\n'));
L.push(``);
for (const w of RETIRE) L.push(`-- ${w.name} / ${w.topic}:\n--   ${w.reason.replace(/(.{1,105})(\s|$)/g, '$1\n--   ').trim()}`);
L.push(``);
L.push(`DELETE FROM inform.politician_context c USING _retire_classb r`);
L.push(` WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;`);
L.push(`DELETE FROM inform.politician_answers a USING _retire_classb r`);
L.push(` WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;`);
L.push(``);
L.push(`-- Guard 1: the retired pairs are gone from BOTH tables.`);
L.push(`DO $$`);
L.push(`DECLARE n int;`);
L.push(`BEGIN`);
L.push(`  SELECT count(*) INTO n FROM inform.politician_answers a JOIN _retire_classb r USING (politician_id, topic_id);`);
L.push(`  IF n <> 0 THEN RAISE EXCEPTION 'guard 1 failed: % targeted answer(s) remain', n; END IF;`);
L.push(`  SELECT count(*) INTO n FROM inform.politician_context c JOIN _retire_classb r USING (politician_id, topic_id);`);
L.push(`  IF n <> 0 THEN RAISE EXCEPTION 'guard 1 failed: % targeted context row(s) remain', n; END IF;`);
L.push(`END $$;`);
L.push(``);
L.push(`-- Guard 2: NOBODY is emptied. A politician at zero answers reads as "we looked and found`);
L.push(`-- nothing" — a real finding this pass must never create by accident.`);
L.push(`DO $$`);
L.push(`DECLARE bad text;`);
L.push(`BEGIN`);
L.push(`  SELECT string_agg(p.full_name, ', ') INTO bad`);
L.push(`  FROM (SELECT DISTINCT politician_id FROM _retire_classb) t`);
L.push(`  JOIN essentials.politicians p ON p.id = t.politician_id`);
L.push(`  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id = t.politician_id);`);
L.push(`  IF bad IS NOT NULL THEN RAISE EXCEPTION 'guard 2 failed: emptied %', bad; END IF;`);
L.push(`END $$;`);
L.push(``);
L.push(`-- Guard 3: exactly ${RETIRE.length} answers and ${RETIRE.length} context rows removed, ${RESOURCE.length} rows re-sourced, no orphans.`);
L.push(`DO $$`);
L.push(`DECLARE ctx_after int; ans_after int; orphans int; snap record; n int;`);
L.push(`BEGIN`);
L.push(`  SELECT * INTO snap FROM classb_snapshot;`);
L.push(`  SELECT count(*) INTO ctx_after FROM inform.politician_context;`);
L.push(`  SELECT count(*) INTO ans_after FROM inform.politician_answers;`);
L.push(`  IF snap.ctx_before - ctx_after <> ${RETIRE.length} THEN RAISE EXCEPTION 'guard 3 failed: context moved % -> % (expected -${RETIRE.length})', snap.ctx_before, ctx_after; END IF;`);
L.push(`  IF snap.ans_before - ans_after <> ${RETIRE.length} THEN RAISE EXCEPTION 'guard 3 failed: answers moved % -> % (expected -${RETIRE.length})', snap.ans_before, ans_after; END IF;`);
L.push(`  SELECT count(*) INTO orphans FROM inform.politician_answers a`);
L.push(`  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c`);
L.push(`                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);`);
L.push(`  IF orphans > 0 THEN RAISE EXCEPTION 'guard 3 failed: % orphan answer(s)', orphans; END IF;`);
L.push(`  SELECT count(*) INTO n FROM inform.politician_context c`);
L.push(`   WHERE (c.politician_id, c.topic_id) IN (${RESOURCE.map((w) => `(${q(w.pid)}::uuid, ${q(w.tid)}::uuid)`).join(', ')})`);
L.push(`     AND EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%roll_call_vote_cfm.cfm%')`);
L.push(`     AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%wikipedia.org%' OR s LIKE '%ballotpedia.org%');`);
L.push(`  IF n <> ${RESOURCE.length} THEN RAISE EXCEPTION 'guard 3 failed: % of ${RESOURCE.length} re-sourced rows carry a Senate roll call and no encyclopaedia', n; END IF;`);
L.push(`  RAISE NOTICE 'class B ok: context %->%, answers %->%, orphans %', snap.ctx_before, ctx_after, snap.ans_before, ans_after, orphans;`);
L.push(`END $$;`);
L.push(``);
L.push(`COMMIT;`);

fs.writeFileSync(OUT, L.join('\n') + '\n');
console.log(`\nwrote ${OUT} (${RESOURCE.length} re-sourced, ${RETIRE.length} retired)`);
console.log(`wrote ${ROLLBACK}`);
