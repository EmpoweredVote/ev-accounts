import { describe, it, expect } from 'vitest';
import { pathspecUsed, commitNotices, OTHER_SESSION_WINDOW_HOURS } from './steward-precommit.mjs';

// §9 rules 1 and 3, which are one signal rather than two:
//
//   1. One session owns a worktree. If you are going to commit, work in your own.
//   3. Always commit with an explicit pathspec — staging carefully is not enough, because it
//      is the OTHER session's `git add -A` that sweeps your files in.
//
// Rule 3 exists BECAUSE of rule 1. A pathspec-less commit alone in your own worktree is
// harmless; the same commit in a checkout another session is using is the recorded failure.
// So the warning is graded by whether anyone else is actually there.

const me = { holder: 'chris@empowered.vote', machine: 'DESKTOP-G6KDNN2' };
const now = Date.parse('2026-09-04T20:00:00Z');
const hoursAgo = (h: number) => new Date(now - h * 3.6e6);

const marker = (over: Record<string, unknown> = {}) => ({
  holder: 'candrews@empowered.vote', machine: 'Chriss-MacBook-Pro.local',
  label: 'knight/ca-2', started_at: hoursAgo(1), ...over,
});

describe('pathspecUsed', () => {
  // 🔴 GIT ACTUALLY TELLS US THIS, which is why rule 3 is checkable at all. A partial commit
  //    (`git commit -- <path>`) builds a TEMPORARY index, so GIT_INDEX_FILE points at
  //    `.git/next-index-<pid>.lock` instead of `.git/index`. Verified against real git before
  //    this was written; without that signal a hook cannot tell the two apart at all.
  it('reads a temporary next-index as a pathspec commit', () => {
    expect(pathspecUsed('C:/repo/.git/next-index-33584.lock')).toBe(true);
    expect(pathspecUsed('.git/next-index-9.lock')).toBe(true);
  });

  it('reads the ordinary index as no pathspec', () => {
    expect(pathspecUsed('.git/index')).toBe(false);
    expect(pathspecUsed('C:/repo/.git/index')).toBe(false);
  });

  // An unset GIT_INDEX_FILE means git used the default index, i.e. no pathspec.
  it('treats an absent value as no pathspec', () => {
    expect(pathspecUsed(undefined)).toBe(false);
    expect(pathspecUsed('')).toBe(false);
  });
});

describe('commitNotices', () => {
  it('says nothing when you used a pathspec and nobody else is here', () => {
    expect(commitNotices({ pathspec: true, markers: [], me, nowMs: now })).toEqual([]);
  });

  it('reminds you about the pathspec even when you are alone', () => {
    const n = commitNotices({ pathspec: false, markers: [], me, nowMs: now });
    expect(n.map((x) => x.kind)).toEqual(['no-pathspec']);
    expect(n[0].severity).toBe('note');
  });

  // 🔴 THE COMBINATION IS THE RECORDED FAILURE, and it is the only one that shouts. Neither
  //    half alone is: committing without a pathspec alone in your own checkout hurts nobody,
  //    and another session being present is normal and expected.
  it('shouts when there is no pathspec AND another session holds this worktree', () => {
    const n = commitNotices({ pathspec: false, markers: [marker()], me, nowMs: now });
    const bad = n.find((x) => x.kind === 'no-pathspec');
    expect(bad!.severity).toBe('alarm');
    expect(bad!.others).toHaveLength(1);
    expect(bad!.others[0].holder).toBe('candrews@empowered.vote');
  });

  it('still mentions the other session when you did use a pathspec, as information', () => {
    const n = commitNotices({ pathspec: true, markers: [marker()], me, nowMs: now });
    expect(n.map((x) => x.kind)).toEqual(['shared-worktree']);
    expect(n[0].severity).toBe('note');
  });

  // 🔴 THE SAME EMAIL ON ANOTHER BOX IS ANOTHER SESSION — the design makes the holder
  //    (email, hostname) because one author's two machines collide as readily as two people.
  it('counts the same person on another machine as another session', () => {
    const n = commitNotices({ pathspec: false, markers: [marker({ holder: me.holder })], me, nowMs: now });
    expect(n.find((x) => x.kind === 'no-pathspec')!.severity).toBe('alarm');
  });

  it('does not count your own marker as somebody else', () => {
    const mine = marker({ holder: me.holder, machine: me.machine });
    const n = commitNotices({ pathspec: false, markers: [mine], me, nowMs: now });
    expect(n.map((x) => x.kind)).toEqual(['no-pathspec']);
    expect(n[0].severity).toBe('note');
  });

  // A marker is a "last seen" record, not a liveness proof — nothing releases it when a
  // terminal closes. Treating a two-day-old marker as an active session would make the alarm
  // fire constantly and teach people to ignore it, which is worse than not having it.
  it('ignores a marker older than the attention window', () => {
    const stale = marker({ started_at: hoursAgo(OTHER_SESSION_WINDOW_HOURS + 1) });
    const n = commitNotices({ pathspec: false, markers: [stale], me, nowMs: now });
    expect(n[0].severity).toBe('note');
    expect(n[0].others).toEqual([]);
  });

  it('keeps a marker exactly inside the window', () => {
    const fresh = marker({ started_at: hoursAgo(OTHER_SESSION_WINDOW_HOURS - 0.01) });
    const n = commitNotices({ pathspec: false, markers: [fresh], me, nowMs: now });
    expect(n[0].severity).toBe('alarm');
  });

  it('reports every other session, not just the first', () => {
    const n = commitNotices({
      pathspec: false,
      markers: [marker(), marker({ holder: 'third@example.com', machine: 'box3' })],
      me, nowMs: now,
    });
    expect(n.find((x) => x.kind === 'no-pathspec')!.others).toHaveLength(2);
  });

  // An unreadable timestamp must not be treated as recent: an alarm nobody can explain is how
  // a warning gets ignored, and this one has to stay credible to be worth anything.
  it('ignores a marker whose timestamp cannot be read', () => {
    const n = commitNotices({ pathspec: false, markers: [marker({ started_at: null })], me, nowMs: now });
    expect(n[0].severity).toBe('note');
  });
});
