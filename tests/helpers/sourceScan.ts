/**
 * Shared helpers for the static-analysis architecture guards.
 *
 * Both guards (dual-client constraint, coordinate leakage) scan source text for
 * forbidden patterns. Raw `content.includes(...)` over raw file text produces two
 * classes of false positive that made both guards fail permanently — and a guard
 * that is always red enforces nothing:
 *
 *   1. Comments that DOCUMENT the rule. `routes/admin.ts` says "delegated to
 *      adminService to avoid supabaseAdmin in routes — architecture rule". The
 *      file complies and was still reported as a violation.
 *   2. Test files. `vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {} }))`
 *      mocks the client away; `.send({ lat, lng })` is a request fixture for the
 *      coordinate-lookup endpoint. Neither ships in a route handler.
 *
 * So: scan shipped source only, with comments stripped.
 */

import fs from 'fs';
import path from 'path';

/**
 * Remove line and block comments while preserving string and template-literal
 * contents, so a `//` inside a URL literal does not swallow the rest of the line.
 * Not a full parser — it does not track regex literals — but sufficient for the
 * identifier and SQL-fragment matching these guards do.
 */
export function stripComments(source: string): string {
  let out = '';
  let i = 0;
  type State = 'code' | 'line' | 'block' | 'single' | 'double' | 'template';
  let state: State = 'code';

  while (i < source.length) {
    const c = source[i];
    const next = source[i + 1];

    switch (state) {
      case 'code':
        if (c === '/' && next === '/') { state = 'line'; i += 2; continue; }
        if (c === '/' && next === '*') { state = 'block'; i += 2; continue; }
        if (c === "'") state = 'single';
        else if (c === '"') state = 'double';
        else if (c === '`') state = 'template';
        out += c;
        i += 1;
        continue;

      case 'line':
        if (c === '\n') { state = 'code'; out += c; }
        i += 1;
        continue;

      case 'block':
        if (c === '*' && next === '/') { state = 'code'; i += 2; continue; }
        // Keep newlines so reported line numbers stay meaningful.
        if (c === '\n') out += c;
        i += 1;
        continue;

      case 'single':
      case 'double':
      case 'template': {
        const quote = state === 'single' ? "'" : state === 'double' ? '"' : '`';
        if (c === '\\') { out += c + (next ?? ''); i += 2; continue; }
        if (c === quote) state = 'code';
        out += c;
        i += 1;
        continue;
      }
    }
  }

  return out;
}

/** True for spec/test files, which are not shipped route code. */
export function isTestFile(filePath: string): boolean {
  return /\.(test|spec)\.ts$/.test(filePath);
}

/**
 * All shipped .ts files under `dir`, recursively — excluding test and spec files.
 */
export function listSourceFiles(dir: string, recursive = true): string[] {
  const files: string[] = [];
  if (!fs.existsSync(dir)) return files;

  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (recursive) files.push(...listSourceFiles(fullPath, recursive));
    } else if (entry.name.endsWith('.ts') && !isTestFile(entry.name)) {
      files.push(fullPath);
    }
  }
  return files;
}

/** Read a shipped source file with its comments removed. */
export function readCode(filePath: string): string {
  return stripComments(fs.readFileSync(filePath, 'utf-8'));
}
