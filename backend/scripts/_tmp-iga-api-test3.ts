// The IGA has a public documented REST API: https://iga.in.gov/api
// Try different base domains and paths

const tests = [
  // Official IGA REST API (documented at developers.iga.in.gov or similar)
  'https://iga.in.gov/api/2025/legislators/senate',
  'https://iga.in.gov/api/2025/legislators/house',
  'https://iga.in.gov/api/2025/senators/',
  // OpenStates might have Indiana data
  'https://v3.openstates.org/people?jurisdiction=in&chamber=upper&per_page=10',
  // LegiScan API
  'https://api.legiscan.com/?op=getPersonList&state=IN',
];

for (const url of tests) {
  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'EmpoweredVote-TM/1.0',
        'Accept': 'application/json',
      },
      signal: AbortSignal.timeout(8000)
    });
    const ct = res.headers.get('content-type') ?? '';
    console.log(`${url} → ${res.status} | ${ct}`);
    if (res.ok && ct.includes('json')) {
      const text = await res.text();
      console.log('  JSON:', text.slice(0, 400));
    } else if (res.ok) {
      const text = await res.text();
      console.log('  Text len:', text.length, '| First 100:', text.slice(0, 100));
    }
  } catch (e) {
    console.log(`${url} → ERROR: ${(e as Error).message}`);
  }
}
