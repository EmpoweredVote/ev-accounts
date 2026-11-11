"""archive.org fallback for the Python batch tools: one reader, shared with the verifier.
When the live fetch fails, the verifier reads the page's newest archive.org snapshot (tier 3 of
src/lib/verificationFetch.ts). build_evidence.py now does the same, through archive-pages.ts, so a page the verifier can
read is not listed as unread (wi-01, 2026-11-10: David Crowley held over two wispolitics.com pages that verified)."""
import hashlib, os, subprocess

BACKEND = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))

# Mirrors MIN_REAL_PAGE_CHARS and CHALLENGE_MARKERS in src/lib/verificationFetch.ts (looksLikeRealPage). Keep in step.
MIN_REAL_PAGE_CHARS = 500
CHALLENGE_MARKERS = ('just a moment', 'enable javascript', 'please enable js', 'cf-browser-verification',
                     'checking your browser', 'verifying you are human', 'attention required', 'access denied',
                     'request unsuccessful')


def live_failed(status, text):
    """True when a live fetch did not return a real page: a non-2xx status (403 from a firewall, 404, a timeout's 000),
    or a body the verifier's looksLikeRealPage would refuse (too short, or a short challenge page)."""
    if not (200 <= int(status or 0) < 300): return True
    if not text or len(text) < MIN_REAL_PAGE_CHARS: return True
    low = text.lower()
    return len(text) < 2000 and any(m in low for m in CHALLENGE_MARKERS)


def archive_text(url, pages_dir):
    """Save and return the archive.org text for a URL (pages_dir/<sha1>.txt), or None when there is no usable snapshot."""
    f = os.path.join(pages_dir, hashlib.sha1(url.encode()).hexdigest() + '.txt')
    if os.path.exists(f): os.remove(f)  # a live failure's body must never stand in for the page
    os.makedirs(pages_dir, exist_ok=True)
    subprocess.run(['npx', 'tsx', '--env-file=.env', 'scripts/stage5/archive-pages.ts', os.path.abspath(pages_dir), url],
                   cwd=BACKEND, capture_output=True)
    return open(f).read() if os.path.exists(f) else None
