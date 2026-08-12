#!/usr/bin/env node
/**
 * Migration 1724 — the TEXAS slice of the "backed Medicaid expansion" template.
 *
 * 🔴 TEXAS NEVER EXPANDED MEDICAID, so the sentence cannot mean a vote for an enacted expansion. What
 * it CAN mean is authorship of an expansion bill — and in Texas those exist and are unmistakable
 * ("Relating to the expansion of eligibility for Medicaid ... under the federal Patient Protection and
 * Affordable Care Act"). 20 of the 24 rows here turn out to be exactly that: the member authored or
 * co-authored a real expansion bill, so the claim was TRUE and merely unevidenced. The remaining 4
 * cite the member's strongest Medicaid/insurance coverage bill instead, and the wording says only what
 * that bill shows.
 *
 * 🔑 SCOPE: only the 25 Texas rows at chair 1-2 on a health topic. Of the 55 Texas rows carrying the
 * phrase, 20 sit at chair 4-5 and NINE OF THOSE SAY THE MEMBER OPPOSED EXPANSION — correct, aligned
 * with an anti-pole chair, and not a defect at all. The phrase is not the defect; PRO wording with no
 * evidence is.
 *
 * 🔴🔴 THE IDENTITY TRAP THAT NEARLY SHIPPED — and it was MINE, not the data's. Resolving members by
 * SURNAME matched Cassandra Garcia Hernandez to code A3155, which is **Ana Hernandez**, a different
 * member, and would have described another woman's legislative record as hers. (Her stored sources
 * carry no member code at all, so nothing in production was wrong; the resolver was.) Identity is now
 * the TLO roster matched on the FULL name — A4495 = "Garcia Hernandez, Cassandra" — with a
 * most-specific-match rule, because bare "Hernandez" is also a subset of her name and a plain
 * uniqueness test therefore found two candidates and fell back to the wrong one. The report page's own
 * header is then checked against surname AND first name; a surname-only check passed "Rep. Ana
 * Hernandez" happily.
 *
 * 🔑 CHAIRS ARE NOT TOUCHED. Citations quote the bill's official CAPTION rather than paraphrasing.
 *
 *   node scripts/gen-1724-tx-medicaid-template.mjs --out <migration.sql> --rollback <rollback.json>
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out'), ROLLBACK = flag('--rollback');
if (!OUT || !ROLLBACK) { console.error('need --out --rollback'); process.exit(2); }

const P = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-tx-medicaid-proposals.json', 'utf8'));
const work = P.rows.filter((r) => r.proposal && r.name_confirms);
const owed = P.rows.filter((r) => !r.proposal || !r.name_confirms);
console.log(`${work.length} to re-source; ${owed.length} owed`);
for (const o of owed) console.log(`  owed: ${o.name} / ${o.topic} — ${o.blocked_reason || 'member name not confirmed'}`);

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const dburl = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: dburl, ssl: { rejectUnauthorized: false } });

const surnameOf = (n) => n.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)\.?$/i, '').trim().split(/\s+/).pop();
const updates = [], rollback = [];
for (const w of work) {
  const { rows: got } = await pool.query(
    `SELECT c.reasoning, c.sources, a.value, p.full_name, t.title
       FROM inform.politician_context c
       JOIN essentials.politicians p ON p.id = c.politician_id
       LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
       LEFT JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
      WHERE c.politician_id=$1::uuid AND c.topic_id=$2::uuid`, [w.politician_id, w.topic_id]);
  if (got.length !== 1) throw new Error(`expected 1 row for ${w.name}, got ${got.length}`);
  const live = got[0];
  if (live.full_name !== w.name || live.title !== w.topic) throw new Error(`identity mismatch for ${w.name}`);
  if (live.reasoning !== w.reasoning) throw new Error(`reasoning changed since the scan for ${w.name}/${w.topic}`);
  if (!/Medicaid expansion/i.test(live.reasoning)) throw new Error(`${w.name}: row no longer carries the template phrase`);
  if (Number(live.value) > 2) throw new Error(`${w.name}: chair ${live.value} is past the pro pole — refuse`);

  const p = w.proposal;
  const sess = p.session.replace(/^(\d+)([R1-9])$/, '$1($2)');
  const billNo = p.bill.replace(/^([HS]B)(\d+)$/, '$1 $2');
  const verb = p.kind === 'author' ? 'authored' : 'co-authored';
  // ⚠ TLO captions already end in a full stop, so appending one gave `…therapy services.".`
  const capt = p.caption.trim().replace(/\.*$/, '.');
  const why2 = `${surnameOf(w.name)} ${verb} ${billNo} in the ${sess} session, "${capt}"`
    + (p.isExpansion ? ' Texas has not adopted the expansion, so the bill did not become law.' : '');

  const url = `https://capitol.texas.gov/BillLookup/History.aspx?LegSess=${p.session}&Bill=${p.bill}`;
  const old = live.sources || [];
  // 🔴 drop the wrong-person member link where one was found; keep everything else
  const drop = w.wrong_stored_code ? new RegExp(`Code=${w.wrong_stored_code}\\b`) : null;
  const kept = old.filter((s) => s !== url && !(drop && drop.test(s)));
  const sources = [url, ...kept];

  updates.push({ ...w, new_reasoning: why2, new_sources: sources, dropped_wrong: !!w.wrong_stored_code });
  rollback.push({ politician_id: w.politician_id, topic_id: w.topic_id, name: w.name, topic: w.topic,
    old_reasoning: live.reasoning, old_sources: old, chair_untouched: Number(live.value) });
}
await pool.end();
fs.writeFileSync(ROLLBACK, JSON.stringify({ pass: 'TX medicaid-template re-sourcing (1723)', rows: rollback }, null, 1));
console.log(`  on an actual expansion bill: ${updates.filter((u) => u.proposal.isExpansion).length}; wrong-person links dropped: ${updates.filter((u) => u.dropped_wrong).length}`);

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const arr = (a) => `ARRAY[${a.map(q).join(',')}]::text[]`;
const L = [];
L.push(`-- ${OUT.split(/[\\/]/).pop()}`);
L.push(`-- THE TEXAS SLICE of the "backed Medicaid expansion" template.`);
L.push(`--`);
L.push(`-- 🔴 TEXAS NEVER EXPANDED MEDICAID, so the sentence cannot mean a vote for an enacted expansion.`);
L.push(`-- It CAN mean authorship of an expansion BILL, and those exist and are unmistakable. ${updates.filter((u) => u.proposal.isExpansion).length} of these`);
L.push(`-- ${updates.length} rows are exactly that — the member authored or co-authored a real expansion bill, so the`);
L.push(`-- claim was TRUE and merely unevidenced. The rest cite the member's strongest coverage bill.`);
L.push(`--`);
L.push(`-- 🔑 SCOPE: Texas rows at chair 1-2 on a health topic. Of the 55 Texas rows carrying the phrase,`);
L.push(`-- 20 sit at chair 4-5 and NINE OF THOSE SAY THE MEMBER OPPOSED EXPANSION — correct, aligned with`);
L.push(`-- an anti-pole chair, not a defect. The phrase is not the defect; PRO wording with no evidence is.`);
L.push(`--`);
L.push(`-- 🔴🔴 AN IDENTITY TRAP THAT NEARLY SHIPPED: Cassandra Garcia Hernandez's row CITES member code`);
L.push(`-- A3155, which is ANA Hernandez — a different member. Sourcing from the stored code would have`);
L.push(`-- described another woman's record as hers. Identity is the TLO roster matched on the FULL name`);
L.push(`-- (A4495 = "Garcia Hernandez, Cassandra"), and the report header is checked against surname AND`);
L.push(`-- first name — a surname-only check passed "Rep. Ana Hernandez" happily. The wrong-person link is`);
L.push(`-- removed from her sources here.`);
L.push(`--`);
L.push(`-- 🔑 CHAIRS ARE NOT TOUCHED. Citations quote the bill's official caption rather than paraphrasing.`);
L.push(`--`);
L.push(`-- Left owed:`);
for (const o of owed) L.push(`--   · ${o.name} / ${o.topic}: ${o.blocked_reason || 'member name not confirmed'}`);
L.push(`--`);
L.push(`-- Rollback: ${ROLLBACK}`);
L.push(`BEGIN;`);
L.push(``);
L.push(`CREATE TEMP TABLE tx_snapshot ON COMMIT DROP AS`);
L.push(`SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,`);
L.push(`       (SELECT count(*) FROM inform.politician_answers) AS ans_before,`);
L.push(`       (SELECT coalesce(sum(value), 0) FROM inform.politician_answers) AS chair_sum_before;`);
L.push(``);
L.push(`CREATE TEMP TABLE tx_intent (pid uuid, tid uuid, reasoning text, sources text[]) ON COMMIT DROP;`);
L.push(`INSERT INTO tx_intent (pid, tid, reasoning, sources) VALUES`);
updates.forEach((u, i) => {
  L.push(`-- ${u.name} / ${u.topic} (chair ${u.chair}) — ${u.proposal.kind} on ${u.proposal.session} ${u.proposal.bill}${u.dropped_wrong ? '  [wrong-person link dropped]' : ''}`);
  L.push(`(${q(u.politician_id)}, ${q(u.topic_id)}, ${q(u.new_reasoning)}, ${arr(u.new_sources)})${i === updates.length - 1 ? ';' : ','}`);
});
L.push(``);
L.push(`UPDATE inform.politician_context c SET reasoning = i.reasoning, sources = i.sources`);
L.push(`FROM tx_intent i WHERE c.politician_id = i.pid AND c.topic_id = i.tid;`);
L.push(``);
L.push(`-- Guard 1: intended text landed, a TLO bill page is cited, and the template phrase is GONE.`);
L.push(`DO $$`);
L.push(`DECLARE bad int;`);
L.push(`BEGIN`);
L.push(`  SELECT count(*) INTO bad FROM tx_intent i`);
L.push(`  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid`);
L.push(`  WHERE c.reasoning IS DISTINCT FROM i.reasoning OR c.sources IS DISTINCT FROM i.sources`);
L.push(`     OR c.reasoning ILIKE '%Medicaid expansion%'`);
L.push(`     OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%capitol.texas.gov/BillLookup/%');`);
L.push(`  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) wrong', bad; END IF;`);
L.push(`END $$;`);
L.push(``);
L.push(`-- Guard 2: exactly ${updates.length} rows touched, nothing created or deleted, NO CHAIR MOVED, no orphans.`);
L.push(`DO $$`);
L.push(`DECLARE n int; ctx_after int; ans_after int; chair_sum_after numeric; orphans int; snap record;`);
L.push(`BEGIN`);
L.push(`  SELECT * INTO snap FROM tx_snapshot;`);
L.push(`  SELECT count(*) INTO n FROM tx_intent i`);
L.push(`  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid;`);
L.push(`  IF n <> ${updates.length} THEN RAISE EXCEPTION 'guard 2 failed: matched % rows, expected ${updates.length}', n; END IF;`);
L.push(`  SELECT count(*) INTO ctx_after FROM inform.politician_context;`);
L.push(`  SELECT count(*) INTO ans_after FROM inform.politician_answers;`);
L.push(`  SELECT coalesce(sum(value), 0) INTO chair_sum_after FROM inform.politician_answers;`);
L.push(`  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 2 failed: context moved % -> %', snap.ctx_before, ctx_after; END IF;`);
L.push(`  IF ans_after <> snap.ans_before THEN RAISE EXCEPTION 'guard 2 failed: answers moved % -> %', snap.ans_before, ans_after; END IF;`);
L.push(`  IF chair_sum_after <> snap.chair_sum_before THEN RAISE EXCEPTION 'guard 2 failed: a chair moved (% -> %)', snap.chair_sum_before, chair_sum_after; END IF;`);
L.push(`  SELECT count(*) INTO orphans FROM inform.politician_answers a`);
L.push(`  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c`);
L.push(`                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);`);
L.push(`  IF orphans > 0 THEN RAISE EXCEPTION 'guard 2 failed: % orphan answer(s)', orphans; END IF;`);
L.push(`  RAISE NOTICE 'tx medicaid template ok: % rows', n;`);
L.push(`END $$;`);
L.push(``);
L.push(`COMMIT;`);
fs.writeFileSync(OUT, L.join('\n') + '\n');
console.log(`wrote ${OUT}\nwrote ${ROLLBACK}`);
