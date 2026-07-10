import { describe, it, expect, vi, afterEach } from 'vitest';

// The script's main() only auto-runs when `import.meta.url` matches
// `file://${process.argv[1]}` (see the isMainModule guard at the bottom of
// load-state-tiger-boundaries.ts) — under vitest that never matches, so
// importing it here is side-effect-free (no DB connect, no process.exit).
import {
  slugifyName,
  parseArgs,
  NATIONWIDE_COUNTY_COUNT_BOUNDS,
  LAYER_DISPATCH,
  processNationwideCounty,
  countAndValidateNationwideCounties,
} from '../scripts/load-state-tiger-boundaries.js';
import type { NationwideCountyRecordSource } from '../scripts/load-state-tiger-boundaries.js';

describe('slugifyName', () => {
  it('strips a trailing "County" suffix (regression)', () => {
    expect(slugifyName('Collin County')).toBe('collin');
    expect(slugifyName('Los Angeles County')).toBe('los_angeles');
  });

  it('strips a trailing "city" suffix (regression)', () => {
    expect(slugifyName('Los Angeles city')).toBe('los_angeles');
  });

  it('strips a trailing "Parish" suffix (Louisiana county-equivalent)', () => {
    expect(slugifyName('Orleans Parish')).toBe('orleans');
    expect(slugifyName('East Baton Rouge Parish')).toBe('east_baton_rouge');
  });

  it('strips a trailing "Planning Region" suffix (Connecticut 2022 TIGER reclassification)', () => {
    expect(slugifyName('Capitol Planning Region')).toBe('capitol');
    expect(slugifyName('Greater Bridgeport Planning Region')).toBe('greater_bridgeport');
  });

  it('strips a bare trailing "Region" suffix', () => {
    expect(slugifyName('Naugatuck Valley Region')).toBe('naugatuck_valley');
  });
});

describe('parseArgs — nationwide county mode', () => {
  let exitSpy: ReturnType<typeof vi.spyOn>;
  let stderrSpy: ReturnType<typeof vi.spyOn>;

  afterEach(() => {
    exitSpy?.mockRestore();
    stderrSpy?.mockRestore();
  });

  function mockExit() {
    stderrSpy = vi.spyOn(process.stderr, 'write').mockImplementation(() => true);
    exitSpy = vi.spyOn(process, 'exit').mockImplementation(((code?: number) => {
      throw new Error(`process.exit(${code})`);
    }) as never);
  }

  it('--nationwide --layers county enables nationwide mode', () => {
    const args = parseArgs(['--nationwide', '--layers', 'county']);
    expect(args.nationwide).toBe(true);
    expect(args.layers).toEqual(['county']);
  });

  it('--fips ALL is a synonym for --nationwide', () => {
    const args = parseArgs(['--fips', 'ALL', '--layers', 'county']);
    expect(args.nationwide).toBe(true);
    expect(args.layers).toEqual(['county']);
  });

  it('rejects --nationwide with more than one layer', () => {
    mockExit();
    expect(() => parseArgs(['--nationwide', '--layers', 'county,place'])).toThrow(/process\.exit/);
    expect(exitSpy).toHaveBeenCalledWith(1);
  });

  it('rejects --nationwide for a non-county layer (sldu/sldl/place/cd stay state-scoped)', () => {
    mockExit();
    expect(() => parseArgs(['--nationwide', '--layers', 'sldu'])).toThrow(/process\.exit/);
    expect(exitSpy).toHaveBeenCalledWith(1);
  });

  it('rejects --nationwide with no --layers', () => {
    mockExit();
    expect(() => parseArgs(['--nationwide'])).toThrow(/process\.exit/);
    expect(exitSpy).toHaveBeenCalledWith(1);
  });

  it('leaves the normal --state/--fips path unaffected when --nationwide is absent', () => {
    const args = parseArgs(['--state', 'CA', '--fips', '06', '--layers', 'county']);
    expect(args.nationwide).toBe(false);
    expect(args.state).toBe('CA');
    expect(args.fips).toBe('06');
  });
});

describe('NATIONWIDE_COUNTY_COUNT_BOUNDS', () => {
  it('brackets the expected ~3,143 county-equivalents with a non-brittle range', () => {
    expect(NATIONWIDE_COUNTY_COUNT_BOUNDS.min).toBeLessThan(3143);
    expect(NATIONWIDE_COUNTY_COUNT_BOUNDS.max).toBeGreaterThan(3143);
    // Sanity: not so wide it'd let a badly-filtered/truncated file slip through.
    expect(NATIONWIDE_COUNTY_COUNT_BOUNDS.max - NATIONWIDE_COUNTY_COUNT_BOUNDS.min).toBeLessThan(500);
  });
});

// ─── Structural zero-write guarantee (nationwide county dry-run) ─────────────
//
// Regression for the refactor that extracted the download + parse + pre-flight
// row-count assertion into `countAndValidateNationwideCounties`, a helper that
// takes NO `Client`. These tests exercise the real `processNationwideCounty` /
// `countAndValidateNationwideCounties` logic with an INJECTED in-memory record
// source (no network, no filesystem, no real DB) so the guarantee is verified
// against actual code paths, not just read by inspection.

type FakeFeature = { geom: unknown; props: Record<string, unknown> };

/** Build `count` synthetic county features for a given (in-FIPS_TO_STATE) STATEFP. */
function makeValidCountyFeatures(count: number, statefp = '06'): FakeFeature[] {
  const features: FakeFeature[] = [];
  for (let i = 0; i < count; i++) {
    const suffix = String(i).padStart(3, '0');
    features.push({
      geom: { type: 'Polygon', coordinates: [] },
      props: {
        STATEFP: statefp,
        GEOID: `${statefp}${suffix}`,
        NAMELSAD: `Fake County ${suffix}`,
        COUNTYFP: suffix,
      },
    });
  }
  return features;
}

/** Build `count` synthetic features for a STATEFP NOT in FIPS_TO_STATE (e.g. Puerto Rico '72'). */
function makeTerritoryCountyFeatures(count: number, statefp = '72'): FakeFeature[] {
  const features: FakeFeature[] = [];
  for (let i = 0; i < count; i++) {
    const suffix = String(i).padStart(3, '0');
    features.push({
      geom: { type: 'Polygon', coordinates: [] },
      props: {
        STATEFP: statefp,
        GEOID: `${statefp}${suffix}`,
        NAMELSAD: `Fake Territory County ${suffix}`,
        COUNTYFP: suffix,
      },
    });
  }
  return features;
}

/** Wrap a fixed in-memory feature array as an injectable NationwideCountyRecordSource. */
function makeFakeRecordSource(features: FakeFeature[]): NationwideCountyRecordSource & ReturnType<typeof vi.fn> {
  return vi.fn(async (_layerDef, _vintage, onRecord: (geom: unknown, props: Record<string, unknown>) => Promise<void>) => {
    for (const f of features) {
      await onRecord(f.geom, f.props);
    }
  }) as unknown as NationwideCountyRecordSource & ReturnType<typeof vi.fn>;
}

function makeFakeClient() {
  return { query: vi.fn().mockResolvedValue({ rowCount: 1 }) };
}

// An in-bounds nationwide feature set: comfortably between
// NATIONWIDE_COUNTY_COUNT_BOUNDS.min (3050) and .max (3200).
const IN_BOUNDS_VALID_COUNT = 3060;
const IN_BOUNDS_TERRITORY_COUNT = 5;

function makeInBoundsFeatures(): FakeFeature[] {
  return [
    ...makeValidCountyFeatures(IN_BOUNDS_VALID_COUNT, '06'),
    ...makeTerritoryCountyFeatures(IN_BOUNDS_TERRITORY_COUNT, '72'),
  ];
}

describe('countAndValidateNationwideCounties — client-free count/validate helper', () => {
  it('counts parsed vs. territory records and passes for an in-bounds count, with no Client involved', async () => {
    const recordSource = makeFakeRecordSource(makeInBoundsFeatures());
    const result = await countAndValidateNationwideCounties(
      LAYER_DISPATCH.county,
      '2024',
      recordSource,
    );
    expect(result.parsedCount).toBe(IN_BOUNDS_VALID_COUNT);
    expect(result.territoryCount).toBe(IN_BOUNDS_TERRITORY_COUNT);
  });

  it('throws (named MtfccAssertionError) for an out-of-bounds count', async () => {
    const recordSource = makeFakeRecordSource(makeValidCountyFeatures(10, '06'));
    await expect(
      countAndValidateNationwideCounties(LAYER_DISPATCH.county, '2024', recordSource),
    ).rejects.toMatchObject({ name: 'MtfccAssertionError' });
  });
});

describe('processNationwideCounty — structural zero-write guarantee', () => {
  it('dry-run: client.query is NEVER called, even with an in-bounds count and a real-shaped client', async () => {
    const fakeClient = makeFakeClient();
    const recordSource = makeFakeRecordSource(makeInBoundsFeatures());

    const totals = await processNationwideCounty(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      fakeClient as any,
      LAYER_DISPATCH.county,
      '2024',
      /* dryRun */ true,
      recordSource,
    );

    expect(fakeClient.query).not.toHaveBeenCalled();
    expect(totals.parsedCount).toBe(IN_BOUNDS_VALID_COUNT);
    expect(totals.territoryCount).toBe(IN_BOUNDS_TERRITORY_COUNT);
    expect(totals.inserted_boundary).toBe(0);
    expect(totals.inserted_district).toBe(0);
  });

  it('live mode: an in-bounds count writes rows, and only after count/validate has run', async () => {
    const fakeClient = makeFakeClient();
    const recordSource = makeFakeRecordSource(makeInBoundsFeatures());

    const totals = await processNationwideCounty(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      fakeClient as any,
      LAYER_DISPATCH.county,
      '2024',
      /* dryRun */ false,
      recordSource,
    );

    // Writes happened: one client.query per county (upsertGeofence) plus one
    // per insertDistrictIfMissing (county's writeDistrictRow is true).
    expect(fakeClient.query).toHaveBeenCalled();
    expect(fakeClient.query.mock.calls.length).toBe(IN_BOUNDS_VALID_COUNT * 2);
    expect(totals.inserted_boundary).toBe(IN_BOUNDS_VALID_COUNT);
    expect(totals.inserted_district).toBe(IN_BOUNDS_VALID_COUNT);
    expect(totals.skipped).toBe(IN_BOUNDS_TERRITORY_COUNT);

    // The record source was invoked twice — once for count/validate, once for
    // the write pass — confirming validation is a real pass over the data
    // that completes (and is awaited) strictly before any write-pass record
    // reaches client.query.
    expect(recordSource).toHaveBeenCalledTimes(2);
  });

  it('live mode: an out-of-bounds count aborts BEFORE any client.query call', async () => {
    const fakeClient = makeFakeClient();
    // Far below NATIONWIDE_COUNTY_COUNT_BOUNDS.min (3050) — must abort during
    // the count/validate pass, never reaching the write pass.
    const recordSource = makeFakeRecordSource(makeValidCountyFeatures(10, '06'));

    await expect(
      processNationwideCounty(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        fakeClient as any,
        LAYER_DISPATCH.county,
        '2024',
        /* dryRun */ false,
        recordSource,
      ),
    ).rejects.toMatchObject({ name: 'MtfccAssertionError' });

    expect(fakeClient.query).not.toHaveBeenCalled();
    // Only the count/validate pass ran; the write pass was never reached.
    expect(recordSource).toHaveBeenCalledTimes(1);
  });
});
