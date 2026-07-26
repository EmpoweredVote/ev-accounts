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
 * Deliberately scoped to files ADDED OR MODIFIED on this branch. History is full of one-off
 * seeders that legitimately wrote the column when it existed; rewriting them would be dishonest
 * about what actually ran against prod.
 *
 * Usage:
 *   node scripts/check-office-occupancy.mjs
 *   BASE_REF=origin/main node scripts/check-office-occupancy.mjs
 */
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import path from "node:path";

const SCANNED_DIRS = ["backend/migrations", "backend/src", "backend/scripts"];
const SCANNED_EXT = new Set([".sql", ".ts", ".tsx", ".js", ".mjs", ".cjs", ".py"]);

// This file documents the forbidden pattern, so it would always match itself.
const SELF = "backend/scripts/check-office-occupancy.mjs";

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
    .filter((f) => f !== SELF);
}

// Strip line comments and block comments so a note ABOUT the old column isn't a violation.
function stripComments(src) {
  return src
    .replace(/\/\*[\s\S]*?\*\//g, "")     // /* ... */
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
    // The offices alias convention in this repo is `o` (occasionally `off`/`offices`).
    // `och.`/`coh.`/`t.`/`ot.` are the view and office_terms and are correct, so they must not match:
    // \b would fire mid-identifier on `och.politician_id`, hence the explicit preceding-char guard.
    re: /(^|[^\w.])(?:o|off|offices)\.politician_id\b/gi,
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

const base = resolveBase();
const files = changedFiles(base);
const violations = [];

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
  console.error("  (one row per office, so it cannot fan out)");
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
  `Office occupancy OK — ${files.length} changed file(s) scanned, no writes to offices.politician_id.` +
    (base ? "" : " (no git base; scanned working tree only)"),
);
