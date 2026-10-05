// Find DIVIDED roll calls for a Legistar client in a date window.
// Usage: node divided-votes.mjs <client> <YYYY-MM-DD from> [bodyId]
const client = process.argv[2];
const from = process.argv[3];
const bodyId = process.argv[4] || '138';

const get = async (u) => { const r = await fetch(u, { signal: AbortSignal.timeout(40000) }); if (!r.ok) throw new Error(`${r.status} ${u}`); return r.json(); };

// 🔴 THIS USED TO BE A SINGLE `$top=40` CALL, WHICH IS A CAP, NOT A WINDOW. Duluth has had more
// than 40 council meetings since 2025, so `from=2024-01-04` and `from=2025-01-01` returned the SAME
// 40 most recent meetings and the SAME 10 divided votes — byte-identical output for a window twice
// as long. That reads as "2024 adds nothing" and actually means "2024 was never fetched".
// The whole point of this script is that a sample is not a census; it was quietly taking a sample.
const events = [];
for (let skip = 0; ; skip += 100) {
  const page = await get(`https://webapi.legistar.com/v1/${client}/events?$filter=EventBodyId+eq+${bodyId}+and+EventDate+ge+datetime'${from}'&$orderby=EventDate+desc&$top=100&$skip=${skip}`);
  events.push(...page);
  if (page.length < 100) break;
  if (skip > 2000) { console.log('!! stopped paging at 2000 meetings — widen this guard if that is real'); break; }
}
const dates = events.map((e) => (e.EventDate || '').slice(0, 10)).filter(Boolean).sort();
console.log(`meetings since ${from}: ${events.length}  (covering ${dates[0]} to ${dates[dates.length - 1]})`);
if (!events.length) { console.log('🔴 ZERO MEETINGS — check the bodyId, not the date'); }

let scanned = 0, withVotes = 0;
const divided = [];
for (const e of events) {
  let items;
  try { items = await get(`https://webapi.legistar.com/v1/${client}/events/${e.EventId}/eventitems?AgendaNote=0&MinutesNote=0`); } catch { continue; }
  for (const it of items) {
    if (!it.EventItemMatterFile) continue;
    scanned++;
    let votes;
    try { votes = await get(`https://webapi.legistar.com/v1/${client}/eventitems/${it.EventItemId}/votes`); } catch { continue; }
    if (!Array.isArray(votes) || !votes.length) continue;
    withVotes++;
    const tally = {};
    for (const v of votes) tally[v.VoteValueName] = (tally[v.VoteValueName] || 0) + 1;
    const yea = tally.Yea || 0, nay = tally.Nay || 0;
    const total = yea + nay;
    if (nay > 0 && total > 0 && nay / total >= 0.10) {
      divided.push({
        date: (e.EventDate || '').slice(0, 10),
        file: it.EventItemMatterFile,
        title: (it.EventItemTitle || '').replace(/\s+/g, ' ').slice(0, 110),
        tally: `${yea}-${nay}`,
        nays: votes.filter((v) => v.VoteValueName === 'Nay').map((v) => v.VotePersonName).join(', '),
      });
    }
  }
  process.stdout.write('.');
}
console.log(`\nitems scanned: ${scanned} | items with a recorded roll call: ${withVotes}`);
console.log(`DIVIDED (>=10% against, C46): ${divided.length}\n`);
for (const d of divided) {
  console.log(`${d.date}  ${d.file.padEnd(14)} ${d.tally.padStart(5)}  nays: ${d.nays}`);
  console.log(`              ${d.title}`);
}
