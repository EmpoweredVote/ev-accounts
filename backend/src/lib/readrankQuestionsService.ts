import { pool } from './db.js';

export type QuestionOrigin = 'compass' | 'moderator' | 'emergent';
export type QuestionStatus = 'proposed' | 'confirmed' | 'rejected';

export interface RaceQuestion {
  questionId: string;
  topicKey: string;
  questionText: string;
  origin: QuestionOrigin;
  status: QuestionStatus;
  answeringCandidates: number;
  rankable: boolean; // >= 2 distinct non-withdrawn candidates with a live quote on this question
  surfaced: boolean; // >= 1
}

interface RaceQuestionRow {
  question_id: string;
  topic_key: string;
  question_text: string;
  origin: QuestionOrigin;
  status: QuestionStatus;
  answering_candidates: string; // pg returns COUNT(...) as text
}

// Per-question comparability for a race. A candidate "answers" a question when they have a
// live quote (readrank_selected + deidentified_text present) attached to it and they are a
// non-withdrawn candidate in the race. Mirrors the predicates in readrankService.ts.
// NOTE: unlike readrankService.ts (topic-level), this deliberately does NOT gate on
// inform.compass_topics.is_live. "Live quote" here is defined purely by readrank_selected +
// deidentified_text; adding an is_live join would wrongly exclude emergent/moderator questions
// whose topic_key isn't a live compass topic. Keep them divergent on purpose.
const LIST_RACE_QUESTIONS_SQL = `
  SELECT rq.id            AS question_id,
         rq.topic_key     AS topic_key,
         rq.question_text AS question_text,
         rq.origin        AS origin,
         rq.status        AS status,
         COUNT(DISTINCT rc.politician_id) AS answering_candidates
  FROM essentials.readrank_questions rq
  LEFT JOIN essentials.quotes q
    ON q.question_id = rq.id
   AND q.readrank_selected = true
   AND q.deidentified_text IS NOT NULL
  LEFT JOIN essentials.race_candidates rc
    ON rc.race_id = rq.race_id
   AND rc.politician_id = q.politician_id
   AND essentials.is_live_candidate(rc.candidate_status, rc.result)
  WHERE rq.race_id = $1
    AND rq.status = 'confirmed'
  GROUP BY rq.id, rq.topic_key, rq.question_text, rq.origin, rq.status
  ORDER BY rq.topic_key, rq.question_text
`;

export async function listRaceQuestions(raceId: string): Promise<RaceQuestion[]> {
  const { rows } = await pool.query<RaceQuestionRow>(LIST_RACE_QUESTIONS_SQL, [raceId]);
  return rows.map((r) => {
    const answeringCandidates = Number(r.answering_candidates);
    return {
      questionId: r.question_id,
      topicKey: r.topic_key,
      questionText: r.question_text,
      origin: r.origin,
      status: r.status,
      answeringCandidates,
      rankable: answeringCandidates >= 2,
      surfaced: answeringCandidates >= 1,
    };
  });
}
