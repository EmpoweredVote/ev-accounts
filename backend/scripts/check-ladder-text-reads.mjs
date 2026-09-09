#!/usr/bin/env node
/**
 * CI gate: never read ladder TEXT from the frozen tables.
 *
 * ── WHY THIS EXISTS ──────────────────────────────────────────────────────────
 *
 * `CA_0012` **froze the text columns** of `inform.compass_topics` and
 * `inform.compass_stances` when content versioning came in (ADR 0004). The rows and
 * their `id`s remain the stable handles they always were; only the *wording* stopped
 * being maintained there. The live wording lives in:
 *
 *   · `inform.compass_stance_revisions` / `inform.compass_topic_revisions`, keyed by
 *     `topic_revision_id` — this is what a SEASON pins, and therefore what a season's
 *     answers were evidenced against; and
 *   · the `_current` views, which resolve the current revision for you.
 *
 * 🔴 **MEASURED 2026-09-08: 29 OF THE 60 TOPICS IN THE OPEN SEASON DISAGREE between
 * the frozen text and the season pin, 16 of them on ALL FIVE RUNGS** — including
 * `housing`, `growth-and-development`, `economic-development`, `gun-policy` and all
 * six `judicial-*` topics.
 *
 * ── WHY A HUMAN CANNOT BE TRUSTED TO REMEMBER ────────────────────────────────
 *
 * The frozen table returns a **complete, plausible five-rung ladder on the right
 * subject**. Nothing errors, nothing is empty, and for `housing` the *question text
 * is identical* while every single rung differs. A wrong ladder and a right ladder
 * look the same until you diff them.
 *
 * That is not hypothetical. On 2026-09-08 a whole-Board stance pass read the frozen
 * text for six topics, and briefly concluded that five PUBLISHED rows were mis-seated
 * — because the frozen rung 3 ("targeted help like subsidies for affordable
 * projects") describes exactly what those rows argue, while the pinned rung 3
 * ("binding rules on the private market") does not. The rows were right; the query
 * was wrong. Two of that day's refusals had to be re-tested and their rung tables
 * corrected.
 *
 * 🟢 **THE PRODUCT WAS NEVER AFFECTED, AND THAT IS THE POINT OF SCOPE HERE.** Every
 * voter-facing read already goes through the versioned source. This gate exists to
 * stop RESEARCH and REPORTING queries drifting onto the frozen columns, because that
 * is where it actually happened.
 *
 * ── WHAT IT FLAGS ────────────────────────────────────────────────────────────
 *
 * A SQL literal (or a PostgREST `.from()` call) that touches `inform.compass_stances`
 * or `inform.compass_topics` **and reads one of the frozen text columns** — `text`,
 * `title`, `short_title`, `question_text` — without also naming a versioned source.
 *
 * ⚠ **READS ONLY. Writes are exempt, which is the opposite of
 * `check-answer-season-consumers`, and deliberately so.** There, a cross-season WRITE
 * is the unfixable bug and the marker is refused on one. Here it inverts: writing to
 * the frozen row is how the admin editor maintains it, while READING its text is the
 * defect. Same machinery, opposite polarity — do not copy one rule into the other.
 *
 * ── THE HATCH ────────────────────────────────────────────────────────────────
 *
 * Some reads legitimately want the frozen text — a migration comparing v1 against a
 * proposed rewrite, for instance. Say so in the literal, with a reason:
 *
 *   -- @ladder-text: frozen-ok — the rewrite workflow diffs OLD text against the
 *   --   proposal, so the frozen v1 wording is the thing being compared.
 *
 * A bare marker is refused; it must carry a reason, exactly as `@season-scope` and
 * `@answer-delete-guards` do.
 *
 * ── THE BASELINE ─────────────────────────────────────────────────────────────
 *
 * Legacy scripts already read the frozen columns. Rather than start red and stay
 * red — a gate nobody can land is a gate nobody keeps — the known offenders are
 * recorded in BASELINE below and the gate fails only when the count RISES. The
 * baseline is printed on every run so it can be worked down, and 🔴 **it must never
 * be raised to make a new offender pass** — that is the same rule as the season
 * floor and the stance-source baselines.
 *
 * RUN: npm run check:ladder-text --prefix backend
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..');

/** The two tables whose text columns CA_0012 froze. */
const FROZEN_TABLE = /inform\.compass_(?:stances|topics)\b/i;

/** PostgREST form: `.from('compass_stances')`. The closing quote is a backreference. */
const FROZEN_POSTGREST = /\.\s*from\s*\(\s*(['"`])(compass_stances|compass_topics)\1/gi;

/**
 * A frozen text column being read.
 *
 * The optional `\w+\.` allows an alias (`s.text`, `cs.title`) while the negative
 * lookbehind keeps `::text` casts and `foo_text` identifiers out — the character
 * before the match may not be a colon or a word character.
 */
const FROZEN_TEXT_COL = /(?<![:\w])(?:\w+\.)?(?:text|title|short_title|question_text)\b/i;

/** Any versioned source. Generous on purpose: naming one means the author knew. */
const VERSIONED = /compass_stance_revisions|compass_topic_revisions|compass_stances_current|compass_topics_current|topic_revision_id|season_questions/i;

/** A literal that modifies rows. Maintaining the frozen row is not the defect. */
const IS_WRITE = /\b(?:insert\s+into|update\s+inform\.|delete\s+from|create\s+(?:or\s+replace\s+)?view)\b/i;

/** The hatch. A reason is required; a bare marker is refused. */
const MARKER = /@ladder-text:\s*frozen-ok\s*(?:—|--|-|:)?\s*(\S.*)?/i;

/**
 * Known offenders at the moment this gate landed, read from a sidecar file.
 *
 * 🔴 IT IS GENERATED, NOT HAND-WRITTEN — `--update-baseline` measures and writes it.
 * A hand-typed baseline is a guess, and a guessed baseline either hides a real
 * offender or blocks an innocent file. Regenerate it only when you have LOWERED a
 * count; **never to make a new offender pass.** Same rule as the season floor.
 *
 * Most entries are one-off `gen-*` and `verify-*` scripts that already ran. They are
 * harmless where they sit — like the applied migrations CLAUDE.md warns not to copy —
 * but they are exactly the wrong thing to copy, which is why they stay listed rather
 * than being globbed out of scope.
 */
const BASELINE_FILE = path.join(HERE, 'lib', 'ladder-text-baseline.json');
const BASELINE = fs.existsSync(BASELINE_FILE)
  ? JSON.parse(fs.readFileSync(BASELINE_FILE, 'utf8'))
  : {};

const SCAN_DIRS = ['src', 'scripts'];
const SKIP_DIR = /node_modules|\.git|dist|build|coverage/;
const CODE_EXT = /\.(ts|mts|mjs|js)$/;

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, e.name);
    if (SKIP_DIR.test(full)) continue;
    if (e.isDirectory()) walk(full, out);
    else if (CODE_EXT.test(e.name)) out.push(full);
  }
  return out;
}

/**
 * Every backtick literal in the source, with the 1-indexed line it starts on.
 * Nested `${...}` containing a backtick will split a literal early; that is
 * conservative in the safe direction, since a split piece is judged on its own.
 */
function literals(src) {
  const out = [];
  const re = /`([^`]*)`/gs;
  let m;
  while ((m = re.exec(src)) !== null) {
    out.push({ body: m[1], line: src.slice(0, m.index).split('\n').length });
  }
  return out;
}

function markerVerdict(raw) {
  const m = MARKER.exec(raw);
  if (!m) return null;
  return m[1] && m[1].trim().length > 3 ? 'ok' : 'no-reason';
}

const offenders = [];
for (const dir of SCAN_DIRS) {
  const abs = path.join(ROOT, dir);
  if (!fs.existsSync(abs)) continue;
  for (const file of walk(abs)) {
    const rel = path.relative(ROOT, file).replace(/\\/g, '/');
    if (rel.endsWith('check-ladder-text-reads.mjs')) continue;      // this file quotes the names
    if (rel.endsWith('.test.ts') || rel.endsWith('.test.mts')) continue;
    const src = fs.readFileSync(file, 'utf8');

    for (const { body, line } of literals(src)) {
      if (!FROZEN_TABLE.test(body)) continue;
      if (IS_WRITE.test(body)) continue;
      if (VERSIONED.test(body)) continue;
      if (!FROZEN_TEXT_COL.test(body)) continue;
      const verdict = markerVerdict(body);
      if (verdict === 'ok') continue;
      offenders.push({
        rel, line,
        why: verdict === 'no-reason'
          ? '@ladder-text: frozen-ok with no stated reason — say why, in the literal'
          : 'reads frozen ladder text without naming a versioned source',
      });
    }

    // PostgREST builder calls carry no SQL literal to inspect.
    let pm;
    FROZEN_POSTGREST.lastIndex = 0;
    while ((pm = FROZEN_POSTGREST.exec(src)) !== null) {
      const line = src.slice(0, pm.index).split('\n').length;
      const window = src.slice(pm.index, pm.index + 600);
      if (VERSIONED.test(window)) continue;
      if (!FROZEN_TEXT_COL.test(window)) continue;
      if (markerVerdict(window) === 'ok') continue;
      offenders.push({ rel, line, why: `PostgREST .from('${pm[2]}') selecting frozen text` });
    }
  }
}

const byFile = {};
for (const o of offenders) (byFile[o.rel] ||= []).push(o);

if (process.argv.includes('--update-baseline')) {
  const next = {};
  for (const rel of Object.keys(byFile).sort()) next[rel] = byFile[rel].length;
  fs.mkdirSync(path.dirname(BASELINE_FILE), { recursive: true });
  fs.writeFileSync(BASELINE_FILE, JSON.stringify(next, null, 2) + String.fromCharCode(10));
  console.log(`wrote baseline: ${Object.keys(next).length} file(s), ${offenders.length} read(s) -> ${path.relative(ROOT, BASELINE_FILE)}`);
  process.exit(0);
}

const rising = [];
for (const [rel, list] of Object.entries(byFile)) {
  const allowed = BASELINE[rel] ?? 0;
  if (list.length > allowed) rising.push({ rel, found: list.length, allowed, list });
}
const fixed = Object.entries(BASELINE).filter(([rel, n]) => (byFile[rel]?.length ?? 0) < n);

console.log(`ladder text reads — ${offenders.length} across ${Object.keys(byFile).length} file(s)`);
for (const [rel, list] of Object.entries(byFile).sort()) {
  const allowed = BASELINE[rel] ?? 0;
  const flag = list.length > allowed ? '🔴' : '  ';
  console.log(`${flag} ${rel.padEnd(48)} ${String(list.length).padStart(2)}  (baseline ${allowed})`);
}

if (fixed.length) {
  console.log('\n🟢 Baseline can be LOWERED — these improved:');
  for (const [rel, n] of fixed) console.log(`   ${rel}: ${byFile[rel]?.length ?? 0} now, baseline says ${n}`);
}

if (rising.length) {
  console.error('\n🔴 NEW reads of FROZEN ladder text:\n');
  for (const r of rising) {
    for (const o of r.list) console.error(`  ${o.rel}:${o.line} — ${o.why}`);
  }
  console.error(`
CA_0012 froze compass_topics/compass_stances' TEXT columns (ADR 0004). 29 of the 60
topics in the open season disagree with the season pin, 16 on all five rungs — and the
frozen table returns a complete, plausible ladder, so nothing will error.

Read the pinned wording instead:

  SELECT sr.value, sr.text
    FROM inform.season_questions sq
    JOIN inform.seasons se ON se.id = sq.season_id AND se.status = 'open'
    JOIN inform.compass_topics t ON t.id = sq.topic_id AND t.topic_key = $1
    JOIN inform.compass_stance_revisions sr ON sr.topic_revision_id = sq.topic_revision_id
   ORDER BY sr.value;

…or the _current views if you want the current revision rather than a season's pin.
If you genuinely want the frozen v1 text, say so in the literal with a reason:

  -- @ladder-text: frozen-ok — <why the v1 wording is the thing you want>

🔴 Do NOT raise the baseline to make this pass.`);
  process.exit(1);
}

console.log('\nOK — no new reads of frozen ladder text.');
