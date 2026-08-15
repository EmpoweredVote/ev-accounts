# Who among the seated 147 sponsored a given WA bill?
#   py wa_cohort.py "HB 1217" ["HB 2367" ...]
# Resolves through member IDs and the verified DB linkage, never through surnames.
import json, os, sys

CACHE = os.path.join(os.environ["TEMP"], "ev-stance-cache", "wa-leg")
link = json.load(open(os.path.join(CACHE, "member-link.json"), encoding="utf-8"))["link"]
by_member = {v["memberId"]: v for v in link.values()}


def cohort(bill_id):
    p = os.path.join(CACHE, "bills", bill_id.replace(" ", "_") + ".json")
    if not os.path.exists(p):
        print(f"{bill_id}: NOT CACHED — fetch it first")
        return []
    r = json.load(open(p, encoding="utf-8"))
    seen, out, unseated = {}, [], []
    for s in r.get("sponsors", []):
        mid = s["id"]
        if not mid or mid in seen:
            continue
        seen[mid] = True
        m = by_member.get(mid)
        if m:
            out.append({**m, "type": s["type"], "order": int(s["order"] or 0)})
        else:
            unseated.append(s["name"])
    out.sort(key=lambda x: x["order"])
    print(f"\n=== {r['billId']} — {r.get('shortDescription','')} ===")
    print(f"    {r.get('longDescription','')[:120]}")
    print(f"    unique sponsors: {len(seen)}   seated among the 147: {len(out)}   not seated: {len(unseated)}")
    if unseated:
        print(f"    (not seated: {', '.join(unseated)})")
    for m in out:
        print(f"  {m['type']:9} {m['party']} LD{m['district']:>2}  {m['name']:28} {m['pid']}")
    return out


if __name__ == "__main__":
    for b in sys.argv[1:]:
        cohort(b)
