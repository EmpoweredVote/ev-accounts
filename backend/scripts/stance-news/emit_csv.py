"""Emit research.csv and evidence.csv for the Charlotte batch from rows.json.

Keeping the rows in one JSON and regenerating both CSVs makes the "one row per
(full_name, topic_key)" rule structural: a re-research replaces the entry, so a
duplicate pair cannot be appended by accident.
"""
import csv, io, json, os, sys

DEFAULT_BATCH = r"C:\ev-accounts-stances-clt\backend\data\stance-research\2026-10-02-knight-clt-city"
BATCH = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_BATCH
HERE = os.path.dirname(os.path.abspath(__file__))
ROWS = os.path.join(HERE, sys.argv[2] if len(sys.argv) > 2 else "rows.json")

RESEARCH_COLS = ["full_name", "topic_key", "value", "evidence_type", "reasoning",
                 "source_url_1", "source_url_2", "source_url_3",
                 "quote_text", "quote_deidentified", "editor_note"]
EVIDENCE_COLS = ["full_name", "topic_key", "source_url", "snippet", "snippet_index"]


def main():
    data = json.load(open(ROWS, encoding="utf-8"))
    rows = data["rows"]
    seen = set()
    for r in rows:
        key = (r["full_name"], r["topic_key"])
        if key in seen:
            print("DUPLICATE PAIR", key, file=sys.stderr)
            sys.exit(1)
        seen.add(key)

    with io.open(os.path.join(BATCH, "research.csv"), "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=RESEARCH_COLS, quoting=csv.QUOTE_MINIMAL)
        w.writeheader()
        for r in rows:
            w.writerow({c: r.get(c, "") for c in RESEARCH_COLS})

    ev_out = []
    for r in rows:
        cited = {r.get(c, "") for c in ("source_url_1", "source_url_2", "source_url_3") if r.get(c)}
        for i, e in enumerate(r.get("evidence", []), 1):
            if e["source_url"] not in cited:
                print("EVIDENCE URL NOT CITED", r["full_name"], r["topic_key"],
                      e["source_url"], file=sys.stderr)
                sys.exit(1)
            ev_out.append({"full_name": r["full_name"], "topic_key": r["topic_key"],
                           "source_url": e["source_url"], "snippet": e["snippet"],
                           "snippet_index": i})

    with io.open(os.path.join(BATCH, "evidence.csv"), "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=EVIDENCE_COLS, quoting=csv.QUOTE_MINIMAL)
        w.writeheader()
        for e in ev_out:
            w.writerow(e)

    scored = [r for r in rows if str(r.get("value", "")).strip()]
    print("rows=%d scored=%d blank=%d evidence=%d"
          % (len(rows), len(scored), len(rows) - len(scored), len(ev_out)))


if __name__ == "__main__":
    main()
