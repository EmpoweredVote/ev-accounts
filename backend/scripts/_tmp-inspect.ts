import AdmZip from 'adm-zip';
import iconv from 'iconv-lite';

const zip = new AdmZip('C:/Users/Chris/AppData/Local/Temp/dbwebexport.zip');
const entries = zip.getEntries().filter(e => e.entryName.endsWith('.TSV'));
console.log('TSV count:', entries.length);

const targets = [
  'CalAccess/DATA/FILER_TO_FILER_TYPE_CD.TSV',
  'CalAccess/DATA/FILERNAME_CD.TSV',
  'CalAccess/DATA/FILER_FILINGS_CD.TSV',
  'CalAccess/DATA/LOOKUP_CODES_CD.TSV',
];
for (const ep of targets) {
  const entry = zip.getEntry(ep);
  if (!entry) { console.log(ep + ': NOT FOUND'); continue; }
  const rawBytes = entry.getData();
  const sizeKB = (rawBytes.length / 1024).toFixed(0);
  const utf8 = iconv.decode(rawBytes.slice(0, 800), 'win1252');
  const firstLine = utf8.split('\n')[0];
  console.log(ep + ' (' + sizeKB + ' KB): ' + firstLine.split('\t').join(', '));
}
