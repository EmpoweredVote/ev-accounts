"""Compare a converted Open States session folder with a real LegiScan dataset folder for the same session.

Usage: python3 -I verify.py <openstates session dir>[,<more dirs>] <legiscan session dir>
  e.g. verify.py ../datasets-openstates/WA-900009 ../datasets/WA-2166
  TN: LegiScan files extraordinary-session bills (HB7001 ...) inside the regular session; Open States keeps them
  in their own sessions, so pass those too: verify.py ../datasets-openstates/TN-900007,../datasets-openstates/TN-900008 ...
Reads files only. Prints bills, sponsors, floor roll calls and member votes that agree / differ.
"""
import collections, glob, json, os, re, sys, unicodedata
nl =lambda x: re.sub(r"[^a-z]", "", unicodedata.normalize("NFD", x).encode("ascii", "ignore").decode().lower())


def load(d):
    base = glob.glob(os.path.join(d, "*", "*"))[0]
    bills = {json.load(open(f))["bill"]["bill_number"]: json.load(open(f))["bill"] for f in glob.glob(f"{base}/bill/*.json")}
    rcs = {}
    for f in glob.glob(f"{base}/vote/*.json"):
        r = json.load(open(f))["roll_call"]; rcs[r["roll_call_id"]] = r
    ppl = {json.load(open(f))["person"]["people_id"]: json.load(open(f))["person"] for f in glob.glob(f"{base}/people/*.json")}
    return bills, rcs, ppl


ob, orc, opp = {}, {}, {}
for d in sys.argv[1].split(","):
    b_, r_, p_ = load(d)
    for n, b in b_.items():
        ob.setdefault(n, b)  # same number in two sessions: keep the first dir's (pass the regular session first)
    orc.update(r_); opp.update(p_)
lb, lrc, lpp = load(sys.argv[2])
S = collections.Counter()
S["bills_openstates"], S["bills_legiscan"] = len(ob), len(lb)
S["bills_both"] = len(set(ob) & set(lb))
only_l = sorted(set(lb) - set(ob)); only_o = sorted(set(ob) - set(lb))
for n in set(ob) & set(lb):
    a = sorted(nl(p["last_name"]) for p in ob[n]["sponsors"] if p["sponsor_type_id"] == 1 and not p["committee_sponsor"])
    b = sorted(nl(p["last_name"]) for p in lb[n]["sponsors"] if p["sponsor_type_id"] == 1 and not p["committee_sponsor"])
    S["primary_sponsor_same" if a == b else "primary_sponsor_differs"] += 1
    S["status_same" if ob[n]["status"] == lb[n]["status"] else "status_differs"] += 1
    if ob[n]["status"] != lb[n]["status"]: S[f"status_os{ob[n]['status']}_ls{lb[n]['status']}"] += 1
    S["has_text_both" if ob[n]["texts"] and lb[n]["texts"] else "text_missing_one_side"] += 1
bill_of = lambda rcs, bills: {r["roll_call_id"]: n for n, b in bills.items() for r in b["votes"]}
obn, lbn = bill_of(orc, ob), bill_of(lrc, lb)
key = lambda r, bn: (bn.get(r["roll_call_id"]), r["date"], r["chamber"], r["yea"], r["nay"])
lfloor = {key(r, lbn): r for r in lrc.values() if r["total"] >= 30 and "Committee" not in r["desc"]}
ofloor = collections.defaultdict(list)
for r in orc.values():
    if not r["_openstates"]["committee"]:
        ofloor[key(r, obn)].append(r)
fold = lambda v: 3 if v == 4 else v
diffs = []
near = collections.defaultdict(list)  # (bill, date, chamber) -> Open States floor roll calls
for kk, rs in ofloor.items():
    near[kk[:3]].extend(rs)
used = set()


def disagree(r, o):
    om = {m["people_id"]: fold(m["vote_id"]) for m in o["votes"]}
    return sum(1 for m in r["votes"] if m["people_id"] in om and om[m["people_id"]] != fold(m["vote_id"]))


count_diffs = []
missing = []
for k, r in lfloor.items():
    cand = [o for o in ofloor.get(k, []) if o["roll_call_id"] not in used]
    if not cand:
        # same bill, day and chamber, tallies within 2 votes: the same roll call with a voter missing on one side
        cand = [o for o in near.get(k[:3], []) if o["roll_call_id"] not in used
                and abs(o["yea"] - r["yea"]) + abs(o["nay"] - r["nay"]) <= 2]
        if cand:
            S["floor_rollcalls_matched_tally_differs"] += 1
            count_diffs.append((k, (cand[0]["yea"], cand[0]["nay"])))
    if cand:
        S["floor_rollcalls_matched"] += 1
        o = min(cand, key=lambda o: disagree(r, o))  # two roll calls can share bill, day and tally (amendments)
        used.add(o["roll_call_id"])
        om = {m["people_id"]: m["vote_id"] for m in o["votes"]}
        for m in r["votes"]:
            if m["people_id"] in om:
                S["member_votes_same_person_id"] += 1
                if fold(om[m["people_id"]]) != fold(m["vote_id"]):
                    S["member_votes_differ"] += 1; diffs.append((k, lpp.get(m["people_id"], {}).get("name"), m["vote_id"], om[m["people_id"]]))
            else:
                S["member_votes_not_bridged"] += 1
        om_ids = set(om)
        S["member_votes_only_openstates"] += sum(1 for p in om_ids - {m["people_id"] for m in r["votes"]}
                                                 if p < 9000001)  # bridged person LegiScan left out of this roll call
    else:
        S["legiscan_floor_rollcalls_not_in_openstates"] += 1
        missing.append(k)
S["legiscan_floor_rollcalls"] = len(lfloor)
S["openstates_floor_rollcalls"] = sum(len(v) for v in ofloor.values())
S["people_openstates"] = len(opp)
S["people_with_real_legiscan_id"] = sum(1 for p in opp if p < 9000001)
for k, v in S.items():
    print(f"{k:45} {v}")
print("bills only in LegiScan:", only_l[:20])
print("bills only in Open States:", only_o[:20])
print("member vote differences (first 10):", diffs[:10])
print("roll calls matched with tallies 1-2 apart (first 10, LegiScan key then Open States yea/nay):", count_diffs[:10])
print("LegiScan floor roll calls not found (by month, chamber):",
      sorted(collections.Counter((m[1][:7], m[2]) for m in missing).items()))
print("  first 10:", missing[:10])
