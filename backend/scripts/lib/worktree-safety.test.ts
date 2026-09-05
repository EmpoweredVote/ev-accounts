import { describe, it, expect } from 'vitest';
import { verdictFor, IGNORABLE } from './worktree-safety.mjs';

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
