#!/usr/bin/env node
// Read the RR/CC's candidate list for election 4348 and work out, for every 2026-12-11 race,
// how many people ACTUALLY FILED nomination papers.
//
// 🔴🔴 THE COUNTY PUBLISHES TWO DATES AND ONLY THE SECOND IS A CANDIDACY. Every row carries
//   `nom_issue` (papers taken out) and `nom_file` (papers returned and accepted). Taking out
//   papers is not standing for election. Azusa Trustee Area 3 is the case that exposed it:
//   Tavia Lorese Lawson took papers out on 7/16 and NEVER FILED; Sandra Benavides issued and
//   filed on 8/7. One filed nominee for one seat, so Educ. Code § 5326 cancelled the election
//   and § 5328 seats Benavides.
//   ⚠ OUR OWN ROWS SAY "nomination papers filed" FOR BOTH. The seeding pass read the list and
//     kept everyone on it, so we hold candidacies for people who never stood.
//
// 🔴 WHAT HAPPENS TO A CANCELLED SEAT DEPENDS ON THE COUNT, AND THE TWO OUTCOMES ARE DIFFERENT
//   ACTS. Educ. Code § 5328, read 2026-11-08 at leginfo.legislature.ca.gov:
//     filed == seats  → "the qualified person or persons nominated shall be seated at the
//                        organizational meeting of the board ... as if elected".
//                        NOBODY IS APPOINTED. The name is on the county's own list.
//     filed <  seats  → "the governing board shall appoint a qualified person or persons".
//                        THE DISTRICT'S OWN BOARD appoints, so there is no county-wide list
//                        and each one needs that district's resolution or minutes.
//   ▶ There is no single source for the appointees, and for most of these seats there does not
//     need to be one.
//
// Usage: node check-nominations.mjs <candidate-list.html> <our-candidacies.json> <analysis.json>
import fs from 'node:fs';

const html = fs.readFileSync(process.argv[2], 'utf8');
const ours = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
const analysis = JSON.parse(fs.readFileSync(process.argv[4], 'utf8'));

if (!/mDetailedDisplay\(/.test(html)) throw new Error('this does not look like the RR/CC candidate list page');

// ── parse the candidate table ──
// each row's onclick carries, in order: party, write_in, incumbent, sil_issue, sil_file,
// doi_issue, doi_file, nom_issue, nom_file, contest_title, contest_id, candidate_id
const rows = [];
for (const chunk of html.split('<tr>')) {
  const m = /mDetailedDisplay\(([\s\S]*?)\)"/.exec(chunk);
  if (!m) continue;
  // the separators are not uniform — some are "','" and some "',  '" — so take the quoted
  // strings themselves rather than splitting on a separator that varies
  const args = [...m[1].matchAll(/'([^']*)'/g)].map((a) => a[1].trim());
  const name = /<b><a href="#">([^<]+)<\/a><\/b>/.exec(chunk)?.[1]?.trim();
  if (!name || args.length < 12) continue;
  rows.push({
    name,
    writeIn: args[1] === 'Y',
    incumbent: args[2] === 'E' || args[2] === 'I',
    nomIssue: args[7] || '',
    nomFile: args[8] || '',
    contest: args[9],
    contestId: args[10],
  });
}
if (rows.length < 400) throw new Error(`parsed only ${rows.length} candidate rows — the list has ~505`);

// 🔴 positive control: the parser must see the pair that exposed the distinction, on both sides
const benavides = rows.find((r) => /BENAVIDES/i.test(r.name) && /AZUSA/i.test(r.contest));
const lawson = rows.find((r) => /LAWSON/i.test(r.name) && /AZUSA/i.test(r.contest));
if (!benavides || !lawson) throw new Error('the parser cannot see the Azusa pair — every count below would be vacuous');
if (!benavides.nomFile) throw new Error('Benavides should read as FILED and does not — the column mapping is wrong');
if (lawson.nomFile) throw new Error('Lawson should read as NOT FILED and does not — the column mapping is wrong');

const filedByContest = new Map();
for (const r of rows) {
  if (!filedByContest.has(r.contestId)) filedByContest.set(r.contestId, { title: r.contest, filed: [], issuedOnly: [] });
  (r.nomFile ? filedByContest.get(r.contestId).filed : filedByContest.get(r.contestId).issuedOnly).push(r.name);
}

// ── our races ──
const byRace = new Map();
for (const r of ours) {
  if (!byRace.has(r.race_id)) byRace.set(r.race_id, { label: r.district_label, seats: r.seats, held: [] });
  byRace.get(r.race_id).held.push(r.full_name);
}
const anchored = new Map(analysis.report.filter((r) => r.anchor).map((r) => [r.race_id, r.anchor]));

const norm = (s) => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toUpperCase().replace(/[^A-Z0-9 ]/g, '').replace(/\s+/g, ' ').trim();
const short = (s) => { const t = norm(s).split(' '); return t.length > 2 ? `${t[0]} ${t[t.length - 1]}` : norm(s); };
const same = (a, b) => norm(a) === norm(b) || short(a) === short(b);

// ── match each CANCELLED race to its contest on the candidate list, by title ──
const cancelled = analysis.report.filter((r) => !r.anchor);
const out = { seated: [], boardAppoints: [], unmatched: [] };
for (const r of cancelled) {
  const mine = byRace.get(r.race_id);
  // ⚠ READ THE SEAT NUMBER OFF THE RAW LABEL. norm() strips the hyphen that separates the
  //   district from its area, so running this against the normalised string returned null for
  //   every districted seat — and the filter then demanded a contest with NO area, which
  //   matched 0 of 86 of them. Only the 10 at-large seats came through, and that looked like
  //   the candidate list simply not carrying the cancelled contests.
  const areaNo = /\s-\s(?:Trustee Area|Division|District)\s+([A-Za-z0-9]+)\s*$/.exec(r.district)?.[1]?.toUpperCase() ?? null;
  const key = norm(r.district.replace(/\s-\s(?:Trustee Area|Division|District)\s+[A-Za-z0-9]+\s*$/, ''));
  // 🔴 "CONTAINS EVERY WORD" IS NOT A MATCH — IT IS A FILTER THAT KEEPS SIBLINGS. "ABC" is
  //   three letters, so a length>3 rule dropped it and left NO words at all, which matched
  //   all 36 contests; and Whittier City against Whittier Union, or Pasadena Unified against
  //   South Pasadena and Pasadena Area, differ only by a word that "contains" does not police.
  //   ▶ Compare the DISTRICT-NAME PART of both strings as a SET, and require them equal.
  const GENERIC = /^(SCHOOL|DISTRICT|UNIFIED|ELEMENTARY|HIGH|UNION|BOARD|GOVERNING|MEMBER|MEMBERS|OF|EDUCATION|COMMUNITY|COLLEGE|THE|SPECIAL|ELECTION)$/;
  const nameSet = (s) => new Set(norm(s)
    .replace(/\s*(GOVERNING BOARD|BOARD OF EDUCATION|MEMBER)\b[\s\S]*$/, '')
    .split(' ').filter((w) => w && !GENERIC.test(w)));
  const eq = (a, b) => a.size === b.size && [...a].every((x) => b.has(x));
  const ours2 = nameSet(key);
  const areaOf = (t) => /(?:TRUSTEE AREA|DIVISION)(?: NO)? ([A-Z0-9]+)/.exec(norm(t))?.[1] ?? null;
  let hits = [...filedByContest.entries()]
    .filter(([, c]) => eq(ours2, nameSet(c.title)) && areaOf(c.title) === areaNo);
  if (hits.length === 0) {
    // the county sometimes abbreviates a name; fall back to containment, but only if it is unique
    hits = [...filedByContest.entries()]
      .filter(([, c]) => [...nameSet(c.title)].every((w) => ours2.has(w)) && areaOf(c.title) === areaNo);
  }
  if (hits.length !== 1) { out.unmatched.push({ race: r.district, hits: hits.length }); continue; }
  const [contestId, c] = hits[0];
  const rec = {
    race: r.district, seats: mine.seats, contestId, contest: c.title,
    filed: c.filed, issuedOnly: c.issuedOnly, weHold: mine.held,
    weHoldNonFilers: mine.held.filter((h) => !c.filed.some((f) => same(f, h))),
    filedWeLack: c.filed.filter((f) => !mine.held.some((h) => same(f, h))),
  };
  if (c.filed.length === mine.seats) out.seated.push(rec);
  else out.boardAppoints.push(rec);
}

const n = (a) => a.length;
console.log(`candidate rows parsed: ${rows.length} (${rows.filter((r) => r.nomFile).length} FILED, ${rows.filter((r) => !r.nomFile).length} issued-only)`);
console.log(`cancelled races: ${cancelled.length}`);
console.log(`  seated under Educ. Code 5328 — filed == seats, NOBODY APPOINTED: ${n(out.seated)}`);
console.log(`  the district's own board appoints — filed < seats:               ${n(out.boardAppoints)}`);
console.log(`  could not be matched to a contest on the candidate list:         ${n(out.unmatched)}`);
for (const u of out.unmatched) console.log(`      ${u.race} (${u.hits} hits)`);

const over = out.seated.concat(out.boardAppoints).filter((r) => r.filed.length > r.seats);
console.log(`\nraces where MORE people filed than there are seats: ${over.length}`);
console.log('  (Educ. Code 5326 cannot cancel such a race, so any of these breaks the reading)');
for (const o of over) console.log(`      ${o.race}: ${o.filed.length} filed for ${o.seats}`);

const stale = out.seated.concat(out.boardAppoints).filter((r) => r.weHoldNonFilers.length);
console.log(`\nour rows holding somebody who never filed: ${stale.length} race(s), ${stale.reduce((a, r) => a + r.weHoldNonFilers.length, 0)} candidacies`);
for (const s of stale.slice(0, 12)) console.log(`      ${s.race}: ${s.weHoldNonFilers.join(', ')}`);
if (stale.length > 12) console.log(`      ... and ${stale.length - 12} more`);

const missing = out.seated.concat(out.boardAppoints).filter((r) => r.filedWeLack.length);
console.log(`\nfiled candidates we hold NO row for: ${missing.length} race(s)`);
for (const m of missing) console.log(`      ${m.race}: ${m.filedWeLack.join(', ')}`);

fs.writeFileSync('nominations-2026-11-08.json', JSON.stringify(out, null, 1));
console.log('\nwrote nominations-2026-11-08.json');
