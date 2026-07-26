import { pool } from './db.js';

export interface BodySearchRow {
  slug: string;
  name_formal: string;
  state: string;
  member_count: number;
}

export interface RosterMember {
  politician_slug: string | null;
  politician_id: string;
  full_name: string;
  preferred_name: string;
  title: string;
  chamber_name: string;
  district_label: string;
  photo_url: string | null;
}

export interface RosterResponse {
  slug: string;
  name_formal: string;
  state: string;
  fetched_at: string;
  members: RosterMember[];
}

const TITLE_RANK: Array<[RegExp, number]> = [
  [/\b(president|chair|chairperson|chairman|chairwoman|speaker|mayor)\b/i, 0],
  [/\b(vice[- ]?president|vice[- ]?chair|deputy|pro[- ]?tempore)\b/i, 1],
];

export function titleRank(title: string): number {
  for (const [re, rank] of TITLE_RANK) if (re.test(title)) return rank;
  return 2;
}

export function resolveDistrictLabel(rawLabel: string, districtType: string): string {
  if (rawLabel && rawLabel.trim() !== '') return rawLabel;
  if (districtType && districtType.endsWith('_EXEC')) return 'At-Large';
  return '';
}

export async function searchBodies(
  q: string,
  state: string | null
): Promise<BodySearchRow[]> {
  const { rows } = await pool.query(
    `
    SELECT
      ch.slug,
      MAX(ch.name_formal)                       AS name_formal,
      COALESCE(MAX(o.representing_state), '')   AS state,
      COUNT(*) FILTER (
        WHERE p.is_active = true AND o.is_vacant = false
      )::int                                     AS member_count
    FROM essentials.chambers ch
    LEFT JOIN essentials.offices o     ON o.chamber_id = ch.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
    WHERE ch.name_formal ILIKE '%' || $1 || '%'
      AND ch.slug IS NOT NULL
      AND ch.slug <> ''
      AND ($2::text IS NULL OR o.representing_state = $2)
    GROUP BY ch.slug
    ORDER BY MAX(ch.name_formal)
    `,
    [q, state]
  );
  return rows.map((r) => ({
    slug: r.slug as string,
    name_formal: (r.name_formal as string) ?? '',
    state: (r.state as string) ?? '',
    member_count: Number(r.member_count ?? 0),
  }));
}

export async function getRosterBySlug(
  slug: string
): Promise<RosterResponse | null> {
  const { rows: chamberRows } = await pool.query(
    `
    SELECT
      ch.slug,
      MAX(ch.name_formal)                     AS name_formal,
      COALESCE(MAX(o.representing_state), '') AS state
    FROM essentials.chambers ch
    LEFT JOIN essentials.offices o ON o.chamber_id = ch.id
    WHERE ch.slug = $1
    GROUP BY ch.slug
    `,
    [slug]
  );
  if (chamberRows.length === 0) return null;

  const { rows: memberRows } = await pool.query(
    `
    SELECT DISTINCT ON (p.id)
      p.id                                     AS politician_id,
      p.slug                                   AS politician_slug,
      COALESCE(p.full_name, '')                AS full_name,
      COALESCE(p.preferred_name, '')           AS preferred_name,
      COALESCE(p.last_name, '')                AS last_name,
      COALESCE(o.title, '')                    AS title,
      COALESCE(ch.name, '')                    AS chamber_name,
      COALESCE(d.label, '')                    AS district_label_raw,
      COALESCE(d.district_type, '')            AS district_type,
      COALESCE(
        p.photo_custom_url,
        CASE WHEN p.photo_origin_url LIKE 'http%' THEN p.photo_origin_url END,
        (
          SELECT pi.url FROM essentials.politician_images pi
          WHERE pi.politician_id = p.id
          ORDER BY pi.id ASC LIMIT 1
        )
      )                                         AS photo_url
    FROM essentials.chambers ch
    JOIN essentials.offices o     ON o.chamber_id = ch.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    WHERE ch.slug = $1
      AND p.is_active = true
      AND o.is_vacant = false
    ORDER BY p.id
    `,
    [slug]
  );

  const members: RosterMember[] = memberRows.map((r) => ({
    politician_slug: (r.politician_slug as string | null) ?? null,
    politician_id: String(r.politician_id),
    full_name: r.full_name as string,
    preferred_name: r.preferred_name as string,
    title: r.title as string,
    chamber_name: r.chamber_name as string,
    district_label: resolveDistrictLabel(
      r.district_label_raw as string,
      r.district_type as string
    ),
    photo_url: (r.photo_url as string | null) ?? null,
  }));

  const lastNameByIdx = memberRows.map((r) => ((r.last_name as string) ?? '').toLowerCase());
  const indices = members.map((_, i) => i);
  indices.sort((a, b) => {
    const ra = titleRank(members[a].title);
    const rb = titleRank(members[b].title);
    if (ra !== rb) return ra - rb;
    const la = lastNameByIdx[a];
    const lb = lastNameByIdx[b];
    const ln = la.localeCompare(lb);
    if (ln !== 0) return ln;
    return members[a].politician_id.localeCompare(members[b].politician_id);
  });
  const sortedMembers = indices.map((i) => members[i]);

  return {
    slug: chamberRows[0].slug as string,
    name_formal: (chamberRows[0].name_formal as string) ?? '',
    state: (chamberRows[0].state as string) ?? '',
    fetched_at: new Date().toISOString(),
    members: sortedMembers,
  };
}
