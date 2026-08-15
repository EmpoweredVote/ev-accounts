# Profile one WA legislator's sponsorship for stance research.
#   py wa_profile.py "Ed Orcutt" [--all]
#
# PRIMARY sponsorships are listed in full: authoring a bill is the strongest single evidence of a
# position. Co-sponsorships are bucketed by compass topic so a shared instrument can be spotted, but
# not dumped -- the median member co-sponsors well over 100 bills.
import json, os, re, sys

C = os.path.join(os.environ["TEMP"], "ev-stance-cache", "wa-leg")
IDX = json.load(open(os.path.join(C, "sponsorship-index-full.json"), encoding="utf-8"))
LINK = json.load(open(os.path.join(C, "member-link.json"), encoding="utf-8"))["link"]
PROC = re.compile(r"^(HCR|SCR|HR|SR|HJM|SJM)")

# Compass topics a WA state legislator plausibly acts on, with anchored keywords.
# Anchored deliberately: an unanchored "rent" matches paRENTal, "lease" matches reLEASE.
TOPIC_KEYS = {
    "taxes":                 r"\btax\b|\btaxes\b|\btaxation|revenue|\bB&O\b|business and occupation|excise|property tax",
    "climate-change":        r"\bclimate\b|\bcarbon\b|greenhouse|\bemission|cap and invest|cap-and-invest|decarbon",
    "fossil-fuels":          r"fossil|\bcoal\b|\boil\b|petroleum|\bdrilling\b|\bnatural gas\b|refiner",
    "healthcare":            r"health care|healthcare|\bmedicaid\b|\bmedicare\b|health insur|hospital|prescription|behavioral health",
    "housing":               r"\bhousing\b|homeless|\bshelter\b|affordable hous",
    "rent-regulation":       r"\brent\b|\brental\b|\btenant|\blandlord|\bevict|just cause|manufactured/mobile|mobile home",
    "residential-zoning":    r"\bzoning\b|\bdensity\b|middle housing|accessory dwelling|\bplat\b|land use|growth management",
    "growth-and-development": r"growth management|\bannex|comprehensive plan|\bpermitting\b|development regulat",
    "transportation-priorities": r"transportation|\btransit\b|\bhighway\b|\bferr(y|ies)\b|bicycle|pedestrian|\btolling\b|\broad\b|\broads\b",
    "public-safety-approach": r"\bpolice\b|law enforcement|\bsheriff\b|public safety|\bpursuit\b|use of force",
    "judicial-criminal-justice": r"sentenc|\bfelony\b|\bmisdemeanor\b|correction|\bprison\b|\bparole\b|reentry|diversion|juvenile",
    "jail-capacity":         r"\bjail\b|\bincarcerat|detention|pretrial",
    "abortion":              r"abortion|reproductive health|pregnan",
    "civil-rights":          r"civil rights|discriminat|\bequity\b|\bracial\b|hate crime",
    "immigration":           r"immigra|\brefugee\b|\basylum\b|undocumented",
    "local-immigration":     r"\bICE\b|immigration enforcement|detainer|sanctuary",
    "childcare":             r"child care|childcare|early learning|\bpreschool\b",
    "school-vouchers":       r"\bcharter school|school choice|\bvoucher\b|private school",
    "voting-rights":         r"\bvoting\b|\bvoter\b|\belection|\bballot\b|registration",
    "campaign-finance":      r"campaign finance|political contribution|\bPDC\b|disclosure of.{0,20}contribut",
    "economic-development":  r"economic development|\bincentive\b|tax preference|\bapprenticeship\b|workforce development",
    "ai-regulation":         r"artificial intelligence|\bAI\b|algorithm|automated decision",
    "data-centers":          r"data center",
    "misinformation":        r"misinformation|disinformation|content moderation|social media platform",
    "local-environment":     r"\bwetland\b|\briparian\b|tree canopy|\bhabitat\b|shoreline|\bsalmon\b|\bforest\b|water quality",
    "trans-athletes":        r"transgender|gender-affirming|\bgender identity\b",
    "religious-freedom":     r"religious|\bfaith\b|clergy",
    "redistricting":         r"redistrict|legislative district boundar",
}


def find(name_query):
    hits = [v for v in LINK.values() if name_query.lower() in v["name"].lower()]
    if len(hits) != 1:
        print(f"name '{name_query}' matched {len(hits)}: {[h['name'] for h in hits]}")
        sys.exit(1)
    return hits[0]


def main():
    show_all = "--all" in sys.argv
    m = find([a for a in sys.argv[1:] if not a.startswith("--")][0])
    mm = IDX["members"].get(m["memberId"], {"primary": [], "secondary": []})
    prim = [b for b in mm["primary"] if not PROC.match(b["billId"])]
    sec = [b for b in mm["secondary"] if not PROC.match(b["billId"])]

    print(f"{m['name']}  ({m['party']} LD{m['district']}, {m['chamber']})")
    print(f"  pid       {m['pid']}")
    print(f"  memberId  {m['memberId']}")
    print(f"  substantive: {len(prim)} primary, {len(sec)} co-sponsored\n")

    print(f"=== PRIMARY-SPONSORED ({len(prim)}) — strongest evidence, read these ===")
    for b in sorted(prim, key=lambda x: (not x["enacted"], x["billId"])):
        tag = "ENACTED" if b["enacted"] else "died   "
        topics = [k for k, pat in TOPIC_KEYS.items() if re.search(pat, b["desc"] + " " + b["long"], re.I)]
        t = ("  [" + ",".join(topics) + "]") if topics else ""
        print(f"  {tag} {b['billId']:10} {b['long'][:88]}{t}")

    print(f"\n=== CO-SPONSORED, bucketed by topic ({len(sec)} total) ===")
    for k, pat in TOPIC_KEYS.items():
        hits = [b for b in sec if re.search(pat, b["desc"] + " " + b["long"], re.I)]
        if not hits:
            continue
        en = sum(1 for b in hits if b["enacted"])
        print(f"  {k:28} {len(hits):3} bills ({en} enacted)")
        if show_all:
            for b in hits:
                print(f"        {'ENACTED' if b['enacted'] else 'died   '} {b['billId']:10} {b['long'][:80]}")


if __name__ == "__main__":
    main()
