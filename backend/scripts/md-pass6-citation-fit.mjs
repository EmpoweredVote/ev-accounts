#!/usr/bin/env node
/**
 * PASS 6 -- CITATION FIT. Does each confirmed sponsorship correspond to the instrument the row's
 * reasoning actually MEANS?
 *
 * 🔑 THE LESSON THIS ENCODES (mig 1686, a self-correction to 1685): sponsorship proves "she
 * sponsored this bill", NEVER "this bill is the one the reasoning means". 3 of 229 citations in
 * 1685 were real bills the legislator really sponsored -- and the WRONG instrument.
 *
 * This extends audit-1685-citation-fit.mjs with the gate that pass 4 did not need and pass 6 does:
 * ⚠ AN ACT NAME CAN EXIST IN MULTIPLE SESSIONS, exactly like a bare bill number.
 *     Climate Solutions Now Act -> 2021RS AND 2022RS
 *     Maryland Voting Rights Act -> 2024RS, 2025RS AND 2026RS
 *     Juvenile Justice Restoration Act -> 2024RS AND 2025RS
 * Confirming sponsorship of the 2021 CSNA for a row that says "the 2022 Act" attaches a real bill
 * the member really sponsored, and it is still the wrong instrument.
 *
 * ⚠ CHECK PARENTHETICALS BEFORE CALLING A TITLE A MISMATCH. MD carries short titles inside the
 * formal title -- "...Fund (Climate Crimes Accountability Act)". 5 of 8 flags in the 1685 audit
 * were the audit being too strict, not defects. norm() strips punctuation, so this is handled.
 *
 * 🔴 Writes nothing to the DB. Emits an audit for a human to read.
 *
 *   node scripts/md-pass6-citation-fit.mjs --worklist <wl.json> --sponsorship <sp.json> \
 *        --corpus <corpus.json> --out <audit.json>
 */
import fs from 'node:fs';
import { norm, buildIndex, lookupAct } from './lib/md-instruments.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const wl = JSON.parse(fs.readFileSync(flag('--worklist'), 'utf8'));
const sp = JSON.parse(fs.readFileSync(flag('--sponsorship'), 'utf8'));
const { bills } = JSON.parse(fs.readFileSync(flag('--corpus'), 'utf8'));
const idx = buildIndex(bills);

const wlByKey = new Map(wl.rows.map((r) => [`${r.politician_id}|${r.topic_id}`, r]));
const spRows = Array.isArray(sp) ? sp : (sp.rows || []);
const confirmed = spRows.filter((r) => r.verdict === 'SPONSOR_CONFIRMED');

/** Every session in which this act name exists at all. */
const sessionCache = new Map();
function sessionsForAct(inst) {
  if (sessionCache.has(inst)) return sessionCache.get(inst);
  const r = lookupAct(inst, idx);
  const s = [...new Set((r.hits || []).map((h) => h.session.slice(0, 4)))].sort();
  sessionCache.set(inst, s);
  return s;
}

const findings = [];
for (const r of confirmed) {
  const w = wlByKey.get(`${r.politician_id}|${r.topic_id}`);
  const reasoning = w?.reasoning || r.reasoning || '';
  const years = [...new Set([...reasoning.matchAll(/\b(20\d{2})\b/g)].map((m) => m[1]))];
  const allMatched = (r.evidence || []).filter((e) => e.matched_slug);
  const attached = [...allMatched].sort((a, b) => a.session.localeCompare(b.session)).slice(0, 4);
  // 🔑 Ambiguity only matters when it CHANGES THE VERDICT. If the member sponsored the act in every
  // session it exists in, "which one does the prose mean" has no wrong answer -- the claim holds
  // either way. Reserve the human's attention for the rows where the choice is load-bearing.
  const sponsoredYears = new Set(allMatched.map((e) => e.session.slice(0, 4)));

  for (const e of attached) {
    const inst = e.instrument;
    const isNum = /^[SH]B\d{4}$/.test(inst);
    const sessYear = e.session.slice(0, 4);
    let verdict;
    let note = null;

    if (!isNum) {
      // ⚠ AUDITOR ARTIFACT, caught by reading the first cut (this is the FOURTH over-fire in this
      // workstream -- every first cut over-fires). Where the extractor resolved a CONJUNCTION
      // ("Juvenile Justice Restoration Act and Juvenile Offender Protection Act"), the welded
      // string can never appear in any single bill title, so a correct citation scored NO_FIT.
      // Test the fit against each PART, exactly as the corpus resolved it.
      const wlInst = (w?.instruments || []).find((x) => x.instrument === inst);
      const names = wlInst?.verdict === 'FOUND_CONJUNCTION'
        ? wlInst.conjunction_parts.map((p) => p.part)
        : [inst];
      // ⚠ OVER-FIRE B: a strict substring test fails on MD's hyphen-segmented titles, where the
      // prose's trailing "Act" is not contiguous with the rest:
      //   "Corporate Income Tax Rate Reduction Act"
      //     vs "Corporate Income Tax - Rate Reduction (Economic Competitiveness Act of 2026)"
      // All six words are present, just interrupted. Accept an all-token match -- but ONLY for names
      // long enough that co-occurrence means something.
      // 🔑 The >=4-token floor is what keeps the CROWN Act trap caught: "crown act" is 2 tokens, and
      // its tokens DO both occur in "...Prohibited Ingredients (Crown Act)" -- a cosmetics bill that
      // is not Maryland's CROWN Act (2020RS SB0531/HB1444, whose title has no "CROWN" at all).
      // Short names collide; long ones do not.
      const carries = (nm) => {
        const t = norm(e.title), n = norm(nm);
        if (t.includes(n)) return true;
        const toks = n.split(' ').filter((x) => x.length > 2);
        return toks.length >= 4 && toks.every((x) => t.includes(x));
      };
      const titleCarries = names.some(carries);
      if (!titleCarries) {
        verdict = 'NO_FIT';
      } else if (!years.length) {
        const all = sessionsForAct(inst);
        if (all.length <= 1) {
          verdict = 'TITLE_CARRIES_ACT';
        } else if (all.every((y) => sponsoredYears.has(y))) {
          verdict = 'TITLE_CARRIES_ACT_ALL_SESSIONS';
          note = `sponsored every session the act exists in (${all.join(', ')}) -- the choice is not load-bearing`;
        } else {
          verdict = 'ACT_AMBIGUOUS_NO_YEAR';
          note = `act exists in ${all.join(', ')}; sponsored ${[...sponsoredYears].sort().join(', ')}`;
        }
      } else if (years.includes(sessYear)) {
        verdict = 'TITLE_CARRIES_ACT_AND_YEAR';
      } else {
        const all = sessionsForAct(inst);
        const proseYearHasAct = years.some((y) => all.includes(y));
        // ⚠ OVER-FIRE A: this loop scores each attachment independently, so a member who sponsored
        // the act in FOUR sessions produced three "mismatches" alongside one correct citation. The
        // question is not "is this attachment the right year" but "IS THE RIGHT YEAR AVAILABLE
        // AMONG THE ATTACHMENTS" -- if it is, the row is settled and the rest are surplus to drop,
        // not evidence of a wrong instrument.
        if (years.some((y) => sponsoredYears.has(y))) {
          verdict = 'SURPLUS_SESSION';
          note = `prose says ${years.join('/')}; the matching year IS sponsored and cited separately -- drop this one`;
          findings.push({
            politician: r.politician, politician_id: r.politician_id, topic: r.topic, topic_id: r.topic_id,
            instrument: inst, from_bill_number: isNum, attached: `${e.session} ${e.number}`,
            title: e.title, verdict, note, stated_years: years,
            url: `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${e.slug}?ys=${e.session}`,
            reasoning,
          });
          continue;
        }
        // 🔑 The distinction that decides the disposition:
        //  - the act ALSO exists in the year the prose names -> we attached the WRONG one (SUSPECT)
        //  - it does not -> the prose's YEAR is simply wrong; substance may be fine, but the
        //    reasoning is voter-facing so the year must be corrected alongside the citation.
        verdict = proseYearHasAct ? 'ACT_YEAR_MISMATCH' : 'ACT_YEAR_STALE';
        note = `prose says ${years.join('/')}, attached ${sessYear}; act exists in ${all.join(', ')}`;
      }
    } else {
      const numOk = e.number.toUpperCase() === inst;
      if (numOk && years.length && years.includes(sessYear)) verdict = 'NUMBER_AND_YEAR';
      else if (numOk && !years.length) verdict = 'NUMBER_NO_YEAR_STATED';
      else if (numOk) verdict = 'NUMBER_ONLY';
      else verdict = 'NO_FIT';
    }

    findings.push({
      politician: r.politician, politician_id: r.politician_id,
      topic: r.topic, topic_id: r.topic_id,
      instrument: inst, from_bill_number: isNum,
      attached: `${e.session} ${e.number}`, title: e.title,
      verdict, note, stated_years: years,
      url: `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${e.slug}?ys=${e.session}`,
      reasoning,
    });
  }
}

const CLEAN = new Set(['TITLE_CARRIES_ACT_AND_YEAR', 'TITLE_CARRIES_ACT', 'TITLE_CARRIES_ACT_ALL_SESSIONS', 'NUMBER_AND_YEAR', 'SURPLUS_SESSION']);
const tally = findings.reduce((m, f) => { m[f.verdict] = (m[f.verdict] || 0) + 1; return m; }, {});
const suspect = findings.filter((f) => !CLEAN.has(f.verdict));

console.log(`confirmed rows: ${confirmed.length} -> citations examined: ${findings.length}`);
console.log(JSON.stringify(tally, null, 2));
console.log(`\nclean: ${findings.length - suspect.length}   NEEDS A HUMAN: ${suspect.length}\n`);
for (const f of suspect) {
  console.log(`[${f.verdict}] ${f.politician} / ${f.topic}`);
  console.log(`   named   : ${f.instrument}`);
  console.log(`   attached: ${f.attached}  ${f.title.slice(0, 88)}`);
  if (f.note) console.log(`   note    : ${f.note}`);
  console.log(`   prose   : ${f.reasoning.slice(0, 170)}\n`);
}
if (flag('--out')) fs.writeFileSync(flag('--out'), JSON.stringify({ tally, clean: findings.length - suspect.length, findings }, null, 1));
