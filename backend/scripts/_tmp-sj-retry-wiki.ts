import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';

async function download(name: string, url: string, ext: string) {
  console.log(`Downloading: ${name}`);
  await new Promise(r => setTimeout(r, 3000));
  const resp = await fetch(url, {
    headers: {
      'User-Agent': 'EmpoweredVote/1.0 (civic data app; contact@empowered.vote)',
    }
  });
  console.log(`  Status: ${resp.status}`);
  if (resp.status === 200) {
    const buf = Buffer.from(await resp.arrayBuffer());
    const outFile = path.join(TMP_DIR, `sj-wiki-${name}.${ext}`);
    fs.writeFileSync(outFile, buf);
    console.log(`  Size: ${buf.length} → ${outFile}`);
  }
}

async function main() {
  await download('D8-Candelas', 'https://upload.wikimedia.org/wikipedia/commons/1/15/Domingo_Candelas%2C_San_Jos%C3%A9_City_Councilman.png', 'png');
  await download('D5-Ortiz', 'https://upload.wikimedia.org/wikipedia/commons/9/96/Peter_Ortiz%2C_San_Jos%C3%A9_City_Councilman.png', 'png');
  await download('Mayor-Mahan', 'https://upload.wikimedia.org/wikipedia/commons/a/ae/Matt_Mahan_portrait_2025.jpg', 'jpg');
}

main().catch(console.error);
