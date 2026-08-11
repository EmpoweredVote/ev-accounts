/**
 * dump-photo-origin-breadcrumbs.mts — capture the rows migration 1688 clears, before it clears them.
 *
 * `essentials.politicians.photo_origin_url` doubles as a research scratchpad: 148 rows hold a
 * process note rather than a URL (`searched:no_results`, `explored`, ...). The migration NULLs
 * them, which is the correct end state for a URL column, but the notes are the only record that
 * somebody already looked for these portraits and came up empty.
 *
 * That signal is undated and of unknown method, so it is not worth a schema column — but it is
 * worth keeping recoverable. This writes the full affected set to a committed JSON artifact so the
 * next headshot sweep can consume it (or ignore it) deliberately rather than by accident.
 *
 * Read-only. Run BEFORE the migration:
 *   node --env-file=.env ./node_modules/tsx/dist/cli.mjs scripts/dump-photo-origin-breadcrumbs.mts
 */
import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { pool } from '../src/lib/db.js';

const OUT = join(process.cwd(), 'data', 'photo-origin-breadcrumbs-2026-08-11.json');

const { rows } = await pool.query(
  `SELECT p.id,
          p.full_name,
          p.photo_origin_url,
          (p.photo_custom_url IS NOT NULL AND btrim(p.photo_custom_url) <> '') AS has_custom_url,
          EXISTS (SELECT 1 FROM essentials.politician_images pi
                   WHERE pi.politician_id = p.id)                              AS has_hosted_image,
          EXISTS (SELECT 1 FROM essentials.office_current_holder och
                   WHERE och.politician_id = p.id)                             AS seated_now,
          p.is_active
     FROM essentials.politicians p
    WHERE p.photo_origin_url IS NOT NULL
      AND btrim(p.photo_origin_url) <> ''
      AND p.photo_origin_url NOT LIKE 'http%'
    ORDER BY p.full_name`
);

const byValue = new Map<string, number>();
for (const r of rows) byValue.set(r.photo_origin_url, (byValue.get(r.photo_origin_url) ?? 0) + 1);

const artifact = {
  captured_at: '2026-08-11',
  purpose:
    'Rows whose photo_origin_url held a research breadcrumb rather than a URL, cleared by migration 1688. ' +
    'Each is a politician somebody already searched for a portrait without success — undated, method unknown. ' +
    'Treat as a reading queue, not as proof no portrait exists.',
  row_count: rows.length,
  value_histogram: Object.fromEntries([...byValue].sort((a, b) => b[1] - a[1])),
  needs_portrait_and_seated: rows.filter(
    (r) => r.seated_now && !r.has_custom_url && !r.has_hosted_image
  ).length,
  rows,
};

writeFileSync(OUT, JSON.stringify(artifact, null, 2) + '\n');
console.log(`wrote ${rows.length} rows to ${OUT}`);
console.log('value histogram:', artifact.value_histogram);
console.log('seated with no portrait at all:', artifact.needs_portrait_and_seated);

await pool.end();
