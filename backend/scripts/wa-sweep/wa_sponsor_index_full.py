# Full WA sponsorship index: ALL introduced legislation, 2025-26 biennium.
#
# WHY NOT ENACTED-ONLY: in a chamber the majority controls, minority-party members get almost
# nothing enacted. An enacted-only index yields rich records for the majority and near-empty ones
# for the minority, which biases WHO ends up with stances. Sponsorship of a bill that died still
# evidences a position.
#
# Resumable: per-bill JSON cache shared with the enacted-only run.
import json, os, re, time, urllib.parse, urllib.request
import xml.etree.ElementTree as ET

BIENNIUM = "2025-26"
YEARS = ["2025", "2026"]
BASE = "https://wslwebservices.leg.wa.gov/LegislationService.asmx"
CACHE = os.path.join(os.environ["TEMP"], "ev-stance-cache", "wa-leg")
BILLS = os.path.join(CACHE, "bills")
os.makedirs(BILLS, exist_ok=True)
NS = {"w": "http://WSLWebServices.leg.wa.gov/"}

# longest-first so SCR matches before SR, HJR before HR
BASE_TYPES = ["HCR", "SCR", "HJM", "SJM", "HJR", "SJR", "HB", "SB", "HR", "SR", "HI", "SI"]


def get(path, **params):
    url = BASE + "/" + path + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=45) as r:
                return r.read()
        except Exception:
            if attempt == 3:
                raise
            time.sleep(1.5 * (attempt + 1))


def txt(node, tag):
    el = node.find("w:" + tag, NS)
    return (el.text or "").strip() if el is not None and el.text else ""


def normalize(bill_id):
    """'2ESHB 1210' -> 'HB 1210'.  Strips engrossed/substitute prefixes."""
    m = re.match(r"^([A-Z0-9]+)\s+(\d+)$", bill_id.strip())
    if not m:
        return None
    prefix, num = m.group(1), m.group(2)
    for t in BASE_TYPES:
        if prefix.endswith(t):
            return f"{t} {num}"
    return None


def collect_bill_ids():
    ids = set()
    for y in YEARS:
        p = os.path.join(CACHE, f"year-{y}.xml")
        if not os.path.exists(p):
            open(p, "wb").write(get("GetLegislationByYear", year=y))
        root = ET.parse(p).getroot()
        for e in root.findall(".//w:BillId", NS):
            if e.text:
                n = normalize(e.text)
                if n:
                    ids.add(n)
    return sorted(ids)


def enacted_set():
    p = os.path.join(CACHE, "passed.xml")
    if not os.path.exists(p):
        open(p, "wb").write(get("GetLegislationPassedLegislature", biennium=BIENNIUM))
    root = ET.parse(p).getroot()
    out = set()
    for i in root.findall(".//w:LegislationInfo", NS):
        n = normalize(txt(i, "BillId"))
        if n:
            out.add(n)
    return out


def fetch_bill(bill_id):
    safe = bill_id.replace(" ", "_")
    cp = os.path.join(BILLS, safe + ".json")
    if os.path.exists(cp):
        try:
            rec = json.load(open(cp, encoding="utf-8"))
            if "sponsors" in rec:
                return rec
        except Exception:
            pass

    num = bill_id.split()[1]
    rec = {"billId": bill_id, "billNumber": num}
    try:
        root = ET.fromstring(get("GetLegislation", biennium=BIENNIUM, billNumber=num))
        legs = root.findall(".//w:Legislation", NS)
        pick = None
        for L in legs:
            if txt(L, "BillId") == bill_id:
                pick = L
                break
        pick = pick if pick is not None else (legs[0] if legs else None)
        if pick is not None:
            rec["shortDescription"] = txt(pick, "ShortDescription")
            rec["longDescription"] = txt(pick, "LongDescription")
            rec["primeSponsorId"] = txt(pick, "PrimeSponsorID")
            rec["currentStatus"] = txt(pick, "CurrentStatus")
    except Exception as e:
        rec["descError"] = str(e)

    try:
        root = ET.fromstring(get("GetSponsors", biennium=BIENNIUM, billId=bill_id))
        rec["sponsors"] = [{
            "id": txt(s, "Id"), "name": txt(s, "Name"),
            "agency": txt(s, "Agency"), "type": txt(s, "Type"), "order": txt(s, "Order"),
        } for s in root.findall(".//w:Sponsor", NS)]
    except Exception as e:
        rec["sponsorError"] = str(e)
        rec["sponsors"] = []

    json.dump(rec, open(cp, "w", encoding="utf-8"), ensure_ascii=False)
    return rec


def main():
    ids = collect_bill_ids()
    enacted = enacted_set()
    print(f"base bills to index: {len(ids)}  (enacted among them: {len(enacted)})", flush=True)

    recs = []
    for n, b in enumerate(ids, 1):
        recs.append(fetch_bill(b))
        if n % 200 == 0:
            print(f"  {n}/{len(ids)}", flush=True)
        time.sleep(0.05)

    by_member = {}
    for r in recs:
        seen = set()
        for s in r.get("sponsors", []):
            if not s["id"] or s["id"] in seen:
                continue
            seen.add(s["id"])
            m = by_member.setdefault(s["id"], {
                "id": s["id"], "name": s["name"], "agency": s["agency"],
                "primary": [], "secondary": [],
            })
            entry = {
                "billId": r["billId"],
                "desc": r.get("shortDescription", ""),
                "long": r.get("longDescription", ""),
                "enacted": r["billId"] in enacted,
            }
            (m["primary"] if s["type"] == "Primary" else m["secondary"]).append(entry)

    # committees are sponsors too; they are not members
    committees = [k for k, v in by_member.items()
                  if not re.search(r"\s", v["name"]) is None and v["name"] in
                  ("Appropriations", "Ways & Means", "Transportation", "Finance", "Rules")]

    out = {"biennium": BIENNIUM, "billCount": len(recs), "members": by_member}
    dest = os.path.join(CACHE, "sponsorship-index-full.json")
    json.dump(out, open(dest, "w", encoding="utf-8"), ensure_ascii=False)

    errs = sum(1 for r in recs if r.get("sponsorError") or r.get("descError"))
    print(f"wrote {dest}")
    print(f"sponsor entities: {len(by_member)}  bills: {len(recs)}  errors: {errs}")
    # party-balance sanity check
    tot = sorted(((len(v["primary"]) + len(v["secondary"]), v["name"]) for v in by_member.values()),
                 reverse=True)
    print("top 5:", tot[:5])
    print("bottom 5:", tot[-5:])


if __name__ == "__main__":
    main()
