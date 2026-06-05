// Test with Adams (we know this works) and check the radio values
const SOS_URL = 'https://campaignfinance.in.gov/PublicSite/SearchPages/CandidateSearch.aspx';

async function searchByLastName(lastName: string, status: string = '2'): Promise<string> {
  const getRes = await fetch(SOS_URL, { headers: { 'User-Agent': 'EmpoweredVote-TM/1.0' } });
  const html = await getRes.text();
  const cookie = getRes.headers.get('set-cookie')?.split(',').map(c => c.split(';')[0]).join('; ') ?? '';
  const viewstate = html.match(/name="__VIEWSTATE"[^>]+value="([^"]+)"/)?.[1] ?? '';
  const eventval = html.match(/name="__EVENTVALIDATION"[^>]+value="([^"]+)"/)?.[1] ?? '';

  const formData = new URLSearchParams({
    '_ctl0_ToolkitScriptManager1_HiddenField': '',
    '__EVENTTARGET': '', '__EVENTARGUMENT': '',
    '__VIEWSTATE': viewstate, '__VIEWSTATEGENERATOR': '4045FD78',
    '__SCROLLPOSITIONX': '0', '__SCROLLPOSITIONY': '0',
    '__EVENTVALIDATION': eventval,
    '_ctl0:Content:ucCommitteeControl:txtCandidateLastName': lastName,
    '_ctl0:Content:ucCommitteeControl:rblCandidateLastNameSearchType': '1',  // contains
    '_ctl0:Content:ucCommitteeControl:txtCandidateFirstName': '',
    '_ctl0:Content:ucCommitteeControl:rblCandidateFirstNameSearchType': '1',
    '_ctl0:Content:ucCommitteeControl:ddlCandidateOffice': '-1',
    '_ctl0:Content:ucCommitteeControl:ucCandidateParty:ucddlParty': '-1',
    '_ctl0:Content:ucCommitteeControl:txtCandidateDistrictNumber': '',
    '_ctl0:Content:ucCommitteeControl:rblCandidateExploratory': '2',  // all
    '_ctl0:Content:ucCommitteeControl:rblCandidateStatus': status,
    '_ctl0:Content:btnSearch': 'Search',
  });

  const res = await fetch(SOS_URL, {
    method: 'POST',
    headers: {
      'User-Agent': 'EmpoweredVote-TM/1.0',
      'Content-Type': 'application/x-www-form-urlencoded',
      'Referer': SOS_URL,
      'Cookie': cookie,
    },
    body: formData.toString(),
    signal: AbortSignal.timeout(15000),
  });
  const postHtml = await res.text();
  const countMatch = postHtml.match(/(\d+)\s+matching\s+record/i);
  const gridStart = postHtml.indexOf('dgdSearchResults');
  if (gridStart === -1) {
    const errIdx = postHtml.indexOf('frmError');
    const errSection = errIdx !== -1 ? postHtml.slice(errIdx, errIdx + 200).replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim() : 'no grid, no error';
    return `NO GRID: ${errSection}`;
  }
  const grid = postHtml.slice(gridStart, gridStart + 3000).replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
  return `${countMatch?.[0] ?? '?'}: ${grid.slice(0, 300)}`;
}

console.log('=== Adams (status=2 = active) ===');
console.log(await searchByLastName('Adams', '2'));
await new Promise(r => setTimeout(r, 300));

console.log('\n=== Adams (status=4 = all) ===');
console.log(await searchByLastName('Adams', '4'));
await new Promise(r => setTimeout(r, 300));

console.log('\n=== Abbott (status=2) ===');
console.log(await searchByLastName('Abbott', '2'));
await new Promise(r => setTimeout(r, 300));

console.log('\n=== Abbott (status=4) ===');
console.log(await searchByLastName('Abbott', '4'));
await new Promise(r => setTimeout(r, 300));

// Try "1" = active filed
console.log('\n=== Abbott (status=1) ===');
console.log(await searchByLastName('Abbott', '1'));
