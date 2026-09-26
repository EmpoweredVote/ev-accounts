/**
 * Branch drift: how far a session's branch has fallen behind the default branch, and whether
 * it ALREADY conflicts with it.
 *
 * ── THE COLLISION THIS EXISTS FOR, AND WHY THE OTHER FOUR MISSED IT ──────────────────────────
 *
 * The coordination design names four ways concurrent sessions collide, and the steward already
 * covers the two that no convention can fix: migration slots, and jurisdiction claims. On
 * 2026-09-26 a fifth was measured, and every existing mechanism worked perfectly throughout it.
 *
 *   Knight slice 11 (Michigan) claimed `state:mi`. Slice 12 (North Dakota) claimed `state:nd`.
 *   Disjoint scopes — the database had nothing to refuse. Slots CC_0138-0143 and CC_0144-0149 —
 *   no collision. Separate worktrees — no HEAD moved under anyone. All three mechanisms did
 *   exactly their job.
 *
 *   Both slices then edited `backend/scripts/load-state-tiger-boundaries.ts`, because every
 *   state's geography load does. PR #797 sat 64 commits behind master with 2 conflicting files
 *   for two days, and nothing told anybody.
 *
 * 🔴 THE STEWARD'S SCOPES DESCRIBE THE WORLD; THIS COLLISION WAS IN THE REPO. A jurisdiction
 *    claim says which PLACE you are working on. It cannot know that seeding that place means
 *    editing a file every other place also edits. Two correctly-disjoint world-claims collided
 *    in one file, in two separate worktrees — which the design's taxonomy says needs a SHARED
 *    working directory to happen. It does not.
 *
 * ▶ SO THE UNIT OF WARNING HERE IS A BRANCH, NOT A SCOPE. The steward already records which
 *   branch each session's worktree is on. That is enough to answer "is your work still going to
 *   apply?" without knowing anything about what you are working on.
 *
 * 🔴 EVERY FUNCTION HERE IS PURE. The CLI owns git, the database and the printing — and in this
 *    case that separation is load-bearing rather than stylistic: the whole point is to report on
 *    OTHER sessions' branches, and the one thing this must never do is touch another session's
 *    worktree. The collector takes an injected runner so the tests never shell out, and the CLI
 *    passes it `git merge-tree`, which computes a merge entirely in memory.
 */

/** Conflicts are reported at ANY distance; a branch 2 behind that conflicts is still broken. */
export const DRIFT_CONFLICT_ALWAYS = true;

/**
 * Behind-count at which a clean-but-stale branch is worth mentioning.
 *
 * ⚠ THIS NUMBER IS CHOSEN, NOT MEASURED, AND SAYING SO IS THE POINT. The lease length in
 *   steward-lease.mjs is 24h because 52 real session transcripts were measured; there is no
 *   equivalent distribution for branch staleness yet. 40 is a default that would have caught
 *   #797 (64 behind) with room to spare while staying quiet for a branch cut this morning.
 *   When a distribution exists, replace this and say so here.
 */
export const DEFAULT_STALE_BEHIND = 40;

/**
 * Classify one branch.
 *
 * @param {object} row
 * @param {string} row.branch            branch name, or null for a detached HEAD
 * @param {number} row.behind            commits on base that the branch lacks
 * @param {number} row.ahead             commits on the branch that base lacks
 * @param {string[]|null} row.conflicts  paths that conflict, [] for none, null for "not computed"
 * @param {string} [row.where]           worktree path, for the operator to find it
 * @param {number} [staleBehind]
 * @returns {{level:'conflicting'|'stale'|'unknown'|'ok', line:string|null}}
 *
 * 🔴 A BRANCH WITH NOTHING ON IT IS NOT DRIFTING, IT IS JUST OLD. `ahead === 0` means there is
 *    no work to lose and no merge to do, so being 400 behind is meaningless — that is every
 *    long-lived checkout of the default branch itself. Reporting those would bury the one row
 *    that matters, which is exactly how a warning stops being read.
 */
export function classifyBranchDrift(row, staleBehind = DEFAULT_STALE_BEHIND) {
  const { branch, behind = null, ahead = null, conflicts = null, where = null } = row || {};
  if (!branch) return { level: 'ok', line: null };        // detached HEAD carries no work to land

  const at = where ? `  ${where}` : '';

  // 🔴 `ahead === 0` MEANS "MEASURED, AND THERE IS NOTHING TO LAND". `ahead === null` MEANS THE
  //    MEASUREMENT FAILED, AND THE TWO MUST NOT SHARE A BRANCH OF THIS FUNCTION. An earlier draft
  //    defaulted a failed rev-list to 0 and this function then reported the branch as 'ok' — a
  //    probe that could not run reading as a probe that found nothing, which is the failure this
  //    whole module is written against. The unit test caught it; it was not caught by reasoning.
  if (ahead === null || behind === null) {
    return { level: 'unknown', line: `  ⚠ ${branch} — position against the base NOT COMPUTED${at}` };
  }
  if (ahead === 0) return { level: 'ok', line: null };     // nothing to lose, nothing to merge

  const dist = `${behind} behind · ${ahead} ahead`;

  if (Array.isArray(conflicts) && conflicts.length > 0) {
    const shown = conflicts.slice(0, 3).join(', ');
    const more = conflicts.length > 3 ? ` +${conflicts.length - 3} more` : '';
    return {
      level: 'conflicting',
      line: `  🔴 ${branch} — ${dist} — CONFLICTS with the base in ${conflicts.length} file(s): ${shown}${more}${at}`,
    };
  }
  if (conflicts === null) {
    return { level: 'unknown', line: `  ⚠ ${branch} — ${dist} — conflict state NOT COMPUTED${at}` };
  }
  if (behind >= staleBehind) {
    return { level: 'stale', line: `  ⚠ ${branch} — ${dist} — no conflicts yet, but merge the base soon${at}` };
  }
  return { level: 'ok', line: null };
}

const RANK = { conflicting: 0, unknown: 1, stale: 2, ok: 3 };

/**
 * Render the block `who` prints. Worst first, and silent when there is nothing to say.
 *
 * ⚠ SILENCE IS A FEATURE. `who` runs at every session start; a section that always prints
 *   something is a section that stops being read, and then the one time it matters it is
 *   scrolled past with the rest.
 */
export function driftLines(rows, { staleBehind = DEFAULT_STALE_BEHIND, baseLabel = 'origin/master', baseAgeHours = null } = {}) {
  const graded = (rows || [])
    .map((r) => ({ r, c: classifyBranchDrift(r, staleBehind) }))
    .filter(({ c }) => c.line)
    .sort((a, b) => RANK[a.c.level] - RANK[b.c.level] || a.r.branch.localeCompare(b.r.branch));

  if (graded.length === 0) return [];

  const out = [`Branch drift against ${baseLabel}:`];
  for (const { c } of graded) out.push(c.line);

  // 🔴 A STALE BASE REF UNDERSTATES EVERY NUMBER ABOVE, AND SILENTLY. This compares against the
  //    LOCAL remote-tracking ref — it does not fetch, because `who` runs at session start and
  //    must not block on the network. CLAUDE.md's most common recorded collision is trusting a
  //    stale worktree (one read 1424 when upstream was at 1464). So the ref's age is printed
  //    whenever it is old enough to matter, rather than being assumed fresh.
  if (baseAgeHours !== null && baseAgeHours >= 6) {
    out.push(`  ⚠ ${baseLabel} here is ${Math.round(baseAgeHours)}h old — run \`git fetch origin\`; these counts are floors, not truths`);
  }
  if (graded.some(({ c }) => c.level === 'conflicting')) {
    out.push('  ▶ A conflicting branch does not get better by waiting. Merge the base into it now,');
    out.push('    in ITS OWN worktree — never by moving HEAD in a worktree you did not create.');
  }
  return out;
}

/**
 * Collect drift for a set of branches.
 *
 * @param {(args:string[]) => string} git  runs git and returns stdout; THROWS on failure
 * @param {object} opts
 * @param {Array<{branch:string, where?:string}>} opts.branches
 * @param {string} [opts.base]
 * @returns {Array<{branch, where, behind, ahead, conflicts}>}
 *
 * 🔴 `merge-tree --write-tree` IS THE ONLY SAFE WAY TO ASK THIS. It computes the merge in
 *    memory and writes nothing — no index, no working tree, no HEAD. Every alternative
 *    (checking the branch out, `git merge --no-commit`, a temporary worktree) would touch a
 *    directory that belongs to another session, which is the very rule this tool enforces.
 *
 * ⚠ A BRANCH WHOSE CONFLICT STATE CANNOT BE COMPUTED REPORTS null, NEVER []. An empty array
 *   means "checked, clean"; null means "not checked". Collapsing the two would turn a broken
 *   probe into a clean bill of health — the failure mode this repo has now recorded three times
 *   (a blind untracked scan, a 503 archive probe, a WAF-blocked sweep all returned "nothing").
 */
export function collectBranchDrift(git, { branches = [], base = 'origin/master' } = {}) {
  const rows = [];
  for (const b of branches) {
    if (!b || !b.branch) continue;
    const row = { branch: b.branch, where: b.where ?? null, behind: null, ahead: null, conflicts: null };
    try {
      const counts = git(['rev-list', '--left-right', '--count', `${base}...${b.branch}`]).trim();
      const [behind, ahead] = counts.split(/\s+/).map((n) => parseInt(n, 10));
      row.behind = Number.isFinite(behind) ? behind : null;
      row.ahead = Number.isFinite(ahead) ? ahead : null;
    } catch {
      rows.push(row);           // ref gone or unreadable: report unknown, never assume clean
      continue;
    }
    if (row.ahead === 0) { row.conflicts = []; rows.push(row); continue; }
    try {
      const out = git(['merge-tree', '--write-tree', '--name-only', base, b.branch]);
      const lines = out.split(/\r?\n/);
      // exit 0 => clean, and stdout is just the tree oid. Non-clean output lists the tree oid,
      // then the conflicted paths, then informational lines.
      const paths = lines.slice(1).filter((l) => l && !/^(Auto-merging|CONFLICT|warning:)/.test(l));
      row.conflicts = paths;
    } catch (e) {
      // merge-tree exits non-zero WHEN THERE ARE CONFLICTS, so a throw is the normal conflict
      // path, not an error path. The paths are still on stdout, which the runner must surface.
      const out = (e && (e.stdout || e.message)) ? String(e.stdout || e.message) : '';
      const lines = out.split(/\r?\n/);
      const paths = lines.slice(1).filter((l) => l && !/^(Auto-merging|CONFLICT|warning:)/.test(l));
      row.conflicts = paths.length ? paths : null;
    }
    rows.push(row);
  }
  return rows;
}
