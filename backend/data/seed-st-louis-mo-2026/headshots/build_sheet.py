"""Build the St. Louis headshot approval contact sheet.

Every frame is the ACTUAL production render (4:5 centre crop, 600x750), shown at 240x300
and embedded as a data: URI -- the artifact CSP blocks external image hosts, so a hotlinked
src renders as a broken box and the operator approves nothing but alt text.
"""
import csv, base64, io, json
from PIL import Image

dims = dict(l.split('\t') for l in open('all-dims.tsv').read().splitlines() if l)

rows = []
for eid, name, role, img, page in csv.reader(open('city-sources.tsv', encoding='utf-8'), delimiter='\t'):
    rows.append(dict(
        eid=eid, name=name, role=role, img=img, page=page,
        fn=img.rsplit('/', 1)[1].replace('%20', ' '),
        group='city', host='stlouis-mo.gov', lic='press_use',
        binding='profile page &lt;title&gt; names them' if 'profile.cfm' in page else 'department profile page',
    ))

C = 'https://stlouiscountymo.gov/sites/default/cache/file/'
POS = 'council page card text &middot; alt is POSITIONAL ("District %d")'
county = [
    ('-2790423', 'Rita Heard Days',     'Council Member, District 1', C + '8C81B1F4-6134-4FA5-B686DF555A5B477A.jpg', POS % 1),
    ('-2790424', 'Gretchen Bangert',    'Council Member, District 2', C + 'DF037C3B-2EFE-409E-B5739272355EAC86.jpg', POS % 2),
    ('-2790425', 'Dennis Hancock',      'Council Member, District 3', C + '6C967536-E556-41D7-864277BA7876CC5E.jpg', POS % 3),
    ('-2790426', 'Shalonda D. Webb',    'Council Member, District 4', C + '6DFA838B-C113-4F89-921E9C8343782CA4.png', POS % 4),
    ('-2790427', 'Lisa D. Clancy',      'Council Member, District 5', C + 'B7918E3A-CBD5-4635-8534FB571D9B574B.jpg', POS % 5),
    ('-2790428', 'Michael Archer',      'Council Member, District 6', C + 'DFDC4783-BBA9-46FD-BBD61E7F793B142B.jpg', POS % 6),
    ('-2790429', 'Mark Harder',         'Council Member, District 7', C + '7CA4891A-82C8-42B8-ADEE57EA4A060708.jpg', POS % 7),
    ('-2790430', 'Sam Page',            'County Executive',     'https://stlouiscountymo.gov/sites/default/assets/County%20Executive/Dr-Page-photo-web-resize-1.jpg', 'alt names them: "portrait of county executive sam page"'),
    ('-2790431', 'Melissa Price Smith', 'Prosecuting Attorney', 'https://stlcopa.stlouiscountymo.gov/sites/stlcopa/assets/images/Prosecuting%20Attorney/Melissa%20Price%20Smith.jpg', 'own bio page &middot; alt names them'),
    ('-2790432', 'Jake Zimmerman',      'County Assessor',      'https://stlouiscountymo.gov/site-assets/images/county-assessor/JakeZimmerman.jpg', 'alt names them: "County Assessor Jake Zimmerman"'),
]
PAGES = {
    '-2790430': 'https://stlouiscountymo.gov/st-louis-county-government/county-executive/',
    '-2790431': 'https://stlcopa.stlouiscountymo.gov/prosecutor-melissa-price-smith/',
    '-2790432': 'https://stlouiscountymo.gov/st-louis-county-government/county-assessor/',
}
for eid, name, role, img, binding in county:
    rows.append(dict(
        eid=eid, name=name, role=role, img=img,
        page=PAGES.get(eid, 'https://stlouiscountymo.gov/st-louis-county-government/county-council/'),
        fn=img.rsplit('/', 1)[1].replace('%20', ' '),
        group='county',
        host='stlcopa.stlouiscountymo.gov' if 'stlcopa' in img else 'stlouiscountymo.gov',
        lic='press_use', binding=binding,
    ))


def named(fn, name):
    """Does the filename carry any part of the person's name? If not, it is the off-by-one class."""
    f = fn.lower()
    return any(p.strip('.').lower() in f for p in name.replace('.', '').split() if len(p) > 2)


for r in rows:
    r['dim'] = dims.get(r['eid'], '?')
    w, h = (int(x) for x in r['dim'].split('x'))
    cw = round(h * 4 / 5) if w / h > 0.8 else w
    r['up'] = round(600 / cw, 1)
    r['named'] = named(r['fn'], r['name'])
    im = Image.open('render/%s.jpg' % r['eid']).resize((240, 300), Image.LANCZOS)
    b = io.BytesIO()
    im.save(b, 'JPEG', quality=72)
    r['uri'] = 'data:image/jpeg;base64,' + base64.b64encode(b.getvalue()).decode()

json.dump([{k: v for k, v in r.items() if k != 'uri'} for r in rows],
          open('sheet-manifest.json', 'w'), indent=1)

flagged = [r['name'] for r in rows if not r['named']]
big = [r['name'] for r in rows if r['up'] > 2.2]


def card(r):
    badges = ''
    if not r['named']:
        badges += '<span class="b b-face">verify face</span>'
    if r['up'] > 2.2:
        badges += '<span class="b b-size">%s&times; upscale</span>' % r['up']
    return (
        '<article class="card%s">'
        '<img src="%s" alt="Production crop shown for %s, %s" width="240" height="300">'
        '<div class="meta"><h3>%s</h3><p class="role">%s</p><div class="badges">%s</div>'
        '<dl><dt>file</dt><dd class="mono">%s</dd>'
        '<dt>source</dt><dd class="mono">%s &rarr; 600&times;750 (%s&times;)</dd>'
        '<dt>host</dt><dd>%s &middot; %s</dd>'
        '<dt>bound by</dt><dd>%s</dd></dl></div></article>'
    ) % (' risk' if not r['named'] else '', r['uri'], r['name'], r['role'],
         r['name'], r['role'], badges, r['fn'], r['dim'], r['up'], r['host'], r['lic'], r['binding'])


city = [r for r in rows if r['group'] == 'city']
cty = [r for r in rows if r['group'] == 'county']

CSS = """
@import url('https://fonts.googleapis.com/css2?family=Source+Serif+4:opsz,wght@8..60,400;8..60,600&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono&display=swap');
:root{color-scheme:light;--paper:#f6f5f1;--card:#fffefc;--ink:#1c1b18;--mut:#6c685f;--rule:#dcd7cd;--acc:#7a4a2b;--riskbg:#fdf3e5;--riskrule:#c0801f;--sizebg:#eeebe2;--sizeink:#5b5340}
@media(prefers-color-scheme:dark){:root:not([data-theme="light"]){color-scheme:dark;--paper:#14141a;--card:#1e1e25;--ink:#e9e6e0;--mut:#9b968b;--rule:#33323b;--acc:#cf9a68;--riskbg:#2b2113;--riskrule:#c8862a;--sizebg:#262631;--sizeink:#b7afa0}}
:root[data-theme="dark"]{color-scheme:dark;--paper:#14141a;--card:#1e1e25;--ink:#e9e6e0;--mut:#9b968b;--rule:#33323b;--acc:#cf9a68;--riskbg:#2b2113;--riskrule:#c8862a;--sizebg:#262631;--sizeink:#b7afa0}
*{box-sizing:border-box}
body{background:var(--paper);color:var(--ink);font-family:'IBM Plex Sans',system-ui,sans-serif;margin:0;padding-block:28px 56px;padding-left:16px;padding-right:16px}
.wrap{max-width:1180px;margin:0 auto}
h1{font-family:'Source Serif 4',Georgia,serif;font-weight:600;font-size:clamp(1.5rem,4vw,2.05rem);margin:0 0 8px;text-wrap:balance}
.sub{color:var(--mut);margin:0 0 20px;max-width:64ch;line-height:1.55}
.tally{display:flex;flex-wrap:wrap;gap:10px;margin:0 0 8px}
.t{background:var(--card);border:1px solid var(--rule);border-radius:3px;padding:8px 12px;font-size:.82rem}
.t b{font-variant-numeric:tabular-nums;font-size:1.05rem}
h2{font-family:'Source Serif 4',Georgia,serif;font-size:1.16rem;font-weight:600;margin:34px 0 6px;padding-bottom:6px;border-bottom:2px solid var(--acc)}
.note{color:var(--mut);font-size:.84rem;margin:0 0 14px;line-height:1.55;max-width:74ch}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(216px,1fr));gap:16px}
.card{background:var(--card);border:1px solid var(--rule);border-radius:3px;overflow:hidden;display:flex;flex-direction:column}
.card.risk{border-color:var(--riskrule);border-width:2px;background:var(--riskbg)}
.card img{width:100%;height:auto;display:block;border-bottom:1px solid var(--rule)}
.meta{padding:11px 12px 13px;display:flex;flex-direction:column;gap:5px}
h3{font-family:'Source Serif 4',Georgia,serif;font-size:1rem;font-weight:600;margin:0;line-height:1.25}
.role{margin:0;color:var(--mut);font-size:.78rem}
.badges{display:flex;flex-wrap:wrap;gap:5px}
.b{font-size:.65rem;letter-spacing:.05em;text-transform:uppercase;padding:2px 6px;border-radius:2px;font-weight:600}
.b-face{background:var(--riskrule);color:#fff}
.b-size{background:var(--sizebg);color:var(--sizeink);border:1px solid var(--rule)}
dl{margin:4px 0 0;display:grid;grid-template-columns:auto 1fr;gap:2px 8px;font-size:.72rem;line-height:1.42}
dt{color:var(--mut);text-transform:uppercase;letter-spacing:.04em;font-size:.62rem;padding-top:2px}
dd{margin:0;overflow-wrap:anywhere}
.mono{font-family:'IBM Plex Mono',ui-monospace,monospace;font-size:.68rem;font-variant-numeric:tabular-nums}
"""

HTML = """<title>St. Louis Headshot Sheet</title>
<style>%s</style>
<div class="wrap">
<h1>St. Louis headshots &mdash; approval sheet</h1>
<p class="sub">Every frame below is the actual production render: the same 4:5 centre crop and 600&times;750 resize the import writes, shown here at 240&times;300. Approving a card approves that picture.</p>
<div class="tally">
<span class="t"><b>32</b> sourced</span>
<span class="t"><b>%d</b> need a face check</span>
<span class="t"><b>%d</b> upscaled over 2.2&times;</span>
<span class="t"><b>0</b> not found</span>
</div>
<p class="note">Every source is an official government page, so the licence is <span class="mono">press_use</span> throughout. No social media, no campaign photography, nothing monochrome.</p>

<h2>City of St. Louis &mdash; 22</h2>
<p class="note">Each alderman came from their own profile page, and that page&rsquo;s <span class="mono">&lt;title&gt;</span> independently names them. The profile ids are opaque (<span class="mono">id=1543</span>), so the title is what ties a face to a name &mdash; never row order. Two filenames carry a <strong>stale ward number</strong> from the superseded 28-ward map (<span class="mono">Schweitzer-ward-13</span>, <span class="mono">boyd-pamela-ward-27</span>); the surname still matches, so those are not flagged.</p>
<div class="grid">%s</div>

<h2>St. Louis County &mdash; 10</h2>
<p class="note">The seven council portraits carry the weakest binding on this page. Their filenames are <strong>bare UUIDs</strong> and their <span class="mono">alt</span> text is <strong>positional</strong> &mdash; <span class="mono">alt="District 1"</span> names the seat, not the person &mdash; so only the card text beside each face ties it to a name. That is the shape an off-by-one error hides in. Check these seven hardest.</p>
<p class="note">The county also serves an <span class="mono">_portrait</span> variant at 800&times;1200 for <em>every</em> asset id, including ones that are not portraits at all. Measured against the 300&times;300 original it is <strong>softer</strong> &mdash; edge energy 640 against 1377 &mdash; so it is an upscale, not detail. These use the originals.</p>
<div class="grid">%s</div>
</div>""" % (CSS, len(flagged), len(big),
             ''.join(card(r) for r in city), ''.join(card(r) for r in cty))

open('contact-sheet.html', 'w', encoding='utf-8').write(HTML)
print('rows %d | no-name-in-filename %d | upscale>2.2x %d' % (len(rows), len(flagged), len(big)))
print('FLAGGED:', ', '.join(flagged))
print('sheet %d KB' % (len(HTML) // 1024))
