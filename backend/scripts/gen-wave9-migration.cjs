const fs = require('fs');
const path = require('path');

// Read CSV manually (no csv-parse)
const csvPath = path.join(__dirname, '../data/stance-research/2026-06-10-112-va-delegates-wave9.csv');
const prefPath = path.join(__dirname, '../data/stance-research/2026-06-10-112-va-delegates-wave9-preflight.json');

function parseCSV(content) {
  const lines = content.replace(/\r\n/g, '\n').split('\n').filter(l => l.trim());
  const headers = lines[0].split(',');
  return lines.slice(1).map(line => {
    const result = [];
    let cur = '', inQ = false;
    for (let i = 0; i < line.length; i++) {
      if (line[i] === '"') { inQ = !inQ; }
      else if (line[i] === ',' && !inQ) { result.push(cur); cur = ''; }
      else cur += line[i];
    }
    result.push(cur);
    const obj = {};
    headers.forEach((h, i) => obj[h.trim()] = (result[i] || '').trim());
    return obj;
  });
}

function esc(s) { return (s || '').replace(/'/g, "''"); }

const rows = parseCSV(fs.readFileSync(csvPath, 'utf8'));
const pf = JSON.parse(fs.readFileSync(prefPath, 'utf8'));

const uuidMap = {};
pf.delegates.forEach(d => { uuidMap[d.full_name] = d.id; });

const header = `-- Phase 112-09: VA House Delegate Stances — Wave 9 (HD-1 through HD-10, NoVA Core)
-- Requirements covered: VAST-03, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-10-112-va-delegates-wave9.csv
--
-- Pre-write cross-check:
--   CSV data rows:                          ${rows.length}
--   INSERT INTO inform.politician_answers:  ${rows.length}
--   INSERT INTO inform.politician_context:  ${rows.length}
--   All UUID literals verified against 2026-06-10-112-va-delegates-wave9-preflight.json
--   max_migration at authoring: 356
--
-- Honest skips (0 stances, no documentable evidence found):
--   R. Kirk McPike (HD-5) — b85d17af-a823-413c-b79c-aa4e7cfab730 — LIS member code H0406 returned no bill records across sessions 221/231/241/251; insufficient web presence to document stances without party inference
--
-- Politician UUIDs (from 2026-06-10-112-va-delegates-wave9-preflight.json):
--   Patrick A. Hope           (HD-1,  ext_id -5120001) -> af6e165b-4668-449b-97a5-6b25c01c572a
--   Adele Y. McClure          (HD-2,  ext_id -5120002) -> 8461412e-6413-4f44-ae5e-b7c8e7f736a5
--   Alfonso H. Lopez          (HD-3,  ext_id -5120003) -> 5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba
--   Charniele L. Herring      (HD-4,  ext_id -5120004) -> 51f5dd85-abb6-4f50-bcb9-e5e6b82376b7
--   R. Kirk McPike            (HD-5,  ext_id -5120005) -> b85d17af-a823-413c-b79c-aa4e7cfab730  (honest-skip)
--   Richard C. Sullivan, Jr.  (HD-6,  ext_id -5120006) -> 1964984f-1751-4ac7-ae94-69e50b0c2968
--   Karen Keys-Gamarra        (HD-7,  ext_id -5120007) -> c0baa6ca-b02d-4bbe-8d90-5f36d31cba1e
--   Irene Shin                (HD-8,  ext_id -5120008) -> 98023fc8-d83b-43ba-b7e1-5bd132122bbe
--   Karrie K. Delaney         (HD-9,  ext_id -5120009) -> b17426e3-d363-44fd-a2b7-a04f54f6d7cb
--   Dan Helmer                (HD-10, ext_id -5120010) -> 090cebbd-19b5-41ed-9c9a-5f537cdb5470
--
-- Migration number: 339
-- Timestamp: 20260610000009
-- Applied: NOT YET (write-only)

BEGIN;

`;

let body = '';
for (const row of rows) {
  const uuid = uuidMap[row.full_name];
  if (!uuid) { console.error('No UUID for:', row.full_name); process.exit(1); }
  const urls = [row.source_url_1, row.source_url_2, row.source_url_3].filter(u => u && u.trim());
  const urlLiterals = urls.map(u => `    '${esc(u)}'`).join(',\n');
  body += `-- ---- ${esc(row.full_name)} / ${row.topic_key} / value=${row.value} ----\n`;
  body += `INSERT INTO inform.politician_answers (politician_id, topic_id, value)\nVALUES (\n  '${uuid}',\n  (SELECT id FROM inform.compass_topics WHERE topic_key = '${row.topic_key}'),\n  ${row.value}\n)\nON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;\n\n`;
  body += `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)\nVALUES (\n  '${uuid}',\n  (SELECT id FROM inform.compass_topics WHERE topic_key = '${row.topic_key}'),\n  '${esc(row.reasoning)}',\n  ARRAY(SELECT u FROM unnest(ARRAY[\n${urlLiterals}\n  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')\n)\nON CONFLICT (politician_id, topic_id)\nDO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;\n\n`;
}

const verif = `-- Verification block scoped to Wave 9 (external_id BETWEEN -5120010 AND -5120001)
DO $$
DECLARE
  delegate_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO delegate_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5120010 AND -5120001;
  RAISE NOTICE 'VA delegates with stances (Wave 9): %', delegate_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5120010 AND -5120001
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA delegate stances (Wave 9): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;
`;

const sql = header + body + verif;
const outPath = path.join(__dirname, '../../supabase/migrations/20260610000009_339_va_delegates_wave9_stances.sql');
fs.writeFileSync(outPath, sql);
console.log('Written:', outPath);
console.log('Rows:', rows.length, '| Answer INSERTs:', (sql.match(/INSERT INTO inform\.politician_answers/g)||[]).length, '| Context INSERTs:', (sql.match(/INSERT INTO inform\.politician_context/g)||[]).length);
