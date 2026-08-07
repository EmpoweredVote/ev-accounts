import { pool } from './db.js';
import { listRaceQuestions, type RaceQuestion } from './readrankQuestionsService.js';

export type CellState = 'live' | 'draft' | 'none';

export interface RaceCandidate { politicianId: string; fullName: string; }
export interface CoverageCell { questionId: string; politicianId: string; state: CellState; }
export interface RaceOption { raceId: string; positionName: string; }
export interface CoverageGrid {
  questions: RaceQuestion[];
  candidates: RaceCandidate[];
  cells: CoverageCell[];
}

interface CandidateRow { politician_id: string; full_name: string; }
interface CellRow { question_id: string; politician_id: string; has_live: boolean; quote_count: string; }
interface RaceRow { race_id: string; position_name: string; }

export function cellState(hasLive: boolean, quoteCount: number): CellState {
  if (hasLive) return 'live';
  if (quoteCount > 0) return 'draft';
  return 'none';
}

const LIST_CANDIDATES_SQL = `
  SELECT DISTINCT rc.politician_id::text AS politician_id,
         COALESCE(p.full_name, rc.full_name) AS full_name
  FROM essentials.race_candidates rc
  LEFT JOIN essentials.politicians p ON p.id = rc.politician_id
  WHERE rc.race_id = $1
    AND rc.politician_id IS NOT NULL
    AND essentials.is_live_candidate(rc.candidate_status, rc.result)
  ORDER BY full_name
`;

export async function listRaceCandidates(raceId: string): Promise<RaceCandidate[]> {
  const { rows } = await pool.query<CandidateRow>(LIST_CANDIDATES_SQL, [raceId]);
  return rows.map((r) => ({ politicianId: r.politician_id, fullName: r.full_name }));
}

const CELLS_SQL = `
  SELECT rq.id::text            AS question_id,
         q.politician_id::text  AS politician_id,
         bool_or(q.readrank_selected AND q.deidentified_text IS NOT NULL) AS has_live,
         count(*)::text         AS quote_count
  FROM essentials.readrank_questions rq
  JOIN essentials.quotes q ON q.question_id = rq.id
  JOIN essentials.race_candidates rc
    ON rc.race_id = rq.race_id
   AND rc.politician_id = q.politician_id
   AND essentials.is_live_candidate(rc.candidate_status, rc.result)
  WHERE rq.race_id = $1 AND rq.status = 'confirmed'
  GROUP BY rq.id, q.politician_id
`;

export async function getCoverageGrid(raceId: string): Promise<CoverageGrid> {
  const questions = await listRaceQuestions(raceId);
  const candidates = await listRaceCandidates(raceId);
  const { rows } = await pool.query<CellRow>(CELLS_SQL, [raceId]);
  const cells = rows.map((r) => ({
    questionId: r.question_id,
    politicianId: r.politician_id,
    state: cellState(r.has_live, Number(r.quote_count)),
  }));
  return { questions, candidates, cells };
}

const SEARCH_RACES_SQL = `
  SELECT r.id::text AS race_id, r.position_name
  FROM essentials.races r
  WHERE r.position_name ILIKE $1
  ORDER BY r.position_name
  LIMIT 25
`;

export async function searchRaces(query: string): Promise<RaceOption[]> {
  const { rows } = await pool.query<RaceRow>(SEARCH_RACES_SQL, [`%${query}%`]);
  return rows.map((r) => ({ raceId: r.race_id, positionName: r.position_name }));
}
