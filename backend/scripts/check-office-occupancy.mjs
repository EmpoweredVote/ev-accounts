#!/usr/bin/env node
/**
 * Fail if code added on this branch writes occupancy onto `essentials.offices`.
 *
 * ADR 0002 (docs/adr/0002-temporal-officeholder-terms.md) made `essentials.office_terms` the only
 * source of officeholder occupancy, and phase 5 dropped `essentials.offices.politician_id`.
 * `essentials.offices` is now a SEAT: district + chamber + title, with no occupant.
 *
 * There are two failure modes and this guard only catches the first:
 *
 *   1. LOUD  — referencing `offices.politician_id` at all. The column is gone, so this is a
 *              42703 undefined_column at runtime. Cheap to catch here instead.
 *   2. SILENT — inserting a row into `essentials.offices` and never writing an `office_terms`
 *              row. Nothing errors; the official is simply invisible everywhere. Individually
 *              valid code, so it cannot be caught by pattern-matching with any confidence.
 *              Watch `essentials.offices_missing_terms` for that one (see migration 1464).
 *
 * A THIRD rule, same family (added 2026-09-23, CA_0188): an INSERT into `essentials.politicians`
 * whose column list does not name `is_incumbent`. That flag is a CACHED occupancy fact — the
 * incumbents-only reads filter on it — and it defaulted to TRUE, so every insert that left it out
 * created an "incumbent" holding no seat: 1,817 active rows by 2026-09-23 (cleared by
 * CA_0181-CA_0187). CA_0188 flips the default to false, which moves the failure to the other side:
 * a seated person inserted without the flag is now HIDDEN from address search (the reachability
 * check's REPS_FILTER_HIDDEN catches that one, but only after the write reaches prod). Neither
 * default is safe to rely on, so the rule is: say it. `true` when you seat someone, `false` for a
 * candidate. The ~55 historical generators that omit it are not flagged unless someone edits one.
 *
 * Deliberately scoped to files ADDED OR MODIFIED on this branch. History is full of one-off
 * seeders that legitimately wrote the column when it existed; rewriting them would be dishonest
 * about what actually ran against prod.
 *
 * WHY AN --all MODE EXISTS. Branch-scoping is right for the gate, but it means a pre-existing
 * backlog is invisible: on 2026-07-26 a sweep found 93 files still reading the dropped column,
 * four of them RE-RUNNABLE evidence artifacts that had been silently broken since migration 1463
 * — including the two dual-map smokes that back the 164.1/164.2 proofs. Nothing surfaced that,
 * because none of them were ever touched on a branch again.
 *
 * `--all` scans every tracked file and splits the result in two, because the two halves deserve
 * different treatment:
 *   * ACTIONABLE  — re-runnable evidence artifacts (*-verify.sql, *-smoke*.ts). These are supposed
 *                   to run green on demand, so a hit here is a live defect. Exits non-zero.
 *   * INVENTORY   — one-off seeders and diagnostics that already ran against prod when the column
 *                   existed. Rewriting them would be dishonest about what actually ran, so these
 *                   are listed and NOT failed. Making them red by default would only train people
 *                   to ignore the guard.
 *
 * Usage:
 *   node scripts/check-office-occupancy.mjs              # branch-scoped gate (CI)
 *   node scripts/check-office-occupancy.mjs --all        # full-repo inventory + actionable gate
 *   BASE_REF=origin/main node scripts/check-office-occupancy.mjs
 */
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import path from "node:path";

const SCANNED_DIRS = ["backend/migrations", "backend/src", "backend/scripts"];
const SCANNED_EXT = new Set([".sql", ".ts", ".tsx", ".js", ".mjs", ".cjs", ".py"]);

// This file documents the forbidden pattern, so it would always match itself. Its test holds the
// pattern as fixtures on purpose; scanned, it would fail every PR that touches it.
const SELF = new Set([
  "backend/scripts/check-office-occupancy.mjs",
  "backend/scripts/check-office-occupancy.test.ts",
]);

const repoRoot = execFileSync("git", ["rev-parse", "--show-toplevel"], { encoding: "utf8" }).trim();
const git = (args) => execFileSync("git", args, { cwd: repoRoot, encoding: "utf8" }).trim();
const tryGit = (args) => {
  try {
    return git(args);
  } catch {
    return null;
  }
};

function resolveBase() {
  if (process.env.BASE_REF) return process.env.BASE_REF;
  for (const ref of ["origin/master", "origin/main", "master", "main"]) {
    if (tryGit(["rev-parse", "--verify", "--quiet", ref])) return ref;
  }
  return null;
}

function changedFiles(base) {
  const sets = [];
  if (base) {
    const mergeBase = tryGit(["merge-base", base, "HEAD"]) || base;
    // A|M rather than A: editing an existing seeder to use the dropped column is the likelier slip.
    sets.push(tryGit(["diff", "--diff-filter=AM", "--name-only", `${mergeBase}..HEAD`, "--", ...SCANNED_DIRS]));
  }
  sets.push(tryGit(["diff", "--cached", "--diff-filter=AM", "--name-only", "--", ...SCANNED_DIRS]));
  sets.push(tryGit(["diff", "--diff-filter=AM", "--name-only", "--", ...SCANNED_DIRS]));
  sets.push(tryGit(["ls-files", "--others", "--exclude-standard", "--", ...SCANNED_DIRS]));
  return [...new Set(sets.flatMap((s) => (s ? s.split("\n") : [])).filter(Boolean))]
    .filter((f) => SCANNED_EXT.has(path.extname(f)))
    .filter((f) => !SELF.has(f));
}

// Strip line comments and block comments so a note ABOUT the old column isn't a violation.
// A block comment becomes the newlines it held, not "": violations report
// `code.slice(0, m.index).split("\n").length`, so deleting those newlines reported every hit after a
// multi-line block too low (senate-candidate-fec.ts:263 for a join on line 291, 2026-09-23).
function stripComments(src) {
  return src
    .replace(/\/\*[\s\S]*?\*\//g, (block) => block.replace(/[^\n]/g, ""))     // /* ... */
    .split("\n")
    .map((line) => line.replace(/(--|\/\/|#)\s.*$/, ""))
    .join("\n");
}

// Precise rules only. An earlier draft used proximity ("essentials.offices within 400 chars of
// politician_id") and produced nothing but false positives: the window jumped statement boundaries
// and happily matched `office_terms.politician_id`, `och.politician_id` and the `p_politician_id`
// parameter of the seat_officeholder helper. Proximity cannot distinguish those, so it is gone.
const PATTERNS = [
  {
    // The offices alias convention in this repo is `o`, and NUMBERED variants (`o2`, `o3`) and
    // suffixed ones (`ox`) are common in multi-join gates — the 2026-07-26 sweep hit `o2` and `ox`
    // in verify-phase-120/120-124 that the original `o|off|offices` pattern walked straight past,
    // leaving those files still broken after a "complete" port. Hence `o[0-9a-z]*`.
    // `och.`/`coh.`/`t.`/`ot.` are the view and office_terms and are correct, so they must not
    // match: `och` and its numbered variants are excluded by the negative lookahead below. Note
    // `(?!och\b)` is NOT enough — \b does not stop at a digit, so `och2.politician_id` slipped
    // through as a false positive; the lookahead must be `och[0-9]*\b`.
    // \b would fire mid-identifier on `och.politician_id`, hence the explicit preceding-char guard.
    //
    // 🔴 `ot` ADDED TO THE LOOKAHEAD 2026-08-17 — the comment above already CLAIMED `ot.` was
    // excluded, but the implementation did not do it: `o[0-9a-z]*` swallows `ot`, so every
    // `ot.politician_id` (the conventional office_terms alias) was a false positive. It went
    // unnoticed for a year because this guard scans only files CHANGED vs origin/master, and
    // `ot.politician_id` already appears in at least ten COMMITTED migrations that CI has always
    // passed — 1458 (the office_terms schema itself), 1460, 1496, 1543-1545, 1548, 1566-1568.
    // Migration 1822 was simply the first NEW file to use the repo's own alias.
    // This narrows nothing: office_terms.politician_id is the column ADR 0002 tells you to read.
    // Numbered variants are covered for the same reason `och[0-9]*` is.
    re: /(^|[^\w.])(?!(?:och|ot)[0-9]*\b)(?:o[0-9a-z]*|off|offices)\.politician_id\b/gi,
    why: "reads <offices alias>.politician_id — the column no longer exists",
  },
  {
    // INSERT INTO essentials.offices ( ... politician_id ... )  -- only the column list
    re: /INSERT\s+INTO\s+essentials\.offices\s*\([^)]*\bpolitician_id\b/gi,
    why: "inserts politician_id into essentials.offices",
  },
  {
    // UPDATE essentials.offices [alias] SET ... politician_id = ...
    // Scans ONLY the assignment list: stops at FROM/WHERE/RETURNING/;, so a legitimate
    // `... FROM essentials.office_current_holder och WHERE och.politician_id = $2` is not a hit.
    // The [^\w.] guard also keeps any qualified `x.politician_id` from counting as an assignment.
    re: /UPDATE\s+essentials\.offices\b[\s\S]{0,80}?\bSET\b((?:(?!\bFROM\b|\bWHERE\b|\bRETURNING\b|;)[\s\S])*?)(^|[^\w.])politician_id\s*=/gi,
    why: "sets politician_id on essentials.offices",
  },
  {
    // DELETE FROM essentials.offices WHERE politician_id = ...
    re: /DELETE\s+FROM\s+essentials\.offices\b(?![\s\S]{0,120}?USING)[\s\S]{0,120}?\bWHERE\b[^;]*?\bpolitician_id\b/gi,
    why: "filters essentials.offices on politician_id",
  },
];

const SCAN_ALL = process.argv.includes("--all");

/**
 * Gate-shaped files: verification gates and coordinate smokes. Two naming conventions exist —
 * the modern `NNN-verify.sql` / `NNN-coordinate-smoke.ts` and the older `verify-phase-NNN.sql` /
 * `verify-*.ts`. Both count; matching only the modern one under-reports badly (it scored 0
 * actionable on a repo holding a dozen broken `verify-phase-*.sql` gates).
 */
const isGateShaped = (rel) => {
  const f = path.basename(rel);
  return /^verify[-_]/.test(f) || /-verify\.(sql|ts)$/.test(f) || /smoke/.test(f);
};

function allTrackedFiles() {
  const out = tryGit(["ls-files", "--", ...SCANNED_DIRS]) || "";
  return out
    .split("\n")
    .filter(Boolean)
    .filter((f) => SCANNED_EXT.has(path.extname(f)))
    .filter((f) => !SELF.has(f));
}

// The column list of an INSERT into essentials.politicians (not politician_* tables: `\s*\(` must
// follow the exact name). Only the parenthesised form is checked; an INSERT with no column list
// fills columns by position and is too rare here to pattern-match with confidence.
const POLITICIAN_INSERT = /INSERT\s+INTO\s+essentials\.politicians\s*\(([^)]*)\)/gi;

const base = SCAN_ALL ? null : resolveBase();
const files = SCAN_ALL ? allTrackedFiles() : changedFiles(base);
const violations = [];
const incumbentViolations = [];

for (const rel of files) {
  let src;
  try {
    src = readFileSync(path.join(repoRoot, rel), "utf8");
  } catch {
    continue; // deleted between diff and read
  }
  const code = stripComments(src);
  for (const { re, why } of PATTERNS) {
    re.lastIndex = 0;
    const m = re.exec(code);
    if (m) {
      const line = code.slice(0, m.index).split("\n").length;
      violations.push({ rel, line, why, snippet: m[0].replace(/\s+/g, " ").slice(0, 120) });
      break; // one finding per file is enough to act on
    }
  }
  if (!SCAN_ALL) {
    POLITICIAN_INSERT.lastIndex = 0;
    let m;
    while ((m = POLITICIAN_INSERT.exec(code)) !== null) {
      if (/\bis_incumbent\b/i.test(m[1])) continue;
      const line = code.slice(0, m.index).split("\n").length;
      incumbentViolations.push({ rel, line, snippet: m[0].replace(/\s+/g, " ").slice(0, 120) });
      break; // one finding per file is enough to act on
    }
  }
}

// --all is an INVENTORY plus a narrow gate, not the branch gate. Report both halves, then fail
// only on the re-runnable evidence artifacts.
if (SCAN_ALL) {
  const isMigration = (rel) => rel.startsWith("backend/migrations/");
  const migrations = violations.filter((v) => isMigration(v.rel));
  const rest = violations.filter((v) => !isMigration(v.rel));
  const gates = rest.filter((v) => isGateShaped(v.rel));
  const oneOffs = rest.filter((v) => !isGateShaped(v.rel));

  console.log(`Full-repo occupancy inventory — ${files.length} tracked file(s) scanned, ${violations.length} still read the dropped column.\n`);

  // Migrations are the append-only record of what actually ran against prod back when the column
  // existed. They are EXPECTED here and are never a defect; listing all 200+ would bury the signal.
  console.log(`MIGRATIONS (${migrations.length}) — expected and correct. Each is the record of a`);
  console.log("  write that really happened while the column existed; they are applied once, ad hoc,");
  console.log("  and never replayed, so a dropped column cannot break them. Not listed individually.");

  console.log(`\nONE-OFF SEEDERS / DIAGNOSTICS (${oneOffs.length}) — ran once against prod while the`);
  console.log("  column existed. Leave them: rewriting history would misrepresent what actually ran.");
  for (const v of oneOffs) console.log(`    ${v.rel}:${v.line}`);

  console.log(`\nGATE-SHAPED (${gates.length}) — verification gates and coordinate smokes. These are`);
  console.log("  the ones that MIGHT still be cited as live evidence. Most belong to long-closed");
  console.log("  milestones and are fine to leave; port one the moment a phase needs to re-run it.");
  for (const v of gates) console.log(`    ${v.rel}:${v.line}`);

  console.log("\nTo port:  JOIN essentials.office_current_holder och ON och.office_id = o.id");
  console.log("          (one row per office, so THIS direction cannot fan out; COUNT() skips a");
  console.log("           vacancy's NULL. Joining from politicians instead CAN fan out — see above.)");
  // Deliberately exit 0. This is an INVENTORY, not a gate — the branch-scoped default is the gate.
  // A permanently-red command is a command people learn to ignore, and every hit below is a
  // legitimately-unfixed historical artifact until someone actually needs to re-run it.
  console.log("\n(Inventory only — exits 0. The branch-scoped default run is the enforcing gate.)");
  process.exit(0);
}

if (incumbentViolations.length > 0) {
  console.error("INSERT into essentials.politicians without an explicit is_incumbent.\n");
  for (const v of incumbentViolations) {
    console.error(`  ${v.rel}:${v.line}`);
    console.error(`      ${v.snippet}`);
  }
  console.error("\nis_incumbent is what the incumbents-only reads filter on. Its default was TRUE until");
  console.error("CA_0188 (1,817 seatless 'incumbents' followed) and is FALSE now (a seated person left");
  console.error("without it is hidden from address search). Name the column and give the value you mean:");
  console.error("  true  — this row is being SEATED (and write its office_terms row: seat_officeholder)");
  console.error("  false — a candidate, a former officeholder, a committee-named discovery row\n");
  if (violations.length === 0) process.exit(1);
}

if (violations.length > 0) {
  console.error("essentials.offices.politician_id was dropped (ADR 0002 phase 5, migration 1463).");
  console.error("essentials.offices is a SEAT and holds no occupant. Occupancy lives in");
  console.error("essentials.office_terms and is read via essentials.office_current_holder.\n");
  for (const v of violations) {
    console.error(`  ${v.rel}:${v.line} — ${v.why}`);
    console.error(`      ${v.snippet}`);
  }
  console.error("\nTo READ who holds a seat:");
  console.error("  JOIN essentials.office_current_holder och ON och.office_id = o.id   -- or");
  console.error("  JOIN essentials.office_current_holder och ON och.politician_id = p.id");
  console.error("  (one row per OFFICE — so the first cannot fan out, and the SECOND CAN: a person");
  console.error("   may hold two offices, and office_terms' exclusion constraint cannot see that.");
  console.error("   Politician-rooted reads need DISTINCT ON (p.id) or a deliberately chosen office.)");
  console.error("\nTo SEAT someone (closes the predecessor's term, idempotent):");
  console.error("  SELECT essentials.seat_officeholder(office_id, politician_id, term_start, source);");
  console.error("To VACATE a seat with no successor:");
  console.error("  SELECT essentials.vacate_office(office_id, first_vacant_day, source);");
  console.error("\nIf a filter really needs `AND o.is_vacant = false`, keep it on the MATCH via a");
  console.error("derived join — 5 offices hold a term while flagged vacant, and filtering after the");
  console.error("match emits a spurious all-NULL office row. See campaignFinanceSearchService.ts.");
  process.exit(1);
}

console.log(
  `Office occupancy OK — ${files.length} changed file(s) scanned, no writes to offices.politician_id, ` +
    `every politicians INSERT names is_incumbent.` +
    (base ? "" : " (no git base; scanned working tree only)"),
);
