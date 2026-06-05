// Use the correct field names from the CandidateSearch form
const candidateUrl = 'https://campaignfinance.in.gov/PublicSite/SearchPages/CandidateSearch.aspx';

// Step 1: GET to get cookies + viewstate
const getRes = await fetch(candidateUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
const html = await getRes.text();
const cookieHeader = getRes.headers.get('set-cookie')?.split(',').map(c => c.split(';')[0]).join('; ') ?? '';

// Extract form fields using more flexible regex
const viewstate = html.match(/id="__VIEWSTATE"\s+value="([^"]+)"/)?.[1]
  ?? html.match(/name="__VIEWSTATE"[^>]+value="([^"]+)"/)?.[1]
  ?? '';
const eventval = html.match(/id="__EVENTVALIDATION"\s+value="([^"]+)"/)?.[1]
  ?? html.match(/name="__EVENTVALIDATION"[^>]+value="([^"]+)"/)?.[1]
  ?? '';
const gen = html.match(/id="__VIEWSTATEGENERATOR"\s+value="([^"]+)"/)?.[1] ?? '4045FD78';
const toolkit = html.match(/name="_ctl0_ToolkitScriptManager1_HiddenField"[^>]*value="([^"]*)"/)?.[1] ?? '';

console.log('VS len:', viewstate.length, '| EV len:', eventval.length, '| Gen:', gen);

// POST with correct field names
const formData = new URLSearchParams({
  '_ctl0_ToolkitScriptManager1_HiddenField': toolkit,
  '__EVENTTARGET': '',
  '__EVENTARGUMENT': '',
  '__VIEWSTATE': viewstate,
  '__VIEWSTATEGENERATOR': gen,
  '__SCROLLPOSITIONX': '0',
  '__SCROLLPOSITIONY': '0',
  '__EVENTVALIDATION': eventval,
  '_ctl0:Content:ucCommitteeControl:txtCandidateLastName': 'Burton',
  '_ctl0:Content:ucCommitteeControl:rblCandidateLastNameSearchType': '0',  // begins with
  '_ctl0:Content:ucCommitteeControl:txtCandidateFirstName': 'Alexander',
  '_ctl0:Content:ucCommitteeControl:rblCandidateFirstNameSearchType': '0',
  '_ctl0:Content:ucCommitteeControl:ddlCandidateOffice': '-1',
  '_ctl0:Content:ucCommitteeControl:ucCandidateParty:ucddlParty': '-1',
  '_ctl0:Content:ucCommitteeControl:txtCandidateDistrictNumber': '',
  '_ctl0:Content:ucCommitteeControl:rblCandidateExploratory': '1',  // no
  '_ctl0:Content:ucCommitteeControl:rblCandidateStatus': '1',  // active
  '_ctl0:Content:btnSearch': 'Search',
});

const postRes = await fetch(candidateUrl, {
  method: 'POST',
  headers: {
    'User-Agent': 'Mozilla/5.0',
    'Content-Type': 'application/x-www-form-urlencoded',
    'Referer': candidateUrl,
    'Cookie': cookieHeader,
  },
  body: formData.toString(),
  signal: AbortSignal.timeout(15000),
});

const postHtml = await postRes.text();
console.log('\nSearch result:', postRes.status, '| Length:', postHtml.length);

// Look at the results section
const resultsIdx = postHtml.indexOf('pnlResults') !== -1 ? postHtml.indexOf('pnlResults') :
                   postHtml.indexOf('GridView') !== -1 ? postHtml.indexOf('GridView') :
                   postHtml.indexOf('DataGrid') !== -1 ? postHtml.indexOf('DataGrid') : -1;

if (resultsIdx !== -1) {
  const resultsSection = postHtml.slice(resultsIdx, resultsIdx + 5000);
  const stripped = resultsSection.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
  console.log('Results:', stripped.slice(0, 2000));
} else {
  // Try finding all tr elements with data
  const trs = postHtml.match(/<tr[^>]*>[\s\S]{20,500}?<\/tr>/gi) || [];
  const dataTrs = trs.filter(tr => {
    const stripped = tr.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
    return stripped.length > 20 && !stripped.includes('navMenu') && stripped.match(/[A-Z][a-z]/);
  });
  console.log('Data rows:', dataTrs.length);
  for (const tr of dataTrs.slice(0, 15)) {
    const stripped = tr.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
    if (stripped.length < 500) console.log('  ROW:', stripped);
  }
}
