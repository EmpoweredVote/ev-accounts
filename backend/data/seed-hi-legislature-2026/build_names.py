"""Split the Legislature's "Last, First M." listing into first/last/suffix, and emit SQL.

The listing is NOT a plain "Last, First". Three shapes appear and they are not
distinguishable by comma count alone:

    Rhoads, Karl                      -> Karl Rhoads
    Ihara, Jr., Les                   -> Les Ihara Jr.            (suffix in the MIDDLE)
    Richards, III, Herbert M. "Tim"   -> Herbert M. Richards III, called Tim
    San Buenaventura, Joy A.          -> Joy A. San Buenaventura  (multi-word SURNAME)
    Keohokapu-Lee Loy, Sue L.         -> Sue L. Keohokapu-Lee Loy (hyphen AND space)

🔴 A naive rsplit(',') puts "Jr." in the first-name column for two members and breaks the
duplicate-name guard, which keys on (first_name, last_name).

Nicknames in double quotes are pulled out as alternates rather than left inside first_name.
"""
import json
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")

SUFFIXES = {"Jr.", "Sr.", "II", "III", "IV", "V"}


def split_name(listed):
    parts = [p.strip() for p in listed.split(",")]
    suffix = None
    if len(parts) == 3 and parts[1] in SUFFIXES:
        last, suffix, first = parts[0], parts[1], parts[2]
    elif len(parts) == 2:
        last, first = parts[0], parts[1]
        # "Herbert M. "Tim"" may carry a trailing suffix token instead
        tail = first.split()
        if tail and tail[-1] in SUFFIXES:
            suffix = tail[-1]
            first = " ".join(tail[:-1])
    else:
        raise ValueError(f"unparsed name: {listed!r}")

    # A suffix can also be glued to the SURNAME with no comma: "Alcos III, David".
    lt = last.split()
    if len(lt) > 1 and lt[-1] in SUFFIXES:
        suffix = suffix or lt[-1]
        last = " ".join(lt[:-1])

    nick = None
    nm = re.search(r'"([^"]+)"', first)
    if nm:
        nick = nm.group(1)
        first = re.sub(r'\s*"[^"]+"\s*', " ", first).strip()

    # A LEADING SINGLE INITIAL is not a first name: "M. Cov" -> Cov. The duplicate-name
    # guard keys on (first_name, last_name), so storing "M." would weaken it to near-nothing.
    toks = first.split()
    given = ""
    if toks:
        given = toks[1] if (len(toks) > 1 and re.fullmatch(r"[A-Z]\.", toks[0])) else toks[0]
    full = " ".join(x for x in [first, last] if x)
    if suffix:
        full = f"{full} {suffix}"
    return {
        "full_name": full,
        "first_name": given,
        "last_name": last,
        "suffix": suffix,
        "nickname": nick,
        "first_full": first,
    }


rows = []
for ch, label in [("S", "Senate"), ("H", "House")]:
    for r in json.load(open(f"roster-{ch}.json", encoding="utf-8")):
        n = split_name(r["name_listed"])
        rows.append({**r, **n, "ch": ch})

print(f"{len(rows)} members parsed\n")
print("  rows where the split was NOT a plain two-part name:")
for r in rows:
    if r["suffix"] or r["nickname"] or " " in r["last_name"] or r["first_full"] != r["first_name"]:
        print(
            f"    {r['ch']}{r['district']:<3} listed={r['name_listed']:<34} -> "
            f"full={r['full_name']:<32} first={r['first_name']:<10} last={r['last_name']:<22}"
            f"{' suffix=' + r['suffix'] if r['suffix'] else ''}"
            f"{' nick=' + r['nickname'] if r['nickname'] else ''}"
        )

json.dump(rows, open("roster-all.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(f"\nwrote roster-all.json ({len(rows)} rows)")

# A VALUES list for the prod identity scan.
vals = ",\n".join(
    "  (" + ",".join("'" + x.replace("'", "''") + "'" for x in (r["first_name"], r["last_name"], r["full_name"])) + ")"
    for r in rows
)
open("names_values.sql", "w", encoding="utf-8").write(vals)
print("wrote names_values.sql")
