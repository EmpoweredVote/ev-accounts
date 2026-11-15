import { describe, it, expect } from 'vitest';
import { dataSourceInfoFor, type BudgetAttribution } from './treasuryCitation';

/**
 * ⚠⚠⚠ THE ONE CLAIM A READER CAN CHECK FOR THEMSELVES.
 *
 * `data_source_info` becomes the href under every chart in Treasury Tracker.
 * Until this fix, a budget carrying a `data_source_id` took the registry branch
 * WHOLE and `budgets.source_url` was never consulted — so **704 budgets were
 * sent to a portal root while the row beside them held the exact dataset page
 * their figures came from** (696 CA State Controller across 87 entities, plus 8
 * West Hollywood demand registers with eight distinct dataset pages).
 *
 * ⭐ PURE, AND THAT IS THE POINT. The live contract tests in tests/integration
 * are `skipIf(!hasLiveDb)`, so a rule covered only there is checked only
 * sometimes. These run with no database and no credentials — which is also why
 * the rule lives in `treasuryCitation.ts` rather than in `treasuryService.ts`,
 * whose import chain calls `process.exit(1)` without an environment.
 *
 * ⚠ MEASURED AGAINST THE OLD CODE, not asserted about it. With the previous
 * precedence restored, exactly three of these fail — the dataset href, the
 * as-of date, and the `base_url` case. The other six pin behaviour this fix
 * deliberately does NOT change (the no-source_url fallback, the municipal
 * branch, the two null cases, the half-filled registry entry); they pass both
 * before and after, which is what makes them regression guards rather than
 * padding. A reader should be able to tell those two kinds apart, so: the
 * three that moved are the three that say so in their names.
 */

const row = (over: Partial<BudgetAttribution>): BudgetAttribution => ({
  data_source: null,
  source_url: null,
  source_date: null,
  ds_display_name: null,
  ds_url: null,
  ds_base_url: null,
  ds_last_synced_at: null,
  ...over,
});

/** The real shape of a CA State Controller budget — 696 of these. */
const CA_SCO = row({
  data_source: 'CA State Controller - Expenditures',
  source_url: 'https://bythenumbers.sco.ca.gov/d/ju3w-4gxp',
  source_date: '2026-06-16T00:00:00.000Z',
  ds_display_name: 'CA State Controller',
  ds_url: 'https://bythenumbers.sco.ca.gov',
  ds_base_url: null,
  ds_last_synced_at: '2026-11-08T04:13:10.413Z',
});

/** A West Hollywood demand register — 8 of these, and none carries a source_date. */
const WEHO = row({
  data_source: 'West Hollywood Demand Register FY2018-19',
  source_url: 'https://data.weho.org/d/by9g-vc9g',
  source_date: null,
  ds_display_name: 'West Hollywood Open Data',
  ds_url: 'https://data.weho.org',
  ds_base_url: 'https://data.weho.org',
  ds_last_synced_at: '2026-11-05T16:27:32.426Z',
});

describe('dataSourceInfoFor — the budget’s own citation wins', () => {
  it('⚠⚠⚠ sends the reader to the DATASET, not the portal root', () => {
    const info = dataSourceInfoFor(CA_SCO);
    expect(info?.url).toBe('https://bythenumbers.sco.ca.gov/d/ju3w-4gxp');
    expect(info?.datasetUrl).toBe('https://bythenumbers.sco.ca.gov/d/ju3w-4gxp');
    // ⛔ The exact regression: a 200 that lands on a list of datasets instead
    // of on the one the figures were parsed from.
    expect(info?.url).not.toBe('https://bythenumbers.sco.ca.gov');
  });

  it('⚠⚠ labels the chip with the AS-OF date, not the last sync timestamp', () => {
    // The client renders this "as of". `source_date` is period end /
    // publication; `ds_last_synced_at` is only when a job ran.
    expect(dataSourceInfoFor(CA_SCO)?.fetchedAt).toBe('2026-06-16T00:00:00.000Z');
    expect(dataSourceInfoFor(CA_SCO)?.fetchedAt).not.toBe('2026-11-08T04:13:10.413Z');
  });

  it('keeps the REGISTRY’s publisher name, not the internal dataset label', () => {
    expect(dataSourceInfoFor(CA_SCO)?.displayName).toBe('CA State Controller');
  });

  it('⚠ beats data_sources.base_url too, not just the registry URL', () => {
    // West Hollywood's base_url is ALSO a portal root, and for a non-federal
    // entity the client prefers `datasetUrl` — so fixing only `url` would have
    // changed nothing a reader actually clicks.
    const info = dataSourceInfoFor(WEHO);
    expect(info?.datasetUrl).toBe('https://data.weho.org/d/by9g-vc9g');
    expect(info?.url).toBe('https://data.weho.org/d/by9g-vc9g');
  });

  it('falls back to the sync timestamp only when the row has no as-of date', () => {
    expect(dataSourceInfoFor(WEHO)?.fetchedAt).toBe('2026-11-05T16:27:32.426Z');
  });

  it('⛔ still serves the registry entry when the budget names no document', () => {
    // 233 budgets depend on this. The fix NARROWS the fallback; removing it
    // would strip those pages of a source chip altogether.
    const info = dataSourceInfoFor(row({
      data_source: 'bloomington-open-data',
      ds_display_name: 'Bloomington Open Data',
      ds_url: 'https://data.bloomington.in.gov',
      ds_base_url: 'https://data.bloomington.in.gov',
      ds_last_synced_at: '2026-03-27T22:16:42.352Z',
    }));
    expect(info?.url).toBe('https://data.bloomington.in.gov');
    expect(info?.datasetUrl).toBe('https://data.bloomington.in.gov');
    expect(info?.fetchedAt).toBe('2026-03-27T22:16:42.352Z');
  });

  it('leaves the non-registry branch exactly as it was', () => {
    expect(dataSourceInfoFor(row({
      data_source: 'Treasury Tracker derived: Total Governmental',
      source_url: 'https://bythenumbers.sco.ca.gov/d/rrtv-rsj9',
      source_date: '2026-06-16T00:00:00.000Z',
    }))).toEqual({
      displayName: 'Treasury Tracker derived: Total Governmental',
      url: 'https://bythenumbers.sco.ca.gov/d/rrtv-rsj9',
      datasetUrl: 'https://bythenumbers.sco.ca.gov/d/rrtv-rsj9',
      fetchedAt: '2026-06-16T00:00:00.000Z',
    });
  });

  it('⛔ serves NO chip rather than an invented one', () => {
    expect(dataSourceInfoFor(row({}))).toBeNull();
    // ⚠ BOTH a name and a URL are needed. A URL with no publisher name would
    // render a nameless pill; a name with no URL, a chip linking nowhere.
    expect(dataSourceInfoFor(row({ source_url: 'https://example.gov/x.pdf' }))).toBeNull();
    expect(dataSourceInfoFor(row({ data_source: 'X' }))).toBeNull();
  });

  it('⚠⚠⚠ SERVES AN UNDATED CITATION — the reversal, and why', () => {
    // This assertion used to be `.toBeNull()`, pinned deliberately on the
    // ground that "an undated citation renders 'as of' a blank".
    //
    // ⛔ THE PREMISE WAS WRONG ABOUT THE CLIENT. Treasury Tracker's SourceChip
    // renders `{!compact && date && <span>· as of {date}</span>}` over
    // `const date = fetchDate ? fetchDate.slice(0, 10) : null`, so a null
    // `fetchedAt` renders NO span at all — the pill is `<sourceName> ↗`, and
    // the aria-label is guarded identically. There was never a blank to avoid.
    //
    // ⛔⛔ AND IT COST 24,573 BUDGETS THEIR CHIP (measured against production
    // 2026-11-14, 746 families): every MA DLS row — 16,813, the whole state,
    // every one of them freshly cited — plus all 7,682 CA publicpay rows. The
    // citation arc's own repairs set `source_url` without `source_date`, so
    // the work landed in the database and reached no reader.
    //
    // ⭐ An undated citation is not an unattributed one. The date is
    // decoration; the href is the substance.
    expect(dataSourceInfoFor(row({
      data_source: 'Abington — MA General Fund Revenues',
      source_url: 'https://dls-gw.dor.state.ma.us/reports/rdPage.aspx'
        + '?rdReport=ScheduleA.GeneralFund&iclMuni=001&islYear=2024&islAmountType=Revenues',
    }))).toEqual({
      displayName: 'Abington — MA General Fund Revenues',
      url: 'https://dls-gw.dor.state.ma.us/reports/rdPage.aspx'
        + '?rdReport=ScheduleA.GeneralFund&iclMuni=001&islYear=2024&islAmountType=Revenues',
      datasetUrl: 'https://dls-gw.dor.state.ma.us/reports/rdPage.aspx'
        + '?rdReport=ScheduleA.GeneralFund&iclMuni=001&islYear=2024&islAmountType=Revenues',
      fetchedAt: null,
    });
  });

  it('⚠ still prefers the as-of date when the row HAS one', () => {
    // The reversal relaxes a requirement; it must not drop the date when one
    // exists, or 21,682 Georgia and 116,456 Michigan chips lose their "as of".
    expect(dataSourceInfoFor(row({
      data_source: 'Georgia DCA Report of Local Government Finances',
      source_url: 'https://example.ga.gov/rlgf.xlsx',
      source_date: '2026-06-16T00:00:00.000Z',
    }))?.fetchedAt).toBe('2026-06-16T00:00:00.000Z');
  });

  it('⚠ a registry entry with a name but no URL is not a registry entry', () => {
    // Both halves are required; a half-filled entry must fall through rather
    // than serve a chip with an empty href.
    const info = dataSourceInfoFor(row({
      data_source: 'X',
      source_url: 'https://example.gov/x.pdf',
      source_date: '2026-01-01T00:00:00.000Z',
      ds_display_name: 'Some Registry',
      ds_url: null,
    }));
    expect(info?.displayName).toBe('X');
    expect(info?.url).toBe('https://example.gov/x.pdf');
  });
});
