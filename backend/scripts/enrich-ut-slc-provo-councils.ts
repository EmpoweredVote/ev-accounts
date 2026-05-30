#!/usr/bin/env -S npx tsx
// One-shot enrichment: contacts + photos for SLC (W1-W3,W5-W7) and Provo (W1-W5) councils.
// Sources: slc.gov/district{N}/ + provo.gov ImageRepository.
// SLC Ward 4 is VACANT (is_vacant=true) — deliberately excluded.
// Do NOT re-run load-ut-city-rosters.ts for SLC — FeatureServer is stale.
//
// Usage:
//   npx tsx scripts/enrich-ut-slc-provo-councils.ts          # dry-run (default)
//   npx tsx scripts/enrich-ut-slc-provo-councils.ts --commit  # write to DB
import 'dotenv/config';
import pg from 'pg';
import { replaceContacts } from './lib/politician-upsert.js';
import { rehostPhoto } from './lib/photo-rehost.js';

const LOG = '[slc-provo-enrich]';
const DRY_RUN = !process.argv.includes('--commit');

interface RosterEntry {
  fullName: string;
  label: string;
  email: string | null;
  phone: string | null;
  photoUrl: string | null;
}

const ROSTER: RosterEntry[] = [
  // SLC — emails from slc.gov district pages (Cloudflare data-cfemail decoded)
  { fullName: 'Victoria Petro',    label: 'SLC W1', email: 'victoria.petro@slc.gov',  phone: '801-535-7723', photoUrl: 'https://www.slc.gov/district1/wp-content/uploads/sites/30/2021/12/D1-Victoria-Petro-Eschler-3.jpg' },
  { fullName: 'Alejandro Puy',     label: 'SLC W2', email: 'alejandro.puy@slc.gov',   phone: '801-535-7781', photoUrl: 'https://www.slc.gov/district2/wp-content/uploads/sites/34/2023/01/Alejandro-Headshot-scaled.jpg' },
  { fullName: 'Chris Wharton',     label: 'SLC W3', email: 'chris.wharton@slc.gov',   phone: '801-535-7726', photoUrl: 'https://www.slc.gov/district3/wp-content/uploads/sites/35/2026/01/Salt-Lake-CIty-Council_86945-3583-Chris-Wharton-scaled.jpg' },
  // SLC Ward 4 VACANT — omitted per spec
  { fullName: 'Erika Carlsen',     label: 'SLC W5', email: 'erika.carlsen@slc.gov',   phone: '801-535-7786', photoUrl: 'https://www.slc.gov/district5/wp-content/uploads/sites/37/2026/01/Salt-Lake-City-Council_86924-2888-Erika-Carlsen-scaled.jpg' },
  { fullName: 'Dan Dugan',         label: 'SLC W6', email: 'dan.dugan@slc.gov',        phone: '801-535-7784', photoUrl: 'https://www.slc.gov/district6/wp-content/uploads/sites/38/2020/01/D6-Dan-Dugan.jpg' },
  { fullName: 'Sarah Young',       label: 'SLC W7', email: 'sarah.young@slc.gov',      phone: '801-535-7715', photoUrl: 'https://www.slc.gov/district7/wp-content/uploads/sites/39/2023/08/D7-Sarah-Young-scaled.jpg' },
  // Provo — contacts from provo.gov; photos from ImageRepository (HTTP 200, image/jpeg)
  { fullName: 'Craig Christensen', label: 'PVO W1', email: 'crchristensen@provo.gov', phone: '801-852-6128', photoUrl: 'https://www.provo.gov/ImageRepository/Document?documentID=7470' },
  { fullName: 'Jeff Whitlock',     label: 'PVO W2', email: 'jwhitlock@provo.gov',     phone: null,           photoUrl: 'https://www.provo.gov/ImageRepository/Document?documentID=8712' },
  { fullName: 'Becky Bogdin',      label: 'PVO W3', email: 'bbogdin@provo.gov',        phone: '801-852-6132', photoUrl: 'https://www.provo.gov/ImageRepository/Document?documentID=7434' },
  { fullName: 'Travis Hoban',      label: 'PVO W4', email: 'thoban@provo.gov',         phone: '801-872-8471', photoUrl: 'https://www.provo.gov/ImageRepository/Document?documentID=7422' },
  { fullName: 'Rachel Whipple',    label: 'PVO W5', email: 'rwhipple@provo.gov',       phone: '385-219-9804', photoUrl: 'https://www.provo.gov/ImageRepository/Document?documentID=7467' },
];

interface PoliticianRow {
  id: string;
  external_id: number;
  data_source: string;
}

async function lookupPolitician(client: pg.PoolClient, fullName: string): Promise<PoliticianRow | null> {
  const { rows } = await client.query<PoliticianRow>(
    `SELECT id, external_id, data_source
       FROM essentials.politicians
      WHERE TRIM(full_name) = $1
        AND data_source LIKE 'ut-city-%'
      LIMIT 1`,
    [fullName.trim()],
  );
  return rows[0] ?? null;
}

async function enrichOne(pool: pg.Pool, entry: RosterEntry): Promise<void> {
  const client = await pool.connect();
  try {
    const pol = await lookupPolitician(client, entry.fullName);
    if (!pol) {
      console.error(`${LOG} SKIP ${entry.fullName} (${entry.label}): not found (data_source LIKE 'ut-city-%')`);
      return;
    }

    if (DRY_RUN) {
      console.log(`${LOG} [dry] ${entry.fullName} (${entry.label}): id=${pol.id} source=${pol.data_source} email=${entry.email ?? 'null'} phone=${entry.phone ?? 'null'} photo=${entry.photoUrl ? 'yes' : 'null'}`);
      return;
    }

    await client.query('BEGIN');

    const contactsInserted = await replaceContacts(client, pol.id, pol.data_source, [
      { politician_id: pol.id, source: pol.data_source, email: entry.email, phone: entry.phone, contact_type: 'office' },
    ]);

    const photoUrl = await rehostPhoto(client, pol.id, pol.external_id, entry.photoUrl);

    await client.query('COMMIT');
    console.log(`${LOG} ${entry.fullName} (${entry.label}): contacts=${contactsInserted} photo=${photoUrl ? '✓' : '✗'}`);
  } catch (e) {
    await client.query('ROLLBACK');
    console.error(`${LOG} ERROR ${entry.fullName} (${entry.label}):`, (e as Error).message);
    throw e;
  } finally {
    client.release();
  }
}

async function main(): Promise<void> {
  if (DRY_RUN) console.log(`${LOG} DRY-RUN — pass --commit to write`);
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  let hadError = false;
  for (const entry of ROSTER) {
    try { await enrichOne(pool, entry); }
    catch { hadError = true; }
  }
  await pool.end();
  if (hadError) { console.error(`${LOG} Finished with errors`); process.exit(1); }
  console.log(`${LOG} Done`);
}

main().catch((e) => { console.error(`${LOG} FATAL`, e); process.exit(1); });
