#!/usr/bin/env python3
"""Build the Hinds County portrait contact sheet. Images embedded as data: URIs (the artifact
CSP blocks external hosts, so a hotlinked <img> renders as a broken box and the operator
approves nothing but alt text)."""
import json, base64, os, sys, html
sys.stdout.reconfigure(encoding='utf-8')

rows = json.load(open('processed.json'))
gaps = json.load(open('gaps.json'))

def uri(p):
    return 'data:image/jpeg;base64,' + base64.b64encode(open(p,'rb').read()).decode()

cards = []
for r in sorted(rows, key=lambda x: x['title']):
    flags = []
    base = os.path.basename(r['img'])
    positional = not any(t and t.lower() in base.lower() for t in
                         [r['name'].split()[-1], r['name'].split()[0]])
    if positional: flags.append('verify face &mdash; filename does not carry the name')
    if r['upscale'] > 1.0: flags.append(f"enlarged &times;{r['upscale']}")
    if r['n_faces'] == 0: flags.append('NO FACE DETECTED')
    if r['n_faces'] > 1: flags.append(f"{r['n_faces']} faces detected")
    if r['spread'] < 12: flags.append('monochrome')
    risky = bool(flags)
    cards.append(f'''
    <figure class="card{' risk' if risky else ''}">
      <img src="{uri(r['processed'])}" alt="{html.escape(r['name'])}">
      <figcaption>
        <strong>{html.escape(r['name'])}</strong>
        <span class="office">{html.escape(r['title'])}</span>
        <span class="meta">source {r['src_w']}&times;{r['src_h']} &rarr; 600&times;750 &nbsp;&middot;&nbsp; &times;{r['upscale']}</span>
        <span class="meta">face {html.escape(r['face'])} &nbsp;&middot;&nbsp; colour spread {r['spread']}</span>
        <span class="meta file">{html.escape(base)}</span>
        {''.join(f'<span class="flag">{f}</span>' for f in flags)}
      </figcaption>
    </figure>''')

gap_rows = ''.join(
    f'<tr><td>{html.escape(g["title"])}</td><td>{html.escape(g["name"])}</td><td>{html.escape(g["why"])}</td></tr>'
    for g in gaps)

doc = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Hinds County Portraits</title>
<style>
  :root {{
    --bg:#f6f5f3; --panel:#fff; --ink:#1b1a18; --muted:#6b6660; --line:#e2ded8;
    --risk:#b4541a; --riskbg:#fdf3ec; --ok:#2f6b43;
  }}
  :root:not([data-theme="light"]) {{ }}
  @media (prefers-color-scheme: dark) {{ :root:not([data-theme="light"]) {{
    --bg:#15161a; --panel:#1e2026; --ink:#eceae6; --muted:#9a948c; --line:#2e3139;
    --risk:#e9975c; --riskbg:#2b2119; --ok:#7dc295;
  }} }}
  :root[data-theme="dark"] {{
    --bg:#15161a; --panel:#1e2026; --ink:#eceae6; --muted:#9a948c; --line:#2e3139;
    --risk:#e9975c; --riskbg:#2b2119; --ok:#7dc295;
  }}
  * {{ box-sizing:border-box; }}
  body {{ margin:0; background:var(--bg); color:var(--ink);
    font:15px/1.5 ui-sans-serif,system-ui,"Segoe UI",Helvetica,Arial,sans-serif; }}
  .wrap {{ max-width:1180px; margin:0 auto; padding:40px 16px 72px; }}
  h1 {{ font-size:clamp(24px,4vw,34px); margin:0 0 6px; letter-spacing:-.01em; }}
  .sub {{ color:var(--muted); margin:0 0 28px; max-width:70ch; }}
  .tally {{ display:flex; flex-wrap:wrap; gap:10px; margin:0 0 32px; }}
  .pill {{ background:var(--panel); border:1px solid var(--line); border-radius:999px;
    padding:7px 15px; font-size:13px; }}
  .pill b {{ font-size:15px; }}
  .grid {{ display:grid; gap:20px; grid-template-columns:repeat(auto-fill,minmax(200px,1fr)); }}
  .card {{ margin:0; background:var(--panel); border:1px solid var(--line); border-radius:12px;
    overflow:hidden; }}
  .card.risk {{ border-color:var(--risk); background:var(--riskbg); }}
  .card img {{ display:block; width:100%; aspect-ratio:4/5; object-fit:cover; }}
  figcaption {{ padding:12px 13px 14px; display:flex; flex-direction:column; gap:3px; }}
  figcaption strong {{ font-size:15px; }}
  .office {{ font-size:13px; color:var(--ink); opacity:.85; }}
  .meta {{ font-size:11.5px; color:var(--muted); }}
  .file {{ font-family:ui-monospace,SFMono-Regular,Menlo,monospace; font-size:10.5px;
    overflow-wrap:anywhere; }}
  .flag {{ margin-top:5px; font-size:11.5px; color:var(--risk); font-weight:600; }}
  h2 {{ font-size:19px; margin:48px 0 8px; }}
  table {{ width:100%; border-collapse:collapse; background:var(--panel);
    border:1px solid var(--line); border-radius:10px; overflow:hidden; font-size:13.5px; }}
  th,td {{ text-align:left; padding:9px 13px; border-bottom:1px solid var(--line);
    vertical-align:top; }}
  th {{ font-size:11.5px; text-transform:uppercase; letter-spacing:.06em; color:var(--muted); }}
  tr:last-child td {{ border-bottom:0; }}
  td:nth-child(3) {{ color:var(--muted); }}
  .note {{ background:var(--panel); border:1px solid var(--line); border-left:3px solid var(--risk);
    border-radius:8px; padding:14px 16px; margin:22px 0 0; font-size:13.5px; color:var(--muted); }}
  @media (max-width:520px) {{ .grid {{ grid-template-columns:repeat(auto-fill,minmax(150px,1fr)); }} }}
</style></head>
<body><div class="wrap">
<h1>Hinds County, Mississippi &mdash; portraits for approval</h1>
<p class="sub">Every crop below is the <strong>production render</strong>: the same 4:5 crop and
600&times;750 resize that would ship. Each is bound <strong>by seat</strong> &mdash; the image is
whatever the county's own page for that office shows, with the officeholder's name printed beside
it &mdash; never by filename.</p>
<div class="tally">
  <span class="pill"><b>{len(rows)}</b> sourced</span>
  <span class="pill"><b>{sum(1 for c in cards if 'risk' in c[:40])}</b> flagged</span>
  <span class="pill"><b>{len(gaps)}</b> no portrait found</span>
  <span class="pill"><b>28</b> officeholders in Hinds</span>
</div>
<div class="grid">{''.join(cards)}</div>

<h2>No portrait found &mdash; {len(gaps)} of 28</h2>
<table><thead><tr><th>Office</th><th>Officeholder</th><th>Why</th></tr></thead>
<tbody>{gap_rows}</tbody></table>

<div class="note"><strong>Where these came from.</strong> The county's live site
(<code>co.hinds.ms.us</code>) is a records portal with no bios or photos.
<code>hindscountyms.com</code> now returns a vendor &ldquo;Website Coming Soon&rdquo; placeholder
&mdash; the county is mid-rebuild &mdash; so every portrait here is read from the Internet
Archive's capture of the county's own page, all captured 2026 and so after the current officers
took office in January 2024. Licence is <code>press_use</code> throughout: county-published
official portraits.</div>
</div></body></html>'''

open('sheet.html','w',encoding='utf-8').write(doc)
print(f'wrote sheet.html  ({len(doc)/1024/1024:.2f} MB)  {len(rows)} cards, {len(gaps)} gaps')
