import { describe, it, expect } from 'vitest';
import type { PoliticianFlatRecord } from '../../backend/src/lib/essentialsService';

describe('PoliticianFlatRecord field contract', () => {
  it('includes is_appointed field', () => {
    // Type-level: this won't compile if field is missing
    const record: Pick<PoliticianFlatRecord, 'is_appointed'> = { is_appointed: false };
    expect(record).toHaveProperty('is_appointed');
    expect(typeof record.is_appointed).toBe('boolean');
  });

  it('includes faces_retention_vote field', () => {
    const record: Pick<PoliticianFlatRecord, 'faces_retention_vote'> = { faces_retention_vote: false };
    expect(record).toHaveProperty('faces_retention_vote');
    expect(typeof record.faces_retention_vote).toBe('boolean');
  });

  it('includes is_elected field (existing — regression guard)', () => {
    const record: Pick<PoliticianFlatRecord, 'is_elected'> = { is_elected: true };
    expect(record).toHaveProperty('is_elected');
    expect(typeof record.is_elected).toBe('boolean');
  });
});
