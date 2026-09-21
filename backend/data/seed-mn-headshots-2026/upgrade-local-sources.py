"""
Try for a bigger copy of each local portrait, and keep the upgrade ONLY when it decodes and is
actually larger.

Every rule upgrades within the SAME host, keeping the same filename or the person's name in the
path, so an upgrade cannot quietly become a different person:
  stpaul.gov       /styles/<style>/public/ is a Drupal derivative; the original sits at the same
                   path without it. 325x260 -> 1200x960.
  stlouiscountymn  the Board of Commissioners folder holds 480x720 portraits keyed by full name,
                   where the e-graphics folder holds 200x300 ones.
Ramsey publishes its portraits pre-sized at 200x250 and has no larger copy -- the bare filename
404s. Measured, not worked around.

🔴 THIS RUNS ON requests, NOT node fetch. The first cut used node's fetch and reported "0 of 37
upgraded" -- not because no upgrade exists, but because these hosts refuse node's TLS fingerprint
and the failure looked exactly like an honest negative.
"""
import json
import re
from io import BytesIO
from urllib.parse import quote, unquote, urlparse

import requests
from PIL import Image

P = "data/seed-mn-headshots-2026/candidates-local.json"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"}
cands = json.load(open(P, encoding="utf-8"))


def variants(c):
    host = urlparse(c["url"]).netloc
    out = []
    if host.endswith("stpaul.gov"):
        # The derivative carries THREE marks, and all three have to come off: the style segment,
        # the `.webp` Drupal appends when it re-encodes, and the `itok` token that signs the
        # derivative. Stripping only the style segment returns the same 325px file.
        v = re.sub(r"/styles/[^/]+/public/", "/", c["url"].split("?")[0])
        out.append(re.sub(r"\.webp$", "", v))
    if host.endswith("stlouiscountymn.gov"):
        name = re.sub(r"\s+[A-Z]\.\s+", " ", c["name"])
        out.append("https://www.stlouiscountymn.gov/portals/0/Library/Dept/"
                   + quote(f"Board of Commissioners/images/{name}.jpg"))
    return out


def measure(url):
    try:
        r = requests.get(url, headers=UA, timeout=60)
        if r.status_code != 200 or len(r.content) < 2000:
            return None
        im = Image.open(BytesIO(r.content))
        im.load()                       # full decode, never a header sniff
        return im.size
    except Exception:                   # noqa: BLE001
        return None


upgraded = 0
for c in cands:
    now = measure(c["url"])
    if not now:
        print(f"  !! {c['name']}: current source did not decode")
        continue
    for v in variants(c):
        if unquote(v) == unquote(c["url"]):
            continue
        alt = measure(v)
        if alt and alt[0] * alt[1] > now[0] * now[1]:
            print(f"  upgrade {c['name']:<24} {now[0]}x{now[1]} -> {alt[0]}x{alt[1]}")
            c["_derivative_url"] = c["url"]
            c["url"] = v
            upgraded += 1
            break

json.dump(cands, open(P, "w", encoding="utf-8"), indent=1)
print(f"upgraded {upgraded} of {len(cands)}")
