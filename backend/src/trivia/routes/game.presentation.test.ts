/**
 * Behavioural replacement for the source-text-regex tests that used to live in
 * servePresentation.test.ts ("every path that puts a question in a session presents it
 * first"). Those tests grepped sessionService.ts and game.ts for a `presentQuestion(`
 * call and passed green while the adaptive-mode first question was served UNPRESENTED --
 * a Critical regression a regex cannot see, because the call site existed; only its
 * *result* was discarded.
 *
 * These tests instead drive the real HTTP routes (via supertest) against the real
 * sessionManager/MemoryStorage, and assert the one thing that actually matters: the
 * options array served to the client is byte-identical to the options array the session
 * stored and will score against. Only the DB-touching layer (questionService.js,
 * gameModes.js, telemetryService.js) is mocked.
 */
import { describe, it, expect, vi, beforeAll, beforeEach, afterEach } from 'vitest';
import express from 'express';
import request from 'supertest';
import { router as gameRouter } from './game.js';
import { initializeSessionManager, sessionManager, type Question } from '../services/sessionService.js';
import { MemoryStorage } from '../services/storage/MemoryStorage.js';

vi.mock('../services/questionService.js', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../services/questionService.js')>();
  return {
    ...actual,
    getFederalCollectionId: vi.fn().mockResolvedValue(1),
    getCollectionMetadata: vi.fn().mockResolvedValue({ id: 1, name: 'Federal Civics', slug: 'federal-civics' }),
    selectQuestionsForGame: vi.fn(),
    createAdaptiveSession: vi.fn(),
    transformSingleDBQuestion: vi.fn(),
  };
});

vi.mock('../services/gameModes.js', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../services/gameModes.js')>();
  return {
    ...actual,
    getNextQuestionTier: vi.fn().mockReturnValue(['easy', 'medium', 'hard']),
    selectNextAdaptiveQuestion: vi.fn(),
  };
});

vi.mock('../services/telemetryService.js', () => ({
  recordQuestionTelemetry: vi.fn().mockResolvedValue(undefined),
}));

// Real auth.js eagerly constructs a Supabase client at import time (config/supabase.ts),
// which throws without SUPABASE_URL/SUPABASE_SERVICE_ROLE_KEY set. These tests never send
// an Authorization header (anonymous flows only), so stub optionalAuth as a pass-through
// rather than wiring real env vars for a code path never exercised here.
vi.mock('../middleware/auth.js', () => ({
  optionalAuth: async (_req: unknown, _res: unknown, next: () => void) => next(),
}));

// progressionService.js imports lib/gemService.js -> lib/supabase.js -> lib/env.ts, whose
// startup validator calls process.exit(1) on any missing engine env var (SUPABASE_URL,
// DATABASE_URL, etc.) -- not throw, exit. None of these tests reach a final question, so
// none of these functions are ever called; the module just can't be imported at all
// without the full engine env, which is out of scope for a trivia route unit test.
vi.mock('../services/progressionService.js', () => ({
  checkAccountContext: vi.fn(),
  calculateProgression: vi.fn(),
  upsertPlayerStats: vi.fn(),
  calculateXpAmount: vi.fn(),
  awardPlatformXp: vi.fn(),
  awardPlatformGems: vi.fn(),
}));

import * as questionService from '../services/questionService.js';
import * as gameModes from '../services/gameModes.js';

function buildApp() {
  const app = express();
  app.use(express.json());
  app.use('/', gameRouter);
  return app;
}

/** Fetch what the session actually stored, bypassing the HTTP response entirely. */
async function storedQuestions(sessionId: string): Promise<Question[]> {
  const session = await sessionManager.getSession(sessionId);
  if (!session) throw new Error('session not found in storage');
  return session.questions;
}

describe('served payload matches stored session questions', () => {
  let randomSpy: ReturnType<typeof vi.spyOn>;

  beforeAll(() => {
    initializeSessionManager(new MemoryStorage());
  });

  beforeEach(() => {
    vi.clearAllMocks();
    // Deterministic throughout: a constant Math.random removes any chance-based pass.
    // For a 4-option Fisher-Yates this specific constant happens to be the identity
    // permutation (verified separately) -- irrelevant here, since these tests assert
    // served === stored, not any particular order.
    randomSpy = vi.spyOn(Math, 'random').mockReturnValue(0.99);
  });

  afterEach(() => {
    randomSpy.mockRestore();
  });

  it('classic start: response.questions equals the stored session.questions', async () => {
    const classicQuestion: Question = {
      id: 'classic-001',
      text: 'Which branch interprets laws?',
      options: ['Alpha', 'Beta', 'Gamma', 'Delta'],
      correctAnswer: 1,
      optionsScale: null,
      explanation: '',
      difficulty: 'easy',
      topic: 't',
      topicCategory: 'c',
    };
    vi.mocked(questionService.selectQuestionsForGame).mockResolvedValue([classicQuestion]);

    const app = buildApp();
    const res = await request(app).post('/session').send({ gameMode: 'classic' }).expect(201);

    const stored = await storedQuestions(res.body.sessionId);
    expect(res.body.questions).toHaveLength(stored.length);
    stored.forEach((q, i) => {
      expect(res.body.questions[i].options).toEqual(q.options);
      // stripAnswers removes correctAnswer only -- confirm it's actually gone from the wire.
      expect(res.body.questions[i]).not.toHaveProperty('correctAnswer');
    });
  });

  it('adaptive start: response.questions[0] equals the stored (rolled) session.questions[0]', async () => {
    // A scaled numeric forces a roll (not a maybe-identity shuffle), so a bug that serves
    // the pre-presentation object is GUARANTEED to differ from what was stored --
    // deterministic red/green, not a 1-in-24 chance of a flaky pass.
    const firstQuestion: Question = {
      id: 'stlmo-020',
      text: 'Population of St. Louis?',
      options: ['7', '9', '11', '13'], // the row's stored (pre-roll) window
      correctAnswer: 3,
      optionsScale: ['7', '9', '11', '13', '15', '17', '19'],
      explanation: '',
      difficulty: 'medium',
      topic: 't',
      topicCategory: 'c',
    };
    vi.mocked(questionService.createAdaptiveSession).mockResolvedValue({
      firstQuestion,
      candidatePools: { easy: [], medium: [], hard: [] },
      firstQuestionDbId: 1,
    } as any);

    const app = buildApp();
    // Math.random = 0.99 -> roll = 1 + floor(0.99 * 4) = 4 -> window scale[3..7) = ['13','15','17','19']
    const res = await request(app).post('/session').send({}).expect(201);

    const stored = await storedQuestions(res.body.sessionId);
    expect(res.body.questions).toHaveLength(1);
    expect(stored).toHaveLength(1);
    expect(res.body.questions[0].options).toEqual(stored[0].options);
    expect(res.body.questions[0].options).toEqual(['13', '15', '17', '19']);

    // Critical 2: the scale itself must never reach the wire -- it is a plaintext answer
    // key once SCALE_ANSWER_INDEX is fixed.
    expect(res.body.questions[0]).not.toHaveProperty('optionsScale');
    expect(stored[0]).not.toHaveProperty('optionsScale');
  });

  it('adaptive append: response.nextQuestion equals the stored (presented) pushed question', async () => {
    const firstQuestion: Question = {
      id: 'q-first',
      text: 'First question',
      options: ['A1', 'B1', 'C1', 'D1'],
      correctAnswer: 0,
      optionsScale: null,
      explanation: '',
      difficulty: 'easy',
      topic: 't',
      topicCategory: 'c',
    };
    vi.mocked(questionService.createAdaptiveSession).mockResolvedValue({
      firstQuestion,
      candidatePools: { easy: [], medium: [], hard: [] },
      firstQuestionDbId: 1,
    } as any);

    const app = buildApp();
    const startRes = await request(app).post('/session').send({}).expect(201);
    const sessionId = startRes.body.sessionId;
    const storedAfterStart = await storedQuestions(sessionId);
    const presentedFirst = storedAfterStart[0];

    // Next question the adaptive pool "picks" -- prose, so it goes through the shuffle
    // branch (identity, under the mocked rng) rather than a roll.
    const nextQuestion: Question = {
      id: 'q-second',
      text: 'Second question',
      options: ['M', 'N', 'O', 'P'],
      correctAnswer: 2,
      optionsScale: null,
      explanation: '',
      difficulty: 'easy',
      topic: 't',
      topicCategory: 'c',
    };
    vi.mocked(gameModes.selectNextAdaptiveQuestion).mockReturnValue({ id: 2, difficulty: 'easy' } as any);
    vi.mocked(questionService.transformSingleDBQuestion).mockResolvedValue(nextQuestion);

    const answerRes = await request(app)
      .post('/answer')
      .send({
        sessionId,
        questionId: presentedFirst.id,
        selectedOption: presentedFirst.correctAnswer,
        timeRemaining: 10,
      })
      .expect(200);

    expect(answerRes.body.nextQuestion).toBeDefined();

    const storedAfterAnswer = await storedQuestions(sessionId);
    expect(storedAfterAnswer).toHaveLength(2);
    expect(answerRes.body.nextQuestion.options).toEqual(storedAfterAnswer[1].options);
    expect(answerRes.body.nextQuestion).not.toHaveProperty('correctAnswer');
    expect(answerRes.body.nextQuestion).not.toHaveProperty('optionsScale');
  });
});
