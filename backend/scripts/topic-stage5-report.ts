/**
 * topic-stage5-report.ts — Stage 5 steps 5 and 6: check every code, then the split, the themes and the early check
 * (no database).
 *
 *   npm run topic:stage5-report --prefix backend -- --topic <key> --research <abs topic folder> --out <abs report.md>
 *        [--units federal,state:in,…] [--themes <abs themes.json>] [--notes-out <abs notes.jsonl>]
 *        [--store <abs store root>] [--early]
 *
 * Reads `<research>/stage5/roster.tsv` and every `<research>/stage5/codes/<politician_id>.json`, and checks each
 * code against the person's saved findings (stage5Code.checkCode). A code that fails is listed and not counted.
 * `--units` limits the roster to the units run so far (the early check). `--notes-out` writes every doesn't-fit
 * open note, with its level, state, tags and blank class but no name, for the theme pass
 * (templates/stage5-theme-prompt.md). `--themes` adds that pass's result. `--early` titles it as the early check.
 *
 * Exit 0 = continue; 3 = some codes failed their check; 4 = the early-check bar says stop (4 wins over 3).
 */
import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, isAbsolute, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { CliFlagError, flag as readFlag, hasFlag } from './lib/cliEnv.js';
import { PersonFindingsSchema, storePaths } from './lib/sourceStore.js';
import { checkCode, Stage5CodeSchema, type Stage5Code } from './lib/stage5Code.js';
import { parseRosterTsv } from './lib/stage5Roster.js';
import { parseUnit } from './lib/stage5Find.js';
import { codeFileProblem, earlyCheck, exitCode, formatReport, summarise, ThemesSchema } from './lib/stage5Report.js';

const backendDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const flag = (name: string) => readFlag(process.argv, name);
const abs = (name: string, p: string | undefined, required = true) => {
  if (!p) { if (required) throw new Error(`${name} is required`); return undefined; }
  if (!isAbsolute(p)) throw new Error(`${name} must be an absolute path (npm runs this from backend/): ${p}`);
  return p;
};

function main(): number {
  const topic = flag('--topic');
  if (!topic) throw new Error('usage: topic-stage5-report --topic <key> --research <abs dir> --out <abs file> [options] (see the file header)');
  const research = abs('--research', flag('--research'))!;
  const out = abs('--out', flag('--out'))!;
  const themesFile = abs('--themes', flag('--themes'), false);
  const notesOut = abs('--notes-out', flag('--notes-out'), false);
  const store = abs('--store', flag('--store'), false) ?? join(backendDir, 'data', 'source-store');
  const early = hasFlag(process.argv, '--early');

  let roster = parseRosterTsv(readFileSync(join(research, 'stage5', 'roster.tsv'), 'utf8'));
  const unitsFlag = flag('--units');
  if (unitsFlag) {
    const units = unitsFlag.split(',').map((u) => parseUnit(u.trim()));
    roster = roster.filter((r) => units.some((u) => u.level === r.level && (!u.state || u.state === r.state)));
  }
  const onRoster = new Set(roster.map((r) => r.politician_id));

  const dir = join(research, 'stage5', 'codes');
  const codes: Stage5Code[] = [];
  const failed: string[] = [];
  for (const name of existsSync(dir) ? readdirSync(dir).filter((n) => n.endsWith('.json')).sort() : []) {
    const raw = JSON.parse(readFileSync(join(dir, name), 'utf8'));
    const parsed = Stage5CodeSchema.safeParse(raw);
    if (!parsed.success) { failed.push(`${name}: ${parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ')}`); continue; }
    const code = parsed.data;
    const nameProblem = codeFileProblem(name, code);
    if (nameProblem) { failed.push(`${name}: ${nameProblem}`); continue; }
    if (code.topic_key !== topic || !onRoster.has(code.politician_id)) continue;
    const f = storePaths(store).findings(code.politician_id);
    const pf = existsSync(f) ? PersonFindingsSchema.parse(JSON.parse(readFileSync(f, 'utf8'))) : { politician_id: code.politician_id, findings: [], searches: [] };
    const problems = checkCode(code, pf);
    if (problems.length) failed.push(`${name}: ${problems.join('; ')}`);
    else codes.push(code);
  }

  if (notesOut) {
    const where = new Map(roster.map((r) => [r.politician_id, r]));
    const notes = codes.filter((c) => c.outcome === 'doesnt-fit').map((c) => JSON.stringify({
      politician_id: c.politician_id, level: where.get(c.politician_id)?.level, state: where.get(c.politician_id)?.state,
      tags: c.tags, blank_class: c.blank_class ?? null, open_note: c.open_note,
    }));
    writeFileSync(notesOut, notes.join('\n') + (notes.length ? '\n' : ''));
  }

  const themes = themesFile ? ThemesSchema.parse(JSON.parse(readFileSync(themesFile, 'utf8'))) : undefined;
  const s = summarise(roster, codes, themes);
  const check = earlyCheck(s);
  const title = `Stage 5 ${early ? 'early check' : 'report'} — ${topic}${unitsFlag ? ` (${unitsFlag})` : ''}`;
  let text = formatReport(s, check, title);
  if (failed.length) text += `\n## Codes that failed their check (${failed.length}, not counted)\n\n${failed.map((f) => `- ${f}`).join('\n')}\n`;
  writeFileSync(out, text);
  console.log(text.split('\n').slice(0, 6).join('\n'));
  console.log(`\nwrote ${out}${failed.length ? `; ${failed.length} code(s) failed their check` : ''}`);
  return exitCode(check.stop, failed.length);
}

try {
  process.exitCode = main();
} catch (e) {
  console.error(e instanceof CliFlagError ? e.message : e);
  process.exitCode = 1;
}
