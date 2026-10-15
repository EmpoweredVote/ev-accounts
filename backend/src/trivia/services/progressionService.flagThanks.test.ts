/**
 * awardFlagThanksGem — the contributor thank-you gem.
 *
 * An admin reviewing a flagged question thanks the reporter who was right. The
 * award is a plain yellow gem (CTC awards no other colour), so the ONLY thing
 * distinguishing it from a gem earned by playing a game is the ledger tagging:
 * transaction_type 'ctc_flag_thanks' and source_ref 'flag:<id>'. Nothing in any
 * UI renders a gem's reason today, which means that ledger row is the entire
 * record of why this gem exists — these tests guard it.
 */
import { describe, it, expect, vi, beforeEach } from 'vitest';

const awardGems = vi.hoisted(() => vi.fn());

// gemService -> lib/supabase.js -> lib/env.ts, whose startup validator calls
// process.exit(1) (not throw) on any missing engine env var. Mock at the seam.
vi.mock('../../lib/gemService.js', () => ({ awardGems }));
vi.mock('../config/supabase.js', () => ({ supabaseAdmin: {} }));
vi.mock('../db/index.js', () => ({ db: {} }));

import { awardFlagThanksGem } from './progressionService.js';

describe('awardFlagThanksGem', () => {
  beforeEach(() => {
    awardGems.mockReset();
    awardGems.mockResolvedValue({ gem_type: 'yellow', amount: 1, new_balance: 13, is_duplicate: false });
  });

  it('credits one yellow gem tagged as flag thanks against that flag', async () => {
    await awardFlagThanksGem('4f3a9c1e-0000-4000-8000-000000000001', 4812);

    expect(awardGems).toHaveBeenCalledTimes(1);
    expect(awardGems).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: '4f3a9c1e-0000-4000-8000-000000000001',
        gemType: 'yellow',
        amount: 1,
        transactionType: 'ctc_flag_thanks',
        sourceRef: 'flag:4812',
      })
    );
  });

  it('keys idempotency on the flag, so two clicks cannot credit twice', async () => {
    await awardFlagThanksGem('4f3a9c1e-0000-4000-8000-000000000001', 4812);
    await awardFlagThanksGem('4f3a9c1e-0000-4000-8000-000000000001', 4812);

    const [first] = awardGems.mock.calls[0];
    const [second] = awardGems.mock.calls[1];
    expect(first.idempotencyKey).toBe('ctc-flagthanks-4812');
    expect(second.idempotencyKey).toBe(first.idempotencyKey);
  });

  it('gives different flags different keys, so a second report is still paid', async () => {
    await awardFlagThanksGem('4f3a9c1e-0000-4000-8000-000000000001', 4812);
    await awardFlagThanksGem('4f3a9c1e-0000-4000-8000-000000000002', 4813);

    expect(awardGems.mock.calls[0][0].idempotencyKey).not.toBe(
      awardGems.mock.calls[1][0].idempotencyKey
    );
  });

  it('propagates a deleted-account refusal instead of swallowing it', async () => {
    // Unlike awardPlatformGems (end-of-game, never throws, a lost gem is not worth
    // failing a finished game over), this is a deliberate admin action: the admin
    // must be told it did not happen.
    awardGems.mockRejectedValue(
      Object.assign(new Error('Account has been deleted'), { code: 'ACCOUNT_DELETED' })
    );

    await expect(
      awardFlagThanksGem('4f3a9c1e-0000-4000-8000-000000000001', 4812)
    ).rejects.toMatchObject({ code: 'ACCOUNT_DELETED' });
  });
});
