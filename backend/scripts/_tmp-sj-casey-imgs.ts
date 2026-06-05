import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';

async function dl(name: string, url: string) {
  const resp = await fetch(url, { headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Referer': 'https://www.sjdistrict10.org/',
  }});
  console.log(`${name}: ${resp.status}, ${resp.headers.get('content-type')}`);
  if (resp.status !== 200) return;
  const buf = Buffer.from(await resp.arrayBuffer());
  const ext = (resp.headers.get('content-type') || '').includes('png') ? 'png' : 'webp';
  const outFile = path.join(TMP_DIR, `sj-casey-${name}.${ext}`);
  fs.writeFileSync(outFile, buf);
  console.log(`  ${buf.length} bytes → ${outFile}`);
}

// Get all D10 Casey images from /meet-our-team
const resp = await fetch('https://www.sjdistrict10.org/meet-our-team', {
  headers: { 'User-Agent': 'Mozilla/5.0', 'Referer': 'https://www.sjdistrict10.org/' }
});
const html = await resp.text();
const re = /https:\/\/images\.squarespace-cdn\.com\/content\/v1\/67d36df71d3cca0e7ebe4c0e\/([^\s"'<>?]+\.(jpg|jpeg|png))/gi;
let m;
const imgs = new Set<string>();
while ((m = re.exec(html)) !== null) imgs.add(m[1]);
console.log('D10 Casey /meet-our-team images:');
Array.from(imgs).forEach(u => console.log(' ', u));

// Download the ones that look like people
for (const img of Array.from(imgs).slice(0, 5)) {
  const url = `https://images.squarespace-cdn.com/content/v1/67d36df71d3cca0e7ebe4c0e/${img}?format=2500w`;
  await dl(img.replace(/[^a-z0-9]/gi, '-').substring(0, 30), url);
  await new Promise(r => setTimeout(r, 200));
}
