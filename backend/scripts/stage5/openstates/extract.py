"""Pull one state's rows out of an Open States monthly PostgreSQL dump.

No LegiScan calls. Open States data is public domain.

Get the dump (about 11 GB, no sign-in, new each month):
    curl -o /path/YYYY-MM-public.pgdump https://data.openstates.org/postgres/monthly/YYYY-MM-public.pgdump

Usage:
    python3 -I extract.py <dump> <state, e.g. wa> <work dir>

<work dir> is the local folder that holds id_registry.json (never the repo): the rows go to
<work dir>/extracts/<YYYY-MM>/<state>/, where convert.py looks for them. Writes one TSV per table
(Postgres COPY text format, header row first) plus extract.json with the row counts.
Needs pg_restore 17 (brew install postgresql@17). Takes a few minutes; the dump can be deleted after.
"""
import json, os, re, subprocess, sys, datetime

PR = "/opt/homebrew/opt/postgresql@17/bin/pg_restore"
dump, st = sys.argv[1], sys.argv[2].lower()
month = (re.search(r"(\d{4}-\d{2})-public", os.path.basename(dump)) or [None, "unknown"])[1]
if len(sys.argv) < 4:
    sys.exit("usage: extract.py <dump> <state> <work dir>   (the local folder that holds id_registry.json)")
out = os.path.join(os.path.abspath(sys.argv[3]), "extracts", month, st)
os.makedirs(out, exist_ok=True)
JUR = f"ocd-jurisdiction/country:us/state:{st}/government"


def stream(table):
    p = subprocess.Popen([PR, "-a", "-t", table, "-f", "-", dump], stdout=subprocess.PIPE, text=True, bufsize=1 << 20)
    cols, inside = None, False
    for line in p.stdout:
        if line.startswith("COPY "):
            cols = [c.strip().strip('"') for c in line[line.index("(") + 1:line.index(")")].split(",")]
            inside = True
            continue
        if inside:
            if line.startswith("\\."):
                inside = False
                continue
            yield cols, line.rstrip("\n").split("\t")
    if p.wait() != 0:
        sys.exit(f"pg_restore failed on {table}")


counts = {}


def run(table, keep, collect=None):
    n = 0
    with open(os.path.join(out, table.replace("opencivicdata_", "") + ".tsv"), "w") as f:
        hdr = False
        for cols, row in stream(table):
            if not hdr:
                f.write("\t".join(cols) + "\n"); hdr = True
            r = dict(zip(cols, row))
            if keep(r):
                f.write("\t".join(row) + "\n"); n += 1
                if collect:
                    collect(r)
    counts[table] = n
    print(table, n, flush=True)


S, B, V, P, VER, ORG = set(), set(), set(), set(), set(), set()
add = lambda s, k: (lambda r: r[k] != "\\N" and s.add(r[k]))
run("opencivicdata_legislativesession", lambda r: r["jurisdiction_id"] == JUR, add(S, "id"))
run("opencivicdata_organization", lambda r: r["jurisdiction_id"] == JUR, add(ORG, "id"))
run("opencivicdata_post", lambda r: r["organization_id"] in ORG)
run("opencivicdata_membership", lambda r: r["organization_id"] in ORG, add(P, "person_id"))
run("opencivicdata_bill", lambda r: r["legislative_session_id"] in S, add(B, "id"))
run("opencivicdata_billabstract", lambda r: r["bill_id"] in B)
run("opencivicdata_billaction", lambda r: r["bill_id"] in B)
run("opencivicdata_billsource", lambda r: r["bill_id"] in B)
run("opencivicdata_billsponsorship", lambda r: r["bill_id"] in B, add(P, "person_id"))
run("opencivicdata_billversion", lambda r: r["bill_id"] in B, add(VER, "id"))
run("opencivicdata_billversionlink", lambda r: r["version_id"] in VER)
run("opencivicdata_voteevent", lambda r: r["legislative_session_id"] in S, add(V, "id"))
run("opencivicdata_votecount", lambda r: r["vote_event_id"] in V)
run("opencivicdata_votesource", lambda r: r["vote_event_id"] in V)
run("opencivicdata_personvote", lambda r: r["vote_event_id"] in V, add(P, "voter_id"))
run("opencivicdata_person", lambda r: r["id"] in P)
run("opencivicdata_personidentifier", lambda r: r["person_id"] in P)
json.dump({"dump": os.path.basename(dump), "month": month, "state": st, "jurisdiction": JUR,
           "extracted_at": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
           "rows": counts}, open(os.path.join(out, "extract.json"), "w"), indent=1)
print("wrote", out)
