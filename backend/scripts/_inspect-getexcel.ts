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
  for (const p of patterns) { const m = html.match(p); if (m) return m[1] ?? ''; }
  return '';
}
function extractCookies(r: Response): string {
  const h = r.headers.get('set-cookie');
  if (!h) return '';
  return h.split(/,(?=[^;]+=[^;]+;|[^;]+=)/).map(c => c.trim().split(';')[0]?.trim() ?? '').filter(Boolean).join('; ');
}

async function download(year: number, target: string): Promise<Buffer | null> {
  const pageUrl = `${NETFILE_BASE_URL}?aid=${NETFILE_AGENCY}`;
  const getResp = await fetch(pageUrl, { headers: { 'User-Agent': 'Mozilla/5.0 Chrome/120.0' } });
  const html = await getResp.text();
  const cookies = extractCookies(getResp);
  const body = new URLSearchParams({
    __EVENTTARGET: target, __EVENTARGUMENT: '',
    __VIEWSTATE: extractHiddenField(html, '__VIEWSTATE'),
    __VIEWSTATEGENERATOR: extractHiddenField(html, '__VIEWSTATEGENERATOR'),
    __EVENTVALIDATION: extractHiddenField(html, '__EVENTVALIDATION'),
    'ctl00$phBody$DateSelect': String(year),
  });
  const resp = await fetch(pageUrl, {
    method: 'POST',
    headers: { 'User-Agent': 'Mozilla/5.0 Chrome/120.0', 'Content-Type': 'application/x-www-form-urlencoded', Referer: pageUrl, Cookie: cookies },
    body: body.toString(),
  });
  const ct = resp.headers.get('content-type') ?? '';
  if (ct.includes('text/html')) return null;
  const buf = Buffer.from(await resp.arrayBuffer());
  if (buf.length < 1000) return null;
  if (ct.includes('zip') || (buf[0] === 0x50 && buf[1] === 0x4b)) {
    const zip = new AdmZip(buf);
    const entry = zip.getEntries().find(e => e.entryName.toLowerCase().endsWith('.xlsx'));
    if (!entry) return null;
    return entry.getData();
  }
  return buf;
}

async function analyze(xlsxBuf: Buffer, label: string) {
  const wb = XLSX.read(xlsxBuf, { type: 'buffer', cellDates: true });
  const ws = wb.Sheets['A-Contributions'];
  if (!ws) { console.log(`${label}: No A-Contributions sheet`); return; }
  const rows = XLSX.utils.sheet_to_json<Record<string, unknown>>(ws, { defval: '' });
  const schedA = rows.filter(r => r['Form_Type'] === 'A');
  
  // Count unique filers
  const filerMap = new Map<string, { name: string; count: number }>();
  for (const r of schedA) {
    const id = String(r['Filer_ID'] ?? '').trim();
    const nm = String(r['Filer_NamL'] ?? '').trim();
    if (!id) continue;
    const ex = filerMap.get(id);
    if (ex) ex.count++;
    else filerMap.set(id, { name: nm, count: 1 });
  }
  
  console.log(`\n${label}: ${schedA.length} Schedule A rows, ${filerMap.size} unique filers`);
  
  // Search for county supervisors
  const targets = ['solis', 'mitchell', 'horvath', 'hahn', 'barger', 'hochman', 'luna', 'prang'];
  const found: string[] = [];
  for (const [id, info] of filerMap) {
    for (const t of targets) {
      if (info.name.toLowerCase().includes(t)) found.push(`  ${id}: "${info.name}" (${info.count} rows)`);
    }
  }
  if (found.length) console.log('County official matches in Filer_NamL:\n' + found.join('\n'));
  else console.log('County officials: NOT FOUND as filers');
  
  // Print top 10 filers by contribution count
  const sorted = [...filerMap.entries()].sort((a,b) => b[1].count - a[1].count).slice(0, 10);
  console.log('Top 10 filers by row count:');
  for (const [id, info] of sorted) console.log(`  ${id}: "${info.name}" — ${info.count} rows`);
}

async function main() {
  // Try GetExcel (all) for 2024
  console.log('Downloading 2024 GetExcel (all filings)...');
  const buf2024All = await download(2024, 'ctl00$phBody$GetExcel');
  if (buf2024All) await analyze(buf2024All, '2024 GetExcel(all)');
  else console.log('2024 GetExcel failed');
  
  // Try 2022 with multiple approaches
  for (const year of [2022, 2020, 2021, 2023]) {
    await new Promise(r => setTimeout(r, 1500));
    console.log(`\nDownloading ${year} GetExcel...`);
    const buf = await download(year, 'ctl00$phBody$GetExcel');
    if (buf) { await analyze(buf, `${year} GetExcel`); break; }
    else {
      const buf2 = await download(year, 'ctl00$phBody$GetExcelAmend');
      if (buf2) { await analyze(buf2, `${year} GetExcelAmend`); break; }
      else console.log(`${year}: both methods failed`);
    }
  }
}
main().catch(console.error);
