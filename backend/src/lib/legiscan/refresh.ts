/**
 * refresh.ts — the weekly LegiScan refresh as one run-to-completion job.
 *
 *   node dist/jobs/run.js legiscan        (Render cron `ev-jobs-legiscan`, Sundays 14:00 UTC)
 *
 * Optional environment overrides, for manual runs:
 *   LEGISCAN_STATES=CA,IN   only these states (default: every state with a sitting legislator)
 *   LEGISCAN_DRY_RUN=1      read and match, write nothing
 *   LEGISCAN_FORCE=1        ignore the unchanged-hash skip (use after the roster grows)
 *   LEGISCAN_SESSIONS=current   only the newest session (default: current,previous)
 *
 * One failing state does not stop the others. The job throws at the end if any state had
 * errors, so Render marks the run failed. ev-cto decision 0030.
 */
import { MONTHLY_QUERY_CAP, readQueriesThisMonth } from './client.js';
import { STATE_NAMES, type SessionLabel } from './helpers.js';
import { emptyResult, importState, statesWithLegislators } from './importer.js';

const truthy = (v: string | undefined) => !!v && !['0', 'false', 'no', ''].includes(v.toLowerCase());

export async function runLegiscanRefresh(): Promise<ReturnType<typeof emptyResult>> {
  const apiKey = process.env.LEGISCAN_API_KEY;
  if (!apiKey) throw new Error('LEGISCAN_API_KEY is not set');

  const dryRun = truthy(process.env.LEGISCAN_DRY_RUN);
  const force = truthy(process.env.LEGISCAN_FORCE);
  const sessions = (process.env.LEGISCAN_SESSIONS ?? 'current,previous')
    .split(',').map((s) => s.trim()).filter(Boolean) as SessionLabel[];

  const states = process.env.LEGISCAN_STATES
    ? process.env.LEGISCAN_STATES.split(',').map((s) => s.trim().toUpperCase()).filter(Boolean)
    : await statesWithLegislators();
  const unknown = states.filter((s) => !STATE_NAMES[s]);
  if (unknown.length) throw new Error(`unknown state codes: ${unknown.join(', ')}`);

  console.info(`[legiscan] ${states.length} states${dryRun ? ' (dry run)' : ''}: ${states.join(' ')}`);
  const total = emptyResult();
  const failed: string[] = [];

  for (const state of states) {
    try {
      const r = await importState(apiKey, state, { dryRun, force, sessions });
      total.bridgeRows += r.bridgeRows; total.bills += r.bills; total.votes += r.votes;
      total.cosponsors += r.cosponsors; total.committees += r.committees;
      total.memberships += r.memberships; total.sessionsSkipped += r.sessionsSkipped;
      if (r.errors.length) {
        failed.push(state);
        console.error(`[legiscan] ${state}: ${r.errors.length} errors, first: ${r.errors.slice(0, 3).join(' | ')}`);
      }
    } catch (err) {
      failed.push(state);
      console.error(`[legiscan] ${state} failed: ${(err as Error).message}`);
      if ((err as Error).message.includes('budget nearly exhausted')) break;
    }
  }

  const used = await readQueriesThisMonth();
  console.info(
    `[legiscan] done: ${total.bills} bills, ${total.votes} vote rows, ${total.cosponsors} cosponsors, ` +
    `${total.sessionsSkipped} sessions unchanged. Queries this month: ${used}/${MONTHLY_QUERY_CAP}. ` +
    `Problem states: ${failed.length ? failed.join(' ') : 'none'}`,
  );
  if (failed.length) throw new Error(`legiscan refresh had problems in: ${failed.join(', ')}`);
  return total;
}
