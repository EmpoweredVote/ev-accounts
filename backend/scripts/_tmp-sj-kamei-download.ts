import 'dotenv/config';
import * as fs from 'fs';
const TMP = process.env.TEMP || 'C:/Windows/Temp';

const resp = await fetch('https://www.sanjoseca.gov/home/showpublishedimage/18393/638145599495300000', {
  headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-1/the-team/rosemary-kamei',
  }
});
console.log('Status:', resp.status, 'Type:', resp.headers.get('content-type'), 'Size header:', resp.headers.get('content-length'));
const buf = Buffer.from(await resp.arrayBuffer());
console.log('Downloaded:', buf.length, 'bytes');
fs.writeFileSync(`${TMP}/sj-kamei-18393.jpg`, buf);
console.log('Saved to:', `${TMP}/sj-kamei-18393.jpg`);
