// Try IGA with special headers or different approaches
const tests = [
  // Try with Accept: application/json - some SPAs have an API mode
  { url: 'https://iga.in.gov/api/2025/legislators', extra: { 'Accept': 'application/json, text/plain, */*', 'X-Requested-With': 'XMLHttpRequest' }},
  // Try the actual app API that the SPA JS calls
  { url: 'https://iga.in.gov/api/2025/legislators?page=1&per_page=10', extra: { 'Accept': 'application/json' }},
  // Check if there's a data endpoint via common patterns
  { url: 'https://iga.in.gov/api/2025/legislators.json', extra: {}},
  { url: 'https://iga.in.gov/data/legislators/2025', extra: {}},
];

for (const { url, extra } of tests) {
  try {
    const res = await fetch(url, {
      headers: { 'User-Agent': 'Mozilla/5.0 EmpoweredVote-TM/1.0', ...extra },
      signal: AbortSignal.timeout(8000)
    });
    const ct = res.headers.get('content-type') ?? '';
    console.log(`${url} → ${res.status} | ${ct}`);
    if (res.ok) {
      const text = await res.text();
      if (text.length < 10000 && (ct.includes('json') || text.trim().startsWith('{'))) {
        console.log('  Data:', text.slice(0, 500));
      } else {
        console.log('  Length:', text.length);
      }
    }
  } catch (e) {
    console.log(`${url} → ERROR: ${(e as Error).message}`);
  }
}

// Try fetching the actual JS bundle that contains the app code
// First get the correct script URL
const spaRes = await fetch('https://iga.in.gov/', { headers: { 'User-Agent': 'Mozilla/5.0' }});
const spaHtml = await spaRes.text();
console.log('\nSPA HTML:', spaHtml);
// It seems all paths return the same 691-byte shell - the actual JS must be loaded separately
// Let's see what's at the root
const rootRes = await fetch('https://iga.in.gov/', { headers: { 'User-Agent': 'Mozilla/5.0 Chrome/120.0' }});
console.log('\nRoot response headers:');
for (const [k, v] of rootRes.headers.entries()) {
  console.log(`  ${k}: ${v}`);
}
