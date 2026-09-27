import { client, MODEL } from '../../scripts/content-generation/anthropic-client.js';
import type { ClaimResult } from './claim-extractor.js';
import type { QuestionInput } from '../../services/qualityRules/types.js';
import { auditQuestion } from '../../services/qualityRules/index.js';
import {
  qualityRulesEnforced,
  emptyQualityRuleStats,
  decideRuleGate,
  recordGate,
  recordRuleError,
  recordWrittenUnaudited,
  type QualityRuleStats,
} from './qualityGate.js';

// ─── Volatility Types & Helpers ───────────────────────────────────────────────

export type Volatility = 'fast' | 'medium' | 'slow' | 'stable';

/**
 * Compute expiresAt for a new international question based on its volatility tier.
 * fast = 4 days (midpoint 3-5), medium = 10 days (midpoint 7-14),
 * slow = 60 days, stable = 180 days.
 */
export function computeExpiresAt(volatility: Volatility): Date {
  const now = new Date();
  const days: Record<Volatility, number> = {
    fast: 4,
    medium: 10,
    slow: 60,
    stable: 180,
  };
  const ms = days[volatility] * 24 * 60 * 60 * 1000;
  return new Date(now.getTime() + ms);
}

// ─── Types ────────────────────────────────────────────────────────────────────

export interface GeneratedQuestion {
  text: string;
  options: string[];
  correctAnswer: number;
  explanation: string;
  difficulty: 'easy' | 'medium' | 'hard';
  qualityGate: { passed: boolean; reason: string };
}

export interface QuestionWriteResult {
  questionId: number;
  externalId: string;
  status: 'active';
}

export interface WritePassResult {
  written: QuestionWriteResult[];
  ruleStats: QualityRuleStats;
}

/**
 * Map a generated question onto the quality engine's input shape.
 *
 * Takes the PLACED options and answer index, not the model's — `placeAnswer`
 * rewrites both, and the engine must judge what will actually be stored.
 */
/**
 * Audit a question the way the nightly pipeline audits it.
 *
 * Exists as its own export so the `skipUrlCheck` decision is testable on the
 * path the pipeline actually takes. Asserting it against `auditQuestion`
 * directly only re-tests `auditQuestion`'s documented contract, and would stay
 * green if the write path dropped the option.
 *
 * skipUrlCheck is not an optimisation: checkLearnMoreLink fetches source.url
 * and raises `broken-learn-more` at severity BLOCKING on any non-timeout
 * failure. A news article URL is not a .gov page that answers bots politely, so
 * leaving the check on would put an HTTP round trip per question inside the
 * cron and make a blocking verdict depend on network weather.
 */
export async function auditForPipeline(input: QuestionInput) {
  return auditQuestion(input, { skipUrlCheck: true });
}

export function toQuestionInput(
  q: {
    text: string;
    options: string[];
    correctAnswer: number;
    explanation: string;
    difficulty: string;
  },
  externalId: string,
  source: { name: string; url: string },
): QuestionInput {
  return {
    text: q.text,
    options: q.options,
    correctAnswer: q.correctAnswer,
    explanation: q.explanation,
    difficulty: q.difficulty,
    source,
    externalId,
  };
}

// ─── Claude Call 2: Question Generation ──────────────────────────────────────

const QUESTION_GENERATION_SCHEMA = {
  type: 'object' as const,
  properties: {
    questions: {
      type: 'array' as const,
      items: {
        type: 'object' as const,
        properties: {
          text: { type: 'string' as const },
          options: {
            type: 'array' as const,
            items: { type: 'string' as const },
          },
          correctAnswer: { type: 'integer' as const },
          explanation: { type: 'string' as const },
          difficulty: {
            type: 'string' as const,
            enum: ['easy', 'medium', 'hard'],
          },
          quality_gate: {
            type: 'object' as const,
            properties: {
              passed: { type: 'boolean' as const },
              reason: { type: 'string' as const },
            },
            required: ['passed', 'reason'] as string[],
            additionalProperties: false,
          },
        },
        required: ['text', 'options', 'correctAnswer', 'explanation', 'difficulty', 'quality_gate'] as string[],
        additionalProperties: false,
      },
    },
  },
  required: ['questions'] as string[],
  additionalProperties: false,
};

export const QUESTION_GENERATION_SYSTEM_PROMPT = `You are a civic trivia question writer. Given a verified factual claim from international news, generate 1-3 multiple-choice questions suitable for a trivia game.

Question composition rules:
- Target ~15% of questions involving concrete numbers: budgets, percentages, dates, quantities
- Prefer verifiable, non-disputed facts over characterizations or contested interpretations
- Preferred style: "Iran's annual military budget in 2025 was...?", "The US allocates what percentage of its budget to...?"
- Avoid questions requiring inference about motive, blame, or prediction
- Each question must have exactly 4 answer options; only one is correct
- Explanations: 1-2 sentences citing the factual basis

Quality gate — assess EACH question against ALL four blocking checks:
1. Partisan framing: assigns blame, takes sides on disputed political questions
2. Logical fallacies: false dilemma, straw man, false cause in question or options
3. Manipulative framing: leading questions, loaded language, emotionally charged phrasing
4. Unverifiability: correct answer requires knowing private intent or predicting future

Set quality_gate.passed = true ONLY if the question passes ALL four checks.
Set quality_gate.passed = false if ANY check fails; include in reason which check failed.

Hard rules — a question breaking any of these is rejected by the quality engine
after you write it, so write them right the first time:

1. TIME. If the question asks what year something happened and the event is in the
   past, no option may be a year that has not arrived yet. A question asking when
   a past treaty entered into force must not offer 2027. A question about a
   deadline, a target or a term that ends in the future may offer a future year —
   the test is the event, not the number.
2. PHRASING OF DATE QUESTIONS. The engine's "pure lookup" rule blocks the exact
   phrasings "in what year was", "in what year did" and "what date". These are
   refused outright, whatever the question is about. Ask the same thing another
   way: "The treaty entered into force in which year?" rather than "In what year
   did the treaty enter into force?". Prefer a question about what happened or
   what changed over one whose whole content is a date.
3. NUMBERS. When all four options are numbers, quantities, years or percentages,
   the correct value must not always sit in the middle of the range. Vary which
   bracket it falls in across a batch — sometimes smallest, sometimes largest.
   Use one unit throughout a single question, and order the options ascending.
   Never move the correct value to achieve this; change the distractors.
4. NO VAGUE QUALIFIERS. Do not write "most important", "best", "primarily",
   "generally", "mainly", "usually", "typically", "often", "commonly" or
   "frequently" into a question. They make more than one option defensible.
   This matches on substrings, so "best known for" trips it too.
5. DISTINCT OPTIONS. The four options must be clearly distinct — not near-synonyms,
   not overlapping ranges, not the same phrase reordered.
6. NO ADDRESSES OR PHONE NUMBERS as answer options.

Generate 1 question for straightforward claims. Generate 2-3 for rich multi-faceted stories.`;

/**
 * Claude Call 2: Generate MCQ questions from a verified claim.
 * Returns ALL questions (passing and failing) so caller can count stats.
 * Failing questions are logged but NOT written to DB.
 */
export async function generateQuestions(claim: ClaimResult): Promise<GeneratedQuestion[]> {
  // Build source article list for user message
  const sourceLines = claim.sourceArticles
    .map(a => `- ${a.title} (${a.feedName}, ${a.pubDate.toDateString()})`)
    .join('\n');

  const userMessage =
    `Claim: ${claim.claim}\n` +
    `Fact snapshot: ${claim.factSnapshot}\n` +
    `Confidence: ${claim.confidenceTier}\n\n` +
    `Source articles:\n${sourceLines}`;

  try {
    const response = await client.messages.create({
      model: MODEL,
      max_tokens: 4096,
      system: QUESTION_GENERATION_SYSTEM_PROMPT,
      messages: [{ role: 'user', content: userMessage }],
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      output_config: { format: { type: 'json_schema', schema: QUESTION_GENERATION_SCHEMA } } as any,
    });

    const contentBlock = response.content[0];
    if (contentBlock.type !== 'text') {
      console.error(
        `[QuestionGenerator] Unexpected response type: ${contentBlock.type} for claim: "${claim.claim.slice(0, 60)}"`,
      );
      return [];
    }

    // Guaranteed valid JSON when using structured output
    const parsed = JSON.parse(contentBlock.text) as {
      questions: Array<{
        text: string;
        options: string[];
        correctAnswer: number;
        explanation: string;
        difficulty: 'easy' | 'medium' | 'hard';
        quality_gate: { passed: boolean; reason: string };
      }>;
    };

    const questions: GeneratedQuestion[] = parsed.questions.map(q => ({
      text: q.text,
      options: q.options,
      correctAnswer: q.correctAnswer,
      explanation: q.explanation,
      difficulty: q.difficulty,
      qualityGate: { passed: q.quality_gate.passed, reason: q.quality_gate.reason },
    }));

    // Log blocked questions
    for (const q of questions) {
      if (!q.qualityGate.passed) {
        console.log(
          `[QualityGate] BLOCKED: "${q.text.slice(0, 60)}" — ${q.qualityGate.reason}`,
        );
      }
    }

    return questions;
  } catch (err) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    console.error(
      `[QuestionGenerator] Error generating questions for claim "${claim.claim.slice(0, 60)}": ${errorMsg}`,
    );
    return [];
  }
}

// ─── DB Write: Passing Questions Only ────────────────────────────────────────

/**
 * Write passing questions to the database as active, with collection_questions rows.
 *
 * Only questions where qualityGate.passed === true are written.
 * Questions failing the quality gate are never created in the DB.
 */
export async function writePassingQuestions(
  questions: GeneratedQuestion[],
  claim: ClaimResult,
  collectionId: number,
  jobId: number,
  externalIdPrefix: string,
  volatility: Volatility,
): Promise<WritePassResult> {
  const ruleStats = emptyQualityRuleStats();
  const passingQuestions = questions.filter(q => q.qualityGate.passed);
  if (passingQuestions.length === 0) return { written: [], ruleStats };

  // Lazy DB imports (ESM pattern — consistent with replacementGenerator.ts)
  const { db } = await import('../../db/index.js');
  const { questions: questionsTable, collectionQuestions, topics } = await import('../../db/schema.js');
  const { eq, and, sql } = await import('drizzle-orm');

  // ── Resolve/create "world-news" topic ──────────────────────────────────────
  const WORLD_NEWS_SLUG = 'world-news';
  const WORLD_NEWS_NAME = 'World News';

  let topicId: number;
  const existingTopic = await db
    .select({ id: topics.id })
    .from(topics)
    .where(eq(topics.slug, WORLD_NEWS_SLUG))
    .limit(1);

  if (existingTopic.length > 0) {
    topicId = existingTopic[0].id;
  } else {
    const [newTopic] = await db
      .insert(topics)
      .values({
        name: WORLD_NEWS_NAME,
        slug: WORLD_NEWS_SLUG,
        description: 'International news and world affairs',
      })
      .returning({ id: topics.id });
    topicId = newTopic.id;
    console.log(`[QuestionGenerator] Created topic: ${WORLD_NEWS_NAME} (id=${topicId})`);
  }

  // ── Get current max external ID for this prefix ────────────────────────────
  const maxIdResult = await db
    .select({
      maxId: sql<string>`MAX(SUBSTRING(${questionsTable.externalId} FROM '[0-9]+$')::int)`,
    })
    .from(questionsTable)
    .innerJoin(collectionQuestions, eq(questionsTable.id, collectionQuestions.questionId))
    .where(
      and(
        eq(collectionQuestions.collectionId, collectionId),
        sql`${questionsTable.externalId} LIKE ${externalIdPrefix + '-%'}`,
      ),
    );

  let nextIdNum = (maxIdResult[0]?.maxId ? parseInt(maxIdResult[0].maxId, 10) : 0) + 1;

  // ── Insert each passing question ────────────────────────────────────────────
  // Write-time answer-position guard: generator prompts show the model
  // "correctAnswer": 0 and it copies it, so position is normalised here rather than
  // being asked for. Seeded on externalId so regenerating a question does not move it.
  const { placeAnswer } = await import('../../services/questionQuality/answerPlacement.js');

  const results: QuestionWriteResult[] = [];
  const primarySource = claim.sourceArticles[0];

  for (const q of passingQuestions) {
    const externalId = `${externalIdPrefix}-${String(nextIdNum).padStart(4, '0')}`;
    nextIdNum++;

    const placed = placeAnswer(q.options, q.correctAnswer, externalId);

    // ── Quality rules gate ──────────────────────────────────────────────────
    // The engine judges the PLACED question, because that is what gets stored.
    // skipUrlCheck is not an optimisation: checkLearnMoreLink fetches
    // source.url and raises a BLOCKING violation on any non-timeout failure,
    // and a news article URL is not a .gov page that answers bots politely.
    // Leaving it on would put an HTTP round trip per question inside the cron
    // and make the verdict depend on network weather.
    const enforce = qualityRulesEnforced();
    // Dereferenced OUTSIDE the try on purpose. A claim with no source articles
    // is a malformed claim, not a rules failure; inside the try it would be
    // logged as "audit threw" and then throw again uncaught at the insert
    // below, blaming the rules engine for someone else's defect.
    const auditSource = { name: primarySource.feedName, url: primarySource.url };
    try {
      const audit = await auditForPipeline(
        toQuestionInput(
          { ...q, options: placed.options, correctAnswer: placed.correctAnswer },
          externalId,
          auditSource,
        ),
      );

      const decision = decideRuleGate(audit.violations, enforce);
      recordGate(ruleStats, externalId, decision, enforce);

      if (decision.blocking.length > 0) {
        const rules = decision.blocking.map(v => v.rule).join(', ');
        console.log(
          `[QualityRules] ${enforce ? 'BLOCKED' : 'WOULD BLOCK'} ${externalId} — ${rules} — "${q.text.slice(0, 60)}"`,
        );
      }

      if (!decision.write) continue;
    } catch (err) {
      // A rule that throws must not cost the claim its remaining questions.
      // run-pipeline contains errors per CLUSTER, so an escape from here
      // discards every question left for this claim, not just this one.
      // Falling through to the insert is deliberate: a broken rule is our
      // defect, and refusing to write because our own code crashed would turn
      // a bug into silent content loss.
      recordRuleError(ruleStats, externalId, err);
      recordWrittenUnaudited(ruleStats);
      console.error(
        `[QualityRules] audit threw for ${externalId}: ${err instanceof Error ? err.message : String(err)} — writing unaudited`,
      );
    }

    const inserted = await db
      .insert(questionsTable)
      .values({
        externalId,
        text: q.text,
        options: placed.options,
        correctAnswer: placed.correctAnswer,
        explanation: q.explanation,
        difficulty: q.difficulty,
        topicId,
        subcategory: WORLD_NEWS_SLUG,
        source: {
          name: primarySource.feedName,
          url: primarySource.url,
        },
        learningContent: null,
        expiresAt: computeExpiresAt(volatility),
        status: 'active' as const,
        expirationHistory: [],
        factSnapshot: claim.factSnapshot,
        confidenceTier: claim.confidenceTier,
        generationJobId: jobId,
        volatility,
      })
      .onConflictDoNothing()
      .returning({ id: questionsTable.id });

    if (!inserted || inserted.length === 0) {
      console.warn(
        `[QuestionGenerator] Skipped (external_id conflict): ${externalId}`,
      );
      continue;
    }

    const questionId = inserted[0].id;

    // Insert collection_questions row (required for game visibility)
    await db
      .insert(collectionQuestions)
      .values({ collectionId, questionId })
      .onConflictDoNothing();

    console.log(
      `[QuestionGenerator] Created: ${externalId} — "${q.text.slice(0, 60)}"`,
    );

    results.push({ questionId, externalId, status: 'active' });
  }

  return { written: results, ruleStats };
}
