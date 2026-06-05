// Test IGA API endpoints
const headers = { 'User-Agent': 'EmpoweredVote-TM/1.0', 'Accept': 'application/json' };

// Try the IGA API
const apis = [
  'https://iga.in.gov/api/2025/legislators',
  'https://api.iga.in.gov/2025/legislators',
  'https://iga.in.gov/api/2025/senators',
  'https://iga.in.gov/api/2025/representatives',
  'https://iga.in.gov/api/2024/legislators',
];

for (const url of apis) {
  try {
    const res = await fetch(url, { headers, signal: AbortSignal.timeout(8000) });
    console.log(`${url} → ${res.status} ${res.statusText}`);
    if (res.ok) {
      const text = await res.text();
      console.log('  Response snippet:', text.slice(0, 200));
    }
  } catch (e) {
    console.log(`${url} → ERROR: ${(e as Error).message}`);
  }
}
