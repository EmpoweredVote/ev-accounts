/**
 * blindnessCheck — prove a blind drafter never touched forbidden folders (the frozen test set,
 * other stages' output). The orchestrator runs this over the drafter's subagent transcript.
 *
 * A transcript is JSONL. Tool calls sit in `message.content[]` as `{type:'tool_use', name, input}`.
 * Every string anywhere inside `input` is scanned, not only the well-known keys, so Read file_path,
 * Bash command, Grep/Glob path and pattern, WebFetch url and tools we have not seen yet are all covered.
 *
 * Both sides are normalised the same way (`~` to home, `%20` decoded, `\ ` unescaped, trailing `/`
 * stripped, case folded because macOS paths are case-insensitive). A forbidden entry matches as a
 * path prefix on path boundaries: `.../stage1` hits `.../stage1` and `.../stage1/x`, never `.../stage1b`.
 * Relative paths are resolved against the line's top-level `cwd` (or the `cwd` option when a line has
 * none), and a leading `cd X && ...` or `cd X; ...` in a Bash command moves that base for the rest of
 * the command. A PASS is never vacuous: `summarise` reports NO_EVIDENCE when no tool call was scanned.
 *
 * Still undetectable: shell variables (`$D/x`), globs (`stage*`), paths built or read by a script the
 * agent wrote and ran, and `cd` anywhere but the start of a command.
 * Pure module: no file or database access. Lines that fail to parse are skipped and counted.
 */
import { posix } from 'node:path';

export interface ForbiddenHit {
  line: number;
  path: string;
  tool: string;
}

export interface BlindnessScan {
  hits: ForbiddenHit[];
  skippedLines: number;
  toolCalls: number;
}

export interface BlindnessOptions {
  /** Fallback base for relative paths on lines that carry no `cwd`. */
  cwd?: string;
}

const PATH_CHAR = /[A-Za-z0-9._\-~%@+]/;

function safeDecode(s: string): string {
  try { return decodeURIComponent(s); } catch { return s.replace(/%20/gi, ' '); }
}

function normalise(s: string, home: string): string {
  const h = home.replace(/\/+$/, '');
  let out = s.replace(/\\ /g, ' ');
  out = out.replace(/%20/gi, ' ');
  out = safeDecode(out);
  out = out.replace(/(^|[\s"'=:(])~(?=\/|$|[\s"')])/g, (_m, pre) => `${pre}${h}`);
  return out.toLowerCase();
}

function normaliseForbidden(p: string, home: string): string {
  return normalise(p, home).replace(/\/+$/, '');
}

function collectStrings(v: unknown, out: string[]): void {
  if (typeof v === 'string') out.push(v);
  else if (Array.isArray(v)) v.forEach((x) => collectStrings(x, out));
  else if (v && typeof v === 'object') Object.values(v).forEach((x) => collectStrings(x, out));
}

function mentions(hay: string, needle: string): boolean {
  if (!needle) return false;
  let from = 0;
  for (;;) {
    const i = hay.indexOf(needle, from);
    if (i === -1) return false;
    const before = i === 0 ? '' : hay[i - 1];
    const after = hay[i + needle.length] ?? '';
    const beforeOk = before === '' || !PATH_CHAR.test(before);
    const afterOk = after === '' || !PATH_CHAR.test(after);
    if (beforeOk && afterOk) return true;
    from = i + 1;
  }
}

const CD_PREFIX = /^\s*cd\s+("[^"]*"|'[^']*'|(?:\\ |\S)+)\s*(?:&&|;)/;

function relativeCandidates(str: string, home: string, cwd: string | undefined): string[] {
  if (!cwd) return [];
  let base = normalise(cwd, home);
  let rest = str;
  const cd = CD_PREFIX.exec(str);
  if (cd) {
    const target = normalise(cd[1].replace(/^["']|["']$/g, ''), home);
    base = target.startsWith('/') ? posix.resolve(target) : posix.resolve(base, target);
    rest = str.slice(cd[0].length);
  }
  const tokens = [rest.trim(), ...rest.replace(/\\ /g, '\u0000').split(/[\s"'`;&|<>()=,]+/).map((t) => t.replace(/\u0000/g, ' '))];
  const out: string[] = [];
  for (const raw of tokens) {
    if (!raw || raw.startsWith('-') || /^[a-z][a-z0-9+.-]*:/i.test(raw)) continue;
    const t = normalise(raw, home);
    if (t.startsWith('/')) continue;
    out.push(posix.resolve(base, t));
  }
  return out;
}

export function scanTranscript(
  transcriptJsonl: string, forbidden: string[], home: string, opts: BlindnessOptions = {},
): BlindnessScan {
  const forb = forbidden.map((f) => ({ raw: f, norm: normaliseForbidden(f, home) }));
  const hits: ForbiddenHit[] = [];
  let skippedLines = 0;
  let toolCalls = 0;
  transcriptJsonl.split('\n').forEach((text, idx) => {
    if (!text.trim()) return;
    let obj: any;
    try { obj = JSON.parse(text); } catch { skippedLines++; return; }
    const content = obj?.message?.content;
    if (!Array.isArray(content)) return;
    const cwd = typeof obj.cwd === 'string' && obj.cwd ? obj.cwd : opts.cwd;
    for (const item of content) {
      if (!item || item.type !== 'tool_use') continue;
      toolCalls++;
      const strings: string[] = [];
      collectStrings(item.input, strings);
      const hays = strings.flatMap((s) => [normalise(s, home), ...relativeCandidates(s, home, cwd)]);
      for (const f of forb) {
        if (hays.some((h) => mentions(h, f.norm))) {
          hits.push({ line: idx + 1, path: f.raw, tool: String(item.name ?? 'unknown') });
        }
      }
    }
  });
  return { hits, skippedLines, toolCalls };
}

export interface BlindnessVerdict {
  status: 'PASS' | 'FAIL' | 'NO_EVIDENCE';
  text: string;
  exitCode: 0 | 1 | 3;
}

/** Turn a scan into the --out text and exit code. A PASS needs at least one tool call scanned. */
export function summarise(scan: BlindnessScan): BlindnessVerdict {
  if (scan.hits.length) {
    return { status: 'FAIL', exitCode: 1, text: scan.hits.map((h) => `line ${h.line}: ${h.tool} touched ${h.path}`).join('\n') };
  }
  if (scan.toolCalls === 0) {
    return { status: 'NO_EVIDENCE', exitCode: 3,
      text: `NO EVIDENCE: 0 tool calls scanned, ${scan.skippedLines} lines skipped (wrong file or wrong format?)` };
  }
  return { status: 'PASS', exitCode: 0, text: `PASS (${scan.toolCalls} tool calls scanned, ${scan.skippedLines} lines skipped)` };
}

/** True when a --forbid entry normalises to nothing (e.g. "/"), which would match everything or nothing. */
export function isEmptyForbidden(f: string, home: string): boolean {
  return normaliseForbidden(f, home) === '';
}

export function findForbiddenReads(
  transcriptJsonl: string, forbidden: string[], home: string, opts: BlindnessOptions = {},
): ForbiddenHit[] {
  return scanTranscript(transcriptJsonl, forbidden, home, opts).hits;
}
