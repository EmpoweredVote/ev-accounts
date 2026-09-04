/**
 * essentialsIngestService — the in-process core of the Validation Quests → Essentials
 * ingest path.
 *
 * WHY THIS FILE EXISTS:
 * The DB logic that stores a crowd-verified officeholder fact used to live only inside
 * the POST /api/essentials/ingest/quest-verified route. Validation Quests is now folded
 * into this engine (engine consolidation), so its consensus job can call this directly
 * in-process instead of looping back over HTTP with an X-Service-Key. The route keeps its
 * service-key auth for any external caller and delegates the storage to this function; the
 * folded VQ consensus job (src/vq/services/essentialsPipeline.ts) calls it with no key and
 * no network hop. Same validation, same idempotency, same table.
 *
 * VQ data lands in essentials.quest_verified_facts with status = 'pending_review'; accounts
 * admins review and promote from there. All writes use the engine pool — the essentials
 * schema is NOT exposed through PostgREST.
 *
 * IDEMPOTENCY:
 * consensus_record_id has a UNIQUE constraint. A duplicate returns { is_duplicate: true }
 * rather than raising, matching the xp/award pattern.
 */

import { z } from 'zod';
import { pool } from './db.js';

// ---------------------------------------------------------------------------
// Validation schema (shared with the route so both entry points agree)
// ---------------------------------------------------------------------------

export const QuestVerifiedFactSchema = z.object({
  consensus_record_id: z.string().min(1).max(255),
  quest_id:            z.string().min(1).max(255),
  question_text:       z.string().min(1).max(2000),
  verified_answer:     z.string().min(1).max(2000),
  confidence_level:    z.number().min(0).max(1),
  total_submissions:   z.number().int().positive(),
  jurisdiction_name:   z.string().min(1).max(500),
  politician_id:       z.string().uuid().optional(), // caller passes if known; null = needs manual match
});

export type QuestVerifiedFact = z.infer<typeof QuestVerifiedFactSchema>;

export interface IngestResult {
  is_duplicate: boolean;
  id: string | null;
}

/**
 * Thrown when the input fails schema validation. The route maps this to a 422 with the
 * same shape it returned before; the VQ consensus job catches it non-fatally.
 */
export class EssentialsIngestValidationError extends Error {
  readonly fields: Record<string, string[] | undefined>;
  constructor(message: string, fields: Record<string, string[] | undefined>) {
    super(message);
    this.name = 'EssentialsIngestValidationError';
    this.fields = fields;
  }
}

/**
 * Store one crowd-verified officeholder fact. Validates the input, then performs the
 * idempotent insert into essentials.quest_verified_facts.
 *
 * - Throws EssentialsIngestValidationError if `input` fails the schema.
 * - Returns { is_duplicate: true, id } if a row with this consensus_record_id already
 *   exists (fast path, or lost an insert race).
 * - Returns { is_duplicate: false, id } on a fresh insert.
 * - Lets any DB error propagate to the caller.
 */
export async function ingestQuestVerifiedFact(input: unknown): Promise<IngestResult> {
  const parsed = QuestVerifiedFactSchema.safeParse(input);
  if (!parsed.success) {
    throw new EssentialsIngestValidationError(
      parsed.error.issues[0]?.message ?? 'Invalid request body',
      parsed.error.flatten().fieldErrors
    );
  }

  const {
    consensus_record_id,
    quest_id,
    question_text,
    verified_answer,
    confidence_level,
    total_submissions,
    jurisdiction_name,
    politician_id,
  } = parsed.data;

  // Idempotency — fast path before the insert.
  const existing = await pool.query<{ id: string }>(
    `SELECT id FROM essentials.quest_verified_facts
     WHERE consensus_record_id = $1
     LIMIT 1`,
    [consensus_record_id]
  );
  if (existing.rows.length > 0) {
    return { is_duplicate: true, id: existing.rows[0]!.id };
  }

  const result = await pool.query<{ id: string }>(
    `INSERT INTO essentials.quest_verified_facts
       (consensus_record_id, quest_id, question_text, verified_answer,
        confidence_level, total_submissions, jurisdiction_name, politician_id)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     ON CONFLICT (consensus_record_id) DO NOTHING
     RETURNING id`,
    [
      consensus_record_id,
      quest_id,
      question_text,
      verified_answer,
      confidence_level,
      total_submissions,
      jurisdiction_name,
      politician_id ?? null,
    ]
  );

  // ON CONFLICT DO NOTHING returns no rows — another writer beat us to it.
  if (result.rows.length === 0) {
    const raced = await pool.query<{ id: string }>(
      `SELECT id FROM essentials.quest_verified_facts WHERE consensus_record_id = $1`,
      [consensus_record_id]
    );
    return { is_duplicate: true, id: raced.rows[0]?.id ?? null };
  }

  return { is_duplicate: false, id: result.rows[0]!.id };
}
