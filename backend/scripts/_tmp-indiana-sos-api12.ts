// Extract results from the dgdSearchResults grid
const candidateUrl = 'https://campaignfinance.in.gov/PublicSite/SearchPages/CandidateSearch.aspx';

const getRes = await fetch(candidateUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
const html = await getRes.text();
const cookieHeader = getRes.headers.get('set-cookie')?.split(',').map(c => c.split(';')[0]).join('; ') ?? '';
const viewstate = html.match(/name="__VIEWSTATE"[^>]+value="([^"]+)"/)?.[1] ?? '';
const eventval = html.match(/name="__EVENTVALIDATION"[^>]+value="([^"]+)"/)?.[1] ?? '';

const formData = new URLSearchParams({
  '_ctl0_ToolkitScriptManager1_HiddenField': '',
  '__EVENTTARGET': '', '__EVENTARGUMENT': '',
  '__VIEWSTATE': viewstate, '__VIEWSTATEGENERATOR': '4045FD78',
  '__SCROLLPOSITIONX': '0', '__SCROLLPOSITIONY': '0',
  '__EVENTVALIDATION': eventval,
  '_ctl0:Content:ucCommitteeControl:txtCandidateLastName': 'Burton',
  '_ctl0:Content:ucCommitteeControl:rblCandidateLastNameSearchType': '1',
  '_ctl0:Content:ucCommitteeControl:txtCandidateFirstName': '',
  '_ctl0:Content:ucCommitteeControl:rblCandidateFirstNameSearchType': '0',
  '_ctl0:Content:ucCommitteeControl:ddlCandidateOffice': '-1',
  '_ctl0:Content:ucCommitteeControl:ucCandidateParty:ucddlParty': '-1',
  '_ctl0:Content:ucCommitteeControl:txtCandidateDistrictNumber': '',
  '_ctl0:Content:ucCommitteeControl:rblCandidateExploratory': '2',
  '_ctl0:Content:ucCommitteeControl:rblCandidateStatus': '4',
  '_ctl0:Content:btnSearch': 'Search',
});

const postRes = await fetch(candidateUrl, {
  method: 'POST',
  headers: { 'User-Agent': 'Mozilla/5.0', 'Content-Type': 'application/x-www-form-urlencoded', 'Referer': candidateUrl, 'Cookie': cookieHeader },
  body: formData.toString(),
  signal: AbortSignal.timeout(15000),
});

const postHtml = await postRes.text();

// Find the results grid
const gridStart = postHtml.indexOf('dgdSearchResults');
const gridSection = postHtml.slice(gridStart, gridStart + 8000);
const stripped = gridSection.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
console.log('Grid content:', stripped.slice(0, 3000));

// Also look for pnlSearchResults section
const panelStart = postHtml.indexOf('pnlSearchResults');
if (panelStart !== -1) {
  const panelSection = postHtml.slice(panelStart, panelStart + 6000);
  const ps = panelSection.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
  console.log('\nPanel content:', ps.slice(0, 2000));
}
