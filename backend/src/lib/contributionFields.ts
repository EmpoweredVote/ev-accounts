/**
 * Column-first SQL for the contributions fields that used to be read out of `raw_record` (CA_0380).
 *
 * WHY. Part D of ev-cto decision 0038 moves `raw_record` out of `transparent_motivations.contributions`
 * (it is ~80% of the table). CA_0380 added one typed column per key that anything reads, and a trigger
 * that fills them from `raw_record` on every write. The existing ~29M rows get their columns in the
 * Part D copy, which also stops keeping FEC's JSON. So for a while a row may have:
 *   - columns NULL and the JSON present  (old rows, before the copy), or
 *   - columns filled and the JSON NULL   (FEC rows, after the copy), or
 *   - both                               (new rows, and state-source rows after the copy).
 * Every reader therefore reads the COLUMN FIRST and the JSON second. Each column holds exactly
 * `raw_record->>'<key>'` (see `contribution_typed_fields`), so `COALESCE(column, raw_record->>'<key>')`
 * equals today's `raw_record->>'<key>'` on every row, in every state above. The copy checks that on
 * all rows before it swaps tables.
 *
 * Every expression here assumes the contributions table is aliased `c`.
 *
 * Step 6 of the plan drops `raw_record`; then each expression collapses to its column.
 */

/** JSON key -> typed column, for the keys stored one column per key. */
const PER_KEY = {
  contributor_name: 'src_contributor_name',
  con_name: 'src_con_name',
  Tran_NamL: 'src_tran_naml',
  Tran_NamF: 'src_tran_namf',
  ContributorName: 'src_contributorname',
  CTRIB_NAML: 'src_ctrib_naml',
  CTRIB_NAMF: 'src_ctrib_namf',
  type: 'src_type',
  entity_type: 'src_entity_type',
  ENTITY_CD: 'src_entity_cd',
  ContributorType: 'src_contributortype',
  recordTypeDescription: 'src_recordtypedescription',
  contributor_committee_id: 'src_contributor_committee_id',
  schedule: 'src_schedule',
  con_desc: 'src_con_desc',
  committee_id: 'fec_committee_id',
  report_type: 'fec_report_type',
} as const;

export type ContributionKey = keyof typeof PER_KEY;

/** `raw_record->>'<key>'`, read from the column first. Text, NULL when absent. */
export function cf(key: ContributionKey): string {
  return `COALESCE(c.${PER_KEY[key]}, c.raw_record->>'${key}')`;
}

/**
 * The merged donor-detail columns. Every reader already reads these as
 * COALESCE(raw->>'contributor_x', raw->>'con_x'), which is exactly what the column holds.
 */
export const EMPLOYER_SQL =
  `COALESCE(c.donor_employer, c.raw_record->>'contributor_employer', c.raw_record->>'con_empr')`;
export const OCCUPATION_SQL =
  `COALESCE(c.donor_occupation, c.raw_record->>'contributor_occupation', c.raw_record->>'con_occp')`;
export const CITY_SQL =
  `COALESCE(c.donor_city, c.raw_record->>'contributor_city', c.raw_record->>'con_city_nm')`;
export const STATE_SQL =
  `COALESCE(c.donor_state, c.raw_record->>'contributor_state', c.raw_record->>'con_state_nm')`;

/** `raw_record->>'is_individual'` — 'true' / 'false' / NULL, as before. */
export const IS_INDIVIDUAL_TEXT_SQL =
  `COALESCE(c.src_is_individual::text, c.raw_record->>'is_individual')`;

/**
 * A JSON object holding the keys the TypeScript helpers in campaignFinanceService read
 * (extractDonorType / extractOccupation / extractEmployer / extractContributorName). It replaces
 * selecting `c.raw_record` itself, which is NULL for FEC rows after the Part D copy.
 *
 * Employer and occupation travel under the `contributor_*` key because the helpers read
 * `contributor_x ?? con_x`, which is what the merged column already is. `is_individual` stays a JSON
 * boolean, as the helper compares it with `=== true`.
 */
export const TYPED_RECORD_SQL = `jsonb_build_object(
  'contributor_name', ${cf('contributor_name')},
  'con_name', ${cf('con_name')},
  'Tran_NamL', ${cf('Tran_NamL')},
  'Tran_NamF', ${cf('Tran_NamF')},
  'contributor_employer', ${EMPLOYER_SQL},
  'contributor_occupation', ${OCCUPATION_SQL},
  'type', ${cf('type')},
  'entity_type', ${cf('entity_type')},
  'ENTITY_CD', ${cf('ENTITY_CD')},
  'ContributorType', ${cf('ContributorType')},
  'recordTypeDescription', ${cf('recordTypeDescription')},
  'is_individual', COALESCE(to_jsonb(c.src_is_individual), c.raw_record->'is_individual'),
  'contributor_committee_id', ${cf('contributor_committee_id')}
)`;
