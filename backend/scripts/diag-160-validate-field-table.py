#!/usr/bin/env python3
"""
diag-160-validate-field-table.py — read-only validator for 160-field-table.csv.

Asserts (Phase 160 Plan 07, USHC3-01 / D-05):
  - 178 data rows; per-state counts for all 38 Wave-3 states (see EXPECTED below)
  - field_status partition: exactly 88 rows 'decided' + exactly 90 rows 'late-primary'
    (any other field_status value is a problem)
  - 19 required columns present, including the 4 D-05 additions: seeding_phase,
    ballot_system, rcv, filing_open_deadline
  - every row has a non-empty source_url and nominee_status
  - every non-(open-seat-vacancy / special-seated / vacancy) row has a non-empty
    incumbent_pid
  - existing_race_id is UUID-shaped exactly for rows whose state is in
    {ME, MD, MA, NV, OR} (the discovered 29-row pre-existing-race set) and BLANK
    for every other row — a row-level check, not a state-blanket check
  - Alabama district-split: AL rows with cd in {3,4,5} must be field_status=decided;
    AL rows with cd in {1,2,6,7} must be field_status=late-primary

Prints "PASS" on success; prints a clear FAIL with the offending rows otherwise
and exits non-zero. Does NOT touch the database (the live-DB baseline is covered
by 160-verify.sql); this is a pure CSV-shape gate.
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
    ".planning", "phases", "160-field-resolution-stance-gap-diagnostic",
    "160-field-table.csv",
))

EXPECTED = {
    "WA": 10, "AZ": 9, "TN": 9, "MA": 9, "IN": 9, "MD": 8, "MN": 8, "MO": 8,
    "WI": 8, "CO": 8, "AL": 7, "SC": 7, "LA": 6, "KY": 6, "OR": 6, "CT": 5,
    "OK": 5, "AR": 4, "IA": 4, "KS": 4, "MS": 4, "NV": 4, "UT": 4, "NM": 3,
    "NE": 3, "WV": 2, "ID": 2, "HI": 2, "ME": 2, "NH": 2, "RI": 2, "MT": 2,
    "AK": 1, "DE": 1, "ND": 1, "SD": 1, "VT": 1, "WY": 1,
}
EXPECTED_TOTAL = 178
EXPECTED_DECIDED = 88
EXPECTED_LATE = 90
# nominee_status values exempt from the non-empty incumbent_pid rule (no sitting incumbent to reuse).
PID_EXEMPT = {"open-seat-vacancy", "special-seated", "vacancy"}
# States whose districts have a pre-existing 2026-11-03 essentials.races row (29 rows total:
# MA 9 + MD 8 + OR 6 + NV 4 + ME 2) — a row-level rule, not a state-blanket one, since every
# row in these 5 states' delegations is fully covered (no partial-state pre-existing case).
EXISTING_RACE_STATES = {"ME", "MD", "MA", "NV", "OR"}
# Alabama's mid-cycle redistricting district split (Critical Finding 2).
AL_DECIDED_CDS = {"3", "4", "5"}
AL_LATE_CDS = {"1", "2", "6", "7"}
REQUIRED_COLS = [
    "state", "cd", "geo_id", "target_election", "existing_race_id",
    "incumbent_name", "incumbent_pid", "incumbent_external_id",
    "incumbent_stance_count", "incumbent_top_up_tier", "nominee_status",
    "general_candidates", "new_records_needed", "field_status", "source_url",
    "seeding_phase", "ballot_system", "rcv", "filing_open_deadline",
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
    late = 0
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

        # existing_race_id: row-level check. ME/MD/MA/NV/OR districts reuse a pre-existing
        # 2026-11-03 race (29 rows total) -> must be UUID-shaped. All other 149 rows have no
        # pre-seeded race -> blank.
        rid = r["existing_race_id"].strip()
        if st in EXISTING_RACE_STATES:
            if not rid:
                problems.append("%s-%s: empty existing_race_id (state=%s is in the pre-existing-race set — must reuse)"
                                % (st, cd, st))
            elif not UUID_RE.match(rid):
                problems.append("%s-%s: existing_race_id not UUID-shaped: %s" % (st, cd, rid))
        elif rid:
            problems.append("%s-%s: existing_race_id should be blank (no pre-seeded race): %s"
                            % (st, cd, rid))

        # field_status partition (Wave-3 uses 'decided' / 'late-primary', not Wave-2's
        # 'decided' / 'pending-primary').
        fs = r["field_status"].strip()
        if fs == "decided":
            decided += 1
        elif fs == "late-primary":
            late += 1
        else:
            problems.append("%s-%s: unexpected field_status %r (must be 'decided' or 'late-primary')"
                            % (st, cd, fs))

        # Alabama district-split assertion (Critical Finding 2): AL-3/4/5 decided,
        # AL-1/2/6/7 late-primary — a district-level check, not a state-blanket shortcut.
        if st == "AL":
            if cd in AL_DECIDED_CDS and fs != "decided":
                problems.append("AL-%s: expected field_status=decided (AL district-split), got %r" % (cd, fs))
            elif cd in AL_LATE_CDS and fs != "late-primary":
                problems.append("AL-%s: expected field_status=late-primary (AL district-split), got %r" % (cd, fs))

    for st, want in EXPECTED.items():
        got = per_state.get(st, 0)
        if got != want:
            problems.append("state %s: expected %d rows, got %d" % (st, want, got))

    if decided != EXPECTED_DECIDED:
        problems.append("field_status partition: expected %d 'decided', got %d" % (EXPECTED_DECIDED, decided))
    if late != EXPECTED_LATE:
        problems.append("field_status partition: expected %d 'late-primary', got %d" % (EXPECTED_LATE, late))

    if problems:
        print("FAIL: %d problem(s):" % len(problems))
        for p in problems:
            print("  - " + p)
        sys.exit(1)

    print("PASS: 178 rows across 38 states (WA10..WY1); "
          "field_status 88 decided + 90 late-primary; "
          "all source_url + nominee_status present; "
          "all non-exempt incumbent_pid present; "
          "29 rows (ME2/MD8/MA9/NV4/OR6) existing_race_id UUID-shaped, 149 others blank; "
          "AL district-split verified (AL-3/4/5 decided, AL-1/2/6/7 late-primary).")


if __name__ == "__main__":
    main()
