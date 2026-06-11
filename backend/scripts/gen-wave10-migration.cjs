const fs = require('fs');
const path = require('path');

const csvPath = path.join(__dirname, '../data/stance-research/2026-06-10-112-va-delegates-wave10.csv');
const prefPath = path.join(__dirname, '../data/stance-research/2026-06-10-112-va-delegates-wave10-preflight.json');

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

const header = `-- Phase 112-10: VA House Delegate Stances — Wave 10 (HD-11 through HD-16, NoVA Fairfax/Prince William, FINAL WAVE)
-- Requirements covered: VAST-03, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-10-112-va-delegates-wave10.csv
--
-- Pre-write cross-check:
--   CSV data rows:                          ${rows.length}
--   INSERT INTO inform.politician_answers:  ${rows.length}
--   INSERT INTO inform.politician_context:  ${rows.length}
--   All UUID literals verified against 2026-06-10-112-va-delegates-wave10-preflight.json
--   max_migration at authoring: 358
--
-- Honest skips (0 stances, no documentable evidence found):
--   None — all 6 Wave 10 delegates have at least 5 sourced stances
--
-- Politician UUIDs (from 2026-06-10-112-va-delegates-wave10-preflight.json):
--   Gretchen M. Bulova  (HD-11, ext_id -5120011) -> 1a1d7fb4-8bf0-4aaf-8a1d-7a4ccc00e5f0
--   Holly M. Seibold    (HD-12, ext_id -5120012) -> 4a5090f7-8d76-40c1-b2f4-c2ed038e6687
--   Marcus B. Simon     (HD-13, ext_id -5120013) -> c490eece-71f4-4051-975d-8fa5ed5f652b
--   Vivian E. Watts     (HD-14, ext_id -5120014) -> b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264
--   Laura Jane Cohen    (HD-15, ext_id -5120015) -> a1a470c9-1b16-4e98-999c-4106422cc52c
--   Paul E. Krizek      (HD-16, ext_id -5120016) -> cd70f416-c844-41db-9ff4-c528e04a72be
--
-- Migration number: 340
-- Timestamp: 20260610000010
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

const verif = `-- Verification block scoped to Wave 10 (external_id BETWEEN -5120016 AND -5120011)
DO $$
DECLARE
  delegate_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO delegate_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5120016 AND -5120011;
  RAISE NOTICE 'VA delegates with stances (Wave 10): %', delegate_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5120016 AND -5120011
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA delegate stances (Wave 10): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;
`;

const sql = header + body + verif;
const outPath = path.join(__dirname, '../../supabase/migrations/20260610000010_340_va_delegates_wave10_stances.sql');
fs.writeFileSync(outPath, sql);
console.log('Written:', outPath);
const ansCount = (sql.match(/^INSERT INTO inform\.politician_answers/mg)||[]).length;
const ctxCount = (sql.match(/^INSERT INTO inform\.politician_context/mg)||[]).length;
console.log('Rows:', rows.length, '| Answer INSERTs:', ansCount, '| Context INSERTs:', ctxCount, '| Paired:', ansCount === ctxCount ? 'OK' : 'MISMATCH');
