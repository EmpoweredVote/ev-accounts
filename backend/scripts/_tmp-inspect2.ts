import AdmZip from 'adm-zip';
import iconv from 'iconv-lite';
import { parse } from 'csv-parse/sync';

const zip = new AdmZip('C:/Users/Chris/AppData/Local/Temp/dbwebexport.zip');

function loadTsv<T extends object>(entryPath: string, limit?: number): T[] {
  const entry = zip.getEntry(entryPath);
  if (!entry) throw new Error(`Not found: ${entryPath}`);
  const rawBytes = entry.getData();
  const utf8 = iconv.decode(rawBytes, 'win1252');
  return parse(utf8, {
    delimiter: '\t',
    columns: true,
    relax_column_count: true,
    quote: false,
    skip_empty_lines: true,
    trim: true,
    to: limit,
  }) as T[];
}

// Look at LOOKUP_CODES_CD for county codes
const lookupRows = loadTsv<any>('CalAccess/DATA/LOOKUP_CODES_CD.TSV');
const countyRows = lookupRows.filter((r: any) => r.CODE_TYPE === 'COU' || r.CODE_TYPE === 'CTY');
console.log('LOOKUP county rows (first 5):', countyRows.slice(0, 5));

// Unique CODE_TYPEs
const types = [...new Set(lookupRows.map((r: any) => r.CODE_TYPE))];
console.log('All CODE_TYPE values:', types.slice(0, 20));

// Sample FILERNAME rows to understand CITY values for LA
const nameRows = loadTsv<any>('CalAccess/DATA/FILERNAME_CD.TSV', 1000);
const laRows = nameRows.filter((r: any) => (r.CITY || '').toLowerCase().includes('angeles'));
console.log('Sample LA FILERNAME rows:', laRows.slice(0, 3).map((r: any) => ({FILER_ID: r.FILER_ID, CITY: r.CITY, ST: r.ST, NAMF: r.NAMF, NAML: r.NAML})));

// Sample FILER_TO_FILER_TYPE_CD rows with COUNTY_CD
const ftRows = loadTsv<any>('CalAccess/DATA/FILER_TO_FILER_TYPE_CD.TSV', 100);
console.log('Sample filer_type cols with county:', ftRows.slice(0, 3).map((r: any) => ({FILER_ID: r.FILER_ID, COUNTY_CD: r.COUNTY_CD, DISTRICT_CD: r.DISTRICT_CD, RACE: r.RACE})));
