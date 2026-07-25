import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';
import { hasLiveDb } from '../../tests/helpers/liveDb.js';

const SOURCES_PATH = path.resolve(__dirname, '../data/arcgis_sources.json');

function slugifyPlace(name: string): string {
  // Mirrors load-state-tiger-boundaries.ts slugifyName() — strips trailing place tokens.
  const stripTokens = /\s+(county|city|town|village|borough|township|cdp)\b\.?\s*$/i;
  const stripped = name.replace(stripTokens, '').trim();
  return stripped.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
}

describe('arcgis_sources.json coverage (GEO-05)', () => {
  let pool: pg.Pool;

  beforeAll(() => {
    pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
  });

  afterAll(async () => {
    await pool.end();
  });

  it('arcgis_sources.json file exists', () => {
    expect(fs.existsSync(SOURCES_PATH)).toBe(true);
  });

  // Cross-checks arcgis_sources.json against the live places table, so it needs
  // a real database. Without one, skip rather than fail: see tests/helpers/liveDb.ts.
  it.skipIf(!hasLiveDb)('every UT G4110 place has a jurisdiction_id record (active|no_source|at_large|manual_geojson)', async () => {
    const sources: Array<{
      jurisdiction_id: string;
      layer_class: string;
      status: 'active' | 'no_source' | 'at_large' | 'manual_geojson';
    }> = JSON.parse(fs.readFileSync(SOURCES_PATH, 'utf-8'));

    const sourcePlaceIds = new Set(
      sources
        .filter((s) => s.layer_class === 'city_ward')
        .map((s) => s.jurisdiction_id),
    );

    const { rows } = await pool.query<{ name: string }>(
      `SELECT name FROM essentials.geofence_boundaries WHERE state='49' AND mtfcc='G4110'`,
    );

    const missing: string[] = [];
    for (const r of rows) {
      const slug = slugifyPlace(r.name);
      const expected = `ocd-division/country:us/state:ut/place:${slug}`;
      if (!sourcePlaceIds.has(expected)) missing.push(expected);
    }

    expect(missing, `Missing jurisdiction_id entries: ${missing.join(', ')}`).toEqual([]);
  });

  it('every record has a valid status', async () => {
    if (!fs.existsSync(SOURCES_PATH)) return; // first test will fail; skip cascade
    const sources = JSON.parse(fs.readFileSync(SOURCES_PATH, 'utf-8'));
    const valid = new Set(['active', 'no_source', 'at_large', 'manual_geojson']);
    for (const s of sources) {
      expect(valid.has(s.status), `Bad status on ${s.jurisdiction_id}: ${s.status}`).toBe(true);
    }
  });
});
