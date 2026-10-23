/**
 * topic-stage5-write.ts — Stage 5 step 7: write a batch's research outcomes and checked passages to the DRAFT season.
 *
 *   npm run topic:stage5-write --prefix backend -- --topic <key> --research <abs topic folder> --season draft
 *        --csv-out <abs research.csv> [--units federal,state:in,…] [--store <abs store root>]
 *   npm run topic:stage5-write … (same flags, without --csv-out) --apply
 *
 * Reads `<research>/stage5/roster.tsv`, every `<research>/stage5/codes/<politician_id>.json`, the people's saved
 * findings, and `<research>/stage5/quote-checks.jsonl` (templates/stage5-quote-check-prompt.md), and plans the
 * batch (lib/stage5Write.planBatch). In a dry run `--csv-out` receives the seats and blanks as research.csv for the
 * existing pipeline (stance-gate.ts → verify-stance-research.ts --season draft); this script never writes answers.
 *
 * DRY RUN BY DEFAULT: it reads the database only to resolve the season and prints what it would write.
 * `--apply` writes inform.topic_research_outcomes and inform.own_words_passages in one transaction, and only
 * after Chris Andrews' yes for this batch (Global Constraints). `--season` must name the draft season
 * (`draft`, or the draft season's uuid); `open` and any other season are refused. `--apply` also refuses while
 * any code is refused (lib/stage5Write.applyBlocker), so no earlier write is left stale.
 *
 * Before printing, it re-fetches each own-words passage's page and keeps the passage only when it is on the page
 * word for word (`--no-verify-pages` skips this). A page that is not HTML or text, or will not load, keeps the
 * quote check's word and is listed.
 *
 * Opens its own pg Pool from DATABASE_URL, loaded by lib/cliEnv.ts; never prints it.
 * Exit 0 = planned (or written); 3 = some codes or passages were refused (listed); 2 = a usage or input error.
 */
import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, isAbsolute, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { CliFlagError, flag as readFlag, hasFlag, loadBackendEnv } from './lib/cliEnv.js';
import { resolveSeasonTarget, seasonSpecFromArgv } from './lib/seasonTarget.js';
import { PersonFindingsSchema, storePaths, type PersonFindings } from './lib/sourceStore.js';
import { Stage5CodeSchema, type Stage5Code } from './lib/stage5Code.js';
import { parseUnit } from './lib/stage5Find.js';
import { readQuoteChecks } from './lib/stage5QuoteCheck.js';
import { parseRosterTsv } from './lib/stage5Roster.js';
import { applyBatch, applyBlocker, assertDraftSeason, planBatch, refusePassagesNotOnPage } from './lib/stage5Write.js';

const backendDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
loadBackendEnv(backendDir);
const flag = (name: string) => readFlag(process.argv, name);
/** A page as text for the re-check. Not HTML or text (a PDF, say) → throw, so it is listed, never refused. */
async function fetchPage(url: string): Promise<string> {
  const res = await fetch(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36', Accept: 'text/html,text/plain;q=0.9,*/*;q=0.5' },
    signal: AbortSignal.timeout(20_000),
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const type = res.headers.get('content-type') ?? '';
  if (!/text\/html|text\/plain|xhtml/i.test(type)) throw new Error(`not an HTML page (${type || 'no content type'})`);
  return res.text();
}

const abs = (name: string, p: string | undefined) => {
  if (!p) throw new Error(`${name} is required`);
  if (!isAbsolute(p)) throw new Error(`${name} must be an absolute path (npm runs this from backend/): ${p}`);
  return p;
};

async function main(): Promise<number> {
  const topic = flag('--topic');
  if (!topic) throw new Error('usage: topic-stage5-write --topic <key> --research <abs dir> --season draft --csv-out <abs file> [--apply] (see the file header)');
  const research = abs('--research', flag('--research'));
  const apply = hasFlag(process.argv, '--apply');
  // The dry run writes research.csv; --apply writes the database only, so the same command plus --apply works.
  const csvOut = apply ? undefined : abs('--csv-out', flag('--csv-out'));
  const store = flag('--store') ? abs('--store', flag('--store')) : join(backendDir, 'data', 'source-store');
  if (!process.argv.includes('--season')) throw new Error('--season draft is required: Stage 5 writes to the draft season only');
  const seasonSpec = seasonSpecFromArgv(process.argv);
  if (seasonSpec === 'open') throw new Error('--season open is refused: Stage 5 writes to the draft season only');
  if (csvOut && existsSync(csvOut)) throw new Error(`${csvOut} already exists; refusing to overwrite it`);

  let roster = parseRosterTsv(readFileSync(join(research, 'stage5', 'roster.tsv'), 'utf8'));
  const unitsFlag = flag('--units');
  if (unitsFlag) {
    const units = unitsFlag.split(',').map((u) => parseUnit(u.trim()));
    roster = roster.filter((r) => units.some((u) => u.level === r.level && (!u.state || u.state === r.state)));
  }
  const names = new Map(roster.map((r) => [r.politician_id, r.full_name]));

  const dir = join(research, 'stage5', 'codes');
  const codes: Stage5Code[] = [];
  for (const name of existsSync(dir) ? readdirSync(dir).filter((n) => n.endsWith('.json')).sort() : []) {
    const code = Stage5CodeSchema.parse(JSON.parse(readFileSync(join(dir, name), 'utf8')));
    if (code.topic_key === topic && names.has(code.politician_id)) codes.push(code);
  }
  const findings = new Map<string, PersonFindings>();
  for (const c of codes) {
    const f = storePaths(store).findings(c.politician_id);
    if (existsSync(f)) findings.set(c.politician_id, PersonFindingsSchema.parse(JSON.parse(readFileSync(f, 'utf8'))));
  }
  const checksFile = join(research, 'stage5', 'quote-checks.jsonl');
  const checks = existsSync(checksFile) ? readQuoteChecks(readFileSync(checksFile, 'utf8')) : [];

  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is not set (expected in backend/.env)');
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 1 });
  const client = await pool.connect();
  try {
    const q = (sql: string, params?: unknown[]) => client.query(sql, params as any[]);
    await q('BEGIN READ ONLY');
    const season = await resolveSeasonTarget(seasonSpec, q).finally(() => q('ROLLBACK'));
    assertDraftSeason(season);

    const planned = planBatch(codes, findings, checks, { seasonId: season.id, names });
    const verify = !hasFlag(process.argv, '--no-verify-pages');
    const plan = verify ? await refusePassagesNotOnPage(planned, fetchPage) : { ...planned, unchecked: [] };
    if (csvOut) writeFileSync(csvOut, plan.researchCsv, { flag: 'wx' });

    const by = (o: string) => plan.outcomes.filter((x) => x.outcome === o).length;
    console.log(`topic ${topic} — season ${season.number} (${season.name}) [draft]; ${codes.length} codes read`);
    console.log(`outcomes:  ${plan.outcomes.length} (seated ${by('seated')}, doesnt-fit ${by('doesnt-fit')}, no-stance ${by('no-stance')})`);
    console.log(`passages:  ${plan.passages.length} (own-words ${plan.passages.filter((p) => p.kind === 'own-words').length}, local-record ${plan.passages.filter((p) => p.kind === 'local-record').length})`);
    if (csvOut) console.log(`research.csv: ${csvOut} (run stance-gate.ts and verify-stance-research.ts --season draft on it)`);
    if (!verify) console.log('pages NOT re-fetched (--no-verify-pages): passages rest on the quote check alone');
    if (plan.unchecked.length) {
      console.log(`not re-checked on the page (${plan.unchecked.length}) — kept on the quote check alone:`);
      for (const r of plan.unchecked) console.log(`  ${r.politician_id}  ${r.reason}`);
    }
    if (plan.notInCsv.length) {
      console.log(`not in research.csv (${plan.notInCsv.length}) — add by hand:`);
      for (const r of plan.notInCsv) console.log(`  ${r.politician_id}  ${r.reason}`);
    }
    if (plan.refused.length) {
      console.log(`refused (${plan.refused.length}):`);
      for (const r of plan.refused) console.log(`  ${r.politician_id}  ${r.reason}`);
    }

    if (!apply) {
      console.log('DRY RUN — nothing written to the database. Re-run with --apply after Chris Andrews\' yes for this batch.');
    } else {
      const blocker = applyBlocker(plan);
      if (blocker) { console.error(`NOT WRITTEN: ${blocker}`); return 3; }
      const n = await applyBatch(q, plan, season.id);
      console.log(`WROTE ${n.outcomes} outcomes and ${n.passages} passages to the draft season (hidden from voters until it opens).`);
    }
    return plan.refused.length ? 3 : 0;
  } finally {
    client.release();
    await pool.end();
  }
}

main()
  .then((code) => { process.exitCode = code; })
  .catch((e) => {
    console.error(e instanceof CliFlagError || e instanceof Error ? e.message : e);
    process.exitCode = 2;
  });
