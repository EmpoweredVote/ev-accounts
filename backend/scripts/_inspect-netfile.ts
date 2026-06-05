import 'dotenv/config';
import * as XLSX from 'xlsx';
import AdmZip from 'adm-zip';

const NETFILE_BASE_URL = 'https://public.netfile.com/pub2/Default.aspx';
const NETFILE_AGENCY = 'LACO';

function extractHiddenField(html: string, fieldName: string): string {
  const patterns = [
    new RegExp(`id="${fieldName}"[^>]*value="([^"]*)"`, 'i'),
    new RegExp(`name="${fieldName}"[^>]*value="([^"]*)"`, 'i'),
    new RegExp(`value="([^"]*)"[^>]*name="${fieldName}"`, 'i'),
  ];
  for (const pattern of patterns) {
    const match = html.match(pattern);
    if (match) return match[1] ?? '';
  }
  return '';
}

function extractCookies(response: Response): string {
  const h = response.headers.get('set-cookie');
  if (!h) return '';
  return h.split(/,(?=[^;]+=[^;]+;|[^;]+=)/).map(c => c.trim().split(';')[0]?.trim() ?? '').filter(Boolean).join('; ');
}

async function main() {
  const pageUrl = `${NETFILE_BASE_URL}?aid=${NETFILE_AGENCY}`;
  const year = 2024;

  const getResp = await fetch(pageUrl, { headers: { 'User-Agent': 'Mozilla/5.0 Chrome/120.0' } });
  const html = await getResp.text();
  const cookies = extractCookies(getResp);
  const viewState = extractHiddenField(html, '__VIEWSTATE');
  const viewStateGenerator = extractHiddenField(html, '__VIEWSTATEGENERATOR');
  const eventValidation = extractHiddenField(html, '__EVENTVALIDATION');

  const formBody = new URLSearchParams({
    __EVENTTARGET: 'ctl00$phBody$GetExcelAmend',
    __EVENTARGUMENT: '',
    __VIEWSTATE: viewState,
    __VIEWSTATEGENERATOR: viewStateGenerator,
    __EVENTVALIDATION: eventValidation,
    'ctl00$phBody$DateSelect': String(year),
  });

  const postResp = await fetch(pageUrl, {
    method: 'POST',
    headers: { 'User-Agent': 'Mozilla/5.0 Chrome/120.0', 'Content-Type': 'application/x-www-form-urlencoded', Referer: pageUrl, Cookie: cookies },
    body: formBody.toString(),
  });

  const contentType = postResp.headers.get('content-type') ?? '';
  const buf = Buffer.from(await postResp.arrayBuffer());
  console.log(`Response: ${contentType} ${(buf.length/1024/1024).toFixed(1)}MB`);

  let xlsxBuf = buf;
  if (contentType.includes('zip') || (buf[0] === 0x50 && buf[1] === 0x4b)) {
    const zip = new AdmZip(buf);
    const entry = zip.getEntries().find(e => e.entryName.toLowerCase().endsWith('.xlsx'));
    if (!entry) { console.error('No xlsx in zip'); return; }
    xlsxBuf = entry.getData();
  }

  const wb = XLSX.read(xlsxBuf, { type: 'buffer', cellDates: true });
  console.log(`Sheets: ${wb.SheetNames.join(', ')}`);

  const ws = wb.Sheets['A-Contributions'];
  if (!ws) { console.error('No A-Contributions sheet'); return; }

  const rows = XLSX.utils.sheet_to_json<Record<string, unknown>>(ws, { defval: '' });
  console.log(`Total rows: ${rows.length}`);

  if (rows[0]) {
    console.log(`\nColumns: ${Object.keys(rows[0]).join(' | ')}`);
  }

  // Show first 3 complete rows
  console.log('\n=== First 3 rows (all fields) ===');
  for (let i = 0; i < 3 && i < rows.length; i++) {
    console.log(`\nRow ${i+1}:`);
    for (const [k, v] of Object.entries(rows[i])) {
      if (v !== '') console.log(`  ${k}: ${v}`);
    }
  }

  // Show unique Filer_ID + Filer_NamL (first 20)
  const seen = new Set<string>();
  let count = 0;
  console.log('\n=== Sample Filer_ID + Filer_NamL (first 20 unique) ===');
  for (const row of rows) {
    const id = String(row['Filer_ID'] ?? '').trim();
    const namL = String(row['Filer_NamL'] ?? '').trim();
    const key = `${id}`;
    if (!seen.has(key)) {
      seen.add(key);
      console.log(`  ${id} | "${namL}"`);
      if (++count >= 20) break;
    }
  }

  // Search all fields for target names
  console.log('\n=== Search all fields for target names ===');
  const targets = ['solis', 'mitchell', 'horvath', 'hahn', 'barger', 'hochman', 'luna', 'prang'];
  for (const target of targets) {
    const hits: string[] = [];
    for (const row of rows) {
      for (const [k, v] of Object.entries(row)) {
        if (String(v).toLowerCase().includes(target)) {
          hits.push(`row[${k}]="${String(v).substring(0, 60)}" (Filer_ID=${row['Filer_ID']})`);
          if (hits.length >= 3) break;
        }
      }
      if (hits.length >= 3) break;
    }
    if (hits.length === 0) console.log(`  "${target}": NOT FOUND in any field`);
    else console.log(`  "${target}": FOUND — ${hits[0]}`);
  }
}

main().catch(console.error);
