/**
 * cliEnv — the two things every season-topic-prep CLI did by hand: load DATABASE_URL and read flags.
 *
 * Environment: `backend/.env` first. A linked git worktree has no `.env` of its own, so when
 * DATABASE_URL is still unset the main checkout's `backend/.env` is borrowed (variables already set
 * win). The CLIs open their own pg Pool from it and never import db.js, which demands every server
 * variable at import time.
 *
 * Flags: `--name value`. A flag given with no value (end of argv, or followed by another `--flag`)
 * is an error everywhere, never a silent fallback to the default, so a mistyped command cannot run
 * against the wrong folder. `flag`, `flags` and `hasFlag` are pure over the argv they are given.
 */
import { existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { execFileSync } from 'node:child_process';
import dotenv from 'dotenv';

export class CliFlagError extends Error {}

function valueAt(argv: readonly string[], i: number, name: string): string {
  const v = argv[i + 1];
  if (v === undefined || v === '' || v.startsWith('--')) throw new CliFlagError(`${name} needs a value`);
  return v;
}

/** The value of a single-use flag, or undefined when absent. Throws CliFlagError when it has no value. */
export function flag(argv: readonly string[], name: string): string | undefined {
  const i = argv.indexOf(name);
  return i === -1 ? undefined : valueAt(argv, i, name);
}

/** Every value of a repeatable flag, in order. Throws CliFlagError when any use has no value. */
export function flags(argv: readonly string[], name: string): string[] {
  const out: string[] = [];
  argv.forEach((a, i) => { if (a === name) out.push(valueAt(argv, i, name)); });
  return out;
}

/** True when a boolean flag (one that takes no value) is present. */
export function hasFlag(argv: readonly string[], name: string): boolean {
  return argv.includes(name);
}

/** Load `<backendDir>/.env`, then the main checkout's `backend/.env` if DATABASE_URL is still unset. */
export function loadBackendEnv(backendDir: string): void {
  dotenv.config({ path: join(backendDir, '.env'), quiet: true });
  if (process.env.DATABASE_URL) return;
  try {
    const common = execFileSync('git', ['rev-parse', '--path-format=absolute', '--git-common-dir'],
      { cwd: backendDir, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
    const mainEnv = join(dirname(common), 'backend', '.env');
    if (existsSync(mainEnv)) dotenv.config({ path: mainEnv, quiet: true });
  } catch { /* no git: the caller reports the missing variable */ }
}
