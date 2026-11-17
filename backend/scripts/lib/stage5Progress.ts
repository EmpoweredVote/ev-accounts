/** Stage 5 progress: one state's counts and the status they add up to (scripts/stage5/progress.ts). Pure. */
export interface StateCount { state: string; sitting: number; written: number; outcomes: Record<string, number>; pending: number; scope?: number; scopeWritten?: number }
export type Status = 'done' | 'to approve' | 'part' | 'not started' | 'no roster';

export function statusOf(c: StateCount): Status {
  if (!c.written) return c.sitting < 20 ? 'no roster' : 'not started';
  if (c.scope !== undefined ? c.scopeWritten! * 10 < c.scope * 9 : c.written * 3 < c.sitting * 2) return 'part';
  return c.pending ? 'to approve' : 'done';
}
