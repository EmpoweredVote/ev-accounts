import { Pool, type PoolClient } from 'pg';

/**
 * A pg Pool for the Supabase session pooler (Supavisor, port 5432) that survives the pooler's
 * per-role session cap.
 *
 * WHY: Supavisor allows `pool_size` sessions per database role — 15 on this project. The engine
 * pool (max 10) and the trivia pool (max 5) both log in as ev_api, so ONE instance can already
 * hold all 15. During a Render deploy two instances run at once: the new one goes live while the
 * old one finishes its in-flight requests, still holding every idle session it had. Any session
 * the new instance opens in that window is refused with
 *   (EMAXCONNSESSION) max clients reached in session mode - max clients are limited to pool_size: 15
 * and the request 500s. Every EMAXCONNSESSION in the logs from 2026-10-20 to 2026-10-22 (20 of
 * them, incl. the Essentials journeys failure at 06:18:44 on 10-22) fell within 30 s of a deploy
 * going live.
 *
 * Two fixes, one on each side of the overlap:
 *   - the NEW instance waits and retries a refused connect (connect() below) instead of failing;
 *   - the OLD instance gives its idle sessions back at SIGTERM (releaseIdleSessions()), so the
 *     wait is only as long as its busy queries, not its whole footprint.
 */

/** Waits between attempts after a refused connect; ~8 s in all, under the 15 s e2e budget. */
export const POOLER_FULL_RETRY_DELAYS_MS: readonly number[] = [250, 500, 1000, 2000, 4000];

/** True for Supavisor's "session cap reached" refusal. It arrives as a FATAL with code XX000. */
export function isPoolerFullError(err: unknown): boolean {
  return err instanceof Error && err.message.includes('EMAXCONNSESSION');
}

const sleep = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

type ConnectCallback = (
  err: Error | undefined,
  client: PoolClient | undefined,
  done: (release?: any) => void
) => void;

export class SessionPoolerPool extends Pool {
  retryDelaysMs: readonly number[] = POOLER_FULL_RETRY_DELAYS_MS;

  // pool.query() acquires through this.connect(cb), so overriding connect covers both paths.
  connect(): Promise<PoolClient>;
  connect(callback: ConnectCallback): void;
  connect(callback?: ConnectCallback): Promise<PoolClient> | void {
    const acquired = this.connectRetrying();
    if (!callback) return acquired;
    acquired.then(
      (client) => callback(undefined, client, (release?: any) => client.release(release)),
      (err: Error) => callback(err, undefined, () => {})
    );
  }

  private async connectRetrying(): Promise<PoolClient> {
    for (let attempt = 0; ; attempt++) {
      try {
        return await super.connect();
      } catch (err) {
        const delay = this.retryDelaysMs[attempt];
        if (!isPoolerFullError(err) || delay === undefined || this.ending) throw err;
        console.warn(`[pool] session pooler full; retry ${attempt + 1}/${this.retryDelaysMs.length} in ${delay}ms`);
        await sleep(delay);
      }
    }
  }

  /**
   * Call at SIGTERM. Closes every idle session now, and every busy one as soon as its query
   * releases it, so the instance being replaced stops holding pooler sessions it no longer needs.
   * The pool stays usable: a request still in flight can open a fresh session if it must.
   */
  async releaseIdleSessions(): Promise<void> {
    this.options.maxUses = 1;
    const idle: PoolClient[] = [];
    // Only take clients that are idle right now; connect() on an empty idle list would open one.
    while (this.idleCount > 0) {
      idle.push(await super.connect());
    }
    for (const client of idle) client.release(true);
  }
}
