# Screen a cohort before applying a shared chair.
#
# The cohort default is only safe if no member has an instrument of their OWN that evidences a
# DIFFERENT chair on the same ladder. This lists, per member, every substantive bill they sponsored
# whose description touches the topic -- excluding the cohort bill itself -- so each candidate can be
# read by hand before the chair is written.
#
#   py wa_screen_cohort.py <cohort_billId> <topic_keyword_set>
import json, os, re, sys

CACHE = os.path.join(os.environ["TEMP"], "ev-stance-cache", "wa-leg")
IDX = json.load(open(os.path.join(CACHE, "sponsorship-index-full.json"), encoding="utf-8"))
LINK = json.load(open(os.path.join(CACHE, "member-link.json"), encoding="utf-8"))["link"]
BY_MEMBER = {v["memberId"]: v for v in LINK.values()}
PROC = re.compile(r"^(HCR|SCR|HR|SR|HJM|SJM)")

# Word-boundary anchored. An unanchored "rent" matches paRENTal and paRENTing, and an unanchored
# "lease" matches reLEASE -- the first cut of this screen fired on parenting-plan and prisoner-reentry
# bills. Every first cut over-fires; anchor before reading anything.
KEYWORDS = {
    "rent": (r"\brent\b|\brents\b|\brental\b|\brentals\b|\brenter|\btenant|\blandlord|\bevict"
             r"|\blease\b|\bleases\b|\bleasing\b|housing stability|manufactured/mobile|mobile home"
             r"|just cause|rent control|rent stabiliz"),
    "climate": (r"\bclimate\b|\bcarbon\b|greenhouse|\bemission|clean energy|renewable|fossil"
                r"|\bcoal\b|cap and invest|cap-and-invest|decarbon|\bnatural gas\b"),
    # `voting-rights` runs from automatic registration (chair 1) to in-person-only with strict photo
    # ID (chair 5), so the screen has to catch registration bills, ID bills, mail/absentee bills and
    # roll-maintenance bills alike. "election" alone is useless -- it matches every campaign-finance,
    # districting and canvassing bill in the corpus -- so it is only matched next to a subject word.
    "voting": (r"\bvoter\b|\bvoters\b|voter registration|\bballot\b|\bballots\b|vote by mail"
               r"|absentee|polling place|voting center|voter roll|election security|election integrity"
               r"|proof of citizenship|verification of citizenship|\bcanvass"),
    # `public-safety-approach` turns on staffing/funding levels AND on whether non-police responders
    # take the call, so the screen has to catch BOTH the police-budget bills and the co-responder /
    # crisis-team ones -- a member holding one of each is the case the screen exists to find.
    "police": (r"\bpolice\b|\bpolicing\b|law enforcement|\bsheriff|\bofficer(s)?\b|public safety"
               r"|co-?responder|crisis response|crisis team|behavioral health response|\b988\b"
               r"|peace officer|\bdeputies\b|community safety"),
    # Deliberately NOT anchored on "revenue" alone: the department of revenue administers most of
    # the tax code, so it fires on every administrative bill. The taxes ladder turns on whether a
    # member raises or cuts, and where the money lands, so match the instruments that do either.
    "tax": (r"\btax\b|\btaxes\b|\btaxed\b|\btaxation\b|\btaxable\b|\btax credit|\btax exemption"
            r"|\btax preference|\bexcise\b|\bb&o\b|business and occupation|\blevy\b|\blevies\b"
            r"|sales and use tax|property tax|capital gains|\bsurcharge\b|\bsurtax\b"),
}


def cohort_members(bill_id):
    p = os.path.join(CACHE, "bills", bill_id.replace(" ", "_") + ".json")
    r = json.load(open(p, encoding="utf-8"))
    seen, out = set(), []
    for s in r.get("sponsors", []):
        if s["id"] and s["id"] not in seen:
            seen.add(s["id"])
            if s["id"] in BY_MEMBER:
                out.append((s["id"], s["type"], BY_MEMBER[s["id"]]))
    return r, out


def main():
    bill_id, kw = sys.argv[1], sys.argv[2]
    pat = re.compile(KEYWORDS[kw], re.I)
    rec, members = cohort_members(bill_id)
    print(f"COHORT {rec['billId']} — {rec.get('shortDescription','')}  ({len(members)} seated sponsors)")
    print(f"screening for other '{kw}' instruments\n")

    clean, flagged = [], []
    for mid, sptype, m in members:
        mm = IDX["members"].get(mid, {"primary": [], "secondary": []})
        hits = []
        for role in ("primary", "secondary"):
            for b in mm[role]:
                if PROC.match(b["billId"]) or b["billId"] == rec["billId"]:
                    continue
                text = f"{b['desc']} {b['long']}"
                if pat.search(text):
                    hits.append((role, b))
        # a member's OWN primary sponsorship is the strongest competing signal
        prim = [h for h in hits if h[0] == "primary"]
        if prim:
            flagged.append((m, sptype, prim, hits))
        else:
            clean.append((m, sptype, hits))

    print(f"=== {len(flagged)} member(s) with their OWN primary-sponsored {kw} bill — READ THESE ===")
    for m, sptype, prim, hits in flagged:
        print(f"\n  {m['name']}  ({m['party']} LD{m['district']}, {sptype} on cohort bill)  [{len(hits)} total {kw} bills]")
        for role, b in prim:
            tag = "ENACTED" if b["enacted"] else "died   "
            print(f"      PRIMARY  {tag}  {b['billId']:10} {b['long'][:95]}")

    print(f"\n=== {len(clean)} member(s) with no primary {kw} instrument of their own ===")
    for m, sptype, hits in clean:
        print(f"  {m['name']:26} {m['party']} LD{m['district']:<3} co-sponsor-only on {len(hits)} other {kw} bill(s)")


if __name__ == "__main__":
    main()
