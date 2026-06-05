// Try the Indiana SoS campaign finance portal more broadly
// Their site at campaignfinance.in.gov likely uses a specific API pattern

const base = 'https://campaignfinance.in.gov';

// Fetch main page to understand structure
const homeRes = await fetch(`${base}/`, {
  headers: { 'User-Agent': 'Mozilla/5.0', 'Accept': 'text/html' },
  signal: AbortSignal.timeout(8000)
}).catch(e => { console.log('HOME ERROR:', e.message); return null; });

if (homeRes?.ok) {
  const html = await homeRes.text();
  console.log('Home status:', homeRes.status);
  console.log('Home length:', html.length);
  console.log('First 1000:', html.slice(0, 1000));
}

// Try PublicSite path (common IIS/.NET portal pattern)
const publicRes = await fetch(`${base}/PublicSite/`, {
  headers: { 'User-Agent': 'Mozilla/5.0' },
  signal: AbortSignal.timeout(8000)
}).catch(e => { console.log('PUBLIC ERROR:', e.message); return null; });

if (publicRes) {
  console.log('\n/PublicSite/ → ', publicRes.status, publicRes.headers.get('content-type'));
  const text = await publicRes.text();
  console.log('Length:', text.length, '| Snippet:', text.slice(0, 500));
}

// Check for API docs or swagger
const apiPaths = [
  '/api',
  '/api/docs',
  '/swagger',
  '/api/v1/filers',
  '/PublicSite/api/v1/filers',
];

for (const path of apiPaths) {
  try {
    const res = await fetch(`${base}${path}`, {
      headers: { 'User-Agent': 'Mozilla/5.0', 'Accept': 'application/json' },
      signal: AbortSignal.timeout(5000)
    });
    console.log(`${path} → ${res.status} | ${res.headers.get('content-type')}`);
  } catch (e) {
    console.log(`${path} → ERROR: ${(e as Error).message}`);
  }
}
