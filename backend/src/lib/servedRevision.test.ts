import { describe, it, expect, vi } from 'vitest';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, resolve } from 'node:path';

// seasonService imports db.js at module scope; no query runs here.
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));

const here = dirname(fileURLToPath(import.meta.url));
const BUILD_AND_CHECK = resolve(here, '../../../.claude/skills/research-stances/scripts/build-and-check.mjs');

// C1 (final review 2026-09-24): one resolver for "the text voters read" — ADR 0006 §3.
describe('servedRevisionLateral', () => {
  it('resolves the LATEST published/superseded revision of the PIN\'S VERSION, not the pin itself', async () => {
    const { servedRevisionLateral } = await import('./seasonService.js');
    const sql = servedRevisionLateral('sq.topic_revision_id', 'eff');
    expect(sql).toMatch(/^LATERAL \(/);
    expect(sql).toMatch(/e\.topic_id = pin\.topic_id\s+AND e\.version\s+= pin\.version/);
    expect(sql).toContain("e.status IN ('published', 'superseded')");
    expect(sql).toContain('WHERE pin.id = sq.topic_revision_id');
    expect(sql).toMatch(/ORDER BY e\.revision DESC\s+LIMIT 1\s+\) eff$/);
  });

  it('build-and-check.mjs carries a byte-identical copy (it cannot import backend TypeScript)', async () => {
    const { servedRevisionLateral } = await import('./seasonService.js');
    const mirror = await import(pathToFileURL(BUILD_AND_CHECK).href) as { servedRevisionLateral: (p: string, a?: string) => string };
    for (const [pin, alias] of [['sq.topic_revision_id', 'eff'], ['$1::uuid', 'tr'], ['CASE WHEN x THEN y END', 'z']]) {
      expect(mirror.servedRevisionLateral(pin, alias)).toBe(servedRevisionLateral(pin, alias));
    }
  });

  it('getPromotedTopics (the voter compass) uses the same resolver on the season pin', async () => {
    const { readFileSync } = await import('node:fs');
    const src = readFileSync(resolve(here, 'compassService.ts'), 'utf8');
    expect(src).toContain("JOIN ${servedRevisionLateral('p.season_revision_id', 'eff')} ON true");
  });
});
