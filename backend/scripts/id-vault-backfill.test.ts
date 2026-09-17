import { describe, it, expect, vi } from 'vitest';
import { backfillSeal } from './id-vault-backfill.mjs';

describe('id-vault-backfill', () => {
  it('seals rows with a non-null name; skips null names', async () => {
    const seal = vi.fn().mockResolvedValue(undefined);
    const res = await backfillSeal(
      [{ user_id: 'a', legal_name: 'Ada' }, { user_id: 'b', legal_name: null }],
      seal, { dryRun: false }
    );
    expect(seal).toHaveBeenCalledTimes(1);
    expect(seal).toHaveBeenCalledWith('a', 'Ada');
    expect(res).toEqual({ sealed: 1, skipped: 1 });
  });

  it('dry-run seals nothing', async () => {
    const seal = vi.fn();
    const res = await backfillSeal([{ user_id: 'a', legal_name: 'Ada' }], seal, { dryRun: true });
    expect(seal).not.toHaveBeenCalled();
    expect(res).toEqual({ sealed: 0, skipped: 0 });
  });
});
