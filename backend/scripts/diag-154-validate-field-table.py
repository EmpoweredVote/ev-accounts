#!/usr/bin/env python3
"""
diag-154-validate-field-table.py — read-only validator for 154-field-table.csv.

Asserts (Phase 154 Plan 02, USHC2-01):
  - 113 data rows; per-state counts PA 17 / IL 17 / OH 15 / GA 14 / NC 14 / MI 13 / NJ 12 / VA 11
  - field_status partition: exactly 89 rows 'decided' + exactly 24 rows containing 'pending-primary'
    (any other field_status value is a problem)
  - every row has a non-empty source_url and nominee_status
  - every non-(open-seat-vacancy / special-seated / vacancy) row has a non-empty incumbent_pid
  - existing_race_id is BLANK for ALL 113 rows (no pre-seeded Wave-2 races; races authored in 155/156/157/159)

Prints "PASS" on success; prints a clear FAIL with the offending rows otherwise
and exits non-zero. Does NOT touch the database (the live-DB baseline is covered
by 154-verify.sql); this is a pure CSV-shape gate.
"""
import csv
import os
import re
import sys

UUID_RE = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-"
                     r"[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")

HERE = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.normpath(os.path.join(
    HERE, "..", "..",
    ".planning", "phases", "154-field-resolution-stance-gap-diagnostic",
    "154-field-table.csv",
))

EXPECTED = {"PA": 17, "IL": 17, "OH": 15, "GA": 14, "NC": 14, "MI": 13, "NJ": 12, "VA": 11}
EXPECTED_TOTAL = 113
EXPECTED_DECIDED = 89
EXPECTED_PENDING = 24
# nominee_status values exempt from the non-empty incumbent_pid rule (no sitting incumbent to reuse).
PID_EXEMPT = {"open-seat-vacancy", "special-seated", "vacancy"}
REQUIRED_COLS = [
    "state", "cd", "geo_id", "target_election", "existing_race_id",
    "incumbent_name", "incumbent_pid", "incumbent_external_id",
    "incumbent_stance_count", "incumbent_top_up_tier", "nominee_status",
    "general_candidates", "new_records_needed", "field_status", "source_url",
]


def fail(msg):
    print("FAIL: " + msg)
    sys.exit(1)


def main():
    if not os.path.isfile(CSV_PATH):
        fail("field table not found at %s" % CSV_PATH)

    with open(CSV_PATH, newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        if reader.fieldnames != REQUIRED_COLS:
            fail("header mismatch.\n expected: %s\n got:      %s"
                 % (REQUIRED_COLS, reader.fieldnames))
        rows = list(reader)

    # row count
    if len(rows) != EXPECTED_TOTAL:
        fail("expected %d data rows, got %d" % (EXPECTED_TOTAL, len(rows)))

    per_state = {}
    decided = 0
    pending = 0
    problems = []
    for r in rows:  # header is line 1
        st = r["state"]
        cd = r["cd"]
        per_state[st] = per_state.get(st, 0) + 1

        if not r["source_url"].strip():
            problems.append("%s-%s: empty source_url" % (st, cd))
        if not r["nominee_status"].strip():
            problems.append("%s-%s: empty nominee_status" % (st, cd))

        # incumbent_pid required unless the seat has no sitting incumbent to reuse
        if r["nominee_status"] not in PID_EXEMPT and not r["incumbent_pid"].strip():
            problems.append("%s-%s: empty incumbent_pid (nominee_status=%s not in exempt set)"
                            % (st, cd, r["nominee_status"]))

        # existing_race_id: VA's 11 House races are already scaffolded in the DB (reuse in
        # Phase 159) -> must be UUID-shaped. All other 102 rows have no pre-seeded race -> blank.
        rid = r["existing_race_id"].strip()
        if st == "VA":
            if not rid:
                problems.append("VA-%s: empty existing_race_id (VA races are pre-scaffolded — must reuse)" % cd)
            elif not UUID_RE.match(rid):
                problems.append("VA-%s: existing_race_id not UUID-shaped: %s" % (cd, rid))
        elif rid:
            problems.append("%s-%s: existing_race_id should be blank (no pre-seeded race): %s"
                            % (st, cd, rid))

        # field_status partition
        fs = r["field_status"].strip()
        if fs == "decided":
            decided += 1
        elif "pending-primary" in fs:
            pending += 1
        else:
            problems.append("%s-%s: unexpected field_status %r (must be 'decided' or contain 'pending-primary')"
                            % (st, cd, fs))

    for st, want in EXPECTED.items():
        got = per_state.get(st, 0)
        if got != want:
            problems.append("state %s: expected %d rows, got %d" % (st, want, got))

    if decided != EXPECTED_DECIDED:
        problems.append("field_status partition: expected %d 'decided', got %d" % (EXPECTED_DECIDED, decided))
    if pending != EXPECTED_PENDING:
        problems.append("field_status partition: expected %d 'pending-primary', got %d" % (EXPECTED_PENDING, pending))

    if problems:
        print("FAIL: %d problem(s):" % len(problems))
        for p in problems:
            print("  - " + p)
        sys.exit(1)

    print("PASS: 113 rows, PA 17 / IL 17 / OH 15 / GA 14 / NC 14 / MI 13 / NJ 12 / VA 11; "
          "field_status 89 decided + 24 pending-primary; "
          "all source_url + nominee_status present; "
          "all non-exempt incumbent_pid present; "
          "11 VA existing_race_id UUID-shaped (pre-scaffolded), 102 others blank.")


if __name__ == "__main__":
    main()
