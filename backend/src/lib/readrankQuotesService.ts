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
         SELECT title, district_id
           FROM essentials.offices
          WHERE politician_id = p.id
          ORDER BY id DESC LIMIT 1
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
  readrankSelected: boolean;
}
export interface AdminTopicQuotes {
  topicKey: string;
  quotes: AdminQuote[];
}

export async function listReadrankQuotes(politicianId: string): Promise<AdminTopicQuotes[]> {
  const { rows } = await pool.query<{
    id: string; topic_key: string; quote_text: string; deidentified_text: string | null;
    source_url: string | null; source_name: string | null; readrank_selected: boolean;
  }>(
    `SELECT id, lower(topic_key) AS topic_key, quote_text, deidentified_text,
            source_url, source_name, readrank_selected
       FROM essentials.quotes
      WHERE politician_id = $1
      ORDER BY lower(topic_key) ASC, readrank_selected DESC, created_at ASC NULLS LAST, id ASC`,
    [politicianId],
  );
  const byTopic = new Map<string, AdminTopicQuotes>();
  const order: string[] = [];
  for (const r of rows) {
    if (!byTopic.has(r.topic_key)) { byTopic.set(r.topic_key, { topicKey: r.topic_key, quotes: [] }); order.push(r.topic_key); }
    byTopic.get(r.topic_key)!.quotes.push({
      id: r.id, quoteText: r.quote_text, deidentifiedText: r.deidentified_text,
      sourceUrl: r.source_url, sourceName: r.source_name, readrankSelected: r.readrank_selected,
    });
  }
  return order.map((k) => byTopic.get(k)!);
}

export async function selectReadrankQuote(quoteId: string): Promise<void> {
  const { rows } = await pool.query<{ politician_id: string; topic_key: string; deidentified_text: string | null }>(
    `SELECT politician_id, topic_key, deidentified_text FROM essentials.quotes WHERE id = $1`,
    [quoteId],
  );
  if (rows.length === 0) throw new Error('Quote not found');
  const { politician_id, topic_key, deidentified_text } = rows[0];
  if (!deidentified_text) throw new Error('Cannot select a quote with no de-identified text');

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(
      `UPDATE essentials.quotes SET readrank_selected = false
        WHERE politician_id = $1 AND lower(topic_key) = lower($2)`,
      [politician_id, topic_key],
    );
    await client.query(`UPDATE essentials.quotes SET readrank_selected = true WHERE id = $1`, [quoteId]);
    await client.query('COMMIT');
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}
