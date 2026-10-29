import { readFileSync, writeFileSync } from 'node:fs';

const DIR = 'C:/ev-accounts-knight-stances/backend/data/stance-research/2026-10-28-knight-phl-city/corpus';
const reports = JSON.parse(readFileSync(`${DIR}/phlcouncil-weekly-reports.json`, 'utf8'));

// The 17 current members, by the surname the reports use.
const MEMBERS = ['Squilla', 'Johnson', 'Gauthier', 'Jones', 'Young', 'Driscoll', 'Lozada', 'Bass',
  'Phillips', "O'Neill", 'Harrity', 'Thomas', 'Brooks', 'Gilmore Richardson', 'Ahmad', "O'Rourke", 'Landau'];

// COUNCIL IS 17. C46 needs >=10% against, so >=2 no votes out of 17 (11.8%). 16-1 is 5.9% and fails.
const SEATS = 17;
const divided = [];

// 🔴 WIDENED AFTER A FALSE ABSENCE. The first pattern matched only "vote of 13-3" and found 5
// tallies in 160 reports. A phrasing census over the same corpus showed the reports also write
// "approved by a 13-3 vote", "passed 12-4" and "the final vote was 14-2". A vote word is now
// required within 40 characters BEFORE the tally, which keeps dates, addresses and committee
// names out while admitting every real phrasing.
const voteRe = /(?:vote|voted|votes|approved|passed|adopted)\b[^.;]{0,40}?\b(\d{1,2})\s*[-\u2013]\s*(\d{1,2})\b/gi;

for (const r of reports) {
  let m;
  voteRe.lastIndex = 0;
  while ((m = voteRe.exec(r.text))) {
    const yes = Number(m[1]), no = Number(m[2]);
    const total = yes + no;
    if (!no || total < 8 || total > SEATS) continue;          // skip unanimous and non-council tallies
    const pct = no / total;
    const ctx = r.text.slice(Math.max(0, m.index - 420), m.index + 520);
    const bill = (ctx.match(/#\s?(\d{6})(-[A-Z])?/) || [])[0] ?? null;
    const named = MEMBERS.filter((n) => ctx.includes(n));
    divided.push({
      date: r.date.slice(0, 10), link: r.link, tally: `${yes}-${no}`,
      pctAgainst: +(pct * 100).toFixed(1), passesC46: pct >= 0.10, bill, named, ctx,
    });
  }
}

// De-duplicate: one tally can match twice when two vote words precede it.
const seen = new Set();
const uniq = divided.filter((d) => {
  const k = `${d.date}|${d.tally}|${d.bill}`;
  if (seen.has(k)) return false;
  seen.add(k); return true;
});

uniq.sort((a, b) => (a.date < b.date ? 1 : -1));
const usable = uniq.filter((d) => d.passesC46);
console.log(`weekly reports: ${reports.length}  (2019-09 .. 2025-10; the series STOPS there)`);
console.log(`divided tallies: ${uniq.length}`);
console.log(`PASS C46 (>=10% against): ${usable.length}   refused (under 10%): ${uniq.length - usable.length}`);
console.log('\n--- usable divided votes, newest first ---');
for (const d of usable.slice(0, 30)) {
  console.log(`${d.date}  ${d.tally.padStart(5)}  ${String(d.pctAgainst).padStart(5)}%  ${(d.bill ?? '—').padEnd(9)} ${d.named.join(', ').slice(0, 95) || '(no member named nearby)'}`);
}

const tally = {};
for (const d of usable) for (const n of d.named) tally[n] = (tally[n] ?? 0) + 1;
console.log('\n--- members named near a usable divided vote ---');
for (const [n, c] of Object.entries(tally).sort((a, b) => b[1] - a[1])) console.log(`  ${String(c).padStart(3)}  ${n}`);

writeFileSync(`${DIR}/phl-divided-votes.json`, JSON.stringify({ seats: SEATS, scanned: reports.length, divided: uniq, usable }, null, 1));
console.log(`\nwrote ${DIR}/phl-divided-votes.json`);
