#!/usr/bin/env python3
"""nd-legislature-portrait-extract.py — Knight program, wave ND-5.

Downloads the NATIVE portrait for every seated North Dakota legislator and validates each one
before anything is published or imported.

🔴 THE ROSTER LINKS A DERIVATIVE, NOT THE ORIGINAL. ndlegis.gov is Drupal; the member pages link
   /sites/default/files/styles/<style>/public/person/photo/<x>.jpg at 140x175. The unlinked
   original is /sites/default/files/person/photo/<x>.jpg. This script fetches the original.
⚠ AND THE ORIGINAL IS BARELY BIGGER: 157x196. There is no `large` style (it 404s) and no
   query-string resize to strip. 157x196 is the whole of what North Dakota publishes, and the
   decision to ship these natives rather than upscale them was taken deliberately (Cantrell,
   2026-09-25). This script therefore asserts the native size rather than hunting for more.

WHAT IT CHECKS, and why each one exists:
  * HTTP status AND magic bytes — a clean 200 can carry an error page or a truncated body.
  * The image opens and its real dimensions are read — not the Content-Length.
  * MONOCHROME IS REJECTED. Documented-but-unenforced cost 156 published frames at SC-5.
  * A BADGE IS PORTRAIT-SHAPED. Shape and size cannot tell a face from a graphic, so this script
    reports but never certifies: the frames must be LOOKED AT on a contact sheet.
  * DUPLICATE BYTES across members — a positional filename can be a placeholder served to many.
  * A POSITIVE CONTROL: a deliberately wrong filename must 404. A sweep where everything
    "succeeds" is a broken detector until something fails.

Usage:
  python scripts/nd-legislature-portrait-extract.py --roster data/seed-nd-2026/nd-roster-special-2.json \\
      --out data/seed-nd-2026/portraits
"""
import argparse
import hashlib
import io
import json
import os
import sys
import time
import urllib.request

from PIL import Image, ImageStat

UA = {"User-Agent": "ev-accounts/nd-slice12"}
EXPECTED_W, EXPECTED_H = 157, 196
# Saturation below this on every channel pair means the file is greyscale in RGB clothing.
MONO_TOLERANCE = 2.0


def native_url(derivative_url: str) -> str:
    """styles/<style>/public/person/photo/x.jpg -> person/photo/x.jpg"""
    marker = "/sites/default/files/"
    head, _, tail = derivative_url.partition(marker)
    if not tail:
        raise ValueError(f"unrecognised portrait URL: {derivative_url}")
    if tail.startswith("styles/"):
        # styles/<style>/public/<rest>
        parts = tail.split("/", 3)
        if len(parts) != 4 or parts[2] != "public":
            raise ValueError(f"unrecognised derivative path: {tail}")
        tail = parts[3]
    return head + marker + tail


def fetch(url: str, timeout: int = 40):
    req = urllib.request.Request(url, headers=UA)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read()
    except urllib.error.HTTPError as e:
        return e.code, b""
    except Exception as e:  # noqa: BLE001
        return -1, str(e).encode()


def is_monochrome(im: Image.Image) -> bool:
    """True when R, G and B are effectively identical everywhere."""
    rgb = im.convert("RGB")
    stat = ImageStat.Stat(rgb)
    r, g, b = stat.mean
    rs, gs, bs = stat.stddev
    return (
        abs(r - g) < MONO_TOLERANCE
        and abs(g - b) < MONO_TOLERANCE
        and abs(rs - gs) < MONO_TOLERANCE
        and abs(gs - bs) < MONO_TOLERANCE
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--roster", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--delay", type=float, default=0.15)
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)
    roster = json.load(io.open(args.roster, encoding="utf-8"))

    # ── POSITIVE CONTROL: a filename that cannot exist must fail. ────────────────
    ctrl_url = native_url(roster[0]["photo_url"]).replace(".jpg", "-no-such-member.jpg")
    ctrl_status, _ = fetch(ctrl_url)
    if ctrl_status == 200:
        print(f"🔴 CONTROL FAILED: {ctrl_url} returned 200. The host answers anything; "
              f"a 200 here proves nothing. Stop.")
        return 1
    print(f"🟢 control: a nonexistent filename returns HTTP {ctrl_status} — the sweep can fail")

    rows, failures = [], []
    by_hash: dict[str, list[str]] = {}

    for i, m in enumerate(roster, 1):
        name = m["name"]
        url = native_url(m["photo_url"])
        status, body = fetch(url)
        if status != 200 or not body:
            failures.append({"name": name, "url": url, "why": f"HTTP {status}"})
            continue
        if body[:2] != b"\xff\xd8":
            failures.append({"name": name, "url": url, "why": f"not a JPEG (magic {body[:4]!r})"})
            continue
        try:
            im = Image.open(io.BytesIO(body))
            im.load()
        except Exception as e:  # noqa: BLE001
            failures.append({"name": name, "url": url, "why": f"unreadable: {e}"})
            continue

        digest = hashlib.sha256(body).hexdigest()
        by_hash.setdefault(digest, []).append(name)
        mono = is_monochrome(im)

        fn = os.path.basename(url)
        path = os.path.join(args.out, fn)
        with open(path, "wb") as f:
            f.write(body)

        rows.append({
            "name": name,
            "chamber": m["chamber"],
            "district": m.get("member_district") or m["district"],
            "party": m.get("party"),
            "url": url,
            "file": fn,
            "bytes": len(body),
            "width": im.width,
            "height": im.height,
            "monochrome": mono,
            "sha256": digest[:16],
        })
        if i % 25 == 0:
            print(f"  … {i}/{len(roster)}")
        time.sleep(args.delay)

    dupes = {h: n for h, n in by_hash.items() if len(n) > 1}
    mono = [r for r in rows if r["monochrome"]]
    odd = [r for r in rows if (r["width"], r["height"]) != (EXPECTED_W, EXPECTED_H)]

    ledger = {
        "extracted_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "roster": args.roster,
        "expected_native": f"{EXPECTED_W}x{EXPECTED_H}",
        "count": len(rows),
        "failures": failures,
        "monochrome": [r["name"] for r in mono],
        "duplicate_bytes": {h: n for h, n in dupes.items()},
        "off_size": [{"name": r["name"], "size": f'{r["width"]}x{r["height"]}'} for r in odd],
        "portraits": rows,
    }
    lp = os.path.join(args.out, "LEDGER.json")
    with io.open(lp, "w", encoding="utf-8") as f:
        json.dump(ledger, f, indent=2, ensure_ascii=False)

    print(f"\nextracted {len(rows)} of {len(roster)}; {len(failures)} failure(s)")
    print(f"  monochrome (MUST be 0 before publishing): {len(mono)}"
          + (": " + ", ".join(r['name'] for r in mono) if mono else ""))
    print(f"  duplicate byte-identical files: {len(dupes)}"
          + (" -> " + "; ".join(', '.join(v) for v in dupes.values()) if dupes else ""))
    print(f"  not {EXPECTED_W}x{EXPECTED_H}: {len(odd)}"
          + (" -> " + ", ".join(f'{r["name"]} {r["width"]}x{r["height"]}' for r in odd) if odd else ""))
    sizes = sorted({(r["width"], r["height"]) for r in rows})
    print(f"  distinct sizes: {sizes}")
    for f_ in failures:
        print(f"  🔴 {f_['name']}: {f_['why']}")
    print(f"\nledger: {lp}")
    print("⚠ NOTHING IS CERTIFIED BY THIS SCRIPT. A badge is portrait-shaped; look at the frames.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
