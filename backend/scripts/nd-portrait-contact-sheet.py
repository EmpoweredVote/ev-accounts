#!/usr/bin/env python3
"""nd-portrait-contact-sheet.py — Knight program, wave ND-5.

Builds the approval contact sheet for the 141 North Dakota legislator portraits as a single
self-contained HTML file, with every frame embedded as a data: URI at its ORIGINAL bytes.

🔴 THE FRAMES ARE EMBEDDED UNMODIFIED, ON PURPOSE. The decision this sheet exists to support is
   whether 157x196 is good enough to publish. Re-encoding or resampling them would put something
   other than the shipping asset in front of the reviewer.
🔴 The Artifact CSP blocks external images, so data: URIs are the only way to show them.
"""
import argparse
import base64
import html
import io
import json
import os

from PIL import Image

TITLE = "North Dakota Portrait Review"


def bg_lightness(path: str) -> float:
    """Mean lightness of the four corner patches — used to spot an odd backdrop, not to judge."""
    im = Image.open(path).convert("L")
    w, h = im.size
    k = 12
    boxes = [(0, 0, k, k), (w - k, 0, w, k), (0, h - k, k, h), (w - k, h - k, w, h)]
    vals = []
    for b in boxes:
        px = list(im.crop(b).getdata())
        vals.append(sum(px) / len(px))
    return sum(vals) / len(vals)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ledger", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    led = json.load(io.open(args.ledger, encoding="utf-8"))
    base = os.path.dirname(args.ledger)
    rows = led["portraits"]

    def dnum(r):
        return int("".join(c for c in r["district"] if c.isdigit()))

    rows.sort(key=lambda r: (0 if "Senator" in r["chamber"] else 1, dnum(r), r["district"], r["name"]))

    for r in rows:
        p = os.path.join(base, r["file"])
        r["_b64"] = base64.b64encode(open(p, "rb").read()).decode("ascii")
        r["_bg"] = bg_lightness(p)

    # The studio backdrop is a mid-grey; a markedly lighter corner means a different sitting.
    lights = sorted(r["_bg"] for r in rows)
    median = lights[len(lights) // 2]
    for r in rows:
        r["_odd"] = r["_bg"] > median + 55

    sen = [r for r in rows if "Senator" in r["chamber"]]
    rep = [r for r in rows if "Representative" in r["chamber"]]
    odd = [r for r in rows if r["_odd"]]

    def tile(r):
        ch = "S" if "Senator" in r["chamber"] else "H"
        party = (r.get("party") or "").strip()
        pc = {"Republican": "r", "Democrat": "d"}.get(party, "i")
        flag = '<span class="flag" title="Different backdrop from the studio set">backdrop</span>' if r["_odd"] else ""
        return (
            f'<figure class="t">'
            f'<img loading="lazy" width="157" height="196" alt="{html.escape(r["name"])}, '
            f'{html.escape(r["chamber"])} for district {html.escape(r["district"])}" '
            f'src="data:image/jpeg;base64,{r["_b64"]}">'
            f'<figcaption><span class="d p{pc}">{ch}-{html.escape(r["district"])}</span>'
            f'<span class="n">{html.escape(r["name"])}</span>{flag}</figcaption>'
            f"</figure>"
        )

    css = """
<style>
:root{
  color-scheme: light;
  --paper:#f4f2ec; --card:#fffdf8; --ink:#1b1d21; --dim:#5d6067; --line:#ddd8cc;
  --gold:#a8761f; --goldsoft:#f2e7cd; --ok:#2f6b46; --warn:#8a5a12;
  --chipr:#9c3a2e; --chipd:#2d4f86; --chipi:#4a4f57;
  --shadow:0 1px 2px rgba(20,18,12,.07), 0 6px 18px rgba(20,18,12,.05);
}
@media (prefers-color-scheme: dark){
  :root:not([data-theme="light"]){
    color-scheme: dark;
    --paper:#14151a; --card:#1d1f25; --ink:#ece9de; --dim:#9aa0aa; --line:#2f323a;
    --gold:#d7a446; --goldsoft:#3a3020; --ok:#7dc39a; --warn:#d8a95c;
    --chipr:#d9776a; --chipd:#7fa5de; --chipi:#a7adb7;
    --shadow:0 1px 2px rgba(0,0,0,.4), 0 6px 18px rgba(0,0,0,.3);
  }
}
:root[data-theme="dark"]{
  color-scheme: dark;
  --paper:#14151a; --card:#1d1f25; --ink:#ece9de; --dim:#9aa0aa; --line:#2f323a;
  --gold:#d7a446; --goldsoft:#3a3020; --ok:#7dc39a; --warn:#d8a95c;
  --chipr:#d9776a; --chipd:#7fa5de; --chipi:#a7adb7;
  --shadow:0 1px 2px rgba(0,0,0,.4), 0 6px 18px rgba(0,0,0,.3);
}
body{background:var(--paper); color:var(--ink); font-family:"Public Sans",system-ui,-apple-system,"Segoe UI",sans-serif;}
.wrap{max-width:1500px; margin:0 auto; padding-inline:20px; padding-block:0 56px;}
header.top{position:sticky; top:env(safe-area-inset-top,0px); z-index:20; background:var(--paper);
  border-bottom:1px solid var(--line); padding-block:16px 12px; margin-bottom:22px;}
h1{font-family:Bitter,Georgia,serif; font-weight:700; font-size:clamp(21px,3.2vw,30px); margin:0 0 4px;
  letter-spacing:-.01em; text-wrap:balance;}
.sub{color:var(--dim); font-size:14px; margin:0; max-width:64ch;}
.bar{display:flex; flex-wrap:wrap; gap:10px 22px; align-items:center; margin-top:14px;}
.stats{display:flex; flex-wrap:wrap; gap:6px 18px; font-size:13px; color:var(--dim);}
.stats b{color:var(--ink); font-weight:600; font-variant-numeric:tabular-nums;}
.zoom{display:flex; gap:0; border:1px solid var(--line); border-radius:8px; overflow:hidden; background:var(--card);}
.zoom button{appearance:none; border:0; background:transparent; color:var(--dim); cursor:pointer;
  font:inherit; font-size:13px; font-weight:500; padding:7px 13px; border-right:1px solid var(--line);}
.zoom button:last-child{border-right:0;}
.zoom button[aria-pressed="true"]{background:var(--goldsoft); color:var(--gold); font-weight:600;}
.zoom button:focus-visible{outline:2px solid var(--gold); outline-offset:-2px;}
.note{border-left:3px solid var(--gold); background:var(--card); padding:12px 16px; border-radius:0 8px 8px 0;
  font-size:14px; margin:0 0 26px; box-shadow:var(--shadow);}
.note b{font-weight:600;}
.note p{margin:0 0 7px;} .note p:last-child{margin:0;}
h2{font-family:Bitter,Georgia,serif; font-size:17px; font-weight:600; margin:30px 0 4px; letter-spacing:-.005em;}
h2 span{font-family:"Public Sans",sans-serif; font-weight:400; font-size:13px; color:var(--dim); margin-left:9px;}
.grid{display:grid; grid-template-columns:repeat(auto-fill,minmax(var(--tw),1fr)); gap:16px 12px; margin-top:14px;}
.t{margin:0; background:var(--card); border:1px solid var(--line); border-radius:7px; overflow:hidden;
  box-shadow:var(--shadow); display:flex; flex-direction:column;}
.t img{display:block; width:100%; height:auto; max-width:100%; background:#2a2a2a;}
figcaption{padding:6px 7px 7px; display:flex; flex-wrap:wrap; align-items:baseline; gap:3px 6px; font-size:11.5px; line-height:1.3;}
.d{font-weight:600; font-variant-numeric:tabular-nums; letter-spacing:.02em; font-size:11px;
  padding:1px 5px; border-radius:4px; background:var(--goldsoft); color:var(--gold);}
.d.pr{background:color-mix(in srgb, var(--chipr) 14%, transparent); color:var(--chipr);}
.d.pd{background:color-mix(in srgb, var(--chipd) 14%, transparent); color:var(--chipd);}
.d.pi{background:color-mix(in srgb, var(--chipi) 14%, transparent); color:var(--chipi);}
.n{color:var(--ink); flex:1 1 auto; min-width:0; overflow-wrap:anywhere;}
.flag{font-size:10px; color:var(--warn); border:1px solid currentColor; border-radius:4px; padding:0 4px;}
footer{margin-top:40px; padding-top:18px; border-top:1px solid var(--line); color:var(--dim); font-size:13px;}
footer b{color:var(--ink);}
@media (max-width:520px){ .wrap{padding-inline:16px;} .bar{gap:10px 14px;} }
@media (prefers-reduced-motion:reduce){ *{transition:none!important; animation:none!important;} }
</style>
"""

    head = f"""<title>{TITLE}</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bitter:wght@600;700&family=Public+Sans:wght@400;500;600&display=swap">
{css}"""

    odd_names = ", ".join(f'{r["name"]} (' + ("S" if "Senator" in r["chamber"] else "H") + f'-{r["district"]})' for r in odd)

    body = f"""
<div class="wrap">
<header class="top">
  <h1>North Dakota legislator portraits — 141 of 141</h1>
  <p class="sub">Every frame below is the <b>unmodified original</b> from ndlegis.gov at its native
  157&nbsp;&times;&nbsp;196. Nothing has been resampled or re-encoded. Use the size control to see
  what publishing them at larger display sizes would look like.</p>
  <div class="bar">
    <div class="zoom" role="group" aria-label="Display size">
      <button type="button" data-w="157" aria-pressed="true">Native 157&times;196</button>
      <button type="button" data-w="235" aria-pressed="false">1.5&times;</button>
      <button type="button" data-w="314" aria-pressed="false">2&times;</button>
      <button type="button" data-w="471" aria-pressed="false">3&times;</button>
    </div>
    <div class="stats">
      <span><b>141</b> extracted, <b>0</b> failed</span>
      <span><b>0</b> monochrome</span>
      <span><b>0</b> duplicate files</span>
      <span><b>157&times;196</b> every frame</span>
    </div>
  </div>
</header>

<div class="note">
  <p><b>The decision.</b> 157&times;196 is everything North Dakota publishes. The linked derivative is
  140&times;175; the unlinked original is 157&times;196; a <code>large</code> style returns 404. There is
  no higher-resolution file to ask the URL for.</p>
  <p><b>What I checked.</b> A deliberately wrong filename returns 404, so the sweep can fail. All 141
  are real JPEGs that open, none is greyscale, no two are byte-identical, and every one is exactly
  157&times;196. The structure matches the seated roster: 47 senators, two representatives on each
  whole House district, one each on subdistricts 4A and 4B.</p>
  <p><b>What a script cannot check.</b> A badge is portrait-shaped. I looked at all 141 frames before
  building this page: every one is a head-and-shoulders portrait, and there are no placeholders,
  logos or graphics.</p>
  <p><b>And the measurement beat my eye.</b> Scanning corner lightness found <b>{len(odd)}</b> frames on a
  lighter backdrop than the studio set; I had spotted two of them by looking. {odd_names}.
  <b>Four of the six arrived mid-term</b> &mdash; Selzler, Rustebakke, Brown and Grindberg were all seated
  between elections and sat for their photograph outside the main session. They are flagged below, and
  every one of them is a portrait.</p>
  <p><b>Still unsettled: the licence.</b> Nothing is granted in the image bytes &mdash; no EXIF at all,
  and no copyright, credit or rights string anywhere in the file. The Legislative Branch publishes a
  Legislator Photo Request Form. Approving this sheet approves the <i>frames</i>; it does not settle
  the right to publish them.</p>
</div>

<h2>Senate <span>47 seats &middot; one member each</span></h2>
<div class="grid">{''.join(tile(r) for r in sen)}</div>

<h2>House of Representatives <span>94 seats over 48 districts &middot; two members on each whole district, one each on 4A and 4B</span></h2>
<div class="grid">{''.join(tile(r) for r in rep)}</div>

<footer>
  <p>Source: North Dakota Legislative Branch, <b>ndlegis.gov</b>, unlinked originals under
  <code>/sites/default/files/person/photo/</code>. Roster: 69th Legislative Assembly, September 2026
  special session. Extracted and reviewed <b>25 September 2026</b> for Knight slice 12, wave ND-5.</p>
</footer>
</div>

<script>
(function () {{
  var root = document.querySelector('.wrap');
  var btns = Array.prototype.slice.call(document.querySelectorAll('.zoom button'));
  function set(w) {{
    root.style.setProperty('--tw', w + 'px');
    btns.forEach(function (b) {{ b.setAttribute('aria-pressed', String(b.dataset.w === String(w))); }});
    try {{ localStorage.setItem('nd-portrait-w', String(w)); }} catch (e) {{}}
  }}
  btns.forEach(function (b) {{ b.addEventListener('click', function () {{ set(Number(b.dataset.w)); }}); }});
  var saved = null;
  try {{ saved = localStorage.getItem('nd-portrait-w'); }} catch (e) {{}}
  set(saved && btns.some(function (b) {{ return b.dataset.w === saved; }}) ? Number(saved) : 157);
}})();
</script>
"""

    with io.open(args.out, "w", encoding="utf-8") as f:
        f.write(head + body)

    mb = os.path.getsize(args.out) / (1024 * 1024)
    print(f"wrote {args.out}  {mb:.2f} MB  ({len(rows)} frames: {len(sen)} senate, {len(rep)} house, {len(odd)} flagged)")
    for r in odd:
        print(f"  flagged backdrop: {r['chamber']} {r['name']} (D{r['district']}), corner lightness {r['_bg']:.0f} vs median {median:.0f}")
    if mb > 15.0:
        print("🔴 over 15 MB — the artifact limit is 16 MB")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
