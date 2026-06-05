// The IGA has a documented public API at https://iga.in.gov/api
// Let's try with different Accept headers and check the network requests the SPA would make

// Based on Indiana General Assembly, their API is typically at a separate domain
const candidates = [
  'https://api.iga.in.gov/2025/legislators/',
  'https://iga.in.gov/api/2025/legislators',
  // Try with CORS-aware headers like a browser would send
];

// Actually let's check - the page says "Indiana General Assembly" API docs mention igapi.in.gov
const igaApis = [
  'https://igapi.in.gov/api/2025/legislators',
  'https://igapi.in.gov/api/2025/legislators/senate',
  'https://igapi.in.gov/api/2025/legislators/house',
  'https://igapi.in.gov/2025/legislators',
];

for (const url of igaApis) {
  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json',
        'Referer': 'https://iga.in.gov/',
        'Origin': 'https://iga.in.gov',
      },
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
