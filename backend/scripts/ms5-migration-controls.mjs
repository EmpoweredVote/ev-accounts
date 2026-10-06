#!/usr/bin/env node
/**
 * Build the CC_0175 dry run and one TAMPERED copy per gate.
 *
 * A gate that has only ever been seen green has not been tested. Each control breaks exactly one
 * thing and must raise exactly the matching exception; a control that passes means the gate it
 * targets is not reading what its message claims.
 *
 * Every file ends in ROLLBACK, so none of this can write to production.
 */
import fs from 'node:fs';
import path from 'node:path';

const SRC = 'migrations/CC_0175_ms5_biloxi_harrison_headshots.sql';
const DIR = 'data/seed-ms-2026/_dryrun';
fs.mkdirSync(DIR, { recursive: true });

const base = fs.readFileSync(SRC, 'utf8');
if (!/\nCOMMIT;\s*$/.test(base)) throw new Error('migration does not end in COMMIT; -- refusing to build a dry run');
const rollback = base.replace(/\nCOMMIT;\s*$/, '\nROLLBACK;\n');

const write = (name, body, note) => {
  fs.writeFileSync(path.join(DIR, name), `-- ${note}\n${body}`);
  console.log(`  ${name.padEnd(34)} ${note}`);
};

console.log('built:');
write('ms5-00-dryrun.sql', rollback, 'UNMODIFIED, ends in ROLLBACK. Must pass both gates.');

// 1. PRE: the seat/name join. Rename one person who is really seated.
write('ms5-01-wrong-name.sql',
  rollback.replace("'Robert Nail'", "'Bob Nail'"),
  "PRE tamper: Robert Nail -> Bob Nail. Must fail 'resolve to a seated officeholder'.");

// 2. PRE: the title half of the same join.
write('ms5-02-wrong-title.sql',
  rollback.replace("'Mayor'", "'Vice Mayor'"),
  "PRE tamper: Mayor -> Vice Mayor. Must fail the same gate, proving it reads the TITLE too.");

// 3. PRE: the "already carries a different photo" guard.
//    That guard reads state that exists BEFORE the migration runs, so the tamper has to plant
//    it before the pre-flight block rather than after -- an edit placed later simply gets
//    overwritten by the migration's own UPDATE and the control passes while proving nothing.
write('ms5-03-existing-photo.sql',
  rollback.replace(
    '-- PRE-FLIGHT',
    "UPDATE essentials.politicians SET photo_custom_url = 'https://example.invalid/someone-else.jpg'\n"
    + " WHERE id = 'c4e9f036-a730-4e17-b19f-67bc4cf0685d'::uuid;  -- control: plant a foreign photo\n\n"
    + '-- PRE-FLIGHT'),
  "PRE tamper: one person already holds a foreign photo. Must fail 'already carry a different'.");

// 4. POST: the render-field-is-an-image guard.
//    🔴 AN EARLIER GATE SHADOWS A LATER ONE. Writing the source page into photo_custom_url also
//    breaks the all-three-fields gate, which raises first, so the image-file guard is never
//    reached. The tamper therefore changes the URL the temp table BUILDS: every field then
//    agrees, the first gate passes, and only the second can fire.
write('ms5-04-page-as-photo.sql',
  rollback.replace("|| '-headshot.jpg' AS url", "|| '-headshot.html' AS url"),
  "POST tamper: the render field holds a .html, consistently. Must fail 'do not point at an image file'.");

// 5. POST: the blank-count gate.
write('ms5-05-blank-count.sql',
  rollback.replace('IF n <> 17 THEN', 'IF n <> 16 THEN'),
  "POST tamper: expect 16 blanks instead of 17. Must fail 'expected exactly 17'.");

// 6. POST: the all-three-fields gate. Skip the image insert.
write('ms5-06-no-image-row.sql',
  rollback.replace(
    "INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)\nSELECT gen_random_uuid(), h.pid, h.url, 'default', 'press_use'\n  FROM ms5_head h\n WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images i WHERE i.politician_id = h.pid);",
    '-- image insert removed by the control'),
  "POST tamper: no image row written. Must fail 'carry all three fields'.");

console.log(`\n${fs.readdirSync(DIR).filter(f => f.startsWith('ms5-')).length} files in ${DIR}`);
