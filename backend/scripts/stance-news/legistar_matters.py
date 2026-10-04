"""Harvest Charlotte Legistar matters + roll-call votes for stance-relevant topics.

Targeted, not exhaustive: search matter titles for topic terms, then pull each
matter's event items and per-member votes. Writes matters.json and votes.json.
"""
import json, os, sys, time, urllib.parse, urllib.request

BASE = "https://webapi.legistar.com/v1/charlottenc"
OUT = os.path.dirname(os.path.abspath(__file__))

TERMS = {
    "residential-zoning": ["Unified Development Ordinance", "Text Amendment"],
    "growth-and-development": ["Comprehensive Plan", "Annexation"],
    "housing": ["Housing Trust Fund", "Affordable Housing", "Housing Bond"],
    "rent-regulation": ["Tenant", "Eviction"],
    "homelessness": ["Homeless", "Encampment", "Shelter"],
    "public-safety-approach": ["Police", "Alternatives to Violence", "Violence Interrupt"],
    "local-immigration": ["Immigration", "Immigrant"],
    "transportation-priorities": ["Transit", "Mobility", "Bicycle", "Sidewalk", "Vision Zero"],
    "climate-change": ["Strategic Energy Action Plan", "Climate", "Solar", "Electric Vehicle"],
    "local-environment": ["Tree Ordinance", "Tree Canopy", "Stormwater"],
    "economic-development": ["Business Investment Grant", "Economic Development", "Incentive"],
    "data-centers": ["Data Center", "Moratorium"],
    "city-sanitation": ["Solid Waste", "Litter", "Sanitation"],
    "civil-rights": ["Nondiscrimination", "Non-Discrimination", "Equity"],
    "childcare": ["Child Care", "Childcare"],
    "cannabis-policy": ["Cannabis", "Marijuana", "Hemp"],
    "campaign-finance": ["Campaign Finance"],
    "jail-capacity": ["Detention", "Jail"],
    "gun-policy": ["Firearm", "Gun"],
    "minimum-wage": ["Minimum Wage", "Living Wage"],
    "ranked-choice-voting": ["Ranked Choice", "Election Method"],
}

MIN_DATE = "2021-01-01"


def get(path, params=None):
    url = BASE + path
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                raw = r.read()
                return json.loads(raw.decode("utf-8"))
        except Exception as e:  # noqa: BLE001
            if attempt == 2:
                print("FAIL", url, e, file=sys.stderr)
                return None
            time.sleep(2)
    return None


def main():
    seen = {}
    for topic, terms in TERMS.items():
        for term in terms:
            flt = "substringof('%s',MatterTitle) and MatterIntroDate gt datetime'%s'" % (
                term.replace("'", "''"), MIN_DATE)
            rows = get("/matters", {"$filter": flt, "$top": "200",
                                    "$orderby": "MatterIntroDate desc"})
            n = 0 if rows is None else len(rows)
            print("%-28s %-32s %s" % (topic, term, n))
            for m in rows or []:
                mid = m["MatterId"]
                rec = seen.setdefault(mid, {
                    "MatterId": mid, "MatterFile": m.get("MatterFile"),
                    "MatterTitle": m.get("MatterTitle"),
                    "MatterIntroDate": m.get("MatterIntroDate"),
                    "MatterPassedDate": m.get("MatterPassedDate"),
                    "MatterStatusName": m.get("MatterStatusName"),
                    "MatterTypeName": m.get("MatterTypeName"),
                    "topics": [], "terms": [],
                })
                if topic not in rec["topics"]:
                    rec["topics"].append(topic)
                if term not in rec["terms"]:
                    rec["terms"].append(term)
    with open(os.path.join(OUT, "matters.json"), "w", encoding="utf-8") as f:
        json.dump(list(seen.values()), f, indent=1)
    print("TOTAL MATTERS", len(seen))


if __name__ == "__main__":
    main()
