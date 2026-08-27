import { describe, it, expect } from 'vitest';
import { z } from 'zod';

// These mirror the schemas guarding PUT /admin/compass/politicians/:id/answers.
// They are re-declared rather than imported because the route module pulls in
// the pg pool and the auth middleware at import time; the thing under test is
// the payload contract, and it is worth pinning on its own.
//
// WHY THIS FILE EXISTS. An empty array used to pass validation and reach
// admin_update_politician_answers, where `array_agg` over zero elements returns
// NULL and selected the RPC's delete-everything branch — one request wiped every
// answer a politician had. The RPC no longer deletes at all
// (CC_0001), so this is now the outer of two
// independent guards. Both must hold; neither is allowed to be the only one.
const AnswersNewSchema = z.object({
  answers: z.array(z.object({
    topic_id: z.string().uuid(),
    value: z.number().multipleOf(0.5).min(0.5).max(5.5),
  })).min(1, 'answers must contain at least one entry'),
});

const AnswersLegacySchema = z.array(z.object({
  topic_id: z.string().uuid(),
  value: z.number(),
})).min(1, 'answers must contain at least one entry');

const UUID = '11111111-1111-4111-8111-111111111111';

describe('answers payload — the empty array must be refused', () => {
  it('refuses { answers: [] }', () => {
    const r = AnswersNewSchema.safeParse({ answers: [] });
    expect(r.success).toBe(false);
  });

  it('refuses a bare [] on the legacy shape', () => {
    const r = AnswersLegacySchema.safeParse([]);
    expect(r.success).toBe(false);
  });

  it('says what is wrong rather than failing anonymously', () => {
    const r = AnswersNewSchema.safeParse({ answers: [] });
    expect(r.success).toBe(false);
    if (!r.success) {
      expect(r.error.issues[0]?.message).toContain('at least one');
    }
  });
});

describe('answers payload — real payloads still pass', () => {
  it('accepts a single-topic save, which is what the admin UI sends', () => {
    const r = AnswersNewSchema.safeParse({ answers: [{ topic_id: UUID, value: 3 }] });
    expect(r.success).toBe(true);
  });

  it('accepts a half step', () => {
    const r = AnswersNewSchema.safeParse({ answers: [{ topic_id: UUID, value: 2.5 }] });
    expect(r.success).toBe(true);
  });

  it('accepts a multi-topic save', () => {
    const r = AnswersNewSchema.safeParse({
      answers: [{ topic_id: UUID, value: 1 }, { topic_id: UUID, value: 5 }],
    });
    expect(r.success).toBe(true);
  });

  it('accepts the legacy flat array', () => {
    const r = AnswersLegacySchema.safeParse([{ topic_id: UUID, value: 4 }]);
    expect(r.success).toBe(true);
  });

  // Guard the guard: .min(1) must not have been pasted onto the wrong rule.
  it('still enforces the value range', () => {
    expect(AnswersNewSchema.safeParse({ answers: [{ topic_id: UUID, value: 9 }] }).success)
      .toBe(false);
    expect(AnswersNewSchema.safeParse({ answers: [{ topic_id: UUID, value: 0 }] }).success)
      .toBe(false);
  });

  it('still enforces topic_id being a uuid', () => {
    expect(AnswersNewSchema.safeParse({ answers: [{ topic_id: 'nope', value: 3 }] }).success)
      .toBe(false);
  });
});
