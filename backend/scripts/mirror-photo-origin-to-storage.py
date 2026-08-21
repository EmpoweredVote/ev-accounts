#!/usr/bin/env python
"""
Mirror hotlinked photo_origin_url portraits into Supabase Storage and create the
politician_images rows that make them the canonical render.

WHY. photo_origin_url pointing at somebody else's host is a live dependency. The
Colorado wave proved the failure mode before it even shipped: 7 of 92
leg.colorado.gov portrait URLs were already HTTP 404, and they are signed Rails
active_storage redirects that can expire with no warning. Worse,
HAS_RENDERABLE_PHOTO_SQL counts any photo_origin_url LIKE 'http%' as coverage, so
rot reads as "covered" until somebody looks.

WHAT IT DOES NOT DO. It does not clear photo_origin_url. That column is the
PROVENANCE of the image and stays pointing at the source; politician_images.url
becomes the thing that renders, and hasRenderablePhoto() checks images first.

SAFETY
  * Refuses to write anything for a URL whose bytes are not a real image. The
    check is the MAGIC NUMBER, never the extension and never r.ok -- a WAF
    rejection can be HTTP 200.
  * NEVER ENLARGES past --max-upscale (default 1.0, i.e. never), and never skips for
    being small either -- a smaller source is stored at its own cropped size. Enlarging
    fabricates detail; skipping leaves a live hotlink to somebody else's host for
    exactly the flimsiest sources, and a rotted hotlink still reads as coverage.
  * Skips anyone who already has a politician_images row.
  * Storage upload uses x-upsert, so a re-run overwrites the same object rather
    than orphaning one. The DB insert is guarded on not-exists, so a re-run
    inserts nothing.
  * --dry-run does everything except the upload and the DB write.

USAGE (from C:/EV-Accounts/backend)
  py scripts/mirror-photo-origin-to-storage.py --band -829999 -810001 --dry-run
  py scripts/mirror-photo-origin-to-storage.py --band -829999 -810001
"""
import argparse
import os
import re
import sys
from io import BytesIO

import psycopg2
import requests
from dotenv import load_dotenv
from PIL import Image

load_dotenv()

BUCKET = "politician_photos"
CDN = f"https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/{BUCKET}/"
UPLOAD = f"https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/{BUCKET}/"
TARGET_W, TARGET_H = 600, 750           # 4:5, the house portrait size
MIN_BYTES = 2000

MAGIC = [
    (b"\xff\xd8\xff", "JPEG"),
    (b"\x89PNG", "PNG"),
    (b"GIF8", "GIF"),
]


def image_kind(b: bytes):
    for sig, name in MAGIC:
        if b.startswith(sig):
            return name
    if len(b) >= 12 and b[0:4] == b"RIFF" and b[8:12] == b"WEBP":
        return "WEBP"
    return None


def larger_variants(url: str):
    """Known host patterns where the stored URL is a THUMBNAIL and a bigger original
    exists at a predictable path. Each rule was verified by fetching both and
    comparing decoded dimensions -- none is assumed from the URL shape alone.

      Ballotpedia S3   /files/thumbs/200/300/NAME  ->  /files/NAME
                       measured: 200x300 -> 1024x1117, 1066x1121, 536x815, 1024x1024
      WordPress uploads  NAME-200x300.jpg          ->  NAME.jpg
                       measured on epc-assets.elpasoco.com: 200x300 -> up to 3924x5887

    Returns candidates best-first. The caller adopts one ONLY if it decodes and is
    genuinely larger, so a wrong guess degrades to the original rather than to a
    broken image.
    """
    out = []
    m = re.match(r"^(https://s3\.amazonaws\.com/ballotpedia-api4/files/)thumbs/\d+/\d+/(.+)$", url)
    if m:
        out.append(m.group(1) + m.group(2))
    m = re.match(r"^(.*)-\d+x\d+(\.[A-Za-z0-9]+)$", url)
    if m:
        out.append(m.group(1) + m.group(2))
    return out


def fetch_image(url: str):
    """Return (bytes, PIL.Image, w, h) or None if the bytes are not a usable image."""
    r = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=30)
    raw = r.content
    if image_kind(raw) is None or len(raw) < MIN_BYTES:
        return None
    try:
        img = Image.open(BytesIO(raw)).convert("RGB")
    except Exception:  # noqa: BLE001
        return None
    return raw, img, img.size[0], img.size[1]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--band", nargs=2, type=int, required=True,
                    metavar=("LO", "HI"), help="external_id range to mirror")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--max-upscale", type=float, default=1.0,
                    help="refuse sources needing more enlargement than this (default 1.0 = never upscale)")
    ap.add_argument("--license", default="press_use",
                    help="photo_license for the created rows")
    args = ap.parse_args()

    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not key and not args.dry_run:
        sys.exit("SUPABASE_SERVICE_ROLE_KEY not set")
    dsn = os.environ.get("DATABASE_URL")
    if not dsn:
        sys.exit("DATABASE_URL not set")

    conn = psycopg2.connect(dsn, sslmode="require")
    cur = conn.cursor()
    cur.execute(
        """
        SELECT p.id, p.full_name, p.photo_origin_url
          FROM essentials.politicians p
         WHERE p.external_id BETWEEN %s AND %s
           AND p.photo_origin_url LIKE 'http%%'
           AND NOT EXISTS (SELECT 1 FROM essentials.politician_images i
                            WHERE i.politician_id = p.id)
         ORDER BY p.full_name
        """,
        (args.band[0], args.band[1]),
    )
    rows = cur.fetchall()
    print(f"{len(rows)} subject(s) to mirror{' (DRY RUN)' if args.dry_run else ''}\n")

    done = skipped = failed = 0
    problems = []

    for pid, name, url in rows:
        try:
            got = fetch_image(url)
            if got is None:
                failed += 1
                problems.append(f"{name}: {url} did not return a usable image")
                continue
            raw, img, w, h = got
            used_url = url

            # Prefer a larger original where the host is known to serve one. Adopt it
            # only if it actually decodes AND is bigger -- never on the URL shape alone.
            for cand in larger_variants(url):
                bigger = fetch_image(cand)
                if bigger and bigger[2] * bigger[3] > w * h:
                    raw, img, w, h = bigger
                    used_url = cand
                    break

            # Upscale gate, measured against the crop that will actually be kept.
            ratio = TARGET_W / TARGET_H
            keep_w, keep_h = (int(h * ratio), h) if w / h > ratio else (w, int(w / ratio))
            upscale = max(TARGET_W / keep_w, TARGET_H / keep_h)
            # NEVER ENLARGE, BUT NEVER LEAVE SOMEONE HOTLINKED EITHER. A source below
            # 600x750 is stored at its own cropped size rather than skipped. Skipping was
            # the original behaviour and it is wrong: it leaves a live dependency on
            # somebody else's host for exactly the people whose source is flimsiest, and
            # a rotted hotlink still counts as coverage (HAS_RENDERABLE_PHOTO_SQL accepts
            # any 'http%'), so the gap hides itself. Enlarging is the other wrong answer --
            # it fabricates detail and produces a file that reads as full resolution.
            out_w, out_h = (TARGET_W, TARGET_H) if upscale <= args.max_upscale else (keep_w, keep_h)

            # Centre crop to 4:5, then resize.
            if w / h > ratio:
                left = (w - keep_w) // 2
                img = img.crop((left, 0, left + keep_w, h))
            else:
                top = (h - keep_h) // 2
                img = img.crop((0, top, w, top + keep_h))
            img = img.resize((out_w, out_h), Image.LANCZOS)

            buf = BytesIO()
            img.save(buf, "JPEG", quality=90)
            data = buf.getvalue()
            filename = f"{pid}-headshot.jpg"
            final_url = CDN + filename

            if args.dry_run:
                src = "" if used_url == url else "  [upgraded variant]"
                native = "  [native, not enlarged]" if (out_w, out_h) != (TARGET_W, TARGET_H) else ""
                print(f"  would mirror {name:<28} {w}x{h} -> {out_w}x{out_h} {len(data)//1024}KB{src}{native}")
                done += 1
                continue

            up = requests.post(
                UPLOAD + filename,
                headers={"Authorization": f"Bearer {key}",
                         "Content-Type": "image/jpeg",
                         "x-upsert": "true"},
                data=data, timeout=60,
            )
            if up.status_code not in (200, 201):
                failed += 1
                problems.append(f"{name}: upload HTTP {up.status_code} {up.text[:120]}")
                continue

            cur.execute(
                """
                INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
                SELECT %s, %s, 'default', %s
                 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                                    WHERE politician_id = %s)
                """,
                (pid, final_url, args.license, pid),
            )
            conn.commit()
            done += 1
            print(f"  mirrored {name:<28} {w}x{h} -> {out_w}x{out_h} -> {final_url}")

        except Exception as e:  # noqa: BLE001 - report and continue, never half-write
            conn.rollback()
            failed += 1
            problems.append(f"{name}: {type(e).__name__}: {e}")

    cur.close()
    conn.close()

    print(f"\nmirrored {done} · skipped {skipped} · failed {failed}")
    if problems:
        print("\nnot mirrored:")
        for p in problems:
            print(f"  {p}")
    # A failure here is a coverage gap, not a crash: report and exit non-zero so a
    # caller notices, but never leave a partial row behind.
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
