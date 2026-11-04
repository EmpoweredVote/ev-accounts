#!/usr/bin/env python3
"""Build the Hinds County portrait contact sheet.

Images are embedded as data: URIs -- the artifact CSP blocks external hosts, so a hotlinked
<img> renders as a broken box and the operator approves nothing but alt text.

THE REJECTS ARE ON THE SHEET, WITH THE DEFECT VISIBLE. A rejection the operator cannot see is a
rejection they have to take on trust; the banner work established that putting the colliding
candidate on the sheet makes the call checkable instead of arguable. The five watermarked
supervisor crops therefore still show the signature rather than cropping it away.
"""
import argparse, base64, html, json, os, sys

sys.stdout.reconfigure(encoding='utf-8')
ap = argparse.ArgumentParser()
ap.add_argument('--dir', default='.')
os.chdir(ap.parse_args().dir)

proc = {r['key']: r for r in json.load(open('processed.json'))}
ship = json.load(open('hc-ship.json'))
rejected = json.load(open('hc-rejected.json'))
gaps = json.load(open('hc-gaps.json'))


def uri(path):
    return 'data:image/jpeg;base64,' + base64.b64encode(open(path, 'rb').read()).decode()


def card(key, name, title, cls='', note=''):
    r = proc.get(key)
    if r:
        img = '<img src="%s" alt="%s">' % (uri(r['processed']), html.escape(name))
        meta = (
            '<span class="meta">source %d&times;%d &rarr; 600&times;750 &middot; &times;%s</span>'
            '<span class="meta">face %s &middot; spread %s</span>'
            '<span class="meta file">%s</span>'
            % (r['orig_w'], r['orig_h'], r['upscale'], html.escape(r['face']), r['spread'],
               html.escape(os.path.basename(r['img'])))
        )
    else:
        img = '<div class="noimg">no portrait<br>published</div>'
        meta = ''
    note_html = '<span class="note">%s</span>' % note if note else ''
    return (
        '<figure class="card %s">%s<figcaption>'
        '<strong>%s</strong><span class="office">%s</span>%s%s'
        '</figcaption></figure>'
        % (cls, img, html.escape(name), html.escape(title), meta, note_html)
    )


ship_cards = ''.join(card(p['key'], p['name'], p['title']) for p in ship)
rej_cards = ''.join(card(r['key'], r['name'], r['title'], 'rej', html.escape(r['why']))
                    for r in rejected)
gap_rows = ''.join(
    '<tr><td>%s</td><td>%s</td><td>%s</td></tr>'
    % (html.escape(g['title']), html.escape(g['name']), html.escape(g['why'])) for g in gaps)

CSS = """
:root{--bg:#f7f6f4;--panel:#fff;--ink:#1b1a18;--muted:#6b6660;--line:#e3dfd9;
 --ok:#2f6b43;--okbg:#f0f6f1;--rej:#b4541a;--rejbg:#fdf3ec}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#15161a;--panel:#1e2026;
 --ink:#eceae6;--muted:#9a948c;--line:#2e3139;--ok:#7dc295;--okbg:#1b241e;--rej:#e9975c;--rejbg:#2b2119}}
:root[data-theme="dark"]{--bg:#15161a;--panel:#1e2026;--ink:#eceae6;--muted:#9a948c;
 --line:#2e3139;--ok:#7dc295;--okbg:#1b241e;--rej:#e9975c;--rejbg:#2b2119}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);
 font:15px/1.55 ui-sans-serif,system-ui,"Segoe UI",Helvetica,Arial,sans-serif}
.wrap{max-width:1180px;margin:0 auto;padding:40px 16px 80px}
h1{font-size:clamp(23px,4vw,33px);margin:0 0 6px;letter-spacing:-.01em}
.sub{color:var(--muted);margin:0 0 26px;max-width:72ch}
.tally{display:flex;flex-wrap:wrap;gap:9px;margin:0 0 34px}
.pill{background:var(--panel);border:1px solid var(--line);border-radius:999px;
 padding:7px 15px;font-size:13px}
.pill b{font-size:15px}
.pill.ok{border-color:var(--ok);background:var(--okbg)}
.pill.rej{border-color:var(--rej);background:var(--rejbg)}
h2{font-size:19px;margin:44px 0 4px}
h2 .n{color:var(--muted);font-weight:400}
.lede{color:var(--muted);margin:0 0 16px;max-width:72ch;font-size:14px}
.grid{display:grid;gap:20px;grid-template-columns:repeat(auto-fill,minmax(205px,1fr))}
.card{margin:0;background:var(--panel);border:1px solid var(--line);border-radius:12px;overflow:hidden}
.card.rej{border-color:var(--rej);background:var(--rejbg)}
.card img{display:block;width:100%;aspect-ratio:4/5;object-fit:cover}
.card.rej img{filter:grayscale(.55) opacity(.72)}
.noimg{aspect-ratio:4/5;display:flex;align-items:center;justify-content:center;
 text-align:center;color:var(--muted);font-size:13px;background:var(--bg)}
figcaption{padding:12px 13px 14px;display:flex;flex-direction:column;gap:3px}
figcaption strong{font-size:15px}
.office{font-size:13px;opacity:.85}
.meta{font-size:11.5px;color:var(--muted)}
.file{font-family:ui-monospace,Menlo,monospace;font-size:10.5px;overflow-wrap:anywhere}
.note{margin-top:6px;font-size:12px;color:var(--rej);font-weight:600;line-height:1.45}
table{width:100%;border-collapse:collapse;background:var(--panel);border:1px solid var(--line);
 border-radius:10px;overflow:hidden;font-size:13.5px}
th,td{text-align:left;padding:9px 13px;border-bottom:1px solid var(--line);vertical-align:top}
th{font-size:11.5px;text-transform:uppercase;letter-spacing:.06em;color:var(--muted)}
tr:last-child td{border-bottom:0}
td:nth-child(3){color:var(--muted)}
.box{background:var(--panel);border:1px solid var(--line);border-left:3px solid var(--muted);
 border-radius:8px;padding:14px 16px;margin:26px 0 0;font-size:13.5px;color:var(--muted)}
@media(max-width:520px){.grid{grid-template-columns:repeat(auto-fill,minmax(150px,1fr))}}
"""

BODY = """<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Hinds County Portraits</title><style>%s</style></head><body><div class="wrap">
<h1>Hinds County, Mississippi &mdash; portraits</h1>
<p class="sub">Each crop is the <strong>production render</strong>: the same 4:5 crop and
600&times;750 resize that would ship. Every one is bound <strong>by seat</strong> &mdash; the
image is whatever the county's own page for that office shows, with the officeholder's name
printed beside it &mdash; never by filename.</p>
<div class="tally">
 <span class="pill ok"><b>%d</b> to import</span>
 <span class="pill rej"><b>%d</b> rejected</span>
 <span class="pill"><b>%d</b> none published</span>
 <span class="pill"><b>28</b> officeholders</span>
</div>

<h2>Import these <span class="n">&mdash; %d</span></h2>
<p class="lede">No watermark, a real photograph, one subject, a face detected in each.</p>
<div class="grid">%s</div>

<h2>Rejected <span class="n">&mdash; %d</span></h2>
<p class="lede">Shown so the call is checkable rather than taken on trust. The five supervisor
portraits are one studio sitting signed <strong>&ldquo;Jay D. Johnson&rdquo;</strong>; per your
ruling they are blanked, and the signature is left in place rather than cropped away &mdash;
removing an author's attribution in order to reuse the work would be worse than declining it.</p>
<div class="grid">%s</div>

<h2>The county publishes no portrait <span class="n">&mdash; %d</span></h2>
<p class="lede">Not a sourcing failure. This is what the county publishes, read office by office.</p>
<table><thead><tr><th>Office</th><th>Officeholder</th><th>Why</th></tr></thead>
<tbody>%s</tbody></table>

<div class="box"><strong>Provenance.</strong> The county's live site (<code>co.hinds.ms.us</code>)
is a records portal with no bios or photographs. <code>hindscountyms.com</code> now returns a
vendor &ldquo;Website Coming Soon&rdquo; placeholder and 404s its image files &mdash; the county
is mid-rebuild &mdash; so every image here is read from the Internet Archive's capture of the
county's own page, all captured in 2026 and so after the current officers took office in January
2024. Licence <code>press_use</code>: county-published official portraits.</div>
</div></body></html>"""

doc = BODY % (CSS, len(ship), len(rejected), len(gaps), len(ship), ship_cards,
              len(rejected), rej_cards, len(gaps), gap_rows)

open('sheet.html', 'w', encoding='utf-8').write(doc)
print('wrote sheet.html  %.2f MB  %d ship / %d rejected / %d none'
      % (len(doc) / 1024 / 1024, len(ship), len(rejected), len(gaps)))
