import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Referer': 'https://www.sanjoseca.gov/',
};

const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';

async function main() {
  // Fetch departments page
  const resp = await fetch('https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council', {
    headers: HEADERS
  });
  const html = await resp.text();

  // Extract all unique non-nav showpublishedimage IDs
  const regex = /showpublishedimage\/(\d+)\/(\d+)/g;
  let m;
  const seen = new Set<string>();
  const images: {id: string, ts: string, ctx: string}[] = [];
  while ((m = regex.exec(html)) !== null) {
    const key = `${m[1]}/${m[2]}`;
    if (seen.has(key)) continue;
    seen.add(key);
    const ctx = html.substring(Math.max(0, m.index - 300), Math.min(html.length, m.index + 400)).replace(/\s+/g, ' ');
    if (!/facebook|twitter|instagram|linkedin|youtube|nextdoor|IG Logo|Center for Digital|Digital Cities|logo$/i.test(ctx)) {
      images.push({ id: m[1], ts: m[2], ctx });
    }
  }

  console.log(`Found ${images.length} unique portrait images\n`);

  // Download each one
  for (const img of images) {
    const url = `https://www.sanjoseca.gov/home/showpublishedimage/${img.id}/${img.ts}`;
    const resp2 = await fetch(url, { headers: HEADERS });
    const type = resp2.headers.get('content-type') || '';
    const ext = type.includes('png') ? 'png' : 'jpg';

    if (resp2.status === 200) {
      const buf = Buffer.from(await resp2.arrayBuffer());
      const outFile = path.join(TMP_DIR, `sj-deptpage-${img.id}.${ext}`);
      fs.writeFileSync(outFile, buf);
      // Grep for name context
      const nameMatch = img.ctx.match(/(?:Mayor|Councilmember|District \d+[^<]*|strong>([^<]+)<\/strong)/);
      console.log(`${img.id}/${img.ts}: ${buf.length} bytes (${type})`);
      console.log(`  Context: ${img.ctx.substring(0, 300)}`);
      console.log(`  Saved: ${outFile}`);
    } else {
      console.log(`${img.id}/${img.ts}: FAILED ${resp2.status}`);
    }
    await new Promise(r => setTimeout(r, 200));
  }
}

main().catch(console.error);
