/**
 * summary-second-opinion.ts — position summaries, step 3: a GPT and a Gemini read each checker prompt through the
 * `opencode` CLI (plan 2026-11-22-position-summaries, task 7).
 *
 *   npx tsx scripts/stage5/summary-second-opinion.ts --profile <stage5>/topic-profile.json --batch <name>
 *     [--models opencode-go/gpt-6-luna,opencode-go/gemini-4-argon] [--timeout 180] [--retry-unusable]
 *
 * For each `<stage5>/summaries/<batch>/checker/<n>.md` (line n of summaries.jsonl) and each model: copies the file
 * alone into a fresh empty temp dir, runs `opencode run -m <model> --format json --archived -f <copy> "<instruction>"`
 * there with an environment stripped of secrets (never `--auto`), pulls the assistant's text out of the event stream,
 * validates the JSON with SummaryCheckSchema, stamps `checker`, `family`, `at` and the summary's own sha256, and
 * appends one line per (summary, model) to `checks.jsonl`. A timeout, a non-zero exit, an error event, an empty or
 * unusable reply is recorded as a FAIL check ("no usable reply: <why>") — never a pass, never a crash.
 * `--retry-unusable` first removes from checks.jsonl the "no usable reply" lines (never a judgement fail) and re-runs
 * only those (summary, model) calls.
 * Exit 2: no models, an unknown model family, or bad arguments.
 */
import { spawnSync } from 'node:child_process';
import { appendFileSync, copyFileSync, existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { SummaryCheckSchema, type SummaryCheck } from '../lib/stage5Summary.js';
import { parseArgs } from './coder-io.js';

type Family = SummaryCheck['family'];
export interface Stamp { checker: string; family: Family; at: string }
interface SummaryRow { politician_id: string; topic_key: string; sha256: string; cites: string[][] }

export const INSTRUCTION =
  'Read the attached checker prompt and reply with the JSON it asks for, and nothing else. Do not use any tools.';

/** 'gpt' or 'gemini' from the model id; null for anything else. */
export function familyOf(model: string): Family | null {
  const m = model.toLowerCase();
  if (m.includes('gpt')) return 'gpt';
  if (m.includes('gemini')) return 'gemini';
  return null;
}

/** The environment opencode runs with: every variable whose name looks like a secret or a database is dropped. */
export function cleanEnv(env: Record<string, string | undefined>): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [k, v] of Object.entries(env)) {
    if (v === undefined) continue;
    if (/KEY|TOKEN|SECRET|PASSWORD|DATABASE|SUPABASE/i.test(k)) continue;
    out[k] = v;
  }
  return out;
}

/**
 * The assistant's final text from `opencode run --format json` stdout: one JSON event per line; the reply is the
 * `part.text` of every `type: "text"` event, joined in order. An `error` event is returned as `error` (opencode can
 * exit 0 after one). Lines that are not JSON are ignored.
 */
export function extractAssistantText(stdout: string): { text: string; error?: string } {
  const texts: string[] = [];
  let error: string | undefined;
  for (const line of stdout.split('\n')) {
    const t = line.trim();
    if (!t.startsWith('{')) continue;
    let ev: { type?: string; part?: { type?: string; text?: unknown }; error?: { message?: unknown; type?: unknown } };
    try { ev = JSON.parse(t); } catch { continue; }
    if (ev.type === 'text' && typeof ev.part?.text === 'string') texts.push(ev.part.text);
    else if (ev.type === 'error') error = String(ev.error?.message ?? ev.error?.type ?? 'error event').slice(0, 200);
  }
  const text = texts.join('');
  return error !== undefined && text.trim() === '' ? { text: '', error } : { text };
}

/** Every top-level `{…}` or `[…]` span in the text, string-aware, in order. */
function jsonSpans(s: string): string[] {
  const spans: string[] = [];
  for (let i = 0; i < s.length; i++) {
    const open = s[i];
    if (open !== '{' && open !== '[') continue;
    const close = open === '{' ? '}' : ']';
    let depth = 0; let inStr = false; let esc = false; let end = -1;
    for (let j = i; j < s.length; j++) {
      const c = s[j];
      if (inStr) { if (esc) esc = false; else if (c === '\\') esc = true; else if (c === '"') inStr = false; continue; }
      if (c === '"') inStr = true;
      else if (c === open) depth++;
      else if (c === close && --depth === 0) { end = j; break; }
    }
    if (end < 0) break; // truncated: nothing after an unclosed span is whole
    spans.push(s.slice(i, end + 1));
    i = end;
  }
  return spans;
}

/** The checks in a model's reply (a fenced block, or JSON among prose), stamped and validated; null when none. */
export function parseModelReply(raw: string, stamp: Stamp = { checker: 'model', family: 'gpt', at: new Date().toISOString() }): SummaryCheck[] | null {
  if (!raw || !raw.trim()) return null;
  for (const span of jsonSpans(raw)) {
    let v: unknown;
    try { v = JSON.parse(span); } catch { continue; }
    const items = Array.isArray(v) ? v : [v];
    if (items.length === 0) continue;
    const checks: SummaryCheck[] = [];
    for (const it of items) {
      if (it === null || typeof it !== 'object') { checks.length = 0; break; }
      const p = SummaryCheckSchema.safeParse({ ...(it as object), ...stamp });
      if (!p.success) { checks.length = 0; break; }
      checks.push(p.data);
    }
    if (checks.length) return checks;
  }
  return null;
}

/** A fail check standing for a reply we could not use. */
export function failCheck(s: Pick<SummaryRow, 'politician_id' | 'topic_key' | 'sha256'>, checker: string, family: Family, why: string, at = new Date().toISOString()): SummaryCheck {
  return {
    politician_id: s.politician_id, topic_key: s.topic_key, text_sha256: s.sha256, checker, family, at, verdict: 'fail',
    sentences: [{ index: 0, verdict: 'fail', reason: `no usable reply: ${why}`.slice(0, 300) }],
  };
}

/** Turn a model's reply text into the one check recorded for this summary and model. Never throws. */
export function toCheck(s: SummaryRow, replyText: string, checker: string, family: Family): SummaryCheck {
  const at = new Date().toISOString();
  const checks = parseModelReply(replyText, { checker, family, at });
  if (!checks) return failCheck(s, checker, family, 'reply is empty, not JSON, or fails the check schema', at);
  const c = checks[0];
  const idx = c.sentences.map((x) => x.index).sort((a, b) => a - b);
  const want = s.cites.length;
  if (checks.length !== 1 || idx.length !== want || idx.some((n, i) => n !== i)) {
    return failCheck(s, checker, family, `reply's sentence list does not match the summary's ${want} sentence(s)`, at);
  }
  // The summary's own identity and hash, never what the model echoed.
  return { ...c, politician_id: s.politician_id, topic_key: s.topic_key, text_sha256: s.sha256 };
}

/**
 * Written into each call's temp dir as opencode.json: every tool permission denied, so the model can only read the
 * attached file. A temp cwd alone does not stop its read/glob/grep/bash/webfetch tools on absolute paths (measured
 * 2026-11-22 with a canary file outside the dir: both models read it back without this config, neither does with it).
 */
export const LOCKDOWN_CONFIG = { $schema: 'https://opencode.ai/config.json', permission: { '*': 'deny' } };

/** A recorded check that stands for an unusable reply (an infrastructure failure, not a judgement). */
export const isUnusable = (c: { verdict?: string; sentences?: { reason?: string }[] }) =>
  c.verdict === 'fail' && (c.sentences?.[0]?.reason ?? '').startsWith('no usable reply');

/** Split checks.jsonl lines: judgement lines are kept, "no usable reply" lines are removed and returned as keys. */
export function dropUnusable(lines: string[]): { kept: string[]; removed: Set<string> } {
  const kept: string[] = []; const removed = new Set<string>();
  for (const l of lines) {
    if (!l.trim()) continue;
    let c: { text_sha256?: string; checker?: string; verdict?: string; sentences?: { reason?: string }[] };
    try { c = JSON.parse(l); } catch { kept.push(l); continue; }
    if (isUnusable(c)) removed.add(`${c.text_sha256}|${c.checker}`); else kept.push(l);
  }
  return { kept, removed };
}

export interface RunResult { text: string; why?: string; seconds: number }

/** One opencode call in a fresh empty dir holding only a copy of the checker file. */
export function runOpencode(file: string, model: string, timeoutS: number, env = process.env): RunResult {
  const dir = mkdtempSync(join(tmpdir(), 'second-opinion-'));
  const t0 = Date.now();
  try {
    const copy = join(dir, 'checker.md');
    copyFileSync(file, copy);
    writeFileSync(join(dir, 'opencode.json'), JSON.stringify(LOCKDOWN_CONFIG));
    const r = spawnSync('opencode', ['run', '-m', model, '--format', 'json', '--archived', '-f', copy, INSTRUCTION], {
      cwd: dir, env: cleanEnv(env), encoding: 'utf8', timeout: timeoutS * 1000, maxBuffer: 32 * 1024 * 1024,
    });
    const seconds = (Date.now() - t0) / 1000;
    if (r.error) {
      const code = (r.error as NodeJS.ErrnoException).code;
      return { text: '', why: code === 'ETIMEDOUT' ? `timed out after ${timeoutS}s` : `could not run opencode: ${r.error.message}`, seconds };
    }
    const x = extractAssistantText(r.stdout ?? '');
    if (r.status !== 0) return { text: '', why: `opencode exited ${r.status}: ${(x.error ?? (r.stderr || '').trim()).slice(0, 120)}`, seconds };
    if (x.error) return { text: '', why: `opencode reported: ${x.error}`, seconds };
    if (!x.text.trim()) return { text: '', why: 'empty reply', seconds };
    return { text: x.text, seconds };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

export function main(argv: string[]): void {
  const { flags } = parseArgs(argv);
  const last = (k: string) => flags.get(k)?.[flags.get(k)!.length - 1];
  const profilePath = last('profile');
  const batch = last('batch');
  if (!profilePath || !batch) { console.error('usage: summary-second-opinion.ts --profile <topic-profile.json> --batch <name> [--models a,b] [--timeout 180]'); process.exit(2); }
  const profile = JSON.parse(readFileSync(profilePath, 'utf8')) as { stage5: string; second_opinion_models?: string[] };
  const models = (last('models') ? last('models')!.split(',') : profile.second_opinion_models ?? []).map((m) => m.trim()).filter(Boolean);
  if (models.length === 0) { console.error('no models: pass --models a,b or set second_opinion_models in the profile'); process.exit(2); }
  const families = models.map((m) => familyOf(m));
  const bad = models.filter((_, i) => families[i] === null);
  if (bad.length) { console.error(`cannot tell the family (gpt or gemini) of: ${bad.join(', ')}`); process.exit(2); }
  const timeout = Number(last('timeout') ?? 180);
  if (!(timeout > 0)) { console.error('--timeout must be a positive number of seconds'); process.exit(2); }

  const dir = join(profile.stage5, 'summaries', batch);
  const rows = readFileSync(join(dir, 'summaries.jsonl'), 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l) as SummaryRow);
  const out = join(dir, 'checks.jsonl');
  let only: Set<string> | null = null;
  if (last('retry-unusable')) {
    const { kept, removed } = dropUnusable(existsSync(out) ? readFileSync(out, 'utf8').split('\n') : []);
    writeFileSync(out, kept.map((l) => `${l}\n`).join(''));
    only = removed;
    console.log(`retrying ${removed.size} unusable call(s)`);
  }
  const tally = { pass: 0, fail: 0, noReply: 0 };
  rows.forEach((s, i) => {
    const file = join(dir, 'checker', `${i + 1}.md`);
    models.forEach((model, mi) => {
      const family = families[mi]!;
      if (only && !only.has(`${s.sha256}|${model}`)) return;
      let check: SummaryCheck;
      let note = '';
      if (!existsSync(file)) check = failCheck(s, model, family, `checker file ${i + 1}.md is missing`);
      else {
        const r = runOpencode(file, model, timeout);
        check = r.why ? failCheck(s, model, family, r.why) : toCheck(s, r.text, model, family);
        note = ` ${r.seconds.toFixed(1)}s`;
      }
      appendFileSync(out, `${JSON.stringify(check)}\n`);
      if (check.sentences[0]?.reason.startsWith('no usable reply')) tally.noReply++;
      else if (check.verdict === 'pass') tally.pass++; else tally.fail++;
      console.log(`${s.politician_id} ${model}: ${check.verdict}${note}`);
    });
  });
  console.log(`checks written ${tally.pass + tally.fail + tally.noReply}: pass ${tally.pass}, fail ${tally.fail}, no usable reply ${tally.noReply} -> ${out}`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try { main(process.argv.slice(2)); } catch (e) { console.error((e as Error).message); process.exit(1); }
}
