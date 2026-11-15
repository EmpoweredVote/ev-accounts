"""Turn an Open States state extract (from extract.py) into LegiScan-shaped dataset folders.

No LegiScan calls. The output has the same layout and field names as a LegiScan dataset ZIP, so the
Stage 5 scripts (scan_gun.py, build_skeletons_*.py, select_core_*.py) can read it unchanged:

    <out>/<ST>-<session_id>/<ST>/<Session_Name>/bill/<HB1240>.json   {"bill": {...}}
                                               /vote/<roll_call_id>.json {"roll_call": {...}}
                                               /people/<people_id>.json  {"person": {...}}
    <out>/<ST>-<session_id>/.openstates.json   (source, counts, warnings)

Usage:
    python3 -I convert.py <extract dir> [--out DIR] [--legiscan-root DIR] [--sessions 2017-2018,2019-2020]

Defaults: --out ../datasets-openstates, --legiscan-root ../datasets (only READ, to reuse real LegiScan
people_id values so existing idmap.tsv files keep working).

IDs. Open States uses UUIDs; LegiScan uses integers. Integers are assigned once and kept in
id_registry.json beside this file, so they stay the same on every re-run and every new month:
    session_id 900001+, bill_id / roll_call_id / doc_id 90000001+, people_id 9000001+.
A person who also appears in a local LegiScan people file for the same state (matched by the
legislature's member photo number, else by first+last name and chamber) keeps the real LegiScan
people_id instead.

What is different from a real LegiScan dataset (also written to .openstates.json):
  - doc_id values are ours: LegiScan's getBillText cannot fetch them. Download texts[].state_link
    (the legislature's own file) instead.
  - Vote marks: Open States only has yes / no / other for many states. "other" becomes NV (vote_id 3);
    "absent" / "excused" become Absent (vote_id 4) when the state provides them.
  - Committee votes are often missing (Open States scrapes mostly floor votes).
  - status is worked out from the bill's action types (1 introduced ... 6 failed).
  - Voters Open States left as a bare surname are matched to the session roster by chamber +
    surname + initial; any still unmatched get a "name only" person (listed in .openstates.json).
"""
import argparse, collections, csv, datetime, json, os, re, shutil, sys, unicodedata

csv.field_size_limit(10**9)
HERE = os.path.dirname(os.path.abspath(__file__))
ap = argparse.ArgumentParser()
ap.add_argument("extract")
ap.add_argument("--work", default=None, help="folder holding id_registry.json and name_overrides.json (default: the folder that holds extracts/)")
ap.add_argument("--out", default=None)
ap.add_argument("--legiscan-root", default=None)
ap.add_argument("--sessions", default="")
a = ap.parse_args()
X = os.path.abspath(a.extract)
# <work>/extracts/<YYYY-MM>/<st>: the work folder is three levels up from the extract
WORK = os.path.abspath(a.work) if a.work else os.path.dirname(os.path.dirname(os.path.dirname(X)))
if not os.path.exists(os.path.join(WORK, "id_registry.json")) and not os.environ.get("OPENSTATES_NEW_REGISTRY"):
    sys.exit(f"no id_registry.json in {WORK}: pass --work <the folder that holds it>. A new registry renumbers every bill, "
             "roll call and person; set OPENSTATES_NEW_REGISTRY=1 only for a first run.")
a.out = a.out or os.path.join(WORK, "..", "datasets-openstates")
a.legiscan_root = a.legiscan_root or os.path.join(WORK, "..", "datasets")
meta = json.load(open(os.path.join(X, "extract.json")))
ST = meta["state"].upper()
NULL = "\\N"


def rows(name):
    p = os.path.join(X, name + ".tsv")
    if not os.path.exists(p):
        return []
    out = []
    for r in csv.DictReader(open(p), delimiter="\t", quoting=csv.QUOTE_NONE):
        out.append({k: (None if v == NULL else v.replace("\\t", "\t").replace("\\n", "\n").replace("\\\\", "\\"))
                    for k, v in r.items()})
    return out


def pgarr(s):
    if not s or s == "{}":
        return []
    return [x.strip('"') for x in re.findall(r'"(?:[^"\\]|\\.)*"|[^,{}]+', s)]


norm = lambda s: re.sub(r"[^a-z]", "", unicodedata.normalize("NFD", s or "").encode("ascii", "ignore").decode().lower())

# ---------------- id registry ----------------
REG_PATH = os.path.join(WORK, "id_registry.json")
REG = json.load(open(REG_PATH)) if os.path.exists(REG_PATH) else {}
START = {"session": 900001, "bill": 90000001, "roll_call": 90000001, "doc": 90000001, "people": 9000001}


def rid(kind, key):
    d = REG.setdefault(kind, {})
    if key not in d:
        # only our own range counts: bridged real LegiScan ids live in the same dict and are smaller
        d[key] = max((v for v in d.values() if v >= START[kind]), default=START[kind] - 1) + 1
    return d[key]


# ---------------- load ----------------
sessions = {r["id"]: r for r in rows("legislativesession")}
want = set(filter(None, a.sessions.split(",")))
orgs = {r["id"]: r for r in rows("organization")}
posts = {r["id"]: r for r in rows("post")}
persons = {r["id"]: r for r in rows("person")}
bills = {r["id"]: r for r in rows("bill") if not want or sessions[r["legislative_session_id"]]["identifier"] in want}
by_bill = collections.defaultdict(lambda: collections.defaultdict(list))
for t in ("billabstract", "billaction", "billsource", "billsponsorship", "billversion"):
    for r in rows(t):
        if r["bill_id"] in bills:
            by_bill[r["bill_id"]][t].append(r)
links = collections.defaultdict(list)
for r in rows("billversionlink"):
    links[r["version_id"]].append(r)
events = {r["id"]: r for r in rows("voteevent") if r["bill_id"] in bills}
counts = collections.defaultdict(dict)
for r in rows("votecount"):
    if r["vote_event_id"] in events:
        counts[r["vote_event_id"]][r["option"]] = int(r["value"])
vsrc = collections.defaultdict(list)
for r in rows("votesource"):
    if r["vote_event_id"] in events:
        vsrc[r["vote_event_id"]].append(r["url"])
pvotes = collections.defaultdict(list)
for r in rows("personvote"):
    if r["vote_event_id"] in events:
        pvotes[r["vote_event_id"]].append(r)
# What a state's roll-call link says that its Open States rows get wrong or leave out (Utah, 2026-11-15):
#  - "chamber": Utah's rows are filed under the BILL's chamber (2019 on) or under the whole legislature (2017-18),
#    never the chamber that voted; the link's house=H|S is the chamber that voted.
#  - "committee": Utah's committee votes are filed under the chamber, with nothing in the motion to say so; they
#    are the mtgvotes.jsp links.
#  - "https": the older rows carry http:// links to a site that serves https.
SRC_RULES = {"UT": {"chamber": re.compile(r"[?&]house=([HS])\b"), "committee": re.compile(r"/mtgvotes\.jsp"), "https": True}}
RULES = SRC_RULES.get(ST, {})
if RULES.get("https"):
    for eid in vsrc:
        vsrc[eid] = [re.sub(r"^http://", "https://", u) for u in vsrc[eid]]
memberships = collections.defaultdict(list)
for r in rows("membership"):
    memberships[r["person_id"]].append(r)


def chamber_of(org_id):
    o = orgs.get(org_id)
    while o and o["classification"] not in ("upper", "lower", "legislature"):
        o = orgs.get(o["parent_id"])
    if not o:
        return None
    if o["classification"] == "upper":
        return "S"
    if o["classification"] == "lower":
        return "A" if "assembly" in o["name"].lower() else "H"
    return "L"  # unicameral


CH_NAME = {"H": "House", "A": "Assembly", "S": "Senate", "L": "Legislature"}


def event_chamber(eid):
    """The chamber that took the vote: from the roll call's own link where the state has a rule, else the row's."""
    m = RULES["chamber"].search((vsrc.get(eid) or [""])[0]) if RULES.get("chamber") else None
    return m.group(1) if m else chamber_of(events[eid]["organization_id"])


def event_committee_link(eid):
    return bool(RULES.get("committee") and RULES["committee"].search((vsrc.get(eid) or [""])[0]))


def seat(pid, sess):
    """(chamber, district label) the person held during the session, latest membership wins."""
    best = None
    s0, s1 = sess["start_date"] or "0000", sess["end_date"] or "9999"
    for m in memberships.get(pid, []):
        ch = chamber_of(m["organization_id"])
        if ch not in ("H", "A", "S", "L") or orgs[m["organization_id"]]["classification"] == "committee":
            continue
        a0, a1 = m["start_date"] or "0000", m["end_date"] or "9999"
        if a0 <= s1 and a1 >= s0:
            lab = posts.get(m["post_id"], {}).get("label") if m["post_id"] else None
            if best is None or a0 >= best[2]:
                best = (ch, lab, a0)
    return best


# ---------------- roster for name-only voters ----------------
# Open States drops chamber memberships of many former members, so the roster for a session+chamber is
# the union of: memberships overlapping the session, people linked as voters there, and people linked as
# sponsors of bills from that chamber.
roster = collections.defaultdict(set)   # (session_id, chamber) -> {person_id}; memberships + voters (strong)
roster_sp = collections.defaultdict(set)  # plus sponsors (weaker: sponsor rows can cross chambers)
for pid, ms in memberships.items():
    for m in ms:
        ch = chamber_of(m["organization_id"])
        if ch not in ("H", "A", "S", "L") or orgs[m["organization_id"]]["classification"] == "committee":
            continue
        for sid, s in sessions.items():
            if (m["start_date"] or "0000") <= (s["end_date"] or "9999") and (m["end_date"] or "9999") >= (s["start_date"] or "0000"):
                roster[(sid, ch)].add(pid)
learned = collections.defaultdict(collections.Counter)
# The same printed label in the same chamber across sessions: (chamber, label) -> session -> linked people / seen.
label_links = collections.defaultdict(lambda: collections.defaultdict(set))
label_seen = collections.defaultdict(set)
for eid, e in events.items():
    if event_committee_link(eid):
        continue  # a committee's members can sit in either chamber: it teaches nothing about a chamber's labels
    ch = event_chamber(eid)
    for v in pvotes[eid]:
        label_seen[(ch, v["voter_name"])].add(e["legislative_session_id"])
        if v["voter_id"]:
            learned[(e["legislative_session_id"], ch, v["voter_name"])][v["voter_id"]] += 1
            label_links[(ch, v["voter_name"])][e["legislative_session_id"]].add(v["voter_id"])
            roster[(e["legislative_session_id"], ch)].add(v["voter_id"])
REGULAR = sorted((s for s in sessions.values() if "special" not in (s["classification"] or "")), key=lambda s: s["start_date"] or s["identifier"])


def bridge(sid, ch, name):
    """The one person this printed label is linked to in other sessions of the same chamber, when the label runs
    without a break from this session to a linked one. Utah 2017-2020 rows link no voter at all; 2021 on link
    nearly all, under the same labels ("Snider, C."). A label that is missing from a regular session in between
    may be a different member of the same surname and initial, and is not bridged."""
    links = label_links.get((ch, name))
    if not links:
        return None
    ppl = set().union(*links.values())
    if len(ppl) != 1:
        return None
    when = lambda s: sessions[s]["start_date"] or sessions[s]["identifier"]
    here = when(sid)
    near = min(links, key=lambda s: abs(int(when(s)[:4]) - int(here[:4])) if when(s)[:4].isdigit() and here[:4].isdigit() else 99)
    lo, hi = sorted((here, when(near)))
    for s in REGULAR:
        if lo < when(s["id"]) < hi and s["id"] not in label_seen[(ch, name)]:
            return None
    return next(iter(ppl))
for bid, b in bills.items():
    for sp in by_bill[bid]["billsponsorship"]:
        if sp["person_id"] and sp["entity_type"] == "person":
            roster_sp[(b["legislative_session_id"], chamber_of(b["from_organization_id"]))].add(sp["person_id"])
for k, v in roster.items():
    roster_sp[k] |= v


# Hand-checked fixes for names the rules above cannot settle: "<ST>:<session>:<chamber>:<voter name>" -> person id
OVR_PATH = os.path.join(WORK, "name_overrides.json")
OVR = {k: v for k, v in (json.load(open(OVR_PATH)) if os.path.exists(OVR_PATH) else {}).items() if not k.startswith("_")}


BRIDGED = {}
SPEAKER = re.compile(r"^\s*(?:mr\.?|madame?|madam)\s+speaker\s+", re.I)   # TN: "Mr. Speaker McNally"


def seated_in(pid, sid, ch):
    """True / False when a membership says which chamber pid sat in during the session; None when unknown."""
    s = seat(pid, sessions[sid])
    if not s or ch not in ("H", "A", "S"):
        return None
    return s[0] == ch


def resolve(sid, ch, name):
    o = OVR.get(f"{ST}:{sessions[sid]['identifier']}:{ch}:{name}")
    if o:
        return o
    c = learned.get((sid, ch, name))
    if c and len(c) == 1 and seated_in(next(iter(c)), sid, ch) is not False:
        return next(iter(c))
    b = bridge(sid, ch, name)
    if b and seated_in(b, sid, ch) is not False:
        BRIDGED[(sessions[sid]["identifier"], ch, name)] = b
        return b
    name = SPEAKER.sub("", name or "")
    m = re.match(r"\s*([A-Za-z])\.\s*(\S.*?)\s*$", name)          # "C. Wilson"
    if m:
        sur, ini = norm(m.group(2)), norm(m.group(1))
    else:
        m = (re.match(r"\s*(\S.*?)\s+([A-Za-z])\.?\s*$", name)       # TN: "White M." / "Sexton J"
             or re.match(r"\s*([^,]+?)\s*,\s*([A-Za-z])[^,]*$", name)          # UT: "Acton, C.K." / "Adams, J. Stuart"
             or re.match(r"\s*([^,]+?)\s*(?:,\s*([A-Za-z]+)\.?)?\s*$", name))  # "Wilson" / "Wilson, C."
        if not m:
            return None
        sur, ini = norm(m.group(1)), norm(m.group(2) or "")
    for ros in (roster, roster_sp):
        cand = [p for p in ros.get((sid, ch), []) if p in persons and norm(persons[p]["family_name"] or persons[p]["name"].split()[-1]) == sur
                and (not ini or norm(persons[p]["given_name"] or persons[p]["name"]).startswith(ini))]
        if len(cand) > 1:
            # Open States links a few votes to a namesake in the other chamber (TN 113: Senate "White" ->
            # Rep. Mark White), which puts both namesakes in the roster. A membership in this chamber settles it.
            seated = [p for p in cand if seated_in(p, sid, ch)]
            if len(seated) == 1:
                return seated[0]
            cand = [p for p in cand if seated_in(p, sid, ch) is not False]
        if len(cand) == 1:
            return cand[0]
        if len(cand) > 1:
            break
    # full-name form ("Jane Doe")
    cand = [p for p in roster.get((sid, ch), []) if p in persons and norm(persons[p]["name"]) == norm(name)]
    return cand[0] if len(cand) == 1 else None


# ---------------- LegiScan people bridge (read-only) ----------------
PHOTO = re.compile(r"(?:memberphoto/|[?&]m=)(\d+)")
ls_photo, ls_name = {}, collections.defaultdict(set)
import glob
for f in glob.glob(os.path.join(a.legiscan_root, f"{ST}-*", "*", "*", "people", "*.json")):
    try:
        p = json.load(open(f))["person"]
    except Exception:
        continue
    img = (p.get("bio") or {}).get("social", {}).get("image", "")
    m = PHOTO.search(img or "")
    if m:
        ls_photo[m.group(1)] = p["people_id"]
    for fn in {p.get("first_name"), p.get("nickname")} - {None, ""}:
        ls_name[(norm(p["last_name"]), norm(fn), "S" if p.get("role") == "Sen" else "H")].add(p["people_id"])


def people_id_for(pid, ch):
    key = f"person:{pid}"
    if key in REG.get("people", {}):
        return REG["people"][key]
    p = persons[pid]
    m = PHOTO.search(p["image"] or "")
    lsid = ls_photo.get(m.group(1)) if m else None
    if not lsid:
        c = ls_name.get((norm(p["family_name"]), norm(p["given_name"]), "S" if ch == "S" else "H"), set())
        lsid = next(iter(c)) if len(c) == 1 else None
    if lsid:
        REG.setdefault("people", {})[key] = lsid
        REG.setdefault("people_bridged", {})[key] = lsid
        return lsid
    return rid("people", key)




def person_json(pid, sess, ch_hint):
    p = persons[pid]
    st_ = seat(pid, sess) or (ch_hint, None, "")
    ch, lab = st_[0], st_[1]
    dist = ""
    if lab:
        dist = (f"{'SD' if ch == 'S' else 'HD'}-{int(lab):03d}" if lab.isdigit() else f"{'SD' if ch == 'S' else 'HD'}-{lab}")
    party, party_id = "", "0"  # no Stage 5 tool reads a party, so none is written
    first = p["given_name"] or (p["name"].split()[0] if p["name"] else "")
    last = p["family_name"] or (p["name"].split()[-1] if p["name"] else "")
    return {"people_id": people_id_for(pid, ch), "person_hash": "", "party_id": party_id, "state_id": 0, "party": party,
            "role_id": 2 if ch == "S" else 1, "role": "Sen" if ch == "S" else "Rep", "name": p["name"],
            "first_name": first, "middle_name": "", "last_name": last, "suffix": "", "nickname": "",
            "district": dist, "ftm_eid": 0, "votesmart_id": 0, "opensecrets_id": "", "knowwho_pid": 0,
            "ballotpedia": "", "bioguide_id": "", "committee_sponsor": 0, "committee_id": 0, "state_federal": 0,
            "bio": {"social": {"image": p["image"] or ""}},
            "_openstates": {"person_id": pid, "image": p["image"] or "", "email": p.get("email") or ""}}


def name_only_json(name, ch, key):
    parts = (name or "").replace(",", " ").split()
    return {"people_id": rid("people", key), "person_hash": "", "party_id": "0", "state_id": 0, "party": "",
            "role_id": 2 if ch == "S" else 1, "role": "Sen" if ch == "S" else "Rep", "name": name,
            "first_name": "", "middle_name": "", "last_name": parts[0] if parts else name, "suffix": "", "nickname": "",
            "district": "", "ftm_eid": 0, "votesmart_id": 0, "opensecrets_id": "", "knowwho_pid": 0, "ballotpedia": "",
            "bioguide_id": "", "committee_sponsor": 0, "committee_id": 0, "state_federal": 0,
            "_openstates": {"person_id": None, "name_only": True}}


# ---------------- mapping helpers ----------------
BTYPE = {"bill": "B", "resolution": "R", "concurrent resolution": "CR", "joint resolution": "JR",
         "constitutional amendment": "CA", "memorial": "M", "joint memorial": "JM", "concurrent memorial": "CM",
         "proclamation": "P", "appointment": "A"}
VOPT = {"yes": (1, "Yea"), "no": (2, "Nay"), "absent": (4, "Absent"), "excused": (4, "Absent")}


def text_type(note):
    n = (note or "").lower()
    if "session law" in n or "chapter" in n:
        return "Chaptered"
    if "passed legislature" in n or "enrolled" in n:
        return "Enrolled"
    if "engrossed" in n:
        return "Engrossed"
    if "amend" in n:
        return "Amended"
    if "substitute" in n:
        return "Comm Sub"
    return "Introduced"


COMMITTEE_MOTION = re.compile(r"^[^:]*COMMITTEE[^:]*:", re.I)
TRANK = {"Introduced": 0, "Comm Sub": 1, "Amended": 2, "Engrossed": 3, "Enrolled": 4, "Chaptered": 5}


PASS_TXT = re.compile(r"^(third reading,? (and final passage,? )?passed|final passage|passed|adopted)", re.I)
LAW_TXT = re.compile(r"^(governor signed|filed with secretary of state|chapter \d+|effective date)", re.I)


def status_of(actions, btype):
    """LegiScan status: 1 introduced, 2 engrossed (passed one chamber), 3 enrolled (passed both),
    4 passed/law (or a one-chamber resolution adopted), 5 vetoed, 6 failed."""
    st, dt, passed_ch = 1, None, set()
    for ac in sorted(actions, key=lambda r: (r["date"] or "", int(r["order"] or 0))):
        cls = set(pgarr(ac["classification"]))
        d = (ac["date"] or "")[:10]
        txt = (ac["description"] or "").strip()
        if "passage" in cls or PASS_TXT.match(txt):
            passed_ch.add(chamber_of(ac["organization_id"]) or ac["organization_id"])
            new = 4 if btype == "R" else (3 if len(passed_ch) >= 2 else 2)
            if new > st and st < 4:
                st, dt = new, d
        if cls & {"executive-signature", "became-law", "veto-override-passage"} or LAW_TXT.match(txt):
            st, dt = 4, d
        elif "executive-veto" in cls and st != 4:
            st, dt = 5, d
        elif cls & {"failure", "withdrawal"} and st < 4:
            st, dt = 6, d
    return st, dt


# LegiScan zero-pads some states' bill numbers (TN "HB0001"); Open States does not ("HB 1").
# Pad to match, so bill files and bill_number keys line up with LegiScan copies of the same session.
PAD = {"TN": 4}


def bnum(ident):
    n = re.sub(r"\s+", "", ident)
    if re.fullmatch(r"(?:[A-Z]\.)+\d+", n):
        n = n.replace(".", "")  # Utah to 2024: "H.B. 346", "S.J.R. 2"
    if ST in PAD:
        n = re.sub(r"^([A-Z]+)(\d+)$", lambda m: m.group(1) + m.group(2).zfill(PAD[ST]), n)
    return n


# ---------------- build ----------------
now = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")
by_sess = collections.defaultdict(list)
for bid, b in bills.items():
    by_sess[b["legislative_session_id"]].append(bid)
ev_by_bill = collections.defaultdict(list)
for eid, e in events.items():
    ev_by_bill[e["bill_id"]].append(eid)

for sid, bids in sorted(by_sess.items(), key=lambda kv: sessions[kv[0]]["identifier"]):
    sess = sessions[sid]
    ident = sess["identifier"]
    lsid = rid("session", f"{ST}:{ident}")
    # WA identifiers are years ("2025-2026"); TN's are numbers ("114", "111S1"), so fall back to the
    # years in the name ("114th Regular Session (2025-2026)", "... (August 2019)"), then the dates
    # (TN 106 has empty start and end dates).
    yrs = (re.findall(r"\d{4}", ident) or re.findall(r"\b(?:19|20)\d{2}\b", sess["name"] or "")
           or [d[:4] for d in (sess["start_date"], sess["end_date"]) if d])
    y0, y1 = int(yrs[0]), int(yrs[-1])
    special = 1 if ("special" in (sess["classification"] or "") or "special" in sess["name"].lower()) else 0
    sname = sess["name"]
    sess_obj = {"session_id": lsid, "state_id": 0, "year_start": y0, "year_end": y1, "prefile": 0, "sine_die": 0,
                "prior": 0, "special": special, "session_tag": "Special Session" if special else "Regular Session",
                "session_title": sname, "session_name": sname}
    root = os.path.join(a.out, f"{ST}-{lsid}")
    if os.path.exists(root):
        shutil.rmtree(root)
    base = os.path.join(root, ST, re.sub(r"[^\w-]+", "_", sname).strip("_"))
    for d in ("bill", "vote", "people"):
        os.makedirs(os.path.join(base, d))
    people_out, name_only, stats = {}, collections.Counter(), collections.Counter()
    vch = collections.defaultdict(collections.Counter)  # people_id -> chamber counts from roll calls

    def person_for(pid, name, ch, vote=False):
        if pid and vote and seated_in(pid, sid, ch) is False:
            # a roll-call link to someone seated in the other chamber is wrong (TN 113); match by name instead
            stats["voter_link_other_chamber_redone"] += 1
            pid = None
        if not pid:
            pid = resolve(sid, ch, name)
            if not pid and not vote:
                # A sponsor row or a committee vote carries the BILL's chamber, not the member's (Utah: a Senate
                # floor sponsor of a House bill; a senator on a joint committee). Look in the other chambers, and
                # take the person only when exactly one fits across all of them.
                other = {resolve(sid, c, name) for c in ("H", "A", "S") if c != ch} - {None}
                if len(other) == 1:
                    pid = next(iter(other))
                    stats["name_resolved_in_other_chamber"] += 1
            if pid:
                stats["name_only_resolved"] += 1
        if pid and pid in persons:
            pj = person_json(pid, sess, ch)
        else:
            name_only[f"{CH_NAME.get(ch, ch)}: {name}"] += 1
            pj = name_only_json(name, ch, f"name:{ST}:{ident}:{ch}:{name}")
        people_out.setdefault(pj["people_id"], pj)
        return pj

    for bid in bids:
        b = bills[bid]
        ex = by_bill[bid]
        num = bnum(b["identifier"])
        if RULES.get("https"):
            for r in ex["billsource"]:
                r["url"] = re.sub(r"^http://", "https://", r["url"])
        bill_id = rid("bill", bid)
        body = chamber_of(b["from_organization_id"]) or (num[:1] if num[:1] in "HSA" else "")
        cls = pgarr(b["classification"])
        btype = next((BTYPE[c] for c in cls if c in BTYPE), (cls[0][:1].upper() if cls else "B"))
        st_, st_date = status_of(ex["billaction"], btype)
        src = [r["url"] for r in ex["billsource"]]
        sponsors = []
        sp_rows = sorted(ex["billsponsorship"], key=lambda r: 0 if r["primary"] == "t" else 1)
        for i, sp in enumerate(sp_rows, 1):
            if sp["entity_type"] == "organization":
                sponsors.append({"people_id": 0, "name": sp["name"], "first_name": "", "last_name": "",
                                 "sponsor_type_id": 1 if sp["primary"] == "t" else 2, "sponsor_order": i,
                                 "committee_sponsor": 1, "committee_id": 0, "role": "", "district": "", "party": ""})
                continue
            pj = person_for(sp["person_id"], sp["name"], body)
            sponsors.append(dict(pj, sponsor_type_id=1 if sp["primary"] == "t" else 2, sponsor_order=i,
                                 committee_sponsor=0, committee_id=0))
        texts = []
        for v in ex["billversion"]:
            ls = links[v["id"]]
            pdf = [l["url"] for l in ls if "pdf" in (l["media_type"] or "")]
            other = [l for l in ls if "pdf" not in (l["media_type"] or "")]
            main = pdf[0] if pdf else (other[0]["url"] if other else "")
            if not main:
                continue
            t = text_type(v["note"])
            texts.append({"doc_id": rid("doc", v["id"]), "date": (v["date"] or "")[:10], "type": t, "type_id": 0,
                          "mime": "application/pdf" if pdf else (other[0]["media_type"] or ""), "mime_id": 0,
                          "url": main, "state_link": main, "text_size": 0, "text_hash": "",
                          "alt_bill_text": 1 if (pdf and other) else 0,
                          "alt_mime": other[0]["media_type"] if (pdf and other) else "", "alt_mime_id": 0,
                          "alt_state_link": other[0]["url"] if (pdf and other) else "", "alt_text_size": 0,
                          "alt_text_hash": "", "_os_note": v["note"]})
        texts.sort(key=lambda t: (TRANK.get(t["type"], 0), t["date"]))
        history = [{"date": (r["date"] or "")[:10], "action": r["description"], "chamber": chamber_of(r["organization_id"]) or "",
                    "chamber_id": 0, "importance": 1 if pgarr(r["classification"]) else 0}
                   for r in sorted(ex["billaction"], key=lambda r: (r["date"] or "", int(r["order"] or 0)))]
        bvotes = []
        for eid in sorted(ev_by_bill[bid], key=lambda e: (events[e]["start_date"] or "", int(events[e]["order"] or 0))):
            e = events[eid]
            ch = event_chamber(eid)
            org = orgs.get(e["organization_id"], {})
            # TN files committee votes under the chamber, with the committee named before a colon in the motion
            # ("HOUSE JUDICIARY COMMITTEE: ..."); floor votes read "FLOOR VOTE: ...".
            committee = (org.get("classification") == "committee" or bool(COMMITTEE_MOTION.match(e["motion_text"] or ""))
                         or event_committee_link(eid))
            rc_id = rid("roll_call", eid)
            mv, tally = [], collections.Counter()
            for v in pvotes[eid]:
                # a committee vote says nothing about the member's chamber (a joint committee seats both)
                pj = person_for(v["voter_id"], v["voter_name"], ch, vote=not committee)
                if not committee:
                    vch[pj["people_id"]][ch] += 1
                vid, vt = VOPT.get(v["option"], (3, "NV"))
                tally[vid] += 1
                mv.append({"people_id": pj["people_id"], "vote_id": vid, "vote_text": vt})
            c = counts[eid]
            yea = tally[1] if mv else c.get("yes", 0)
            nay = tally[2] if mv else c.get("no", 0)
            nv = tally[3] if mv else sum(v for k, v in c.items() if k not in ("yes", "no", "absent", "excused"))
            ab = tally[4] if mv else c.get("absent", 0) + c.get("excused", 0)
            desc = (f"{CH_NAME.get(ch, '')} Committee {org.get('name', '')}: " if committee and org.get("classification") == "committee"
                    else f"{CH_NAME.get(ch, '')} Committee: " if committee else f"{CH_NAME.get(ch, '')} ") + (e["motion_text"] or "")
            rc = {"roll_call_id": rc_id, "bill_id": bill_id, "date": (e["start_date"] or "")[:10], "desc": desc.strip(),
                  "yea": yea, "nay": nay, "nv": nv, "absent": ab, "total": yea + nay + nv + ab,
                  "passed": 1 if e["result"] == "pass" else 0, "chamber": ch or "", "chamber_id": 0,
                  "url": (vsrc[eid] or [""])[0], "state_link": (vsrc[eid] or [""])[0], "votes": mv,
                  "_openstates": {"vote_event_id": eid, "counts": c, "committee": committee}}
            if mv and (c.get("yes") is not None) and (c.get("yes") != yea or c.get("no") != nay):
                stats["rollcalls_count_mismatch"] += 1
            json.dump({"roll_call": rc}, open(os.path.join(base, "vote", f"{rc_id}.json"), "w"), ensure_ascii=False)
            bvotes.append({k: rc[k] for k in ("roll_call_id", "date", "desc", "yea", "nay", "nv", "absent", "total",
                                              "passed", "chamber", "chamber_id", "url", "state_link")})
            stats["rollcalls"] += 1
            stats["committee_rollcalls"] += committee
            stats["member_votes"] += len(mv)
        abstract = next((r["abstract"] for r in ex["billabstract"]), None)
        bill = {"bill_id": bill_id, "change_hash": "", "session_id": lsid, "session": sess_obj,
                "url": f"https://open.pluralpolicy.com/{ST.lower()}/bills/{ident}/{num}/",
                "state_link": src[0] if src else "", "completed": 1 if st_ in (4, 5, 6) else 0,
                "status": st_, "status_date": st_date or "", "progress": [], "state": ST, "state_id": 0,
                "bill_number": num, "bill_type": btype,
                "bill_type_id": 0, "body": body, "body_id": 0, "current_body": body, "current_body_id": 0,
                "title": b["title"], "description": abstract or b["title"], "pending_committee_id": 0,
                "committee": [], "referrals": [], "history": history, "sponsors": sponsors, "sasts": [],
                "subjects": [{"subject_id": 0, "subject_name": s} for s in pgarr(b["subject"])],
                "texts": texts, "votes": bvotes, "amendments": [], "supplements": [], "calendar": [],
                "_openstates": {"bill_id": bid, "sources": src}}
        json.dump({"bill": bill}, open(os.path.join(base, "bill", f"{num}.json"), "w"), ensure_ascii=False)
        stats["bills"] += 1
        stats["sponsorships"] += len(sponsors)
        stats["text_docs"] += len(texts)
    for pid_, pj in people_out.items():
        # Open States seat history can be wrong for former members; trust the chamber they voted in.
        if vch[pid_]:
            vc = vch[pid_].most_common(1)[0][0]
            if ("S" if vc == "S" else "H") != ("S" if pj["role"] == "Sen" else "H"):
                pj.update(role="Sen" if vc == "S" else "Rep", role_id=2 if vc == "S" else 1, district="")
                stats["role_fixed_from_votes"] += 1
        json.dump({"person": pj}, open(os.path.join(base, "people", f"{pid_}.json"), "w"), ensure_ascii=False)
    stats["people"] = len(people_out)
    stats["people_with_legiscan_id"] = sum(1 for p in people_out if p < START["people"])
    marker = {"source": "Open States monthly dump (public domain)", "dump": meta["dump"], "extracted_at": meta["extracted_at"],
              "converted_at": now, "state": ST, "openstates_session": ident, "session_id": lsid, "synthetic_ids": True,
              "counts": dict(stats), "name_only_voters_unmatched": dict(name_only),
              "labels_bridged_from_other_sessions": {f"{CH_NAME.get(c, c)}: {n}": persons[p]["name"] for (s_, c, n), p in sorted(BRIDGED.items()) if s_ == ident},
              "warnings": ["Not a LegiScan dataset. doc_id values cannot be used with LegiScan getBillText; fetch texts[].state_link.",
                           "people_id below 9000001 are real LegiScan ids (bridged); others are ours.",
                           "Vote mark 'other' is shown as NV; check absent/excused against the state's journal if it matters.",
                           "Committee votes may be missing."]}
    json.dump(marker, open(os.path.join(root, ".openstates.json"), "w"), indent=1, ensure_ascii=False)
    print(f"{ST}-{lsid} {ident}: " + ", ".join(f"{k} {v}" for k, v in stats.items())
          + (f"; unmatched name-only voters {sum(name_only.values())}" if name_only else ""), flush=True)

json.dump(REG, open(REG_PATH, "w"), indent=0, sort_keys=True)
