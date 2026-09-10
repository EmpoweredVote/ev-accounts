import type { ClaimKeys } from './claimFingerprint.js';
import type { Lane } from './lanes.js';

/** How far back a claim counts as already covered. */
export const CLAIM_WINDOW_DAYS = 14;

export interface FingerprintRow {
  topicKey: string;
  valueKey: string;
  lane: Lane;
  questionExternalId: string | null;
  firstSeenAt: Date;
}

export interface FingerprintStore {
  /** Rows for this topic key first seen at or after `since`. */
  findByTopicKey(topicKey: string, since: Date): Promise<FingerprintRow[]>;
  insert(row: FingerprintRow & { generationJobId: number | null }): Promise<void>;
}

export type ClaimVerdict =
  | { kind: 'new' }
  | { kind: 'duplicate'; existing: FingerprintRow }
  | { kind: 'contradiction'; existing: FingerprintRow };

export function makeClaimGuard(store: FingerprintStore, now: () => Date = () => new Date()) {
  function windowStart(): Date {
    return new Date(now().getTime() - CLAIM_WINDOW_DAYS * 24 * 60 * 60 * 1000);
  }

  return {
    async check(keys: ClaimKeys): Promise<ClaimVerdict> {
      const rows = await store.findByTopicKey(keys.topicKey, windowStart());
      if (rows.length === 0) return { kind: 'new' };

      // A value match is a plain duplicate and takes priority: if we have
      // already published this exact answer, that is the relevant fact,
      // regardless of what else the pool says about the same topic.
      const sameValue = rows.find(r => r.valueKey === keys.valueKey);
      if (sameValue) return { kind: 'duplicate', existing: sameValue };

      // Same topic, different answer: two live answers to one question.
      const differing = rows.reduce((newest, r) =>
        r.firstSeenAt > newest.firstSeenAt ? r : newest,
      );
      return { kind: 'contradiction', existing: differing };
    },

    async record(
      keys: ClaimKeys,
      lane: Lane,
      questionExternalId: string | null,
      generationJobId: number | null,
    ): Promise<void> {
      await store.insert({
        topicKey: keys.topicKey,
        valueKey: keys.valueKey,
        lane,
        questionExternalId,
        firstSeenAt: now(),
        generationJobId,
      });
    },
  };
}
