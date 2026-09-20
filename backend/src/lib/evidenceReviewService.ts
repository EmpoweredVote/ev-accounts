export const REJECT_REASONS = [
  'off-question', 'goal-only', 'not-verbatim', 'not-primary', 'not-forward',
  'is-attack', 'stale', 'other',
] as const;

export interface PendingCandidate {
  politicianId: string; name: string; pendingGreen: number; pendingFlagged: number;
}
export interface EvidenceRow {
  id: string; issue: string; topicId: string | null; evidenceType: string;
  verbatimText: string; sourceUrl: string; deepLink: string | null; context: string | null;
  sourceType: string; machineStatus: string; gateFlags: unknown; provenance: unknown; createdAt: string;
}

export async function listCandidatesWithPending(): Promise<PendingCandidate[]> {
  const { pool } = await import('./db.js');
  const { rows } = await pool.query(
    `SELECT e.politician_id AS "politicianId",
            COALESCE(p.full_name, TRIM(COALESCE(p.preferred_name,p.first_name)||' '||p.last_name)) AS name,
            COUNT(*) FILTER (WHERE e.machine_status='green')   AS "pendingGreen",
            COUNT(*) FILTER (WHERE e.machine_status='flagged') AS "pendingFlagged"
       FROM inform.evidence_items e
       JOIN essentials.politicians p ON p.id = e.politician_id
      WHERE e.review_status='pending'
      GROUP BY e.politician_id, name
      ORDER BY COUNT(*) DESC`);
  return rows;
}

export async function listPendingEvidence(
  politicianId: string, filters: { issue?: string; machineStatus?: string } = {},
): Promise<EvidenceRow[]> {
  const { pool } = await import('./db.js');
  const params: any[] = [politicianId];
  let sql =
    `SELECT id, issue, topic_id AS "topicId", evidence_type AS "evidenceType",
            verbatim_text AS "verbatimText", source_url AS "sourceUrl", deep_link AS "deepLink",
            context, source_type AS "sourceType", machine_status AS "machineStatus",
            gate_flags AS "gateFlags", provenance, created_at AS "createdAt"
       FROM inform.evidence_items
      WHERE review_status='pending' AND politician_id=$1`;
  if (filters.issue) { params.push(filters.issue); sql += ` AND issue=$${params.length}`; }
  if (filters.machineStatus) { params.push(filters.machineStatus); sql += ` AND machine_status=$${params.length}`; }
  sql += ` ORDER BY issue, created_at`;
  const { rows } = await pool.query(sql, params);
  return rows;
}

export async function acceptEvidence(id: string, reviewerId: string): Promise<void> {
  const { pool } = await import('./db.js');
  await pool.query(
    `UPDATE inform.evidence_items
       SET review_status='accepted', reviewed_by=$2, reviewed_at=NOW(), updated_at=NOW()
     WHERE id=$1`, [id, reviewerId]);
}

export async function rejectEvidence(
  id: string, reviewerId: string, reason: string, note?: string,
): Promise<void> {
  if (!REJECT_REASONS.includes(reason as any)) throw new Error(`invalid reject reason: ${reason}`);
  const { pool } = await import('./db.js');
  await pool.query(
    `UPDATE inform.evidence_items
       SET review_status='rejected', review_reason=$3, review_note=COALESCE($4, review_note),
           reviewed_by=$2, reviewed_at=NOW(), updated_at=NOW()
     WHERE id=$1`, [id, reviewerId, reason, note ?? null]);
}

export async function rehomeEvidence(
  id: string, target: { topicId: string | null; issue: string }, reviewerId: string,
): Promise<void> {
  if (!target.issue || !target.issue.trim()) throw new Error('re-home requires a non-empty issue');
  const { pool } = await import('./db.js');
  await pool.query(
    `UPDATE inform.evidence_items
       SET topic_id=$2, issue=$3, reviewed_by=$4, updated_at=NOW()
     WHERE id=$1`, [id, target.topicId, target.issue.trim(), reviewerId]);
}

export async function evidenceReviewMetrics(): Promise<{
  byStatus: any[]; byIssue: any[]; byModel: any[]; topRejectReasons: any[];
}> {
  const { pool } = await import('./db.js');
  const decided = `review_status IN ('accepted','rejected')`;
  const prec = `ROUND(AVG((review_status='accepted')::int)::numeric, 3) AS precision,
                COUNT(*) FILTER (WHERE review_status='accepted') AS accepted,
                COUNT(*) FILTER (WHERE review_status='rejected') AS rejected`;
  const [byStatus, byIssue, byModel, topRejectReasons] = await Promise.all([
    pool.query(`SELECT machine_status AS "machineStatus", ${prec} FROM inform.evidence_items WHERE ${decided} GROUP BY 1 ORDER BY 1`),
    pool.query(`SELECT issue, ${prec} FROM inform.evidence_items WHERE ${decided} GROUP BY 1 ORDER BY rejected DESC NULLS LAST LIMIT 25`),
    pool.query(`SELECT provenance->>'judge' AS model, ${prec} FROM inform.evidence_items WHERE ${decided} GROUP BY 1 ORDER BY 1`),
    pool.query(`SELECT review_reason AS reason, COUNT(*) AS n FROM inform.evidence_items WHERE review_status='rejected' AND review_reason IS NOT NULL GROUP BY 1 ORDER BY n DESC`),
  ]);
  return { byStatus: byStatus.rows, byIssue: byIssue.rows, byModel: byModel.rows, topRejectReasons: topRejectReasons.rows };
}
