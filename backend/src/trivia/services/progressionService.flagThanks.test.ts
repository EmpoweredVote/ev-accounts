/**
 * awardFlagThanksGem — the contributor thank-you gem.
 *
 * An admin reviewing a flagged question thanks the reporter who was right.
 *
 * The gem is RED, not the yellow CTC hands out for playing. Red is the platform's
 * verification currency — the only other code that awards it is the VQ quest path
 * (1 gem for a correct answer, 2 more for citing a valid source), and catching a
 * factually broken question is the same kind of act. Yellow would have paid the
 * same amount for a different thing.
 *
 * That choice also hardens the tier gate rather than relying on it: Inform-tier
 * accounts CANNOT hold red at all (awardGems throws INFORM_TIER_NO_BLUE_RED), so
 * "Connected and Empowered only" stops being a product rule the route enforces
 * alone and becomes something the ledger refuses underneath it.
 *
 * The ledger tagging — transaction_type 'ctc_flag_thanks', source_ref 'flag:<id>'
 * — is still the only record of WHY the gem exists, since no UI renders a gem's
 * reason. These tests guard the colour, the tag and the key.
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
    awardGems.mockResolvedValue({ gem_type: 'red', amount: 1, new_balance: 4, is_duplicate: false });
  });

  it('credits one RED gem tagged as flag thanks against that flag', async () => {
    await awardFlagThanksGem('4f3a9c1e-0000-4000-8000-000000000001', 4812);

    expect(awardGems).toHaveBeenCalledTimes(1);
    expect(awardGems).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: '4f3a9c1e-0000-4000-8000-000000000001',
        gemType: 'red',
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
