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
 * A recursive search can read a forbidden folder without naming it, so the search root is checked too:
 * a Grep or Glob tool call (root = `path`, else the literal head of an absolute Glob pattern, else the
 * cwd), and `grep -r`/`-R`/`--recursive`, `rg`, `find` and `ls -R` in a Bash command (root = each path
 * argument, else the cwd) are hits when the root is a forbidden entry or a parent of one. A Glob only
 * counts as recursive when its pattern has `**`.
 * Tool output is evidence too: every string in a `tool_result` block (user messages) is scanned for a
 * forbidden absolute or `~` path, and a hit names the tool that produced the result.
 *
 * Still undetectable: shell variables (`$D/x`), globs in Bash (`stage*`), paths built or read by a
 * script the agent wrote and ran, `cd` anywhere but the start of a command, search roots passed through
 * `xargs`, a subshell or an alias, recursive tools other than those listed above (`tree`, `du`, `cp -r`,
 * `tar`), and relative paths printed in tool output (only absolute and `~` paths in results are matched).
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

/** Apply a leading `cd X &&` / `cd X;` to the base. Returns the new base (or undefined) and the rest. */
function splitCd(str: string, home: string, cwd: string | undefined): { base: string | undefined; rest: string } {
  let base = cwd ? normalise(cwd, home) : undefined;
  const cd = CD_PREFIX.exec(str);
  if (!cd) return { base, rest: str };
  const target = normalise(cd[1].replace(/^["']|["']$/g, ''), home);
  if (target.startsWith('/')) base = posix.resolve(target);
  else if (base) base = posix.resolve(base, target);
  return { base, rest: str.slice(cd[0].length) };
}

function relativeCandidates(str: string, home: string, cwd: string | undefined): string[] {
  if (!cwd) return [];
  const sp = splitCd(str, home, cwd);
  const base = sp.base as string;
  const rest = sp.rest;
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

function resolveRoot(p: string, home: string, base: string | undefined): string | undefined {
  const t = normalise(p.replace(/^["']|["']$/g, ''), home);
  if (t.startsWith('/')) return posix.resolve(t);
  return base ? posix.resolve(base, t) : undefined;
}

/** True when `root` is `f` or a folder above it. */
function coversForbidden(root: string, f: string): boolean {
  const r = root.replace(/\/+$/, '');
  return r === '' || f === r || f.startsWith(r + '/');
}

const GLOB_CHAR = /[*?[\]{}]/;

/** The literal folder in front of the first glob segment of a pattern. */
function literalHead(pattern: string): string {
  const segs = pattern.split('/');
  const lit: string[] = [];
  for (const s of segs) { if (GLOB_CHAR.test(s)) break; lit.push(s); }
  return lit.join('/') || (pattern.startsWith('/') ? '/' : '.');
}

function shellWords(seg: string): string[] {
  const out: string[] = [];
  const re = /"([^"]*)"|'([^']*)'|((?:\\ |[^\s"'])+)/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(seg))) out.push(m[1] ?? m[2] ?? m[3].replace(/\\ /g, ' '));
  return out;
}

/** Search roots of recursive commands (`grep -r`, `rg`, `find`, `ls -R`) in a Bash command line. */
function bashRecursiveRoots(command: string, home: string, cwd: string | undefined): string[] {
  const { base, rest } = splitCd(command, home, cwd);
  const roots: string[] = [];
  for (const seg of rest.split(/&&|\|\||;|\||\n/)) {
    const words = shellWords(seg.trim());
    while (words.length && /^(sudo|command|time|nice|env|[A-Za-z_][A-Za-z0-9_]*=.*)$/.test(words[0])) words.shift();
    if (!words.length) continue;
    const cmd = posix.basename(words[0]);
    const args = words.slice(1);
    let paths: string[] = [];
    if (cmd === 'grep' || cmd === 'egrep' || cmd === 'fgrep' || cmd === 'rg') {
      const recursive = cmd === 'rg'
        || args.some((a) => /^-[A-Za-z]*[rR]/.test(a) && !a.startsWith('--')) || args.includes('--recursive')
        || args.includes('--dereference-recursive') || args.some((a) => /^(-d|--directories)=?recurse$/.test(a));
      if (!recursive) continue;
      let patternGiven = (cmd === 'rg' && args.includes('--files')) || args.some((a) => a === '-e' || a === '-f' || /^--(regexp|file)(=|$)/.test(a) || /^-[A-Za-z]*[ef].+/.test(a));
      const valueFlags = new Set(['-e', '-f', '-m', '-A', '-B', '-C', '-g', '-t', '-T', '--glob', '--type', '--include', '--exclude', '--max-count']);
      for (let i = 0; i < args.length; i++) {
        const a = args[i];
        if (a === '--') { paths.push(...args.slice(i + 1 + (patternGiven ? 0 : 1))); break; }
        if (a.startsWith('-')) { if (valueFlags.has(a)) i++; continue; }
        if (!patternGiven) { patternGiven = true; continue; }
        paths.push(a);
      }
    } else if (cmd === 'find') {
      for (const a of args) { if (/^[-(!]/.test(a)) break; paths.push(a); }
    } else if (cmd === 'ls') {
      const recursive = args.some((a) => /^-[A-Za-z]*R/.test(a) && !a.startsWith('--')) || args.includes('--recursive');
      if (!recursive) continue;
      paths = args.filter((a) => !a.startsWith('-'));
    } else continue;
    if (!paths.length) paths = ['.'];
    for (const p of paths) { const r = resolveRoot(p, home, base); if (r) roots.push(r); }
  }
  return roots;
}

/** Search roots of a tool call that reads a folder tree without naming the files. */
function recursiveRoots(name: string, input: any, home: string, cwd: string | undefined): string[] {
  if (!input || typeof input !== 'object') return [];
  const base = cwd ? normalise(cwd, home) : undefined;
  if (name === 'Grep') {
    const r = typeof input.path === 'string' && input.path ? resolveRoot(input.path, home, base) : base;
    return r ? [r] : [];
  }
  if (name === 'Glob') {
    const pattern = typeof input.pattern === 'string' ? input.pattern : '';
    if (!pattern.includes('**')) return [];
    const dir = typeof input.path === 'string' && input.path ? resolveRoot(input.path, home, base) : base;
    const head = literalHead(normalise(pattern, home));
    const r = head.startsWith('/') ? posix.resolve(head) : dir ? posix.resolve(dir, head) : undefined;
    return r ? [r] : [];
  }
  if (name === 'Bash' && typeof input.command === 'string') return bashRecursiveRoots(input.command, home, cwd);
  return [];
}

function resultStrings(item: any): string[] {
  const out: string[] = [];
  collectStrings(item?.content, out);
  return out;
}

export function scanTranscript(
  transcriptJsonl: string, forbidden: string[], home: string, opts: BlindnessOptions = {},
): BlindnessScan {
  const forb = forbidden.map((f) => ({ raw: f, norm: normaliseForbidden(f, home) }));
  const hits: ForbiddenHit[] = [];
  const toolNames = new Map<string, string>();
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
      if (!item) continue;
      if (item.type === 'tool_result') {
        const tool = `${toolNames.get(String(item.tool_use_id)) ?? 'unknown'} (result)`;
        const hays = resultStrings(item).map((s) => normalise(s, home));
        for (const f of forb) {
          if (hays.some((h) => mentions(h, f.norm))) hits.push({ line: idx + 1, path: f.raw, tool });
        }
        continue;
      }
      if (item.type !== 'tool_use') continue;
      toolCalls++;
      const name = String(item.name ?? 'unknown');
      if (item.id) toolNames.set(String(item.id), name);
      const strings: string[] = [];
      collectStrings(item.input, strings);
      const hays = strings.flatMap((s) => [normalise(s, home), ...relativeCandidates(s, home, cwd)]);
      const roots = recursiveRoots(name, item.input, home, cwd);
      for (const f of forb) {
        if (hays.some((h) => mentions(h, f.norm)) || roots.some((r) => coversForbidden(r, f.norm))) {
          hits.push({ line: idx + 1, path: f.raw, tool: name });
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
