# Audit the web service's sponsor list against the list printed on the bill itself.
#
# 🔴 WHY THIS EXISTS. The sponsorship index has exactly ONE source — SponsorService/GetSponsors — and
# a cohort migration seats everyone that source names. If the service under-reports, the migration is
# short a member and NOTHING downstream shows it: the guards check the rows that were written, the
# gate checks orphans, and a missing person looks identical to a person who never sponsored anything.
# Confirmed on SB 6346 (the millionaires' tax): the service returned 26 sponsors, the enrolled session
# law names 27. Adrian Cortes was missing, and migration 1770 was short his row until 1776 added it.
#
# Two false alarms this will raise, both benign:
#   · NAME CHANGES. Member 20760 is printed as "Caldier" on bills introduced in January 2025 and as
#     "Valdez" by the service today. Same member ID, same person — always compare IDs before believing
#     a surname mismatch.
#   · REGEX TRUNCATION. Sponsor lines run straight into the bill text on some PDFs, so a stray token
#     like "(3" can appear as a printed-only name. Read the line before treating it as a finding.
#
# Usage:  py wa_audit_sponsors.py "SB 6346:Senate%20Bills/6346.pdf" ["HB 1435:House%20Bills/1435.pdf" ...]
#         Session laws live under Session%20Laws/{House,Senate}/, joint resolutions under
#         Senate%20Joint%20Resolutions/. Bills are cached under %TEMP%/ev-stance-cache/wa-leg/pdf/.
import json, os, re, subprocess, sys
from pypdf import PdfReader

C = os.path.join(os.environ["TEMP"], "ev-stance-cache", "wa-leg")
PDF = os.path.join(C, "pdf")
os.makedirs(PDF, exist_ok=True)
BASE = "https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/"
SPLIT = re.compile(r",\s*and\s+|,\s*|\s+and\s+")

for arg in sys.argv[1:]:
    bill_id, path = arg.split(":", 1)
    stem = re.sub(r"\W+", "_", bill_id)
    cache = os.path.join(C, "bills", bill_id.replace(" ", "_") + ".json")
    if not os.path.exists(cache):
        print(f"skip     {bill_id:9} — not in the bill cache")
        continue
    pdf = os.path.join(PDF, stem + ".pdf")
    if not os.path.exists(pdf):
        subprocess.run(["curl", "-s", "-o", pdf, BASE + path], check=True)
    try:
        txt = "\n".join((p.extract_text() or "") for p in PdfReader(pdf).pages[:3])
    except Exception as e:
        print(f"skip     {bill_id:9} — unreadable ({e})")
        continue
    flat = re.sub(r"\s+", " ", re.sub(r"\n\s*\d+\s*", " ", txt))
    m = re.search(r"(?:originally sponsored by|By) (?:Senators?|Representatives?) (.+?)"
                  r"(?:\)|Read first time|Prefiled|READ FIRST TIME|By request)", flat)
    if not m:
        print(f"skip     {bill_id:9} — sponsor line not found")
        continue
    printed = {s.strip(" .;").split()[-1].lower() for s in SPLIT.split(m.group(1)) if s.strip(" .;")}
    svc = {s["name"].split()[-1].lower().strip(",")
           for s in json.load(open(cache, encoding="utf-8"))["sponsors"] if s.get("id")}
    missing, extra = sorted(printed - svc), sorted(svc - printed)
    flag = "MISSING!" if missing else "ok      "
    print(f"{flag} {bill_id:9} printed={len(printed):3} service={len(svc):3} "
          f"not_in_service={missing if missing else '-'} only_in_service={extra if extra else '-'}")
