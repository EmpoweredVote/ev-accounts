import 'dotenv/config';

const filenames = [
  'George Casey, San José City Councilman.png',
  'George Casey San Jose councilman.jpg',
  'George Casey San Jose.jpg',
];

for (const fname of filenames) {
  const url = `https://commons.wikimedia.org/w/api.php?action=query&titles=File:${encodeURIComponent(fname)}&prop=imageinfo&iiprop=url|extmetadata&format=json`;
  const resp = await fetch(url, { headers: { 'User-Agent': 'EmpoweredVote/1.0' } });
  const d: any = await resp.json();
  for (const p of Object.values(d?.query?.pages || {}) as any[]) {
    if (p.missing === undefined) {
      console.log(`Found: ${fname}`);
      console.log(`  URL: ${p.imageinfo?.[0]?.url}`);
      console.log(`  License: ${p.imageinfo?.[0]?.extmetadata?.LicenseShortName?.value}`);
    } else {
      console.log(`Missing: ${fname}`);
    }
  }
  await new Promise(r => setTimeout(r, 300));
}

// Also try search
const searchResp = await fetch('https://commons.wikimedia.org/w/api.php?action=query&list=search&srsearch=George+Casey+San+Jose+council&format=json&srnamespace=6&srlimit=5', {
  headers: { 'User-Agent': 'EmpoweredVote/1.0' }
});
const sd: any = await searchResp.json();
console.log('\nSearch results:');
sd?.query?.search?.forEach((r: any) => console.log(' ', r.title));
