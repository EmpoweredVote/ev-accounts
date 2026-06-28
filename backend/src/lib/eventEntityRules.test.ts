import { describe, it, expect } from 'vitest';
import { validateEventEntities } from './eventEntityRules.js';

const CHAMBER = '11111111-1111-4111-8111-111111111111';

describe('validateEventEntities', () => {
  it('imposes no requirements (races derived in pipeline; chamber optional)', () => {
    // council/school_board no longer require a chamber (multi-seat bodies).
    expect(validateEventEntities({ eventKind: 'council', chamberId: null })).toBeNull();
    expect(validateEventEntities({ eventKind: 'school_board', chamberId: null })).toBeNull();
    // still fine when a chamber is present, and for race-bearing kinds.
    expect(validateEventEntities({ eventKind: 'council', chamberId: CHAMBER })).toBeNull();
    expect(validateEventEntities({ eventKind: 'debate', chamberId: null })).toBeNull();
    expect(validateEventEntities({ eventKind: 'forum', chamberId: null })).toBeNull();
  });
});
