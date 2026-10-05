// Print a Legistar matter's identity: file number, title, type, status and dates.
// Usage: node _matter.mjs <client> <MatterFile>
const client = process.argv[2];
const file = process.argv[3];
const get = async (u) => { const r = await fetch(u); if (!r.ok) throw new Error(r.status + ' ' + u); return r.json(); };
const q = `https://webapi.legistar.com/v1/${client}/matters?$filter=MatterFile+eq+'${encodeURIComponent(file)}'`;
const ms = await get(q);
if (!ms.length) { console.log('no matter ' + file); process.exit(0); }
for (const m of ms) {
  console.log(`MatterId ${m.MatterId} | ${m.MatterFile} | ${m.MatterTypeName} | ${m.MatterStatusName}`);
  console.log(`  intro: ${(m.MatterIntroDate || '').slice(0, 10)}   agenda: ${(m.MatterAgendaDate || '').slice(0, 10)}   passed: ${(m.MatterPassedDate || '').slice(0, 10)}`);
  console.log(`  title: ${(m.MatterTitle || '').replace(/\s+/g, ' ')}`);
  let hist = [];
  try { hist = await get(`https://webapi.legistar.com/v1/${client}/matters/${m.MatterId}/histories`); } catch (e) { console.log('  histories: ' + e.message); }
  for (const h of hist) {
    console.log(`   ${(h.MatterHistoryActionDate || '').slice(0, 10)}  ${String(h.MatterHistoryActionName).padEnd(22)} ${h.MatterHistoryActionBodyName || ''}  pass=${h.MatterHistoryPassedFlagName || ''}`);
  }
}
