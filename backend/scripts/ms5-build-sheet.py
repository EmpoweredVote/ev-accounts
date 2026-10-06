#!/usr/bin/env python3
"""Build the MS-5 headshot approval sheet: every frame that would be published, at the size it
would be published, with its own per-image label. Nothing is uploaded before this is approved."""
import base64, json, os, html

BIL = json.load(open('data/seed-ms-2026/_assets/biloxi-processed.json'))
HAR = json.load(open('data/seed-ms-2026/_assets/harrison-processed.json'))

BIL_SRC = 'biloxi.ms.us/wp-content/uploads/2025/08/'
HAR_SRC = {
    'd1': 'harrisoncountyms.gov', 'd2': 'harrisoncountyms.gov', 'd3': 'harrisoncountyms.gov',
    'd4': 'harrisoncountyms.gov', 'd5': 'harrisoncountyms.gov', 'circuit': 'harrisoncountyms.gov',
    'assessor': 'harrisoncountyms.gov', 'collector': 'harrisoncountyms.gov',
    'sheriff': 'harrisoncountysheriff.com', 'chancery': 'harrisoncountymschanceryclerk.gov',
}
NOTES = {
    'ward3': 'The city calls him <b>Mike Nail</b>; production holds <b>Robert Nail</b>. Bound by ward, not by name.',
    'ward6': 'The city file is named <b>Glavin</b> and its thumbnail is labelled <b>Ward 5</b>. Both wrong. Bound by the page caption.',
    'mayor': 'The mayor page shows a 2024 lectern photo. This is the official studio portrait from the city media library, an older sitting.',
    'sheriff': 'HCSO publishes him only as a cut-out inside a gold ring. This is the plain original from the same server, 3742&times;5423, which their own pages never link &mdash; found by following the naming their command staff use.',
    'd2': 'Published inside a decorative white frame with a drop shadow. Frame trimmed, then zoomed to the subject.',
    'd3': 'Published inside a decorative white frame with a drop shadow. Frame trimmed, then zoomed to the subject.',
    'd4': 'Published inside a decorative white frame with a drop shadow. Frame trimmed, then zoomed to the subject.',
}


def card(pid, name, title, src_host, src_w, src_h, upscale, note, folder):
    p = 'data/seed-ms-2026/_assets/%s/%s-headshot.jpg' % (folder, pid)
    b64 = base64.b64encode(open(p, 'rb').read()).decode()
    warn = ('<span class="pill warn">upscaled %s&times;</span>' % upscale) if upscale \
        else '<span class="pill ok">no upscale</span>'
    n = ('<p class="note">%s</p>' % note) if note else ''
    return (
        '<figure class="card">\n'
        '  <img src="data:image/jpeg;base64,%s" alt="Published headshot for %s, %s" width="600" height="750">\n'
        '  <figcaption>\n'
        '    <h3>%s</h3>\n'
        '    <p class="role">%s</p>\n'
        '    <dl><dt>source</dt><dd>%s</dd>\n'
        '        <dt>original</dt><dd>%d&times;%d</dd>\n'
        '        <dt>published</dt><dd>600&times;750</dd></dl>\n'
        '    %s%s\n'
        '  </figcaption>\n'
        '</figure>'
    ) % (b64, html.escape(name), html.escape(title), html.escape(name),
         html.escape(title), html.escape(src_host), src_w, src_h, warn, n)


bil_cards = '\n'.join(
    card(r['politician_id'], r['name'], r['title'], BIL_SRC, r['src_w'], r['src_h'],
         None, NOTES.get(r['slug']), 'biloxi-processed') for r in BIL)
har_cards = '\n'.join(
    card(r['politician_id'], r['name'], r['title'], HAR_SRC[r['slug']], r['src_w'], r['src_h'],
         r['upscale'], NOTES.get(r['slug']), 'harrison-processed') for r in HAR)

MISSING = [
    ('Coroner', 'Brian Switzer', 'County page names him and publishes no photograph'),
    ('County Prosecuting Attorney', 'Herman Cox', 'No county page for the office'),
    ('Justice Court Judge, District 1', 'Albert Fountain', 'Justice court page publishes no photographs'),
    ('Justice Court Judge, District 2', 'Brandon Ladner', 'Justice court page publishes no photographs'),
    ('Justice Court Judge, District 3', 'Dianne Ladner', 'Justice court page publishes no photographs'),
    ('Justice Court Judge, District 4', 'Theressia Lyons', 'Justice court page publishes no photographs'),
    ('Justice Court Judge, District 5', 'Nick Patano', 'Justice court page publishes no photographs'),
    ('Constable, District 1', 'James Morgan', 'County publishes no constable page'),
    ('Constable, District 2', 'Angel Kibler-Middleton', 'County publishes no constable page'),
    ('Constable, District 3', 'Alan Weatherford', 'County publishes no constable page'),
    ('Constable, District 4', 'Sammie Taylor', 'County publishes no constable page'),
    ('Constable, District 5', 'Jeff Migues', 'County publishes no constable page'),
    ('Election Commissioner, District 1', 'Toni Diaz', 'Commission page names all five and publishes no photographs'),
    ('Election Commissioner, District 2', 'Becky Payne', 'Commission page names all five and publishes no photographs'),
    ('Election Commissioner, District 3', 'Jennifer Smith', 'Commission page names all five and publishes no photographs'),
    ('Election Commissioner, District 4', 'Christene Brice', 'Commission page names all five and publishes no photographs'),
    ('Election Commissioner, District 5', 'Carolyn Handler', 'Commission page names all five and publishes no photographs'),
]
miss_rows = '\n'.join(
    '<tr><td>%s</td><td>%s</td><td>%s</td></tr>' % (html.escape(n), html.escape(t), html.escape(w))
    for t, n, w in MISSING)

TOKENS = """
  --ink:#e9ece9; --ink-soft:#a9bab8; --ink-faint:#7d8f8d;
  --paper:#111716; --card:#19201f; --rule:#2c3634;
  --accent:#6fd0d4; --warn-bg:#3a2c10; --warn-ink:#f0c478;
  --ok-bg:#1c3025; --ok-ink:#9bd4ad;
  color-scheme: dark;
"""

doc = """<title>Biloxi and Harrison County Portraits</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Newsreader:opsz,wght@6..72,400;6..72,600&family=IBM+Plex+Sans:wght@400;500;600&display=swap">
<style>
:root {
  --ink:#10201f; --ink-soft:#4a5f5e; --ink-faint:#718584;
  --paper:#f5f3ee; --card:#fffefb; --rule:#dcd9d0;
  --accent:#0d5f63; --warn-bg:#fbeed6; --warn-ink:#6f4308;
  --ok-bg:#e2eee6; --ok-ink:#265334;
  color-scheme: light;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {__TOKENS__}
}
:root[data-theme="dark"] {__TOKENS__}

body { background:var(--paper); color:var(--ink);
       font-family:"IBM Plex Sans",system-ui,-apple-system,sans-serif; }
.wrap { max-width:1080px; margin:0 auto; padding-inline:16px; padding-block:40px 64px; }
h1 { font-family:Newsreader,Georgia,serif; font-weight:600;
     font-size:clamp(1.9rem,1.2rem + 2.4vw,2.9rem); line-height:1.1; margin:0 0 .5rem;
     text-wrap:balance; letter-spacing:-.01em; }
.stand { font-size:1.02rem; color:var(--ink-soft); max-width:64ch; margin:0 0 1.8rem; line-height:1.55; }
.tally { display:flex; flex-wrap:wrap; gap:10px; margin:0 0 2.2rem; padding:0; list-style:none; }
.tally li { background:var(--card); border:1px solid var(--rule); border-radius:3px;
            padding:10px 14px; font-size:.82rem; color:var(--ink-soft);
            font-variant-numeric:tabular-nums; }
.tally b { font-size:1.35rem; display:block; font-family:Newsreader,Georgia,serif;
           color:var(--ink); font-weight:600; }
h2 { font-family:Newsreader,Georgia,serif; font-weight:600; font-size:1.5rem;
     margin:2.8rem 0 .3rem; padding-bottom:.4rem; border-bottom:2px solid var(--accent);
     display:flex; justify-content:space-between; align-items:baseline; gap:12px; }
h2 .count { font-family:"IBM Plex Sans",sans-serif; font-size:.78rem; font-weight:500;
            color:var(--ink-faint); font-variant-numeric:tabular-nums; white-space:nowrap; }
.sub { color:var(--ink-soft); font-size:.92rem; margin:.7rem 0 1.5rem; max-width:70ch; line-height:1.55; }
.grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(196px,1fr)); gap:20px; }
.card { margin:0; background:var(--card); border:1px solid var(--rule); border-radius:3px;
        overflow:hidden; display:flex; flex-direction:column; }
.card img { width:100%; max-width:100%; height:auto; aspect-ratio:4/5; object-fit:cover;
            display:block; border-bottom:1px solid var(--rule); }
figcaption { padding:12px 13px 14px; display:flex; flex-direction:column; gap:6px; }
figcaption h3 { margin:0; font-size:.97rem; font-weight:600; line-height:1.25; }
.role { margin:0; font-size:.79rem; color:var(--ink-soft); }
dl { margin:.2rem 0 0; display:grid; grid-template-columns:auto 1fr; gap:2px 8px;
     font-size:.71rem; font-variant-numeric:tabular-nums; }
dt { color:var(--ink-faint); text-transform:uppercase; letter-spacing:.05em;
     font-size:.61rem; align-self:center; }
dd { margin:0; color:var(--ink-soft); overflow-wrap:anywhere; }
.pill { align-self:flex-start; font-size:.67rem; padding:2px 7px; border-radius:2px;
        letter-spacing:.03em; }
.warn { background:var(--warn-bg); color:var(--warn-ink); }
.ok { background:var(--ok-bg); color:var(--ok-ink); }
.note { margin:.25rem 0 0; font-size:.735rem; line-height:1.45; color:var(--ink-soft);
        border-left:2px solid var(--accent); padding-left:8px; }
.scroll { overflow-x:auto; }
table { border-collapse:collapse; width:100%; font-size:.84rem; }
th,td { text-align:left; padding:7px 10px; border-bottom:1px solid var(--rule); }
th { font-size:.65rem; text-transform:uppercase; letter-spacing:.06em;
     color:var(--ink-faint); font-weight:600; }
td:first-child { font-weight:500; }
td:last-child { color:var(--ink-soft); }
footer { margin-top:3rem; padding-top:1.2rem; border-top:1px solid var(--rule);
         font-size:.8rem; color:var(--ink-faint); line-height:1.65; max-width:78ch; }
code { font-size:.92em; background:var(--card); border:1px solid var(--rule);
       padding:1px 4px; border-radius:2px; }
</style>

<div class="wrap">
<h1>Biloxi and Harrison County portraits</h1>
<p class="stand">Every frame below is the exact file that would be published &mdash; 4:5, 600&times;750, JPEG q90 &mdash; not a preview of one. Nothing has been uploaded and no database row has been written. Mississippi is the last slice of the Knight programme, and all 35 of these officials carry no portrait today.</p>

<ul class="tally">
  <li><b>35</b>officials seated</li>
  <li><b>18</b>portraits found</li>
  <li><b>17</b>none published</li>
  <li><b>5</b>would be upscaled</li>
  <li><b>0</b>carry one today</li>
</ul>

<h2>City of Biloxi <span class="count">8 of 8</span></h2>
<p class="sub">The city publishes a studio portrait for every council member, and a mayoral portrait in its media library. Seven council originals are 2048&times;2560 &mdash; exactly 4:5, so they are a pure resize with no crop decision at all. <b>Not one image on the council page carries alt text</b> and three of its filenames are wrong, so each portrait was bound to its officeholder by the caption the page prints beside it, then checked by eye against the thumbnail it links from.</p>
<div class="grid">
__BIL__
</div>

<h2>Harrison County <span class="count">10 of 27</span></h2>
<p class="sub">The county pages sit behind a challenge that refuses every scripted request, so they were read in a browser and only the image files pulled directly. Each officer has a page of their own, and every page names the officeholder production holds. <b>Three supervisors are published inside a decorative white frame</b>, which was being counted as picture; the frame is trimmed and the crop zoomed on the subject, so those upscale factors are higher than before and now describe the photograph rather than its border. The county has not replaced some of these files since 2016.</p>
<div class="grid">
__HAR__
</div>

<h2>No portrait published <span class="count">17</span></h2>
<p class="sub">These officials are seated and correct. Their offices simply publish no photograph. A blank is the honest answer: a wrong or invented link would read as coverage and hide them from every query that looks for who still needs one.</p>
<div class="scroll">
<table>
  <thead><tr><th>Person</th><th>Office</th><th>Why there is none</th></tr></thead>
  <tbody>
__MISS__
  </tbody>
</table>
</div>

<footer>
Sources: City of Biloxi (biloxi.ms.us), Harrison County (harrisoncountyms.gov), Harrison County Sheriff's Office, Harrison County Chancery Clerk. Each is the officeholder's own government publishing its own officials. Licence would be recorded as <code>press_use</code> on every row, and the source page on <code>photo_origin_url</code>.
</footer>
</div>"""

doc = (doc.replace('__TOKENS__', TOKENS)
          .replace('__BIL__', bil_cards)
          .replace('__HAR__', har_cards)
          .replace('__MISS__', miss_rows))

out = 'data/seed-ms-2026/_assets/ms5-headshot-sheet.html'
open(out, 'w', encoding='utf-8').write(doc)
print('wrote', out, round(os.path.getsize(out) / 1024), 'KB')
