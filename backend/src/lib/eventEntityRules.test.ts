import { describe, it, expect } from 'vitest';
import { validateEventEntities } from './eventEntityRules.js';

const CHAMBER = '11111111-1111-4111-8111-111111111111';

describe('validateEventEntities', () => {
  it('requires chamberId for council and school_board', () => {
    expect(validateEventEntities({ eventKind: 'council', chamberId: null })).toMatch(/chamberId is required/);
    expect(validateEventEntities({ eventKind: 'school_board', chamberId: null })).toMatch(/chamberId is required/);
    expect(validateEventEntities({ eventKind: 'council', chamberId: CHAMBER })).toBeNull();
  });

  it('does not require anything for debate/forum (races derived from candidates)', () => {
    expect(validateEventEntities({ eventKind: 'debate', chamberId: null })).toBeNull();
    expect(validateEventEntities({ eventKind: 'forum', chamberId: null })).toBeNull();
  });
});
