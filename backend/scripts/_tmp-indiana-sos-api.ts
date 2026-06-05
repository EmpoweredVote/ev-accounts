// Check the Indiana SoS campaign finance portal for committee lookup
// The Indiana SoS portal is at: https://campaignfinance.in.gov
// They have committee details at: https://campaignfinance.in.gov/PublicSite/api/...

const tests = [
  // Try common API patterns for the IN SoS portal
  'https://campaignfinance.in.gov/PublicSite/api/Committees/7925',
  'https://campaignfinance.in.gov/PublicSite/api/Filers/7925',
  'https://campaignfinance.in.gov/PublicSite/Committees/7925',
  // OpenElections Indiana data
  'https://raw.githubusercontent.com/openelections/openelections-data-in/master/2024/README.md',
];

for (const url of tests) {
  try {
    const res = await fetch(url, {
      headers: { 'User-Agent': 'EmpoweredVote-TM/1.0', 'Accept': 'application/json' },
      signal: AbortSignal.timeout(8000)
    });
    const ct = res.headers.get('content-type') ?? '';
    console.log(`${url} → ${res.status} | ${ct}`);
    if (res.ok) {
      const text = await res.text();
      console.log('  Snippet:', text.slice(0, 400));
    }
  } catch (e) {
    console.log(`${url} → ERROR: ${(e as Error).message}`);
  }
}

// Also check if IN SoS has bulk committee type data
console.log('\n--- Checking IN SoS committee lookup ---');
// FileNumber 7925 = Alex Burton for Indiana
const sosTests = [
  'https://campaignfinance.in.gov/PublicSite/api/1/filers/7925',
  'https://campaignfinance.in.gov/PublicSite/api/filers?filenumber=7925',
  'https://campaignfinance.in.gov/api/Filers/GetFilerInfo?fileNumber=7925',
];

for (const url of sosTests) {
  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json, text/html, */*',
        'Referer': 'https://campaignfinance.in.gov/',
      },
      signal: AbortSignal.timeout(8000)
    });
    const ct = res.headers.get('content-type') ?? '';
    console.log(`${url} → ${res.status} | ${ct}`);
    if (res.ok) {
      const text = await res.text();
      if (ct.includes('json')) {
        console.log('  JSON:', text.slice(0, 500));
      } else {
        console.log('  Length:', text.length, '| Snippet:', text.slice(0, 200));
      }
    }
  } catch (e) {
    console.log(`${url} → ERROR: ${(e as Error).message}`);
  }
}
