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
 * Pure module: no file or database access. Lines that fail to parse are skipped and counted.
 */
export interface ForbiddenHit {
  line: number;
  path: string;
  tool: string;
}

export interface BlindnessScan {
  hits: ForbiddenHit[];
  skippedLines: number;
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

export function scanTranscript(transcriptJsonl: string, forbidden: string[], home: string): BlindnessScan {
  const forb = forbidden.map((f) => ({ raw: f, norm: normaliseForbidden(f, home) }));
  const hits: ForbiddenHit[] = [];
  let skippedLines = 0;
  transcriptJsonl.split('\n').forEach((text, idx) => {
    if (!text.trim()) return;
    let obj: any;
    try { obj = JSON.parse(text); } catch { skippedLines++; return; }
    const content = obj?.message?.content;
    if (!Array.isArray(content)) return;
    for (const item of content) {
      if (!item || item.type !== 'tool_use') continue;
      const strings: string[] = [];
      collectStrings(item.input, strings);
      const hays = strings.map((s) => normalise(s, home));
      for (const f of forb) {
        if (hays.some((h) => mentions(h, f.norm))) {
          hits.push({ line: idx + 1, path: f.raw, tool: String(item.name ?? 'unknown') });
        }
      }
    }
  });
  return { hits, skippedLines };
}

export function findForbiddenReads(transcriptJsonl: string, forbidden: string[], home: string): ForbiddenHit[] {
  return scanTranscript(transcriptJsonl, forbidden, home).hits;
}
