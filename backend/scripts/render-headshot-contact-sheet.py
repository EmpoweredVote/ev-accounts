"""
Render a headshot CONTACT SHEET for batch approval, and nothing else.

The find-headshots skill requires batch approval via a single contact-sheet artifact,
never one dialog per person. Wrong-person and off-by-one errors are the dominant
failure mode in this work, and they are obvious when thirty faces sit side by side
with names under them, nearly invisible one at a time.

Every frame is the ACTUAL production render -- 4:5, 600x750, the same crop the importer
applies -- so the operator approves what will ship, not the source image. Images are
embedded as data: URIs because the artifact CSP blocks external hosts; a hotlinked
<img src> renders as a broken box and the operator approves nothing but alt text.

INPUT: a JSON array (default .tmp-all-candidates.json), one object per subject:
    politician_id  uuid of the essentials.politicians row
    name           full name, shown under the frame
    office         office title, shown under the frame
    cohort         grouping label for the section heading
    url            candidate image URL (null => listed under "no candidate found")
    page           source page, for the provenance line
    license        photo_license to record
    positional     true when the filename encodes a SEAT not a PERSON
                   (D1.jpg, 1.png, a bare UUID) -- these get a "verify face" flag,
                   because that is exactly where off-by-one errors hide

OUTPUT: ../.tmp-cos-contactsheet.html, self-contained, ready to publish as an Artifact.

USAGE (from C:/EV-Accounts/backend):
  py scripts/render-headshot-contact-sheet.py
"""
import argparse
import base64
import hashlib
import os
import sys
import html
import json
from io import BytesIO

import requests
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from headshot_crop import crop_4x5  # noqa: E402

TARGET_W, TARGET_H = 600, 750
CACHE = ".tmp-headshot-cache"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}

ap = argparse.ArgumentParser()
ap.add_argument("--title", default="Headshot proof sheet",
                help="page title and h1; name the wave so a later reader knows what they approved")
ap.add_argument("--json", default=".tmp-all-candidates.json")
ap.add_argument("--out", default="../.tmp-cos-contactsheet.html")
ap.add_argument("--max-upscale", type=float, default=1.0,
                help="mirror of the importer flag. A source too small to reach 600x750 is "
                     "embedded at the size that will actually SHIP, not enlarged to fill the "
                     "card, so the operator approves the real pixels")
ARGS = ap.parse_args()
TITLE = ARGS.title

cands = json.load(open(ARGS.json, encoding="utf-8"))

rendered, missing = [], []
for c in cands:
    if not c.get("url"):
        missing.append(c)
        continue
    try:
        # ⚠ CACHE THE BYTES ON DISK. Tuning crops means re-rendering repeatedly, and
        # re-fetching 71 third-party URLs each time gets you rate-limited: the Wayback
        # Machine and discover.pbc.gov both started refusing partway through, so the sheet
        # lost a different handful of faces on every pass and no run was ever complete.
        # Cache-first also means the operator is comparing identical bytes between passes.
        # Delete .tmp-headshot-cache/ to force a refetch.
        os.makedirs(CACHE, exist_ok=True)
        ck = os.path.join(CACHE, hashlib.sha1(c["url"].encode()).hexdigest() + ".bin")
        if os.path.exists(ck) and os.path.getsize(ck) > 0:
            raw = open(ck, "rb").read()
        else:
            raw = requests.get(c["url"], headers=UA, timeout=40).content
            try:                                   # cache anything that actually decodes,
                Image.open(BytesIO(raw)).verify()  # which includes WEBP -- a JPEG/PNG
                open(ck, "wb").write(raw)          # allowlist silently skipped nine rows
            except Exception:                      # noqa: BLE001
                pass                               # HTML error pages never reach the cache
        # ONE crop implementation, shared with the importer (scripts/headshot_crop.py).
        # A per-row "crop" override handles subjects the centre crop gets wrong.
        src = Image.open(BytesIO(raw))
        w, h = src.size                    # SOURCE size, reported on the card
        img, (keep_w, keep_h) = crop_4x5(src, **c.get("crop", {}))
        upscale = max(TARGET_W / keep_w, TARGET_H / keep_h)
        # SHOW WHAT SHIPS. crop_4x5 always returns 600x750, but the importer stores the
        # NATIVE cropped size whenever reaching 600x750 would mean enlarging. Embedding the
        # enlarged version here would show the operator detail the stored file will not have
        # -- the same proof-sheet-vs-import drift headshot_crop.py exists to prevent. The
        # card still lays out at 600x750; the browser scales it, exactly as the site does.
        if upscale > ARGS.max_upscale:
            img = img.resize((keep_w, keep_h), Image.LANCZOS)
        buf = BytesIO()
        img.save(buf, "JPEG", quality=84, optimize=True)
        c["data"] = base64.b64encode(buf.getvalue()).decode()
        c["upscale"] = round(upscale, 2)
        c["src_w"], c["src_h"] = w, h
        rendered.append(c)
        print(f"  rendered {c['name']:<26} {w}x{h} ({upscale:.2f}x)")
    except Exception as e:  # noqa: BLE001
        c["error"] = f"{type(e).__name__}: {e}"
        missing.append(c)
        print(f"  FAILED   {c['name']:<26} {e}")

json.dump({"rendered": [{k: v for k, v in c.items() if k != "data"} for c in rendered],
           "missing": missing}, open(".tmp-contactsheet-manifest.json", "w"), indent=2)

# 🔴 COHORTS ARE DERIVED FROM THE DATA, NEVER HARDCODED. This list used to be
# ["Colorado Springs", "El Paso County", "CO legislature"], so the Florida wave rendered
# 68 faces and then filtered every one of them out at the section loop: the page came out
# 7 KB with zero <img> and a Colorado title, and printed "rendered 68" while showing none.
# A grouping key that must be edited per wave is a trap for the wave that forgets.
# First-appearance order is kept, so the caller controls section order by ordering the JSON.
COHORTS = list(dict.fromkeys(c["cohort"] for c in cands))
flagged = [c for c in rendered if c["positional"] or c["upscale"] > 1.0]

def card(c, n):
    marks = []
    if c["positional"]:
        marks.append('<span class="mark mark-face">verify face</span>')
    if c["upscale"] > 1.0:
        marks.append(f'<span class="mark mark-up">{c["upscale"]:.2f}&times; upscale</span>')
    cls = " flagged" if marks else ""
    host = c["page"].split("/")[2] if c.get("page") else "—"
    return f'''<figure class="frame{cls}">
  <button class="shot" type="button" aria-label="Enlarge {html.escape(c['name'])}"
          data-full="data:image/jpeg;base64,{c['data']}" data-name="{html.escape(c['name'])}">
    <img src="data:image/jpeg;base64,{c['data']}" alt="Headshot candidate for {html.escape(c['name'])}" loading="lazy" width="600" height="750" />
    <span class="fno">{n:02d}</span>
  </button>
  <figcaption>
    <span class="who">{html.escape(c['name'])}</span>
    <span class="role">{html.escape(c['office'])}</span>
    <span class="meta"><span class="dim">{c['src_w']}&times;{c['src_h']}</span> · {html.escape(host)} · {html.escape(c['license'])}</span>
    <span class="marks">{''.join(marks)}</span>
  </figcaption>
</figure>'''

sections = ""
n = 0
for co in COHORTS:
    group = [c for c in rendered if c["cohort"] == co]
    if not group:
        continue
    cards = ""
    for c in group:
        n += 1
        cards += card(c, n)
    sections += f'''<section class="cohort">
  <h2>{html.escape(co)} <span class="count">{len(group)}</span></h2>
  <div class="grid">{cards}</div>
</section>'''

miss_rows = "".join(
    f'<li><span class="who">{html.escape(m["name"])}</span><span class="role">{html.escape(m["office"])}</span>'
    f'<span class="why">{html.escape(m.get("error", "no candidate image found at any source"))}</span></li>'
    for m in missing)
miss_block = f'''<section class="cohort missing">
  <h2>No candidate found <span class="count">{len(missing)}</span></h2>
  <p class="note">Listed so coverage reads honestly. These stay blank rather than taking a
  wrong or unusable image — a blank keeps them in the headshot backlog, where they belong.</p>
  <ul class="misslist">{miss_rows}</ul>
</section>''' if missing else ""

doc = f'''<title>{html.escape(TITLE)}</title>
<style>
:root {{
  --ground:#EDEFF2; --panel:#F7F8FA; --ink:#171A1F; --ink-2:#4A525E; --ink-3:#79828F;
  --rule:#D3D8DE; --amber:#B4690E; --rust:#9C3B2E; --sage:#3F6B54; --frame:#20242B;
}}
:root:not([data-theme="light"]) {{ }}
@media (prefers-color-scheme: dark) {{
  :root:not([data-theme="light"]) {{
    --ground:#12151A; --panel:#191D24; --ink:#E7EAEF; --ink-2:#AAB3C0; --ink-3:#78828F;
    --rule:#2A303A; --amber:#E0A44E; --rust:#D98274; --sage:#7FB395; --frame:#0C0E12;
  }}
}}
:root[data-theme="dark"] {{
  --ground:#12151A; --panel:#191D24; --ink:#E7EAEF; --ink-2:#AAB3C0; --ink-3:#78828F;
  --rule:#2A303A; --amber:#E0A44E; --rust:#D98274; --sage:#7FB395; --frame:#0C0E12;
}}
* {{ box-sizing:border-box; }}
body {{
  margin:0; background:var(--ground); color:var(--ink);
  font:15px/1.5 ui-sans-serif,-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  -webkit-font-smoothing:antialiased;
}}
.wrap {{ max-width:1220px; margin:0 auto; padding:40px 24px 96px; }}
header h1 {{ font-size:clamp(26px,3.4vw,38px); letter-spacing:-.02em; margin:0 0 6px; text-wrap:balance; }}
header p {{ margin:0; color:var(--ink-2); max-width:64ch; }}
.tally {{
  display:flex; flex-wrap:wrap; gap:0; margin:28px 0 8px;
  border:1px solid var(--rule); border-radius:3px; background:var(--panel); overflow:hidden;
}}
.tally div {{ flex:1 1 130px; padding:14px 16px; border-right:1px solid var(--rule); }}
.tally div:last-child {{ border-right:0; }}
.tally b {{
  display:block; font:600 24px/1.1 ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;
  font-variant-numeric:tabular-nums; letter-spacing:-.01em;
}}
.tally span {{ font-size:11px; text-transform:uppercase; letter-spacing:.09em; color:var(--ink-3); }}
.tally .t-face b {{ color:var(--amber); }} .tally .t-up b {{ color:var(--rust); }}
.tally .t-ok b {{ color:var(--sage); }}
.cohort {{ margin-top:46px; }}
.cohort h2 {{
  font-size:12px; text-transform:uppercase; letter-spacing:.12em; color:var(--ink-2);
  margin:0 0 14px; padding-bottom:8px; border-bottom:1px solid var(--rule);
  display:flex; justify-content:space-between; align-items:baseline;
}}
.count {{ font:600 12px/1 ui-monospace,Menlo,Consolas,monospace; color:var(--ink-3); font-variant-numeric:tabular-nums; }}
.grid {{ display:grid; grid-template-columns:repeat(auto-fill,minmax(168px,1fr)); gap:22px 18px; }}
.frame {{ margin:0; display:flex; flex-direction:column; gap:8px; }}
.shot {{
  position:relative; display:block; padding:6px; border:0; cursor:zoom-in; width:100%;
  background:var(--frame); border-radius:2px; line-height:0;
}}
.shot img {{ width:100%; height:auto; display:block; border-radius:1px; }}
.shot:focus-visible {{ outline:2px solid var(--amber); outline-offset:3px; }}
.fno {{
  position:absolute; left:6px; top:6px; padding:2px 5px; background:rgba(0,0,0,.62);
  color:#F2F3F5; font:600 10px/1 ui-monospace,Menlo,Consolas,monospace; letter-spacing:.06em;
}}
.frame.flagged .shot {{ box-shadow:0 0 0 2px var(--amber); }}
figcaption {{ display:flex; flex-direction:column; gap:2px; }}
.who {{ font-weight:600; font-size:13.5px; line-height:1.25; }}
.role {{ font-size:12px; color:var(--ink-2); line-height:1.3; }}
.meta {{ font:11px/1.4 ui-monospace,Menlo,Consolas,monospace; color:var(--ink-3); word-break:break-word; }}
.dim {{ font-variant-numeric:tabular-nums; }}
.marks {{ display:flex; flex-wrap:wrap; gap:4px; margin-top:2px; }}
.mark {{
  font:600 9.5px/1 ui-monospace,Menlo,Consolas,monospace; text-transform:uppercase;
  letter-spacing:.06em; padding:3px 5px; border:1px solid currentColor; border-radius:2px;
}}
.mark-face {{ color:var(--amber); }} .mark-up {{ color:var(--rust); }}
.note {{ color:var(--ink-2); max-width:70ch; margin:0 0 14px; font-size:13.5px; }}
.misslist {{ list-style:none; margin:0; padding:0; display:flex; flex-direction:column; gap:1px; }}
.misslist li {{
  display:grid; grid-template-columns:minmax(140px,1fr) minmax(160px,1.4fr) minmax(180px,2fr);
  gap:14px; padding:11px 14px; background:var(--panel); border:1px solid var(--rule); border-radius:2px;
}}
.misslist .why {{ font:11.5px/1.4 ui-monospace,Menlo,Consolas,monospace; color:var(--rust); }}
dialog {{ border:0; padding:0; background:transparent; max-width:96vw; max-height:96vh; }}
dialog::backdrop {{ background:rgba(8,10,14,.86); }}
dialog img {{ max-width:min(600px,92vw); max-height:88vh; width:auto; display:block; border-radius:2px; }}
dialog .cap {{
  color:#E7EAEF; font:600 13px/1.6 ui-sans-serif,system-ui,sans-serif; text-align:center; padding-top:10px;
}}
@media (prefers-reduced-motion:reduce) {{ * {{ animation:none !important; transition:none !important; }} }}
</style>

<div class="wrap">
  <header>
    <h1>{html.escape(TITLE)}</h1>
    <p>Every frame is the actual production render &mdash; 4:5, 600&times;750 &mdash; not the source
    image. Approve what ships. Click any frame to enlarge for a face check.</p>
  </header>

  <div class="tally">
    <div class="t-ok"><b>{len(rendered)}</b><span>sourced</span></div>
    <div class="t-face"><b>{sum(1 for c in rendered if c['positional'])}</b><span>verify face</span></div>
    <div class="t-up"><b>{sum(1 for c in rendered if c['upscale'] > 1.0)}</b><span>upscaled</span></div>
    <div><b>{len(missing)}</b><span>not found</span></div>
    <div><b>{len(cands)}</b><span>subjects</span></div>
  </div>
  <p class="note"><strong>Amber frames need a face check.</strong> Their filename is positional
  &mdash; <code>1.png</code>, <code>D1.jpg</code>, a bare UUID &mdash; so it encodes a seat, not a
  person. Name-to-face pairing for the nine councilmembers was read from the live page structure,
  not guessed from filenames, but positional sources are where off-by-one errors hide.</p>

  {sections}
  {miss_block}
</div>

<dialog id="lb"><img id="lb-img" alt="" /><div class="cap" id="lb-cap"></div></dialog>
<script>
  const lb = document.getElementById('lb'), lbImg = document.getElementById('lb-img'), lbCap = document.getElementById('lb-cap');
  document.querySelectorAll('.shot').forEach((b) => b.addEventListener('click', () => {{
    lbImg.src = b.dataset.full; lbImg.alt = b.dataset.name; lbCap.textContent = b.dataset.name; lb.showModal();
  }}));
  lb.addEventListener('click', () => lb.close());
</script>'''

open(ARGS.out, "w", encoding="utf-8").write(doc)
print(f"\nwrote ../.tmp-cos-contactsheet.html  ({len(doc)//1024} KB)")
print(f"rendered {len(rendered)} · missing {len(missing)} · flagged {len(flagged)}")
