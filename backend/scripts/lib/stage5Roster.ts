/**
 * stage5Roster.ts — who Stage 5 researches for one topic (season-topic-prep, design §4 and §5 step 1).
 *
 * Everyone in scope, one row per person: sitting officials at the levels the topic is asked at
 * (`inform.compass_topic_roles`), plus active candidates in upcoming races at those levels. A person who
 * holds two offices, or who sits and also runs, is ONE row (office_current_holder is politician-rooted
 * here and fans out, so the highest-level office is chosen in code). Nothing is dropped silently: an
 * active candidate with no politician record, an office whose level is unknown, and a level the topic is
 * not asked at are each reported through `onGap`.
 *
 * `leaving` says whether a sitting official is on their way out: `yes` when their seat has an upcoming
 * race and they are not a live candidate in it; `no` when they are on that ballot, or their chamber has
 * upcoming races on file but not for their seat; `unknown` when their chamber has no upcoming race on
 * file at all, so the data cannot say. Read-only.
 */
import { levelForDistrict, type Level } from '../../src/lib/topicApplicability.js';

type Query = (sql: string, params?: unknown[]) => Promise<{ rows: any[] }>;

export type RosterRow = {
  politician_id: string;
  full_name: string;
  office_id: string | null;
  level: Level;
  state: string | null;
  scope: 'sitting' | 'candidate' | 'both';
  leaving: 'yes' | 'no' | 'unknown';
  race_ids: string[];
};

export type RosterGap = { kind: 'candidate-no-politician' | 'no-level' | 'level-out-of-scope'; id: string; note: string };

const LEVEL_RANK: Record<Level, number> = { federal: 5, state: 4, judicial: 3, local: 2, school: 1 };
const LEVELS: Level[] = ['federal', 'state', 'judicial', 'local', 'school'];

type OfficeFields = {
  office_id: string | null; chamber_id: string | null; district_type: string | null; is_judicial: boolean | null;
  district_label: string | null; office_labels: (string | null)[] | null; state: string | null;
};

const levelOf = (r: OfficeFields): Level | null =>
  levelForDistrict(r.district_type ?? null, r.is_judicial ?? null, r.district_label ?? null, r.office_labels ?? []);

export async function loadRoster(
  q: Query, topicKey: string, onGap: (g: RosterGap) => void, opts: { asOf?: string } = {},
): Promise<RosterRow[]> {
  const asOf = opts.asOf ?? new Date().toISOString().slice(0, 10);
  const roles = await q(
    `-- stage5:roles
     SELECT r.role_scope FROM inform.compass_topic_roles r JOIN inform.compass_topics t ON t.id = r.topic_id
      WHERE t.topic_key = $1`,
    [topicKey],
  );
  const asked = new Set<string>(roles.rows.map((r) => r.role_scope));

  const officeCols = `o.id::text AS office_id, o.chamber_id::text AS chamber_id, d.district_type, d.is_judicial,
            d.label AS district_label, ARRAY[o.title, c.name] AS office_labels, upper(d.state) AS state`;
  const officeJoins = `LEFT JOIN essentials.districts d ON d.id = o.district_id
       LEFT JOIN essentials.chambers c ON c.id = o.chamber_id`;

  // Politician-rooted: one row per (person, office) here; the highest level is chosen below.
  const sitting = await q(
    `-- stage5:sitting
     SELECT och.politician_id::text AS politician_id, p.full_name, ${officeCols}
       FROM essentials.office_current_holder och
       JOIN essentials.politicians p ON p.id = och.politician_id
       JOIN essentials.offices o ON o.id = och.office_id
       ${officeJoins}
      WHERE och.politician_id IS NOT NULL`,
  );
  const candidates = await q(
    `-- stage5:candidates
     SELECT rc.id::text AS candidate_id, rc.politician_id::text AS politician_id, rc.full_name, r.id::text AS race_id, ${officeCols}
       FROM essentials.race_candidates rc
       JOIN essentials.races r ON r.id = rc.race_id
       JOIN essentials.elections e ON e.id = r.election_id
       LEFT JOIN essentials.offices o ON o.id = r.office_id
       ${officeJoins}
      WHERE rc.candidate_status = 'active' AND essentials.is_live_candidate(rc.candidate_status, rc.result)
        AND e.election_date >= $1::date`,
    [asOf],
  );
  const upcoming = await q(
    `-- stage5:upcoming
     SELECT DISTINCT r.office_id::text AS office_id, o.chamber_id::text AS chamber_id
       FROM essentials.races r
       JOIN essentials.elections e ON e.id = r.election_id
       JOIN essentials.offices o ON o.id = r.office_id
      WHERE e.election_date >= $1::date`,
    [asOf],
  );
  const officesUp = new Set<string>(upcoming.rows.map((r) => r.office_id));
  const chambersUp = new Set<string>(upcoming.rows.map((r) => r.chamber_id).filter(Boolean));

  const byPerson = new Map<string, RosterRow & { _rank: number }>();
  const candidacies = new Map<string, { race_id: string; office_id: string | null }[]>();
  const chamberOf = new Map<string, string | null>(); // the chosen sitting office's chamber, for `leaving`

  const place = (id: string, name: string, r: OfficeFields) => {
    const level = levelOf(r);
    if (!level) { onGap({ kind: 'no-level', id, note: `${name}: office ${r.office_id ?? '(none)'} has no known level` }); return null; }
    if (!asked.has(level)) { onGap({ kind: 'level-out-of-scope', id, note: `${name}: ${level} is not asked on this topic` }); return null; }
    return level;
  };

  for (const r of sitting.rows) {
    const level = place(r.politician_id, r.full_name, r);
    if (!level) continue;
    const old = byPerson.get(r.politician_id);
    if (old && old._rank >= LEVEL_RANK[level]) continue;
    byPerson.set(r.politician_id, {
      politician_id: r.politician_id, full_name: r.full_name, office_id: r.office_id, level, state: r.state || null,
      scope: 'sitting', leaving: 'unknown', race_ids: [], _rank: LEVEL_RANK[level],
    });
    chamberOf.set(r.politician_id, r.chamber_id ?? null);
  }

  for (const r of candidates.rows) {
    if (!r.politician_id) {
      onGap({ kind: 'candidate-no-politician', id: r.candidate_id, note: `${r.full_name}: active candidate in race ${r.race_id} with no politician record` });
      continue;
    }
    const list = candidacies.get(r.politician_id) ?? [];
    list.push({ race_id: r.race_id, office_id: r.office_id });
    candidacies.set(r.politician_id, list);
    const existing = byPerson.get(r.politician_id);
    if (existing) continue;
    const level = place(r.politician_id, r.full_name, r);
    if (!level) continue;
    byPerson.set(r.politician_id, {
      politician_id: r.politician_id, full_name: r.full_name, office_id: r.office_id, level, state: r.state || null,
      scope: 'candidate', leaving: 'no', race_ids: [], _rank: LEVEL_RANK[level],
    });
  }

  const out: RosterRow[] = [];
  for (const row of byPerson.values()) {
    const runs = candidacies.get(row.politician_id) ?? [];
    row.race_ids = [...new Set(runs.map((c) => c.race_id))].sort();
    if (row.scope === 'sitting') {
      if (runs.length) row.scope = 'both';
      const chamber = chamberOf.get(row.politician_id) ?? null;
      if (row.office_id && officesUp.has(row.office_id)) {
        row.leaving = runs.some((c) => c.office_id === row.office_id) ? 'no' : 'yes';
      } else if (chamber && chambersUp.has(chamber)) {
        row.leaving = 'no';
      } else {
        row.leaving = runs.length ? 'no' : 'unknown';
      }
    }
    const { politician_id, full_name, office_id, level, state, scope, leaving, race_ids } = row;
    out.push({ politician_id, full_name, office_id, level, state, scope, leaving, race_ids });
  }
  return out.sort((a, b) => LEVEL_RANK[b.level] - LEVEL_RANK[a.level] || (a.state ?? '').localeCompare(b.state ?? '') || a.full_name.localeCompare(b.full_name));
}

// ---- tsv --------------------------------------------------------------------------------------

export const ROSTER_COLUMNS = ['politician_id', 'full_name', 'office_id', 'level', 'state', 'scope', 'leaving', 'race_ids'] as const;

const clean = (s: string) => s.replace(/[\t\r\n]+/g, ' ');

export function formatRosterTsv(rows: RosterRow[]): string {
  const lines = rows.map((r) => [r.politician_id, clean(r.full_name), r.office_id ?? '', r.level, r.state ?? '', r.scope, r.leaving, r.race_ids.join(',')].join('\t'));
  return [ROSTER_COLUMNS.join('\t'), ...lines].join('\n') + '\n';
}

export function parseRosterTsv(text: string): RosterRow[] {
  const lines = text.split('\n').filter((l) => l.trim());
  if (lines[0] !== ROSTER_COLUMNS.join('\t')) throw new Error(`roster.tsv: header must be: ${ROSTER_COLUMNS.join(' ')}`);
  return lines.slice(1).map((line, i) => {
    const c = line.split('\t');
    const [politician_id, full_name, office_id, level, state, scope, leaving, race_ids] = c;
    if (!LEVELS.includes(level as Level)) throw new Error(`roster.tsv line ${i + 2}: bad level "${level}"`);
    if (!['sitting', 'candidate', 'both'].includes(scope)) throw new Error(`roster.tsv line ${i + 2}: bad scope "${scope}"`);
    if (!['yes', 'no', 'unknown'].includes(leaving)) throw new Error(`roster.tsv line ${i + 2}: bad leaving "${leaving}"`);
    return {
      politician_id, full_name, office_id: office_id || null, level: level as Level, state: state || null,
      scope: scope as RosterRow['scope'], leaving: leaving as RosterRow['leaving'], race_ids: race_ids ? race_ids.split(',') : [],
    };
  });
}

export function rosterCounts(rows: RosterRow[]) {
  const byLevel = Object.fromEntries(LEVELS.map((l) => [l, 0])) as Record<Level, number>;
  const byState: Record<string, number> = {};
  const byScope = { sitting: 0, candidate: 0, both: 0 };
  const leaving = { yes: 0, no: 0, unknown: 0 };
  for (const r of rows) {
    byLevel[r.level]++;
    const s = r.state ?? '(none)';
    byState[s] = (byState[s] ?? 0) + 1;
    byScope[r.scope]++;
    leaving[r.leaving]++;
  }
  return { byLevel, byState, byScope, leaving };
}
