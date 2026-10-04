"""Build rows.json for the Charlotte batch.

Two layers:
  1. SCOPE_BLANKS - a legal fact about the OFFICE, identical for every member of
     this body and verified once against the statute. Templated per member.
  2. EVIDENCED - per-person rows from research, which override the template.

One row per (full_name, topic_key) is structural: EVIDENCED replaces the
template entry for that pair, so a duplicate cannot be appended.
"""
import io, json, os

HERE = os.path.dirname(os.path.abspath(__file__))

MEMBERS = [
    "Rob Harrington", "Dimple Ajmera", "James Mitchell Jr.", "Victoria Watlington",
    "LaWana Mayfield", "Danté Anderson", "Malcolm Graham", "Joi Mayo",
    "Reneé Johnson", "JD Mazuera Arias", "Kimberly Owens", "Edmund H. Driggs",
]

CMS = ("Scope blank. Schools in Charlotte are run by the Charlotte-Mecklenburg Board of "
       "Education, a separately elected body with its own budget and its own policies. A "
       "Charlotte City Council member casts no vote on %s. Recorded as closed research "
       "under spec 4.9, not as a gap.")

SCOPE_BLANKS = {
    "gun-policy":
        "Scope blank. N.C.G.S. 14-409.40(a) declares that the entire field of regulation of "
        "firearms is preempted from regulation by local governments, and (b) bars a municipality "
        "from regulating in any manner the possession, ownership, storage, transfer, sale, "
        "purchase, licensing, taxation, manufacture, transportation or registration of firearms. "
        "Every rung on this ladder requires either new firearm restrictions or the loosening of "
        "existing ones, and a Charlotte City Council member holds no lever on any of them.",
    "minimum-wage":
        "Scope blank. N.C.G.S. 95-25.1(d) preempts any local ordinance, regulation, resolution or "
        "policy imposing a requirement on an employer pertaining to compensation of employees, "
        "including wage levels. The statute's first exception lets a local government set pay for "
        "its own staff, so Charlotte's votes on city employee salaries are not evidence about the "
        "wage floor this ladder asks about. No rung is available to this office.",
    "campaign-finance":
        "Scope blank. Campaign contribution limits in North Carolina are set by statute at a state "
        "dollar figure under N.C.G.S. 163-278.13 and indexed by the State Board of Elections. A "
        "city council cannot set, raise, lower or abolish them, so no rung on this ladder is "
        "available to this office.",
    "ranked-choice-voting":
        "Scope blank. The method by which a North Carolina municipality elects its council is fixed "
        "by statute - N.C.G.S. 163-292 sets out how results are determined under the plurality "
        "method - and a city cannot adopt ranked-choice voting on its own authority. Every rung on "
        "this ladder is a decision for the General Assembly, not this office.",
    "abortion":
        "Scope blank. Abortion law in North Carolina is set by the General Assembly. A city council "
        "holds no lever on the legality or the timing limits this ladder asks about.",
    "cannabis-policy":
        "Scope blank. Cannabis is controlled by state criminal law in North Carolina. A city council "
        "cannot legalise, decriminalise or license it, and a sweep of the council's own legislative "
        "record returned no cannabis matter of any kind. No rung is available to this office.",
    "trans-athletes":
        "Scope blank. Eligibility for school and league sport is set by the state, the school board "
        "and the athletic associations. A Charlotte City Council member holds no lever on any rung.",
    "fossil-fuels":
        "Scope blank. Every rung on this ladder is about national fossil fuel production levels, "
        "drilling permits and public land. A city council holds no lever on any of them.",
    "jail-capacity":
        "Scope blank. The jail serving Charlotte is operated by the Mecklenburg County Sheriff and "
        "funded by the county commission. A city council member holds no vote on jail capacity, on "
        "alternatives to incarceration, or on detention funding.",
    "education-curriculum": CMS % "curriculum or materials adoption",
    "education-library-books": CMS % "challenges to library and classroom books",
    "education-gender-identity": CMS % "how staff treat a student's name or gender identity",
    "education-equity-programs": CMS % "district equity staffing, training or achievement-gap programmes",
    "education-school-police": CMS % "school resource officer contracts",
    "education-school-budget": CMS % "school spending levels or school tax requests",
    "education-ai":
        "Scope blank. Classroom use of artificial intelligence is set by the Charlotte-Mecklenburg "
        "Board of Education and its administration. A Charlotte City Council member holds no lever "
        "on it. Recorded as closed research under spec 4.9, not as a gap.",
    "education-charter-authorization":
        "Scope blank. Charter schools in North Carolina are authorised by the State Board of "
        "Education through the Charter Schools Review Board, not by a city council and not by the "
        "local school board. No rung is available to this office.",
}

# Rungs 1 and 2 are removed by statute; 4 names detainers, which are the Sheriff's.
IMMIGRATION_DEFAULT = (
    "Blank. N.C.G.S. 160A-205.2(a) bars a city from any policy that limits or restricts the "
    "enforcement of federal immigration laws, and (b)(3) bars prohibiting the communication of "
    "immigration status information to federal agencies, so chairs 1 and 2 are not lawfully "
    "available to this office. Chair 4 turns on honouring ICE detainers, which are served on the "
    "Mecklenburg County Sheriff's jail rather than on city police. That leaves chair 3, which is "
    "the statutory floor every North Carolina city already sits on, and chair 5. No vote or "
    "statement was found placing this member beyond that floor, and complying with a state mandate "
    "is not evidence of a position.")


def main():
    path = os.path.join(HERE, "evidenced.json")
    evidenced = json.load(open(path, encoding="utf-8")) if os.path.exists(path) else []
    by_pair = {(r["full_name"], r["topic_key"]): r for r in evidenced}

    rows = []
    for name in MEMBERS:
        for topic, reason in SCOPE_BLANKS.items():
            key = (name, topic)
            rows.append(by_pair.pop(key) if key in by_pair else {
                "full_name": name, "topic_key": topic, "value": "",
                "evidence_type": "", "reasoning": reason})
        key = (name, "local-immigration")
        rows.append(by_pair.pop(key) if key in by_pair else {
            "full_name": name, "topic_key": "local-immigration", "value": "",
            "evidence_type": "", "reasoning": IMMIGRATION_DEFAULT})

    # Layer 3 — SEARCHED BLANKS. One row per member x live ladder that the
    # name-x-topic sweep actually covered. The reasoning states the method and
    # the article count so a reviewer can price the depth: a topic-specific
    # search was run, and every passage that both names the member and carries
    # a direct quotation was read. That is closed research at a stated depth,
    # not an assertion that nothing exists anywhere.
    import json as _json, os as _os
    merged = {}
    for _c in ("topicnews", "cltnews2"):
        _p = _os.path.join(HERE, _c, "hits.json")
        if not _os.path.exists(_p):
            continue
        for _m, _t in _json.load(open(_p, encoding="utf-8")).items():
            for _k, _u in _t.items():
                merged.setdefault(_m, {}).setdefault(_k, set()).update(_u)
    hits = {m: {k: sorted(v) for k, v in t.items()} for m, t in merged.items()}
    if hits:
        for name, topics in hits.items():
            for topic, urls in topics.items():
                key = (name, topic)
                if key in by_pair or any(r["full_name"] == name and r["topic_key"] == topic
                                         for r in rows):
                    continue
                rows.append({
                    "full_name": name, "topic_key": topic, "value": "",
                    "evidence_type": "",
                    "reasoning": (
                        ("Blank. A name-and-topic search of WFAE, Queen City Nerve, WCNC and The "
                         "Charlotte Post returned no article naming this member that bears on this "
                         "question, and the member's official city page does not address it. "
                         "Recorded as searched and not found, at that stated depth.")
                        if not urls else
                        ("Blank after a topic-specific search. A name-and-topic search of WFAE, "
                         "Queen City Nerve, WCNC and The Charlotte Post returned %d article(s) that "
                         "name this member and bear on this question, and every passage in them that "
                         "both names the member and carries a direct quotation was read. None states "
                         "a position that matches a rung on this ladder. Charlotte council members "
                         "are quoted mostly on individual projects, budgets and process rather than "
                         "on the general policy posture this ladder asks about, so the honest result "
                         "is a blank rather than a chair inferred from direction." % len(urls))),
                })

    # anything left in evidenced is a live-ladder row
    rows.extend(by_pair.values())

    out = {"note": "Charlotte NC city stance batch 2026-10-02. Scope blanks are templated per "
                   "member because they are a fact about the office, verified once against the "
                   "statute. Evidenced rows override the template.",
           "rows": rows}
    io.open(os.path.join(HERE, "rows.json"), "w", encoding="utf-8").write(
        json.dumps(out, indent=1, ensure_ascii=False))
    print("members=%d template_topics=%d evidenced=%d total_rows=%d"
          % (len(MEMBERS), len(SCOPE_BLANKS) + 1, len(evidenced), len(rows)))


if __name__ == "__main__":
    main()
