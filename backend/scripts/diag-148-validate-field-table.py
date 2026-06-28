#!/usr/bin/env python3
"""
diag-148-validate-field-table.py — read-only validator for 148-field-table.csv.

Asserts (Phase 148 Plan 02, USHC-01):
  - 144 data rows; per-state counts CA 52 / TX 38 / FL 28 / NY 26
  - every row has a non-empty source_url and nominee_status
  - every non-open-seat-vacancy row has a non-empty incumbent_pid
  - every CA row has a non-empty existing_race_id matching the UUID shape (8-4-4-4-12 hex)

Prints "PASS" on success; prints a clear FAIL with the offending rows otherwise
and exits non-zero. Does NOT touch the database (the live-DB existing_race_id
match is covered by 148-verify.sql); this is a pure CSV-shape gate.
"""
import csv
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.normpath(os.path.join(
    HERE, "..", "..",
    ".planning", "phases", "148-field-resolution-stance-gap-diagnostic",
    "148-field-table.csv",
))

UUID_RE = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-"
                     r"[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
EXPECTED = {"CA": 52, "TX": 38, "FL": 28, "NY": 26}
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
    if len(rows) != 144:
        fail("expected 144 data rows, got %d" % len(rows))

    per_state = {}
    problems = []
    for i, r in enumerate(rows, start=2):  # +2: header is line 1
        st = r["state"]
        cd = r["cd"]
        per_state[st] = per_state.get(st, 0) + 1

        if not r["source_url"].strip():
            problems.append("%s-%s: empty source_url" % (st, cd))
        if not r["nominee_status"].strip():
            problems.append("%s-%s: empty nominee_status" % (st, cd))

        if r["nominee_status"] != "open-seat-vacancy":
            if not r["incumbent_pid"].strip():
                problems.append("%s-%s: empty incumbent_pid (non-vacancy)" % (st, cd))

        if st == "CA":
            rid = r["existing_race_id"].strip()
            if not rid:
                problems.append("CA-%s: empty existing_race_id" % cd)
            elif not UUID_RE.match(rid):
                problems.append("CA-%s: existing_race_id not UUID-shaped: %s" % (cd, rid))
        else:
            # TX/FL/NY races are created in Phases 150/151 — existing_race_id must be blank
            if r["existing_race_id"].strip():
                problems.append("%s-%s: existing_race_id should be blank for non-CA" % (st, cd))

    for st, want in EXPECTED.items():
        got = per_state.get(st, 0)
        if got != want:
            problems.append("state %s: expected %d rows, got %d" % (st, want, got))

    if problems:
        print("FAIL: %d problem(s):" % len(problems))
        for p in problems:
            print("  - " + p)
        sys.exit(1)

    print("PASS: 144 rows, CA 52 / TX 38 / FL 28 / NY 26, "
          "all source_url + nominee_status present, "
          "all non-vacancy incumbent_pid present, "
          "all 52 CA existing_race_id UUID-shaped.")


if __name__ == "__main__":
    main()
