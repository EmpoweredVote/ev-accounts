/**
 * Pure grouping for the research-review list (task 5, requirement 2): pending rows grouped by
 * topic, then by body/chamber, so one reviewer can work a whole cohort against one ladder instead
 * of hopping topics row by row. No DB access here — the API already carries `bodyLabel` on each
 * row (a DISTINCT-ON-deduped join server-side; see researchEvidenceService.ts), so this only
 * shapes what is already on the wire.
 */

/** The label used when the politician holds no current office (bodyLabel is null). */
export const UNKNOWN_BODY = 'No current office';

export interface GroupableResearchRow {
  topicKey: string;
  bodyLabel: string | null;
}

export interface BodyGroup<T> {
  body: string;
  rows: T[];
}

export interface TopicGroup<T> {
  topicKey: string;
  count: number;
  bodies: BodyGroup<T>[];
}

/**
 * Groups rows by topicKey, then by bodyLabel (falling back to UNKNOWN_BODY). Both levels sort
 * alphabetically for a stable, predictable order — the same rows always land in the same place on
 * screen, run to run. `count` is the topic's total across every body, for the group header.
 */
export function groupResearchReviewRows<T extends GroupableResearchRow>(rows: T[]): TopicGroup<T>[] {
  const byTopic = new Map<string, Map<string, T[]>>();
  for (const row of rows) {
    const body = row.bodyLabel ?? UNKNOWN_BODY;
    let byBody = byTopic.get(row.topicKey);
    if (!byBody) { byBody = new Map(); byTopic.set(row.topicKey, byBody); }
    let bucket = byBody.get(body);
    if (!bucket) { bucket = []; byBody.set(body, bucket); }
    bucket.push(row);
  }

  return [...byTopic.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([topicKey, byBody]) => {
      const bodies = [...byBody.entries()]
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([body, groupRows]) => ({ body, rows: groupRows }));
      const count = bodies.reduce((n, g) => n + g.rows.length, 0);
      return { topicKey, count, bodies };
    });
}
