import { pool } from './db.js';

export interface StanceCount {
  value: number; // integer 1-5
  text: string;
  count: number;
}

// Responses whose value sits between stances (0.5 grid: 0.5, 1.5, ... 5.5).
// These are write-in placements and must not be rounded into a stance bucket.
export interface BetweenCount {
  value: number;
  count: number;
}

export interface TopicBreakdown {
  topicId: string;
  title: string;
  shortTitle: string | null;
  isLive: boolean;
  totalResponses: number;
  writeInCount: number;
  stances: StanceCount[];
  betweens: BetweenCount[];
}

export interface StanceBreakdownReport {
  totals: { responses: number; users: number };
  topics: TopicBreakdown[];
}

interface StanceRow {
  topic_id: string;
  title: string;
  short_title: string | null;
  is_live: boolean;
  stance_value: number | null;
  stance_text: string | null;
}

interface CountRow {
  topic_id: string;
  value: number;
  n: number;
  write_ins: number;
}

interface TotalsRow {
  responses: number;
  users: number;
}

const STANCES_SQL = `
  SELECT t.id::text       AS topic_id,
         t.title,
         t.short_title,
         t.is_live,
         s.value::int     AS stance_value,
         s.text           AS stance_text
  FROM inform.compass_topics t
  LEFT JOIN inform.compass_stances s ON s.topic_id = t.id
  ORDER BY t.title ASC, s.value ASC
`;

const COUNTS_SQL = `
  SELECT topic_id::text AS topic_id,
         value::float8  AS value,
         COUNT(*)::int  AS n,
         (COUNT(*) FILTER (WHERE write_in_text IS NOT NULL))::int AS write_ins
  FROM inform.compass_responses
  WHERE deleted_at IS NULL
  GROUP BY topic_id, value
`;

const TOTALS_SQL = `
  SELECT COUNT(*)::int                 AS responses,
         COUNT(DISTINCT user_id)::int  AS users
  FROM inform.compass_responses
  WHERE deleted_at IS NULL
`;

export async function getStanceBreakdown(): Promise<StanceBreakdownReport> {
  const [stanceRes, countRes, totalsRes] = await Promise.all([
    pool.query<StanceRow>(STANCES_SQL),
    pool.query<CountRow>(COUNTS_SQL),
    pool.query<TotalsRow>(TOTALS_SQL),
  ]);

  const byTopic = new Map<string, TopicBreakdown>();
  for (const row of stanceRes.rows) {
    let topic = byTopic.get(row.topic_id);
    if (!topic) {
      topic = {
        topicId: row.topic_id,
        title: row.title,
        shortTitle: row.short_title,
        isLive: row.is_live,
        totalResponses: 0,
        writeInCount: 0,
        stances: [],
        betweens: [],
      };
      byTopic.set(row.topic_id, topic);
    }
    if (row.stance_value !== null && row.stance_text !== null) {
      topic.stances.push({ value: row.stance_value, text: row.stance_text, count: 0 });
    }
  }

  for (const row of countRes.rows) {
    const topic = byTopic.get(row.topic_id);
    if (!topic) continue; // response for a topic that no longer exists
    topic.totalResponses += row.n;
    topic.writeInCount += row.write_ins;
    const stance = Number.isInteger(row.value)
      ? topic.stances.find((s) => s.value === row.value)
      : undefined;
    if (stance) {
      stance.count += row.n;
    } else {
      topic.betweens.push({ value: row.value, count: row.n });
    }
  }

  const topics = [...byTopic.values()];
  for (const t of topics) t.betweens.sort((a, b) => a.value - b.value);
  topics.sort(
    (a, b) => b.totalResponses - a.totalResponses || a.title.localeCompare(b.title)
  );

  const totals = totalsRes.rows[0] ?? { responses: 0, users: 0 };
  return { totals: { responses: totals.responses, users: totals.users }, topics };
}
