"""Stage 2: for each harvested matter, pull its histories and per-member votes.

Writes votes.json: one record per (matter, event item) that carries a recorded
roll call, with every member's vote value. Flags divided votes (>=10% against).
"""
import json, os, sys, time, urllib.parse, urllib.request

BASE = "https://webapi.legistar.com/v1/charlottenc"
OUT = os.path.dirname(os.path.abspath(__file__))


def get(path, params=None):
    url = BASE + path
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.loads(r.read().decode("utf-8"))
        except Exception as e:  # noqa: BLE001
            if attempt == 2:
                return None
            time.sleep(1.5)
    return None


def main():
    matters = json.load(open(os.path.join(OUT, "matters.json"), encoding="utf-8"))
    out = []
    seen_items = set()
    for i, m in enumerate(matters, 1):
        hs = get("/matters/%d/histories" % m["MatterId"])
        if not hs:
            continue
        for h in hs:
            eid = h.get("MatterHistoryId")
            if not eid or eid in seen_items:
                continue
            seen_items.add(eid)
            votes = get("/eventitems/%d/votes" % eid)
            if not votes:
                continue
            tally = {}
            for v in votes:
                tally[v.get("VoteValueName")] = tally.get(v.get("VoteValueName"), 0) + 1
            yea = tally.get("Yea", 0)
            nay = tally.get("Nay", 0)
            total = yea + nay
            out.append({
                "MatterId": m["MatterId"], "MatterFile": m.get("MatterFile"),
                "MatterTitle": m.get("MatterTitle"), "topics": m.get("topics"),
                "EventItemId": eid,
                "ActionName": h.get("MatterHistoryActionName"),
                "ActionText": h.get("MatterHistoryActionText"),
                "ActionDate": h.get("MatterHistoryActionDate"),
                "EventId": h.get("MatterHistoryEventId"),
                "PassedFlag": h.get("MatterHistoryPassedFlagName"),
                "AgendaNumber": h.get("MatterHistoryAgendaNumber"),
                "tally": tally,
                "divided": bool(total and nay / total >= 0.10),
                "votes": [{"name": v.get("VotePersonName"), "value": v.get("VoteValueName")}
                          for v in votes],
            })
        if i % 50 == 0:
            print("matters processed", i, "items", len(out), flush=True)
    with open(os.path.join(OUT, "votes.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, indent=1)
    div = [x for x in out if x["divided"]]
    print("ITEMS WITH VOTES", len(out), "DIVIDED", len(div))


if __name__ == "__main__":
    main()
