/**
 * helpers.ts — pure helpers for the LegiScan state-legislature refresh (no I/O).
 *
 * Ported from the Python loader (backend/scripts/legiscan/import_state_legislative.py) so the
 * refresh can run as a Render cron job next to the other `ev-jobs-*` jobs. ev-cto decision 0030.
 *
 * Antipartisan rule: nothing here reads, stores or returns a legislator's party.
 */

export const STATE_NAMES: Record<string, string> = {
  AL: 'Alabama', AK: 'Alaska', AZ: 'Arizona', AR: 'Arkansas', CA: 'California',
  CO: 'Colorado', CT: 'Connecticut', DE: 'Delaware', DC: 'District of Columbia',
  FL: 'Florida', GA: 'Georgia', HI: 'Hawaii', ID: 'Idaho', IL: 'Illinois',
  IN: 'Indiana', IA: 'Iowa', KS: 'Kansas', KY: 'Kentucky', LA: 'Louisiana',
  ME: 'Maine', MD: 'Maryland', MA: 'Massachusetts', MI: 'Michigan',
  MN: 'Minnesota', MS: 'Mississippi', MO: 'Missouri', MT: 'Montana',
  NE: 'Nebraska', NV: 'Nevada', NH: 'New Hampshire', NJ: 'New Jersey',
  NM: 'New Mexico', NY: 'New York', NC: 'North Carolina', ND: 'North Dakota',
  OH: 'Ohio', OK: 'Oklahoma', OR: 'Oregon', PA: 'Pennsylvania',
  RI: 'Rhode Island', SC: 'South Carolina', SD: 'South Dakota', TN: 'Tennessee',
  TX: 'Texas', UT: 'Utah', VT: 'Vermont', VA: 'Virginia', WA: 'Washington',
  WV: 'West Virginia', WI: 'Wisconsin', WY: 'Wyoming',
  // No PR: LegiScan has no Puerto Rico dataset (getDatasetList answers "Invalid state PR").
};

/** `legislative_sessions.jurisdiction` value for a state: the lower-case full name. */
export function jurisdictionFor(stateCode: string): string {
  return STATE_NAMES[stateCode].toLowerCase();
}

const NICKNAME_GROUPS: Array<[string, string]> = [
  ['bill', 'william'], ['bob', 'robert'], ['bobby', 'robert'], ['rob', 'robert'],
  ['jim', 'james'], ['jimmy', 'james'], ['joe', 'joseph'], ['mike', 'michael'],
  ['tom', 'thomas'], ['dick', 'richard'], ['rick', 'richard'], ['rich', 'richard'],
  ['ron', 'ronald'], ['dan', 'daniel'], ['danny', 'daniel'], ['ed', 'edward'],
  ['ted', 'theodore'], ['ted', 'edward'], ['pat', 'patricia'], ['pat', 'patrick'],
  ['chris', 'christopher'], ['chris', 'christine'], ['beth', 'elizabeth'],
  ['liz', 'elizabeth'], ['sue', 'susan'], ['barb', 'barbara'], ['cathy', 'catherine'],
  ['kathy', 'katherine'], ['jeff', 'jeffrey'], ['steve', 'steven'], ['steve', 'stephen'],
  ['tony', 'anthony'], ['matt', 'matthew'], ['andy', 'andrew'], ['greg', 'gregory'],
  ['phil', 'philip'], ['larry', 'lawrence'], ['jerry', 'gerald'], ['terry', 'terrence'],
  ['peggy', 'margaret'], ['chuck', 'charles'], ['charlie', 'charles'], ['jack', 'john'],
  ['will', 'william'], ['sam', 'samuel'], ['ben', 'benjamin'], ['tim', 'timothy'],
  ['ken', 'kenneth'], ['don', 'donald'], ['dave', 'david'], ['doug', 'douglas'],
  ['al', 'albert'], ['al', 'alan'], ['alex', 'alexander'], ['nick', 'nicholas'],
  ['nate', 'nathaniel'], ['nate', 'nathan'], ['fred', 'frederick'], ['frank', 'francis'],
  ['frank', 'franklin'], ['hank', 'henry'], ['ray', 'raymond'], ['walt', 'walter'],
  ['wes', 'wesley'], ['lenny', 'leonard'], ['len', 'leonard'], ['marty', 'martin'],
  ['jon', 'jonathan'], ['vince', 'vincent'], ['vic', 'victor'],
];

const NICKNAME_MAP: Map<string, Set<string>> = (() => {
  const m = new Map<string, Set<string>>();
  for (const [a, b] of NICKNAME_GROUPS) {
    if (!m.has(a)) m.set(a, new Set());
    if (!m.has(b)) m.set(b, new Set());
    m.get(a)!.add(b);
    m.get(b)!.add(a);
  }
  return m;
})();

/** Lower-case first name plus its nickname variants ("dave" matches "david" and back). */
export function getNameVariants(firstName: string): string[] {
  const name = firstName.toLowerCase().trim();
  return [name, ...(NICKNAME_MAP.get(name) ?? [])];
}

/** LegiScan status integer (1-8) to a label; falls back to the last action text. */
const STATUS_MAP: Record<number, string> = {
  1: 'Introduced',
  2: 'In Committee',
  3: 'Passed',
  4: 'Passed',
  5: 'Vetoed',
  6: 'Failed',
  7: 'Passed',
  8: 'Signed',
};

export function normalizeBillStatus(statusInt: unknown, lastAction = ''): string {
  if (typeof statusInt === 'number' && STATUS_MAP[statusInt]) return STATUS_MAP[statusInt];
  const t = lastAction.toLowerCase();
  if (t.includes('signed') || t.includes('chaptered') || t.includes('public law')) return 'Signed';
  if (t.includes('passed') || t.includes('enrolled')) return 'Passed';
  if (t.includes('reported') || t.includes('engrossed')) return 'In Committee';
  if (t.includes('referred') || t.includes('committee')) return 'In Committee';
  if (t.includes('vetoed')) return 'Vetoed';
  if (t.includes('failed') || t.includes('dead')) return 'Failed';
  return 'Introduced';
}

const VOTE_MAP: Record<string, string> = {
  yea: 'yea', aye: 'yea', yes: 'yea',
  nay: 'nay', no: 'nay',
  nv: 'not_voting', 'not voting': 'not_voting',
  absent: 'absent', present: 'present',
};

export function normalizeVoteCast(voteText: string | undefined | null): string {
  return VOTE_MAP[(voteText ?? '').toLowerCase().trim()] ?? 'not_voting';
}

export function committeeChamber(raw: string | undefined | null): 'house' | 'senate' | 'joint' {
  const c = (raw ?? '').toUpperCase();
  if (c === 'H') return 'house';
  if (c === 'S') return 'senate';
  return 'joint';
}

export interface DatasetListEntry {
  session_id: number;
  year_start: number;
  year_end?: number;
  special?: number;
  dataset_hash: string;
  access_key: string;
  dataset_size?: number;
}

export type SessionLabel = 'current' | 'previous';

/**
 * The two newest regular (non-special) sessions: newest = current, next = previous.
 * Biennial states give e.g. 2025-2026 then 2023-2024; annual states give 2026 then 2025.
 */
export function pickSessionDatasets(
  datasets: DatasetListEntry[],
  wanted: SessionLabel[] = ['current', 'previous'],
): Array<{ label: SessionLabel; dataset: DatasetListEntry }> {
  const regular = datasets
    .filter((d) => (d.special ?? 0) === 0)
    .sort((a, b) => b.year_start - a.year_start);
  const labels: SessionLabel[] = ['current', 'previous'];
  return regular
    .slice(0, 2)
    .map((dataset, i) => ({ label: labels[i], dataset }))
    .filter((p) => wanted.includes(p.label));
}

export function sessionName(stateName: string, ds: Pick<DatasetListEntry, 'year_start' | 'year_end'>): string {
  const end = ds.year_end ?? ds.year_start;
  return end !== ds.year_start
    ? `${ds.year_start}-${end} ${stateName} Regular Session`
    : `${ds.year_start} ${stateName} Regular Session`;
}

/** 'YYYY-MM-DD' to the same string if valid, else null. Used for introduced and vote dates. */
export function parseIsoDate(s: unknown): string | null {
  if (typeof s !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(s)) return null;
  const d = new Date(`${s}T00:00:00Z`);
  // Round-trip, because the Date parser rolls 2026-02-30 forward to March instead of rejecting it.
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === s ? s : null;
}
