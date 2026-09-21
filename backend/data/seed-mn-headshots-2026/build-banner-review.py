"""
Build the MN-5 banner certification page.

Spec 8.2: the review shows the REAL 6:1 desktop band at real CSS, at real aspect, with the rejected
options and the live baseline alongside. The artifact CSP blocks external hosts, so every image is
embedded as a data URI; the Supabase CDN would render as a broken box.
"""
import base64
import os

B = (r"C:\Users\Chris\AppData\Local\Temp\claude\C--EV-Accounts"
     r"\2729211a-70e4-4ffc-81d7-1b4e81956c20\scratchpad\bann")
STATE = (r"C:\Users\Chris\AppData\Local\Temp\claude\C--EV-Accounts"
         r"\2729211a-70e4-4ffc-81d7-1b4e81956c20\scratchpad\mn-state.jpg")
OUT = r"C:\EV-Accounts\.tmp-mn5-banners.html"


def uri(path):
    with open(path, "rb") as fh:
        return "data:image/jpeg;base64," + base64.b64encode(fh.read()).decode()


BASELINE = {
    "file": STATE,
    "title": "Minnesota, the live state banner",
    "credit": "w_lemay, CC BY-SA 2.0",
    "origin": "states/MN.jpg, already in production",
    "why": ("This is the composition the two city banners must not repeat: a daytime downtown skyline "
            "panorama under clear sky. The rule compares compositions, not subject nouns."),
    "band": "Towers sit mid-frame; the desktop band keeps them and drops sky and rooftops.",
}

OPTIONS = [
    {"city": "Duluth", "key": "A", "file": "FINAL-duluth.jpg", "verdict": "shipped",
     "title": "The canal, the Aerial Lift Bridge and Canal Park",
     "credit": "Bspor.88, CC0",
     "origin": "Duluth, MN - Aerial Lift Bridge and harbor, aerial, August 2024 - 4000x1660",
     "why": ("Water, piers and a working harbour, with no skyline, so nothing of the state banner "
             "repeats. CC0 carries no attribution obligation. The bridge sits inside the desktop band "
             "at anchor 0.10; at 0.25 it rides the top edge."),
     "band": "The lift bridge spans rows 150 to 250 of 540, inside the 128 to 412 the desktop keeps."},
    {"city": "Duluth", "key": "B", "file": "opt-duluth-c.jpg", "verdict": "alternative",
     "title": "Canal Park light over Lake Superior",
     "credit": "Sharon Mollerus, CC BY 2.0",
     "origin": "Canal Park, Duluth1.jpg - 3598x2024",
     "why": ("The strongest colour of any candidate and unmistakably Lake Superior. It is also the most "
             "saturated thing on the page, and a banner sits directly above the list of officials."),
     "band": "Lighthouse and horizon both sit mid-frame; the band loses only sky and water."},
    {"city": "Duluth", "key": "-", "file": "t-d2-0.20.jpg", "verdict": "rejected",
     "title": "The lift bridge head-on, winter",
     "credit": "Misterhrd, CC BY-SA 4.0",
     "origin": "Duluth MN Aerial Lift Bridge 31 December 2023 - 4968x2591",
     "why": ("Dramatic at full frame and empty at 6:1. The span's steel frames the left and right edges, "
             "and the desktop band keeps mostly the white sky between them."),
     "band": "The subject is the frame, and the frame is what the band cuts."},
    {"city": "Saint Paul", "key": "A", "file": "FINAL-saint-paul.jpg", "verdict": "shipped",
     "title": "Union Depot colonnade, its bases and the lawn",
     "credit": "August Schwerdfeger, CC BY 4.0",
     "origin": "Saint Paul Union Depot headhouse panorama, 2015 - 12285x3974",
     "why": ("A colonnade, not a skyline, so the adjacency test passes against both the state banner "
             "and Duluth. The first crop held the whole building and the desktop band cut its ground "
             "away. Re-cropped for the ground: the roofline is trimmed from the source, so the bases, "
             "the planting strip and the lawn now sit inside the band. The cornice is deliberately "
             "outside it, and mobile still shows it."),
     "band": ("The source is 3.09:1 against the asset's 3.148:1 - 22 source pixels apart - so anchor_y "
              "moves the frame about ten pixels and cannot choose what the band shows. Trimming the "
              "source is the only lever that works.")},
    {"city": "Saint Paul", "key": "-", "file": "t-s4-0.40.jpg", "verdict": "rejected",
     "title": "The same photograph, centred - the first certified crop",
     "credit": "August Schwerdfeger, CC BY 4.0",
     "origin": "Same source, anchor 0.40, no source trim",
     "why": ("Kept here because of how it failed. It reads well on mobile, which keeps 96.9% of the "
             "height, and on desktop the building has no ground: the band ends above the column "
             "bases. 'Better on mobile than desktop' is the Bend failure's signature."),
     "band": "Desktop keeps mid-facade; the base line falls below row 412."},
    {"city": "Saint Paul", "key": "-", "file": "opt-stpaul-b.jpg", "verdict": "rejected",
     "title": "Downtown Saint Paul skyline",
     "credit": "Tony Webster, CC BY 2.0",
     "origin": "Downtown Saint Paul (1444948927) - 3455x1125",
     "why": ("It fails the adjacency rule. A daytime downtown skyline panorama is the state banner's "
             "composition, so a reader moving from the state section to the city section would meet the "
             "same picture twice. The colour is posterised in the source as well."),
     "band": "Composition, not crop, is what rejects this one."},
]

CSS = """
:root{--ground:#F1F4F7;--panel:#FFFFFF;--ink:#121820;--ink-2:#4B5663;--ink-3:#79838F;
 --rule:#D5DCE3;--steel:#2E5E7E;--rust:#9A4A2F;--sage:#3D6B55;--shadow:0 1px 2px rgba(18,24,32,.07);}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--ground:#0F1418;--panel:#161C22;
 --ink:#E6EAEF;--ink-2:#A2ADBA;--ink-3:#79838F;--rule:#27303A;--steel:#7FB2D4;--rust:#D4866C;
 --sage:#7FB395;--shadow:0 1px 2px rgba(0,0,0,.45);}}
:root[data-theme="dark"]{--ground:#0F1418;--panel:#161C22;--ink:#E6EAEF;--ink-2:#A2ADBA;--ink-3:#79838F;
 --rule:#27303A;--steel:#7FB2D4;--rust:#D4866C;--sage:#7FB395;--shadow:0 1px 2px rgba(0,0,0,.45);}
*{box-sizing:border-box}
body{margin:0;background:var(--ground);color:var(--ink);
 font:17px/1.62 Newsreader,Georgia,"Times New Roman",serif;-webkit-font-smoothing:antialiased}
.wrap{max-width:1040px;margin:0 auto;padding:56px 24px 88px}
h1,h2,h3,.label,.verdict{font-family:Archivo,"Helvetica Neue",Arial,sans-serif}
h1{font-size:clamp(28px,3.3vw,39px);font-weight:600;letter-spacing:-.022em;margin:6px 0 12px;
 text-wrap:balance;line-height:1.14}
.standfirst{color:var(--ink-2);max-width:64ch;margin:0}
.label{font-size:11px;letter-spacing:.14em;text-transform:uppercase;color:var(--ink-3);font-weight:600}
.mono{font-family:"IBM Plex Mono",ui-monospace,Consolas,monospace;font-size:13px;
 font-variant-numeric:tabular-nums}
section{margin-top:40px}
h2{font-size:21px;font-weight:600;margin:6px 0 6px;letter-spacing:-.012em}
.opt{background:var(--panel);border:1px solid var(--rule);border-radius:10px;padding:20px;
 margin-top:18px;box-shadow:var(--shadow)}
.opt.is-rejected{background:transparent;border-style:dashed;box-shadow:none}
.opt-head{display:flex;gap:12px;align-items:baseline;flex-wrap:wrap;margin-bottom:2px}
.opt-head h3{font-size:18px;font-weight:600;margin:0;letter-spacing:-.01em}
.verdict{font-size:10px;letter-spacing:.11em;text-transform:uppercase;font-weight:600;
 padding:3px 9px;border-radius:999px;border:1px solid}
.v-recommended{color:var(--sage);border-color:var(--sage)}
.v-shipped{color:var(--panel);background:var(--sage);border-color:var(--sage)}
.v-alternative{color:var(--steel);border-color:var(--steel)}
.v-rejected{color:var(--rust);border-color:var(--rust)}
.v-baseline{color:var(--ink-3);border-color:var(--rule)}
.bands{display:grid;grid-template-columns:1fr 306px;gap:16px;margin:16px 0 14px;align-items:start}
@media (max-width:780px){.bands{grid-template-columns:1fr}}
.band{margin:0}
.band img{width:100%;height:100%;object-fit:cover;display:block}
.band figcaption{margin-top:7px}
.desktop-box{aspect-ratio:6/1;border-radius:6px;overflow:hidden;background:var(--rule)}
.mobile-box{aspect-ratio:13/4;border-radius:6px;overflow:hidden;background:var(--rule)}
.why{color:var(--ink-2);max-width:68ch;margin:0 0 12px}
.meta{display:flex;gap:22px;flex-wrap:wrap;border-top:1px solid var(--rule);padding-top:11px;
 color:var(--ink-3)}
.meta div{display:flex;flex-direction:column;gap:3px;max-width:46ch}
.rule{height:1px;background:var(--rule);border:0;margin:42px 0 0}
.callout{border-left:3px solid var(--steel);padding:3px 0 3px 16px;margin:20px 0 0;color:var(--ink-2);
 max-width:66ch}
.next{background:var(--panel);border:1px solid var(--rule);border-radius:10px;padding:18px 22px;
 margin-top:30px;box-shadow:var(--shadow)}
.next ol{margin:10px 0 0;padding-left:20px}
.next li{margin:6px 0;color:var(--ink-2)}
"""


def card(opt, data_uri, baseline=False):
    verdict = "baseline" if baseline else opt["verdict"]
    key = "" if baseline else (
        '<span class="mono" style="color:var(--ink-3)">Option ' + opt["key"] + "</span>")
    rejected = " is-rejected" if verdict == "rejected" else ""
    return f"""
  <article class="opt{rejected}">
    <div class="opt-head">
      {key}
      <h3>{opt['title']}</h3>
      <span class="verdict v-{verdict}">{verdict}</span>
    </div>
    <div class="bands">
      <figure class="band">
        <div class="desktop-box"><img src="{data_uri}" alt="{opt['title']}, desktop band"></div>
        <figcaption class="label">desktop &middot; 6:1 &middot; keeps rows 128&ndash;412 of 540</figcaption>
      </figure>
      <figure class="band">
        <div class="mobile-box"><img src="{data_uri}" alt="{opt['title']}, mobile band"></div>
        <figcaption class="label">mobile &middot; 13:4 &middot; keeps 8&ndash;532</figcaption>
      </figure>
    </div>
    <p class="why">{opt['why']}</p>
    <div class="meta mono">
      <div><span class="label">credit</span>{opt['credit']}</div>
      <div><span class="label">source</span>{opt['origin']}</div>
      <div><span class="label">in the band</span>{opt['band']}</div>
    </div>
  </article>"""


duluth = "".join(card(o, uri(os.path.join(B, o["file"])))
                 for o in OPTIONS if o["city"] == "Duluth")
stpaul = "".join(card(o, uri(os.path.join(B, o["file"])))
                 for o in OPTIONS if o["city"] == "Saint Paul")

HTML = f"""<title>Duluth and Saint Paul Banners</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Archivo:wght@500;600&family=Newsreader:opsz,wght@6..72,400;6..72,500&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>{CSS}</style>
<div class="wrap">
  <header>
    <p class="label">Knight programme &middot; slice 5 &middot; stage 5</p>
    <h1>Two Minnesota banners, judged in the band a reader actually sees</h1>
    <p class="standfirst">Every frame below is the production render, at real CSS and real aspect.
      <strong>One file shows two different pictures</strong>: a phone keeps 96.9% of the 540-pixel
      height, a desktop keeps the middle 52.5%, rows 128 to 412. Bend, Oregon shipped broken because it
      was certified on the full frame and reviewed on a phone.</p>
    <p class="callout">The adjacency rule compares <em>compositions</em>, not subject nouns. Minnesota's
      state banner is a daytime downtown skyline panorama, so neither city may be one, and the two
      cities must not repeat each other either.</p>
  </header>

  <section>
    <p class="label">the baseline</p>
    <h2>What already sits above these pages</h2>
    {card(BASELINE, uri(BASELINE['file']), baseline=True)}
  </section>

  <hr class="rule">
  <section>
    <p class="label">city one</p>
    <h2>Duluth</h2>
    <p class="standfirst">Three candidates, all free-licensed, all from Wikimedia Commons.</p>
    {duluth}
  </section>

  <hr class="rule">
  <section>
    <p class="label">city two</p>
    <h2>Saint Paul</h2>
    <p class="standfirst">The harder half. Saint Paul's best-known view is a skyline across a river,
      which is the one composition the rule refuses.</p>
    {stpaul}
  </section>

  <div class="next">
    <p class="label">shipped 2026-09-16</p>
    <ol>
      <li>Both frames composed at 1700&times;540, JPEG q90 progressive, and uploaded to
        <span class="mono">cities/duluth.jpg</span> and <span class="mono">cities/saint-paul.jpg</span>.
        Fetched back from the CDN and decoded: sha256 identical to the local files, and a key that
        cannot exist returned HTTP 400.</li>
      <li>Two <span class="mono">match:'exact'</span> keys added to
        <span class="mono">buildingImages.js</span>, state-scoped to MN. Both are load-bearing:
        <em>Duluth, Georgia</em> is a city of 33,000 in Gwinnett County, and Georgia is slice 2 of this
        same programme.</li>
      <li>Both recorded in <span class="mono">banner_review.md</span> with their credits, and
        <span class="mono">banners.json</span> regenerated. 429 tests pass.</li>
      <li>Open as <strong>essentials#150</strong>.</li>
    </ol>
  </div>
</div>
"""

with open(OUT, "w", encoding="utf-8") as fh:
    fh.write(HTML)
print(f"wrote {OUT}  ({os.path.getsize(OUT) / 1024 / 1024:.2f} MB)")
