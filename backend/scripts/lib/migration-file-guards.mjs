/**
 * The two things a migration RUNNER has to decide about a file before it touches prod:
 * where the file's own transaction is, and whether any DROP in it destroys something real.
 *
 * Extracted from apply-migration-file.mjs and dry-run-migration.mjs on 2026-09-09, which had
 * the strip logic duplicated inline and — in the applier — a DROP guard that refused the
 * house style.
 *
 * ── 🔴 WHY THE DROP GUARD HAD TO CHANGE ──────────────────────────────────────────────────
 *
 * The applier refused any file matching /DROP\s+(TABLE|SCHEMA|DATABASE)/. The house style
 * for a post-verify gate is to CREATE TEMP TABLE for the before-snapshot and DROP it at the
 * end, so the guard refused the very shape CLAUDE.md asks for: measured 2026-09-09, **9 of
 * the 11 migrations in this repo that contain DROP TABLE only drop temp tables they created
 * themselves**, CC_0083 and CC_0084 among them.
 *
 * That is not a harmless false positive. The applier's own header explains that it exists so
 * nobody hand-pastes a migration body through another channel — and being refused is exactly
 * what sends someone back to hand-pasting. It happened in this session: a throwaway runner got
 * written because the safe one would not take the file.
 *
 * The distinction the guard actually wants is TEMP vs REAL, and SQL makes it easy:
 *   * a temp table is always UNQUALIFIED — `CREATE TEMP TABLE _cc0083_want`
 *   * a real table worth protecting is qualified — the two files that legitimately trip this
 *     guard drop `app_auth.sessions` and `app_auth.users` (1818, 1819)
 *
 * So: a DROP TABLE is allowed only when every name it lists is unqualified AND appears in a
 * CREATE TEMP TABLE in the same file. DROP SCHEMA and DROP DATABASE are never allowed.
 *
 * ⚠ THE CREATE MAY COME AFTER THE DROP. The house style opens with
 * `DROP TABLE IF EXISTS _ccNNNN_want;` so a re-run on a pooled connection cannot trip over a
 * leftover, and creates it below. So this scans the WHOLE file for creations rather than only
 * what precedes each drop.
 */

/**
 * SQL with line comments, block comments and single-quoted strings blanked out, so a DROP
 * mentioned in prose cannot look like a statement.
 *
 * 🔴 THIS IS NOT COSMETIC. Migration 1818 raises
 * `'Aborting: app_auth.sessions still exists after DROP TABLE.'` — a guard reading raw text
 * sees a DROP TABLE there with no parseable target. Every migration in this repo also carries
 * a long `--` header, and several of those headers quote the SQL they are about.
 *
 * Dollar-quoted bodies ($$ ... $$) are deliberately KEPT: that is where a migration's DO
 * blocks live, and a DROP inside one is a real statement.
 */
export function stripCommentsAndStrings(sql) {
  let out = '';
  let i = 0;
  const n = sql.length;
  while (i < n) {
    const two = sql.slice(i, i + 2);
    if (two === '--') {
      const j = sql.indexOf('\n', i);
      i = j === -1 ? n : j;                       // keep the newline, drop the comment
      continue;
    }
    if (two === '/*') {
      const j = sql.indexOf('*/', i + 2);
      i = j === -1 ? n : j + 2;
      out += ' ';
      continue;
    }
    if (sql[i] === "'") {
      let j = i + 1;
      while (j < n) {
        if (sql[j] === "'" && sql[j + 1] === "'") { j += 2; continue; }  // escaped quote
        if (sql[j] === "'") { j += 1; break; }
        j += 1;
      }
      i = j;
      out += "''";                                 // an empty literal keeps the syntax shape
      continue;
    }
    out += sql[i];
    i += 1;
  }
  return out;
}

/** Unqualified names created as TEMP tables anywhere in the file, lower-cased. */
export function tempTablesCreated(sql) {
  const code = stripCommentsAndStrings(sql);
  const re = /\bCREATE\s+(?:GLOBAL\s+|LOCAL\s+)?TEMP(?:ORARY)?\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([A-Za-z_][\w$]*)/gi;
  const out = new Set();
  for (const m of code.matchAll(re)) out.add(m[1].toLowerCase());
  return out;
}

const stripDecoration = (name) =>
  name.replace(/\b(CASCADE|RESTRICT)\b/gi, '').replace(/["\s]/g, '');

/**
 * Everything in this file whose DROP would destroy something that is not its own temp table.
 * An empty array means the file is safe for a runner to execute.
 *
 * Each entry is {kind, target, reason} so a caller can print WHICH object it refused on —
 * "refusing: migration contains a DROP" sends the reader back to grep.
 */
export function unsafeDropTargets(sql) {
  const code = stripCommentsAndStrings(sql);
  const temps = tempTablesCreated(sql);
  const out = [];

  for (const m of code.matchAll(/\bDROP\s+(SCHEMA|DATABASE)\s+(?:IF\s+EXISTS\s+)?([^\s;]+)/gi)) {
    out.push({ kind: m[1].toUpperCase(), target: stripDecoration(m[2]), reason: 'a runner must never drop a schema or database' });
  }

  for (const m of code.matchAll(/\bDROP\s+TABLE\s+(?:IF\s+EXISTS\s+)?([^;]+);/gi)) {
    for (const raw of m[1].split(',')) {
      const name = stripDecoration(raw);
      if (!name) continue;
      if (name.includes('.')) {
        out.push({ kind: 'TABLE', target: name, reason: 'qualified name, so not a temp table' });
      } else if (!temps.has(name.toLowerCase())) {
        out.push({ kind: 'TABLE', target: name, reason: 'this file never creates it as a TEMP table' });
      }
    }
  }
  return out;
}

/**
 * The file with its own outermost BEGIN;/COMMIT; removed, so the RUNNER owns the transaction
 * and can roll back whatever the file would have committed.
 *
 * ⚠ ONLY THE FIRST of each, and only line-anchored — matching what both scripts did inline
 *   before this was extracted. A migration with a second COMMIT in the middle is not a shape
 *   this repo writes, and silently removing one would be worse than failing loudly.
 */
export function stripOwnTransaction(sql) {
  return sql.replace(/^\s*BEGIN\s*;/im, '').replace(/^\s*COMMIT\s*;/im, '');
}

/** True when the file manages its own transaction, which is the house style. */
export function ownsItsTransaction(sql) {
  const code = stripCommentsAndStrings(sql);
  return /^\s*BEGIN\s*;/im.test(code) && /^\s*COMMIT\s*;/im.test(code);
}
