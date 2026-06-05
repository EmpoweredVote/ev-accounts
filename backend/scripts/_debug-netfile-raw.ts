import 'dotenv/config';
import * as XLSX from 'xlsx';
import AdmZip from 'adm-zip';

const NETFILE_BASE_URL = 'https://public.netfile.com/pub2/Default.aspx';
const YEAR = 2024;

function extractHiddenField(html: string, fieldName: string): string {
  const escaped = fieldName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const p1 = new RegExp(`id="${escaped}"[^>]*value="([^"]*)"`, 'i');
  const p2 = new RegExp(`name="${escaped}"[^>]*value="([^"]*)"`, 'i');
  for (const p of [p1, p2]) { const m = html.match(p); if (m) return m[1] ?? ''; }
  return '';
}

function extractCookies(response: Response): string {
  const h = response.headers.get('set-cookie');
  if (!h) return '';
  return h.split(/,(?=[^;]+=[^;]+;|[^;]+=)/).map((c) => c.trim().split(';')[0]?.trim() ?? '').filter(Boolean).join('; ');
}

const pageUrl = `${NETFILE_BASE_URL}?aid=LACO`;
const getResp = await fetch(pageUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
const html = await getResp.text();
const cookies = extractCookies(getResp);

const formBody = new URLSearchParams({
  __EVENTTARGET: 'ctl00$phBody$GetExcel',
  __EVENTARGUMENT: '',
  __VIEWSTATE: extractHiddenField(html, '__VIEWSTATE'),
  __VIEWSTATEGENERATOR: extractHiddenField(html, '__VIEWSTATEGENERATOR'),
  __EVENTVALIDATION: extractHiddenField(html, '__EVENTVALIDATION'),
  'ctl00$phBody$DateSelect': String(YEAR),
});

const postResp = await fetch(pageUrl, {
  method: 'POST',
  headers: { 'User-Agent': 'Mozilla/5.0', 'Content-Type': 'application/x-www-form-urlencoded', Referer: pageUrl, Cookie: cookies },
  body: formBody.toString(),
});

const raw = Buffer.from(await postResp.arrayBuffer());
const zip = new AdmZip(raw);
const entry = zip.getEntries().find((e: AdmZip.IZipEntry) => e.entryName.toLowerCase().endsWith('.xlsx'))!;
const xlsxBuf = entry.getData();

const wb = XLSX.read(xlsxBuf, { type: 'buffer', cellDates: true });
const ws = wb.Sheets['A-Contributions'];
const rows = XLSX.utils.sheet_to_json<Record<string, unknown>>(ws, { defval: '' });

console.log('=== ALL COLUMN NAMES ===');
const allCols = new Set<string>();
rows.slice(0, 5).forEach((r) => Object.keys(r).forEach((k) => allCols.add(k)));
console.log([...allCols].join('\n'));

const ctl = rows.filter((r) => r['Form_Type'] === 'A' && r['Committee_Type'] === 'CTL');
console.log(`\nTotal CTL rows: ${ctl.length}`);

const seen = new Set<string>();
let count = 0;
console.log('\n=== FIRST 10 UNIQUE CTL FILERS (raw field values) ===');
for (const r of ctl) {
  const fid = String(r['Filer_ID'] ?? '').trim();
  if (seen.has(fid)) continue;
  seen.add(fid);
  console.log(`\nFiler_ID: ${fid}`);
  console.log(`  Filer_NamL: "${r['Filer_NamL']}"`);
  console.log(`  Cand_NamL:  "${r['Cand_NamL']}"`);
  console.log(`  Cand_NamF:  "${r['Cand_NamF']}"`);
  if (++count >= 10) break;
}
