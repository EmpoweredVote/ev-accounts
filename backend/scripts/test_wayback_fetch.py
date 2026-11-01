"""Controls for wayback_fetch. The point of the module is that it STOPS; prove it stops."""
import sys, urllib.error, urllib.request, io
sys.path.insert(0, '.')
import wayback_fetch as wf

class FakeResp(io.BytesIO):
    def __init__(self, data): super().__init__(data); self.headers = {}
    def __enter__(self): return self
    def __exit__(self, *a): return False

def run(codes, max_429=3):
    seq = list(codes)
    def fake_urlopen(req, timeout=None):
        c = seq.pop(0)
        if c == 200: return FakeResp(b'x' * 5000)
        raise urllib.error.HTTPError(req.full_url, c, 'nope', {}, None)
    wf.urllib.request.urlopen = fake_urlopen
    c = wf.WaybackClient(min_gap=0, max_429=max_429, log=lambda *a: None)
    c._wait = lambda extra=0: None
    import time as _t; _t.sleep = lambda s: None
    out = []
    try:
        for _ in codes: out.append(c.get('https://web.archive.org/x'))
    except wf.Blocked as e:
        return 'BLOCKED', out
    return 'ran', out

# 1. Three 429s in a row must STOP the run.
r, _ = run([429, 429, 429])
assert r == 'BLOCKED', f'CONTROL FAILED: three consecutive 429s did not stop the run ({r})'

# 2. Two 429s must NOT stop it -- a throttle is survivable, a block is not.
r, _ = run([429, 429])
assert r == 'ran', f'CONTROL FAILED: two 429s stopped the run, which would abort on a blip ({r})'

# 3. A success between 429s must RESET the streak, or a long run dies of unrelated blips.
r, _ = run([429, 429, 200, 429, 429])
assert r == 'ran', f'CONTROL FAILED: a 200 did not reset the 429 streak ({r})'

# 4. A 404 is a missing capture, never a block.
r, out = run([404, 404, 404, 404])
assert r == 'ran' and out == [None]*4, f'CONTROL FAILED: 404s treated as a block ({r})'

print('CONTROL OK  stops on 3 consecutive 429s; survives 2; a 200 resets; 404 is not a block')
