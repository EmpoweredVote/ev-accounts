#!/usr/bin/env bash
# Watch every post-verify gate FAIL before its pass is believed.
# Each control mutates a COPY of the dry run and must abort with the named exception.
set -u
cd "$(dirname "$0")"
run() { psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$1" 2>&1; }
check() {
  local name="$1" file="$2" want="$3"
  local out; out="$(run "$file")"
  if echo "$out" | grep -q "$want"; then
    echo "  OK   $name -> $(echo "$out" | grep -o "ERROR:.*" | head -1 | cut -c1-110)"
  else
    echo "  FAIL $name -> expected /$want/, got:"; echo "$out" | tail -4 | sed 's/^/        /'
  fi
  rm -f "$file"
}

echo "-- GATE CONTROLS (each must ABORT) ---------------------------------------"

# 1. one office short
sed "s/^  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);/  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id)\n  AND d.geo_id <> '27001';/" _dryrun.sql > _ctl1.sql
check "1 office short" _ctl1.sql "expected 134 House / 67 Senate offices"

# 2. vacancy never flagged
sed "s/^SELECT essentials.vacate_office($/SELECT 1, essentials.vacate_office_DISABLED_BY_CONTROL($/" _dryrun.sql \
  | sed "s/^SELECT essentials.vacate_office(/SELECT (SELECT 1) WHERE false; SELECT essentials.noop_control(/" > /dev/null 2>\&1 || true
python - <<'PY'
import re
s=open('_dryrun.sql',encoding='utf-8').read()
s=re.sub(r"SELECT essentials\.vacate_office\([\s\S]*?WHERE lower\(d\.state\) = 'mn' AND d\.district_type::text = 'STATE_LOWER' AND d\.geo_id = '2721A';",
         "-- control: vacate_office call removed",s,count=1)
open('_ctl2.sql','w',encoding='utf-8').write(s)
PY
check "vacancy not flagged" _ctl2.sql "expected 1 vacant Minnesota legislative office"

# 3. one term short
python - <<'PY'
s=open('_dryrun.sql',encoding='utf-8').read()
s=s.replace("  ('27001', 'STATE_UPPER', ", "  -- control: term row removed\n  ('27001_CONTROL_MISSING', 'STATE_UPPER', ",1)
open('_ctl3.sql','w',encoding='utf-8').write(s)
PY
check "1 term short" _ctl3.sql "expected 200 seated Minnesota legislative offices"

# 4. a term carries a date
python - <<'PY'
s=open('_dryrun.sql',encoding='utf-8').read()
s=s.replace("SELECT o.id, p.id, NULL, NULL, 'unknown', 'unknown',","SELECT o.id, p.id, DATE '2025-01-06', NULL, 'day', 'elected',",1)
open('_ctl4.sql','w',encoding='utf-8').write(s)
PY
check "a term is dated" _ctl4.sql "every Minnesota term is open-ended and unknown"

# 5. the vacant seat gets seated
python - <<'PY'
s=open('_dryrun.sql',encoding='utf-8').read()
s=s.replace("  ('2721B', 'STATE_LOWER', ","  ('2721A', 'STATE_LOWER', -2732001::bigint, NULL::uuid),\n  ('2721B', 'STATE_LOWER', ",1)
open('_ctl5.sql','w',encoding='utf-8').write(s)
PY
check "21A seated anyway" _ctl5.sql "MN-2 occupancy"
