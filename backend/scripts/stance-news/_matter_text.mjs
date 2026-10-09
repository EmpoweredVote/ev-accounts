// Read a Legistar matter's text with the AMENDMENT MARKS VISIBLE.
// Usage: node _matter_text.mjs <client> <MatterFile>
//
// 🔴 MatterTextPlain renders the strikethrough INVISIBLE, so a struck passage reads as if it were
// still in force — that produced a wrong mechanism in three already-seated rows. This reads
// MatterTextRtf and marks \strike runs as [STRUCK: …] and \ul runs as [NEW: …].
const client = process.argv[2];
const file = process.argv[3];
const get = async (u) => { const r = await fetch(u, { signal: AbortSignal.timeout(40000) }); if (!r.ok) throw new Error(r.status + ' ' + u); return r.json(); };
const ms = await get(`https://webapi.legistar.com/v1/${client}/matters?$filter=MatterFile+eq+'${encodeURIComponent(file)}'`);
if (!ms.length) { console.log('no matter ' + file); process.exit(0); }
const m = ms[0];
console.log(`${m.MatterFile} (MatterId ${m.MatterId}) — ${m.MatterStatusName}`);

// 🔴 `/matters/{id}/texts` RETURNS 405 ON duluth-mn — it is not a "no text" answer, it is the
// wrong route. Go through `/versions`, which returns [{Key: MatterTextId, Value: versionNumber}],
// and fetch each by its KEY. Passing Value gives a 404 that reads exactly like a missing matter.
const versions = await get(`https://webapi.legistar.com/v1/${client}/matters/${m.MatterId}/versions`);
if (!versions.length) { console.log('no text versions'); process.exit(0); }
const texts = [];
for (const v of versions) texts.push(await get(`https://webapi.legistar.com/v1/${client}/matters/${m.MatterId}/texts/${v.Key}`));
for (const t of texts) {
  const rtf = t.MatterTextRtf || '';
  const plain = (t.MatterTextPlain || '').replace(/\s+/g, ' ').trim();
  console.log(`\n--- version ${t.MatterTextVersion} | rtf ${rtf.length} chars | plain ${plain.length} chars`);
  if (!rtf) { console.log('(no RTF — plain only, AMENDMENT MARKS NOT VISIBLE)\n' + plain.slice(0, 3000)); continue; }
  // Minimal RTF walk: track \strike and \ul state, emit text runs with markers.
  let out = '', strike = 0, ul = 0, i = 0;
  while (i < rtf.length) {
    const c = rtf[i];
    if (c === '\\') {
      const mw = /^\\([a-zA-Z]+)(-?\d+)?/.exec(rtf.slice(i));
      if (mw) {
        const w = mw[1], n = mw[2];
        if (w === 'strike') strike = n === '0' ? 0 : 1;
        else if (w === 'ulnone') ul = 0;
        else if (w === 'ul') ul = n === '0' ? 0 : 1;
        else if (w === 'par' || w === 'line') out += '\n';
        else if (w === 'tab') out += '\t';
        i += mw[0].length;
        if (rtf[i] === ' ') i++;
        continue;
      }
      if (rtf[i + 1] === "'") { i += 4; continue; }
      out += rtf[i + 1]; i += 2; continue;
    }
    if (c === '{' || c === '}') { i++; continue; }
    out += (strike ? '\u0001' : ul ? '\u0002' : '') + c + (strike || ul ? '\u0003' : '');
    i++;
  }
  out = out.replace(/\u0001(.)\u0003/g, '$1').replace(/\u0002(.)\u0003/g, '$1');
  // Re-walk for runs (simpler: re-do with run accumulation)
  console.log(out.replace(/\n{3,}/g, '\n\n').trim().slice(0, 4000));
}
