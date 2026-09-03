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
    value: z.number().multipleOf(0.5).min(0).max(5.5),
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
    expect(AnswersNewSchema.safeParse({ answers: [{ topic_id: UUID, value: -1 }] }).success)
      .toBe(false);
  });

  // 🔴 THIS ASSERTION USED TO READ `value: 0 -> false`. It was not testing a
  // rule; it was pinning the gap that made a blank inexpressible. A blanked
  // answer IS value 0 — the politician was researched and the ladder moved out
  // from under them — so refusing it here meant blanks could only ever be
  // written by migration, never maintained through the editor.
  it('ACCEPTS value 0 — that is a blank, not a bad request', () => {
    expect(AnswersNewSchema.safeParse({ answers: [{ topic_id: UUID, value: 0 }] }).success)
      .toBe(true);
  });

  it('still enforces topic_id being a uuid', () => {
    expect(AnswersNewSchema.safeParse({ answers: [{ topic_id: 'nope', value: 3 }] }).success)
      .toBe(false);
  });
});

// 🔴 THE SCHEMA ABOVE IS A COPY, AND A COPY CAN DRIFT. It is re-declared rather
// than imported because the route module pulls in the pg pool at import time —
// which means this file could keep passing against a stale mirror while the real
// route rejects the payload. That is not hypothetical: FOUR separate zod schemas
// across three route files guard a write into inform.politician_answers, and
// every one of them independently blocked value 0.
//
// So this reads the sources. Each entry names a site and the exact text that must
// be there. Change a schema and this fails, naming the file — which is the point:
// the next person is told there are four, not one.
describe('every answer-value schema permits a blank', () => {
  const SITES = [
    {
      file: 'src/routes/compassAdmin.ts',
      what: 'PoliticianAnswersNewSchema — PUT /compass/politicians/:id/answers',
      expect: 'value: z.number().multipleOf(0.5).min(0).max(5.5),',
    },
    {
      file: 'src/routes/compassContributor.ts',
      what: 'singleStanceSchema + bulkStanceSchema — the contributor research surface',
      expect: 'value: z.number().int().min(0).max(5),',
      times: 2,
    },
    {
      file: 'src/routes/admin.ts',
      what: 'PoliticianAnswersSchema — PUT /admin/compass/politicians/:id/answers',
      expect: 'value: z.number().int().min(0).max(5),',
    },
  ];

  for (const site of SITES) {
    it(`${site.file} — ${site.what}`, async () => {
      const { readFileSync } = await import('node:fs');
      const src = readFileSync(site.file, 'utf8');
      const found = src.split(site.expect).length - 1;
      expect(found, `expected ${site.times ?? 1}x "${site.expect}" in ${site.file}`)
        .toBe(site.times ?? 1);
    });
  }

  // The mirror at the top of this file must say what the route says.
  it('the mirrored schema in this file matches the route it mirrors', async () => {
    const { readFileSync } = await import('node:fs');
    const route = readFileSync('src/routes/compassAdmin.ts', 'utf8');
    const mirror = readFileSync('src/routes/compassAdmin.answersPayload.test.ts', 'utf8');
    const line = 'value: z.number().multipleOf(0.5).min(0).max(5.5),';
    expect(route).toContain(line);
    expect(mirror).toContain(line);
  });

  // 🔴 A LADDER RUNG IS NOT AN ANSWER. compass_stance_revisions holds the five
  // rungs a topic offers, and there is no rung 0 — a blank is the ABSENCE of a
  // rung, not one of them. If a find-and-replace ever loosens these the same way,
  // a topic could be authored with a rung nothing can render.
  it('but the LADDER schemas still refuse 0', async () => {
    const { readFileSync } = await import('node:fs');
    for (const f of ['src/routes/compassRevisions.ts', 'src/routes/topicRewrites.ts']) {
      expect(readFileSync(f, 'utf8')).toContain('value: z.number().int().min(1).max(5),');
    }
  });
});
