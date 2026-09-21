#!/usr/bin/env bash
# Controls for the two OCD-ID suffix guards.
#
# 🔴 A GUARD THAT HAS NEVER BEEN SEEN TO FAIL IS NOT A GUARD — and one that fires on CORRECT code
# gets deleted, so both directions are exercised here. Every case states what it plants and the
# tree is restored afterwards.
#
#   bash data/md-ocd-repair-2026-09/control-ocd-guards.sh     # from backend/
set -u
cd "$(dirname "$0")/../../.." || exit 1
cd backend || exit 1

LOADER=scripts/load-state-tiger-boundaries.ts
BACKUP=$(mktemp)
cp "$LOADER" "$BACKUP"
restore() { cp "$BACKUP" "$LOADER"; rm -f "$BACKUP"; }
trap restore EXIT

pass=0; fail=0
expect() { # expect <want: ok|refuse> <label> <cmd...>
  local want=$1 label=$2; shift 2
  if "$@" >/dev/null 2>&1; then got=ok; else got=refuse; fi
  if [ "$got" = "$want" ]; then pass=$((pass+1)); printf '  ✓ %-12s %s\n' "$got" "$label"
  else fail=$((fail+1)); printf '  ✗ got %-8s %s (wanted %s)\n' "$got" "$label" "$want"; fi
}

echo "══ check:ocd-loader — the static half ═══════════════════════════════════════"
expect ok "the real loader passes" npm run check:ocd-loader --silent

# 1. The helper call removed from the sldu/sldl branch.
python - "$LOADER" <<'PY'
import sys, io
p=sys.argv[1]; s=io.open(p,encoding='utf-8').read()
old='ocd_id = buildOcdId(abbrevUpper, layerDef.ocdKey, ocdDistrictSuffix(districtNum));'
new="ocd_id = buildOcdId(abbrevUpper, layerDef.ocdKey, String(parseInt(districtNum ?? '0', 10)));"
assert old in s, 'PLANT FAILED: the call site moved; this control would prove nothing'
io.open(p,'w',encoding='utf-8').write(s.replace(old,new,1))
print('  plant        the defect reintroduced in the sldu/sldl branch')
PY
expect refuse "it refuses the reintroduced parseInt" npm run check:ocd-loader --silent
restore; cp "$LOADER" "$BACKUP"

# 2. 🔴 THE FALSE-POSITIVE CONTROL. The `cd` branch's parseInt is CORRECT — congressional codes are
#    plain numbers — and the first draft of this guard flagged it. It must stay quiet there.
grep -q "const dn = parseInt(districtNum ?? '0', 10);" "$LOADER" \
  && echo "  plant        none — asserting the cd branch's correct parseInt is still present" \
  || { echo "  ✗ PLANT the cd-branch parseInt is gone; this control would prove nothing"; fail=$((fail+1)); }
expect ok "it does NOT fire on the cd branch" npm run check:ocd-loader --silent

# 3. The branch label itself gone — the guard must refuse rather than silently find nothing.
python - "$LOADER" <<'PY'
import sys, io
p=sys.argv[1]; s=io.open(p,encoding='utf-8').read()
assert "case 'sldu':" in s, 'PLANT FAILED: no sldu case to remove'
io.open(p,'w',encoding='utf-8').write(s.replace("case 'sldu':","case 'sldu_RENAMED':",1))
print('  plant        the sldu case label renamed')
PY
expect refuse "it refuses when its anchor is gone" npm run check:ocd-loader --silent
restore; cp "$LOADER" "$BACKUP"

echo
echo "══ check:ocd-suffixes — the data half ═══════════════════════════════════════"
if [ -z "${DATABASE_URL:-}" ]; then
  echo "  (skipped: DATABASE_URL not set)"
else
  expect ok "production passes" npm run check:ocd-suffixes --silent
  # A planted collapsed row must be caught. Written and rolled back in one transaction.
  echo "  plant        one MN row stripped of its letter, inside a rolled-back txn"
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -q <<'SQL' >/dev/null 2>&1
BEGIN;
UPDATE essentials.districts SET ocd_id='ocd-division/country:us/state:mn/sldl:8' WHERE geo_id='2708A';
SQL
  # The above cannot persist across psql sessions, so the real proof is the in-transaction run:
  node - <<'JS'
import pg from 'pg';
const c = new pg.Client({ connectionString: process.env.DATABASE_URL });
await c.connect(); await c.query('BEGIN');
const before = (await c.query(`SELECT count(*)::int n FROM essentials.districts WHERE geo_id='2708A' AND ocd_id ~ '[A-Z]$'`)).rows[0].n;
await c.query(`UPDATE essentials.districts SET ocd_id='ocd-division/country:us/state:mn/sldl:8' WHERE geo_id='2708A'`);
const after = (await c.query(`SELECT count(*)::int n FROM essentials.districts WHERE geo_id='2708A' AND ocd_id ~ '[A-Z]$'`)).rows[0].n;
if (!(before === 1 && after === 0)) { console.log('  ✗ PLANT did not strip the letter'); process.exit(2); }
const off = (await c.query(`SELECT count(*)::int n FROM essentials.districts
  WHERE district_type::text IN ('STATE_LOWER','STATE_UPPER') AND geo_id ~ '[A-Za-z]$'
    AND ocd_id IS NOT NULL AND ocd_id <> '' AND regexp_replace(ocd_id,'^.*:','') !~ '[A-Za-z]$'`)).rows[0].n;
await c.query('ROLLBACK'); await c.end();
console.log(off === 1 ? "  ✓ refuse       the guard's predicate finds a planted collapsed row"
                      : `  ✗ the predicate found ${off}, expected 1`);
process.exit(off === 1 ? 0 : 2);
JS
  if [ $? -eq 0 ]; then pass=$((pass+1)); else fail=$((fail+1)); fi
fi

echo
echo "$pass control(s) correct · $fail wrong"
[ "$fail" -eq 0 ]
