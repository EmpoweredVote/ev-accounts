import { describe, it, expect } from 'vitest';
import { verdictFor, IGNORABLE, parsePorcelain } from './worktree-safety.mjs';

// §9 rule 4: "Verify before deleting a worktree or branch: untracked-and-ignored count is zero,
// the branch is fully merged into origin/master, the merged content is byte-identical, and the
// repo stash count is unchanged. Run a positive control on any detector that reports 'nothing
// found' — on 2026-09-04 two such detectors were silently broken and only a control exposed
// them."
//
// 🔴 THE LITERAL RULE CANNOT PASS, WHICH IS WHY IT WAS NEVER RUN AS WRITTEN. Every worktree
//    here carries node_modules and a .env copy, so "untracked-and-ignored count is zero" is
//    false every single time. A checklist whose first item always fails is a checklist people
//    stop at — so the check asks the question the rule MEANS: is there anything here that
//    exists nowhere else? node_modules is regenerable and a .env verified byte-identical to the
//    main worktree's is a copy, and neither is unique content.

const ok = {
  merged: true,
  identicalContent: true,
  stashDelta: 0,
  untracked: [],
  envIdentical: true,
  controlPassed: true,
};

describe('verdictFor', () => {
  it('clears a worktree that is merged, identical, and holds nothing unique', () => {
    const v = verdictFor(ok);
    expect(v.safe).toBe(true);
    expect(v.blockers).toEqual([]);
  });

  it('refuses an unmerged branch', () => {
    const v = verdictFor({ ...ok, merged: false });
    expect(v.safe).toBe(false);
    expect(v.blockers.map((b) => b.kind)).toContain('not-merged');
  });

  it('refuses when the merged content is not byte-identical', () => {
    const v = verdictFor({ ...ok, identicalContent: false });
    expect(v.safe).toBe(false);
    expect(v.blockers.map((b) => b.kind)).toContain('content-differs');
  });

  // Stashes are shared across worktrees and are usually somebody else's. A change in the count
  // during your work means something of yours — or theirs — is sitting in one.
  it('refuses when the stash count moved in either direction', () => {
    expect(verdictFor({ ...ok, stashDelta: 1 }).safe).toBe(false);
    expect(verdictFor({ ...ok, stashDelta: -1 }).safe).toBe(false);
    expect(verdictFor({ ...ok, stashDelta: -1 }).blockers[0].kind).toBe('stash-changed');
  });

  it('ignores node_modules and a verified-identical .env, and says so', () => {
    const v = verdictFor({ ...ok, untracked: ['node_modules/x', 'backend/.env'] });
    expect(v.safe).toBe(true);
    expect(v.ignored).toHaveLength(2);
  });

  // 🔴 THE .env CARVE-OUT IS CONDITIONAL ON HAVING COMPARED IT. An unverified .env is treated
  //    as unique content, because the one in a worktree could hold a credential that exists
  //    nowhere else, and deleting that is unrecoverable.
  it('refuses a .env that was NOT verified identical', () => {
    const v = verdictFor({ ...ok, untracked: ['backend/.env'], envIdentical: false });
    expect(v.safe).toBe(false);
    expect(v.blockers.map((b) => b.kind)).toContain('unique-files');
  });

  it('refuses any other untracked file, naming it', () => {
    const v = verdictFor({ ...ok, untracked: ['backend/data/notes.md'] });
    expect(v.safe).toBe(false);
    const b = v.blockers.find((x) => x.kind === 'unique-files');
    expect(b!.files).toEqual(['backend/data/notes.md']);
  });

  // 🔴 THE RULE'S OWN CLOSING SENTENCE, MADE STRUCTURAL. Two detectors were silently broken on
  //    2026-09-04 and only a positive control exposed them: an mtime scan whose threshold
  //    predated the checkout, and a curl sweep against a host that had begun 403-ing. A scan
  //    that reports "nothing found" is worthless until it has proved it can find something.
  it('refuses when the scan could not prove it detects anything', () => {
    const v = verdictFor({ ...ok, controlPassed: false });
    expect(v.safe).toBe(false);
    expect(v.blockers.map((b) => b.kind)).toContain('control-failed');
  });

  it('reports every blocker at once, not just the first', () => {
    const v = verdictFor({ merged: false, identicalContent: false, stashDelta: 2,
      untracked: ['a.txt'], envIdentical: true, controlPassed: false });
    expect(v.blockers).toHaveLength(5);
  });

  it('exposes what counts as ignorable so the caller can print it', () => {
    expect(IGNORABLE.some((r) => r.test('node_modules/foo/bar'))).toBe(true);
    expect(IGNORABLE.some((r) => r.test('backend/.env'))).toBe(true);
    expect(IGNORABLE.some((r) => r.test('backend/.envrc'))).toBe(false);
    expect(IGNORABLE.some((r) => r.test('notes.md'))).toBe(false);
  });
});

// ── PORCELAIN PARSING ────────────────────────────────────────────────────────────────────────
//
// 🔴 THESE PIN A BUG THAT CORRUPTED A FILENAME IN A REAL VERDICT (2026-09-12, /c/ev-accounts-in).
//    The runner trimmed the WHOLE `git status --porcelain` output and then took `slice(3)` of
//    each line. A leading space is significant in porcelain — ` M path` means "tracked, modified
//    in the worktree" — so trimming ate it on the first line only, and slice(3) then ate the
//    first character of the path. The blocker printed
//    `ackend/data/seed-in-local-headshots-2026/harvest.json`, a path that does not exist.
//
// 🔴 AND IT WAS UNDER THE WRONG HEADING. A tracked file with uncommitted edits is not untracked.
//    It blocked as "unique-files: these exist nowhere else", which misdescribes the risk: the
//    file IS in git, it is the EDIT that exists nowhere else. Different fact, different fix.

describe('parsePorcelain', () => {
  it('keeps the first path intact when the first line is a tracked modification', () => {
    const out = ' M backend/data/harvest.json\n?? backend/data/_scratch.png\n';
    const s = parsePorcelain(out);
    expect(s.modified).toEqual(['backend/data/harvest.json']);
    expect(s.untracked).toEqual(['backend/data/_scratch.png']);
  });

  it('separates tracked modifications from untracked and ignored paths', () => {
    const out = [
      ' M tracked-modified.json',
      'M  tracked-staged.json',
      ' D tracked-deleted.json',
      '?? untracked.png',
      '!! node_modules/foo/index.js',
    ].join('\n');
    const s = parsePorcelain(out);
    expect(s.modified.sort()).toEqual(
      ['tracked-deleted.json', 'tracked-modified.json', 'tracked-staged.json'],
    );
    expect(s.untracked.sort()).toEqual(['node_modules/foo/index.js', 'untracked.png']);
  });

  it('unquotes a path that git escaped, and handles a rename', () => {
    const out = String.raw`?? "backend/data/caf\303\251.png"` + '\n' + 'R  old/name.ts -> new/name.ts\n';
    const s = parsePorcelain(out);
    expect(s.untracked).toEqual(['backend/data/café.png']);
    expect(s.modified).toEqual(['new/name.ts']);
  });

  it('returns empty lists for empty output', () => {
    expect(parsePorcelain('')).toEqual({ untracked: [], modified: [] });
  });
});

describe('verdictFor — uncommitted tracked edits', () => {
  it('blocks on a tracked file with uncommitted changes, under its own kind', () => {
    const v = verdictFor({ ...ok, modified: ['backend/data/harvest.json'] });
    expect(v.safe).toBe(false);
    const b = v.blockers.find((x) => x.kind === 'dirty-tracked');
    expect(b).toBeTruthy();
    expect(b.files).toEqual(['backend/data/harvest.json']);
    // It must NOT be misreported as something that exists nowhere else.
    expect(v.blockers.map((x) => x.kind)).not.toContain('unique-files');
  });

  it('is quiet when there are no tracked modifications', () => {
    expect(verdictFor({ ...ok, modified: [] }).safe).toBe(true);
  });
});
