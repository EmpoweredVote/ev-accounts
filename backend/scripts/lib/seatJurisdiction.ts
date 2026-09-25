/**
 * seatJurisdiction — the jurisdiction names the CONFIRM identity check looks for on a snapshot
 * (spec §1.6). offices.representing_state holds a USPS code ('UT', 'IN', 'CA'); a two-letter token
 * is useless as an identity signal ("in" is on every page), so it is mapped to the state's full name.
 * The key set is pinned against state-fips.mjs (USPS_TO_FIPS) by the test, so a dropped
 * jurisdiction fails CI instead of silently weakening the check.
 */

/** USPS (uppercase) -> full name. 50 states + DC + the five territories (ADR 0003). */
export const USPS_TO_STATE_NAME: Readonly<Record<string, string>> = Object.freeze({
  AL: 'Alabama', AK: 'Alaska', AZ: 'Arizona', AR: 'Arkansas', CA: 'California', CO: 'Colorado',
  CT: 'Connecticut', DE: 'Delaware', DC: 'District of Columbia', FL: 'Florida', GA: 'Georgia',
  HI: 'Hawaii', ID: 'Idaho', IL: 'Illinois', IN: 'Indiana', IA: 'Iowa', KS: 'Kansas',
  KY: 'Kentucky', LA: 'Louisiana', ME: 'Maine', MD: 'Maryland', MA: 'Massachusetts',
  MI: 'Michigan', MN: 'Minnesota', MS: 'Mississippi', MO: 'Missouri', MT: 'Montana',
  NE: 'Nebraska', NV: 'Nevada', NH: 'New Hampshire', NJ: 'New Jersey', NM: 'New Mexico',
  NY: 'New York', NC: 'North Carolina', ND: 'North Dakota', OH: 'Ohio', OK: 'Oklahoma',
  OR: 'Oregon', PA: 'Pennsylvania', RI: 'Rhode Island', SC: 'South Carolina', SD: 'South Dakota',
  TN: 'Tennessee', TX: 'Texas', UT: 'Utah', VT: 'Vermont', VA: 'Virginia', WA: 'Washington',
  WV: 'West Virginia', WI: 'Wisconsin', WY: 'Wyoming',
  AS: 'American Samoa', GU: 'Guam', MP: 'Northern Mariana Islands', PR: 'Puerto Rico',
  VI: 'U.S. Virgin Islands',
});

/**
 * The names to look for: the state's full name (a USPS code is mapped; an unknown two-letter code
 * is dropped, never kept) and the city as given. Empty and <= 2-character tokens are dropped.
 */
export function seatJurisdictionNames(state: string | null | undefined, city: string | null | undefined): string[] {
  const out: string[] = [];
  const s = (state ?? '').trim();
  if (s) {
    const mapped = USPS_TO_STATE_NAME[s.toUpperCase()];
    if (mapped) out.push(mapped);
    else if (s.length > 2) out.push(s);
  }
  const c = (city ?? '').trim();
  if (c.length > 2) out.push(c);
  return out;
}
