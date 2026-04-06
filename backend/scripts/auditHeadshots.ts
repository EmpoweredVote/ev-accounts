/**
 * auditHeadshots.ts — Scan all CDN politician headshot images and flag issues.
 *
 * Checks four categories:
 *   1. Missing headshots — politicians with no image record
 *   2. Broken CDN URLs — 404s, timeouts, non-200 responses
 *   3. File size outliers — unusually large (>500KB) or tiny (<2KB)
 *   4. Image dimensions/aspect ratio — landscape, too small, bad ratio
 *
 * Output: CSV to stdout with columns: politician_id,name,issue,url,details
 * Progress messages go to stderr.
 *
 * Usage:
 *   cd ev-accounts/backend
 *   npx tsx scripts/auditHeadshots.ts             # Full audit
 *   npx tsx scripts/auditHeadshots.ts --dry-run   # Count only, skip HTTP checks
 */

import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

const DRY_RUN = process.argv.includes('--dry-run');

// ---------------------------------------------------------------------------
// Image dimension parsers (pure buffer — no native deps)
// ---------------------------------------------------------------------------

function parsePngDimensions(buf: Buffer): { width: number; height: number } | null {
  const PNG_SIG = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (buf.length < 24 || !buf.subarray(0, 8).equals(PNG_SIG)) return null;
  return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20) };
}

function parseJpegDimensions(buf: Buffer): { width: number; height: number } | null {
  for (let i = 0; i < buf.length - 8; i++) {
    if (buf[i] === 0xff && (buf[i + 1] === 0xc0 || buf[i + 1] === 0xc2)) {
      return { height: buf.readUInt16BE(i + 5), width: buf.readUInt16BE(i + 7) };
    }
  }
  return null;
}

function parseDimensions(buf: Buffer): { width: number; height: number } | null {
  return parsePngDimensions(buf) ?? parseJpegDimensions(buf);
}

// ---------------------------------------------------------------------------
// HTTP helpers
// ---------------------------------------------------------------------------

async function fetchHead(
  url: string,
  timeoutMs = 10_000
): Promise<{ status: number; contentLength: number | null; ok: boolean; error?: string }> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, { method: 'HEAD', signal: controller.signal });
    clearTimeout(timer);
    const cl = res.headers.get('content-length');
    return {
      status: res.status,
      contentLength: cl ? parseInt(cl, 10) : null,
      ok: res.ok,
    };
  } catch (err: unknown) {
    clearTimeout(timer);
    const message = err instanceof Error ? err.message : String(err);
    return { status: 0, contentLength: null, ok: false, error: message };
  }
}

async function fetchBytes(url: string, timeoutMs = 20_000): Promise<Buffer | null> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, { signal: controller.signal });
    clearTimeout(timer);
    if (!res.ok) return null;
    const arrayBuf = await res.arrayBuffer();
    return Buffer.from(arrayBuf);
  } catch {
    clearTimeout(timer);
    return null;
  }
}

// ---------------------------------------------------------------------------
// Batch helpers
// ---------------------------------------------------------------------------

async function runBatch<T, R>(
  items: T[],
  batchSize: number,
  fn: (item: T) => Promise<R>
): Promise<R[]> {
  const results: R[] = [];
  for (let i = 0; i < items.length; i += batchSize) {
    const batch = items.slice(i, i + batchSize);
    const batchResults = await Promise.all(batch.map(fn));
    results.push(...batchResults);
  }
  return results;
}

// ---------------------------------------------------------------------------
// CSV output
// ---------------------------------------------------------------------------

function csvRow(
  id: number,
  name: string,
  issue: string,
  url: string,
  details: string
): string {
  // Wrap name in quotes to handle commas; url and details are safe without quotes
  return `${id},"${name}",${issue},${url},${details}`;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

interface PoliticianRow {
  id: number;
  first_name: string;
  last_name: string;
  url: string | null;
}

async function main() {
  const result = await pool.query<PoliticianRow>(`
    SELECT p.id, p.first_name, p.last_name, pi.url
    FROM essentials.politicians p
    LEFT JOIN essentials.politician_images pi
      ON pi.politician_id = p.id AND pi.type = 'default'
    ORDER BY p.id
  `);

  const rows = result.rows;
  const withImages = rows.filter((r) => r.url !== null);
  const withoutImages = rows.filter((r) => r.url === null);

  console.error(`Checking ${rows.length} politicians...`);
  console.error(`  With images: ${withImages.length}`);
  console.error(`  Missing headshots: ${withoutImages.length}`);

  if (DRY_RUN) {
    console.log(
      `Found ${rows.length} politicians, ${withImages.length} with images, ${withoutImages.length} missing headshots. Dry run — skipping HTTP checks.`
    );
    await pool.end();
    return;
  }

  // CSV header
  process.stdout.write('politician_id,name,issue,url,details\n');

  // Check 1: Missing headshots (no HTTP needed)
  for (const row of withoutImages) {
    const name = `${row.first_name} ${row.last_name}`;
    process.stdout.write(csvRow(row.id, name, 'missing_headshot', '', 'no image record') + '\n');
  }

  // Checks 2 & 3: HEAD requests for broken URLs and file size outliers
  console.error(`Running HEAD checks on ${withImages.length} URLs (batches of 20)...`);

  interface HeadResult {
    row: PoliticianRow;
    status: number;
    contentLength: number | null;
    ok: boolean;
    error?: string;
  }

  const headResults = await runBatch<PoliticianRow, HeadResult>(
    withImages,
    20,
    async (row) => {
      const head = await fetchHead(row.url!);
      return { row, ...head };
    }
  );

  const okUrls: PoliticianRow[] = [];

  for (const r of headResults) {
    const name = `${r.row.first_name} ${r.row.last_name}`;

    if (!r.ok || r.status !== 200) {
      // Check 2: Broken CDN URL
      const details = r.error
        ? `timeout or error: ${r.error}`
        : `HTTP ${r.status}`;
      process.stdout.write(csvRow(r.row.id, name, 'broken_url', r.row.url!, details) + '\n');
      continue; // Don't attempt dimension check on broken URLs
    }

    // Check 3: File size outliers (from content-length header)
    if (r.contentLength !== null) {
      if (r.contentLength > 500_000) {
        process.stdout.write(
          csvRow(r.row.id, name, 'large_file', r.row.url!, `size=${r.contentLength} bytes`) + '\n'
        );
      } else if (r.contentLength < 2_000) {
        process.stdout.write(
          csvRow(r.row.id, name, 'tiny_file', r.row.url!, `size=${r.contentLength} bytes`) + '\n'
        );
      }
    }

    okUrls.push(r.row);
  }

  // Check 4: Image dimensions and aspect ratio
  console.error(`Running dimension checks on ${okUrls.length} images (batches of 10)...`);

  await runBatch<PoliticianRow, void>(okUrls, 10, async (row) => {
    const buf = await fetchBytes(row.url!);
    if (!buf) return;

    const dims = parseDimensions(buf);
    if (!dims) return; // Could not parse — skip

    const { width, height } = dims;
    const name = `${row.first_name} ${row.last_name}`;
    const dimStr = `width=${width} height=${height}`;

    if (width > height) {
      process.stdout.write(
        csvRow(row.id, name, 'landscape', row.url!, dimStr) + '\n'
      );
    } else if (height < 100) {
      process.stdout.write(
        csvRow(row.id, name, 'too_small', row.url!, dimStr) + '\n'
      );
    } else {
      const ratio = width / height;
      if (ratio < 0.5 || ratio > 1.2) {
        process.stdout.write(
          csvRow(
            row.id,
            name,
            'bad_aspect_ratio',
            row.url!,
            `${dimStr} ratio=${ratio.toFixed(2)}`
          ) + '\n'
        );
      }
    }
  });

  console.error('Audit complete.');
  await pool.end();
}

main().catch((err) => {
  console.error('Fatal error:', err);
  pool.end();
  process.exit(1);
});
