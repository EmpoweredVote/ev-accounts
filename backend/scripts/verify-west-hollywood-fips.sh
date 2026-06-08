#!/usr/bin/env bash
# verify-west-hollywood-fips.sh
# Verifies the Census FIPS place code for West Hollywood, CA via the Census Geocoder API.
# Emits exactly one line on stdout: the 7-character code in the form 06XXXXX.
# Emits an error message to stderr and exits non-zero if verification fails.
#
# Usage: bash backend/scripts/verify-west-hollywood-fips.sh
# Source: https://geocoding.geo.census.gov (Census Geocoder API)
# Fallback: https://www2.census.gov/geo/docs/reference/codes2020/place/st06_ca_place2020.txt

set -euo pipefail

GEOCODER_URL="https://geocoding.geo.census.gov/geocoder/geographies/address?street=8300+Santa+Monica+Blvd&city=West+Hollywood&state=CA&benchmark=Public_AR_Current&vintage=Current_Current&format=json"
PLACE_FILE_URL="https://www2.census.gov/geo/docs/reference/codes2020/place/st06_ca_place2020.txt"

# Method 1: Census Geocoder API
FIPS=$(curl -s "$GEOCODER_URL" 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    results = data['result']['addressMatches']
    if results:
        places = results[0].get('geographies', {}).get('Incorporated Places', [])
        if places:
            state = places[0].get('STATE', '')
            place = places[0].get('PLACE', '')
            fips = state + place
            if len(fips) == 7:
                print(fips)
                sys.exit(0)
    sys.exit(1)
except Exception:
    sys.exit(1)
" 2>/dev/null || true)

if echo "$FIPS" | grep -qE '^06[0-9]{5}$'; then
    echo "$FIPS"
    exit 0
fi

# Method 2: CA place codes text file
>&2 echo "Census Geocoder API did not return a match; falling back to CA place codes file..."
FIPS=$(curl -s "$PLACE_FILE_URL" 2>/dev/null | grep -i "west hollywood" | python3 -c "
import sys, re
line = sys.stdin.read().strip().split('\n')[0] if sys.stdin.read().strip() else ''
" 2>/dev/null || true)

# Re-run since we already read stdin above - use awk/grep pipeline instead
FIPS2=$(curl -s "$PLACE_FILE_URL" 2>/dev/null | awk -F'|' '/[Ww]est [Hh]ollywood/{print "06" $3}' | head -1 || true)

if echo "$FIPS2" | grep -qE '^06[0-9]{5}$'; then
    echo "$FIPS2"
    exit 0
fi

>&2 echo "ERROR: Could not verify West Hollywood FIPS code via either method."
>&2 echo "  Geocoder result: '${FIPS}'"
>&2 echo "  Place file result: '${FIPS2}'"
>&2 echo "Manual fallback: download $PLACE_FILE_URL and search for 'West Hollywood'"
exit 1
