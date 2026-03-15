/**
 * seedData.ts — Idempotent data migration from EV-Backend repo.
 *
 * Inserts production data for the Alpha launch:
 *   1. 20 compass topics + 5 stances each (from Empowered Compass Issues and Stances Top 20.csv)
 *   2. ~45 politicians with district metadata (hardcoded office info, stance data from CSVs)
 *   3. ~1,000 politician stance values into inform.politician_answers
 *   4. ~500 politician reasoning rows into inform.politician_context
 *
 * Safe to re-run: topics and politicians check for existence before inserting.
 * Answers and context use ON CONFLICT DO NOTHING (ignoreDuplicates: true).
 *
 * Prerequisites:
 *   - Migrations 026–036 applied to production
 *   - EV-Backend repo cloned to /tmp/ev-backend
 *   - SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY set in environment
 *
 * Usage:
 *   NODE_PATH=/c/EV-Accounts/backend/node_modules npx --prefix /c/EV-Accounts/backend tsx scripts/seedData.ts
 *
 * To re-clone EV-Backend first:
 *   git clone https://github.com/EmpoweredVote/EV-Backend /tmp/ev-backend
 */

import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';

// ---------------------------------------------------------------------------
// Environment + client setup
// ---------------------------------------------------------------------------

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('[seedData] ERROR: Missing required environment variables.');
  console.error('  Required: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

// On Windows/MINGW64, /tmp maps to %LOCALAPPDATA%\Temp
// Node.js uses Windows paths, so we resolve via cygpath or use the Windows path directly.
const EV_BACKEND = process.env.EV_BACKEND_PATH ??
  'C:/Users/Chris/AppData/Local/Temp/ev-backend';

// ---------------------------------------------------------------------------
// CSV parsing
// ---------------------------------------------------------------------------

function parseCSVLine(line: string): string[] {
  const result: string[] = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    if (char === '"') {
      if (inQuotes && line[i + 1] === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char === ',' && !inQuotes) {
      result.push(current.trim());
      current = '';
    } else {
      current += char;
    }
  }
  result.push(current.trim());
  return result;
}

function parseCSV(filePath: string): Record<string, string>[] {
  const content = fs.readFileSync(filePath, 'utf8').replace(/^\uFEFF/, ''); // strip BOM
  const lines = content.replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n');
  if (lines.length === 0) return [];

  const headers = parseCSVLine(lines[0]);
  const rows: Record<string, string>[] = [];

  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;
    const values = parseCSVLine(line);
    const obj: Record<string, string> = {};
    for (let j = 0; j < headers.length; j++) {
      obj[headers[j]] = values[j] ?? '';
    }
    // Skip rows where the first field looks like metadata noise (not a person name)
    rows.push(obj);
  }

  return rows;
}

// ---------------------------------------------------------------------------
// Politician metadata — hardcoded office/district info for all politicians
// in the EV-Backend dataset, keyed by canonical full_name.
// ---------------------------------------------------------------------------

type PoliticianRecord = {
  first_name: string;
  last_name: string;
  preferred_name: string | null;
  office_title: string;
  photo_origin_url: string | null;
  is_active: boolean;
  is_candidate: boolean;
  is_vacant: boolean;
  representing_city: string | null;
  representing_state: string | null;
  district_type: string | null;
  district_label: string | null;
  district_id: string | null;
  chamber_name: string | null;
  chamber_name_formal: string | null;
  government_name: string | null;
};

// Name variants in CSVs → canonical name used in this map
const NAME_NORMALIZE: Record<string, string> = {
  'Nanette Diaz Baragán': 'Nanette Barragan',
  'Nanette Diaz Baragan': 'Nanette Barragan',
};

const POLITICIAN_METADATA: Record<string, PoliticianRecord> = {
  // -------------------------------------------------------------------------
  // Indiana politicians
  // -------------------------------------------------------------------------
  'Kerry Thomson': {
    first_name: 'Kerry',
    last_name: 'Thomson',
    preferred_name: null,
    office_title: 'Mayor, City of Bloomington',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Bloomington',
    representing_state: 'IN',
    district_type: 'local_executive',
    district_label: 'City of Bloomington',
    district_id: '18-Monroe-Bloomington',
    chamber_name: null,
    chamber_name_formal: null,
    government_name: 'City of Bloomington, Indiana',
  },
  'Mike Braun': {
    first_name: 'Mike',
    last_name: 'Braun',
    preferred_name: null,
    office_title: 'Governor of Indiana',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Indianapolis',
    representing_state: 'IN',
    district_type: 'governor',
    district_label: 'State of Indiana',
    district_id: '18-GOV',
    chamber_name: null,
    chamber_name_formal: null,
    government_name: 'State of Indiana',
  },
  'Jim Banks': {
    first_name: 'Jim',
    last_name: 'Banks',
    preferred_name: null,
    office_title: 'U.S. Senator, Indiana',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: null,
    representing_state: 'IN',
    district_type: 'senator',
    district_label: 'Indiana',
    district_id: '18-SEN',
    chamber_name: 'U.S. Senate',
    chamber_name_formal: 'United States Senate',
    government_name: 'United States Federal Government',
  },
  'Todd Young': {
    first_name: 'Todd',
    last_name: 'Young',
    preferred_name: null,
    office_title: 'U.S. Senator, Indiana',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: null,
    representing_state: 'IN',
    district_type: 'senator',
    district_label: 'Indiana',
    district_id: '18-SEN',
    chamber_name: 'U.S. Senate',
    chamber_name_formal: 'United States Senate',
    government_name: 'United States Federal Government',
  },
  'Erin Houchin': {
    first_name: 'Erin',
    last_name: 'Houchin',
    preferred_name: null,
    office_title: 'U.S. Representative, Indiana 9th Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: null,
    representing_state: 'IN',
    district_type: 'congressional',
    district_label: 'Indiana 9th Congressional District',
    district_id: '18-09',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Micah Beckwith': {
    first_name: 'Micah',
    last_name: 'Beckwith',
    preferred_name: null,
    office_title: 'Lieutenant Governor of Indiana',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: null,
    representing_state: 'IN',
    district_type: 'lt_governor',
    district_label: 'State of Indiana',
    district_id: '18-LT-GOV',
    chamber_name: null,
    chamber_name_formal: null,
    government_name: 'State of Indiana',
  },

  // -------------------------------------------------------------------------
  // California / Los Angeles politicians
  // -------------------------------------------------------------------------
  'Gavin Newsom': {
    first_name: 'Gavin',
    last_name: 'Newsom',
    preferred_name: null,
    office_title: 'Governor of California',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Sacramento',
    representing_state: 'CA',
    district_type: 'governor',
    district_label: 'State of California',
    district_id: '06-GOV',
    chamber_name: null,
    chamber_name_formal: null,
    government_name: 'State of California',
  },
  'Karen Bass': {
    first_name: 'Karen',
    last_name: 'Bass',
    preferred_name: null,
    office_title: 'Mayor, City of Los Angeles',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Los Angeles',
    representing_state: 'CA',
    district_type: 'mayor',
    district_label: 'City of Los Angeles',
    district_id: '06-037',
    chamber_name: null,
    chamber_name_formal: null,
    government_name: 'City of Los Angeles',
  },
  'Eleni Kounalakis': {
    first_name: 'Eleni',
    last_name: 'Kounalakis',
    preferred_name: null,
    office_title: 'Lieutenant Governor of California',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: null,
    representing_state: 'CA',
    district_type: 'lt_governor',
    district_label: 'State of California',
    district_id: '06-LT-GOV',
    chamber_name: null,
    chamber_name_formal: null,
    government_name: 'State of California',
  },
  'Adam Schiff': {
    first_name: 'Adam',
    last_name: 'Schiff',
    preferred_name: null,
    office_title: 'U.S. Senator, California',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: null,
    representing_state: 'CA',
    district_type: 'senator',
    district_label: 'California',
    district_id: '06-SEN',
    chamber_name: 'U.S. Senate',
    chamber_name_formal: 'United States Senate',
    government_name: 'United States Federal Government',
  },
  'Alex Padilla': {
    first_name: 'Alex',
    last_name: 'Padilla',
    preferred_name: null,
    office_title: 'U.S. Senator, California',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: null,
    representing_state: 'CA',
    district_type: 'senator',
    district_label: 'California',
    district_id: '06-SEN',
    chamber_name: 'U.S. Senate',
    chamber_name_formal: 'United States Senate',
    government_name: 'United States Federal Government',
  },
  'Judy Chu': {
    first_name: 'Judy',
    last_name: 'Chu',
    preferred_name: null,
    office_title: 'U.S. Representative, California 28th Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Pasadena',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 28th Congressional District',
    district_id: '06-28',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Brad Sherman': {
    first_name: 'Brad',
    last_name: 'Sherman',
    preferred_name: null,
    office_title: 'U.S. Representative, California 32nd Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Sherman Oaks',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 32nd Congressional District',
    district_id: '06-32',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Nanette Barragan': {
    first_name: 'Nanette',
    last_name: 'Barragan',
    preferred_name: null,
    office_title: 'U.S. Representative, California 44th Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Compton',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 44th Congressional District',
    district_id: '06-44',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Ted Lieu': {
    first_name: 'Ted',
    last_name: 'Lieu',
    preferred_name: null,
    office_title: 'U.S. Representative, California 36th Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Torrance',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 36th Congressional District',
    district_id: '06-36',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Sydney Kamlager-Dove': {
    first_name: 'Sydney',
    last_name: 'Kamlager-Dove',
    preferred_name: null,
    office_title: 'U.S. Representative, California 37th Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Los Angeles',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 37th Congressional District',
    district_id: '06-37',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Maxine Waters': {
    first_name: 'Maxine',
    last_name: 'Waters',
    preferred_name: null,
    office_title: 'U.S. Representative, California 43rd Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Inglewood',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 43rd Congressional District',
    district_id: '06-43',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Jimmy Gomez': {
    first_name: 'Jimmy',
    last_name: 'Gomez',
    preferred_name: null,
    office_title: 'U.S. Representative, California 34th Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Los Angeles',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 34th Congressional District',
    district_id: '06-34',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Linda Sanchez': {
    first_name: 'Linda',
    last_name: 'Sanchez',
    preferred_name: null,
    office_title: 'U.S. Representative, California 38th Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Whittier',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 38th Congressional District',
    district_id: '06-38',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Norma Torres': {
    first_name: 'Norma',
    last_name: 'Torres',
    preferred_name: null,
    office_title: 'U.S. Representative, California 35th Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Pomona',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 35th Congressional District',
    district_id: '06-35',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Jay Obernolte': {
    first_name: 'Jay',
    last_name: 'Obernolte',
    preferred_name: null,
    office_title: 'U.S. Representative, California 23rd Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Big Bear Lake',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 23rd Congressional District',
    district_id: '06-23',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Laura Friedman': {
    first_name: 'Laura',
    last_name: 'Friedman',
    preferred_name: null,
    office_title: 'U.S. Representative, California 30th Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Burbank',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 30th Congressional District',
    district_id: '06-30',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Luz Rivas': {
    first_name: 'Luz',
    last_name: 'Rivas',
    preferred_name: null,
    office_title: 'California State Assemblymember, District 53',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Arleta',
    representing_state: 'CA',
    district_type: 'state_house',
    district_label: 'California Assembly District 53',
    district_id: '06-053',
    chamber_name: 'California Assembly',
    chamber_name_formal: 'California State Assembly',
    government_name: 'State of California',
  },
  'Robert Garcia': {
    first_name: 'Robert',
    last_name: 'Garcia',
    preferred_name: null,
    office_title: 'U.S. Representative, California 42nd Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Long Beach',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 42nd Congressional District',
    district_id: '06-42',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Derek Tran': {
    first_name: 'Derek',
    last_name: 'Tran',
    preferred_name: null,
    office_title: 'U.S. Representative, California 45th Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Garden Grove',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 45th Congressional District',
    district_id: '06-45',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'George Whitesides': {
    first_name: 'George',
    last_name: 'Whitesides',
    preferred_name: null,
    office_title: 'U.S. Representative, California 27th Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Santa Clarita',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 27th Congressional District',
    district_id: '06-27',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Julia Brownley': {
    first_name: 'Julia',
    last_name: 'Brownley',
    preferred_name: null,
    office_title: 'Former U.S. Representative, California 26th Congressional District',
    photo_origin_url: null,
    is_active: false, // retired January 2025
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Oxnard',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 26th Congressional District',
    district_id: '06-26',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Gilbert Cisneros': {
    first_name: 'Gilbert',
    last_name: 'Cisneros',
    preferred_name: null,
    office_title: 'Former U.S. Representative, California 39th Congressional District',
    photo_origin_url: null,
    is_active: false, // lost reelection 2020
    is_candidate: false,
    is_vacant: false,
    representing_city: null,
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 39th Congressional District',
    district_id: '06-39',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Pete Aguilar': {
    first_name: 'Pete',
    last_name: 'Aguilar',
    preferred_name: null,
    office_title: 'U.S. Representative, California 33rd Congressional District',
    photo_origin_url: null,
    is_active: true,
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Redlands',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 33rd Congressional District',
    district_id: '06-33',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
  'Tony Cardenas': {
    first_name: 'Tony',
    last_name: 'Cardenas',
    preferred_name: null,
    office_title: 'Former U.S. Representative, California 29th Congressional District',
    photo_origin_url: null,
    is_active: false, // retired January 2025
    is_candidate: false,
    is_vacant: false,
    representing_city: 'Pacoima',
    representing_state: 'CA',
    district_type: 'congressional',
    district_label: 'California 29th Congressional District',
    district_id: '06-29',
    chamber_name: 'U.S. House',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'United States Federal Government',
  },
};

// ---------------------------------------------------------------------------
// Step 1: Seed compass topics
// ---------------------------------------------------------------------------

async function seedTopics(): Promise<Map<string, string>> {
  console.log('\n[seedData] Step 1: Seeding compass topics...');

  const csvPath = path.join(EV_BACKEND, 'Empowered Compass Issues and Stances Top 20.csv');
  if (!fs.existsSync(csvPath)) {
    console.error(`[seedData] ERROR: Topics CSV not found at ${csvPath}`);
    console.error('  Clone EV-Backend: git clone https://github.com/EmpoweredVote/EV-Backend /tmp/ev-backend');
    process.exit(1);
  }

  const rows = parseCSV(csvPath);
  console.log(`[seedData] Found ${rows.length} topics in CSV`);

  // Load existing topics to skip duplicates
  const { data: existingTopics, error: fetchErr } = await supabase
    .schema('inform')
    .from('compass_topics')
    .select('id, title, short_title');

  if (fetchErr) {
    console.error('[seedData] ERROR fetching existing topics:', fetchErr.message);
    process.exit(1);
  }

  const existingByTitle = new Map<string, string>(
    (existingTopics ?? []).map((t) => [t.title, t.id])
  );
  const existingByShortTitle = new Map<string, string>(
    (existingTopics ?? []).map((t) => [t.short_title, t.id])
  );

  // topicKey → topic UUID (for later use in answers/context seeding)
  const topicKeyToId = new Map<string, string>();

  let inserted = 0;
  let skipped = 0;

  for (const row of rows) {
    const topicKey = row['topic_key'];
    const title = row['title'];
    const shortTitle = row['short_title'];
    const questionText = row['start_phrase'];

    if (!topicKey || !title || !questionText) {
      console.warn(`[seedData]   SKIP malformed row: ${JSON.stringify(row)}`);
      continue;
    }

    // Idempotency: check by title first, then short_title
    const existingId = existingByTitle.get(title) ?? existingByShortTitle.get(shortTitle);
    if (existingId) {
      console.log(`[seedData]   SKIP (exists) ${topicKey}: ${shortTitle}`);
      topicKeyToId.set(topicKey, existingId);
      skipped++;
      continue;
    }

    // Build stances array from stance_1..5 columns
    const stances = [];
    for (let i = 1; i <= 5; i++) {
      const text = row[`stance_${i}`];
      if (text) stances.push({ value: i, text });
    }

    const { data, error } = await supabase.rpc('admin_create_topic_with_stances', {
      p_title: title,
      p_question_text: questionText,
      p_short_title: shortTitle || null,
      p_is_live: true,
      p_stances: stances,
    });

    if (error) {
      console.error(`[seedData]   ERROR inserting topic ${topicKey}:`, error.message);
      continue;
    }

    const topicId = (data as { topic: { id: string } }).topic.id;
    topicKeyToId.set(topicKey, topicId);
    console.log(`[seedData]   INSERTED ${topicKey}: ${shortTitle} (${stances.length} stances)`);
    inserted++;
  }

  // Also populate from existing topics we skipped (they weren't in topicKeyToId yet if we matched by title)
  // Re-map any topics already in DB that matched by title but whose topicKey we know
  for (const row of rows) {
    const topicKey = row['topic_key'];
    if (topicKey && !topicKeyToId.has(topicKey)) {
      const existingId = existingByTitle.get(row['title']);
      if (existingId) topicKeyToId.set(topicKey, existingId);
    }
  }

  console.log(`[seedData] Topics: ${inserted} inserted, ${skipped} skipped (already existed)`);
  console.log(`[seedData] Topic key map: ${topicKeyToId.size} entries`);
  return topicKeyToId;
}

// ---------------------------------------------------------------------------
// Step 2: Seed politicians
// ---------------------------------------------------------------------------

async function seedPoliticians(): Promise<Map<string, string>> {
  console.log('\n[seedData] Step 2: Seeding politicians...');

  // Load existing politicians (by first_name + last_name)
  const { data: existing, error: fetchErr } = await supabase
    .schema('inform')
    .from('politicians')
    .select('id, first_name, last_name');

  if (fetchErr) {
    console.error('[seedData] ERROR fetching existing politicians:', fetchErr.message);
    process.exit(1);
  }

  const existingByName = new Map<string, string>(
    (existing ?? []).map((p) => [`${p.first_name} ${p.last_name}`, p.id])
  );

  const nameToId = new Map<string, string>();

  // Populate map with already-existing politicians first
  for (const [fullName, id] of existingByName) {
    nameToId.set(fullName, id);
  }

  let inserted = 0;
  let skipped = 0;

  for (const [fullName, meta] of Object.entries(POLITICIAN_METADATA)) {
    const existing = existingByName.get(fullName);
    if (existing) {
      console.log(`[seedData]   SKIP (exists) ${fullName}`);
      nameToId.set(fullName, existing);
      skipped++;
      continue;
    }

    const { data, error } = await supabase
      .schema('inform')
      .from('politicians')
      .insert(meta)
      .select('id')
      .single();

    if (error) {
      console.error(`[seedData]   ERROR inserting ${fullName}:`, error.message);
      continue;
    }

    nameToId.set(fullName, data.id);
    // Also add name variants
    NAME_NORMALIZE[fullName] && nameToId.set(fullName, data.id);
    console.log(`[seedData]   INSERTED ${fullName} (${meta.office_title})`);
    inserted++;
  }

  // Resolve name variants into the map
  for (const [variant, canonical] of Object.entries(NAME_NORMALIZE)) {
    const id = nameToId.get(canonical);
    if (id) nameToId.set(variant, id);
  }

  console.log(`[seedData] Politicians: ${inserted} inserted, ${skipped} skipped`);
  return nameToId;
}

// ---------------------------------------------------------------------------
// Step 3: Seed politician answers from all stance CSVs
// ---------------------------------------------------------------------------

// Known noise rows in reasoning CSVs (not actual politicians)
const NOISE_NAMES = new Set([
  'Adelanto Detention Center', 'Artificial Intelligence', 'As CBC Whip',
  'Assembly Natural Resources Committee', 'Border Act', 'California Assemblyman',
  'Congressional LGBT Equality Caucus', 'County Central Committees', 'Equality Act',
  'Honest Ads Act', 'In California', 'Inclusivity Act', 'Intellectual Property',
  'Medicare Dental', 'Means Trade Subcommittee Ranking Member', 'One Big Beautiful Bill',
  'People Act', 'Results Act', 'Sacramento County', 'Strength Act',
  'Ukraine Supplemental', 'Voting Rights Advancement Act',
]);

function normalizeName(name: string): string {
  return NAME_NORMALIZE[name] ?? name;
}

async function seedPoliticianAnswers(
  topicKeyToId: Map<string, string>,
  nameToId: Map<string, string>
): Promise<void> {
  console.log('\n[seedData] Step 3: Seeding politician answers...');

  const stanceFiles = [
    path.join(EV_BACKEND, 'data', 'stance_research.csv'),
    path.join(EV_BACKEND, 'data', 'ChuBassBarraganBrownlet.csv'),
    path.join(EV_BACKEND, 'data', 'CisnerosFriedmanGarciaGomez.csv'),
    path.join(EV_BACKEND, 'data', 'Kamlager-DoveLieuObernolteRivas.csv'),
    path.join(EV_BACKEND, 'data', 'NewsomeBraunSchiffPadilla.csv'),
    path.join(EV_BACKEND, 'data', 'SanchezShermanTorres.csv'),
    path.join(EV_BACKEND, 'data', 'ThomsonBanksYoungHouchin.csv'),
    path.join(EV_BACKEND, 'data', 'WatersTranWhitesides.csv'),
  ];

  // De-duplicate answers across files — use map: `politicianId:topicId` → value
  const answerMap = new Map<string, { politician_id: string; topic_id: string; value: number }>();

  let skippedUnknownPolitician = 0;
  let skippedUnknownTopic = 0;
  let skippedInvalidValue = 0;

  for (const filePath of stanceFiles) {
    if (!fs.existsSync(filePath)) {
      console.warn(`[seedData]   SKIP missing file: ${filePath}`);
      continue;
    }

    const rows = parseCSV(filePath);
    const fileName = path.basename(filePath);

    for (const row of rows) {
      const rawName = row['full_name']?.trim();
      const topicKey = row['topic_key']?.trim();
      const rawValue = row['value']?.trim();

      if (!rawName || !topicKey || !rawValue) continue;
      if (NOISE_NAMES.has(rawName)) continue;

      const fullName = normalizeName(rawName);
      const politicianId = nameToId.get(fullName);
      if (!politicianId) {
        skippedUnknownPolitician++;
        continue;
      }

      const topicId = topicKeyToId.get(topicKey);
      if (!topicId) {
        skippedUnknownTopic++;
        continue;
      }

      const value = parseInt(rawValue, 10);
      if (isNaN(value) || value < 1 || value > 5) {
        skippedInvalidValue++;
        continue;
      }

      const key = `${politicianId}:${topicId}`;
      // Reasoning CSVs take priority over stance_research.csv (processed after)
      if (!answerMap.has(key) || fileName !== 'stance_research.csv') {
        answerMap.set(key, { politician_id: politicianId, topic_id: topicId, value });
      }
    }
  }

  const answers = [...answerMap.values()];
  console.log(`[seedData] Collected ${answers.length} unique answers to insert`);
  console.log(`[seedData]   Skipped: ${skippedUnknownPolitician} unknown politician, ${skippedUnknownTopic} unknown topic, ${skippedInvalidValue} invalid value`);

  if (answers.length === 0) {
    console.log('[seedData] No answers to insert.');
    return;
  }

  // Batch insert in chunks of 100 with ON CONFLICT DO NOTHING
  const CHUNK = 100;
  let totalInserted = 0;
  for (let i = 0; i < answers.length; i += CHUNK) {
    const chunk = answers.slice(i, i + CHUNK);
    const { error } = await supabase
      .schema('inform')
      .from('politician_answers')
      .upsert(chunk, { ignoreDuplicates: true });

    if (error) {
      console.error(`[seedData]   ERROR inserting answers chunk ${i}–${i + CHUNK}:`, error.message);
    } else {
      totalInserted += chunk.length;
    }
  }

  console.log(`[seedData] Answers: ${totalInserted} rows upserted (duplicates ignored)`);
}

// ---------------------------------------------------------------------------
// Step 4: Seed politician context (reasoning + sources) from reasoning CSVs
// ---------------------------------------------------------------------------

async function seedPoliticianContext(
  topicKeyToId: Map<string, string>,
  nameToId: Map<string, string>
): Promise<void> {
  console.log('\n[seedData] Step 4: Seeding politician context (reasoning)...');

  const reasoningFiles = [
    path.join(EV_BACKEND, 'data', 'ChuBassBarraganBrownlet.csv'),
    path.join(EV_BACKEND, 'data', 'CisnerosFriedmanGarciaGomez.csv'),
    path.join(EV_BACKEND, 'data', 'Kamlager-DoveLieuObernolteRivas.csv'),
    path.join(EV_BACKEND, 'data', 'NewsomeBraunSchiffPadilla.csv'),
    path.join(EV_BACKEND, 'data', 'SanchezShermanTorres.csv'),
    path.join(EV_BACKEND, 'data', 'ThomsonBanksYoungHouchin.csv'),
    path.join(EV_BACKEND, 'data', 'WatersTranWhitesides.csv'),
  ];

  // De-duplicate context rows by politicianId:topicId
  const contextMap = new Map<string, { politician_id: string; topic_id: string; reasoning: string; sources: string[] }>();

  let skippedNoReasoning = 0;
  let skippedUnknown = 0;

  for (const filePath of reasoningFiles) {
    if (!fs.existsSync(filePath)) {
      console.warn(`[seedData]   SKIP missing file: ${filePath}`);
      continue;
    }

    const rows = parseCSV(filePath);

    for (const row of rows) {
      const rawName = row['full_name']?.trim();
      const topicKey = row['topic_key']?.trim();
      const reasoning = row['reasoning']?.trim();

      if (!rawName || !topicKey) continue;
      if (NOISE_NAMES.has(rawName)) continue;
      if (!reasoning) {
        skippedNoReasoning++;
        continue;
      }

      const fullName = normalizeName(rawName);
      const politicianId = nameToId.get(fullName);
      if (!politicianId) {
        skippedUnknown++;
        continue;
      }

      const topicId = topicKeyToId.get(topicKey);
      if (!topicId) {
        skippedUnknown++;
        continue;
      }

      // Collect non-empty source URLs
      const sources: string[] = [];
      for (let i = 1; i <= 3; i++) {
        const url = row[`source_url_${i}`]?.trim();
        if (url) sources.push(url);
      }

      const key = `${politicianId}:${topicId}`;
      if (!contextMap.has(key)) {
        contextMap.set(key, { politician_id: politicianId, topic_id: topicId, reasoning, sources });
      }
    }
  }

  const contextRows = [...contextMap.values()];
  console.log(`[seedData] Collected ${contextRows.length} unique context rows to insert`);
  console.log(`[seedData]   Skipped: ${skippedNoReasoning} no reasoning, ${skippedUnknown} unknown politician/topic`);

  if (contextRows.length === 0) {
    console.log('[seedData] No context rows to insert.');
    return;
  }

  // Batch insert in chunks of 50 with ON CONFLICT DO NOTHING
  const CHUNK = 50;
  let totalInserted = 0;
  for (let i = 0; i < contextRows.length; i += CHUNK) {
    const chunk = contextRows.slice(i, i + CHUNK);
    const { error } = await supabase
      .schema('inform')
      .from('politician_context')
      .upsert(chunk, { ignoreDuplicates: true });

    if (error) {
      console.error(`[seedData]   ERROR inserting context chunk ${i}–${i + CHUNK}:`, error.message);
    } else {
      totalInserted += chunk.length;
    }
  }

  console.log(`[seedData] Context: ${totalInserted} rows upserted (duplicates ignored)`);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  console.log('[seedData] Starting EV-Backend data migration...');
  console.log(`[seedData] EV-Backend path: ${EV_BACKEND}`);
  console.log(`[seedData] Supabase URL: ${SUPABASE_URL}`);

  if (!fs.existsSync(EV_BACKEND)) {
    console.error(`[seedData] ERROR: EV-Backend not found at ${EV_BACKEND}`);
    console.error('  Clone it first into %LOCALAPPDATA%\\Temp:');
    console.error('    git clone https://github.com/EmpoweredVote/EV-Backend /tmp/ev-backend');
    console.error('  Or set EV_BACKEND_PATH=<path> to override.');
    process.exit(1);
  }

  const topicKeyToId = await seedTopics();
  const nameToId = await seedPoliticians();

  await seedPoliticianAnswers(topicKeyToId, nameToId);
  await seedPoliticianContext(topicKeyToId, nameToId);

  console.log('\n[seedData] Done.');
  process.exit(0);
}

main().catch((err: unknown) => {
  console.error('[seedData] Unexpected error:', err);
  process.exit(1);
});
