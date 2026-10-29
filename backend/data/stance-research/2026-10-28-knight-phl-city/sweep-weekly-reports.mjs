import { writeFileSync, mkdirSync } from 'node:fs';

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36';
const OUT = 'C:/ev-accounts-knight-stances/backend/data/stance-research/2026-10-28-knight-phl-city/corpus';
mkdirSync(OUT, { recursive: true });

const posts = [];
for (let page = 1; page <= 12; page++) {
  const url = `https://phlcouncil.com/wp-json/wp/v2/posts?search=${encodeURIComponent('weekly report')}&per_page=100&page=${page}&_fields=id,date,slug,title,link,content`;
  const res = await fetch(url, { headers: { 'user-agent': UA } });
  if (!res.ok) { console.log(`page ${page}: HTTP ${res.status} — stopping`); break; }
  const rows = await res.json();
  if (!Array.isArray(rows) || rows.length === 0) { console.log(`page ${page}: empty — done`); break; }
  posts.push(...rows);
  console.log(`page ${page}: +${rows.length} (total ${posts.length})`);
  if (rows.length < 100) break;
}

// Keep only genuine weekly reports.
const weekly = posts.filter((p) => /weekly report/i.test(p.title?.rendered ?? ''));
console.log(`\nposts fetched: ${posts.length}  weekly reports: ${weekly.length}`);
if (weekly.length) {
  const dates = weekly.map((p) => p.date).sort();
  console.log(`date range: ${dates[0]} .. ${dates[dates.length - 1]}`);
}

const strip = (h) => (h ?? '')
  .replace(/<[^>]*>/g, ' ')
  .replace(/&#8217;|&#8216;/g, "'").replace(/&#8220;|&#8221;/g, '"')
  .replace(/&amp;/g, '&').replace(/&nbsp;|&#160;/g, ' ').replace(/&#8211;|&#8212;/g, '-')
  .replace(/\s+/g, ' ').trim();

const slim = weekly.map((p) => ({ id: p.id, date: p.date, link: p.link, title: strip(p.title?.rendered), text: strip(p.content?.rendered) }));
writeFileSync(`${OUT}/phlcouncil-weekly-reports.json`, JSON.stringify(slim, null, 1));
console.log(`wrote ${OUT}/phlcouncil-weekly-reports.json  (${slim.reduce((n, p) => n + p.text.length, 0)} chars of text)`);
