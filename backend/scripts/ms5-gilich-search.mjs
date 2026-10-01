#!/usr/bin/env node
/** Look for a better official portrait of Mayor Andrew "FoFo" Gilich than the lectern shot. */
const UA = { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' };
// 1. The city's own media library, by the WordPress search endpoint.
for (const q of ['Gilich', 'mayor portrait', 'FoFo']) {
  const u = `https://biloxi.ms.us/wp-json/wp/v2/media?search=${encodeURIComponent(q)}&per_page=30`;
  try {
    const r = await fetch(u, { headers: UA });
    const j = await r.json();
    console.log(`\n--- city media search "${q}" -> HTTP ${r.status}, ${Array.isArray(j) ? j.length : 'n/a'} items`);
    if (Array.isArray(j)) for (const m of j) {
      const d = m.media_details || {};
      console.log(`   ${String(d.width || '?')}x${String(d.height || '?')}  ${m.source_url}`);
    }
  } catch (e) { console.log(q, 'ERR', e.message); }
}
// 2. Wikimedia Commons.
const cu = 'https://commons.wikimedia.org/w/api.php?action=query&format=json&list=search&srsearch=' +
           encodeURIComponent('Gilich Biloxi mayor') + '&srnamespace=6&srlimit=20';
const cj = await (await fetch(cu, { headers: UA })).json();
console.log(`\n--- Commons: ${cj.query.search.length} hits`);
for (const s of cj.query.search) console.log('   ' + s.title);
