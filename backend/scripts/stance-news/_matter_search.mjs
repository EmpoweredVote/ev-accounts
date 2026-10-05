// Search Legistar matters by a phrase in the title. Usage: node _matter_search.mjs <client> "<phrase>"
// ⚠ substringof has NO word boundary — a bare stem matches unrelated words (searching `rent` returns
// CONCURRENT use permits). Search the phrase, not the stem.
const client = process.argv[2];
const phrase = process.argv[3];
const get = async (u) => { const r = await fetch(u); if (!r.ok) throw new Error(r.status + ' ' + u); return r.json(); };
const q = `https://webapi.legistar.com/v1/${client}/matters?$filter=substringof('${encodeURIComponent(phrase)}',MatterTitle)&$orderby=MatterIntroDate+desc&$top=40`;
const ms = await get(q);
console.log(`matters whose title contains "${phrase}": ${ms.length}`);
for (const m of ms) {
  console.log(`${(m.MatterIntroDate || '').slice(0, 10)}  ${String(m.MatterFile).padEnd(12)} ${String(m.MatterStatusName).padEnd(10)} ${(m.MatterTitle || '').replace(/\s+/g, ' ').slice(0, 130)}`);
}
