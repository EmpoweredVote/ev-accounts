#!/usr/bin/env python3
"""
Config-driven validation pipeline — Phase 134 refactor of validate_la_county.py.

Performs three checks in sequence:
  1. VACUUM ANALYZE essentials.geofence_boundaries (VAL-02)
  2. GiST index verification via EXPLAIN ANALYZE (VAL-03)
  3. Point-in-polygon tier checks for the per-state address corpus (VAL-01 + VAL-04)

Usage:
    cd ev-accounts/backend/scripts
    python3 validate_pipeline.py --state CA
    python3 validate_pipeline.py --state UT

Exit codes:
    0 — all addresses pass AND GiST index check passes
    1 — any address fails OR GiST index check fails OR unknown/missing state

Adding a new state: create validate-addresses-<STATE>.json in this directory,
following the CA/UT examples. No code changes required.
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

import psycopg2
import psycopg2.extras
from urllib.parse import urlparse


# ============================================================
# Env loading — reads DATABASE_URL from ev-accounts/backend/.env
# (the TS loaders use dotenv -> .env; this mirrors that convention).
# Falls back to .env.local for backward compatibility with EV-Backend.
# ============================================================

def load_env() -> None:
    """Load DATABASE_URL from .env if not already set in the environment.

    Reads ev-accounts/backend/.env (two directories above this script:
    scripts/ -> backend/ -> .env).
    Falls back to .env.local for backward compatibility.
    If DATABASE_URL is already set (e.g. via shell export), does nothing.

    CRITICAL: Use the direct connection string (port 5432).
    The Supabase pooler (port 6543) breaks VACUUM ANALYZE.
    Never log the connection string.
    """
    if os.getenv("DATABASE_URL"):
        return

    script_dir = Path(__file__).parent
    candidates = [
        script_dir.parent / ".env",        # ev-accounts/backend/.env
        script_dir.parent / ".env.local",  # ev-accounts/backend/.env.local (back-compat)
    ]

    for env_path in candidates:
        if env_path.exists():
            with open(env_path) as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("DATABASE_URL="):
                        os.environ["DATABASE_URL"] = line.split("=", 1)[1].strip()
                        return  # Found; never log the value
            break  # File found but DATABASE_URL not in it — stop searching

    print("Error: DATABASE_URL not set and no .env file found", file=sys.stderr)
    sys.exit(1)


# ============================================================
# Database connection
# ============================================================

def get_connection():
    """Open a psycopg2 connection using DATABASE_URL.

    Uses direct connection (port 5432) — pooler port 6543 breaks VACUUM.
    Never logs the connection string (T-134-05).
    """
    raw_url = os.getenv("DATABASE_URL")
    if not raw_url:
        print("Error: DATABASE_URL not set. Call load_env() first.", file=sys.stderr)
        sys.exit(1)
    parsed = urlparse(raw_url)
    return psycopg2.connect(
        host=parsed.hostname,
        port=parsed.port or 5432,        # Pitfall 1: pooler 6543 breaks VACUUM
        dbname=parsed.path.lstrip("/"),
        user=parsed.username,
        password=parsed.password,
    )


# ============================================================
# Config loading — one JSON file per state (D-04, D-05)
# ============================================================

def load_config(state: str, scripts_dir: str = None) -> dict:
    """Load the per-state address config from validate-addresses-<state>.json.

    Args:
        state:       Two-letter state code (e.g. "CA", "UT").
        scripts_dir: Directory containing the JSON files. Defaults to
                     the directory of this script.

    Returns:
        Parsed config dict with 'state', 'fips', 'description', 'addresses' keys.

    Raises:
        FileNotFoundError / sys.exit(1) if no config exists for the state.
    """
    if scripts_dir is None:
        scripts_dir = str(Path(__file__).parent)

    config_path = os.path.join(scripts_dir, f"validate-addresses-{state.lower()}.json")
    if not os.path.exists(config_path):
        msg = (
            f"Error: no config found for state '{state}'. "
            f"Expected: {config_path}\n"
            f"Create validate-addresses-{state.lower()}.json to add a new state."
        )
        print(msg, file=sys.stderr)
        raise FileNotFoundError(msg)

    with open(config_path) as f:
        config = json.load(f)

    return config


# ============================================================
# Assertion evaluator — pure function (testable without DB)
# ============================================================

def evaluate_assertions(found: dict, assertions: dict) -> dict:
    """Evaluate per-tier assertions against found tier counts.

    Args:
        found:      Dict mapping tier name -> count (int). Missing tiers = 0.
        assertions: Dict mapping tier name -> assertion spec.
                    Only tiers listed in assertions are evaluated (superset semantics).

    Assertion spec shapes (D-06):
        {"min": N}              — tier count >= N  ({min:1} = "tier present")
        {"max": N}              — tier count <= N
        {"min": M, "max": N}   — M <= tier count <= N
        {"exact": N}            — tier count == N  ({exact:0} = "tier must be absent")
        {"expect": true}        — non-count flag; tier count >= 1 means true

    Returns:
        Dict mapping tier name -> bool (True=PASS, False=FAIL).
        Only tiers in assertions are present in the result — extra found tiers ignored.

    Raises:
        ValueError if an assertion contains an unknown key.
    """
    results = {}

    for tier, spec in assertions.items():
        count = found.get(tier, 0)
        known_keys = {"min", "max", "exact", "expect"}
        unknown = set(spec.keys()) - known_keys
        if unknown:
            raise ValueError(
                f"Malformed assertion for tier '{tier}': unknown key(s) {unknown}. "
                f"Valid keys: {known_keys}"
            )

        if "expect" in spec:
            # Non-count flag: {expect: true} passes iff count >= 1
            results[tier] = count >= 1

        elif "exact" in spec:
            results[tier] = count == spec["exact"]

        elif "min" in spec or "max" in spec:
            passed = True
            if "min" in spec and count < spec["min"]:
                passed = False
            if "max" in spec and count > spec["max"]:
                passed = False
            results[tier] = passed

        else:
            raise ValueError(
                f"Malformed assertion for tier '{tier}': spec has no evaluable key. "
                f"Got: {spec}"
            )

    return results


# ============================================================
# Tier classification — mirrors geofence_lookup.go / essentialsService.ts
# ============================================================

def classify_tier(district_type: str, ocd_id: str, office_title: str) -> str:
    """Return a tier name for the given district metadata.

    Returns one of: federal, state_senate, state_assembly, state,
                    county, city, school, state_board, judicial, unknown
    """
    dt = district_type or ""
    ocd = ocd_id or ""
    title = office_title or ""

    if dt in ("NATIONAL_LOWER", "NATIONAL_UPPER", "NATIONAL_EXEC"):
        return "federal"
    if dt == "STATE_UPPER":
        return "state_senate"
    if dt == "STATE_LOWER":
        return "state_assembly"
    if dt == "STATE_EXEC":
        return "state"
    if dt == "STATE_BOARD":
        # UT State Board of Education — SCHEMA-01 new enum (Pitfall 4)
        return "state_board"
    if dt == "COUNTY":
        return "county"
    if dt == "SCHOOL":
        return "school"
    if dt == "JUDICIAL":
        return "judicial"
    if dt == "LOCAL_EXEC":
        # Mayor / county exec
        if "county:los_angeles" in ocd and "council_district" in ocd:
            return "county"
        return "city"
    if dt == "LOCAL":
        # LA County supervisors have district_type=LOCAL (Phase 35-01 decision).
        # Detect by ocd_id pattern or office title.
        if "county:los_angeles/council_district" in ocd:
            return "county"
        if "Supervisor" in title:
            return "county"
        return "city"
    return "unknown"


# ============================================================
# PIP query — mirrors geofence_lookup.go FindGeoIDsByPoint
# ANTIPARTISAN: p.party column removed from SELECT (T-134-08,
# CLAUDE.md "never surface political parties").
# ============================================================

PIP_QUERY = """
    SELECT DISTINCT
        p.full_name,
        o.title AS office_title,
        d.district_type,
        d.geo_id,
        gb.mtfcc,
        d.ocd_id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON o.district_id = d.id
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
    WHERE ST_Covers(
        gb.geometry,
        ST_SetSRID(ST_MakePoint(%s, %s), 4326)
    )
      AND p.is_active = true
    ORDER BY d.district_type, p.full_name
"""

# Tribal-land auxiliary query — X0004 polygons carry no politician links,
# so the main PIP join cannot surface tribal coverage. Run this separately
# for addresses with a tribal_land {expect:true} assertion (RESEARCH.md Open Q2).
# Read-only SELECT only (D-09, T-134-06).
TRIBAL_LAND_QUERY = """
    SELECT count(*)
    FROM essentials.geofence_boundaries
    WHERE mtfcc = 'X0004'
      AND ST_Covers(
          geometry,
          ST_SetSRID(ST_MakePoint(%s, %s), 4326)
      )
"""


def check_tiers(cur, lat: float, lng: float, needs_tribal: bool = False) -> dict:
    """Run PIP query and return tier -> [(full_name, office_title), ...].

    Also runs the X0004 auxiliary query if needs_tribal is True, adding
    'tribal_land' -> count to the result for {expect:true} assertion evaluation.

    Note: PostGIS ST_MakePoint takes (x=lng, y=lat) — NOT (lat, lng). (Pitfall 2)
    """
    cur.execute(PIP_QUERY, (lng, lat))  # Pitfall 2: swap to (lng, lat)
    rows = cur.fetchall()

    tiers: dict = {}
    for row in rows:
        full_name, office_title, district_type, geo_id, mtfcc, ocd_id = row
        tier = classify_tier(district_type, ocd_id or "", office_title or "")
        if tier not in tiers:
            tiers[tier] = []
        tiers[tier].append((full_name, office_title))

    if needs_tribal:
        cur.execute(TRIBAL_LAND_QUERY, (lng, lat))  # Same (lng, lat) swap
        tribal_count = cur.fetchone()[0]
        tiers["tribal_land"] = [("X0004 polygon", "Tribal land")] * tribal_count

    return tiers


# ============================================================
# Step 1 — VACUUM ANALYZE (VAL-02)
# ============================================================

def run_vacuum_analyze(conn) -> None:
    """Run VACUUM ANALYZE on geofence_boundaries.

    CRITICAL: Must use autocommit=True — VACUUM cannot run inside a transaction.
    (RESEARCH.md Pitfall 1)
    """
    print("\n" + "=" * 60)
    print("STEP 1: VACUUM ANALYZE (VAL-02)")
    print("=" * 60)

    conn.autocommit = True
    cur = conn.cursor()
    try:
        print("Running VACUUM ANALYZE essentials.geofence_boundaries ...")
        t0 = time.time()
        cur.execute("VACUUM ANALYZE essentials.geofence_boundaries;")
        elapsed = time.time() - t0
        print(f"VACUUM ANALYZE complete in {elapsed:.1f}s")
    finally:
        conn.autocommit = False
        cur.close()


# ============================================================
# Step 2 — GiST index verification (VAL-03)
# ============================================================

def verify_gist_index(conn, first_address: dict) -> bool:
    """Check that a GiST index exists and EXPLAIN ANALYZE does not show Seq Scan.

    Uses the first address coordinate from the loaded per-state config for the
    EXPLAIN ANALYZE query — state-derived, not hardcoded (VAL-03 requirement).

    Returns True if index check passes, False if Seq Scan detected.
    """
    print("\n" + "=" * 60)
    print("STEP 2: GiST INDEX VERIFICATION (VAL-03)")
    print("=" * 60)

    cur = conn.cursor()

    # Check pg_indexes for existing GiST index
    cur.execute("""
        SELECT indexname, indexdef
        FROM pg_indexes
        WHERE tablename = 'geofence_boundaries'
          AND schemaname = 'essentials'
          AND indexdef ILIKE '%gist%'
    """)
    idx_rows = cur.fetchall()

    if not idx_rows:
        print("WARNING: No GiST index found on essentials.geofence_boundaries.geometry")
        print("Creating GiST index now ...")
        conn.autocommit = True
        cur.execute("CREATE INDEX ON essentials.geofence_boundaries USING gist (geometry);")
        conn.autocommit = False
        print("GiST index created. Re-running VACUUM ANALYZE to update statistics ...")
        conn.autocommit = True
        cur.execute("VACUUM ANALYZE essentials.geofence_boundaries;")
        conn.autocommit = False
        print("VACUUM ANALYZE complete.")
        # Re-query index list
        cur.execute("""
            SELECT indexname, indexdef
            FROM pg_indexes
            WHERE tablename = 'geofence_boundaries'
              AND schemaname = 'essentials'
              AND indexdef ILIKE '%gist%'
        """)
        idx_rows = cur.fetchall()

    print(f"Found {len(idx_rows)} GiST index(es):")
    for name, defn in idx_rows:
        print(f"  {name}: {defn}")

    # Use first address coordinate from config — state-derived (VAL-03)
    explain_lat = first_address["lat"]
    explain_lng = first_address["lng"]
    explain_label = first_address.get("label", "first config address")

    print(f"\nRunning EXPLAIN ANALYZE with {explain_label} ({explain_lng}, {explain_lat}) ...")
    cur.execute("""
        EXPLAIN ANALYZE
        SELECT geo_id, mtfcc
        FROM essentials.geofence_boundaries
        WHERE ST_Covers(
            geometry,
            ST_SetSRID(ST_MakePoint(%s, %s), 4326)
        )
    """, (explain_lng, explain_lat))  # Pitfall 2: (lng, lat)
    plan_rows = cur.fetchall()
    plan_text = "\n".join(row[0] for row in plan_rows)

    print("\nEXPLAIN ANALYZE output:")
    print(plan_text)

    if "Seq Scan on geofence_boundaries" in plan_text:
        print("\nFAIL: Seq Scan detected on geofence_boundaries — GiST index not used.")
        print("      This may indicate stale statistics. VACUUM ANALYZE should have fixed this.")
        cur.close()
        return False
    else:
        print("\nPASS: No Seq Scan on geofence_boundaries (GiST index confirmed).")
        cur.close()
        return True


# ============================================================
# Step 3 — Per-address PIP validation (VAL-01 + VAL-04)
# ============================================================

def validate_addresses(conn, config: dict) -> list:
    """Run PIP checks for all addresses in the config.

    Returns list of result dicts for summary report.
    """
    state = config["state"]
    addresses = config["addresses"]

    print("\n" + "=" * 60)
    print("STEP 3: ADDRESS VALIDATION (VAL-01 + VAL-04)")
    print("=" * 60)

    cur = conn.cursor()
    results = []

    for idx, addr in enumerate(addresses, 1):
        label = addr["label"]
        lat = addr["lat"]
        lng = addr["lng"]
        notes = addr.get("notes", "")
        assertions = addr.get("assertions", {})

        # Does this address need the tribal-land auxiliary query?
        needs_tribal = "tribal_land" in assertions

        print(f"\n[{idx:02d}/{len(addresses)}] {label}")
        print(f"      Coords: ({lat}, {lng})")
        if notes:
            print(f"      Notes:  {notes}")

        found_tiers = check_tiers(cur, lat, lng, needs_tribal=needs_tribal)

        # Build found counts for assertion evaluation
        # Exclude "unknown" from the counts (unknown = unclassified tier, not a real tier)
        found_counts = {}
        for tier, officials in found_tiers.items():
            if tier == "unknown":
                continue
            found_counts[tier] = len(officials)

        # Print officials grouped by tier (excluding unknown)
        if any(v for k, v in found_tiers.items() if k != "unknown"):
            for tier in sorted(found_tiers.keys()):
                if tier == "unknown":
                    continue
                officials = found_tiers[tier]
                if not officials:
                    continue
                print(f"      [{tier.upper()}]")
                if tier == "tribal_land":
                    print(f"        - X0004 tribal polygon covers this point (count: {len(officials)})")
                else:
                    for name, title in officials:
                        print(f"        - {name} | {title}")
        else:
            print("      (no officials found via geofence)")

        # Evaluate assertions — pure function, no DB needed
        assertion_results = evaluate_assertions(found_counts, assertions)

        # Determine per-address PASS/FAIL
        failing = [tier for tier, passed in assertion_results.items() if not passed]
        passing = [tier for tier, passed in assertion_results.items() if passed]

        # Tiers found but not asserted (extra tiers — OK per CA superset semantics)
        asserted_tiers = set(assertions.keys())
        extra_tiers = {t for t in found_counts if t not in asserted_tiers and t not in ("unknown", "judicial")}
        if extra_tiers:
            print(f"      INFO: Extra tiers found (OK): {', '.join(sorted(extra_tiers))}")

        # Per-tier PASS/FAIL output
        print(f"\n      Tier results:")
        all_display_tiers = sorted(asserted_tiers | extra_tiers)
        for tier in all_display_tiers:
            if tier in assertion_results:
                status_str = "PASS" if assertion_results[tier] else "FAIL"
                count = found_counts.get(tier, 0)
                spec = assertions[tier]
                print(f"        {tier:<16} {status_str}  (found={count}, assertion={json.dumps(spec)})")
            else:
                # Extra tier — not asserted
                count = found_counts.get(tier, 0)
                print(f"        {tier:<16} INFO  (found={count}, not asserted)")

        addr_pass = len(failing) == 0
        if addr_pass:
            detail = f"{len(passing)}/{len(assertions)} assertions PASS"
        else:
            detail = f"FAIL: {', '.join(sorted(failing))}"

        print(f"\n      RESULT: {'PASS' if addr_pass else 'FAIL'} — {detail}")

        results.append({
            "label": label,
            "lat": lat,
            "lng": lng,
            "assertions": assertions,
            "found_counts": found_counts,
            "assertion_results": assertion_results,
            "failing": failing,
            "status": "PASS" if addr_pass else "FAIL",
            "notes": notes,
        })

    cur.close()
    return results


# ============================================================
# Step 4 — Summary report
# ============================================================

def print_summary(results: list, index_pass: bool, state: str) -> bool:
    """Print final summary table and emit machine-greppable summary line.

    The summary line format is:
        <STATE> <PASS_COUNT>/<TOTAL> PASS
    e.g.:  CA 16/16 PASS   or   UT 10/10 PASS

    Plan 02's automated gate greps for this line.

    Returns True if all checks pass, False otherwise.
    """
    print("\n" + "=" * 70)
    print("=== VALIDATION SUMMARY ===")
    print("=" * 70)

    gist_label = "GiST Index Check (EXPLAIN ANALYZE)"
    gist_status = "PASS" if index_pass else "FAIL"
    print(f"{'Check':<45} {'Result':<6}  {'Notes'}")
    print("-" * 70)
    print(f"{'VACUUM ANALYZE complete':<45} {'PASS':<6}  VAL-02")
    print(f"{gist_label:<45} {gist_status:<6}  VAL-03")
    print("-" * 70)

    passed = 0
    failed = 0
    for r in results:
        total_assertions = len(r["assertions"])
        pass_count = sum(1 for v in r["assertion_results"].values() if v)
        tier_summary = f"{pass_count}/{total_assertions} assertions PASS"
        if r["failing"]:
            tier_summary += f" | Failing: {', '.join(sorted(r['failing']))}"
        label = r["label"][:44]
        print(f"{label:<45} {r['status']:<6}  {tier_summary}")
        if r["status"] == "PASS":
            passed += 1
        else:
            failed += 1

    total = len(results)
    print("-" * 70)

    overall_ok = failed == 0 and index_pass
    overall_label = "PASS" if overall_ok else "FAIL"

    print(f"\nOVERALL: {passed}/{total} addresses PASS | GiST: {'PASS' if index_pass else 'FAIL'} | OVERALL: {overall_label}")

    if failed > 0:
        print(f"\nAddresses needing investigation ({failed}):")
        for r in results:
            if r["status"] == "FAIL":
                print(f"  - {r['label']}: failing = {', '.join(sorted(r['failing']))}")

    print("=" * 70)

    # Machine-greppable summary line for Plan 02 automated gate (D-f2)
    # Format: <STATE> <PASS_COUNT>/<TOTAL> PASS  (or FAIL if any failure)
    summary_line = f"{state} {passed}/{total} {'PASS' if overall_ok else 'FAIL'}"
    print(summary_line)

    return overall_ok


# ============================================================
# Main entry point
# ============================================================

def main():
    # Parse --state argument
    parser = argparse.ArgumentParser(
        description="Config-driven state-parameterized validation pipeline.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  python3 validate_pipeline.py --state CA\n"
            "  python3 validate_pipeline.py --state UT\n\n"
            "Adding a new state: create validate-addresses-<STATE>.json in this directory.\n"
            "Exit 0 = all addresses PASS + GiST index PASS; Exit 1 = any failure."
        ),
    )
    parser.add_argument(
        "--state",
        required=True,
        metavar="CODE",
        help="Two-letter state code (e.g. CA, UT). Must have a validate-addresses-<STATE>.json config.",
    )
    args = parser.parse_args()
    state = args.state.upper()

    # Load per-state config — fail fast on unknown state (mirrors TS CLI idiom)
    scripts_dir = str(Path(__file__).parent)
    try:
        config = load_config(state, scripts_dir)
    except FileNotFoundError:
        sys.exit(1)  # Error message already printed by load_config

    addresses = config["addresses"]
    print("=" * 60)
    print(f"Validation Pipeline — {state} ({config.get('description', '')})")
    print(f"Addresses to test: {len(addresses)}")
    print("=" * 60)

    load_env()
    conn = get_connection()

    try:
        # Step 1: VACUUM ANALYZE (VAL-02)
        run_vacuum_analyze(conn)

        # Step 2: GiST index verification (VAL-03) — coordinate from first config address
        first_address = addresses[0]
        index_pass = verify_gist_index(conn, first_address)

        # Step 3: Address validation (VAL-01 + VAL-04)
        results = validate_addresses(conn, config)

    finally:
        conn.close()

    # Step 4: Summary report
    overall_ok = print_summary(results, index_pass, state)

    if overall_ok:
        print(f"\nValidation complete. All checks passed.")
        sys.exit(0)
    else:
        print(f"\nValidation complete. One or more checks FAILED — see summary above.")
        sys.exit(1)


if __name__ == "__main__":
    main()
