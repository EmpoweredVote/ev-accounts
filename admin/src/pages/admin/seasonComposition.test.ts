import { describe, it, expect } from 'vitest';
import {
  classifyTopic,
  classifyAll,
  statCounts,
  type CompositionTopic,
  type RevisionContent,
} from './seasonComposition';

const rev = (id: string, revision = 1): RevisionContent => ({
  revision_id: id,
  revision,
  title: 'T',
  short_title: 'T',
  question_text: 'Q',
  ladder: [],
});

const mk = (over: Partial<CompositionTopic>): CompositionTopic => ({
  topic_id: 'topic-1',
  topic_key: 'topic-key',
  current: rev('cur'),
  in_open: null,
  in_draft: null,
  distribution: {},
  answer_total: 0,
  ...over,
});

const member = (pinId: string, n = 1) => ({
  question_number: n,
  display_order: n,
  pin: rev(pinId),
});

describe('classifyTopic', () => {
  it('carried: in both seasons with the same pin', () => {
    const t = mk({ current: rev('a'), in_open: member('a'), in_draft: member('a') });
    expect(classifyTopic(t, true).status).toBe('carried');
  });

  it('changed: in both seasons with different pins', () => {
    const t = mk({ current: rev('b'), in_open: member('a'), in_draft: member('b') });
    expect(classifyTopic(t, true).status).toBe('changed');
  });

  it('dropped: open only, when a draft exists', () => {
    const t = mk({ in_open: member('a') });
    expect(classifyTopic(t, true).status).toBe('dropped');
  });

  it('collapses dropped to carried when there is NO draft', () => {
    const t = mk({ in_open: member('a') });
    expect(classifyTopic(t, false).status).toBe('carried');
  });

  it('added: draft only', () => {
    const t = mk({ in_draft: member('b') });
    expect(classifyTopic(t, true).status).toBe('added');
  });

  it('available: in neither season (the topic pool)', () => {
    const t = mk({});
    expect(classifyTopic(t, true).status).toBe('available');
  });

  it('flags a stale draft pin when a newer revision was published after compose', () => {
    const t = mk({ current: rev('new'), in_open: member('old'), in_draft: member('old') });
    const c = classifyTopic(t, true);
    expect(c.pin_is_stale).toBe(true);
    // Still carried: both seasons pin the same revision; staleness is a flag, not a category.
    expect(c.status).toBe('carried');
  });

  it('does not flag staleness without a draft or without a current revision', () => {
    expect(classifyTopic(mk({ current: rev('new'), in_open: member('old') }), true).pin_is_stale).toBe(false);
    expect(classifyTopic(mk({ current: null, in_draft: member('old') }), true).pin_is_stale).toBe(false);
  });
});

describe('statCounts', () => {
  it('counts the four categories and ignores the pool', () => {
    const rows = classifyAll([
      mk({ topic_id: '1', in_open: member('a'), in_draft: member('a') }),  // carried
      mk({ topic_id: '2', current: rev('b'), in_open: member('a'), in_draft: member('b') }), // changed
      mk({ topic_id: '3', in_open: member('a') }),                          // dropped
      mk({ topic_id: '4', in_draft: member('b') }),                         // added
      mk({ topic_id: '5' }),                                                // available
    ], true);
    expect(statCounts(rows)).toEqual({ carried: 1, changed: 1, dropped: 1, added: 1 });
  });
});
