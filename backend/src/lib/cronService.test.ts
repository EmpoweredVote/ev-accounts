import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

const { adminRpcMock, rpcMock, executeDemotionMock } = vi.hoisted(() => ({
  adminRpcMock: vi.fn(),
  rpcMock: vi.fn(),
  executeDemotionMock: vi.fn(),
}));

vi.mock('./supabase.js', () => ({
  adminRpc: adminRpcMock,
  supabaseAdmin: { rpc: rpcMock },
}));
vi.mock('./empowerService.js', () => ({ executeDemotion: executeDemotionMock }));

import { runCalibrationLapseJob } from './cronService.js';

/** Which adminRpc functions were called, in order. */
function calledRpcs(): string[] {
  return adminRpcMock.mock.calls.map((c) => c[0] as string);
}

beforeEach(() => {
  adminRpcMock.mockReset();
  rpcMock.mockReset();
  executeDemotionMock.mockReset();

  vi.spyOn(console, 'log').mockImplementation(() => {});
  vi.spyOn(console, 'error').mockImplementation(() => {});

  // The idempotency upsert claims today's run; everything else succeeds by default.
  adminRpcMock.mockImplementation((fn: string) => {
    if (fn === 'cron_upsert_lapse_run') return Promise.resolve({ data: true, error: null });
    return Promise.resolve({ data: null, error: null });
  });
});

// ---------------------------------------------------------------------------

describe('calibration lapse — a broken detector must not report a clean run', () => {
  // 🔴 The three get_calibration_lapsed_users calls destructured only `data`, discarding
  // `error`. A failing RPC therefore yielded `data: null` -> `?? []` -> zero lapsed users,
  // and the job recorded warned_25=0, warned_30=0, demoted=0 and logged level:info. The
  // lapse detector could be dead for weeks and every signal would read healthy. Nobody is
  // wrongly demoted, so the DIRECTION is safe — the silence is the defect.

  it('throws when the lapsed-users RPC fails instead of counting zero', async () => {
    rpcMock.mockResolvedValue({ data: null, error: { message: 'relation does not exist' } });

    await expect(runCalibrationLapseJob()).rejects.toThrow(/relation does not exist/);
  });

  it('records the failure on the run row', async () => {
    rpcMock.mockResolvedValue({ data: null, error: { message: 'relation does not exist' } });

    await runCalibrationLapseJob().catch(() => {});

    expect(calledRpcs()).toContain('cron_record_lapse_error');
  });

  it('does not stamp a clean zero-count result when the RPC failed', async () => {
    rpcMock.mockResolvedValue({ data: null, error: { message: 'relation does not exist' } });

    await runCalibrationLapseJob().catch(() => {});

    expect(calledRpcs()).not.toContain('cron_update_lapse_run');
  });

  it('demotes nobody when the RPC failed', async () => {
    rpcMock.mockResolvedValue({ data: null, error: { message: 'relation does not exist' } });

    await runCalibrationLapseJob().catch(() => {});

    expect(executeDemotionMock).not.toHaveBeenCalled();
  });
});

describe('calibration lapse — a genuinely quiet day still succeeds', () => {
  it('records a zero-count run when no user has lapsed', async () => {
    // Positive control. An empty result with NO error is a real answer: nobody lapsed.
    rpcMock.mockResolvedValue({ data: [], error: null });

    await runCalibrationLapseJob();

    expect(calledRpcs()).toContain('cron_update_lapse_run');
    expect(calledRpcs()).not.toContain('cron_record_lapse_error');
  });

  it('demotes a user the RPC reports at day 31', async () => {
    rpcMock.mockImplementation((_fn: string, args: { p_days_threshold: number }) =>
      Promise.resolve({
        data:
          args.p_days_threshold === 31
            ? [{ user_id: 'user-1', overdue_topic_ids: ['t1'], days_overdue: 31 }]
            : [],
        error: null,
      })
    );

    await runCalibrationLapseJob();

    expect(executeDemotionMock).toHaveBeenCalledTimes(1);
    expect(calledRpcs()).toContain('cron_update_lapse_run');
  });
});
