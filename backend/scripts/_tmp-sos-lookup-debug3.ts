// Debug the SoS form POST more carefully
const SOS_URL = 'https://campaignfinance.in.gov/PublicSite/SearchPages/CandidateSearch.aspx';

const getRes = await fetch(SOS_URL, { headers: { 'User-Agent': 'EmpoweredVote-TM/1.0' } });
const html = await getRes.text();
const cookie = getRes.headers.get('set-cookie')?.split(',').map(c => c.split(';')[0]).join('; ') ?? '';
const viewstate = html.match(/name="__VIEWSTATE"[^>]+value="([^"]+)"/)?.[1] ?? '';
const eventval = html.match(/name="__EVENTVALIDATION"[^>]+value="([^"]+)"/)?.[1] ?? '';
const toolkitField = html.match(/name="_ctl0_ToolkitScriptManager1_HiddenField"[^>]*value="([^"]*)"/)?.[1] ?? '';

console.log('Cookie:', cookie.slice(0, 100));
console.log('VS len:', viewstate.length, 'EV len:', eventval.length);
console.log('Toolkit:', toolkitField.slice(0, 50));

// Check for hidden fields we might be missing
const hiddenFields = html.match(/<input[^>]+type="hidden"[^>]*>/gi) || [];
console.log('\nAll hidden fields:');
for (const f of hiddenFields) {
  const name = f.match(/name="([^"]+)"/)?.[1];
  const value = f.match(/value="([^"]{0,50})"/)?.[1];
  if (name && !name.includes('VIEWSTATE') && !name.includes('EVENTVALIDATION')) {
    console.log(`  ${name} = "${value}"`);
  }
}

// Also check what radio buttons look like
console.log('\nRadio button defaults:');
const radios = html.match(/<input[^>]+type="radio"[^>]*>/gi) || [];
for (const r of radios) {
  const name = r.match(/name="([^"]+)"/)?.[1];
  const value = r.match(/value="([^"]+)"/)?.[1];
  const checked = r.includes('checked');
  if (checked) console.log(`  ${name} = ${value} (CHECKED)`);
}

// Try POST with "Abbott" and show full error section
const formData = new URLSearchParams({
  '_ctl0_ToolkitScriptManager1_HiddenField': toolkitField,
  '__EVENTTARGET': '',
  '__EVENTARGUMENT': '',
  '__VIEWSTATE': viewstate,
  '__VIEWSTATEGENERATOR': '4045FD78',
  '__SCROLLPOSITIONX': '0',
  '__SCROLLPOSITIONY': '0',
  '__EVENTVALIDATION': eventval,
  '_ctl0:Content:ucCommitteeControl:txtCandidateLastName': 'Abbott',
  '_ctl0:Content:ucCommitteeControl:rblCandidateLastNameSearchType': '0',
  '_ctl0:Content:ucCommitteeControl:txtCandidateFirstName': '',
  '_ctl0:Content:ucCommitteeControl:rblCandidateFirstNameSearchType': '0',
  '_ctl0:Content:ucCommitteeControl:ddlCandidateOffice': '-1',
  '_ctl0:Content:ucCommitteeControl:ucCandidateParty:ucddlParty': '-1',
  '_ctl0:Content:ucCommitteeControl:txtCandidateDistrictNumber': '',
  '_ctl0:Content:ucCommitteeControl:rblCandidateExploratory': '2',
  '_ctl0:Content:ucCommitteeControl:rblCandidateStatus': '4',
  '_ctl0:Content:btnSearch': 'Search',
});

const postRes = await fetch(SOS_URL, {
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

const postHtml = await postRes.text();
console.log('\nPOST status:', postRes.status, 'len:', postHtml.length);

// Find error section
const errIdx = postHtml.indexOf('frmError');
if (errIdx !== -1) {
  const errSection = postHtml.slice(errIdx, errIdx + 500);
  const stripped = errSection.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
  console.log('Error section:', stripped.slice(0, 300));
}

// Also find any validation message
const valIdx = postHtml.indexOf('Please correct');
if (valIdx !== -1) {
  const valSection = postHtml.slice(valIdx, valIdx + 500);
  const stripped = valSection.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
  console.log('Validation:', stripped.slice(0, 300));
}

// Check results count
const countMatch = postHtml.match(/(\d+)\s+matching\s+record/i);
console.log('Count match:', countMatch?.[0]);
