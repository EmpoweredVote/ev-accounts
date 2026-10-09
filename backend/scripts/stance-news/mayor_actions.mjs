// Find a MAYOR's own recorded acts in Legistar: vetoes, and ordinances that passed without signature.
// Usage: node mayor_actions.mjs <client> <YYYY-MM-DD from> [bodyId]
//
// 🔴 A mayor casts no votes, so member_votes.mjs finds nothing and the divided-vote census is silent
// about the executive. The mayor's recorded act is the SIGNATURE: signing, vetoing, or letting an
// ordinance pass unsigned. That shows up only in the event item's action text.
// ⚠ Not signing has TWO readings — disapproval, or simply letting it take effect — so it is a lead,
// never a chair on its own.
import process from 'node:process';
const client = process.argv[2];
const from = process.argv[3];
const bodyId = process.argv[4] || '138';
const get = async (u) => { const r = await fetch(u, { signal: AbortSignal.timeout(40000) }); if (!r.ok) throw new Error(`${r.status} ${u}`); return r.json(); };

const events = [];
for (let skip = 0; ; skip += 100) {
  const page = await get(`https://webapi.legistar.com/v1/${client}/events?$filter=EventBodyId+eq+${bodyId}+and+EventDate+ge+datetime'${from}'&$orderby=EventDate+desc&$top=100&$skip=${skip}`);
  events.push(...page);
  if (page.length < 100) break;
}
console.log(`meetings: ${events.length}`);

const PAT = /veto|without mayoral signature|mayor'?s? signature|returned by the mayor|disapprov/i;
let scanned = 0;
const hits = [];
for (const e of events) {
  let items;
  try { items = await get(`https://webapi.legistar.com/v1/${client}/events/${e.EventId}/eventitems?AgendaNote=0&MinutesNote=0`); } catch { continue; }
  for (const it of items) {
    if (!it.EventItemMatterFile) continue;
    scanned++;
    const txt = `${it.EventItemActionText || ''} ${it.EventItemActionName || ''}`.replace(/\s+/g, ' ');
    if (!PAT.test(txt)) continue;
    hits.push({ date: (e.EventDate || '').slice(0, 10), file: it.EventItemMatterFile, title: (it.EventItemTitle || '').replace(/\s+/g, ' ').slice(0, 130), txt: txt.slice(0, 220) });
  }
  process.stdout.write('.');
}
console.log(`\nitems scanned: ${scanned} | mayoral-signature events: ${hits.length}\n`);
// 🔴 A zero here is a finding only if the pattern can fire at all. Say so rather than printing nothing.
if (!hits.length) console.log('no match — confirm the pattern by searching a matter you KNOW passed unsigned before trusting this zero');
for (const h of hits) {
  console.log(`${h.date}  ${h.file.padEnd(13)} ${h.title}`);
  console.log(`              ${h.txt}`);
}
