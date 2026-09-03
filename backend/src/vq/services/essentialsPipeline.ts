/**
 * essentialsPipeline.ts
 * Feature-flagged service for writing verified officeholder answers
 * to Empowered Vote's Essentials data layer (inform schema).
 *
 * Gated by ESSENTIALS_PIPELINE_ENABLED env var (default: false).
 * Non-fatal: any failure logs a warning and returns without throwing.
 */

import { logger } from '../lib/logger.js';

const ACCOUNTS_URL = process.env.ACCOUNTS_URL ?? 'https://accounts.empowered.vote';
const ESSENTIALS_PIPELINE_URL = `${ACCOUNTS_URL}/api/essentials/ingest/quest-verified`;

export interface EssentialsPipelineInput {
  questId: string;
  questType: string;
  questionText: string;
  consensusAnswer: string;
  confidenceLevel: string;   // internal string ('high') — mapped to number before sending
  totalSubmissions: number;
  consensusRecordId: string;
  jurisdictionName: string | null;
  politicianId?: string | null;   // add this field
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
    const res = await fetch(ESSENTIALS_PIPELINE_URL, {
      method: 'POST',
      headers: {
        'X-Service-Key': process.env.VQ_SERVICE_KEY ?? '',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        quest_id: input.questId,
        question_text: input.questionText,
        verified_answer: input.consensusAnswer,
        confidence_level: confidenceLevelNum,
        total_submissions: input.totalSubmissions,
        consensus_record_id: `vq-consensus-${input.consensusRecordId}`,
        jurisdiction_name: input.jurisdictionName,
        ...(input.politicianId ? { politician_id: input.politicianId } : {}),
      }),
    });

    if (res.status >= 400 && res.status < 500) {
      // 4xx: log and return immediately, no retry
      const body = await res.text().catch(() => '(unreadable)');
      logger.warn('Essentials pipeline: 4xx from endpoint — non-fatal, no retry', {
        questId: input.questId,
        status: res.status,
        body: body.substring(0, 200),
      });
      return;
    }

    if (res.status >= 500) {
      // 5xx: one retry after ~1 second
      const body = await res.text().catch(() => '(unreadable)');
      logger.warn('Essentials pipeline: 5xx from endpoint — retrying once', {
        questId: input.questId,
        status: res.status,
        body: body.substring(0, 200),
      });
      await new Promise((r) => setTimeout(r, 1000));
      try {
        const retryRes = await fetch(ESSENTIALS_PIPELINE_URL, {
          method: 'POST',
          headers: {
            'X-Service-Key': process.env.VQ_SERVICE_KEY ?? '',
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            quest_id: input.questId,
            question_text: input.questionText,
            verified_answer: input.consensusAnswer,
            confidence_level: confidenceLevelNum,
            total_submissions: input.totalSubmissions,
            consensus_record_id: `vq-consensus-${input.consensusRecordId}`,
            jurisdiction_name: input.jurisdictionName,
            ...(input.politicianId ? { politician_id: input.politicianId } : {}),
          }),
        });
        if (!retryRes.ok) {
          const retryBody = await retryRes.text().catch(() => '(unreadable)');
          logger.warn('Essentials pipeline: retry also failed — non-fatal', {
            questId: input.questId,
            status: retryRes.status,
            body: retryBody.substring(0, 200),
          });
          return;
        }
        const retryData = await retryRes.json().catch(() => ({}));
        if ((retryData as any).is_duplicate) {
          logger.info('Essentials pipeline: retry — already ingested (is_duplicate)', {
            questId: input.questId,
          });
          return;
        }
        logger.info('Essentials pipeline: retry succeeded', { questId: input.questId });
      } catch (retryErr) {
        logger.warn('Essentials pipeline: retry threw — non-fatal', {
          questId: input.questId,
          error: String(retryErr),
        });
      }
      return;
    }

    // 2xx success
    const data = await res.json().catch(() => ({}));
    if ((data as any).is_duplicate) {
      logger.info('Essentials pipeline: already ingested (is_duplicate) — non-fatal', {
        questId: input.questId,
      });
      return;
    }
    logger.info('Essentials pipeline: ingest succeeded', {
      questId: input.questId,
      response: data,
    });
  } catch (err) {
    logger.warn('Essentials pipeline: fetch threw — non-fatal', {
      questId: input.questId,
      error: String(err),
    });
  }
}
