import { describe, it, expect, vi, beforeEach } from 'vitest';

// getCompassCategories reads the promoted set through pool.query and three inform tables through
// supabaseAnon. Its tier flags must come from appliesFromRoles (CA_0256): the same rule as
// getCompassTopics, including applies_school, which is false for a topic with no role rows.
const { mockQuery, tables } = vi.hoisted(() => ({
  mockQuery: vi.fn(),
  tables: {} as Record<string, unknown[]>,
}));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));
vi.mock('./supabase.js', () => {
  const from = (table: string) => ({
    select: () => {
      const res = { data: tables[table] ?? [], error: null };
      return Object.assign(Promise.resolve(res), { order: () => Promise.resolve(res) });
    },
  });
  return { supabaseAnon: { schema: () => ({ from }) }, supabaseService: {}, adminRpc: vi.fn(), createUserClient: vi.fn() };
});

import { getCompassCategories } from './compassService.js';

const promoted = (id: string, key: string, title: string) => ({
  id, topic_key: key, title, short_title: title, question_text: 'Q?', version: 1,
  effective_revision_id: `rev-${id}`, fc_community_slug: null, judicial_role: null, is_live: true, office_scope: null,
});

beforeEach(() => {
  mockQuery.mockReset();
  mockQuery.mockResolvedValue({
    rows: [
      promoted('t-edu', 'education-library-books', 'Library Books'),
      promoted('t-vou', 'school-vouchers', 'School Vouchers'),
      promoted('t-any', 'cross-cutting', 'Cross Cutting'),
    ],
  });
  tables.compass_categories = [{ id: 'c1', title: 'Education' }];
  tables.compass_topic_categories = [
    { category_id: 'c1', topic_id: 't-edu' },
    { category_id: 'c1', topic_id: 't-vou' },
    { category_id: 'c1', topic_id: 't-any' },
    { category_id: 'c1', topic_id: 't-retired' }, // not in the open season: dropped
  ];
  tables.compass_topic_roles = [
    { topic_id: 't-edu', role_scope: 'local' }, { topic_id: 't-edu', role_scope: 'state' },
    { topic_id: 't-edu', role_scope: 'school' },
    { topic_id: 't-vou', role_scope: 'federal' }, { topic_id: 't-vou', role_scope: 'state' },
  ];
});

describe('getCompassCategories — tier flags from appliesFromRoles, applies_school included', () => {
  it('attaches all five flags per topic and drops topics outside the open season', async () => {
    const [cat] = await getCompassCategories();
    const byKey = Object.fromEntries((cat.topics as { topic_key: string }[]).map((t) => [t.topic_key, t]));
    expect(Object.keys(byKey).sort()).toEqual(['cross-cutting', 'education-library-books', 'school-vouchers']);
    expect(byKey['education-library-books']).toMatchObject({
      applies_federal: false, applies_state: true, applies_local: true, applies_judicial: false, applies_school: true,
    });
    expect(byKey['school-vouchers']).toMatchObject({
      applies_federal: true, applies_state: true, applies_local: false, applies_judicial: false, applies_school: false,
    });
    // No role rows: cross-cutting for federal/state/local, never judicial, never school.
    expect(byKey['cross-cutting']).toMatchObject({
      applies_federal: true, applies_state: true, applies_local: true, applies_judicial: false, applies_school: false,
    });
  });
});
