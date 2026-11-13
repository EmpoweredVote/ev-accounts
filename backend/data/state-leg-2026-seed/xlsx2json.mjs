// Minimal xlsx reader: an .xlsx is a zip of XML, already extracted by `unzip`. Reads one sheet
// into rows of strings. Kept OUT of the download directory on purpose — an interpreter loads
// code from the script's own directory, so a planted module next to the data must not be
// reachable. Paths come in as arguments.
import fs from 'node:fs';
import path from 'node:path';

const dir = process.argv[2];           // the extracted xlsx root (holds xl/)
const sheet = process.argv[3] || 'sheet1.xml';
if (!dir) { console.error('usage: xlsx2json.mjs <extracted-dir> [sheetN.xml]'); process.exit(2); }

const xml = fs.readFileSync(path.join(dir, 'xl', 'worksheets', sheet), 'utf8');
let shared = [];
const ssPath = path.join(dir, 'xl', 'sharedStrings.xml');
if (fs.existsSync(ssPath)) {
  const ss = fs.readFileSync(ssPath, 'utf8');
  shared = [...ss.matchAll(/<si>([\s\S]*?)<\/si>/g)].map((m) =>
    [...m[1].matchAll(/<t[^>]*>([\s\S]*?)<\/t>/g)].map((t) => t[1]).join(''));
}
const unesc = (s) => s.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"')
  .replace(/&apos;/g, "'").replace(/&#x([0-9a-fA-F]+);/g, (_, h) => String.fromCodePoint(parseInt(h, 16)))
  .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d))).replace(/&amp;/g, '&');
const colIndex = (ref) => {
  const letters = ref.match(/^[A-Z]+/)[0];
  let n = 0;
  for (const ch of letters) n = n * 26 + (ch.charCodeAt(0) - 64);
  return n - 1;
};

const rows = [];
for (const rm of xml.matchAll(/<row[^>]*>([\s\S]*?)<\/row>/g)) {
  const cells = [];
  // 🔴 AN EMPTY CELL IS SELF-CLOSING (`<c r="B2" s="12"/>`) AND A PAIRED-TAG-ONLY REGEX
  //   SWALLOWS THE NEXT REAL CELL INTO IT — every column after an empty one then shifts left,
  //   and the result is a complete, plausible, WRONG table. Read as paired tags only, Susan
  //   Collins' US Senate row reported district "17", which is her party code. Both forms here.
  for (const cm of rm[1].matchAll(/<c r="([A-Z]+\d+)"((?:[^>"/]|"[^"]*"|\/(?!>))*)(?:\/>|>([\s\S]*?)<\/c>)/g)) {
    const [, ref, attrs, body = ''] = cm;
    const t = (attrs.match(/t="([^"]+)"/) || [])[1];
    let v = null;
    if (t === 'inlineStr') v = [...body.matchAll(/<t[^>]*>([\s\S]*?)<\/t>/g)].map((x) => x[1]).join('');
    else {
      const vm = body.match(/<v>([\s\S]*?)<\/v>/);
      if (vm) v = t === 's' ? shared[Number(vm[1])] : vm[1];
    }
    cells[colIndex(ref)] = v === null || v === undefined ? '' : unesc(String(v));
  }
  rows.push(Array.from(cells, (c) => c ?? ''));
}
process.stdout.write(JSON.stringify(rows));
