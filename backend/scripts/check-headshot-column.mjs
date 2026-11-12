#!/usr/bin/env node
/**
 * check-headshot-column — an imported headshot is NOT finished when its
 * `politician_images` row is inserted. `politicians.photo_custom_url` must also carry that
 * same CDN url, and this check is the thing that says so out loud.
 *
 * THE FAILURE THIS WATCHES, AND IT IS THE QUIET KIND. check-headshot-faces.py resolves the
 * image it judges as:
 *
 *     NULLIF(COALESCE(p.photo_custom_url, p.photo_origin_url), '') LIKE
 *       '%supabase.co/storage/v1/object/public/%'
 *
 * so a politician whose `politician_images` row exists while `photo_custom_url` is NULL
 * falls into one of two holes, depending on what `photo_origin_url` happens to hold:
 *
 *   1. origin is the SOURCE PAGE (the normal case — origin is provenance, not a render
 *      target). That url is off our storage, so the NIGHTLY off-site scope (`NOT LIKE
 *      OURS`) selects it, fetches an HTML document, cannot decode it, and reports
 *      `UNDECODABLE` against a perfectly good portrait — while the Sunday full-corpus
 *      sweep, which is the one that would actually look at the face, never sees it at all.
 *      Noisy and wrong in both directions, but at least the noise is visible.
 *   2. origin is ALSO NULL. `NULLIF(COALESCE(…), '')` is then NULL, and `NULL LIKE
 *      anything` is NULL rather than false, so the row matches NEITHER scope — not the
 *      full corpus, not the off-site complement. It is never selected and never judged.
 *      Nothing goes red. Nothing is skipped-with-a-reason. A published photograph simply
 *      is not looked at by anything, for as long as nobody notices.
 *
 * Hole 2 is why this file exists. Hole 1 announces itself every nightly run; hole 2 is
 * indistinguishable from a healthy database unless something asks this question directly.
 *
 * 📏 MEASURED 2026-11-12, the day the class was closed: 9,459 active politicians hold an
 * image row, and after the repair ALL 9,459 set `photo_custom_url`, every one of them on
 * our own storage path — 0 NULL, 0 off-CDN. 34 rows had to be fixed to get there:
 *   * 14 in hole 1 — 8 Santa Cruz, 5 Corte Madera, Marin Sheriff Scardina. These had been
 *     false-flagging `UNDECODABLE` on every run since they landed.
 *   * 20 in hole 2 — the Anchorage cohort (Municipality Assembly + Mayor, School District
 *     board), which recorded provenance inside a long descriptive `photo_license` string
 *     and left BOTH url columns NULL. They shipped 2026-10-27 and had been face-checked by
 *     nothing at all for 16 days when this was found by hand.
 * Recording provenance in `photo_license` instead of `photo_origin_url` is fine. Leaving
 * `photo_custom_url` NULL is not, and that is the whole rule.
 *
 * THE PREDICATE. A politician is an offender when all of:
 *   1. `is_active = true`                 — see the note on latent rows below;
 *   2. a `politician_images` row exists   — there IS a published photograph to check;
 *   3. `photo_custom_url` is NULL/empty, OR it is set but does NOT sit on our storage
 *      path — a hotlink can change or vanish with no commit, and the face gate's default
 *      scope (`OURS`) skips it, so an off-CDN value satisfies the column without
 *      delivering what the column is for.
 *
 * ◐ INACTIVE ROWS ARE REPORTED, NOT FAILED — the `check-chamberless-orphans` convention.
 * The face gate sweeps `is_active = true` only, so an inactive politician's blank column
 * is dropping nothing today; it becomes hole 2 the moment anybody reactivates them. 124
 * inactive politicians hold an image row as of 2026-11-12 and all 124 set the column, so
 * the number printed should stay 0 — if it starts climbing, an importer has regressed and
 * you will see it here before a reactivation turns it into a real blind spot.
 *
 * 🔴 POSITIVE CONTROL, MANUFACTURED — the project's rule for any detector whose healthy
 * answer is "nothing found". A clean database holds zero offenders, so there is no
 * standing example to lean on the way check-rls-coverage leans on spatial_ref_sys. Inside
 * a transaction that is ALWAYS rolled back, this script plants ONE OF EACH KIND on two
 * different real politicians — one NULL column, one off-CDN column — and re-runs the
 * detector. BOTH must come back, each under its own reason. One plant would not do: the
 * two halves of condition 3 are separate SQL, and a typo in either could leave that half
 * matching nothing while the other half kept the check looking alive. If a plant is not
 * seen the check ERRORS (exit 2) rather than passing, because an empty result would then
 * be saying nothing. This script cannot write: the rollback is unconditional.
 *
 * 🔴 `OURS` BELOW IS A COPY OF check-headshot-faces.py's CONSTANT OF THE SAME NAME, and
 * the two must stay in step — this check is only meaningful if it tests the same scope the
 * face gate selects on. Our storage answers to TWO hostnames (`<ref>.storage.supabase.co`
 * and `<ref>.supabase.co`; the Santa Cruz and Anchorage cohorts use one each, and both
 * serve), so the match is on the storage PATH they share, NEVER on a hostname. Matching
 * one hostname is what once called 1,279 of our own files "hotlinked to an outside host".
 *
 * Live-DB check, so like check-chamberless-orphans and check-rls-coverage it runs on the
 * SCHEDULE, not on push/PR: a commit applies no migration here, and an import writes to
 * prod from a session rather than from a merge. It SKIPS itself green without DATABASE_URL
 * (forks / manual runs with no secret).
 *
 * Exit 0 = every published photograph is reachable by the face gate (or skipped).
 * Exit 1 = at least one is not. Exit 2 = error, including a blind detector.
 *
 * ⚠ `--selftest` RENDERS THE FAILURE MESSAGE WITHOUT A DATABASE. The green path runs every
 * night; the red path would otherwise first execute on the day something is actually wrong,
 * which is the worst moment to discover that a row shape throws on a null field. It feeds
 * one synthetic offender of each shape through the same reporting code and exits 0. It
 * touches no database and proves nothing about prod — it is a test of the MESSAGE.
 *
 * Usage:
 *   node scripts/check-headshot-column.mjs
 *   node scripts/check-headshot-column.mjs --verbose    # also list the inactive ones
 *   node scripts/check-headshot-column.mjs --selftest   # render the FAIL output, no DB
 */
import 'dotenv/config';
import { Pool } from 'pg';

const VERBOSE = process.argv.includes('--verbose');
const SELFTEST = process.argv.includes('--selftest');

/** 🔴 Keep identical to OURS in scripts/check-headshot-faces.py. PATH, not hostname. */
const OURS = '%supabase.co/storage/v1/object/public/%';

/**
 * The detector. `active` decides fail vs latent; everything else is identical, which is
 * what lets the latent count be trusted as the same question asked of a different cohort.
 *
 * `gate_sees` is reported rather than used: it is the difference between hole 1 and hole 2
 * above, and the operator wants to know which one they are looking at. It is NOT part of
 * the predicate — a row rescued by `photo_origin_url` pointing at the CDN is still
 * off-contract, because origin is provenance and is free to go back to being a page.
 */
const DETECT_SQL = `
  SELECT p.id,
         p.full_name,
         NULLIF(p.photo_custom_url, '') AS custom_url,
         NULLIF(p.photo_origin_url, '') AS origin_url,
         CASE WHEN NULLIF(p.photo_custom_url, '') IS NULL THEN 'NULL' ELSE 'OFF_CDN' END AS reason,
         (NULLIF(COALESCE(p.photo_custom_url, p.photo_origin_url), '') LIKE $2) AS gate_sees,
         (SELECT pi.url
            FROM essentials.politician_images pi
           WHERE pi.politician_id = p.id
           ORDER BY (pi.type = 'default') DESC, pi.id
           LIMIT 1) AS image_url
    FROM essentials.politicians p
   WHERE p.is_active = $1
     AND EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id)
     AND (NULLIF(p.photo_custom_url, '') IS NULL
          OR p.photo_custom_url NOT LIKE $2)
   ORDER BY p.full_name, p.id`;

/** The corpus this check claims to have swept. An empty one is not a clean database. */
const CORPUS_SQL = `
  SELECT count(*)::int AS n
    FROM essentials.politicians p
   WHERE p.is_active = $1
     AND EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id)`;

/**
 * Two DIFFERENT healthy politicians to plant on — one per reason. Ordered by id so the
 * pick is deterministic run to run, which matters only for reading the error when a plant
 * is not seen.
 */
const CONTROL_PICK_SQL = `
  SELECT p.id, p.full_name
    FROM essentials.politicians p
   WHERE p.is_active = true
     AND p.photo_custom_url LIKE $1
     AND EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id)
   ORDER BY p.id
   LIMIT 2`;

/**
 * A value that is unmistakably not ours, for the OFF_CDN plant. `.invalid` is reserved by
 * RFC 2606 and can never resolve, so even if a rollback somehow failed this could not
 * quietly serve a real picture of someone else.
 */
const PLANTED_OFF_CDN = 'https://control.invalid/check-headshot-column-positive-control.jpg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

/**
 * What this particular offender costs, which depends on BOTH columns and on which of the
 * face gate's two scopes ends up selecting it. The gate runs the full corpus
 * (`COALESCE(custom, origin) LIKE OURS`) on Sundays and the off-site complement
 * (`NOT LIKE OURS`) every night, so a row is invisible only when it matches NEITHER — and
 * that needs both columns empty, because `NULLIF(…) LIKE anything` is NULL, not false.
 */
function consequenceOf(r) {
  if (r.gate_sees) {
    return 'the Sunday full-corpus sweep judges photo_origin_url here — it is checking the SOURCE mirror, '
         + 'not the column, and origin is free to go back to being a page';
  }
  if (!r.custom_url && !r.origin_url) {
    return 'NOT FACE-CHECKED BY ANYTHING: both url columns are empty, so this row matches neither the '
         + 'full-corpus scope nor the nightly off-site one — it is not selected, not skipped, not reported';
  }
  if (!r.custom_url) {
    return 'FALSE-FLAGGED NIGHTLY: the off-site sweep selects photo_origin_url, fetches an HTML page and '
         + 'reports UNDECODABLE against a perfectly good portrait. The Sunday sweep never sees it';
  }
  return 'judged nightly as somebody else\'s hotlink: it can change or vanish with no commit of ours, and '
       + 'the Sunday full-corpus sweep never sees it';
}

/** One offender, printed so the fix is obvious from the log alone. */
function describe(r) {
  const consequence = consequenceOf(r);
  return [
    `  ${r.full_name}  [${r.reason}]`,
    `      politician  ${r.id}`,
    `      image row   ${r.image_url ?? '(none readable)'}`,
    `      custom_url  ${r.custom_url ?? 'NULL'}`,
    `      origin_url  ${r.origin_url ?? 'NULL'}`,
    `      → ${consequence}`,
  ].join('\n');
}

/** The red path's whole output, so `--selftest` renders exactly what a real failure would. */
function failMessage(offenders, corpus, latentNote) {
  const invisible = offenders.filter((r) => !r.gate_sees && !r.custom_url && !r.origin_url).length;
  return (
    `FAIL: ${offenders.length} of ${corpus} active politicians publish a photograph whose\n` +
    `photo_custom_url does not point at it — ${invisible} of them checked by NOTHING at all:\n` +
    `${offenders.map(describe).join('\n')}\n\n` +
    'FIX: set photo_custom_url to the CDN url the politician_images row already holds — and fetch\n' +
    'that url first to confirm it is a real image, so nothing broken is promoted into the canonical\n' +
    'profile column. Do NOT fix this by deleting the image row, and do NOT fix it by pointing\n' +
    'photo_origin_url at the image: origin is PROVENANCE (the page the photo came from) and the\n' +
    'face gate only falls back to it, which is the brittle path this check exists to end.\n' +
    `  (${latentNote}.)`
  );
}

/**
 * One synthetic row per shape the reporter has to survive: the Anchorage hole (both columns
 * NULL, seen by nothing), the Santa Cruz hole (column NULL, origin is a page the gate then
 * false-flags), and a hotlink that satisfies the column without being ours.
 */
const SELFTEST_ROWS = [
  {
    id: '00000000-0000-0000-0000-00000000anch', full_name: 'Synthetic Anchorage Row',
    custom_url: null, origin_url: null, reason: 'NULL', gate_sees: false,
    image_url: 'https://ref.supabase.co/storage/v1/object/public/politician_photos/x-headshot.jpg',
  },
  {
    id: '00000000-0000-0000-0000-0000000scruz', full_name: 'Synthetic Santa Cruz Row',
    custom_url: null, origin_url: 'https://example.gov/council/members/someone', reason: 'NULL', gate_sees: false,
    image_url: 'https://ref.storage.supabase.co/storage/v1/object/public/politician_photos/y-headshot.jpg',
  },
  {
    id: '00000000-0000-0000-0000-00000hotlink', full_name: 'Synthetic Hotlinked Row',
    custom_url: 'https://someone-elses-host.example/portrait.jpg', origin_url: null, reason: 'OFF_CDN', gate_sees: false,
    image_url: null,
  },
];

(async () => {
  if (SELFTEST) {
    console.log('--selftest: no database touched. This is what the red path prints.\n');
    console.log(failMessage(SELFTEST_ROWS, 9459, '◐ 1 INACTIVE politician(s) with an image row and no usable column'));
    process.exit(0);
  }

  if (!process.env.DATABASE_URL) {
    console.log('SKIP: DATABASE_URL not set — this check needs a live database.');
    process.exit(0);
  }

  const client = await pool.connect();
  let offenders = [];
  let latent = [];
  let corpus = 0;
  let picks = [];
  let sawNull = false;
  let sawOffCdn = false;

  try {
    // One transaction, ALWAYS rolled back, because the positive control has to write in
    // order to exist. Nothing below this line can reach prod.
    await client.query('BEGIN');

    corpus = (await client.query(CORPUS_SQL, [true])).rows[0].n;
    offenders = (await client.query(DETECT_SQL, [true, OURS])).rows;
    latent = (await client.query(DETECT_SQL, [false, OURS])).rows;

    // ── Positive control: plant one of each reason and prove both are reported.
    picks = (await client.query(CONTROL_PICK_SQL, [OURS])).rows;
    if (picks.length === 2) {
      await client.query('UPDATE essentials.politicians SET photo_custom_url = NULL WHERE id = $1', [picks[0].id]);
      await client.query('UPDATE essentials.politicians SET photo_custom_url = $2 WHERE id = $1', [picks[1].id, PLANTED_OFF_CDN]);
      const after = (await client.query(DETECT_SQL, [true, OURS])).rows;
      sawNull = after.some((r) => r.id === picks[0].id && r.reason === 'NULL');
      sawOffCdn = after.some((r) => r.id === picks[1].id && r.reason === 'OFF_CDN');
    }
  } finally {
    // Unconditional: the plants must never survive, on any path.
    try { await client.query('ROLLBACK'); } catch { /* connection already gone */ }
    client.release();
  }

  if (corpus === 0) {
    console.error(
      'FAIL (empty corpus): not one active politician holds a politician_images row. That is not a\n' +
      'clean database — it means the join or the schema moved under this check, and a green result\n' +
      'here would be vacuous. Refusing to report one.',
    );
    await pool.end();
    process.exit(2);
  }

  if (picks.length < 2) {
    console.error(
      'FAIL (no control available): could not find two active politicians that hold an image row AND\n' +
      'already set photo_custom_url on our storage path. That is the NORMAL state of 9,459 rows, so\n' +
      'its absence means this query is wrong rather than that the data is. Refusing to report a result.',
    );
    await pool.end();
    process.exit(2);
  }

  if (!sawNull || !sawOffCdn) {
    const missed = [!sawNull && 'NULL', !sawOffCdn && 'OFF_CDN'].filter(Boolean).join(' and ');
    console.error(
      `FAIL (blind detector): the ${missed} half of the predicate did not report a planted offender.\n` +
      `  NULL plant     ${picks[0].full_name} (${picks[0].id}) — ${sawNull ? 'seen' : 'MISSED'}\n` +
      `  OFF_CDN plant  ${picks[1].full_name} (${picks[1].id}) — ${sawOffCdn ? 'seen' : 'MISSED'}\n` +
      'An empty result therefore says nothing about the database. Fix the query before trusting a\n' +
      'green run. (Both plants were rolled back; prod is unchanged.)',
    );
    await pool.end();
    process.exit(2);
  }

  const latentNote = latent.length === 0
    ? 'no inactive ones either'
    : `◐ ${latent.length} INACTIVE politician(s) with an image row and no usable column — not swept by the ` +
      'face gate today, blind the moment anyone reactivates them';

  if (offenders.length === 0) {
    console.log(
      `Headshot column OK — all ${corpus} active politicians holding an image row set photo_custom_url\n` +
      `on our own storage path; ${latentNote}.\n` +
      '  (control passed: a planted NULL and a planted off-CDN value were both reported, then rolled back.)',
    );
    if (VERBOSE && latent.length > 0) for (const r of latent) console.log(describe(r));
    await pool.end();
    process.exit(0);
  }

  console.error(failMessage(offenders, corpus, latentNote));
  await pool.end();
  process.exit(1);
})().catch(async (err) => {
  console.error('FAIL: check-headshot-column errored:', err.message);
  try { await pool.end(); } catch { /* already closed */ }
  process.exit(2);
});
