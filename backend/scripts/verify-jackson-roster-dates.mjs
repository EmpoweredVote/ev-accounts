import * as fs from 'fs';
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

/**
 * 🔴 THE MIKE LEE RULE. A page that carries the right NAME is not a page about the right
 * PERSON. Each row must assert, from the page's own text: the city, the office, and the
 * ward. A page that fails any of those is rejected, not reconciled.
 */
const rows = [
  ['Mayor', 'John Horhn', 'https://ballotpedia.org/John_Horhn', null],
  ['Ward 1', 'Ashby Foote', 'https://ballotpedia.org/Ashby_Foote', 1],
  ['Ward 2', 'Montyne Clay', 'https://ballotpedia.org/Montyne_Clay', 2],
  ['Ward 3', 'Kenneth Stokes', 'https://ballotpedia.org/Kenneth_Stokes', 3],
  ['Ward 4', 'Brian Grizzell', 'https://ballotpedia.org/Brian_Grizzell', 4],
  ['Ward 5', 'Vernon Hartley', 'https://ballotpedia.org/Vernon_Hartley', 5],
  ['Ward 6', 'Lashia Brown-Thomas', 'https://ballotpedia.org/Lashia_Brown-Thomas', 6],
  ['Ward 7', 'Kevin Parkinson', 'https://ballotpedia.org/Kevin_Parkinson', 7],
];

for (const [seat, name, url, ward] of rows) {
  const r = await fetch(url, { headers: { 'User-Agent': UA }, redirect: 'follow' });
  const b = await r.text();
  let t = b.replace(/<(script|style|noscript)[^>]*>[\s\S]*?<\/\1>/gi, ' ').replace(/<[^>]+>/g, '\n');
  t = t.replace(/&#\d+;/g, "'").replace(/&amp;/g, '&').replace(/&nbsp;/g, ' ');
  const flat = t.replace(/\s+/g, ' ');

  const saysJackson = /Jackson,? Mississippi|City of Jackson/i.test(flat);
  const saysOffice = ward === null
    ? /Mayor of Jackson/i.test(flat)
    : new RegExp(`Jackson City Council[^.]{0,40}Ward ${ward}\\b|Ward ${ward}[^.]{0,40}Jackson City Council`, 'i').test(flat);
  const assumed = flat.match(/assumed office (?:on |in )?([A-Z][a-z]+ \d{1,2}, \d{4}|\d{4})/i);
  const appointed = /was appointed/i.test(flat);

  console.log(
    `${seat.padEnd(7)} ${name.padEnd(20)} ` +
    `${saysJackson ? 'city✅' : 'city🔴'} ${saysOffice ? 'office✅' : 'office🔴'} ` +
    `assumed=${(assumed ? assumed[1] : 'NONE').padEnd(18)} ${appointed ? '⚠ mentions "appointed"' : ''}`,
  );
}
