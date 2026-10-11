import { describe, it, expect } from 'vitest';
import { join, resolve } from 'node:path';
import { loadHumanSavedCopies } from './humanSavedCopies.js';

const BATCH = '/b';

const entry = (o: Record<string, unknown>) => ({
  url: 'https://x.example/policies/a', source_kind: 'own-site', politician_id: 'p', office_id: 'o',
  topic_keys: ['t'], instruments: [], pointer_passages: [], candidate_quotes: [], ...o,
});
// 🔴 The fake filesystem must be keyed by the paths the implementation actually builds, and the two
// are NOT the same shape: the manifest is join(dir, 'sources.json'), a saved copy is
// resolveHumanSavedPath -> resolve(dir, rel), which also absolutises. On Windows those are
// `\b\sources.json` and `C:\b\human-saved\a.html`. Keying on '/b/…' literals missed both, so every
// lookup returned undefined — on Windows only.
const run = (sources: unknown[], files: Record<string, string> = { 'human-saved/a.html': '<p>hello</p>' }) => {
  const all: Record<string, string> = {
    [join(BATCH, 'sources.json')]: JSON.stringify({ batch_id: 'b', sources }),
    ...Object.fromEntries(Object.entries(files).map(([k, v]) => [resolve(BATCH, k), v])),
  };
  return loadHumanSavedCopies(BATCH, (r) => r.replace(/<[^>]+>/g, ''), (p) => all[p], (p) => p in all);
};

describe('loadHumanSavedCopies', () => {
  it('loads an own-site copy and hashes the raw file', () => {
    const { copies } = run([entry({ human_saved_path: 'human-saved/a.html' })]);
    expect(copies.get('https://x.example/policies/a')?.text).toBe('hello');
    expect(copies.get('https://x.example/policies/a')?.rawSha256).toMatch(/^[0-9a-f]{64}$/);
  });
  it('rule 3: ignores a news or public-record source even with a saved copy', () => {
    expect(run([entry({ source_kind: 'news', pointer_passages: ['p'], human_saved_path: 'human-saved/a.html' })]).copies.size).toBe(0);
    expect(run([entry({ source_kind: 'public-record', human_saved_path: 'human-saved/a.html' })]).copies.size).toBe(0);
  });
  it('refuses a path outside the batch dir and a missing file, with a warning', () => {
    expect(run([entry({ human_saved_path: '../../etc/passwd' })]).warnings[0]).toMatch(/outside/);
    expect(run([entry({ human_saved_path: 'human-saved/gone.html' })]).warnings[0]).toMatch(/does not exist/);
  });
  it('no sources.json = no copies and no warning', () => {
    expect(loadHumanSavedCopies(BATCH, (r) => r, () => '', () => false)).toEqual({ copies: new Map(), warnings: [] });
  });
});
