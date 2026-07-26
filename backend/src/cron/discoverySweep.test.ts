import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

/**
 * Operator policy (2026-07-26): no cron may spend API credits unattended.
 *
 * discovery-sweep is the only scheduled job in this service that spends money — one paid
 * Anthropic agent run per in-horizon jurisdiction, weekly. These tests pin the gate, and
 * specifically pin that it is DEFAULT-OFF: a missing env var must fail toward not spending.
 */

const scheduleMock = vi.hoisted(() => vi.fn());
vi.mock('node-cron', () => ({ default: { schedule: scheduleMock } }));
vi.mock('../lib/discoveryCron.js', () => ({ runDiscoverySweep: vi.fn() }));

import { startDiscoverySweepCron, isDiscoverySweepCronEnabled } from './discoverySweep.js';

const ORIGINAL = process.env.DISCOVERY_SWEEP_ENABLED;

beforeEach(() => {
  scheduleMock.mockReset();
  delete process.env.DISCOVERY_SWEEP_ENABLED;
});

afterEach(() => {
  if (ORIGINAL === undefined) delete process.env.DISCOVERY_SWEEP_ENABLED;
  else process.env.DISCOVERY_SWEEP_ENABLED = ORIGINAL;
});

describe('discovery-sweep cron — scheduled spend is opt-in', () => {
  it('DEFAULT-OFF: an unset flag registers no cron, so a forgotten variable cannot spend money', () => {
    startDiscoverySweepCron();
    expect(scheduleMock).not.toHaveBeenCalled();
    expect(isDiscoverySweepCronEnabled()).toBe(false);
  });

  it('registers the weekly job only when explicitly enabled', () => {
    process.env.DISCOVERY_SWEEP_ENABLED = 'true';

    startDiscoverySweepCron();

    expect(scheduleMock).toHaveBeenCalledTimes(1);
    const [expression, , options] = scheduleMock.mock.calls[0];
    expect(expression).toBe('0 2 * * 0'); // Sunday 02:00 UTC — unchanged
    expect(options).toMatchObject({ timezone: 'UTC', name: 'discovery-sweep' });
  });

  it.each(['1', 'yes', 'TRUE', 'on', ''])(
    'treats %o as OFF — only the exact string "true" enables spend',
    (value) => {
      process.env.DISCOVERY_SWEEP_ENABLED = value;
      startDiscoverySweepCron();
      expect(scheduleMock).not.toHaveBeenCalled();
    }
  );
});
