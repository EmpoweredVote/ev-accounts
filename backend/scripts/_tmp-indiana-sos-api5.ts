// Check the PoliticalRaceSearch and try to get committee detail for a specific FileNumber
// The Indiana SoS committee detail page should show office type

// Try different committee detail URL patterns
const fileNum = '7925'; // Alex Burton for Indiana

const detailUrls = [
  `https://campaignfinance.in.gov/PublicSite/SearchPages/CommitteeDetail.aspx?FilingID=${fileNum}`,
  `https://campaignfinance.in.gov/PublicSite/SearchPages/CommitteeDetail.aspx?FileNumber=${fileNum}`,
  `https://campaignfinance.in.gov/PublicSite/SearchPages/CommitteeDetail.aspx?ID=${fileNum}`,
  `https://campaignfinance.in.gov/PublicSite/Committee/CommitteeDetail.aspx?FilingID=${fileNum}`,
  `https://campaignfinance.in.gov/PublicSite/Filer/FilerDetail.aspx?FilingID=${fileNum}`,
  `https://campaignfinance.in.gov/PublicSite/Filer/FilerDetail.aspx?FilerID=${fileNum}`,
];

for (const url of detailUrls) {
  try {
    const res = await fetch(url, {
      headers: { 'User-Agent': 'Mozilla/5.0' },
      signal: AbortSignal.timeout(5000)
    });
    const ct = res.headers.get('content-type') ?? '';
    const loc = res.headers.get('location') ?? '';
    const text = res.ok ? (await res.text()).slice(0, 800) : '';
    console.log(`${url.split('/').slice(-1)[0]} → ${res.status} | ${loc || ct.split(';')[0]}`);
    if (res.ok && text.length > 100) {
      // Look for office type fields
      const relevant = text.match(/(?:Office|Position|Chamber|Type|Race)[^<]{0,100}/gi) || [];
      console.log('  Relevant:', relevant.slice(0, 5).join(' | '));
    }
  } catch (e) {
    console.log(`→ ERROR: ${(e as Error).message}`);
  }
}

// Let's also check the PoliticalRaceSearch page
console.log('\n--- PoliticalRaceSearch ---');
const raceRes = await fetch('https://campaignfinance.in.gov/PublicSite/SearchPages/PoliticalRaceSearch.aspx', {
  headers: { 'User-Agent': 'Mozilla/5.0' }
});
const raceHtml = await raceRes.text();
console.log('Status:', raceRes.status, '| Length:', raceHtml.length);
// Find any dropdown options that might show office types
const selectMatches = raceHtml.match(/<select[^>]*>[\s\S]{0,2000}?<\/select>/gi) || [];
for (const s of selectMatches.slice(0, 3)) {
  console.log('SELECT:', s.slice(0, 500));
}
