#!/usr/bin/env python3
"""Generate the Tennessee General Assembly seed migration (99 House + 33 Senate).

    python backend/scripts/tn-general-assembly-seed-generate.py 1855 > backend/migrations/1855_tn_general_assembly_seed.sql

Fetches the General Assembly's own legislator directory, parses the roster, and emits the
migration SQL. Re-running it against a later directory will produce a different roster -- this
script generated the seed as the directory stood on the date in RETRIEVED below, and it is kept
so that seed is reproducible and auditable, not so it can be re-run blindly.

Row shape copies North Carolina (seeded 2026-08-22), the closest analogue:
  districts : state code LOWERCASE 'tn' (NATIONAL_* and STATE_EXEC use uppercase -- see the
              migration header), mtfcc G5220 lower / G5210 upper,
              ocd_id .../state:tn/sldl:N | sldu:N, geo_id = '47' + 3-digit district
  offices   : Representative/Senator, representing_state 'TN', seats 1,
              is_appointed_position false, voting_powers 'full'
  politician: party NULL (every GA/NC/UT legislator row stores none),
              external_id = -47 + '20'|'10' + 3-digit district, where 20/10 is the MTFCC tail
              that marks the chamber -- the same encoding NC uses
  terms     : term_start NULL / start_precision 'unknown'; the directory publishes no
              assumed-office date (see the migration header)

The directory pages are served only to a browser-like User-Agent; a bare urlopen gets a redirect
shell from capitol.tn.gov/house/members/, which is why the wapp.capitol.tn.gov URLs are used
directly with an explicit UA.
"""
import html
import re
import sys
import urllib.request

RETRIEVED = "2026-09-11"
GA_NUM = 114
DIR_URL = "https://wapp.capitol.tn.gov/apps/LegislatorInfo/Directory?chamber={}"
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/126.0 Safari/537.36")

CHAMBERS = {
    "H": {
        "name": "Tennessee House of Representatives",
        "count": 99,
        "term_length": "2",
        "district_type": "STATE_LOWER",
        "mtfcc": "G5220",
        "sld": "sldl",
        "label": "State House District ",
        "short": "House",
        "title": "Representative",
        "ext_prefix": -4720000,
    },
    "S": {
        "name": "Tennessee Senate",
        "count": 33,
        "term_length": "4",
        "district_type": "STATE_UPPER",
        "mtfcc": "G5210",
        "sld": "sldu",
        "label": "State Senate District ",
        "short": "Senate",
        "title": "Senator",
        "ext_prefix": -4710000,
    },
}

MEMBER_RE = re.compile(
    r"<a href='(https://wapp\.capitol\.tn\.gov/apps/LegislatorInfo/Member\?district=([HS])(\d+)&ga=(\d+))'"
    r"[^>]*>([^<]+)</a>",
    re.I,
)
BILLS_RE = re.compile(r'aria-label="View sponsored bills for ([^"]+)"', re.I)


def fetch(chamber):
    req = urllib.request.Request(DIR_URL.format(chamber), headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read().decode("utf-8", "replace")


def parse(raw, chamber):
    """One row per member. A seat with no member is listed as 'Vacant' and yields no name."""
    out = []
    for tr in re.split(r"<tr[\s>]", raw, flags=re.I)[1:]:
        m = MEMBER_RE.search(tr)
        if not m or m.group(2).upper() != chamber:
            continue
        pm = re.search(r"<td>\s*([A-Z])\s*</td>", tr[m.end():])
        bm = BILLS_RE.search(tr)
        out.append({
            "district": int(m.group(3)),
            "listed_name": html.unescape(m.group(5)).strip(),
            "natural_name": html.unescape(bm.group(1)).strip() if bm else None,
            "party": pm.group(1) if pm else None,
        })
    return sorted(out, key=lambda r: r["district"])


def split_name(listed):
    """'Hawk, David B.' -> ('David', 'B.', 'Hawk', None, None, 'David B. Hawk')."""
    parts = [p.strip() for p in listed.split(",")]
    suffix = None
    if len(parts) == 3:
        last, suffix, given = parts
    elif len(parts) == 2:
        last, given = parts
    else:
        raise ValueError("unparseable listed name: %r" % listed)

    preferred = None
    nick = re.search(r"'([^']+)'", given)
    if nick:
        preferred = nick.group(1)
        given = (given[:nick.start()] + given[nick.end():]).strip()

    toks = given.split()
    middle = None
    if len(toks) > 1 and re.fullmatch(r"[A-Z]\.", toks[-1]):
        middle, toks = toks[-1], toks[:-1]
    first = " ".join(toks)

    full = " ".join(t for t in (first, middle, last) if t)
    if suffix:
        full += ", " + suffix
    return first, middle, last, suffix, preferred, full


def q(s):
    return "NULL" if s is None else "'" + s.replace("'", "''") + "'"


def main():
    if len(sys.argv) != 2 or not sys.argv[1].isdigit():
        sys.stderr.write("usage: %s <migration-number>\n" % sys.argv[0])
        return 2
    mignum = int(sys.argv[1])

    # The header carries non-ASCII markers. Windows stdout defaults to cp1252 and would raise
    # UnicodeEncodeError on them *after* the work is done, leaving a zero-byte migration file.
    try:
        sys.stdout.reconfigure(encoding="utf-8", newline="\n")
    except AttributeError:  # pragma: no cover - Python < 3.7
        pass

    rows, cite = {}, {}
    for k, cfg in CHAMBERS.items():
        rows[k] = parse(fetch(k), k)
        cite[k] = ("%s (Tennessee General Assembly legislator directory - identity, party, "
                   "district and chamber; %dth General Assembly). Retrieved %s."
                   % (DIR_URL.format(k), GA_NUM, RETRIEVED))

        nums = [r["district"] for r in rows[k]]
        expected = list(range(1, cfg["count"] + 1))
        if nums != expected:
            raise SystemExit("chamber %s: districts %r do not match 1..%d"
                             % (k, nums, cfg["count"]))
        for r in rows[k]:
            r["vacant"] = r["natural_name"] is None or r["listed_name"].lower() == "vacant"
            if r["vacant"]:
                continue
            (r["first"], r["middle"], r["last"],
             r["suffix"], r["preferred"], r["full"]) = split_name(r["listed_name"])
            # the rebuilt full_name, minus any middle initial, must equal the directory's own
            # natural-order rendering -- catches a bad comma split
            if re.sub(r"\s+[A-Z]\.\s+", " ", r["full"]) != r["natural_name"]:
                raise SystemExit("chamber %s district %d: rebuilt name %r disagrees with the "
                                 "directory's %r" % (k, r["district"], r["full"], r["natural_name"]))

    vacant = {k: [r for r in rows[k] if r["vacant"]] for k in CHAMBERS}
    seated = [r for k in CHAMBERS for r in rows[k] if not r["vacant"]]
    n_vacant_lower = len(vacant["H"])

    L = []
    w = L.append
    w("-- Migration %d: seed the Tennessee General Assembly (99 House + 33 Senate)" % mignum)
    w("--")
    w("-- Gives the live Nashville landing chip a populated State band. Before this migration the")
    w("-- TN state tier held exactly one chamber, one office and one occupant (the Governor), and")
    w("-- no STATE_LOWER/STATE_UPPER districts existed at all.")
    w("--")
    w("-- THE THIN EXECUTIVE BAND IS CORRECT AND IS DELIBERATELY LEFT ALONE.")
    w("-- Tennessee popularly elects only the Governor. Verified against the enacted text of the")
    w("-- state constitution (Tennessee Blue Book, publications.tnsosfiles.com, retrieved %s):" % RETRIEVED)
    w("--   Art. III Sec. 2/4 - the governor is chosen by the electors; 4-year term.")
    w("--   Art. III Sec. 17  - \"A secretary of state shall be appointed by joint vote of the")
    w("--                       General Assembly\" (4 years).")
    w("--   Art. VII Sec. 3   - treasurer and comptroller of the treasury \"appointed for the state,")
    w("--                       by the joint vote of both Houses\" (2 years).")
    w("--   Art. VI Sec. 5    - \"An attorney general and reporter for the state, shall be appointed")
    w("--                       by the judges of the Supreme Court\" (8 years).")
    w("--   Lieutenant Governor is not a constitutional office; TCA 8-2-102 (Acts 1951 ch. 49 s.2)")
    w("--   gives the title to the Senate Speaker, who is chosen by senators.")
    w("-- Mirroring Georgia's or North Carolina's four-to-five-seat executive row here would invent")
    w("-- popular elections that do not exist. DO NOT \"FIX\" THE ONE-OFFICE EXEC BAND.")
    w("--")
    w("-- Chamber sizes: Art. II Sec. 5 fixes the House at ninety-nine. Art. II Sec. 6 caps the")
    w("-- Senate at one-third of that; the standing figure of 33 comes from the apportionment act")
    w("-- and is confirmed by the directory below listing districts 1-33. Terms: Art. II Sec. 3,")
    w("-- two years for representatives and four for senators.")
    w("--")
    w("-- CASE TRAP: essentials.districts stores LEGISLATIVE district rows with a LOWERCASE state")
    w("-- code ('ga', 'nc', 'ut' -- and now 'tn') while NATIONAL_LOWER, NATIONAL_UPPER and")
    w("-- STATE_EXEC use uppercase. A verification query filtering state = 'TN' reports ZERO")
    w("-- legislative districts even after a perfectly good seed. Every check below uses ILIKE.")
    w("--")
    w("-- Roster source (both chambers, retrieved %s, %dth General Assembly):" % (RETRIEVED, GA_NUM))
    for k in ("H", "S"):
        w("--   %s" % DIR_URL.format(k))
    for k in ("H", "S"):
        for r in vacant[k]:
            w("-- %s District %d is listed as Vacant by that directory, so its office is seeded with"
              % (CHAMBERS[k]["short"], r["district"]))
            w("-- is_vacant = true and NO office_terms row - the same shape Georgia Senate District 12")
            w("-- already uses.")
    w("-- 132 offices, %d occupants." % len(seated))
    w("--")
    w("-- term_start is left NULL with start_precision 'unknown'. The directory publishes no")
    w("-- assumed-office date, and the corpus semantic for this column is when the person took THIS")
    w("-- seat (cf. NC, where dates were cross-checked per member against Ballotpedia). Inventing a")
    w("-- date from the election calendar would mix semantics silently. NULL term_start still passes")
    w("-- essentials.current_office_holders. Populating them is owed follow-up work.")
    w("--")
    w('-- 🔴 ROUTING IS NOT WIRED UP. THIS SEED ALONE DOES NOT MAKE A LEGISLATOR REACHABLE.')
    w('-- essentials.geofence_boundaries DOES carry state-legislative polygons (G5210/G5220), for 19')
    w('-- states - including Georgia (236) and North Carolina (170). Tennessee has ZERO; its only')
    w('-- geofences are G4000/G4020/G5200/G5200V26/G6350. Measured after this migration applied:')
    w('-- POST /essentials/browse/by-government-list for Nashville returns "State of Tennessee: 1"')
    w('-- (the Governor), while the same call for Columbus GA returns 5 State House + 2 State Senate')
    w('-- members, routed by polygon. So these 132 offices are real and correct but not yet reachable')
    w('-- from an address or a landing chip.')
    w('-- Loading the polygons is a SEPARATE job: backend/scripts/load-state-tiger-boundaries.ts, which')
    w('-- requires adding TN to its STATE_LAYER_ALLOWLIST - a deliberate code change, because the')
    w('-- allowlist exists to force an explicit per-state review. Confirm FIRST that the TIGER vintage')
    w("-- matches Tennessee's current legislative map: routing a voter to the WRONG legislator is worse")
    w('-- than routing them to none.')
    w("--")
    w("-- Generated by backend/scripts/tn-general-assembly-seed-generate.py.")
    w("-- No migration runner exists; this file records SQL applied by hand as postgres via the")
    w("-- supabase-local MCP. Verified on row counts, not on absence of an error.")
    w("")
    w("BEGIN;")
    w("")
    w("-- ---------------------------------------------------------------------------------------")
    w("-- Guards")
    w("-- ---------------------------------------------------------------------------------------")
    w("DO $guard$")
    w("DECLARE v_gov uuid; n bigint;")
    w("BEGIN")
    w("  SELECT id INTO v_gov FROM essentials.governments WHERE geo_id = '47' AND type = 'STATE';")
    w("  IF v_gov IS NULL THEN")
    w("    RAISE EXCEPTION 'Migration %d: State of Tennessee government (geo_id 47) not found';" % mignum)
    w("  END IF;")
    w("")
    w("  SELECT count(*) INTO n FROM essentials.districts")
    w("   WHERE district_type IN ('STATE_LOWER','STATE_UPPER') AND state ILIKE 'tn';")
    w("  IF n <> 0 THEN")
    w("    RAISE EXCEPTION 'Migration %d: expected 0 pre-existing TN legislative districts, found %%', n;" % mignum)
    w("  END IF;")
    w("")
    w("  SELECT count(*) INTO n FROM essentials.politicians")
    w("   WHERE external_id BETWEEN -4729999 AND -4710000;")
    w("  IF n <> 0 THEN")
    w("    RAISE EXCEPTION 'Migration %d: external_id band -4729999..-4710000 is not free, found %%', n;" % mignum)
    w("  END IF;")
    w("")
    w("  SELECT count(*) INTO n FROM essentials.chambers")
    w("   WHERE government_id = v_gov AND name IN (%s);"
      % ", ".join(q(CHAMBERS[k]["name"]) for k in ("H", "S")))
    w("  IF n <> 0 THEN")
    w("    RAISE EXCEPTION 'Migration %d: TN legislative chambers already exist, found %%', n;" % mignum)
    w("  END IF;")
    w("END")
    w("$guard$;")
    w("")
    w("-- ---------------------------------------------------------------------------------------")
    w("-- 1. Chambers")
    w("-- ---------------------------------------------------------------------------------------")
    w("-- chambers.slug is a GENERATED column derived from name_formal (NOT name), so it is not")
    w("-- listed here - inserting into it raises 428C9. Setting name_formal is what produces the")
    w("-- slug the app routes on; leaving it NULL would generate an empty slug. For legislative")
    w("-- chambers GA/NC/UT all carry name = name_formal.")
    w("INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)")
    w("SELECT g.id, v.name, v.name, v.official_count, v.term_length")
    w("  FROM essentials.governments g")
    w("  CROSS JOIN (VALUES")
    w(",\n".join("    (%s, %d::bigint, %s)" % (q(CHAMBERS[k]["name"]), CHAMBERS[k]["count"],
                                               q(CHAMBERS[k]["term_length"])) for k in ("H", "S")))
    w("  ) AS v(name, official_count, term_length)")
    w(" WHERE g.geo_id = '47' AND g.type = 'STATE';")
    w("")
    w("-- ---------------------------------------------------------------------------------------")
    w("-- 2. Districts (132) -- state code LOWERCASE 'tn', matching ga/nc/ut")
    w("-- ---------------------------------------------------------------------------------------")
    w("-- Generated from the seat counts rather than listed one by one: the district numbers are")
    w("-- contiguous 1..99 and 1..33 (the generator asserts this against the directory, which lists")
    w("-- every one of them with no gaps), so generate_series cannot silently omit a district the")
    w("-- way a hand-written VALUES list can.")
    w("INSERT INTO essentials.districts (district_type, label, state, ocd_id, mtfcc, geo_id, representation_basis)")
    w("\nUNION ALL\n".join(
        "SELECT %s, %s || n, 'tn',\n"
        "       %s || n, %s, '47' || lpad(n::text, 3, '0'), 'residency'\n"
        "  FROM generate_series(1, %d) AS n" % (
            q(CHAMBERS[k]["district_type"]), q(CHAMBERS[k]["label"]),
            q("ocd-division/country:us/state:tn/%s:" % CHAMBERS[k]["sld"]),
            q(CHAMBERS[k]["mtfcc"]), CHAMBERS[k]["count"]) for k in ("H", "S")) + ";")
    w("")
    w("-- ---------------------------------------------------------------------------------------")
    w("-- 3. Offices (132), one per district. geo_id COLLIDES across chambers (House 1 and Senate 1")
    w("--    are both '47001'), so nothing in this file joins on geo_id alone.")
    w("-- ---------------------------------------------------------------------------------------")
    for k in ("H", "S"):
        cfg = CHAMBERS[k]
        w("INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats,")
        w("                                is_appointed_position, voting_powers, is_vacant)")
        w("SELECT c.id, d.id, %s, 'TN', 1, false, 'full'," % q(cfg["title"]))
        w("       %s" % ("d.ocd_id IN (%s)" % ", ".join(
            q("ocd-division/country:us/state:tn/%s:%d" % (cfg["sld"], r["district"]))
            for r in vacant[k]) if vacant[k] else "false"))
        w("  FROM essentials.districts d")
        w("  JOIN essentials.chambers c ON c.name = %s" % q(cfg["name"]))
        w("   AND c.government_id = (SELECT id FROM essentials.governments WHERE geo_id = '47' AND type = 'STATE')")
        w(" WHERE d.district_type = %s AND d.state = 'tn';" % q(cfg["district_type"]))
        w("")
    w("-- ---------------------------------------------------------------------------------------")
    w("-- 4. Officeholders (%d). party is left NULL, matching every GA/NC/UT legislator row." % len(seated))
    w("-- ---------------------------------------------------------------------------------------")
    for k in ("H", "S"):
        w("-- %s" % CHAMBERS[k]["name"])
        w("INSERT INTO essentials.politicians (external_id, full_name, first_name, middle_initial, last_name,")
        w("                                    name_suffix, preferred_name, data_source, is_incumbent, is_active)")
        w("SELECT v.external_id, v.full_name, v.first_name, v.middle_initial, v.last_name,")
        w("       v.name_suffix, v.preferred_name,")
        w("       %s," % q(cite[k]))
        w("       true, true")
        w("  FROM (VALUES")
        w(",\n".join(
            "    (%d::bigint, %s, %s, %s, %s, %s, %s)" % (
                CHAMBERS[k]["ext_prefix"] - r["district"], q(r["full"]), q(r["first"]),
                q(r["middle"]), q(r["last"]), q(r["suffix"]), q(r["preferred"]))
            for r in rows[k] if not r["vacant"]))
        w("  ) AS v(external_id, full_name, first_name, middle_initial, last_name,")
        w("         name_suffix, preferred_name);")
        w("")
    w("-- ---------------------------------------------------------------------------------------")
    w("-- 5. Occupancy. One office_terms row per seated member; a vacant seat gets none.")
    w("-- ---------------------------------------------------------------------------------------")
    for k in ("H", "S"):
        cfg = CHAMBERS[k]
        w("-- %s" % cfg["name"])
        w("INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end,")
        w("                                     start_precision, how_started, source)")
        w("SELECT o.id, p.id, NULL, NULL, 'unknown', 'elected', %s" % q(cite[k]))
        w("  FROM essentials.districts d")
        w("  JOIN essentials.offices o ON o.district_id = d.id")
        w("  -- external_id encodes the district: prefix minus the district number, and geo_id is")
        w("  -- '47' + the 3-digit district, so the number is geo_id::int - 47000.")
        w("  JOIN essentials.politicians p ON p.external_id = %d - (d.geo_id::int - 47000)" % cfg["ext_prefix"])
        w(" WHERE d.state = 'tn' AND d.district_type = %s" % q(cfg["district_type"]))
        w("   AND NOT o.is_vacant;")
        w("")
    w("-- ---------------------------------------------------------------------------------------")
    w("-- 6. Post-conditions -- counted with ILIKE so the lowercase/uppercase split cannot hide a")
    w("--    partial seed behind a confident zero.")
    w("-- ---------------------------------------------------------------------------------------")
    w("DO $verify$")
    w("DECLARE n bigint;")
    w("BEGIN")
    for k in ("H", "S"):
        cfg = CHAMBERS[k]
        w("  SELECT count(*) INTO n FROM essentials.districts")
        w("   WHERE district_type = %s AND state ILIKE 'tn';" % q(cfg["district_type"]))
        w("  IF n <> %d THEN RAISE EXCEPTION 'Migration %d: expected %d %s districts, got %%', n; END IF;"
          % (cfg["count"], mignum, cfg["count"], cfg["district_type"]))
    w("")
    w("  SELECT count(*) INTO n FROM essentials.offices o")
    w("    JOIN essentials.districts d ON d.id = o.district_id")
    w("   WHERE d.state ILIKE 'tn' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');")
    w("  IF n <> 132 THEN RAISE EXCEPTION 'Migration %d: expected 132 TN legislative offices, got %%', n; END IF;" % mignum)
    w("")
    w("  SELECT count(*) INTO n FROM essentials.districts d")
    w("    JOIN essentials.offices o ON o.district_id = d.id")
    w("   WHERE d.state ILIKE 'tn' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')")
    w("   GROUP BY d.id HAVING count(o.id) <> 1 LIMIT 1;")
    w("  IF FOUND THEN RAISE EXCEPTION 'Migration %d: a TN legislative district does not have exactly one office'; END IF;" % mignum)
    w("")
    w("  SELECT count(*) INTO n FROM essentials.current_office_holders coh")
    w("    JOIN essentials.offices o ON o.id = coh.office_id")
    w("    JOIN essentials.districts d ON d.id = o.district_id")
    w("   WHERE d.state ILIKE 'tn' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');")
    w("  IF n <> %d THEN RAISE EXCEPTION 'Migration %d: expected %d seated TN legislators, got %%', n; END IF;"
      % (len(seated), mignum, len(seated)))
    w("")
    w("  SELECT count(*) INTO n FROM essentials.offices o")
    w("    JOIN essentials.districts d ON d.id = o.district_id")
    w("   WHERE d.state ILIKE 'tn' AND d.district_type = 'STATE_LOWER' AND o.is_vacant;")
    w("  IF n <> %d THEN RAISE EXCEPTION 'Migration %d: expected exactly %d vacant TN House office(s), got %%', n; END IF;"
      % (n_vacant_lower, mignum, n_vacant_lower))
    w("")
    w("  -- the generated slug is what the app routes on; prove it came out right rather than empty")
    w("  SELECT count(*) INTO n FROM essentials.chambers c")
    w("   WHERE c.government_id = (SELECT id FROM essentials.governments WHERE geo_id = '47' AND type = 'STATE')")
    w("     AND c.slug IN ('tennessee-house-of-representatives','tennessee-senate');")
    w("  IF n <> 2 THEN RAISE EXCEPTION 'Migration %d: expected 2 TN legislative chamber slugs, got %%', n; END IF;" % mignum)
    w("END")
    w("$verify$;")
    w("")
    w("COMMIT;")
    w("")
    sys.stdout.write("\n".join(L))
    return 0


if __name__ == "__main__":
    sys.exit(main())
