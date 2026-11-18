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
import argparse, collections, csv, datetime, glob, hashlib, json, os, re, shutil, sys, unicodedata

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
#  - "oh_votes_page" (Ohio, 2026-11-16): the rows' addresses (search-prod.lis.state.oh.us/solarapi/v1/...) are dead
#    (404). The same record is the bill's Votes page at www.legislature.ohio.gov, which holds every vote of the bill;
#    the address names one vote by its session day, chamber and tally after a #, and the verifier reads that vote
#    from the page and the legislature's data (src/lib/stateRollCallEvidence.ts). Committee votes are the
#    .../cmtevotes rows; from the 136th the address is the bill's action list for every vote, and a committee vote
#    is told by its motion: "Reported..." classed committee-passage (a conference report is classed so too, and is
#    the chamber's floor vote). The dump holds most Ohio votes two to four times over (the same vote scraped again under
#    a new key: 135 HB 33's House passage, 78-19, three times): each vote is kept once.
#  - "sd_record_is_the_floor" (South Dakota, 2026-11-17): the rows cannot tell a committee's vote from the chamber's
#    (sdlegislature.gov/api/Votes/83164, House Taxation, is filed under the House with the motion "Do Pass", as the
#    floor vote is), and 2018 files every vote under the whole legislature. Only the legislature's record says which
#    vote is a floor vote, in which chamber, on what question. So a South Dakota roll call is placed only when it was
#    read from the record (fetch-legislature-rollcalls.ts, every bill the scan finds): the record's copy replaces the
#    dump's, and every other dump row is kept as not placed (marked committee, so no step maps it). The dump's own
#    copy of a record vote still teaches convert.py which person a label is (Open States links most voters from 2021).
#    The addresses (/api/Votes/<id>, /Legislative_Session/Bills/RollCall.aspx?Vote=<id>&Session=2018) become the
#    vote's own page, /Session/Vote/<id>, which is cited; the verifier reads /api/Votes/<id> for it.
#  - "sd_sponsors_from_text" (South Dakota, runner 2026-11-17): the dump marks every sponsor primary, and the bill page
#    it cites (/Session/Bill/<id>) is a script shell. For a bill whose sponsors the fetch read (supplements 'sponsors'),
#    the bill's page becomes its introduced text (a PDF that prints "Introduced by: ..."), and its sponsors are the
#    record's members THAT TEXT NAMES, prime or co-sponsor as the record says. From 2021 the text names only the lead
#    sponsor (2018 and 2019 name all, 2020 some): the others have no page a person can read, and are left out and counted (sd_sponsors_not_named_on_the_text).
#  - Mississippi (2026-11-17): "ms_vote_page": each vote's address (/<session>/pdf/votes/<house|senate>/<NNNNNNN>.pdf, a
#    PDF a person can open) is cited with the bill after a # (one PDF can carry several bills), which is the form the
#    reader reads (stateRollCallEvidence.ts). "record_is_the_floor", as South Dakota's: the dump's member lists are
#    misread from the PDFs' prose ("B (122nd)", "Absent or those Bell (21st)", "Yeas--Barnett"), so no dump vote is
#    placed; only votes read from the record are. "ms_full_names": the record names each member in full, from the
#    session's member list ("Robert L. Jackson", "Sam Creekmore IV"); ms_resolve links such a name to one person.
#  - Maryland (2026-11-18): "md_vote_page": each vote's address becomes the form the reader reads
#    (stateRollCallEvidence.ts), https://mgaleg.maryland.gov/<year>RS/votes/<house|senate>/<NNNN>.pdf#<bill> (a consent
#    calendar is one vote on several bills). 2017's rows carry the old page (webmga/frmMain.aspx?pid=flrvotepage&id=
#    hb0760,h-0501&ys=2017RS), which is gone; the same vote is /2017RS/votes/house/0501.htm. "chamber": 2017's rows are
#    filed under the whole legislature; the address says which chamber voted. "md_bill_page": the old bill page
#    (webmga/frmMain.aspx?id=HB22&pid=billpage&ys=2019rs) is gone; the same bill is /mgawebsite/Legislation/Details/
#    hb0022?ys=2019RS. "https_texts": the texts are served over https too. "record_is_the_floor", as Mississippi's: the
#    dump leaves about one member vote in twenty of 2017-2022 on a label it links to no one ("Washington, A.", "Davis,
#    D.E.", "Young"), and it holds no 2023 vote at all, so only votes read from the record are placed (the fetch reads
#    each bill's page and every floor vote on it); the dump's copy of a record vote only teaches which person a label
#    is. The record's members are full names from the session's committee lists: ms_full_names links them.
SRC_RULES = {"UT": {"chamber": re.compile(r"[?&]house=([HS])\b"), "committee": re.compile(r"/mtgvotes\.jsp"), "https": True},
             "OH": {"committee": re.compile(r"/cmtevotes/?$"), "committee_motion": re.compile(r"^Reported\b"), "oh_votes_page": True,
                    "oh_text_v2": True, "record_replaces_dump": True},
             "SD": {"https": True, "sd_vote_page": True, "record_replaces_dump": True, "sd_record_is_the_floor": True,
                    "sd_sponsors_from_text": True},
             "MS": {"https": True, "ms_vote_page": True, "record_replaces_dump": True, "record_is_the_floor": True, "ms_full_names": True},
             "MD": {"https": True, "md_vote_page": True, "record_replaces_dump": True, "record_is_the_floor": True, "chamber": re.compile(r"/votes/(house|senate)/\d{4}\.(?:pdf|htm)#", re.I),
                    "md_bill_page": True, "https_texts": True, "ms_full_names": True}}
RULES = SRC_RULES.get(ST, {})
# Only votes read from the legislature's record are placed (South Dakota's rule first; Mississippi's too).
FLOOR_FROM_RECORD = bool(RULES.get("sd_record_is_the_floor") or RULES.get("record_is_the_floor"))
NP = "sd_" if RULES.get("sd_record_is_the_floor") else ""  # South Dakota's counts keep their names
if RULES.get("https"):
    for eid in vsrc:
        vsrc[eid] = [re.sub(r"^http://", "https://", u) for u in vsrc[eid]]
# The address each row came with, before any rule below rewrites it: the committee rule reads this one.
vsrc_orig = {eid: list(us) for eid, us in vsrc.items()}


def event_committee_link(eid):
    """A committee's vote, by the state's rule: its address, or (Ohio) its motion and classification."""
    if FLOOR_FROM_RECORD:
        return not str(eid).startswith("supplement:")  # South Dakota, Mississippi: only a vote read from the record is placed
    if RULES.get("committee_motion") and "committee-passage" in pgarr(events[eid].get("motion_classification")) \
            and RULES["committee_motion"].search(events[eid]["motion_text"] or ""):
        return True
    return bool(RULES.get("committee") and RULES["committee"].search((vsrc_orig.get(eid) or vsrc.get(eid) or [""])[0]))


DUPES = collections.defaultdict(collections.Counter)  # session id -> counts, for .openstates.json
OH_ADDR = re.compile(r"/general_assembly_(\d{3})/(?:bills|resolutions|legislation)/([a-z]+\d+)/(?:votes|cmtevotes|actions)/?$")


def oh_votes_page(eid):
    """The Votes-page address of one Ohio vote, or None (a special session's address, an address of another form)."""
    e = events[eid]
    m = OH_ADDR.search((vsrc.get(eid) or [""])[0])
    org = orgs.get(e["organization_id"]) or {}
    ch = {"lower": "House", "upper": "Senate"}.get(org.get("classification"))
    if not m or not ch or not re.match(r"^\d{4}-\d{2}-\d{2}$", (e["start_date"] or "")[:10]):
        return None
    pv = pvotes.get(eid) or []
    yes = sum(v["option"] == "yes" for v in pv) if pv else counts[eid].get("yes", 0)
    no = sum(v["option"] == "no" for v in pv) if pv else counts[eid].get("no", 0)
    return f"https://www.legislature.ohio.gov/legislation/{m.group(1)}/{m.group(2)}/votes#{e['start_date'][:10]}-{ch}-{yes}-{no}"


if RULES.get("oh_votes_page"):
    keep = {}
    for eid in sorted(events, key=lambda x: (events[x].get("updated_at") or "", x), reverse=True):
        page = oh_votes_page(eid)
        if not page:
            continue
        k = (events[eid]["bill_id"], page, event_committee_link(eid))
        sid = events[eid]["legislative_session_id"]
        if k in keep:
            # the same vote again: drop it, the copy updated last is kept; say so when the members differ
            ours = sorted((v["voter_name"], v["option"]) for v in pvotes.get(keep[k], []))
            DUPES[sid]["duplicate_rollcalls_dropped"] += 1
            if sorted((v["voter_name"], v["option"]) for v in pvotes.get(eid, [])) != ours:
                DUPES[sid]["duplicate_rollcalls_dropped_members_differed"] += 1
            for d in (events, vsrc, pvotes, counts):
                d.pop(eid, None)
            continue
        keep[k] = eid
        vsrc[eid] = [page]

SD_VOTE = re.compile(r"(?:/api/Votes/|/RollCall\.aspx\?Vote=|/Session/Vote/)(\d+)\b")
if RULES.get("sd_vote_page"):
    keep = {}
    for eid in sorted(events, key=lambda x: (events[x].get("updated_at") or "", x), reverse=True):
        m = next((SD_VOTE.search(u) for u in (vsrc.get(eid) or []) + [events[eid].get("dedupe_key") or ""] if SD_VOTE.search(u)), None)
        if not m:
            continue
        page = f"https://sdlegislature.gov/Session/Vote/{m.group(1)}"
        k = (events[eid]["bill_id"], page)
        if k in keep:  # the same vote again: the copy updated last is kept
            DUPES[events[eid]["legislative_session_id"]]["duplicate_rollcalls_dropped"] += 1
            for d in (events, vsrc, pvotes, counts):
                d.pop(eid, None)
            continue
        keep[k] = eid
        vsrc[eid] = [page]

MS_VOTE = re.compile(r"/(20\d{2}(?:[1-9]E)?)/pdf/votes/(house|senate)/(\d{7})\.pdf$", re.I)
if RULES.get("ms_vote_page"):
    for eid in list(events):
        m = MS_VOTE.search((vsrc.get(eid) or [""])[0])
        if m:
            code = re.sub(r"[\s.]+", "", bills[events[eid]["bill_id"]]["identifier"]).upper()
            vsrc[eid] = [f"https://billstatus.ls.state.ms.us/{m.group(1)}/pdf/votes/{m.group(2).lower()}/{m.group(3)}.pdf#{code}"]

MD_VOTE = re.compile(r"^https://mgaleg\.maryland\.gov/(20\d{2})RS/votes/(house|senate)/(\d{4})\.pdf$", re.I)
MD_OLD_VOTE = re.compile(r"^https://mgaleg\.maryland\.gov/webmga/frmMain\.aspx\?pid=flrvotepage&tab=subject\d+&id=([hs][bj])0*(\d+),([hs])-(\d{4})&stab=\d+&ys=(20\d{2})RS$", re.I)
if RULES.get("md_vote_page"):
    for eid in list(events):
        u = (vsrc.get(eid) or [""])[0]
        code = re.sub(r"[\s.]+", "", bills[events[eid]["bill_id"]]["identifier"]).upper()
        m, o = MD_VOTE.search(u), MD_OLD_VOTE.search(u)
        # a veto is overridden in the next session, on a vote filed under it (2020 HB 4: /2021RS/...): the address
        # names the bill's year, #2020-HB4, because that session has its own HB 4
        yr = sessions[events[eid]["legislative_session_id"]]["identifier"][:4]
        tag = lambda vote_year: f"{yr}-{code}" if vote_year == str(int(yr) + 1) else code
        if m and m.group(1) in (yr, str(int(yr) + 1)):
            vsrc[eid] = [f"https://mgaleg.maryland.gov/{m.group(1)}RS/votes/{m.group(2).lower()}/{m.group(3)}.{'htm' if m.group(1) == '2017' else 'pdf'}#{tag(m.group(1))}"]
        elif o and o.group(5) in (yr, str(int(yr) + 1)) and f"{o.group(1).upper()}{int(o.group(2))}" == re.sub(r"^([A-Z]+)0+", r"\1", code):
            # the old page names its bill: it must be the row's bill, else the address is left as it is (no reader knows it)
            ext = "htm" if o.group(5) == "2017" else "pdf"
            vsrc[eid] = [f"https://mgaleg.maryland.gov/{o.group(5)}RS/votes/{'house' if o.group(3).lower() == 'h' else 'senate'}/{o.group(4)}.{ext}#{tag(o.group(5))}"]
        else:
            DUPES[events[eid]["legislative_session_id"]]["md_vote_address_not_rewritten"] += 1

# ---------------- roll calls the dump does not hold ----------------
RECORD_NAMES = set()  # (session, chamber, name) printed in a roll call read from the record; ms_resolve reads only these
# A dump can hold a session's bills and none of its roll calls (Utah's 2025 General Session, 2026-11 dump: 959
# bills, 0 roll calls). fetch-legislature-rollcalls.ts reads those roll calls from the legislature's own site into
# <work>/supplements/<ST>/<session>.json; they join here as roll calls like any other, so the same name rules link
# their voters. A roll call whose page the dump already holds is NOT added a second time.
SUPP_OPT = {"Yea": "yes", "Nay": "no"}  # anything else is "other", as Open States marks an absent member
SUPP = collections.Counter()
SUPP_SESSIONS = collections.defaultdict(lambda: {"added": 0, "bills": set(), "source": ""})
LEARN_ONLY = {}  # South Dakota: dump copies of votes the record replaced -> (event, person votes, chamber)
CHECKED_BILLS = set()  # bill ids whose record was read
def sd_same_member(printed, m):
    """fetch-legislature-rollcalls.ts sdSameMember: the same label, the same first and last name, or the same surname
    with any given name the printed form adds agreeing with the member's (first two letters)."""
    k = lambda t: re.sub(r"[^a-z()]", "", t.lower())
    if k(printed) in (k(m["label"]), k(m["name"])):
        return True
    g = re.match(r"^(.*?)\s*\((.+)\)$", printed.strip())
    sur, given = (g.group(1), g.group(2)) if g else (printed, None)
    if k(sur) != k(re.sub(r"\s*\(.*\)\s*$", "", m["label"])):
        return False
    return given is None or k(m["name"]).startswith(k(given)[:2])


SD_SP = {}  # South Dakota: bill id -> the record's sponsors and the introduced text (supplements 'sponsors')
# South Dakota votes a consent calendar as ONE roll call on many bills, and the dump files a copy under each bill: there a
# roll call is known by (bill, address), so one bill's copy never stands in for another's.
PER_BILL = FLOOR_FROM_RECORD
hkey = lambda bid, u: (bid, u) if PER_BILL else u
have_url = {hkey(events[e]["bill_id"], u) for e, us in vsrc.items() for u in us}
sess_by_ident = {s["identifier"]: sid for sid, s in sessions.items()}
bill_by_key = {(b["legislative_session_id"], re.sub(r"[\s.]+", "", b["identifier"]).upper()): bid for bid, b in bills.items()}
RECORD_ONLY_BILLS = collections.Counter()  # session id -> bills built from the legislature's history alone


def ms_bill_from_history(sp, sid, ident):
    """Mississippi: a bill the dump does not hold (2016 and before: the 2026-11 dump has no bills before 20171E; the
    ms-01 batch cites 2016 HB 786). Built only from the history the fetch kept (supplements/MS/raw/, named by the
    sha256 of its address): the history must name this bill of this session. It carries no sponsor, text or action;
    its roll calls are the supplement's. None when the history is not on disk or is another bill."""
    u = (sp.get("checked", {}).get(ident) or {}).get("vote_list") or ""
    p = os.path.join(WORK, "supplements", ST, "raw", hashlib.sha256(u.encode()).hexdigest()[:24]) if u else ""
    if not p or not os.path.exists(p):
        return None
    h = open(p, encoding="latin-1").read()
    tag = lambda t: (re.search(rf"<{t}>(.*?)</{t}>", h, re.S) or [None, ""])[1].strip()
    if re.sub(r"\s+", "", tag("SHORT_MSRID")).upper() != re.sub(r"[\s.]+", "", ident).upper() or tag("YEAR") != sp["session"][:4] \
            or not tag("SESSION").startswith("Regular") or sp["session"] != tag("YEAR"):
        return None
    bid = f"history:{ST}:{sp['session']}:{ident}"
    bills[bid] = {"id": bid, "identifier": ident, "title": tag("SHORTTITLE") or ident, "classification": "{bill}",
                  "subject": "{}", "from_organization_id": None, "legislative_session_id": sid}
    by_bill[bid]["billsource"].append({"url": u})
    if tag("LONGTITLE"):
        by_bill[bid]["billabstract"].append({"abstract": tag("LONGTITLE")})
    bill_by_key[(sid, re.sub(r"[\s.]+", "", ident).upper())] = bid
    RECORD_ONLY_BILLS[sid] += 1
    return bid


def md_bill_from_page(sp, sid, ident):
    """Maryland: a bill the dump does not hold (2016 and before: the 2026-11 dump has no bill before 2017; the md-02
    batch cites 2013 SB 281). Built only from the bill page the fetch kept (supplements/MD/raw/, named by the sha256 of
    its address): the page must name this bill ("Legislation - SB0281") and this session ("2013 Regular Session"). It
    carries no sponsor, text or action; its roll calls are the supplement's. None when the page is not on disk or is
    another bill."""
    u = (sp.get("checked", {}).get(ident) or {}).get("vote_list") or ""
    p = os.path.join(WORK, "supplements", ST, "raw", hashlib.sha256(u.encode()).hexdigest()[:24]) if u else ""
    if not p or not os.path.exists(p):
        return None
    h = open(p, encoding="utf-8").read()
    named = re.search(r"<title>\s*Legislation - ([HS][BJ])0*(\d+)\s*</title>", h, re.I)
    sel = re.search(r'<select[^>]*id="valueSessions"[^>]*>\s*<option[^>]*>([^<]*)</option>', h)
    if not named or f"{named.group(1).upper()}{int(named.group(2))}" != re.sub(r"[\s.]+", "", ident).upper() \
            or not sel or sel.group(1).strip() != f"{sp['session']} Regular Session":
        return None
    bid = f"page:{ST}:{sp['session']}:{ident}"
    # the page's synopsis heading: <h3 ...>Firearm Safety Act of 2013</h3> under "Title"; else the bill itself
    t = re.search(r"<dt[^>]*>\s*Title\s*</dt>\s*<dd[^>]*>([\s\S]*?)</dd>", h)
    title = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", t.group(1))).strip() if t else ident
    bills[bid] = {"id": bid, "identifier": f"{named.group(1).upper()} {int(named.group(2))}", "title": title or ident,
                  "classification": "{bill}", "subject": "{}", "from_organization_id": None, "legislative_session_id": sid}
    by_bill[bid]["billsource"].append({"url": u})
    bill_by_key[(sid, re.sub(r"[\s.]+", "", ident).upper())] = bid
    RECORD_ONLY_BILLS[sid] += 1
    return bid


for f in sorted(glob.glob(os.path.join(WORK, "supplements", ST, "*.json"))):
    sp = json.load(open(f))
    if sp.get("state", "").upper() != ST or sp.get("session") not in sess_by_ident:
        sys.exit(f"{f}: not a {ST} supplement for a session of this extract (state {sp.get('state')!r}, session {sp.get('session')!r})")
    sid = sess_by_ident[sp["session"]]
    if want and sp["session"] not in want:
        continue
    if RULES.get("ms_vote_page"):
        for ident in sp.get("bills", {}):
            if not bill_by_key.get((sid, re.sub(r"[\s.]+", "", ident).upper())):
                ms_bill_from_history(sp, sid, ident)
    if RULES.get("md_vote_page"):
        for ident in sp.get("bills", {}):
            if not bill_by_key.get((sid, re.sub(r"[\s.]+", "", ident).upper())):
                md_bill_from_page(sp, sid, ident)
    if RULES.get("sd_sponsors_from_text"):
        for ident, spn in sp.get("sponsors", {}).items():
            cb = bill_by_key.get((sid, re.sub(r"[\s.]+", "", ident).upper()))
            if not cb:
                sys.exit(f"{f}: bill {ident!r} is not in session {sp['session']} of this extract")
            SD_SP[cb] = spn
    for ident in sp.get("checked", {}):
        cb = bill_by_key.get((sid, re.sub(r"[\s.]+", "", ident).upper()))
        if cb:
            CHECKED_BILLS.add(cb)
    for ident, rcs in sorted(sp.get("bills", {}).items()):
        bid = bill_by_key.get((sid, re.sub(r"[\s.]+", "", ident).upper()))
        if not bid:
            sys.exit(f"{f}: bill {ident!r} is not in session {sp['session']} of this extract")
        if FLOOR_FROM_RECORD and ident in sp.get("checked", {}):
            # South Dakota: the record's copy of a floor vote replaces the dump's. The dump's copy is kept aside, only
            # to teach which person a label is (its voters are mostly linked by Open States from 2021).
            on_rec = {rc["url"]: rc for rc in rcs}
            for eid in [e for e, ev_ in events.items() if ev_["bill_id"] == bid and e in vsrc and not e.startswith("supplement:")]:
                if vsrc[eid][0] in on_rec:
                    DUPES[sid]["dump_floor_rollcalls_replaced_by_the_record"] += 1
                    LEARN_ONLY[eid] = (events[eid], pvotes.get(eid, []), on_rec[vsrc[eid][0]]["chamber"])
                    have_url.discard(hkey(bid, vsrc[eid][0]))
                    for d in (events, vsrc, pvotes, counts):
                        d.pop(eid, None)
        elif RULES.get("record_replaces_dump") and ident in sp.get("checked", {}):
            # The legislature's record of this bill was read: it is the bill's floor votes. A dump floor vote of the
            # bill that is not on it is dropped (Ohio: the 136th's dates are clock times, so a late vote lands on the
            # next day; one tally of 135 SB 58 is not the record's). Committee votes are not on it and stay.
            on_rec = {rc["url"] for rc in rcs}
            for eid in [e for e, ev_ in events.items() if ev_["bill_id"] == bid and e in vsrc and not event_committee_link(e)
                        and not e.startswith("supplement:") and vsrc[e][0] not in on_rec]:
                DUPES[sid]["dump_floor_rollcalls_not_on_the_record_dropped"] += 1
                have_url.discard(hkey(bid, vsrc[eid][0]))
                for d in (events, vsrc, pvotes, counts):
                    d.pop(eid, None)
        for n, rc in enumerate(rcs):
            if hkey(bid, rc["url"]) in have_url:
                SUPP["already_in_dump"] += 1
                continue
            groups = rc["groups"]
            tally = [len(groups.get(k, [])) for k in ("Yea", "Nay", "Absent or not voting")]
            if tally != [rc["yea"], rc["nay"], rc["absent"]] or set(groups) - {"Yea", "Nay", "Absent or not voting"}:
                sys.exit(f"{f}: {ident} {rc['url']}: the members listed ({tally}) are not the tally ({rc['yea']}-{rc['nay']}-{rc['absent']})")
            eid = "supplement:" + rc["url"] + (f"#{bid}" if PER_BILL else "")
            have_url.add(hkey(bid, rc["url"]))
            events[eid] = {"id": eid, "bill_id": bid, "legislative_session_id": sid, "organization_id": None,
                           "motion_text": rc["motion"], "start_date": rc["date"], "order": str(n),
                           "result": "pass" if rc["passed"] else "fail", "_chamber": rc["chamber"], "_supplement": sp.get("source", "")}
            counts[eid] = {"yes": rc["yea"], "no": rc["nay"], "other": rc["absent"]}
            vsrc[eid] = [rc["url"]]
            pvotes[eid] = [{"voter_id": None, "voter_name": name, "option": SUPP_OPT.get(k, "other")}
                           for k in ("Yea", "Nay", "Absent or not voting") for name in groups.get(k, [])]
            RECORD_NAMES.update((sid, rc["chamber"], name) for k in groups for name in groups[k])
            SUPP["added"] += 1
            SUPP_SESSIONS[sid]["added"] += 1
            SUPP_SESSIONS[sid]["bills"].add(ident)
            SUPP_SESSIONS[sid]["source"] = sp.get("source", "")
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
    return m.group(1)[0].upper() if m else (events[eid].get("_chamber") or chamber_of(events[eid]["organization_id"]))


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
for eid, e, ch, pv in ([(x, y, None, None) for x, y in events.items()] + [(x, y[0], y[2], y[1]) for x, y in LEARN_ONLY.items()]):
    if ch is None and event_committee_link(eid):
        continue  # a committee's members can sit in either chamber: it teaches nothing about a chamber's labels
    ch = ch or event_chamber(eid)
    for v in (pv if pv is not None else pvotes[eid]):
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


MS_SUFFIX = re.compile(r"[\s,]+(?:jr|sr|ii|iii|iv|v)\.?$", re.I)
# Maryland's lists print accents ("Joseline A. Peña-Melnyk"): a word is read without them, as norm() reads a name.
ascii_fold = lambda s: unicodedata.normalize("NFD", s or "").encode("ascii", "ignore").decode()


MS_BY_SEAT = collections.Counter()  # (session, chamber, printed name, Open States name) -> votes linked by the seat rule
MS_BY_NAME = collections.Counter()  # the same, linked by the name alone against a membership in the other chamber


def ms_family_in(p, name):
    """Does person p's family name end this printed name (a suffix dropped; one part of a hyphenated name)?"""
    w = re.findall(r"[A-Za-z][A-Za-z'\-]*", MS_SUFFIX.sub("", ascii_fold(name)))
    fam = norm(MS_SUFFIX.sub("", persons[p]["family_name"] or persons[p]["name"].split()[-1]))
    parts = [norm(x) for x in (persons[p]["family_name"] or "").split("-")]
    return bool(w) and (norm(w[-1]) in [fam] + parts or norm("".join(w[-2:])) == fam)


def ms_resolve(sid, ch, name):
    """Mississippi: a full name from the legislature's member list ("Robert L. Jackson", "Dennis DeBar, Jr.", "Sam
    Creekmore IV", "Theresa Gillespie Isom"), printed in a roll call read from the record -> one person of this session
    and chamber, or None.
    1. The family name (a suffix dropped from both; one part of a hyphenated name, "Hobgood-Wilkes") is the name's
       last word or words, and a given name is one of its other words, starts with an initial it prints, or is the
       start of one of them ("Chris" for "Christopher", "Ed" is too short to count).
    2. Otherwise, because Open States often stores a nickname ("Bubba Carpenter", "Hank Zuber") where the
       legislature prints the legal name ("Lester Carpenter", "Henry Zuber III"): the family name fits exactly one
       person in the session's roster of that chamber, a membership seats that person in it during the session, and
       the record prints only one member of that family name in that chamber that session. Every such link is counted in MS_BY_SEAT and printed at the end, to be checked by hand."""
    if (sid, ch, name) not in RECORD_NAMES:
        return None  # the dump's own labels are misread ("Absent or those Barnett"); only the record's names are linked here
    words = re.findall(r"[A-Za-z][A-Za-z'\-]*", MS_SUFFIX.sub("", ascii_fold(name)))
    if len(words) < 2 or "(" in name:
        return None

    def fam_fits(p, k):
        fam = norm(MS_SUFFIX.sub("", persons[p]["family_name"] or persons[p]["name"].split()[-1]))
        tail = norm("".join(words[-k:]))
        # one part of a hyphenated or two-word family name: "Hobgood-Wilkes"; Maryland's record prints "Heather Bagnall"
        # and "Jennifer White" for Open States' "Bagnall Tudball" and "White Holland"
        return tail == fam or (k == 1 and tail in [norm(x) for x in re.split(r"[-\s]+", persons[p]["family_name"] or "")])
    def name_fits(p, first_only=False):
        given = norm(persons[p]["given_name"] or persons[p]["name"].split()[0])
        fits = lambda f: f and (f == given or given.startswith(f) or (len(given) >= 3 and f.startswith(given)))  # "C." / "Chris"
        for k in (1, 2):
            if len(words) > k and fam_fits(p, k):
                ws = [norm(w) for w in words[:-k]]
                if (fits(ws[0]) and len(ws[0]) > 1) if first_only else any(fits(f) for f in ws):
                    return True
        return False
    # Then every person of the state, not only the session's roster, for two Maryland faults. The dump may link none of
    # a member's votes that session (2017 "Theodore Sophocleus", 2020 "Dana Jones"); and Open States may keep only an
    # undated membership in the member's latest chamber, so a delegate who became a senator (Alonzo Washington, Shaneka
    # Henson) never reads as seated in the House. Each link made here is printed. Because a person whose name fits is
    # always found here, the seat rule below never gives a printed name to a namesake (Alice Sophocleus, or the
    # Speaker Adrienne Jones, whom the record prints by office).
    for i, ros in enumerate((roster, roster_sp, {(sid, ch): list(persons)})):
        # across the whole state the FIRST given word must fit, written out: a middle initial fits too much there
        # (Mississippi's "Robert L. Jackson" is not Lataisha Jackson)
        cand = [p for p in ros.get((sid, ch), []) if p in persons and name_fits(p, first_only=i == 2)]
        if len(cand) > 1:
            seated = [p for p in cand if seated_in(p, sid, ch)]
            cand = seated if len(seated) == 1 else [p for p in cand if seated_in(p, sid, ch) is not False]
        if len(cand) == 1:
            if i == 2:
                MS_BY_NAME[(sessions[sid]["identifier"], ch, name, persons[cand[0]]["name"])] += 1
            return cand[0]
        if cand:
            return None
    # Seated by a membership: the roster also takes voters the dump linked, and a dump link can name a senator in a
    # House vote (Kevin Blackwell beside Rep. Charles "Chuck" Blackwell, 2024).
    fam = [p for p in roster.get((sid, ch), []) if p in persons and seated_in(p, sid, ch)
           and any(len(words) > k and fam_fits(p, k) for k in (1, 2))]
    # The record prints every member of the chamber in each roll call, so the session's printed names stand in for
    # the legislature's roster: two printed members of one family name ("Mac Huddleston", "Robert E. Huddleston",
    # Districts 15 and 30 in 2018, the second unknown to Open States) means the family name settles nothing.
    if len(fam) == 1 and sum(
            1 for (s2, c2, n2) in RECORD_NAMES if s2 == sid and c2 == ch and ms_family_in(fam[0], n2)) == 1:
        MS_BY_SEAT[(sessions[sid]["identifier"], ch, name, persons[fam[0]]["name"])] += 1
        return fam[0]
    return None


def resolve(sid, ch, name):
    o = OVR.get(f"{ST}:{sessions[sid]['identifier']}:{ch}:{name}")
    if o:
        return o
    if RULES.get("ms_full_names"):
        p = ms_resolve(sid, ch, name)
        if p:
            return p
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
        if RULES.get("md_bill_page"):
            for r in ex["billsource"]:
                r["url"] = re.sub(r"^https://mgaleg\.maryland\.gov/webmga/frmMain\.aspx\?id=([HS][BJ])(\d+)&stab=\d+&pid=billpage&tab=subject\d+&ys=(20\d{2})rs$",
                                  lambda g: f"https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/{g.group(1).lower()}{int(g.group(2)):04d}?ys={g.group(3)}RS",
                                  r["url"], flags=re.I)
        bill_id = rid("bill", bid)
        body = chamber_of(b["from_organization_id"]) or (num[:1] if num[:1] in "HSA" else "")
        cls = pgarr(b["classification"])
        btype = next((BTYPE[c] for c in cls if c in BTYPE), (cls[0][:1].upper() if cls else "B"))
        st_, st_date = status_of(ex["billaction"], btype)
        src = [r["url"] for r in ex["billsource"]]
        sponsors = []
        sp_rows = sorted(ex["billsponsorship"], key=lambda r: 0 if r["primary"] == "t" else 1)
        if bid in SD_SP and "refused" in SD_SP[bid]:
            # South Dakota: the fetch refused this bill's sponsors (its text names someone it cannot tie to one sponsor
            # of the record). The dump's people are not cited instead: their page is a script shell and they are all
            # marked primary. A committee sponsor row is kept.
            stats["sd_sponsor_rows_dropped_sponsors_refused"] += sum(1 for r in sp_rows if r["entity_type"] == "person")
            sp_rows = [r for r in sp_rows if r["entity_type"] == "organization"]
        elif bid in SD_SP:
            # South Dakota: the record's sponsors the introduced text names, cited on that text (see SRC_RULES)
            spn = SD_SP[bid]
            src = [spn["text"]]
            dump_people = [r for r in ex["billsponsorship"] if r["entity_type"] == "person"]
            stats["dump_sponsor_rows_replaced_by_the_record"] += len(sp_rows)
            sp_rows = [r for r in sp_rows if r["entity_type"] == "organization"]
            on = sorted((m for m in spn["members"] if m["on_text"]), key=lambda m: 0 if m["type"] == "P" else 1)
            stats["sd_sponsors_not_named_on_the_text"] += sum(1 for m in spn["members"] if not m["on_text"])
            for i, m in enumerate(on, 1):
                # the dump's row for this sponsor, printed as the dump prints it ("Kolbeck" for "Kolbeck (Jack)"): used
                # only when exactly one row is that member; otherwise the label links it, as any other name does
                rows_ = [r for r in dump_people if sd_same_member(r["name"] or "", m)]
                row = rows_[0] if len(rows_) == 1 else None
                pj = person_for(row["person_id"] if row else None, m["label"], m["chamber"])
                sponsors.append(dict(pj, sponsor_type_id=1 if m["type"] == "P" else 2, sponsor_order=i, committee_sponsor=0, committee_id=0))
                stats["sd_sponsors_named_on_the_text"] += 1
        for i, sp in enumerate(sp_rows, len(sponsors) + 1):
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
            if RULES.get("oh_text_v2"):
                # Ohio, 2026-11-16: .../solarapi/v1/general_assembly_132/bills/hb228/RH/01?format=pdf is dead (404);
                # the same PDF is .../api/v2/general_assembly_132/legislation/hb228/01_RH/pdf/. Other forms are kept.
                main = re.sub(r"^https?://search-prod\.lis\.state\.oh\.us/solarapi/v1/general_assembly_(\d{3})/(?:bills|resolutions)/([a-z]+\d+)/([A-Z]+)/(\d+)\?format=pdf$",
                              r"https://search-prod.lis.state.oh.us/api/v2/general_assembly_\1/legislation/\2/\4_\3/pdf/", main)
            if RULES.get("https_texts"):
                main = re.sub(r"^http://", "https://", main)
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
            sd_why = None
            if FLOOR_FROM_RECORD and not str(eid).startswith("supplement:"):
                # South Dakota: not read from the record, so neither its chamber nor whether it was a committee's is known.
                # Mississippi: its member list is misread from the PDF.
                sd_why = "the bill's record was read and this is not a floor vote on the bill" if bid in CHECKED_BILLS else "the bill's record was not read"
                stats[f"{NP}dump_rollcalls_not_placed"] += 1
                desc = f"{CH_NAME.get(ch, '')} Committee or not placed ({sd_why}): {e['motion_text'] or ''}"
            rc = {"roll_call_id": rc_id, "bill_id": bill_id, "date": (e["start_date"] or "")[:10], "desc": desc.strip(),
                  "yea": yea, "nay": nay, "nv": nv, "absent": ab, "total": yea + nay + nv + ab,
                  "passed": 1 if e["result"] == "pass" else 0, "chamber": ch or "", "chamber_id": 0,
                  "url": (vsrc[eid] or [""])[0], "state_link": (vsrc[eid] or [""])[0], "votes": mv,
                  "_openstates": {"vote_event_id": eid, "counts": c, "committee": committee, **({f"{NP}not_placed": sd_why} if sd_why else {})}}
            if e.get("_supplement") is not None:
                # not from the dump: read from the legislature's own site (see the supplement block above)
                rc["_openstates"]["from_legislature"] = e["_supplement"] or True
                stats["rollcalls_from_legislature"] += 1
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
              "counts": dict(stats, **DUPES[sid], **({"bills_from_the_legislature_history_only": RECORD_ONLY_BILLS[sid]} if RECORD_ONLY_BILLS[sid] else {})),
              "name_only_voters_unmatched": dict(name_only),
              "rollcalls_from_legislature": ({"count": SUPP_SESSIONS[sid]["added"], "bills": sorted(SUPP_SESSIONS[sid]["bills"]),
                                              "source": SUPP_SESSIONS[sid]["source"],
                                              "note": "The dump holds no roll call for these; each was read from the legislature's own page. "
                                                      "Only the bills listed were looked up: every other bill of this session still has no roll call here."}
                                             if sid in SUPP_SESSIONS else None),
              "labels_bridged_from_other_sessions": {f"{CH_NAME.get(c, c)}: {n}": persons[p]["name"] for (s_, c, n), p in sorted(BRIDGED.items()) if s_ == ident},
              "warnings": ["Not a LegiScan dataset. doc_id values cannot be used with LegiScan getBillText; fetch texts[].state_link.",
                           "people_id below 9000001 are real LegiScan ids (bridged); others are ours.",
                           "Vote mark 'other' is shown as NV; check absent/excused against the state's journal if it matters.",
                           "Committee votes may be missing."]}
    json.dump(marker, open(os.path.join(root, ".openstates.json"), "w"), indent=1, ensure_ascii=False)
    print(f"{ST}-{lsid} {ident}: " + ", ".join(f"{k} {v}" for k, v in stats.items())
          + (f"; unmatched name-only voters {sum(name_only.values())}" if name_only else ""), flush=True)

json.dump(REG, open(REG_PATH, "w"), indent=0, sort_keys=True)
if SUPP:
    print("roll calls read from the legislature's own site: " + ", ".join(f"{k} {v}" for k, v in sorted(SUPP.items())), flush=True)
if MS_BY_SEAT:
    print("Full names linked by the seat rule (family name fits one seated member; check each by hand):")
    for (sess, ch, printed, os_name), n in sorted(MS_BY_SEAT.items()):
        print(f"  {sess} {ch} {printed!r} -> {os_name!r} ({n} votes)")
if MS_BY_NAME:
    print("Full names linked by the name alone, no membership seating the person in this chamber that session (check each by hand):")
    for (sess, ch, printed, os_name), n in sorted(MS_BY_NAME.items()):
        print(f"  {sess} {ch} {printed!r} -> {os_name!r} ({n} votes)")
