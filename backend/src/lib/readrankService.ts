import crypto from 'node:crypto';
import { pool } from './db.js';
import { env } from './env.js';

/**
 * Read & Rank — blind candidate-match election tool.
 *
 * Hard rules enforced here:
 *  - Blind payloads NEVER expose quote_text, politician_id, source, or photo.
 *    Only deidentified_text + an opaque candidateToken leave the server.
 *  - The API NEVER falls back to raw quote_text. A quote with no
 *    deidentified_text is simply not served (the blind premise must hold).
 *  - Identities are de-masked ONLY by the reveal (computeRaceMatch).
 */

const ESSENTIALS_BASE = 'https://essentials.empowered.vote';
const TOKEN_SECRET = process.env.READRANK_TOKEN_SECRET || env.SUPABASE_SERVICE_ROLE_KEY;

/** Opaque, deterministic per-candidate token, scoped to a race. Not reversible client-side. */
function candidateToken(raceId: string, politicianId: string): string {
  return crypto
    .createHmac('sha256', TOKEN_SECRET)
    .update(`${raceId}:${politicianId}`)
    .digest('hex')
    .slice(0, 16);
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface RaceSummary {
  raceId: string;
  positionName: string;
  electionName: string;
  electionDate: string | null;
  state: string | null;
  jurisdictionLevel: string | null;
  candidateCount: number;
  topicCount: number;
  isLocal: boolean;
}

export interface BlindQuote {
  id: string;
  text: string;
  candidateToken: string;
  topicKey: string;
}

export interface RacePayload {
  raceId: string;
  positionName: string;
  topics: Array<{ topicKey: string; title: string; question: string; quotes: BlindQuote[] }>;
}

export interface VerdictInput {
  quote_id: string;
  supported: boolean;
  rank: number | null;
}

export interface BallotEntry {
  rank: number;
  candidateId: string;
  party: string;
  name: string;
  office: string;
  photo: string;
  essentialsUrl: string;
  evidence: { agreementCount: number; firstPlaceCount: number; topicsWithAgreement: number };
  perTopic: Array<{
    topicKey: string;
    title: string;
    userTopWinner: boolean;
    quotes: Array<{ quoteId: string; text: string; supported: boolean; rank: number | null; sourceName?: string; sourceUrl?: string }>;
  }>;
  score?: number;
}

export interface RevealResult {
  raceId: string;
  positionName: string;
  ballot: BallotEntry[];
}

// ---------------------------------------------------------------------------
// 1. Playable races
// ---------------------------------------------------------------------------

export async function getPlayableRaces(politicianIds?: string[]): Promise<RaceSummary[]> {
  const { rows } = await pool.query<{
    race_id: string; position_name: string; election_id: string; election_name: string;
    election_date: Date | null; jurisdiction_level: string | null; state: string | null;
    candidate_count: string; topic_count: string; politician_ids: string[];
  }>(`
    SELECT r.id AS race_id, r.position_name,
           e.id AS election_id, e.name AS election_name, e.election_date,
           e.jurisdiction_level, e.state,
           COUNT(DISTINCT rc.politician_id)        AS candidate_count,
           COUNT(DISTINCT lower(q.topic_key))      AS topic_count,
           array_agg(DISTINCT rc.politician_id)    AS politician_ids
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.race_candidates rc
      ON rc.race_id = r.id
     AND rc.politician_id IS NOT NULL
     AND COALESCE(rc.candidate_status, 'active') <> 'withdrawn'
    JOIN essentials.quotes q
      ON q.politician_id = rc.politician_id
     AND q.deidentified_text IS NOT NULL
     AND q.readrank_selected = true
    JOIN inform.compass_topics ct
      ON ct.topic_key = lower(q.topic_key) AND ct.is_live = true
    GROUP BY r.id, r.position_name, e.id, e.name, e.election_date, e.jurisdiction_level, e.state
    HAVING COUNT(DISTINCT rc.politician_id) >= 2
    ORDER BY e.election_date ASC NULLS LAST
  `);

  const localSet = new Set(politicianIds ?? []);
  return rows.map((r) => ({
    raceId: r.race_id,
    positionName: r.position_name,
    electionName: r.election_name,
    electionDate: r.election_date ? new Date(r.election_date).toISOString().slice(0, 10) : null,
    state: r.state,
    jurisdictionLevel: r.jurisdiction_level,
    candidateCount: Number(r.candidate_count),
    topicCount: Number(r.topic_count),
    isLocal: localSet.size > 0 && (r.politician_ids ?? []).some((id) => localSet.has(id)),
  }));
}

// ---------------------------------------------------------------------------
// 2. Blind, topic-grouped quotes for a race
// ---------------------------------------------------------------------------

export async function getRaceBlindQuotes(raceId: string): Promise<RacePayload | null> {
  const { rows } = await pool.query<{
    quote_id: string; deidentified_text: string; topic_key: string; politician_id: string;
    topic_title: string; topic_question: string; position_name: string;
  }>(`
    SELECT q.id AS quote_id, q.deidentified_text, lower(q.topic_key) AS topic_key,
           q.politician_id,
           ct.short_title AS topic_title, ct.question_text AS topic_question,
           r.position_name
    FROM essentials.races r
    JOIN essentials.race_candidates rc
      ON rc.race_id = r.id
     AND rc.politician_id IS NOT NULL
     AND COALESCE(rc.candidate_status, 'active') <> 'withdrawn'
    JOIN essentials.quotes q
      ON q.politician_id = rc.politician_id
     AND q.deidentified_text IS NOT NULL
     AND q.readrank_selected = true
    JOIN inform.compass_topics ct
      ON ct.topic_key = lower(q.topic_key) AND ct.is_live = true
    WHERE r.id = $1
    ORDER BY ct.short_title
  `, [raceId]);

  if (rows.length === 0) return null;

  const positionName = rows[0].position_name;
  const topicOrder: string[] = [];
  const byTopic = new Map<string, RacePayload['topics'][number]>();

  for (const row of rows) {
    let topic = byTopic.get(row.topic_key);
    if (!topic) {
      topic = { topicKey: row.topic_key, title: row.topic_title ?? '', question: row.topic_question ?? '', quotes: [] };
      byTopic.set(row.topic_key, topic);
      topicOrder.push(row.topic_key);
    }
    topic.quotes.push({
      id: row.quote_id,
      text: row.deidentified_text, // NEVER quote_text
      candidateToken: candidateToken(raceId, row.politician_id),
      topicKey: row.topic_key,
    });
  }

  return { raceId, positionName, topics: topicOrder.map((k) => byTopic.get(k)!) };
}

// ---------------------------------------------------------------------------
// 3. Verdict + rank candidate match (the reveal) — de-masks identities
// ---------------------------------------------------------------------------

const rankBonus = (rank: number | null) => (rank === 1 ? 3 : rank === 2 ? 2 : rank === 3 ? 1 : 0.5);

export async function computeRaceMatch(
  raceId: string,
  verdicts: VerdictInput[],
  exposeScore = false
): Promise<RevealResult | null> {
  const quoteIds = verdicts.map((v) => v.quote_id);
  if (quoteIds.length === 0) return { raceId, positionName: '', ballot: [] };

  const { rows } = await pool.query<{
    quote_id: string; politician_id: string; topic_key: string; deidentified_text: string;
    source_name: string | null; source_url: string | null; full_name: string;
    photo: string | null; office_title: string | null; topic_title: string; position_name: string;
  }>(`
    SELECT q.id AS quote_id, q.politician_id, lower(q.topic_key) AS topic_key,
           q.deidentified_text, q.source_name, q.source_url,
           p.full_name, p.photo_origin_url AS photo,
           o.title AS office_title, ct.short_title AS topic_title, r.position_name
    FROM essentials.races r
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id IS NOT NULL
    JOIN essentials.quotes q ON q.politician_id = rc.politician_id AND q.deidentified_text IS NOT NULL AND q.readrank_selected = true
    JOIN essentials.politicians p ON p.id = q.politician_id
    LEFT JOIN LATERAL (
      SELECT title FROM essentials.offices WHERE politician_id = p.id ORDER BY id DESC LIMIT 1
    ) o ON true
    JOIN inform.compass_topics ct ON ct.topic_key = lower(q.topic_key) AND ct.is_live = true
    WHERE r.id = $1 AND q.id = ANY($2::uuid[])
  `, [raceId, quoteIds]);

  if (rows.length === 0) return { raceId, positionName: '', ballot: [] };

  const positionName = rows[0].position_name;
  const verdictByQuote = new Map(verdicts.map((v) => [v.quote_id, v]));

  interface Agg {
    politicianId: string; name: string; photo: string; office: string;
    agreementCount: number; firstPlaceCount: number; score: number;
    topicsWithAgreement: Set<string>;
    perTopic: Map<string, BallotEntry['perTopic'][number]>;
  }
  const aggs = new Map<string, Agg>();
  const topicBest: Record<string, { pid: string; rank: number }> = {};

  for (const row of rows) {
    const v = verdictByQuote.get(row.quote_id);
    if (!v) continue;
    let a = aggs.get(row.politician_id);
    if (!a) {
      a = {
        politicianId: row.politician_id, name: row.full_name, photo: row.photo ?? '',
        office: row.office_title || 'Candidate',
        agreementCount: 0, firstPlaceCount: 0, score: 0,
        topicsWithAgreement: new Set(), perTopic: new Map(),
      };
      aggs.set(row.politician_id, a);
    }
    let pt = a.perTopic.get(row.topic_key);
    if (!pt) {
      pt = { topicKey: row.topic_key, title: row.topic_title ?? '', userTopWinner: false, quotes: [] };
      a.perTopic.set(row.topic_key, pt);
    }
    pt.quotes.push({
      quoteId: row.quote_id, text: row.deidentified_text, supported: v.supported, rank: v.rank,
      sourceName: row.source_name ?? undefined, sourceUrl: row.source_url ?? undefined,
    });
    if (v.supported) {
      a.agreementCount += 1;
      a.score += rankBonus(v.rank);
      a.topicsWithAgreement.add(row.topic_key);
      if (v.rank === 1) a.firstPlaceCount += 1;
      if (v.rank != null) {
        const best = topicBest[row.topic_key];
        if (!best || v.rank < best.rank) topicBest[row.topic_key] = { pid: row.politician_id, rank: v.rank };
      }
    }
  }

  // Only candidates the user agreed with at least once appear on the ballot.
  const ranked = [...aggs.values()]
    .filter((a) => a.agreementCount > 0)
    .sort((x, y) => y.score - x.score || y.agreementCount - x.agreementCount || y.firstPlaceCount - x.firstPlaceCount || x.name.localeCompare(y.name));

  const ballot: BallotEntry[] = ranked.map((a, i) => {
    for (const pt of a.perTopic.values()) pt.userTopWinner = topicBest[pt.topicKey]?.pid === a.politicianId;
    const entry: BallotEntry = {
      rank: i + 1,
      candidateId: a.politicianId,
      party: '', // antipartisan — party intentionally not transmitted
      name: a.name,
      office: a.office,
      photo: a.photo,
      essentialsUrl: `${ESSENTIALS_BASE}/politician/${a.politicianId}`,
      evidence: {
        agreementCount: a.agreementCount,
        firstPlaceCount: a.firstPlaceCount,
        topicsWithAgreement: a.topicsWithAgreement.size,
      },
      perTopic: [...a.perTopic.values()],
    };
    if (exposeScore) entry.score = a.score;
    return entry;
  });

  return { raceId, positionName, ballot };
}
