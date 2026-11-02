"""Replace the HTML-stripped text of PDF sources with pdftotext output (STAGE5 step 7.4).
python3 -I scripts/stage5/pdf_pages.py <batch dir>
Reads <batch>/evidence-missing.json; for each PDF URL saves <batch>/pdf/<sha1>.pdf and rewrites pages/<sha1>.txt."""
import json, hashlib, subprocess, os, re, sys
# ⚠ BROWSER USER-AGENT — a deliberate exception to decision 0003 (ev-cto knowledge/decisions/0003-scraping-toolchain.md), ruled
# 2026-10-31 by Chris Andrews: kept for LOCAL research runs only, never in a live or scheduled fetch path. A page read
# this way is NOT proof the verifier can read it: the verifier sends the honest EmpoweredVoteBot identity
# (src/lib/verificationFetch.ts), so it may still fail there. iga.in.gov is NOT fetched this way: it goes through the
# official MyIGA API (_iga.py → iga-pages.ts, the same reader the verifier uses).
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _iga import is_iga, iga_text
B = sys.argv[1]; os.makedirs(f'{B}/pdf', exist_ok=True)
for u in sorted({x[1] for x in json.load(open(f'{B}/evidence-missing.json')) if '.pdf' in x[1].lower()}):
    h = hashlib.sha1(u.encode()).hexdigest(); pdf = f'{B}/pdf/{h}.pdf'
    if is_iga(u):  # official API text (a roll call as its member-by-vote render), written to pages/<sha1>.txt
        t = iga_text(u, f'{B}/pages'); print(u, len(t or '')); continue
    if not os.path.exists(pdf): subprocess.run(['curl', '-sL', '--compressed', '--max-time', '90', '-A', 'Mozilla/5.0', u.split('#')[0], '-o', pdf])
    t = re.sub(r'\s+', ' ', subprocess.run(['pdftotext', '-layout', pdf, '-'], capture_output=True).stdout.decode('utf-8', 'replace')).strip()
    open(f'{B}/pages/{h}.txt', 'w').write(t); print(u, len(t))
