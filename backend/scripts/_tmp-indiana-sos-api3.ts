// Look at the Indiana SoS ASMX/ASPX endpoints for committee details
const base = 'https://campaignfinance.in.gov/PublicSite';

const res = await fetch(`${base}/`, {
  headers: { 'User-Agent': 'Mozilla/5.0' },
  signal: AbortSignal.timeout(10000)
});
const html = await res.text();

// Find links and form actions in the HTML
const links = html.match(/href="([^"]+)"/g)?.map(h => h.replace(/href="/, '').replace(/"$/, '')) ?? [];
const actions = html.match(/action="([^"]+)"/g)?.map(a => a.replace(/action="/, '').replace(/"$/, '')) ?? [];

console.log('Links on main page:');
for (const l of [...new Set(links)].filter(l => !l.startsWith('#') && !l.includes('javascript')).slice(0, 30)) {
  console.log(`  ${l}`);
}
console.log('\nForm actions:', actions);

// Try the SearchCampaignFinance endpoint pattern
const searchPaths = [
  `/SearchCampaignFinance.aspx`,
  `/Filer/FilerDetail.aspx?FilerID=7925`,
  `/Filer/Detail.aspx?ID=7925`,
  `/Committee/Detail.aspx?ID=7925`,
  `/PublicSite/SearchCampaignFinance.aspx`,
  `/Filer/CommitteeDetail.aspx?FileNumber=7925`,
];

for (const path of searchPaths) {
  try {
    const r = await fetch(`https://campaignfinance.in.gov${path}`, {
      headers: { 'User-Agent': 'Mozilla/5.0' },
      signal: AbortSignal.timeout(5000)
    });
    console.log(`${path} → ${r.status} | ${r.headers.get('content-type')?.split(';')[0]}`);
    if (r.ok) {
      const t = await r.text();
      // Look for office type mentions
      if (t.includes('State Representative') || t.includes('State Senator') || t.includes('Office') || t.includes('Committee')) {
        const officeIdx = t.indexOf('Office');
        if (officeIdx !== -1) {
          console.log('  Office context:', t.slice(Math.max(0, officeIdx-50), officeIdx+200).replace(/\s+/g, ' '));
        }
      }
    }
  } catch (e) {
    console.log(`${path} → ERROR: ${(e as Error).message}`);
  }
}
