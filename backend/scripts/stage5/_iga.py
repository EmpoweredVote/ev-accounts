"""iga.in.gov for the Python batch tools: one reader, shared with the verifier.
iga.in.gov answers a plain fetch with a JavaScript shell. The official MyIGA API serves the same records
(scripts/stage5/iga-pages.ts → src/lib/adapters/igaAdapter.ts, IGA_API_KEY in backend/.env). The text saved
here is exactly what the verifier will read, so a snippet cut from it can verify."""
import hashlib, os, subprocess
from urllib.parse import urlparse

BACKEND = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))


def is_iga(url):
    try: return urlparse(url).hostname in ('iga.in.gov', 'www.iga.in.gov')
    except ValueError: return False


def iga_text(url, pages_dir):
    """Save and return the API text for an iga.in.gov URL (pages_dir/<sha1>.txt), or None when it cannot be read."""
    f = os.path.join(pages_dir, hashlib.sha1(url.encode()).hexdigest() + '.txt')
    if not os.path.exists(f):
        os.makedirs(pages_dir, exist_ok=True)
        subprocess.run(['npx', 'tsx', '--env-file=.env', 'scripts/stage5/iga-pages.ts', os.path.abspath(pages_dir), url],
                       cwd=BACKEND, capture_output=True)
    return open(f).read() if os.path.exists(f) else None
