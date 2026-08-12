#!/usr/bin/env node
/**
 * Migration 1721 — CLASS-C SOURCING for the instrument-free Maryland rows from migration 1714.
 *
 * These 35 rows name no bill and no act. Each member's own mgaleg sponsored-legislation list was read
 * per session, filtered to the topic, ranked, and every shortlisted bill's SYNOPSIS was read. The
 * citation below is chosen per row by reading, not by score.
 *
 * 🔑 CHAIRS ARE NOT TOUCHED. Reasoning and sources only.
 *
 * 🔴 WHAT THE OLD TEXT WAS. Every healthcare row said the member "backed Medicaid expansion" —
 * template text. Maryland expanded Medicaid in 2013, before most of these members were seated, so for
 * them the claim was not merely unsourced but impossible. The same template shape runs through the
 * housing rows ("backed tenant protection measures and affordable housing funding").
 *
 * 🔴 NINE ROWS ARE DELIBERATELY LEFT OWED rather than sourced to something weak:
 *   · 4 × Same-Sex Marriage (Ellis, Harris, Kramer, Watson). Maryland settled this with the 2012 Civil
 *     Marriage Protection Act and the corpus holds no usable 2012 bills. Ellis's ENTIRE tenure is
 *     readable and contains no same-sex-marriage bill at all — an absence that evidences nothing,
 *     because there was nothing left to vote on. Harris's only "domestic partner" hit is a financial-
 *     disclosure ethics bill, which is not a marriage position.
 *   · Harris, Love and Watson on Healthcare Access, and Watson on Affordable Housing: no coverage or
 *     access bill in their readable sessions. Watson's health leads are paternity testing and sickle
 *     cell — public health, not access.
 *   · Muse on Childcare: nothing on topic in his readable sessions.
 * ⚠ For all but Ellis these rows ALSO have unreadable sessions (see below), so "no bill found" is not
 * a finding about the member. They stay as they are, and stay owed.
 *
 * 🔴🔴 THE UNREADABLE-SESSION TRAP. mgaleg member records are CHAMBER-SCOPED: asking a current
 * senator's record for a session when they sat in the House returns an empty list, not an error.
 * Alonzo T. Washington's ten House sessions read as "sponsored nothing". Any row whose evidence would
 * have to come from a pre-switch session is reported as owed, never as absent.
 *
 *   node scripts/gen-1721-md-classc-sourcing.mjs --out <migration.sql> --rollback <rollback.json>
 */
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';
import { UA, sponsorSlugs } from './lib/md-rollcall.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out'), ROLLBACK = flag('--rollback');
if (!OUT || !ROLLBACK) { console.error('need --out --rollback'); process.exit(2); }

const CACHE = 'C:/Users/Chris/AppData/Local/Temp/ev-stance-cache/mdcorpus';
const BILLS = path.join(CACHE, 'bill-cache');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * The curated picks. `clause` is written by hand FROM the synopsis — a synopsis is legislative prose
 * and unreadable on a voter-facing page — and `chapter` is asserted so the generator can check it
 * against the live page rather than trusting the note.
 */
const PICKS = [
  // ── Healthcare Access (chair 2: affordable coverage via public programs + regulated insurance) ──
  { name: 'Joanne C. Benson', topic: 'Healthcare Access', bill: '2023RS:sb0965', role: 'lead', chapter: 353,
    clause: 'requiring health insurers to cover lung cancer screening and diagnostic imaging and capping what they may charge for it' },
  { name: 'Nick Charles', topic: 'Healthcare Access', bill: '2025RS:sb0518', role: 'lead',
    clause: 'requiring insurers to cover preventive ovarian cancer screening and prohibiting them from imposing a copayment, coinsurance or deductible for it' },
  { name: 'Arthur Ellis', topic: 'Healthcare Access', bill: '2025RS:sb0094', role: 'lead', chapter: 715,
    clause: 'requiring the Maryland Medical Assistance Program to cover self-measured blood pressure monitoring for maternal health, and to reimburse the provider time it takes' },
  { name: 'Shaneka Henson', topic: 'Healthcare Access', bill: '2025RS:sb0508', role: 'lead',
    clause: 'requiring the Maryland Medical Assistance Program and private insurers to cover medically necessary restorative care for victims of domestic violence' },
  { name: 'William C. Smith, Jr.', topic: 'Healthcare Access', bill: '2019RS:sb0765', role: 'lead',
    clause: 'extending from 18 to 36 months the period for which group health plans must offer continuation coverage to people who lose their job' },
  { name: 'Cheryl C. Kagan', topic: 'Healthcare Access', bill: '2020RS:sb0402', role: 'lead', chapter: 16,
    clause: 'letting health care practitioners establish a patient relationship by telehealth, which widens access where providers are scarce' },
  { name: 'C. Anthony Muse', topic: 'Healthcare Access', bill: '2025RS:sb0646', role: 'lead', chapter: 689,
    clause: 'barring insurers from imposing step-therapy or fail-first protocols on insulin' },
  { name: 'Jim Rosapepe', topic: 'Healthcare Access', bill: '2018RS:sb0858', role: 'lead', chapter: 488,
    clause: 'requiring carriers to let enrollees use local health departments as in-network providers' },
  { name: 'Alonzo T. Washington', topic: 'Healthcare Access', bill: '2025RS:sb0372', role: 'cosp', chapter: 481,
    clause: 'the Preserve Telehealth Access Act of 2025, which keeps telehealth coverage and payment parity in place' },

  // ── Affordable Housing ──────────────────────────────────────────────────────────────────────────
  { name: 'Joanne C. Benson', topic: 'Affordable Housing', bill: '2024RS:sb0992', role: 'lead',
    clause: 'requiring a landlord to notify a tenant once a court has issued a warrant of restitution for failure to pay rent, before the tenant can be put out' },
  { name: 'Nick Charles', topic: 'Affordable Housing', bill: '2024RS:sb0671', role: 'lead',
    clause: 'establishing access to counsel so homeowners have legal representation in foreclosure proceedings' },
  { name: 'Arthur Ellis', topic: 'Affordable Housing', bill: '2021RS:sb0937', role: 'lead',
    clause: 'requiring the Department of Housing and Community Development to weigh a family\u2019s student loan debt when setting eligibility for mortgage, down payment and settlement expense assistance' },
  { name: 'Kevin M. Harris', topic: 'Affordable Housing', bill: '2026RS:sb0389', role: 'cosp',
    clause: 'automatically designating qualifying transit-oriented developments as enterprise zones to speed housing construction near transit' },
  { name: 'Shaneka Henson', topic: 'Affordable Housing', bill: '2025RS:sb0856', role: 'lead', chapter: 539,
    clause: 'the Maryland Tenant Mold Protection Act, setting landlord obligations and regulations for mold in rental housing' },
  { name: 'William C. Smith, Jr.', topic: 'Affordable Housing', bill: '2018RS:sb1218', role: 'lead', chapter: 748,
    clause: 'the Ending Youth Homelessness Act, establishing a grant program to prevent and end youth homelessness' },
  { name: 'Cheryl C. Kagan', topic: 'Affordable Housing', bill: '2023RS:sb0848', role: 'cosp', chapter: 446,
    clause: 'establishing a Statewide Rental Assistance Voucher Program to provide housing vouchers through the Department of Housing and Community Development' },
  { name: 'Benjamin F. Kramer', topic: 'Affordable Housing', bill: '2022RS:sb0592', role: 'cosp', chapter: 672,
    clause: 'preserving a tenant\u2019s right to redeem leased premises after a judgment for failure to pay rent' },
  { name: 'Sara Love', topic: 'Affordable Housing', bill: '2026RS:sb0335', role: 'lead', chapter: 773,
    clause: 'barring a landlord from refusing to rent to a tenant because they pay with an income-based housing subsidy' },
  { name: 'C. Anthony Muse', topic: 'Affordable Housing', bill: '2024RS:sb0356', role: 'lead',
    clause: 'requiring local jurisdictions to run an expedited development review process for proposed affordable housing developments' },
  { name: 'Jim Rosapepe', topic: 'Affordable Housing', bill: '2015RS:sb0372', role: 'cosp',
    clause: 'creating a tax subtraction for First-Time Homebuyer Savings Accounts' },
  { name: 'Jeff Waldstreicher', topic: 'Affordable Housing', bill: '2024RS:sb0199', role: 'lead', chapter: 288,
    clause: 'authorizing a condominium regime on land owned by an affordable housing land trust, so trusts can hold land under permanently affordable homes' },
  { name: 'Alonzo T. Washington', topic: 'Affordable Housing', bill: '2023RS:sb0807', role: 'cosp',
    clause: 'deeming a rented dwelling warranted fit for human habitation and giving tenants remedies when a landlord fails to repair serious and dangerous defects' },

  // ── Rent Regulation (chair 2: strengthen rent stabilization and extend coverage) ────────────────
  { name: 'Sara Love', topic: 'Rent Regulation', bill: '2025RS:sb0609', role: 'lead',
    clause: 'prohibiting a landlord from using algorithmic devices to set the rent charged to residential tenants' },
  { name: 'Jeff Waldstreicher', topic: 'Rent Regulation', bill: '2024RS:sb0354', role: 'lead', chapter: 295,
    clause: 'establishing a Rent Court Workforce Solutions Pilot Program for tenants facing failure-to-pay-rent proceedings in Montgomery and Prince George\u2019s counties' },

  // ── Misinformation ──────────────────────────────────────────────────────────────────────────────
  { name: 'Cheryl C. Kagan', topic: 'Misinformation and the Role of Algorithms in Democracy', bill: '2026RS:sb0141', role: 'cosp', chapter: 444,
    clause: 'empowering the State Administrator of Elections to act on credible reports of election misinformation and disinformation' },
];

/** Rows deliberately left as they are, with the reason recorded rather than glossed. */
const OWED = [
  ['Kevin M. Harris', 'Healthcare Access', 'only broad co-sponsorships (preventive-services recommendations); 3 pre-switch sessions unreadable'],
  ['Sara Love', 'Healthcare Access', 'only co-sponsorships of preventive-services bills; 6 pre-switch sessions unreadable'],
  ['Ron Watson', 'Healthcare Access', 'lead bills are paternity testing and sickle cell — public health, not coverage or access; 3 sessions unreadable'],
  ['Ron Watson', 'Affordable Housing', 'no on-topic bill in readable sessions; 3 sessions unreadable'],
  ['Arthur Ellis', 'Same-Sex Marriage', 'entire tenure readable and contains no same-sex-marriage bill — Maryland settled the question in 2012, before he was seated'],
  ['Kevin M. Harris', 'Same-Sex Marriage', 'only hit is a financial-disclosure ethics bill mentioning domestic partners; not a marriage position'],
  ['Benjamin F. Kramer', 'Same-Sex Marriage', 'no on-topic bill in readable sessions; 6 pre-switch sessions unreadable'],
  ['Ron Watson', 'Same-Sex Marriage', 'no on-topic bill in readable sessions; 3 sessions unreadable'],
  ['C. Anthony Muse', 'Childcare Affordability & Access', 'no on-topic bill in readable sessions; 7 sessions unreadable'],
];
/** Verified as already correct; no change. */
const VERIFIED = [
  ['Kevin M. Harris', 'Childcare Affordability & Access', 'already cites SB0664 (2026), which he leads, and SB0402 (2026), enacted as Chapter 641 — both confirmed by slug'],
];

const surnameOf = (n) => n.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)\.?$/i, '').trim().split(/\s+/).pop();
const textOf = (h) => h.replace(/<[^>]*>/g, ' ').replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ');

async function billHtml(slug, session) {
  const f = path.join(BILLS, `${slug}-${session}.html`);
  if (fs.existsSync(f) && fs.statSync(f).size > 5000) return fs.readFileSync(f, 'utf8');
  const res = await fetch(`https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${slug}?ys=${session}`, { headers: { 'User-Agent': UA } });
  const body = await res.text(); await sleep(1100);
  if (!res.ok || body.length < 20000) return null;
  fs.writeFileSync(f, body); return body;
}

const LEG = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-md-member-legislation.json', 'utf8'));
const rowOf = (name, topic) => LEG.rows.find((r) => r.name === name && r.topic === topic);
const corpus = JSON.parse(fs.readFileSync(path.join(CACHE, 'md-bill-corpus.json'), 'utf8'));
const meta = {};
for (const b of corpus.bills) if (b.title && b.title.length > 5) meta[`${b.session}:${b.slug}`] = b;

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const dburl = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: dburl, ssl: { rejectUnauthorized: false } });

const updates = [], rollback = [];
for (const p of PICKS) {
  const row = rowOf(p.name, p.topic);
  if (!row) throw new Error(`no legislation row for ${p.name} / ${p.topic}`);
  const m = meta[p.bill];
  if (!m) throw new Error(`${p.bill} not in the corpus`);
  const [session, slug] = p.bill.split(':');

  const html = await billHtml(slug, session);
  if (!html) throw new Error(`${p.bill}: bill page unavailable`);
  const t = textOf(html);

  // 🔑 identity re-checked at write time, from the bill page's own sponsor hyperlink
  const slugs = sponsorSlugs(html);
  const confirmed = slugs.some((s) => s.slug === row.member_slug);
  const stale = slugs.length && !confirmed;
  if (stale) console.log(`  ⚠ ${p.name} / ${p.bill}: member slug ${row.member_slug} not in sponsor links [${slugs.map((s) => s.slug).join(',')}]`);

  // 🔑 the asserted chapter is checked against the page, so a hand-written note cannot drift
  const sp = t.indexOf('Sponsored by');
  const statusText = sp > -1 ? t.slice(t.indexOf('Status', sp) + 6, t.indexOf('Status', sp) + 140) : '';
  const chapMatch = statusText.match(/Chapter\s+(\d+)/i);
  if (p.chapter != null) {
    if (!chapMatch || parseInt(chapMatch[1], 10) !== p.chapter) {
      throw new Error(`${p.name} / ${p.bill}: asserted Chapter ${p.chapter} but the page says "${statusText.trim().slice(0, 70)}"`);
    }
  } else if (chapMatch) {
    console.log(`  note: ${p.name} / ${p.bill} was enacted (Chapter ${chapMatch[1]}) but no chapter was asserted`);
  }

  const { rows: got } = await pool.query(
    `SELECT c.reasoning, c.sources, a.value, pol.full_name, t.title
       FROM inform.politician_context c
       JOIN essentials.politicians pol ON pol.id = c.politician_id
       LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
       LEFT JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
      WHERE c.politician_id=$1::uuid AND c.topic_id=$2::uuid`, [row.politician_id, row.topic_id]);
  if (got.length !== 1) throw new Error(`expected 1 row for ${p.name}/${p.topic}, got ${got.length}`);
  const live = got[0];
  if (live.full_name !== p.name || live.title !== p.topic) throw new Error(`identity mismatch for ${p.name}/${p.topic}`);
  if (live.reasoning !== row.reasoning) throw new Error(`reasoning changed since the scan for ${p.name}/${p.topic}`);

  const year = session.slice(0, 4);
  const chapterClause = p.chapter != null ? ` It was enacted as Chapter ${p.chapter} of ${year}.` : '';
  const verb = p.role === 'lead' ? 'was the lead sponsor of' : 'co-sponsored';
  const why = `${surnameOf(p.name)} ${verb} ${m.number} (${year}), ${p.clause}.${chapterClause}`;

  const url = `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${slug}?ys=${session}`;
  const old = live.sources || [];
  const sources = [url, ...old.filter((s) => s !== url)];

  updates.push({ ...row, new_reasoning: why, new_sources: sources, bill: p.bill, role: p.role });
  rollback.push({ politician_id: row.politician_id, topic_id: row.topic_id, name: p.name, topic: p.topic,
    old_reasoning: live.reasoning, old_sources: old, chair_untouched: Number(live.value) });
}
await pool.end();
fs.writeFileSync(ROLLBACK, JSON.stringify({ pass: 'MD class-C sourcing (1720)', rows: rollback }, null, 1));

console.log(`\n${updates.length} row(s) re-sourced; ${OWED.length} left owed; ${VERIFIED.length} verified unchanged.`);
for (const u of updates) console.log(`  ${u.role.toUpperCase().padEnd(4)} ${u.bill}  ${u.name} / ${u.topic}`);

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const arr = (a) => `ARRAY[${a.map(q).join(',')}]::text[]`;
const L = [];
L.push(`-- ${OUT.split(/[\\/]/).pop()}`);
L.push(`-- CLASS-C SOURCING for the instrument-free Maryland rows left by migration 1714.`);
L.push(`--`);
L.push(`-- These rows named no bill and no act. Each member's own mgaleg sponsored-legislation list was`);
L.push(`-- read per session, filtered to the topic, and every shortlisted bill's SYNOPSIS was read; the`);
L.push(`-- citation is chosen per row by reading, not by score.`);
L.push(`--`);
L.push(`-- 🔑 CHAIRS ARE NOT TOUCHED. Reasoning and sources only.`);
L.push(`--`);
L.push(`-- 🔴 WHAT THE OLD TEXT WAS. Every healthcare row said the member "backed Medicaid expansion" —`);
L.push(`-- template text. Maryland expanded Medicaid in 2013, before most of these members were seated,`);
L.push(`-- so for them it was not merely unsourced but impossible. The housing rows run the same shape.`);
L.push(`--`);
L.push(`-- 🔴 ${OWED.length} ROWS ARE DELIBERATELY LEFT OWED rather than sourced to something weak:`);
for (const [n, t, why] of OWED) L.push(`--   · ${n} / ${t}: ${why}`);
L.push(`--`);
L.push(`-- 🔴🔴 THE UNREADABLE-SESSION TRAP. mgaleg member records are CHAMBER-SCOPED: asking a current`);
L.push(`-- senator's record for a session when they sat in the House returns an EMPTY LIST, not an error.`);
L.push(`-- Alonzo T. Washington's ten House sessions read as "sponsored nothing". So "no bill found" is`);
L.push(`-- never reported as a fact about a member with unreadable sessions — it is reported as owed.`);
L.push(`--`);
for (const [n, t, why] of VERIFIED) L.push(`-- ✓ ${n} / ${t}: ${why} — left unchanged.`);
L.push(`--`);
L.push(`-- Rollback: ${ROLLBACK}`);
L.push(`BEGIN;`);
L.push(``);
L.push(`CREATE TEMP TABLE cc_snapshot ON COMMIT DROP AS`);
L.push(`SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,`);
L.push(`       (SELECT count(*) FROM inform.politician_answers) AS ans_before,`);
L.push(`       (SELECT coalesce(sum(value), 0) FROM inform.politician_answers) AS chair_sum_before;`);
L.push(``);
L.push(`CREATE TEMP TABLE cc_intent (pid uuid, tid uuid, reasoning text, sources text[]) ON COMMIT DROP;`);
L.push(`INSERT INTO cc_intent (pid, tid, reasoning, sources) VALUES`);
updates.forEach((u, i) => {
  L.push(`-- ${u.name} / ${u.topic} — ${u.role} on ${u.bill}`);
  L.push(`(${q(u.politician_id)}, ${q(u.topic_id)}, ${q(u.new_reasoning)}, ${arr(u.new_sources)})${i === updates.length - 1 ? ';' : ','}`);
});
L.push(``);
L.push(`UPDATE inform.politician_context c SET reasoning = i.reasoning, sources = i.sources`);
L.push(`FROM cc_intent i WHERE c.politician_id = i.pid AND c.topic_id = i.tid;`);
L.push(``);
L.push(`-- Guard 1: every targeted row holds its intended text and cites an mgaleg bill page.`);
L.push(`DO $$`);
L.push(`DECLARE bad int;`);
L.push(`BEGIN`);
L.push(`  SELECT count(*) INTO bad FROM cc_intent i`);
L.push(`  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid`);
L.push(`  WHERE c.reasoning IS DISTINCT FROM i.reasoning OR c.sources IS DISTINCT FROM i.sources`);
L.push(`     OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%mgaleg.maryland.gov/mgawebsite/Legislation/Details/%');`);
L.push(`  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) wrong', bad; END IF;`);
L.push(`END $$;`);
L.push(``);
L.push(`-- Guard 2: exactly ${updates.length} rows touched, nothing created or deleted, NO CHAIR MOVED, no orphans.`);
L.push(`DO $$`);
L.push(`DECLARE n int; ctx_after int; ans_after int; chair_sum_after numeric; orphans int; snap record;`);
L.push(`BEGIN`);
L.push(`  SELECT * INTO snap FROM cc_snapshot;`);
L.push(`  SELECT count(*) INTO n FROM cc_intent i`);
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
L.push(`  RAISE NOTICE 'class-C sourcing ok: % rows, context=% answers=% orphans=%', n, ctx_after, ans_after, orphans;`);
L.push(`END $$;`);
L.push(``);
L.push(`COMMIT;`);
fs.writeFileSync(OUT, L.join('\n') + '\n');
console.log(`wrote ${OUT}\nwrote ${ROLLBACK}`);
