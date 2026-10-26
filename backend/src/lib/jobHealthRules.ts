/**
 * jobHealthRules — the pure half of the job-health alarm (src/lib/jobHealth.ts).
 *
 * No database, no env, no email: it turns already-fetched rows into a list of problems,
 * so the rules can be unit-tested without secrets (CI's unit step runs without them).
 */

export interface Problem {
  /** The job as a person would look it up: pg_cron jobname or Render cron service name. */
  job: string;
  /** What is wrong, in one short clause. */
  what: string;
  /** When it started being wrong, if known — rendered as "for 3d 4h". */
  since: Date | null;
}

export interface PgCronRow {
  jobname: string;
  schedule: string;
  active: boolean;
  last_start: Date | null;
  fails: number;
  first_fail_at: Date | null;
  newest_fail_at: Date | null;
  newest_fail_message: string | null;
}

export interface ProofRow {
  /** Render cron service name (plus the step, when one service runs two jobs). */
  job: string;
  /** Newest "proof it ran" timestamp, from the manifest in docs/JOB-API-SPLIT.md. */
  newest: Date | null;
  /** Older than this = stale. */
  maxAgeMinutes: number;
}

export interface HttpRow {
  status_code: number | null;
  timed_out: boolean;
  error_msg: string | null;
  responses: number;
  first_seen: Date;
}

export interface StrandedRow {
  adapter_name: string;
  runs: number;
  oldest_start: Date;
}

/** A job is stale once its newest run is older than this many of its own intervals. */
export const STALE_INTERVALS = 3;

const MINUTE = 1;
const HOUR = 60;
const DAY = 24 * HOUR;

const isFixed = (field: string) => /^\d+(,\d+)*$/.test(field);

/**
 * Approximate minutes between runs for a pg_cron schedule, or null when the shape is not
 * one we recognise (that job then gets no staleness check — failures are still reported).
 * Only needs to be right to within a factor of ~2: the threshold is three intervals.
 */
export function scheduleIntervalMinutes(schedule: string): number | null {
  const s = schedule.trim();

  // pg_cron's sub-minute form: "30 seconds".
  const secs = /^(\d+)\s+seconds?$/i.exec(s);
  if (secs) return Math.max(1, Math.ceil(Number(secs[1]) / 60));

  const f = s.split(/\s+/);
  if (f.length !== 5) return null;
  const [min, hour, dom, month, dow] = f;
  if (month !== '*') return null;

  const step = (field: string) => /^\*\/(\d+)$/.exec(field)?.[1];

  if (min === '*' && hour === '*') return MINUTE;
  if (step(min) && hour === '*') return Number(step(min));
  if (!isFixed(min)) return null;
  if (hour === '*') return HOUR;
  if (step(hour)) return Number(step(hour)) * HOUR;
  if (!isFixed(hour)) return null;
  if (dom === '*' && dow === '*') return DAY;
  if (dom === '*' && isFixed(dow)) return 7 * DAY;
  if (isFixed(dom) && dow === '*') return 31 * DAY;
  return null;
}

/**
 * Build the problem list. `staleOverrideMinutes` replaces EVERY staleness threshold — it
 * exists only to prove the alarm fires (set it to 1 and every job trips).
 */
export function evaluate(input: {
  now: Date;
  pgCron: PgCronRow[];
  proofs: ProofRow[];
  http: HttpRow[];
  stranded: StrandedRow[];
  staleOverrideMinutes?: number;
}): Problem[] {
  const { now, staleOverrideMinutes } = input;
  const problems: Problem[] = [];
  const ageMin = (d: Date) => (now.getTime() - d.getTime()) / 60_000;

  // (a) pg_cron failures, and (b) pg_cron staleness.
  for (const j of input.pgCron) {
    if (j.fails > 0) {
      const msg = (j.newest_fail_message ?? '').replace(/\s+/g, ' ').trim().slice(0, 200);
      problems.push({
        job: j.jobname,
        what: `${j.fails} failed run${j.fails === 1 ? '' : 's'} in the last 24h — newest: ${msg || '(no message)'}`,
        since: j.first_fail_at,
      });
    }
    if (!j.active) continue; // a paused job is a decision, not a fault
    const interval = scheduleIntervalMinutes(j.schedule);
    if (interval === null && staleOverrideMinutes === undefined) continue;
    const limit = staleOverrideMinutes ?? STALE_INTERVALS * (interval as number);
    if (!j.last_start) {
      problems.push({ job: j.jobname, what: `has never run (schedule ${j.schedule})`, since: null });
    } else if (ageMin(j.last_start) > limit) {
      problems.push({
        job: j.jobname,
        what: `no run since ${j.last_start.toISOString()} (schedule ${j.schedule})`,
        since: j.last_start,
      });
    }
  }

  // (c) Render cron proof-of-run staleness.
  for (const p of input.proofs) {
    const limit = staleOverrideMinutes ?? p.maxAgeMinutes;
    if (!p.newest) {
      problems.push({ job: p.job, what: 'no proof it has ever run', since: null });
    } else if (ageMin(p.newest) > limit) {
      problems.push({
        job: p.job,
        what: `no proof it ran since ${p.newest.toISOString()} (expected within ${formatDuration(p.maxAgeMinutes)})`,
        since: p.newest,
      });
    }
  }

  // (d) Stranded ingestion runs.
  for (const s of input.stranded) {
    problems.push({
      job: `ingestion_runs ${s.adapter_name}`,
      what: `${s.runs} run${s.runs === 1 ? '' : 's'} stuck in 'running' for over 24h`,
      since: s.oldest_start,
    });
  }

  // HTTP triggers that pg_cron recorded as 'succeeded' but the API refused or never answered.
  for (const h of input.http) {
    const what = h.timed_out
      ? 'timed out'
      : h.status_code === null
        ? `failed: ${h.error_msg ?? 'no status'}`
        : `answered HTTP ${h.status_code}`;
    problems.push({
      job: 'pg_cron → API trigger',
      what: `${h.responses} request${h.responses === 1 ? '' : 's'} ${what}`,
      since: h.first_seen,
    });
  }

  return problems;
}

export function formatDuration(minutes: number): string {
  const m = Math.max(0, Math.round(minutes));
  const d = Math.floor(m / DAY);
  const h = Math.floor((m % DAY) / HOUR);
  const mm = m % HOUR;
  if (d > 0) return h > 0 ? `${d}d ${h}h` : `${d}d`;
  if (h > 0) return mm > 0 ? `${h}h ${mm}m` : `${h}h`;
  return `${mm}m`;
}

/** One line per problem: job name, what is wrong, how long it has been wrong. */
export function formatProblemLine(p: Problem, now: Date): string {
  const howLong = p.since
    ? `for ${formatDuration((now.getTime() - p.since.getTime()) / 60_000)}`
    : 'for an unknown time';
  return `${p.job} — ${p.what} — ${howLong}`;
}
