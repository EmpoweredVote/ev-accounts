// Find DIVIDED roll calls for a Legistar client in a date window.
// Usage: node divided-votes.mjs <client> <YYYY-MM-DD from> [bodyId]
const client = process.argv[2];
const from = process.argv[3];
const bodyId = process.argv[4] || '138';

const get = async (u) => { const r = await fetch(u); if (!r.ok) throw new Error(`${r.status} ${u}`); return r.json(); };

const events = await get(`https://webapi.legistar.com/v1/${client}/events?$filter=EventBodyId+eq+${bodyId}+and+EventDate+ge+datetime'${from}'&$orderby=EventDate+desc&$top=40`);
console.log(`meetings since ${from}: ${events.length}`);

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
