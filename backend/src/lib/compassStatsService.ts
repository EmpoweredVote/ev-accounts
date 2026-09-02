import { pool } from './db.js';

export interface StanceCount {
  id: string; // inform.compass_stances.id — stable handle for per-stance references
  value: number; // integer 1-5
  text: string;
  users: number; // count from inform.compass_responses (user answers)
  politicians: number; // count from inform.politician_answers
}

// Responses whose value sits between stances (0.5 grid: 0.5, 1.5, ... 5.5).
// These are write-in placements and must not be rounded into a stance bucket.
// Politician answers are integer-valued, so in practice only users land here,
// but both cohorts are carried for uniformity.
export interface BetweenCount {
  value: number;
  users: number;
  politicians: number;
}

export interface TopicBreakdown {
  topicId: string;
  title: string;
  shortTitle: string | null;
  isLive: boolean;
  userResponses: number;
  politicianAnswers: number;
  userWriteIns: number;
  politicianWriteIns: number;
  stances: StanceCount[];
  betweens: BetweenCount[];
}

export interface StanceBreakdownReport {
  totals: {
    userResponses: number;
    users: number;
    politicianAnswers: number;
    politicians: number;
  };
  topics: TopicBreakdown[];
}

interface StanceRow {
  topic_id: string;
  title: string;
  short_title: string | null;
  is_live: boolean;
  stance_id: string | null;
  stance_value: number | null;
  stance_text: string | null;
}

interface CountRow {
  topic_id: string;
  value: number;
  n: number;
  write_ins: number;
}

// TEXT ONLY (ADR 0004). `t` stays the row source and the sole authority on
// is_live — this endpoint REPORTS promotion state, so it must keep reading it —
// while `tc`/`sc` supply the current revision's wording for topics and rungs.
// CA_0012 froze compass_topics/compass_stances' own text columns, so without
// this an admin looking at stats would never see a published revision land.
// Neither join can fan out: one current revision per topic
// (compass_topic_revisions_one_current), and the stance view is keyed on that
// same revision, so it yields one row per (topic, value).
const STANCES_SQL = `
  SELECT t.id::text       AS topic_id,
         tc.title,
         tc.short_title,
         t.is_live,
         s.id::text       AS stance_id,
         s.value::int     AS stance_value,
         -- Capitalize the first letter for display, matching the voter read path
         -- (ADR 0006 / #217). Stored text stays lowercase, verb-first.
         upper(left(sc.text, 1)) || substr(sc.text, 2) AS stance_text
  FROM inform.compass_topics t
  JOIN inform.compass_topics_current tc ON tc.id = t.id
  LEFT JOIN inform.compass_stances s ON s.topic_id = t.id
  LEFT JOIN inform.compass_stances_current sc
    ON sc.topic_id = t.id AND sc.value = s.value
  ORDER BY tc.title ASC, s.value ASC
`;

const USER_COUNTS_SQL = `
  SELECT topic_id::text AS topic_id,
         value::float8  AS value,
         COUNT(*)::int  AS n,
         (COUNT(*) FILTER (WHERE write_in_text IS NOT NULL))::int AS write_ins
  FROM inform.compass_responses_current
  WHERE deleted_at IS NULL
  GROUP BY topic_id, value
`;

// politician_answers has no soft-delete column; every row is live.
//
// ONE ANSWER PER POLITICIAN PER TOPIC — THEIR LATEST. A plain COUNT(*) over the
// table would count someone researched in two seasons twice, weighting them
// double in the distribution and inflating every bar. The DISTINCT ON collapses
// each politician/topic to the newest season they actually answered in, which is
// also what the compass displays, so the chart and the profile agree.
const POLITICIAN_COUNTS_SQL = `
  WITH latest AS (
    SELECT DISTINCT ON (a.politician_id, a.topic_id)
           a.topic_id, a.value, a.write_in_text
      FROM inform.politician_answers a
      JOIN inform.seasons s ON s.id = a.season_id
     ORDER BY a.politician_id, a.topic_id, s.number DESC
  )
  SELECT topic_id::text AS topic_id,
         value::float8  AS value,
         COUNT(*)::int  AS n,
         (COUNT(*) FILTER (WHERE write_in_text IS NOT NULL))::int AS write_ins
  FROM latest
  GROUP BY topic_id, value
`;

const USER_TOTALS_SQL = `
  SELECT COUNT(*)::int                 AS responses,
         COUNT(DISTINCT user_id)::int  AS respondents
  FROM inform.compass_responses_current
  WHERE deleted_at IS NULL
`;

// Same collapse as POLITICIAN_COUNTS_SQL, and for the same reason: `responses`
// is a COUNT(*), so without it the total climbs every season on re-research
// while no new position has been recorded.
const POLITICIAN_TOTALS_SQL = `
  WITH latest AS (
    SELECT DISTINCT ON (a.politician_id, a.topic_id)
           a.politician_id
      FROM inform.politician_answers a
      JOIN inform.seasons s ON s.id = a.season_id
     ORDER BY a.politician_id, a.topic_id, s.number DESC
  )
  SELECT COUNT(*)::int                       AS responses,
         COUNT(DISTINCT politician_id)::int  AS respondents
  FROM latest
`;

interface TotalsRow {
  responses: number;
  respondents: number;
}

type Cohort = 'users' | 'politicians';

function applyCounts(
  byTopic: Map<string, TopicBreakdown>,
  rows: CountRow[],
  cohort: Cohort
): void {
  for (const row of rows) {
    const topic = byTopic.get(row.topic_id);
    if (!topic) continue; // response for a topic that no longer exists
    if (cohort === 'users') {
      topic.userResponses += row.n;
      topic.userWriteIns += row.write_ins;
    } else {
      topic.politicianAnswers += row.n;
      topic.politicianWriteIns += row.write_ins;
    }
    const stance = Number.isInteger(row.value)
      ? topic.stances.find((s) => s.value === row.value)
      : undefined;
    if (stance) {
      stance[cohort] += row.n;
      continue;
    }
    let between = topic.betweens.find((b) => b.value === row.value);
    if (!between) {
      between = { value: row.value, users: 0, politicians: 0 };
      topic.betweens.push(between);
    }
    between[cohort] += row.n;
  }
}

export async function getStanceBreakdown(): Promise<StanceBreakdownReport> {
  const [stanceRes, userCountRes, politicianCountRes, userTotalsRes, politicianTotalsRes] =
    await Promise.all([
      pool.query<StanceRow>(STANCES_SQL),
      pool.query<CountRow>(USER_COUNTS_SQL),
      pool.query<CountRow>(POLITICIAN_COUNTS_SQL),
      pool.query<TotalsRow>(USER_TOTALS_SQL),
      pool.query<TotalsRow>(POLITICIAN_TOTALS_SQL),
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
        userResponses: 0,
        politicianAnswers: 0,
        userWriteIns: 0,
        politicianWriteIns: 0,
        stances: [],
        betweens: [],
      };
      byTopic.set(row.topic_id, topic);
    }
    // LEFT JOIN yields null stance columns for topics that have no stances yet.
    if (row.stance_id !== null && row.stance_value !== null && row.stance_text !== null) {
      topic.stances.push({
        id: row.stance_id,
        value: row.stance_value,
        text: row.stance_text,
        users: 0,
        politicians: 0,
      });
    }
  }

  applyCounts(byTopic, userCountRes.rows, 'users');
  applyCounts(byTopic, politicianCountRes.rows, 'politicians');

  const topics = [...byTopic.values()];
  for (const t of topics) t.betweens.sort((a, b) => a.value - b.value);
  topics.sort(
    (a, b) =>
      b.politicianAnswers + b.userResponses - (a.politicianAnswers + a.userResponses) ||
      a.title.localeCompare(b.title)
  );

  const userTotals = userTotalsRes.rows[0] ?? { responses: 0, respondents: 0 };
  const politicianTotals = politicianTotalsRes.rows[0] ?? { responses: 0, respondents: 0 };
  return {
    totals: {
      userResponses: userTotals.responses,
      users: userTotals.respondents,
      politicianAnswers: politicianTotals.responses,
      politicians: politicianTotals.respondents,
    },
    topics,
  };
}
