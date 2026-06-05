import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';
const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Referer': 'https://www.sjdistrict3.org/',
};

const resp = await fetch('https://www.sjdistrict3.org/our-team', { headers: HEADERS });
console.log('Status:', resp.status, resp.url);
const html = await resp.text();
const re = /https:\/\/images\.squarespace-cdn\.com\/content\/v1\/68dc1d398d83da7d0336165b\/([^\s"'<>?]+\.(jpg|jpeg|png|webp))/gi;
const imgs = new Set<string>();
let m;
while ((m = re.exec(html)) !== null) imgs.add(m[0].split('?')[0]);
console.log('\nImages found:');
Array.from(imgs).forEach(u => {
  const short = u.replace('https://images.squarespace-cdn.com/content/v1/68dc1d398d83da7d0336165b/', '');
  if (!/logo|banner|favicon/i.test(short)) console.log(' ', short);
});

// Also check /d3-office
const resp2 = await fetch('https://www.sjdistrict3.org/d3-office', { headers: HEADERS });
const html2 = await resp2.text();
const imgs2 = new Set<string>();
while ((m = re.exec(html2)) !== null) imgs2.add(m[0].split('?')[0]);
console.log('\nD3 /d3-office images:');
Array.from(imgs2).forEach(u => {
  const short = u.replace('https://images.squarespace-cdn.com/content/v1/68dc1d398d83da7d0336165b/', '');
  if (!/logo|banner|favicon/i.test(short)) console.log(' ', short);
});

// Download the landing image to see actual content
console.log('\nDownloading landing image at full res:');
const landingResp = await fetch(
  'https://images.squarespace-cdn.com/content/v1/68dc1d398d83da7d0336165b/265abb99-2103-4102-83ed-303e5b4034e3/Website+Landing+Image.png?format=2500w',
  { headers: HEADERS }
);
console.log('Status:', landingResp.status);
const buf = Buffer.from(await landingResp.arrayBuffer());
const outFile = path.join(TMP_DIR, 'sj-tordillos-landing-full.webp');
fs.writeFileSync(outFile, buf);
console.log(`${buf.length} bytes → ${outFile}`);
