import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { listRaceQuestions } from './readrankQuestionsService.js';

describe('listRaceQuestions', () => {
  beforeEach(() => mockQuery.mockReset());

  it('queries readrank_questions for the race and maps rankable/surfaced from candidate counts', async () => {
    // pg returns COUNT(...) as a string; two answers -> rankable, one -> surfaced only, zero -> neither.
    mockQuery.mockResolvedValueOnce({
      rows: [
        { question_id: 'q-rankable', topic_key: 'economic-development', question_text: 'Should the state legalize gambling?', origin: 'emergent', status: 'confirmed', answering_candidates: '2' },
        { question_id: 'q-solo', topic_key: 'religious-freedom', question_text: 'What role should religion play in government?', origin: 'emergent', status: 'confirmed', answering_candidates: '1' },
        { question_id: 'q-empty', topic_key: 'healthcare', question_text: 'What role should government play in healthcare access?', origin: 'compass', status: 'confirmed', answering_candidates: '0' },
      ],
    });

    const result = await listRaceQuestions('race-123');

    expect(mockQuery).toHaveBeenCalledTimes(1);
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toContain('essentials.readrank_questions');
    expect(sql).toContain('q.question_id = rq.id');
    expect(sql).toContain('q.readrank_selected = true');
    expect(sql).toContain("rq.status = 'confirmed'");
    expect(params).toEqual(['race-123']);

    expect(result).toEqual([
      { questionId: 'q-rankable', topicKey: 'economic-development', questionText: 'Should the state legalize gambling?', origin: 'emergent', status: 'confirmed', answeringCandidates: 2, rankable: true, surfaced: true },
      { questionId: 'q-solo', topicKey: 'religious-freedom', questionText: 'What role should religion play in government?', origin: 'emergent', status: 'confirmed', answeringCandidates: 1, rankable: false, surfaced: true },
      { questionId: 'q-empty', topicKey: 'healthcare', questionText: 'What role should government play in healthcare access?', origin: 'compass', status: 'confirmed', answeringCandidates: 0, rankable: false, surfaced: false },
    ]);
  });
});
