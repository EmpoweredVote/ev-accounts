// Try the documented IGA API - Indiana's General Assembly API
// Based on public documentation, the IGA API endpoint pattern is:
// GET https://iga.in.gov/api/{year}/legislators?Chamber=S|H
// But it might need an API key

// Let's also try the actual legislative data format from earlier IGA versions
const tests = [
  // IGA with api key header
  'https://iga.in.gov/api/2025/legislators?Chamber=S&per_page=100',
  // Check if there's an XML endpoint
  'https://iga.in.gov/2025/legislators.xml',
  // Try the raw data endpoint used by their app
  'https://iga.in.gov/api/2025/chamber/senate/legislators',
  'https://iga.in.gov/api/2025/chamber/house/legislators',
  // OpenStates API (free tier with key)
  'https://v3.openstates.org/people?jurisdiction=ocd-jurisdiction/country:us/state:in/government&chamber=upper&per_page=5',
];

for (const url of tests) {
  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json, text/html, */*',
      },
      signal: AbortSignal.timeout(10000)
    });
    const ct = res.headers.get('content-type') ?? '';
    console.log(`${url}\n  → ${res.status} | ${ct}`);
    if (res.ok) {
      const text = await res.text();
      if (ct.includes('json')) {
        console.log('  JSON:', text.slice(0, 500));
      } else {
        console.log('  Length:', text.length, '| Preview:', text.slice(0, 200).replace(/\n/g, ' '));
      }
    }
  } catch (e) {
    console.log(`${url}\n  → ERROR: ${(e as Error).message}`);
  }
}

// Also check the IGA API documentation page itself
console.log('\n--- Checking for IGA API docs ---');
const docRes = await fetch('https://iga.in.gov/api', {
  headers: { 'User-Agent': 'Mozilla/5.0', 'Accept': 'application/json' },
  signal: AbortSignal.timeout(8000)
}).catch(e => null);
if (docRes) {
  const ct = docRes.headers.get('content-type') ?? '';
  const text = await docRes.text();
  console.log(`/api → ${docRes.status} | ${ct} | length: ${text.length}`);
  if (text.length < 2000) console.log(text);
}
