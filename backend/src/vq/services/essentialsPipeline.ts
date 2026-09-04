/**
 * essentialsPipeline.ts
 * Feature-flagged service for writing verified officeholder answers
 * to Empowered Vote's Essentials data layer.
 *
 * Gated by ESSENTIALS_PIPELINE_ENABLED env var (default: false).
 * Non-fatal: any failure logs a warning and returns without throwing.
 *
 * Engine consolidation (VQ fold-in): this used to POST to
 * ACCOUNTS_URL/api/essentials/ingest/quest-verified carrying X-Service-Key: VQ_SERVICE_KEY.
 * VQ now runs inside the engine, so it writes in-process via ingestQuestVerifiedFact — the
 * same validation, idempotency, and table the HTTP route uses — with no network hop and no
 * service key.
 */

import { logger } from '../lib/logger.js';
import {
  ingestQuestVerifiedFact,
  EssentialsIngestValidationError,
} from '../../lib/essentialsIngestService.js';

export interface EssentialsPipelineInput {
  questId: string;
  questType: string;
  questionText: string;
  consensusAnswer: string;
  confidenceLevel: string;   // internal string ('high') — mapped to number before storing
  totalSubmissions: number;
  consensusRecordId: string;
  jurisdictionName: string | null;
  politicianId?: string | null;
}

/**
 * Write a verified officeholder answer to the Essentials data layer.
 *
 * - Returns immediately if ESSENTIALS_PIPELINE_ENABLED !== 'true'
 * - Returns immediately if questType !== 'official'
 * - Returns immediately if jurisdictionName is null
 * - Catches all errors and logs warnings — never throws
 */
export async function writeToEssentials(input: EssentialsPipelineInput): Promise<void> {
  if (process.env.ESSENTIALS_PIPELINE_ENABLED !== 'true') {
    return;
  }

  if (input.questType !== 'official') {
    return;
  }

  if (!input.jurisdictionName) {
    logger.info('Essentials pipeline: skipping ingest — jurisdictionName is null', {
      questId: input.questId,
    });
    return;
  }

  const confidenceLevelMap: Record<string, number> = {
    high: 1.0,
    moderate: 0.8,
    low: 0.6,
  };
  const confidenceLevelNum = confidenceLevelMap[input.confidenceLevel] ?? 0.6;

  try {
    const result = await ingestQuestVerifiedFact({
      quest_id: input.questId,
      question_text: input.questionText,
      verified_answer: input.consensusAnswer,
      confidence_level: confidenceLevelNum,
      total_submissions: input.totalSubmissions,
      consensus_record_id: `vq-consensus-${input.consensusRecordId}`,
      jurisdiction_name: input.jurisdictionName,
      ...(input.politicianId ? { politician_id: input.politicianId } : {}),
    });

    if (result.is_duplicate) {
      logger.info('Essentials pipeline: already ingested (is_duplicate) — non-fatal', {
        questId: input.questId,
      });
      return;
    }

    logger.info('Essentials pipeline: ingest succeeded', {
      questId: input.questId,
      id: result.id,
    });
  } catch (err) {
    // Validation failures and DB errors are both non-fatal here — the same posture the
    // old HTTP path had toward a 4xx/5xx from the endpoint.
    if (err instanceof EssentialsIngestValidationError) {
      logger.warn('Essentials pipeline: validation rejected the fact — non-fatal', {
        questId: input.questId,
        message: err.message,
        fields: err.fields,
      });
      return;
    }
    logger.warn('Essentials pipeline: ingest threw — non-fatal', {
      questId: input.questId,
      error: String(err),
    });
  }
}
