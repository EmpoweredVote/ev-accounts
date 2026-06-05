// Inspect the CandidateSearch form structure more carefully
const candidateUrl = 'https://campaignfinance.in.gov/PublicSite/SearchPages/CandidateSearch.aspx';
const res = await fetch(candidateUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
const html = await res.text();
const cookies = res.headers.get('set-cookie') ?? '';

// Find all input fields
const inputs = html.match(/<input[^>]+>/gi) || [];
console.log('All inputs:');
for (const i of inputs) {
  const name = i.match(/name="([^"]+)"/)?.[1];
  const type = i.match(/type="([^"]+)"/)?.[1] ?? 'text';
  const value = i.match(/value="([^"]{0,30})"/)?.[1] ?? '';
  if (name) console.log(`  name="${name}" type="${type}" value="${value}"`);
}

// Find all select elements
const selects = html.match(/<select[^>]*name="([^"]+)"[^>]*>/gi) || [];
console.log('\nSelect elements:');
for (const s of selects) {
  const name = s.match(/name="([^"]+)"/)?.[1];
  console.log(`  name="${name}"`);
}

// Find the main content div
const contentIdx = html.indexOf('id="_ctl0_Content');
const content = html.slice(contentIdx, contentIdx + 3000);
const stripped = content.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 1000);
console.log('\nContent area:', stripped);
