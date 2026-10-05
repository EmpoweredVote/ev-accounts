// Per-member votes on ONE matter, found through its event items. Usage: node _matter_votes.mjs <client> <MatterFile>
// 🔴 Do not match a news article to a vote by subject-matter resemblance — look the matter up and
// read its tally. Duluth has a Lester Park CONVEYANCE ordinance (Dec 2025) and a Lester Park GOLF
// COURSE land-use decision (Aug 2026); they are different matters about the same neighbourhood.
const client = process.argv[2];
const file = process.argv[3];
const get = async (u) => { const r = await fetch(u); if (!r.ok) throw new Error(r.status + ' ' + u); return r.json(); };
const ms = await get(`https://webapi.legistar.com/v1/${client}/matters?$filter=MatterFile+eq+'${encodeURIComponent(file)}'`);
if (!ms.length) { console.log('no matter ' + file); process.exit(0); }
for (const m of ms) {
  console.log(`${m.MatterFile} (MatterId ${m.MatterId}) — ${m.MatterStatusName}`);
  console.log(`  ${(m.MatterTitle || '').replace(/\s+/g, ' ').slice(0, 200)}`);
  let hist = [];
  try { hist = await get(`https://webapi.legistar.com/v1/${client}/matters/${m.MatterId}/histories`); } catch (e) { console.log('  histories: ' + e.message); continue; }
  for (const h of hist) {
    // 🔴 The event-item id IS MatterHistoryId. Reading any other field returns a silent zero.
    let votes = [];
    try { votes = await get(`https://webapi.legistar.com/v1/${client}/eventitems/${h.MatterHistoryId}/votes`); } catch { /* none */ }
    const tally = {};
    for (const v of votes) tally[v.VoteValueName] = (tally[v.VoteValueName] || 0) + 1;
    console.log(`  ${(h.MatterHistoryActionDate || '').slice(0, 10)}  ${String(h.MatterHistoryActionName).padEnd(24)} votes=${votes.length} ${JSON.stringify(tally)}`);
    for (const v of votes) console.log(`      ${String(v.VoteValueName).padEnd(8)} ${v.VotePersonName}`);
  }
}
