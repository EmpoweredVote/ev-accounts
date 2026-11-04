#!/usr/bin/env python3
"""
A POLITE Wayback Machine client. Import this instead of hand-rolling urllib in each wave.

🔴🔴 WHY THIS EXISTS: on 2026-10-31 the Hinds County portrait wave got this machine's IP put on
the Internet Archive's block list -- "suspected abusive bot traffic that is degrading the
performance of the Wayback Machine" -- partway through fetching 12 image files. Nothing exotic
caused it. Two ordinary mistakes did:

  1. A BURST. 47 replay requests went out back to back with a 1-second sleep. The Wayback replay
     endpoints (/web/<ts>id_/, /web/<ts>im_/) are the expensive, rate-limited ones; a burst is
     exactly the shape their abuse detector looks for.
  2. RETRYING THROUGH THE 429. Each failure retried with a short backoff, so the moment the
     throttle appeared the script started hammering the thing that was asking it to stop.
     🔴 A 429 IS AN INSTRUCTION, NOT AN ERROR. Retrying through one is what converts a
     temporary throttle into an IP-level block, and the block then outlasts the session.

RULES THIS MODULE ENFORCES, so no caller has to remember them:
  * ONE request at a time, never concurrent, with a minimum gap between any two (default 10s).
  * `Retry-After` is OBEYED when the server sends one.
  * CONSECUTIVE 429s ABORT THE RUN. Two in a row means backed-off waiting; `max_429` in a row
    means stop and tell the human. The run never "pushes through".
  * An HONEST, IDENTIFYING User-Agent with a contact address. 🔴 Do NOT spoof a browser here.
    archive.org's block notice asks you to identify yourself and email info@archive.org; a
    Chrome UA makes a legitimate civic-data fetch indistinguishable from the abuse they are
    blocking, and removes their ability to whitelist you.
  * RESUME IS FREE: anything already on disk is skipped, so a blocked run costs nothing and a
    retry does not re-fetch.

⚠ DISCOVERY IS CHEAPER THAN REPLAY. The CDX API (/cdx/search/cdx) is a different, lighter
endpoint. Enumerate with CDX, then fetch only the captures you actually need -- do not walk a
site by replaying pages to find links.
"""
import gzip, os, sys, time, urllib.error, urllib.request

CONTACT = os.environ.get('ARCHIVE_CONTACT', 'chris@empowered.vote')
UA = f'EmpoweredVote-civic-data/1.0 (+https://empowered.vote; {CONTACT})'

class Blocked(RuntimeError):
    """The archive asked us to stop. Do not catch this to retry -- let the run end."""

class WaybackClient:
    def __init__(self, min_gap=10.0, max_429=3, timeout=90, log=print):
        self.min_gap, self.max_429, self.timeout, self.log = min_gap, max_429, timeout, log
        self._last = 0.0
        self._streak = 0

    def _wait(self, extra=0.0):
        gap = self.min_gap + extra - (time.monotonic() - self._last)
        if gap > 0: time.sleep(gap)

    def get(self, url):
        """One replay fetch. Returns bytes, or None if this capture is genuinely unavailable.
        Raises Blocked when the archive has told us to stop."""
        self._wait()
        req = urllib.request.Request(url, headers={'User-Agent': UA, 'Accept-Encoding': 'gzip'})
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as r:
                data = r.read()
            self._last = time.monotonic(); self._streak = 0
            if data[:2] == b'\x1f\x8b':
                try: data = gzip.decompress(data)
                except Exception: pass
            return data
        except urllib.error.HTTPError as e:
            self._last = time.monotonic()
            if e.code in (429, 403):
                self._streak += 1
                if self._streak >= self.max_429:
                    raise Blocked(
                        f'archive.org returned {e.code} {self._streak}x in a row. STOPPING.\n'
                        f'  This is a block, not a throttle: do not retry in a loop.\n'
                        f'  Wait hours, not minutes. If it persists, email info@archive.org '
                        f'from {CONTACT} with the IP and this User-Agent:\n  {UA}') from None
                # obey Retry-After when offered, else back off hard and linearly
                ra = e.headers.get('Retry-After')
                wait = min(float(ra), 600.0) if (ra or '').isdigit() else 60.0 * self._streak
                self.log(f'   {e.code} from archive.org -- backing off {wait:.0f}s '
                         f'({self._streak}/{self.max_429} before stopping)')
                time.sleep(wait)
                return None
            if e.code == 404:
                self._streak = 0; return None
            raise
        except Exception as e:
            self._last = time.monotonic()
            self.log(f'   {type(e).__name__} -- treating as a miss, not a block')
            return None

    def save(self, url, dest, min_bytes=3000):
        """Fetch to dest unless it already exists. Returns True if dest now holds a real file."""
        if os.path.exists(dest) and os.path.getsize(dest) >= min_bytes:
            return True
        data = self.get(url)
        if not data or len(data) < min_bytes:
            return False
        os.makedirs(os.path.dirname(dest) or '.', exist_ok=True)
        with open(dest, 'wb') as f: f.write(data)
        return True
