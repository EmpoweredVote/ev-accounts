import { describe, it, expect } from 'vitest';
import { existsSync, mkdtempSync, mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { coderAnnexPath, annexPath } from './codebookAnnex.js';
import { readBundleSeason, writeBundleSeason } from './seasonTarget.js';

// coderAnnexPath uses path.join, so normalise the separator before comparing (see codebookAnnex.test.ts).
const norm = (p: string) => p.replaceAll('\\', '/');
const draft3 = { id: 'd3', number: 3, name: 'Season 3', status: 'draft' as const };

describe('coderAnnexPath', () => {
  const repo = mkdtempSync(join(tmpdir(), 'annex-'));
  const annex = join(repo, 'docs', 'codebook', 'annex');
  mkdirSync(join(annex, 'season3'), { recursive: true });
  writeFileSync(join(annex, 'library-books.md'), 'season 2 annex');
  writeFileSync(join(annex, 'season3', 'library-books.md'), 'season 3 annex');
  writeFileSync(join(annex, 'vouchers.md'), 'season 2 annex');

  it('reads season3/<key>.md for a draft Season 3 bundle', () =>
    expect(norm(coderAnnexPath(repo, 'library-books', draft3))).toBe(norm(join(annex, 'season3', 'library-books.md'))));
  it('reads the root file for the open season, even when a season file exists', () => {
    expect(coderAnnexPath(repo, 'library-books', null)).toBe(annexPath(repo, 'library-books'));
    expect(coderAnnexPath(repo, 'library-books', { number: 3, status: 'open' })).toBe(annexPath(repo, 'library-books'));
  });
  it('falls back to the root file when the season has no annex of its own for the topic', () =>
    expect(coderAnnexPath(repo, 'vouchers', draft3)).toBe(annexPath(repo, 'vouchers')));
  it('falls back to the root path when the season dir does not exist at all', () =>
    expect(coderAnnexPath(repo, 'vouchers', { number: 4, status: 'draft' })).toBe(annexPath(repo, 'vouchers')));

  it('takes the season from the batch dir: season.json for a draft bundle, none for an open one', () => {
    const draftDir = mkdtempSync(join(tmpdir(), 'batch-'));
    writeBundleSeason(draftDir, draft3);
    expect(norm(coderAnnexPath(repo, 'library-books', readBundleSeason(draftDir)))).toBe(norm(join(annex, 'season3', 'library-books.md')));
    const openDir = mkdtempSync(join(tmpdir(), 'batch-'));
    writeBundleSeason(openDir, { ...draft3, status: 'open' });
    expect(readBundleSeason(openDir)).toBeNull();
    expect(coderAnnexPath(repo, 'library-books', readBundleSeason(openDir))).toBe(annexPath(repo, 'library-books'));
  });

  it('finds the real Season 3 library-books annex in this repo', () => {
    const repoRoot = resolve(__dirname, '..', '..', '..');
    const p = coderAnnexPath(repoRoot, 'education-library-books', draft3);
    expect(norm(p)).toMatch(/docs\/codebook\/annex\/season3\/education-library-books\.md$/);
    expect(existsSync(p)).toBe(true);
  });
});
