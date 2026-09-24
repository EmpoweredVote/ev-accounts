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
  // From splitPersonName. NULL keeps what the row already has on a re-run, so a hand-set value survives.
  middle_initial?: string | null;
  name_suffix?: string | null;
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
      // is_incumbent is explicit: every caller loads a CURRENT roster and seats the row (upsertOffice
      // writes its office_terms row). The column default is false since CA_0188, and leaving it out
      // would hide the officeholder from address search. check:occupancy requires the column here.
      `INSERT INTO essentials.politicians
         (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
          is_active, is_vacant, is_incumbent,
          data_source, photo_origin_url, last_synced)
       VALUES ($1, $2, $3, $4, $7, $8, true, false, true, $5, $6, now())
       ON CONFLICT (external_id) DO UPDATE SET
         full_name        = EXCLUDED.full_name,
         first_name       = EXCLUDED.first_name,
         last_name        = EXCLUDED.last_name,
         middle_initial   = COALESCE(EXCLUDED.middle_initial, essentials.politicians.middle_initial),
         name_suffix      = COALESCE(EXCLUDED.name_suffix, essentials.politicians.name_suffix),
         data_source      = EXCLUDED.data_source,
         photo_origin_url = COALESCE(EXCLUDED.photo_origin_url, essentials.politicians.photo_origin_url),
         last_synced      = now()
       RETURNING id, (xmax = 0) AS inserted`,
      [row.external_id, row.full_name, row.first_name, row.last_name, row.data_source, row.photo_origin_url ?? null,
       row.middle_initial ?? null, row.name_suffix ?? null],
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
  /**
   * The date this person took the seat, if known. Supply it whenever the source gives one —
   * it is what makes future hand-offs automatic (ADR 0002). Omit ONLY when genuinely unknown;
   * the term is then recorded open-ended with start_precision 'unknown', exactly as the phase-2
   * backfill did, rather than inventing a date.
   */
  term_start?: string | null;      // 'YYYY-MM-DD'
  source?: string | null;          // provenance for the term row
}

/**
 * Create the seat and record who occupies it.
 *
 * ADR 0002: essentials.offices is a SEAT (district + chamber + title) and carries NO occupant —
 * offices.politician_id was dropped in phase 5. Occupancy is a dated row in
 * essentials.office_terms, resolved at read time via essentials.office_current_holder.
 *
 * !! An office with no office_terms row is INVISIBLE: it has no holder, so the official will not
 *    appear in Essentials, stance research, coverage or campaign finance, and nothing errors.
 *    That is why this function always writes a term, and why you should not INSERT into
 *    essentials.offices directly from a seeder. Watch essentials.offices_missing_terms for drift.
 *
 * Keeps the previous re-run semantics (one current office per politician for this UT loader) by
 * deleting whatever seat the politician currently holds before inserting the new one; office_terms
 * rows go with it via ON DELETE CASCADE.
 */
export async function upsertOffice(
  client: PoolClient,
  row: UpsertOfficeInput,
): Promise<string> {
  // Drop the seat this politician currently holds, located through office_terms rather than a
  // column on offices.
  await client.query(
    `DELETE FROM essentials.offices o
       USING essentials.office_current_holder och
      WHERE och.office_id = o.id
        AND och.politician_id = $1`,
    [row.politician_id],
  );
  const ins = await client.query<{ id: string }>(
    `INSERT INTO essentials.offices
       (district_id, title, representing_state, representing_city,
        description, seats, is_appointed_position)
     VALUES ($1, $2, 'UT', $3, $4, $5, $6)
     RETURNING id`,
    [
      row.district_id, row.title,
      row.representing_city ?? null, row.description ?? null,
      row.seats ?? 1, row.is_appointed_position ?? false,
    ],
  );
  const officeId = ins.rows[0].id;
  const source = row.source ?? 'UT loader (scripts/lib/politician-upsert.ts)';

  if (row.term_start) {
    // Dated: the sanctioned helper closes any predecessor the day before and is idempotent.
    await client.query(
      `SELECT essentials.seat_officeholder($1, $2, $3::date, $4, 'elected')`,
      [officeId, row.politician_id, row.term_start, source],
    );
  } else {
    // Undated: assert only "holds this seat now", the same shape the phase-2 backfill used.
    await client.query(
      `INSERT INTO essentials.office_terms
         (office_id, politician_id, term_start, term_end, start_precision, source)
       VALUES ($1, $2, NULL, NULL, 'unknown', $3)`,
      [officeId, row.politician_id, `${source}; start date unknown`],
    );
  }

  // Backlink politicians.office_id for legacy code paths that read it. DEPRECATED: this is another
  // point-in-time snapshot with the same flaw as the dropped column — read office_current_holder.
  await client.query(
    `UPDATE essentials.politicians SET office_id = $1 WHERE id = $2`,
    [officeId, row.politician_id],
  );
  return officeId;
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
