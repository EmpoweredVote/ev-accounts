import { pool } from './db.js';

export interface PoliticianWithQuotes {
  id: string;
  name: string;
  officeTitle: string | null;
  state: string | null;
  quoteCount: number;
  selectedCount: number;
}

export async function listReadrankPoliticians(): Promise<PoliticianWithQuotes[]> {
  const { rows } = await pool.query<{
    id: string; name: string; office_title: string | null;
    state: string | null; quote_count: string; selected_count: string;
  }>(
    `SELECT p.id,
            COALESCE(p.full_name, TRIM(COALESCE(p.preferred_name, p.first_name) || ' ' || p.last_name)) AS name,
            o.title AS office_title,
            d.state,
            COUNT(q.id)::text AS quote_count,
            COUNT(q.id) FILTER (WHERE q.readrank_selected)::text AS selected_count
       FROM essentials.politicians p
       JOIN essentials.quotes q ON q.politician_id = p.id
       LEFT JOIN LATERAL (
         -- ADR 0002 phase 5: offices.politician_id is gone; occupancy resolves via current_office_holders.
         SELECT o.title, o.district_id
           FROM essentials.current_office_holders coh
           JOIN essentials.offices o ON o.id = coh.office_id
          WHERE coh.politician_id = p.id
          ORDER BY o.id DESC LIMIT 1
       ) o ON true
       LEFT JOIN essentials.districts d ON d.id = o.district_id
      GROUP BY p.id, p.full_name, p.preferred_name, p.first_name, p.last_name, o.title, d.state
      ORDER BY d.state NULLS LAST, p.last_name, p.first_name`,
  );
  return rows.map((r) => ({
    id: r.id,
    name: r.name,
    officeTitle: r.office_title,
    state: r.state,
    quoteCount: parseInt(r.quote_count, 10),
    selectedCount: parseInt(r.selected_count, 10),
  }));
}

export interface AdminQuote {
  id: string;
  quoteText: string;
  deidentifiedText: string | null;
  sourceUrl: string | null;
  sourceName: string | null;
  editorNote: string | null;
  readrankSelected: boolean;
}
/**
 * One selectable group: a candidate's quotes answering a single question.
 *
 * Named `AdminTopicQuotes` for the admin client, but grouped per QUESTION since
 * migration 1377 made the question the unit of comparison. `topicKey` is NOT
 * unique across groups — the admin page must key its radio groups on `key`, or a
 * split topic gets one radio group and the editor cannot select an answer to each
 * question.
 */
export interface AdminTopicQuotes {
  /** Stable group identity: question id, or `topic:<topic_key>` for compass-era rows. */
  key: string;
  topicKey: string;
  questionId: string | null;
  /** NULL for compass-era rows that answer no readrank_question. */
  questionText: string | null;
  quotes: AdminQuote[];
}

export async function listReadrankQuotes(politicianId: string): Promise<AdminTopicQuotes[]> {
  const { rows } = await pool.query<{
    id: string; topic_key: string; question_id: string | null; question_text: string | null;
    quote_text: string; deidentified_text: string | null;
    source_url: string | null; source_name: string | null; editor_note: string | null;
    readrank_selected: boolean;
  }>(
    `SELECT q.id, lower(q.topic_key) AS topic_key, q.question_id,
            rq.question_text, q.quote_text, q.deidentified_text,
            q.source_url, q.source_name, q.editor_note, q.readrank_selected
       FROM essentials.quotes q
       LEFT JOIN essentials.readrank_questions rq ON rq.id = q.question_id
      WHERE q.politician_id = $1
      ORDER BY lower(q.topic_key) ASC, rq.question_text ASC NULLS FIRST, q.question_id ASC NULLS FIRST,
               q.readrank_selected DESC, q.created_at ASC NULLS LAST, q.id ASC`,
    [politicianId],
  );
  const byCard = new Map<string, AdminTopicQuotes>();
  const order: string[] = [];
  for (const r of rows) {
    const key = r.question_id ?? `topic:${r.topic_key}`;
    if (!byCard.has(key)) {
      byCard.set(key, {
        key,
        topicKey: r.topic_key,
        questionId: r.question_id,
        questionText: r.question_text,
        quotes: [],
      });
      order.push(key);
    }
    byCard.get(key)!.quotes.push({
      id: r.id, quoteText: r.quote_text, deidentifiedText: r.deidentified_text,
      sourceUrl: r.source_url, sourceName: r.source_name, editorNote: r.editor_note,
      readrankSelected: r.readrank_selected,
    });
  }
  return order.map((k) => byCard.get(k)!);
}

export interface ReadrankQuoteUpdate {
  quoteText: string;
  deidentifiedText: string | null;
  sourceUrl: string | null;
  sourceName: string | null;
  editorNote: string | null;
}

export async function updateReadrankQuote(quoteId: string, fields: ReadrankQuoteUpdate): Promise<void> {
  const { rows } = await pool.query<{ readrank_selected: boolean }>(
    `SELECT readrank_selected FROM essentials.quotes WHERE id = $1`,
    [quoteId],
  );
  if (rows.length === 0) throw new Error('Quote not found');

  const deidentifiedText = fields.deidentifiedText;
  // Mirror the selectReadrankQuote guard: a selected quote must keep de-identified text.
  if (rows[0].readrank_selected && !deidentifiedText?.trim()) {
    throw new Error('Cannot remove de-identified text from a selected quote');
  }

  await pool.query(
    `UPDATE essentials.quotes
        SET quote_text = $2, deidentified_text = $3, source_url = $4, source_name = $5, editor_note = $6
      WHERE id = $1`,
    [quoteId, fields.quoteText, deidentifiedText, fields.sourceUrl, fields.sourceName, fields.editorNote],
  );
}

export async function deleteReadrankQuote(quoteId: string): Promise<void> {
  const { rowCount } = await pool.query(`DELETE FROM essentials.quotes WHERE id = $1`, [quoteId]);
  if (!rowCount) throw new Error('Quote not found');
}

/** Turn a candidate off for Read & Rank by clearing selected quotes. Pass a
 *  questionId to turn off ONE question in a topic that hosts several; omit it to
 *  clear the whole topic. Idempotent (a no-op when nothing was selected); the
 *  partial unique index permits zero selected, so this is always schema-legal. */
export async function clearReadrankSelection(
  politicianId: string,
  topicKey: string,
  questionId?: string | null,
): Promise<void> {
  if (questionId) {
    await pool.query(
      `UPDATE essentials.quotes SET readrank_selected = false
        WHERE politician_id = $1 AND question_id = $2`,
      [politicianId, questionId],
    );
    return;
  }
  await pool.query(
    `UPDATE essentials.quotes SET readrank_selected = false
      WHERE politician_id = $1 AND lower(topic_key) = lower($2)`,
    [politicianId, topicKey],
  );
}

/**
 * Make this quote the candidate's served answer, clearing the one it replaces.
 *
 * Scoped to the QUESTION, not the topic (migration 1377 made the question the unit
 * of comparison). A topic-wide clear here was the live trap: with two questions in
 * one topic, selecting a quote on the second question silently unselected the
 * candidate's answer to the first. The two questions then held one candidate each,
 * which satisfied the partial unique index without error — and the game paired
 * answers to DIFFERENT questions on one card. See
 * .planning/todos/2026-08-17-readrank-question-as-unit-vs-topic.md.
 *
 * Compass-era quotes (question_id IS NULL) predate 1377 and still group by topic,
 * so their clear is per (candidate, topic) — but restricted to question_id IS NULL
 * so it cannot reach across and clear the topic's question-bearing selections.
 */
export async function selectReadrankQuote(quoteId: string): Promise<void> {
  const { rows } = await pool.query<{
    politician_id: string; topic_key: string; question_id: string | null; deidentified_text: string | null;
  }>(
    `SELECT politician_id, topic_key, question_id, deidentified_text
       FROM essentials.quotes WHERE id = $1`,
    [quoteId],
  );
  if (rows.length === 0) throw new Error('Quote not found');
  const { politician_id, topic_key, question_id, deidentified_text } = rows[0];
  if (!deidentified_text) throw new Error('Cannot select a quote with no de-identified text');

  const clearSql = question_id
    ? `UPDATE essentials.quotes SET readrank_selected = false
        WHERE politician_id = $1 AND question_id = $2`
    : `UPDATE essentials.quotes SET readrank_selected = false
        WHERE politician_id = $1 AND lower(topic_key) = lower($2) AND question_id IS NULL`;
  const clearArg = question_id ?? topic_key;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(clearSql, [politician_id, clearArg]);
    await client.query(`UPDATE essentials.quotes SET readrank_selected = true WHERE id = $1`, [quoteId]);
    await client.query('COMMIT');
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}
