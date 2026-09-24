/**
 * cfa-summaries-to-migration.ts — reviewed summaries CSV → data migration for filed_report_summaries.
 *
 * Usage:
 *   npm run steward --prefix backend -- slot CA --purpose "..."          # get the slot first
 *   npx tsx scripts/cfa-summaries-to-migration.ts --csv reviewed.csv --slot CA_0000 --suffix monroe_april
 *
 * Writes backend/migrations/<slot>_filed_report_summaries_<suffix>.sql. Refuses any row whose
 * needs_review is not "no". Dry-run the output on prod (BEGIN … ROLLBACK) before applying it.
 */

import * as fs from 'fs';
import * as path from 'path';
import { parseCsv, buildMigrationSql } from './lib/cfaSummaryMigration.js';

function flag(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i === -1 ? undefined : process.argv[i + 1];
}

const csv = flag('--csv');
const slot = flag('--slot');
const suffix = flag('--suffix');
const sourceSystem = flag('--source-system') ?? 'IN_MONROE_COUNTY_LOCAL';

if (!csv || !slot || !suffix || !/^[a-z0-9_]+$/.test(suffix)) {
  console.error('Usage: npx tsx scripts/cfa-summaries-to-migration.ts --csv <reviewed.csv> --slot CA_0000 --suffix <snake_case> [--source-system IN_MONROE_COUNTY_LOCAL]');
  process.exit(1);
}

const sql = buildMigrationSql(parseCsv(fs.readFileSync(csv, 'utf8')), {
  slot,
  sourceSystem,
  date: new Date().toISOString().slice(0, 10),
});
const out = path.join(path.dirname(new URL(import.meta.url).pathname), '..', 'migrations', `${slot}_filed_report_summaries_${suffix}.sql`);
fs.writeFileSync(out, sql, 'utf8');
console.log(`wrote ${out}`);
