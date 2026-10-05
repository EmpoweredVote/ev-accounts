// How ONE member voted on every DIVIDED matter in a window, with the tally and the action text.
// Usage: node member_votes.mjs <client> <YYYY-MM-DD from> <bodyId> "Surname"
//
// 🔴 Built because the divided list alone names only the NAYS. A member who voted Yea on a divided
// matter is invisible in it, and a member's Yea on a contested measure is as much a position as a
// Nay. It also prints the action text, because that is what separates a vote on the MERITS from a
// vote to TABLE, and C46 should refuse the latter.
// ⚠ Paginates. A single $top call is a CAP, not a window — see divided_votes.mjs.
const client = process.argv[2];
const from = process.argv[3];
const bodyId = process.argv[4] || '138';
const who = (process.argv[5] || '').toLowerCase();
if (!who) { console.error('usage: member_votes.mjs <client> <from> <bodyId> "Surname"'); process.exit(1); }

const get = async (u) => { const r = await fetch(u, { signal: AbortSignal.timeout(40000) }); if (!r.ok) throw new Error(`${r.status} ${u}`); return r.json(); };

const events = [];
for (let skip = 0; ; skip += 100) {
  const page = await get(`https://webapi.legistar.com/v1/${client}/events?$filter=EventBodyId+eq+${bodyId}+and+EventDate+ge+datetime'${from}'&$orderby=EventDate+desc&$top=100&$skip=${skip}`);
  events.push(...page);
  if (page.length < 100) break;
}
const dates = events.map((e) => (e.EventDate || '').slice(0, 10)).filter(Boolean).sort();
console.log(`meetings: ${events.length} (${dates[0]} to ${dates[dates.length - 1]})`);

const rows = [];
let seen = 0;
for (const e of events) {
  let items;
  try { items = await get(`https://webapi.legistar.com/v1/${client}/events/${e.EventId}/eventitems?AgendaNote=0&MinutesNote=0`); } catch { continue; }
  for (const it of items) {
    if (!it.EventItemMatterFile) continue;
    let votes;
    try { votes = await get(`https://webapi.legistar.com/v1/${client}/eventitems/${it.EventItemId}/votes`); } catch { continue; }
    if (!Array.isArray(votes) || !votes.length) continue;
    const yea = votes.filter((v) => v.VoteValueName === 'Yea').length;
    const nay = votes.filter((v) => v.VoteValueName === 'Nay').length;
    if (!nay || nay / (yea + nay) < 0.10) continue;   // C46
    seen++;
    const mine = votes.find((v) => String(v.VotePersonName).toLowerCase().includes(who));
    rows.push({
      date: (e.EventDate || '').slice(0, 10),
      file: it.EventItemMatterFile,
      tally: `${yea}-${nay}`,
      vote: mine ? mine.VoteValueName : '—  (not on the council / absent)',
      action: (it.EventItemActionName || ''),
      actionText: (it.EventItemActionText || '').replace(/\s+/g, ' ').slice(0, 170),
      title: (it.EventItemTitle || '').replace(/\s+/g, ' ').slice(0, 150),
    });
  }
  process.stdout.write('.');
}
console.log(`\ndivided matters (C46): ${seen}`);
const present = rows.filter((r) => r.vote === 'Yea' || r.vote === 'Nay');
console.log(`"${process.argv[5]}" recorded on ${present.length} of them — Yea ${present.filter((r) => r.vote === 'Yea').length} / Nay ${present.filter((r) => r.vote === 'Nay').length}\n`);
for (const r of rows) {
  console.log(`${r.date}  ${r.file.padEnd(13)} ${r.tally.padStart(5)}  ${String(r.vote).padEnd(5)}  ${r.action}`);
  console.log(`              ${r.title}`);
  if (/tabl|postpone|refer|withdraw/i.test(r.action + r.actionText)) console.log(`              ⚠ PROCEDURAL: ${r.actionText}`);
}
