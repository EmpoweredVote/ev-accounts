/**
 * Current Term Question Generator
 *
 * Generates post-election "Who is the current [seat]?" trivia questions after
 * an election resolves. Questions are linked to the winning official and expire
 * at the end of their term date rather than the election date.
 *
 * Called from: POST /api/admin/election-races/:id/enter-result
 */

import { client, MODEL, EFFORT, firstText, describeContent } from '../../scripts/content-generation/anthropic-client.js';
import { db } from '../../db/index.js';
import { placeAnswer } from '../questionQuality/answerPlacement.js';
import { auditBeforeInsert } from './auditBeforeInsert.js';
import { ModelQuestionSchema, type ModelQuestion } from '../../scripts/content-generation/question-schema.js';
import {
  questions,
  collectionQuestions,
  electionRaces,
} from '../../db/schema.js';
import { eq } from 'drizzle-orm';
import { QUALITY_GUIDELINES } from '../../scripts/content-generation/prompts/quality-guidelines.js';
import {
  getEndOfDayUTC,
  resolveCollectionAndTopic,
} from './ElectionQuestionGenerator.js';

// ─── Exported interfaces ──────────────────────────────────────────────────────

export interface CurrentTermResult {
  questionsCreated: number;
  /** Questions the model returned that the schema refused. 0 is the expected value. */
  questionsRejected: number;
  raceId: number;
  jurisdiction: string;
  collectionSlug: string;
}

// ─── Custom error for idempotency guard ──────────────────────────────────────

export class FollowupBlockedError extends Error {
  raceId: number;

  constructor(raceId: number) {
    super(`Current-term questions already generated for race ${raceId}.`);
    this.name = 'FollowupBlockedError';
    this.raceId = raceId;
  }
}

// ─── External ID builder ──────────────────────────────────────────────────────

/**
 * Build a unique external ID for a current-term question.
 * Format: elc-term-{raceId}-{seq} (e.g., elc-term-5-001)
 */
function buildCurrentTermExternalId(raceId: number, seq: number): string {
  return `elc-term-${raceId}-${String(seq).padStart(3, '0')}`;
}

// ─── System prompt builder ────────────────────────────────────────────────────

function buildCurrentTermSystemPrompt(
  race: { seat: string; jurisdiction: string; electionType: string },
  opts: { winnerName: string; termEndDate: string }
): string {
  return `You are a civic education content creator generating trivia questions about a recently elected official.

## Office Details
- Seat: ${race.seat}
- Jurisdiction: ${race.jurisdiction}
- Winner: ${opts.winnerName}
- Term End Date: ${opts.termEndDate}
- Election Type: ${race.electionType}

## Question Types
Generate exactly 6 questions:
1. "Who is the current ${race.seat}?" — straightforward knowledge check
2. "When does ${opts.winnerName}'s term as ${race.seat} expire?" — timeline question
3-4. Two questions about the role, powers, and responsibilities of this office
5. "Who won the [year] ${race.seat} election in ${race.jurisdiction}?" — election context (historical fact)
6. One additional office-specific question (salary, term length, how many members, notable powers, etc.)

## Rules
- All questions must be factual and non-partisan
- Do NOT compare candidates or express opinions
- Distractors should be plausible: real names of other officials, real dates, real government structures
- Each question must have exactly 4 answer options

## Output Format
Return ONLY a valid JSON object:
{
  "questions": [
    {
      "text": "Question text?",
      "options": ["A", "B", "C", "D"],
      "correctAnswer": 0,
      "explanation": "Brief explanation with source reference",
      "difficulty": "easy",
      "topicCategory": "current-term",
      "source": { "name": "Source Name", "url": "https://..." }
    }
  ]
}

${QUALITY_GUIDELINES}`;
}

// ─── Main export: generateCurrentTermQuestions ────────────────────────────────

/**
 * Generate current-term civic trivia questions after an election resolves.
 *
 * Steps:
 * 1. Load race from DB. Throw if not found.
 * 2. Check followupGenerated — throw FollowupBlockedError if already done.
 * 3. Resolve collection + elections-voting topic.
 * 4. Compute expiresAt = end-of-day on termEndDate in race's timezone.
 * 5. Build current-term system prompt, call Claude API.
 * 6. Parse and validate JSON response.
 * 7. Insert 6 questions with elc-term- external IDs.
 * 8. Set followupGenerated = true and result = winnerName on the race.
 * 9. Return CurrentTermResult.
 */
export async function generateCurrentTermQuestions(
  raceId: number,
  collectionSlug: string,
  opts: { winnerName: string; termEndDate: string }
): Promise<CurrentTermResult> {
  // 1. Load race from DB
  const [race] = await db
    .select()
    .from(electionRaces)
    .where(eq(electionRaces.id, raceId))
    .limit(1);

  if (!race) {
    throw new Error(`Election race not found: ID ${raceId}`);
  }

  // 2. Check followupGenerated — idempotency guard
  if (race.followupGenerated) {
    throw new FollowupBlockedError(raceId);
  }

  console.log(`\nGenerating current-term questions for: ${race.seat} — ${race.jurisdiction}`);
  console.log(`  Winner: ${opts.winnerName}`);
  console.log(`  Term end date: ${opts.termEndDate}`);

  // 3. Resolve collection + topic
  console.log(`\n  Resolving collection "${collectionSlug}"...`);
  const { collectionId, topicId } = await resolveCollectionAndTopic(collectionSlug);
  console.log(`  Collection ID: ${collectionId}, Topic ID: ${topicId}`);

  // 4. Compute expiresAt — end of term in the jurisdiction's local timezone
  const expiresAt = getEndOfDayUTC(opts.termEndDate, race.timezone);
  console.log(`  Expires at: ${expiresAt.toISOString()} (end of ${opts.termEndDate} in ${race.timezone})`);

  // 5. Build system prompt
  const systemPrompt = buildCurrentTermSystemPrompt(race, opts);
  const userMessage = `Generate 6 current-term civic trivia questions about ${opts.winnerName} as ${race.seat} in ${race.jurisdiction}.`;

  // 6. Call Claude API
  console.log(`\n  Calling Claude API (${MODEL})...`);

  const response = await client.messages.create({
    model: MODEL,
    max_tokens: 8192, // room for adaptive thinking as well as the reply
    system: systemPrompt,
    messages: [{ role: 'user', content: userMessage }],
    output_config: { effort: EFFORT },
  });

  const text = firstText(response);
  if (text === null) {
    throw new Error(`Unexpected Claude response type: ${describeContent(response)}`);
  }

  const responseText = text.trim();

  // Parse JSON from response (handle potential markdown code blocks)
  const jsonMatch = responseText.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    throw new Error(
      `No JSON object found in Claude response. Preview: ${responseText.slice(0, 300)}`
    );
  }

  let parsed: { questions: unknown[] };

  try {
    parsed = JSON.parse(jsonMatch[0]);
  } catch (err) {
    throw new Error(
      `Failed to parse JSON from Claude response: ${err instanceof Error ? err.message : err}`,
      { cause: err }
    );
  }

  if (!parsed.questions || !Array.isArray(parsed.questions)) {
    throw new Error(
      `Claude response missing "questions" array. Got: ${JSON.stringify(parsed).slice(0, 200)}`
    );
  }

  // Validate the model's reply against the shared question schema.
  //
  // What this replaces checked four things loosely: text present, options an array of AT LEAST
  // four, correctAnswer not undefined. That let through, silently:
  //   - five or more options, and an answer index pointing past the fourth
  //   - correctAnswer out of range (or a string), which placeAnswer() cannot fix -- it returns
  //     the question UNCHANGED when the shape is wrong, so the guard quietly did nothing and a
  //     question with no correct option was written
  //   - any difficulty string at all, including one the tiered picker will never select
  //   - no explanation checks, so an empty or boilerplate-opening explanation passed
  //   - no source, which the insert below turns into { name: 'Unknown', url: '' }
  //
  // Same drop-and-continue behaviour as before -- one bad question must not cost the batch --
  // but the reason is now printed rather than "malformed", because "malformed" is what you
  // read in a log three weeks later and learn nothing from.
  const rejections: string[] = [];
  const parsedQuestions: ModelQuestion[] = [];
  for (const [idx, raw] of parsed.questions.entries()) {
    const result = ModelQuestionSchema.safeParse(raw);
    if (!result.success) {
      const why = result.error.issues
        .map((i) => `${i.path.join('.') || '(root)'}: ${i.message}`)
        .join('; ');
      rejections.push(`question ${idx + 1}: ${why}`);
      continue;
    }
    parsedQuestions.push(result.data);
  }

  if (rejections.length > 0) {
    console.warn(`  ${rejections.length} question(s) rejected by the schema:`);
    for (const r of rejections) console.warn(`    - ${r}`);
  }

  console.log(`  Claude generated ${parsedQuestions.length} valid questions.`);

  // 7. Insert questions into DB
  console.log(`\n  Inserting ${parsedQuestions.length} questions into database...`);
  let questionsCreated = 0;
  let questionsBlocked = 0;

  for (let i = 0; i < parsedQuestions.length; i++) {
    const q = parsedQuestions[i];
    const seq = i + 1;
    const externalId = buildCurrentTermExternalId(raceId, seq);

    // Write-time answer-position guard -- the output example in the prompt above says
    // correctAnswer: 0, and the model copies it. Seeded on externalId for determinism.
    const placed = placeAnswer(q.options, q.correctAnswer, externalId);

    // Quality gate. Runs on the PLACED question, because that is what gets
    // stored. Enforcement is per rule and shared with the nightly pipeline via
    // TRIVIA_QUALITY_RULES_ENFORCE -- unenforced rules still log, they just do
    // not refuse the write.
    const verdict = await auditBeforeInsert({
      externalId,
      text: q.text,
      options: placed.options,
      correctAnswer: placed.correctAnswer,
      explanation: q.explanation,
      difficulty: q.difficulty,
      source: q.source ?? { name: 'Unknown', url: '' },
    });
    if (!verdict.write) {
      questionsBlocked++;
      continue;
    }

    const inserted = await db
      .insert(questions)
      .values({
        externalId,
        text: q.text,
        options: placed.options,
        correctAnswer: placed.correctAnswer,
        explanation: q.explanation,
        difficulty: q.difficulty,
        topicId,
        subcategory: 'current-term',
        source: q.source ?? { name: 'Unknown', url: '' },
        learningContent: null,
        expiresAt,
        status: 'draft',
        expirationHistory: [],
        electionRaceId: raceId,
      })
      .onConflictDoNothing()
      .returning({ id: questions.id });

    if (inserted.length > 0) {
      const questionId = inserted[0].id;

      // Link to collection_questions
      await db
        .insert(collectionQuestions)
        .values({ collectionId, questionId })
        .onConflictDoNothing();

      questionsCreated++;
    } else {
      console.warn(
        `  Warning: Question ${seq} (${externalId}) skipped — external ID conflict.`
      );
    }
  }

  console.log(`  Inserted: ${questionsCreated}/${parsedQuestions.length} questions.`);
  if (questionsBlocked > 0) {
    console.log(
      `  [QualityRules] ${questionsBlocked} refused by an enforced rule and NOT written.`,
    );
  }

  // 8. Update race: set followupGenerated = true and result = winnerName
  await db
    .update(electionRaces)
    .set({
      followupGenerated: true,
      result: opts.winnerName,
    })
    .where(eq(electionRaces.id, raceId));

  console.log(`  Set followupGenerated = true, result = "${opts.winnerName}" for race ${raceId}.`);

  // 9. Return result
  return {
    questionsCreated,
    questionsRejected: rejections.length,
    raceId,
    jurisdiction: race.jurisdiction,
    collectionSlug,
  };
}
