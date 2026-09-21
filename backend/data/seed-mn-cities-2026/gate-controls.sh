#!/usr/bin/env bash
# Watch every MN-3 post-verify gate FAIL before its pass is believed.
# Each control mutates a COPY of the dry run and must abort with the named exception.
#
# 🔴 Control 1 is the one that matters most: it removes the boundary prelude entirely, which is
# the state production is in right now. A structure migration that ran anyway would create
# offices on districts with no polygon -- unreachable by any address, erroring nothing.
#
#   DATABASE_URL=... bash gate-controls.sh
set -u
cd "$(dirname "$0")"

check() {
  local name="$1" file="$2" want="$3"
  if [ ! -f "$file" ]; then echo "  FAIL $name -- control file was never written"; return; fi
  local out; out="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file" 2>&1)"
  if echo "$out" | grep -q "$want"; then
    echo "  OK   $name"
    echo "         $(echo "$out" | grep -o 'ERROR:.*' | head -1 | cut -c1-150)"
  else
    echo "  FAIL $name -- expected /$want/, got:"
    echo "$out" | tail -4 | sed 's/^/           /'
  fi
  rm -f "$file"
}

echo "-- MN-3 GATE CONTROLS (each must ABORT) ----------------------------------------"
python plant-controls.py || { echo "control planting failed"; exit 1; }

check "1  no boundaries loaded at all"          _c1.sql "X0052 holds 0 Duluth council boundaries"
check "2  boundaries from the SUPERSEDED map"   _c2.sql "may be the superseded 2012 map"
check "3  one Duluth district missing"          _c3.sql "X0052 holds 4 Duluth council boundaries"
check "4  at-large ordinals not distinct"       _c4.sql "Duluth at-large is 4 office(s) with 1 distinct"
check "5  Saint Paul given an at-large seat"    _c5.sql "its charter creates none"
check "6  a term written with no start date"    _c6.sql "carry no term_start"
check "7  a term given a term_end"              _c7.sql "self-vacates the seat"
check "8  two at-large seats, one person"       _c8.sql "distinct people, expected 4"
