/**
 * report.ts — open local-record exceptions, per city: counts by cause for each of the last 8 ISO weeks
 * (by the week the exception was first logged), then the open list. Read-only.
 *
 *   npm run local-record:report --prefix backend
 */
import 'dotenv/config';
import { fileURLToPath } from 'node:url';

export interface WeekRow { city_scope: string; cause: string; week: string; n: number }
export interface OpenRow { city_scope: string; cause: string; subject: string; run_id: string; detail: unknown }

const pad = (s: string, w: number) => s.padEnd(w);

/** ISO week label ('2026-W48') of a date. */
export function isoWeek(d: Date): string {
  const t = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
  const year = t.getUTCFullYear();
  const week = Math.ceil(((t.getTime() - Date.UTC(year, 0, 1)) / 86_400_000 + 1) / 7);
  return `${year}-W${String(week).padStart(2, '0')}`;
}

/** The last 8 ISO weeks ending with the week of `now`, oldest first. */
export const lastWeeks = (now: Date): string[] =>
  Array.from({ length: 8 }, (_, i) => isoWeek(new Date(now.getTime() - (7 - i) * 7 * 86_400_000)));

export function formatReport(weeks: WeekRow[], open: OpenRow[], now: Date = new Date()): string {
  const cities = [...new Set([...weeks.map((r) => r.city_scope), ...open.map((r) => r.city_scope)])].sort();
  if (!cities.length) return 'No open exceptions.\n';
  const lines: string[] = [];
  for (const city of cities) {
    lines.push(`${city}`, '', 'Open exceptions by cause and ISO week (last 8 weeks):');
    const mine = weeks.filter((r) => r.city_scope === city);
    for (const week of lastWeeks(now)) {
      const parts = mine.filter((r) => r.week === week).sort((a, b) => (a.cause < b.cause ? -1 : 1)).map((r) => `${r.cause} ${r.n}`);
      lines.push(`  ${pad(week, 9)} ${parts.length ? parts.join(', ') : 'none'}`);
    }
    lines.push('', 'Open list:');
    const list = open.filter((r) => r.city_scope === city);
    if (!list.length) lines.push('  none');
    for (const r of list) lines.push(`  ${pad(r.cause, 20)} ${r.subject}  ${JSON.stringify(r.detail)}`);
    lines.push('');
  }
  return lines.join('\n');
}

async function main(): Promise<void> {
  const { pool } = await import('../../src/lib/db.js');
  try {
    const weeks = await pool.query(
      `SELECT city_scope, cause, to_char(created_at, 'IYYY-"W"IW') AS week, count(*)::int AS n
       FROM essentials.local_record_exceptions
       WHERE status = 'open' AND created_at >= date_trunc('week', now()) - interval '7 weeks' -- created_at: the table has no reopened-at column
       GROUP BY 1, 2, 3 ORDER BY 1, 3, 2`,
    );
    const open = await pool.query(
      `SELECT city_scope, cause, subject, run_id, detail FROM essentials.local_record_exceptions
       WHERE status = 'open' ORDER BY city_scope, cause, subject`,
    );
    process.stdout.write(formatReport(weeks.rows, open.rows));
  } finally {
    await pool.end();
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((e) => { console.error(e); process.exit(1); });
}
