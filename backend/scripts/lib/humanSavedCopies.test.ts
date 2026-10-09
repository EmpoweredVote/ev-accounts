import { describe, it, expect } from 'vitest';
import { loadHumanSavedCopies } from './humanSavedCopies.js';

const entry = (o: Record<string, unknown>) => ({
  url: 'https://x.example/policies/a', source_kind: 'own-site', politician_id: 'p', office_id: 'o',
  topic_keys: ['t'], instruments: [], pointer_passages: [], candidate_quotes: [], ...o,
});
const run = (sources: unknown[], files: Record<string, string> = { 'human-saved/a.html': '<p>hello</p>' }) => {
  const all: Record<string, string> = { '/b/sources.json': JSON.stringify({ batch_id: 'b', sources }), ...Object.fromEntries(Object.entries(files).map(([k, v]) => [`/b/${k}`, v])) };
  return loadHumanSavedCopies('/b', (r) => r.replace(/<[^>]+>/g, ''), (p) => all[p], (p) => p in all);
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
    expect(loadHumanSavedCopies('/b', (r) => r, () => '', () => false)).toEqual({ copies: new Map(), warnings: [] });
  });
});
