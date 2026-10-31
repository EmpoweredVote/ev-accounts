"""Replace the HTML-stripped text of PDF sources with pdftotext output (STAGE5 step 7.4).
python3 -I scripts/stage5/pdf_pages.py <batch dir>
Reads <batch>/evidence-missing.json; for each PDF URL saves <batch>/pdf/<sha1>.pdf and rewrites pages/<sha1>.txt."""
import json, hashlib, subprocess, os, re, sys
# ⚠ BROWSER USER-AGENT — a deliberate exception to decision 0003 (ev-cto knowledge/decisions/0003-scraping-toolchain.md), ruled
# 2026-10-31 by Chris Andrews: kept for LOCAL research runs only, never in a live or scheduled fetch path. Some sites
# (iga.in.gov) serve their files only to a browser identity. A page read this way is NOT proof the verifier can read it:
# the verifier sends the honest EmpoweredVoteBot identity (src/lib/verificationFetch.ts), so it may still fail there.
B = sys.argv[1]; os.makedirs(f'{B}/pdf', exist_ok=True)
for u in sorted({x[1] for x in json.load(open(f'{B}/evidence-missing.json')) if '.pdf' in x[1].lower()}):
    h = hashlib.sha1(u.encode()).hexdigest(); pdf = f'{B}/pdf/{h}.pdf'
    if not os.path.exists(pdf): subprocess.run(['curl', '-sL', '--compressed', '--max-time', '90', '-A', 'Mozilla/5.0', u.split('#')[0], '-o', pdf])
    t = re.sub(r'\s+', ' ', subprocess.run(['pdftotext', '-layout', pdf, '-'], capture_output=True).stdout.decode('utf-8', 'replace')).strip()
    open(f'{B}/pages/{h}.txt', 'w').write(t); print(u, len(t))
