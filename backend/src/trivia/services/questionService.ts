/**
 * Question service - Collection-scoped question selection from PostgreSQL
 * Handles difficulty-balanced ordering, recent-question exclusion, and silent JSON fallback
 */

import { fallbackQuestions } from '../data/questions.js';
import { db } from '../db/index.js';
import { questions, collections, collectionQuestions, topics } from '../db/schema.js';
import { eq, and, notInArray, isNull, or, gt, sql } from 'drizzle-orm';
import { Question } from '../services/sessionService.js';
import { gameModes, DEFAULT_GAME_MODE } from './gameModes.js';
import type { DBQuestionRow } from './gameModes.js';

export const TOTAL_QUESTIONS = 5;

/**
 * The owned-bobit set for a player who has none, or for a signed-out one.
 *
 * Shared rather than allocated per call, and the reason it is a named constant is that it is
 * also the DEFAULT: every selection path must work unchanged when nobody is signed in.
 */
const EMPTY_OWNED: ReadonlySet<string> = new Set();

// Module-level caches
let cachedFederalCollectionId: number | null = null;
let cachedTopicMap: Map<number, string> | null = null;

/**
 * Topic ids a refresh has already looked for and failed to find.
 *
 * Without this, a question pointing at a topic row that no longer exists would
 * miss the cache on every request and trigger a fresh SELECT each time.
 */
const unresolvableTopicIds = new Set<number>();

// Re-export DBQuestionRow for external consumers
export type { DBQuestionRow } from './gameModes.js';

/**
 * Fisher-Yates shuffle algorithm
 */
function shuffle<T>(array: T[]): T[] {
  const shuffled = [...array];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}

/**
 * Whether the cached topic map has to be reloaded to answer for `requiredIds`.
 *
 * Pulled out of the loader so the judgement is testable without a database,
 * the same way `skipReasonFor()` was pulled out of the preflight loop.
 *
 * A cache that exists but is EMPTY is a real state (a database with no topic
 * rows yet) and is not the same as "not loaded" — hence the explicit null check
 * rather than a falsiness test.
 */
export function needsTopicRefresh(
  cache: Map<number, string> | null,
  requiredIds: Iterable<number>,
  unresolvable: ReadonlySet<number>,
): boolean {
  if (cache === null) return true;
  for (const id of requiredIds) {
    if (!cache.has(id) && !unresolvable.has(id)) return true;
  }
  return false;
}

/**
 * Load topic map from database. Maps topic ID to display name.
 *
 * Cached, but NOT immutably: topic rows are inserted at runtime every time a
 * collection is scaffolded, and a long-lived process would otherwise keep
 * serving the map it loaded at boot. A question whose topic is missing from
 * that map renders as the literal word "Unknown" on the player's card, because
 * `Question.topic` is passed straight through to QuestionCard.tsx.
 *
 * So: pass the topic ids you are about to render. A miss costs one reload, and
 * an id that the reload still cannot find is remembered so it costs nothing
 * thereafter.
 */
async function loadTopicMap(requiredIds: Iterable<number> = []): Promise<Map<number, string>> {
  if (!needsTopicRefresh(cachedTopicMap, requiredIds, unresolvableTopicIds)) {
    return cachedTopicMap!;
  }

  const rows = await db.select({ id: topics.id, name: topics.name }).from(topics);
  const map = new Map<number, string>();
  for (const row of rows) {
    map.set(row.id, row.name);
  }
  cachedTopicMap = map;

  for (const id of requiredIds) {
    if (!map.has(id)) unresolvableTopicIds.add(id);
  }

  return map;
}

/**
 * Transform DB question rows to the existing Question interface
 * Critical: uses externalId as id (NOT the database serial id)
 */
function transformDBQuestions(dbRows: DBQuestionRow[], topicMap: Map<number, string>): Question[] {
  return dbRows.map((row): Question => {
    const topicName = topicMap.get(row.topicId) || 'Unknown';

    const question: Question = {
      id: row.externalId,
      text: row.text,
      options: row.options,
      correctAnswer: row.correctAnswer,
      explanation: row.explanation,
      difficulty: row.difficulty,
      topic: topicName,
      topicCategory: row.subcategory || '',
    };

    if (row.learningContent !== null) {
      question.learningContent = {
        topic: topicName,
        paragraphs: row.learningContent.paragraphs,
        corrections: row.learningContent.corrections,
        source: row.source,
      };
    }

    return question;
  });
}

/**
 * Load questions from the embedded fallback set as an emergency fallback.
 * Shuffled and limited — no difficulty ordering, no collection filtering.
 *
 * NOTE (engine fold-in, Phase 1): the standalone CTC service read this from
 * data/questions.json via readFileSync at runtime. The engine build (`npx tsc`)
 * does not copy .json data files into dist/, so the set is embedded as a TS module
 * (data/questions.ts) that ships with the compiled output. Same questions.
 */
function loadQuestionsFromJSON(): Question[] {
  return shuffle(fallbackQuestions).slice(0, TOTAL_QUESTIONS);
}

/**
 * Put the questions a player has NOT yet earned a bobit for at the front.
 *
 * WHY THIS EXISTS. A collection bobit is granted the first time a question is answered
 * correctly, and the CTC tableau needs 100 DISTINCT bobits in one collection to finish its
 * 25 lines. Measured 2026-10-11 against the live bank: the most engaged player on record had
 * played 45 games -- roughly 225 question slots -- and held 23 bobits spread across five
 * collections, two lines deep at best. Selection was the reason. The only memory of what a
 * player had already seen was a 30-deep in-process Map in the game route, which is wiped by
 * every deploy, so the same questions came round again and again while most of the collection
 * was never served at all.
 *
 * A PREFERENCE, NOT AN EXCLUSION, and that distinction is the whole design:
 *   - Repetition is how trivia teaches. A question answered right once should still come back.
 *   - Collections run from 31 questions upward. Excluding owned questions would starve a small
 *     collection into an empty pool and then into the JSON fallback -- a worse failure than
 *     the one being fixed.
 *   - A player who owns everything sees exactly today's behaviour, because the partition is
 *     then a no-op.
 * Every caller takes from the FRONT of these pools (`pool.shift()`), so ordering is all the
 * steering that is needed; nothing is removed and no pool can shrink.
 *
 * STABLE, so the shuffle upstream still decides the order WITHIN each group. Sorting by a
 * boolean would not be: `Array.prototype.sort` is only required to be stable in modern V8 for
 * the comparison it is given, and partitioning by hand says what is meant.
 */
export function preferUnowned(
  rows: DBQuestionRow[],
  owned: ReadonlySet<string>
): DBQuestionRow[] {
  if (owned.size === 0) return rows;
  const fresh: DBQuestionRow[] = [];
  const seen: DBQuestionRow[] = [];
  for (const row of rows) (owned.has(row.externalId) ? seen : fresh).push(row);
  return fresh.concat(seen);
}

/**
 * Apply difficulty selection using the pluggable game mode strategy system.
 *
 * Delegates to the selected strategy from gameModes registry.
 * Falls back to DEFAULT_GAME_MODE if the requested mode is unknown.
 *
 * Constraint relaxation: if fewer than TOTAL_QUESTIONS available, returns all shuffled.
 */
function applyDifficultySelection(
  allRows: DBQuestionRow[],
  collectionId: number,
  gameMode?: string,
  owned: ReadonlySet<string> = EMPTY_OWNED
): DBQuestionRow[] {
  const modeName = gameMode && gameModes[gameMode] ? gameMode : DEFAULT_GAME_MODE;
  const strategy = gameModes[modeName];

  // Shuffle first, then partition: the shuffle decides the order within each group and the
  // partition decides which group goes first.
  const pool = (difficulty: string) =>
    preferUnowned(shuffle(allRows.filter(q => q.difficulty === difficulty)), owned);
  const easyPool = pool('easy');
  const mediumPool = pool('medium');
  const hardPool = pool('hard');

  if (allRows.length < TOTAL_QUESTIONS) {
    console.warn(
      `Relaxed difficulty constraints: only ${allRows.length} questions for collection ${collectionId}`
    );
    return preferUnowned(shuffle(allRows), owned);
  }

  return strategy(easyPool, mediumPool, hardPool, TOTAL_QUESTIONS);
}

/**
 * Resolve the federal civics collection ID (cached after first lookup)
 * Returns 1 as hardcoded fallback if query fails (seed creates Federal as ID 1)
 */
export async function getFederalCollectionId(): Promise<number> {
  if (cachedFederalCollectionId !== null) {
    return cachedFederalCollectionId;
  }

  try {
    const result = await db
      .select({ id: collections.id })
      .from(collections)
      .where(eq(collections.slug, 'federal-civics'))
      .limit(1);

    if (result.length > 0) {
      cachedFederalCollectionId = result[0].id;
      return cachedFederalCollectionId;
    }

    // Collection not found — return hardcoded fallback
    console.warn('Federal civics collection not found by slug, using fallback ID 1');
    return 1;
  } catch (error) {
    console.warn('Failed to query federal collection ID, using fallback ID 1:', error);
    return 1;
  }
}

/**
 * Get collection metadata by ID
 * Returns null if not found or on error — never throws
 */
export async function getCollectionMetadata(
  collectionId: number
): Promise<{ id: number; name: string; slug: string } | null> {
  try {
    const result = await db
      .select({
        id: collections.id,
        name: collections.name,
        slug: collections.slug,
      })
      .from(collections)
      .where(eq(collections.id, collectionId))
      .limit(1);

    if (result.length === 0) {
      return null;
    }

    return result[0];
  } catch (error) {
    console.warn('Failed to query collection metadata:', error);
    return null;
  }
}

/**
 * Select 8 questions for a game session from a specific collection.
 *
 * Algorithm:
 *   1. Resolve collectionId (use federal-civics if null)
 *   2. Query all available questions for the collection (excluding recent + expired)
 *   3. Apply difficulty selection: Q1=easy, Q8=hard, Q2-Q7=balanced mix
 *   4. Transform DB rows to the existing Question interface (externalId -> id)
 *   5. On any error: fall back silently to JSON file
 *
 * @param collectionId - Collection to query (null = federal civics)
 * @param recentQuestionIds - Question external IDs to exclude from selection
 * @param gameMode - Game mode strategy name (defaults to 'easy-steps')
 * @param owned - External IDs this player already holds a bobit for. A PREFERENCE only:
 *   these sort last rather than being excluded. See `preferUnowned`. Empty when signed out.
 * @returns Array of up to 8 questions shaped as Question interface
 */
export async function selectQuestionsForGame(
  collectionId: number | null,
  recentQuestionIds: string[],
  gameMode?: string,
  owned: ReadonlySet<string> = EMPTY_OWNED
): Promise<Question[]> {
  try {
    // Resolve collection ID
    const targetCollectionId = collectionId ?? await getFederalCollectionId();

    // Build query conditions
    const now = new Date();

    // Base conditions: join collection and exclude expired
    const baseConditions = and(
      eq(collectionQuestions.collectionId, targetCollectionId),
      eq(questions.status, 'active'),
      or(
        isNull(questions.expiresAt),
        gt(questions.expiresAt, now)
      )
    );

    // Add recent question exclusion if any IDs provided
    const whereCondition = recentQuestionIds.length > 0
      ? and(baseConditions, notInArray(questions.externalId, recentQuestionIds))
      : baseConditions;

    // Query all matching questions for difficulty selection
    const dbRows = await db
      .select({
        id: questions.id,
        externalId: questions.externalId,
        text: questions.text,
        options: questions.options,
        correctAnswer: questions.correctAnswer,
        explanation: questions.explanation,
        difficulty: questions.difficulty,
        topicId: questions.topicId,
        subcategory: questions.subcategory,
        source: questions.source,
        learningContent: questions.learningContent,
      })
      .from(questions)
      .innerJoin(collectionQuestions, eq(questions.id, collectionQuestions.questionId))
      .where(whereCondition);

    if (dbRows.length === 0) {
      console.warn(
        `No questions found for collection ${targetCollectionId}, falling back to JSON`
      );
      return loadQuestionsFromJSON();
    }

    // Deduplicate DB rows by externalId (safety net against unexpected join duplicates)
    const seenIds = new Set<string>();
    const uniqueRows = (dbRows as DBQuestionRow[]).filter(row => {
      if (seenIds.has(row.externalId)) {
        console.warn(`Duplicate question detected in query results: ${row.externalId}`);
        return false;
      }
      seenIds.add(row.externalId);
      return true;
    });

    const unowned = owned.size === 0
      ? uniqueRows.length
      : uniqueRows.filter(r => !owned.has(r.externalId)).length;
    console.log(
      `Question selection: collection=${targetCollectionId}, available=${uniqueRows.length}, ` +
      `excluded=${recentQuestionIds.length}, unowned=${unowned}`
    );

    // Apply difficulty selection algorithm
    const selectedRows = applyDifficultySelection(
      uniqueRows,
      targetCollectionId,
      gameMode,
      owned
    );

    // Final dedup safety check on selected questions
    const selectedIds = new Set<string>();
    const dedupedSelected = selectedRows.filter(row => {
      if (selectedIds.has(row.externalId)) {
        console.error(`DUPLICATE in final selection: ${row.externalId} "${row.text.substring(0, 60)}..."`);
        return false;
      }
      selectedIds.add(row.externalId);
      return true;
    });

    // Transform DB rows to Question interface
    const topicMap = await loadTopicMap(dedupedSelected.map(r => r.topicId));
    return transformDBQuestions(dedupedSelected, topicMap);
  } catch (error) {
    console.warn('Database question query failed, falling back to JSON:', error);
    return loadQuestionsFromJSON();
  }
}

/**
 * Transform a single DB question row to a Question interface.
 * Used by the adaptive flow to transform dynamically-selected next questions.
 */
export async function transformSingleDBQuestion(row: DBQuestionRow): Promise<Question> {
  const topicMap = await loadTopicMap([row.topicId]);
  return transformDBQuestions([row], topicMap)[0];
}

/**
 * Create an adaptive game session: fetch all questions for the collection,
 * split into difficulty pools, and pick the first easy question.
 *
 * Returns the first question and the remaining candidate pools for
 * on-the-fly selection during gameplay.
 */
export async function createAdaptiveSession(
  collectionId: number | null,
  recentQuestionIds: string[],
  owned: ReadonlySet<string> = EMPTY_OWNED
): Promise<{
  firstQuestion: Question;
  candidatePools: { easy: DBQuestionRow[]; medium: DBQuestionRow[]; hard: DBQuestionRow[] };
  firstQuestionDbId: number;
}> {
  // Resolve collection ID
  const targetCollectionId = collectionId ?? await getFederalCollectionId();

  // Build query conditions (same as selectQuestionsForGame)
  const now = new Date();
  const baseConditions = and(
    eq(collectionQuestions.collectionId, targetCollectionId),
    eq(questions.status, 'active'),
    or(
      isNull(questions.expiresAt),
      gt(questions.expiresAt, now)
    )
  );

  const whereCondition = recentQuestionIds.length > 0
    ? and(baseConditions, notInArray(questions.externalId, recentQuestionIds))
    : baseConditions;

  const dbRows = await db
    .select({
      id: questions.id,
      externalId: questions.externalId,
      text: questions.text,
      options: questions.options,
      correctAnswer: questions.correctAnswer,
      explanation: questions.explanation,
      difficulty: questions.difficulty,
      topicId: questions.topicId,
      subcategory: questions.subcategory,
      source: questions.source,
      learningContent: questions.learningContent,
    })
    .from(questions)
    .innerJoin(collectionQuestions, eq(questions.id, collectionQuestions.questionId))
    .where(whereCondition);

  if (dbRows.length === 0) {
    throw new Error(`No questions found for collection ${targetCollectionId}`);
  }

  // Deduplicate
  const seenIds = new Set<string>();
  const uniqueRows = (dbRows as DBQuestionRow[]).filter(row => {
    if (seenIds.has(row.externalId)) return false;
    seenIds.add(row.externalId);
    return true;
  });

  // Shuffle, split into pools, then float the questions this player has no bobit for to the
  // front of each. Every picker here takes from the front, so that is the whole steering.
  const shuffled = shuffle(uniqueRows);
  const easyPool = preferUnowned(shuffled.filter(q => q.difficulty === 'easy'), owned);
  const mediumPool = preferUnowned(shuffled.filter(q => q.difficulty === 'medium'), owned);
  const hardPool = preferUnowned(shuffled.filter(q => q.difficulty === 'hard'), owned);

  // Pick first question from easy pool (Tier 1 = easy only)
  const firstRow = easyPool.shift() || mediumPool.shift() || hardPool.shift();
  if (!firstRow) {
    throw new Error('No questions available after pool split');
  }

  const topicMap = await loadTopicMap([firstRow.topicId]);
  const firstQuestion = transformDBQuestions([firstRow], topicMap)[0];

  console.log(
    `[easy-steps-adaptive] Session created: collection=${targetCollectionId}, ` +
    `available=${uniqueRows.length} (easy=${easyPool.length + 1}, medium=${mediumPool.length}, hard=${hardPool.length}), ` +
    `first=${firstRow.difficulty}`
  );

  return {
    firstQuestion,
    candidatePools: { easy: easyPool, medium: mediumPool, hard: hardPool },
    firstQuestionDbId: firstRow.id,
  };
}
