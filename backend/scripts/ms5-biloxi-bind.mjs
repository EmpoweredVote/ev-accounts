#!/usr/bin/env node
/**
 * Bind each Biloxi portrait to a PERSON using the page's own structure, because the two
 * cheap signals both fail here:
 *   - every alt attribute on the page is the empty string;
 *   - the filenames are wrong in three separate ways (a nickname, a misspelling, and a
 *     ward number that contradicts the roster, with TWO files claiming Ward 5).
 * So the only evidence left is what text the page places WITH each image.
 */
const URL_ = 'https://biloxi.ms.us/departments/city-council/';
const html = await (await fetch(URL_, { headers: { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' } })).text();

const re = /<img\b[^>]*src\s*=\s*"([^"]*2025\/06\/[^"]*)"[^>]*>/gi;
let m;
while ((m = re.exec(html))) {
  const at = m.index;
  const before = html.slice(Math.max(0, at - 1200), at);
  const after = html.slice(at + m[0].length, at + m[0].length + 1200);
  const txt = (s) => s.replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&#\d+;/g, "'").replace(/\s+/g, ' ').trim();
  console.log('='.repeat(78));
  console.log('FILE  ', m[1].split('/').pop());
  console.log('BEFORE …', txt(before).slice(-260));
  console.log('AFTER  …', txt(after).slice(0, 260));
  console.log('');
}
