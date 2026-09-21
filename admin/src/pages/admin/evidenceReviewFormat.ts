export const REJECT_REASONS = ['off-question','goal-only','not-verbatim','not-primary','not-forward','is-attack','stale','other'] as const;
export function statusBadge(machineStatus: string): { label: string; kind: 'green' | 'flagged' } {
  return machineStatus === 'green' ? { label: 'green', kind: 'green' } : { label: 'flagged', kind: 'flagged' };
}
export function flagReasons(gateFlags: any): string[] {
  return Array.isArray(gateFlags?.reasons) ? gateFlags.reasons : [];
}
export function pct(v: number | null | undefined): string {
  return v === null || v === undefined ? 'n/a' : Number(v).toFixed(2);
}
