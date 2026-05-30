// Phase 133 — shared politician upsert.
// Canonical idiom from import-indiana-sos-xlsx.ts:508-547.
// HARDENING vs analog (RESEARCH Pitfall 8): SAVEPOINT name uses SHA1(full_name).slice(0,8)
// to avoid collision on long-name pairs.
//
// ANTIPARTISAN: the `party` column is intentionally NOT in the INSERT/UPDATE list.
// Roster sources publish party affiliation but the platform never displays it; capture
// in audit CSV at the caller layer if needed.
import crypto from 'node:crypto';
import type { PoolClient } from 'pg';

export interface UpsertPoliticianInput {
  external_id: number;             // negative, D-07 range (-399999..-300001)
  full_name: string;
  first_name: string;
  last_name: string;
  data_source: string;             // e.g., 'ut-legislator-le-utah', 'ut-county-roster', 'ut-sboe-roster'
  photo_origin_url?: string | null; // optional: original source URL pre-rehost (audit only)
}

export interface UpsertPoliticianResult {
  id: string;                       // uuid
  inserted: boolean;
}

function savepointName(fullName: string, idx: number): string {
  const h = crypto.createHash('sha1').update(`${fullName}:${idx}`).digest('hex').slice(0, 12);
  return `sp_${h}`;
}

export async function upsertPolitician(
  client: PoolClient,
  row: UpsertPoliticianInput,
  rowIndex: number,
): Promise<UpsertPoliticianResult> {
  if (row.external_id > -300001 || row.external_id < -399999) {
    throw new Error(`upsertPolitician: external_id ${row.external_id} out of UT range`);
  }
  const sp = savepointName(row.full_name, rowIndex);
  await client.query(`SAVEPOINT ${sp}`);
  try {
    const ins = await client.query<{ id: string }>(
      `INSERT INTO essentials.politicians
         (external_id, full_name, first_name, last_name,
          is_active, is_vacant,
          data_source, photo_origin_url, last_synced)
       VALUES ($1, $2, $3, $4, true, false, $5, $6, now())
       ON CONFLICT (external_id) DO UPDATE SET
         full_name        = EXCLUDED.full_name,
         first_name       = EXCLUDED.first_name,
         last_name        = EXCLUDED.last_name,
         data_source      = EXCLUDED.data_source,
         photo_origin_url = COALESCE(EXCLUDED.photo_origin_url, essentials.politicians.photo_origin_url),
         last_synced      = now()
       RETURNING id, (xmax = 0) AS inserted`,
      [row.external_id, row.full_name, row.first_name, row.last_name, row.data_source, row.photo_origin_url ?? null],
    );
    await client.query(`RELEASE SAVEPOINT ${sp}`);
    return { id: ins.rows[0].id, inserted: Boolean((ins.rows[0] as unknown as { inserted: boolean }).inserted) };
  } catch (e) {
    await client.query(`ROLLBACK TO SAVEPOINT ${sp}`);
    throw e;
  }
}

export interface UpsertOfficeInput {
  politician_id: string;
  district_id: string;             // FK to essentials.districts.id
  title: string;                   // e.g., 'Mayor', 'Council District 1', 'State Senator District 5'
  representing_state: 'UT';
  representing_city?: string | null;
  description?: string | null;
  seats?: number;
  is_appointed_position?: boolean;
}

/**
 * essentials.offices has UNIQUE (politician_id) — one current office per politician.
 * Re-runs DELETE-then-INSERT (RESEARCH Schemas note + objective bullet from CONTEXT).
 */
export async function upsertOffice(
  client: PoolClient,
  row: UpsertOfficeInput,
): Promise<string> {
  await client.query(
    `DELETE FROM essentials.offices WHERE politician_id = $1`,
    [row.politician_id],
  );
  const ins = await client.query<{ id: string }>(
    `INSERT INTO essentials.offices
       (politician_id, district_id, title, representing_state, representing_city,
        description, seats, is_appointed_position)
     VALUES ($1, $2, $3, 'UT', $4, $5, $6, $7)
     RETURNING id`,
    [
      row.politician_id, row.district_id, row.title,
      row.representing_city ?? null, row.description ?? null,
      row.seats ?? 1, row.is_appointed_position ?? false,
    ],
  );
  // Backlink politicians.office_id for legacy code paths that read it.
  await client.query(
    `UPDATE essentials.politicians SET office_id = $1 WHERE id = $2`,
    [ins.rows[0].id, row.politician_id],
  );
  return ins.rows[0].id;
}

export interface UpsertContactInput {
  politician_id: string;
  source: string;                  // loader slug
  email?: string | null;
  phone?: string | null;
  fax?: string | null;
  website_url?: string | null;
  contact_type: 'primary' | 'office' | 'campaign' | 'personal' | 'central' | 'district' | 'city_website' | 'office_website' | 'other';
}

/**
 * D-08: contacts are fully overwritable per re-scrape.
 * DELETE all contacts for (politician_id, source) then INSERT fresh rows.
 */
export async function replaceContacts(
  client: PoolClient,
  politicianId: string,
  source: string,
  contacts: UpsertContactInput[],
): Promise<number> {
  await client.query(
    `DELETE FROM essentials.politician_contacts WHERE politician_id = $1 AND source = $2`,
    [politicianId, source],
  );
  let inserted = 0;
  for (const c of contacts) {
    if (!c.email && !c.phone && !c.fax && !c.website_url) continue;
    await client.query(
      `INSERT INTO essentials.politician_contacts
         (politician_id, source, email, phone, fax, website_url, contact_type, contact_synced_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, now())`,
      [politicianId, source, c.email ?? null, c.phone ?? null, c.fax ?? null, c.website_url ?? null, c.contact_type],
    );
    inserted++;
  }
  return inserted;
}
