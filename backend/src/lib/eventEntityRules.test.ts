import { describe, expect, it } from 'vitest';
import { validateEventEntities } from './eventEntityRules.js';

const CHAMBER_ID = '11111111-1111-4111-8111-111111111111';
const RACE_ID = '22222222-2222-4222-8222-222222222222';

describe('validateEventEntities', () => {
  it.each(['council', 'school_board'] as const)(
    'requires a chamber for %s',
    (eventKind) => {
      expect(validateEventEntities({
        eventKind,
        chamberId: null,
        raceId: null,
      })).toMatch(/chamberId is required/);
    }
  );

  it.each(['debate', 'forum'] as const)(
    'requires a race for %s',
    (eventKind) => {
      expect(validateEventEntities({
        eventKind,
        chamberId: null,
        raceId: null,
      })).toMatch(/raceId is required/);
    }
  );

  it('rejects both IDs for every kind', () => {
    expect(validateEventEntities({
      eventKind: 'news_clip',
      chamberId: CHAMBER_ID,
      raceId: RACE_ID,
    })).toMatch(/cannot both be set/);
  });

  it.each(['news_clip', 'community_meeting', 'other'] as const)(
    'allows neither entity for %s',
    (eventKind) => {
      expect(validateEventEntities({
        eventKind,
        chamberId: null,
        raceId: null,
      })).toBeNull();
    }
  );

  it('accepts the required single entity', () => {
    expect(validateEventEntities({
      eventKind: 'council',
      chamberId: CHAMBER_ID,
      raceId: null,
    })).toBeNull();

    expect(validateEventEntities({
      eventKind: 'debate',
      chamberId: null,
      raceId: RACE_ID,
    })).toBeNull();
  });
});
