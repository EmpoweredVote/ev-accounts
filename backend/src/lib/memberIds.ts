/**
 * memberIds — a legislator's own member ids, from essentials.legislative_politician_id_map.
 *
 * The map (CA_0401) holds one row per (politician, id_type, id_value); one id names one person
 * (UNIQUE (id_type, id_value)). `match_method` says how the row was made:
 *   seat          the issuer's current-member list, matched on chamber + district (never on name)
 *   id_crosswalk  another id we already trust (an Open States record that links the LRL id)
 *   name          a name match (the LegiScan state importer). Not proof of identity.
 *   manual        set by hand
 *
 * Research tools that must not trust a name read only the id types they need, and only rows made by
 * something other than a name match (TRUSTED_MATCH_METHODS).
 */

type Query = (sql: string, params: unknown[]) => Promise<{ rows: Record<string, unknown>[] }>;

/** Minnesota Legislative Reference Library legislator id (lrl.mn.gov/legdb/fulldetail?ID=<id>). The same
 * number space for both chambers; it is what house.mn.gov/members/profile/<id> and the Senate's
 * member_bio.html?leg_id=<id> carry, and what Revisor author links point to. */
export const MN_LRL = 'mn-lrl';
/** The Minnesota Senate's own member number (senate.mn/api/members `mem_id`). NOT the LRL id. */
export const MN_SENATE_MEM = 'mn-senate-mem';

export const TRUSTED_MATCH_METHODS = ['seat', 'id_crosswalk', 'manual'] as const;

/** politician_id → id_type → id values (trusted rows only). */
export type MemberIdsByPolitician = Map<string, Record<string, string[]>>;

export async function loadMemberIds(
  query: Query, politicianIds: string[], idTypes: string[],
): Promise<MemberIdsByPolitician> {
  const out: MemberIdsByPolitician = new Map();
  if (!politicianIds.length || !idTypes.length) return out;
  let rows: Record<string, unknown>[];
  try {
    ({ rows } = await query(
      `SELECT politician_id::text AS pid, id_type, id_value
         FROM essentials.legislative_politician_id_map
        WHERE politician_id::text = ANY($1::text[]) AND id_type = ANY($2::text[])
          AND match_method = ANY($3::text[])`,
      [politicianIds, idTypes, [...TRUSTED_MATCH_METHODS]],
    ));
  } catch (err) {
    // 42703: match_method does not exist yet (CA_0401 not applied). No trusted ids — callers keep their
    // name rules, exactly as before the column existed.
    if ((err as { code?: string }).code === '42703') return out;
    throw err;
  }
  for (const r of rows) {
    const pid = String(r.pid);
    const rec = out.get(pid) ?? {};
    const t = String(r.id_type);
    rec[t] = [...(rec[t] ?? []), String(r.id_value)];
    out.set(pid, rec);
  }
  return out;
}
