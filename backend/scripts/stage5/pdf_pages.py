"""Replace the HTML-stripped text of PDF sources with pdftotext output (STAGE5 step 7.4).
python3 -I scripts/stage5/pdf_pages.py <batch dir>
Reads <batch>/evidence-missing.json; for each PDF URL saves <batch>/pdf/<sha1>.pdf and rewrites pages/<sha1>.txt."""
import json, hashlib, subprocess, os, re, sys
B = sys.argv[1]; os.makedirs(f'{B}/pdf', exist_ok=True)
for u in sorted({x[1] for x in json.load(open(f'{B}/evidence-missing.json')) if '.pdf' in x[1].lower()}):
    h = hashlib.sha1(u.encode()).hexdigest(); pdf = f'{B}/pdf/{h}.pdf'
    if not os.path.exists(pdf): subprocess.run(['curl', '-sL', '--compressed', '--max-time', '90', '-A', 'Mozilla/5.0', u.split('#')[0], '-o', pdf])
    t = re.sub(r'\s+', ' ', subprocess.run(['pdftotext', '-layout', pdf, '-'], capture_output=True).stdout.decode('utf-8', 'replace')).strip()
    open(f'{B}/pages/{h}.txt', 'w').write(t); print(u, len(t))
