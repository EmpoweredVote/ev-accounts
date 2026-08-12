#!/usr/bin/env node
/**
 * Turn the landmark-act report into a per-row sourcing decision.
 *
 * 🔑 THE BILL IS CHOSEN BY WHAT THE CLAIM SAYS, NOT BY WHAT SCORES BEST. A first cut ranked candidate
 * bills by vote margin and picked HB1372/2021 ("Blueprint - Revisions") for every childcare row purely
 * because its roll call was the most divided. But the childcare claim lives in HB1300 — the enacted
 * implementation, Chapter 36 of 2021 — whose text carries 159 "prekindergarten", 28 "child care" and 3
 * "Child Care Scholarship" mentions. HB1372 merely alters implementation dates. Ranking by margin was
 * ranking by the wrong thing.
 *
 * 🔑 A NEAR-UNANIMOUS VOTE IS NOT A POSITION. SB1030/2019 passed the Senate 43-1 and then 45-0. A Yea
 * there distinguishes nobody and cannot carry a compass chair, so votes whose losing side is under 10%
 * of those cast are not usable as evidence. SPONSORSHIP of the same bill is fine — that is a positive
 * act, not a bandwagon.
 *
 * 🔑 SPONSORSHIP BEATS A VOTE, and where both exist both are cited: the bill page shows the sponsorship,
 * the roll-call PDF shows the vote.
 *
 * 🔴 Reads only. Emits a disposition to be READ before any migration is generated.
 *   node scripts/md-landmark-disposition.mjs --out <disposition.json>
 */
import fs from 'node:fs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out', 'data/stance-retirement/2026-08-12-landmark-disposition.json');

const R = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-landmark-acts.json', 'utf8'));

/** the losing side must be at least this share of votes cast for the vote to distinguish anyone */
const MIN_MINORITY = 0.10;

/**
 * Candidate bills in CLAIM ORDER — the bill that carries the claim comes first, and the fallbacks are
 * the same act at a different stage. Anything not listed is not evidence for that claim.
 */
const PREFERENCE = {
  'climate-solutions-now': [
    // the enacted Act, then the 2021 version of the same Act (passed the Senate, died in the House)
    '2022RS SB0528', '2021RS SB0414', '2021RS HB0583',
  ],
  blueprint: [
    // the enacted implementation — the only Blueprint bill whose text carries pre-K and Child Care
    // Scholarship provisions — then the establishing act, then the revisions
    '2020RS HB1300', '2020RS SB1000', '2019RS SB1030', '2019RS HB1413', '2021RS HB1372', '2021RS SB0965',
  ],
};

/**
 * 🔑 THE TOPIC CLAUSE IS QUOTED FROM THE ENACTED TEXT, NOT RECALLED. Every one of these rows claims
 * something topic-specific — "childcare investment and pre-K expansion", "environmental justice for
 * communities disproportionately affected by pollution" — and a bare "voted for the Blueprint" would
 * not justify a childcare chair at all. Neither claim appears in the bill SYNOPSIS, so each was checked
 * against the enacted chapter text, which carries it:
 *   Ch. 36 of 2021 (HB1300): 159 × "prekindergarten", 28 × "child care", 3 × "Child Care Scholarship"
 *   Ch. 38 of 2022 (SB0528): 88 × "greenhouse gas", 20 × "environmental justice", "OVERBURDENED COMMUNITY"
 * ⚠ The clause is attached ONLY when the row is cited to that enacted bill; an earlier or later stage of
 * the same act is a different text and cannot borrow it.
 */
const ACT = {
  'climate-solutions-now': {
    name: 'Climate Solutions Now Act',
    enacted: '2022RS SB0528',
    clause: 'establishes a net-zero statewide greenhouse gas emissions goal and directs benefits to communities it defines as overburdened and underserved',
    text_url: 'https://mgaleg.maryland.gov/2022RS/chapters_noln/Ch_38_sb0528E.pdf',
    chapter: 'Chapter 38 of 2022',
  },
  blueprint: {
    name: "Blueprint for Maryland's Future",
    enacted: '2020RS HB1300',
    clause: 'establishes a publicly funded full-day prekindergarten program and extends Child Care Scholarship Program access for income-eligible families',
    text_url: 'https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf',
    chapter: 'Chapter 36 of 2021',
  },
};
const ACT_NAME = Object.fromEntries(Object.entries(ACT).map(([k, v]) => [k, v.name]));

/** ⚠ "William C. Smith, Jr." must not become "Jr." — strip the suffix before taking the surname. */
const surnameOf = (n) => n.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)\.?$/i, '').trim().split(/\s+/).pop();

/**
 * 🔑 RETIREMENT IS WHAT IS LEFT AFTER LOOKING. Two rows credit a member with backing the Climate
 * Solutions Now Act while they were not in the legislature at all — Kevin M. Harris (House 2023-2025,
 * Senate since December 2025) and C. Anthony Muse (Senate 2007-2019, then again from 2023) both sit in
 * a gap that swallows the Act's 2021 and 2022 sessions. The claim as written cannot be true.
 *
 * But an unsupportable SENTENCE is not an unsupportable CHAIR. Both members have real, in-tenure clean-
 * energy records, found by searching their own sponsored bills, so the row is RE-SOURCED rather than
 * retired. Both sit at chair 3 — "invest in clean energy while gradually reducing fossil fuels" — which
 * these bills support; the chair is not touched.
 *
 * ⚠ Identity is settled by mgaleg itself, not by the surname: SB0669 and SB0923 both appear on Harris's
 * own member page, and SB0120's sponsor link points at `muse01`.
 */
const REPLACEMENT = {
  'Kevin M. Harris|Climate Change and Environmental Protection': {
    why: 'Harris is the lead sponsor of SB0669 (2026), which extends the Small Solar Energy Generating System Incentive Program deadline to 2031 and doubles eligible in-State solar capacity from 270 to 540 megawatts. He also introduced SB0923 (2026), establishing solar photovoltaic, energy storage and zero-emission vehicle funds, which he later withdrew.',
    sources: [
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0669?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0923?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03',
    ],
  },
  'C. Anthony Muse|Climate Change and Environmental Protection': {
    why: 'Muse is the sponsor of SB0120 (2025), enacted as Chapter 516, which bars land-use restrictions that raise the cost of installing a solar collector system by 5% or more, or that cut its efficiency by 10% or more.',
    sources: [
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0120?ys=2025RS',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01',
    ],
  },
};

const rows = [];
for (const r of R.rows) {
  const order = PREFERENCE[r.act];
  const byBill = Object.fromEntries((r.evidence || []).map((e) => [e.bill, e]));

  let sponsorOn = null, voteOn = null;
  for (const bill of order) {
    const e = byBill[bill];
    if (!e) continue;
    if (!sponsorOn && e.sponsor === 'SPONSOR') sponsorOn = e;
    if (!voteOn) {
      const usable = (e.votes || []).filter((v) => {
        if (v.verdict !== 'YEA') return false;
        const y = v.declared.YEA ?? 0, n = v.declared.NAY ?? 0;
        return y + n > 0 && n / (y + n) >= MIN_MINORITY;
      // ⚠ PREFER THE THIRD READING. Sorting by margin alone put SB0528's "Senate Concurs House
      // Amendments" (31-15) ahead of its Third Reading (32-15) on a fraction of a percent. The Third
      // Reading is the vote on the bill; a concurrence is a vote on the other chamber's amendments,
      // and citing it invites the reader to check a sheet that does not look like passage.
      }).sort((a, b) => (/Third Reading/i.test(b.action) ? 1 : 0) - (/Third Reading/i.test(a.action) ? 1 : 0)
                      || a.href.localeCompare(b.href));
      if (usable.length) voteOn = { e, v: usable[0] };
    }
    if (sponsorOn && voteOn) break;
  }

  // ⚠ a Yea that exists but is too lopsided to mean anything is recorded, so "no usable vote" is never
  // confused with "did not vote for it"
  const lopsided = (r.evidence || []).flatMap((e) => (e.votes || []).filter((v) => v.verdict === 'YEA'))
    .filter((v) => { const y = v.declared.YEA ?? 0, n = v.declared.NAY ?? 0; return y + n > 0 && n / (y + n) < MIN_MINORITY; });

  const notServing = (r.evidence || []).every((e) => e.chamber_note === 'NOT_SERVING in that session');

  let verdict, sources = [], why = null;
  if (sponsorOn || voteOn) {
    verdict = sponsorOn ? 'SPONSOR' : 'VOTE';
    const act = ACT[r.act];
    // ⚠ VOTER-FACING PROSE, not a log line. Building it by concatenating relative clauses produced
    // "…communities it defines as overburdened and underserved, which passed the Senate 32-15" — a
    // dangling second "which". The record goes in the first sentence, what the Act does in the second.
    const sur = surnameOf(r.name);
    const num = (e) => e.bill.split(' ')[1];
    const yr = (e) => e.session.slice(0, 4);
    const chamberOf = (v) => (v.chamber === 'house' ? 'House' : 'Senate');
    if (sponsorOn) sources.push(sponsorOn.url);
    if (voteOn) {
      if (!sources.includes(voteOn.e.url)) sources.push(voteOn.e.url);
      sources.push(`https://mgaleg.maryland.gov${voteOn.v.href}`);
    }
    const passed = voteOn ? `${chamberOf(voteOn.v)} ${voteOn.v.declared.YEA}-${voteOn.v.declared.NAY}` : null;

    let first;
    if (sponsorOn && voteOn && sponsorOn.bill === voteOn.e.bill) {
      first = `${sur} was one of ${sponsorOn.n_sponsors} sponsors of ${num(sponsorOn)} (${yr(sponsorOn)}), the ${act.name}, and voted for it on passage, which cleared the ${passed}.`;
    } else if (sponsorOn && voteOn) {
      first = `${sur} was one of ${sponsorOn.n_sponsors} sponsors of ${num(sponsorOn)} (${yr(sponsorOn)}), the ${act.name}, and voted Yea on ${num(voteOn.e)} (${yr(voteOn.e)}), which passed the ${passed}.`;
    } else if (sponsorOn) {
      first = `${sur} was one of ${sponsorOn.n_sponsors} sponsors of ${num(sponsorOn)} (${yr(sponsorOn)}), the ${act.name}.`;
    } else {
      first = `${sur} voted Yea on ${num(voteOn.e)} (${yr(voteOn.e)}), the ${act.name}, which passed the ${passed}.`;
    }

    // the topic clause only where the row is cited to the enacted text that carries it
    const onEnacted = [sponsorOn?.bill, voteOn?.e.bill].includes(act.enacted);
    if (onEnacted) sources.push(act.text_url);
    why = onEnacted
      ? `${first} Enacted as ${act.chapter}, ${act.enacted.split(' ')[1]} ${act.clause}.`
      : first;
  } else if (notServing && REPLACEMENT[`${r.name}|${r.topic}`]) {
    // 🔴 the claim as written cannot be true, but a searched-for in-tenure record replaces it
    const rep = REPLACEMENT[`${r.name}|${r.topic}`];
    verdict = 'RESOURCED_PRETENURE';
    why = rep.why;
    sources = [...rep.sources];
  } else if (notServing) {
    verdict = 'NOT_SERVING';   // 🔴 the claim cannot be true — the member was not in the legislature
  } else {
    verdict = 'UNRESOLVED';
  }

  rows.push({
    politician_id: r.politician_id, topic_id: r.topic_id, name: r.name, topic: r.topic, chair: r.chair,
    act: r.act, verdict, old_reasoning: r.reasoning, old_sources: r.sources,
    evidence_sources: sources, evidence_clause: why,
    sponsor_on: sponsorOn ? sponsorOn.bill : null,
    vote_on: voteOn ? `${voteOn.e.bill} ${voteOn.v.declared.YEA}-${voteOn.v.declared.NAY}` : null,
    lopsided_votes_ignored: lopsided.map((v) => `${v.href} ${v.declared.YEA}-${v.declared.NAY}`),
    tenure: r.tenure, spans: r.spans,
  });
}

const tally = rows.reduce((m, r) => { m[r.verdict] = (m[r.verdict] || 0) + 1; return m; }, {});
console.log(JSON.stringify(tally, null, 1));
for (const r of rows) {
  console.log(`\n[${r.verdict}] ${r.name} | ${r.topic} | chair ${r.chair}`);
  console.log(`  old : ${r.old_reasoning}`);
  if (r.evidence_clause) console.log(`  new : ${r.evidence_clause}`);
  for (const s of r.evidence_sources) console.log(`   +  ${s}`);
  if (r.lopsided_votes_ignored.length) console.log(`  ⚠ ignored as near-unanimous: ${r.lopsided_votes_ignored.join(', ')}`);
}
fs.writeFileSync(OUT, JSON.stringify({ pass: 'landmark-act sourcing disposition', tally, rows }, null, 1));
console.log(`\nwrote ${OUT}`);
