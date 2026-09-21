"""
Build the CO-3 banner certification page.

Same contract as MN-5's page: every frame is the production render at real CSS and real aspect, the
rejected options are shown with the reason, and the live baselines sit beside them. The CSS is READ
from the MN-5 builder rather than copied, so the two review pages cannot drift apart.

Colorado is the first slice where TWO compositions are already spoken for — the Denver skyline as the
state banner, and Garden of the Gods, which Colorado Springs took because of it.
"""
import base64
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
MN_BUILDER = os.path.join(HERE, "..", "seed-mn-headshots-2026", "build-banner-review.py")
SCRATCH = (r"C:\Users\Chris\AppData\Local\Temp\claude\C--EV-Accounts"
           r"\2729211a-70e4-4ffc-81d7-1b4e81956c20\scratchpad")
B = os.path.join(SCRATCH, "bould")
OUT = r"C:\EV-Accounts\.tmp-co3-banners.html"

CSS = re.search(r'CSS = """(.*?)"""', open(MN_BUILDER, encoding="utf-8").read(), re.S).group(1)


def uri(path):
    with open(path, "rb") as fh:
        return "data:image/jpeg;base64," + base64.b64encode(fh.read()).decode()


BASELINES = [
    {"file": os.path.join(SCRATCH, "co-state.jpg"),
     "title": "Colorado, the live state banner",
     "credit": "states/CO.jpg, already in production",
     "origin": "Denver skyline with the Front Range behind it",
     "why": ("The first of TWO compositions already spoken for in this state: a daytime downtown "
             "skyline at eye level, mountains as a back wall."),
     "band": "Towers fill the band and the mountains sit behind them."},
    {"file": os.path.join(SCRATCH, "cos.jpg"),
     "title": "Colorado Springs, the sibling city",
     "credit": "cities/colorado-springs.jpg, already in production",
     "origin": "Garden of the Gods, chosen BECAUSE the state banner is a skyline",
     "why": ("The second, and the harder one for Boulder: near-field rock formations filling the "
             "frame at eye level, green below, plain behind. Colorado Springs went to rock precisely "
             "to avoid the Denver skyline, which leaves Boulder needing a frame that is neither."),
     "band": "Red fins fill the band edge to edge."},
]

OPTIONS = [
    {"key": "A", "file": "opt-b5.jpg", "verdict": "recommended",
     "title": "The Flatirons from Bluebell Road",
     "credit": "joiseyshowaa, CC BY-SA 2.0",
     "origin": "The Flatirons and Bluebell Road - 5824x2942",
     "why": ("The one frame a Boulder resident recognises instantly, and the closest call against "
             "Colorado Springs, which is why it sits directly under it. The rock is grey-tan tilted "
             "slab rather than red fin; the camera looks UP a mountain flank through a pine screen "
             "rather than across a park at eye level; and the near field is forest, not rock. The "
             "Asheville ruling makes the test camera height and what fills the frame, and both differ."),
     "band": "Slabs occupy the upper band and pines the lower; nothing important is cut."},
    {"key": "B", "file": "opt-b6.jpg", "verdict": "alternative",
     "title": "The city under snow, from Flagstaff Mountain",
     "credit": "Hustvedt, CC BY-SA 3.0",
     "origin": "Boulder-Snow-flagstaff-big - 14597x2651",
     "why": ("Boulder itself rather than the rock behind it, seen from above under snow. It clears "
             "both baselines cleanly, because an elevated town view is neither an eye-level skyline "
             "nor a rock face, and it is the safer choice if the Flatirons read as too close to "
             "Garden of the Gods. Its weakness is legibility: a low-rise town from height is quiet "
             "at banner size."),
     "band": "The street grid runs through the middle of the band."},
    {"key": "C", "file": "opt-b1.jpg", "verdict": "alternative",
     "title": "Chautauqua Park, the meadow trail above the city",
     "credit": "Akos Kokai, CC BY 2.0",
     "origin": "Chautauqua Park (9709143875) - 10800x2340",
     "why": ("Golden meadow and a trail looking out over the plains, with the city as a distant "
             "band. Distinct from both baselines. But the Flatirons are behind the camera, so this "
             "frame could be many foothill towns: it is the least specifically Boulder of the three."),
     "band": "Trail and meadow fill the band; the city is a thin line along the top."},
    {"key": "-", "file": "opt-b4.jpg", "verdict": "rejected",
     "title": "Pearl Street Mall",
     "credit": "Pedro Szekely, CC BY-SA 2.0",
     "origin": "Boulder, Colorado (29290343542) - 4708x1901",
     "why": ("Compositionally the most distinctive candidate here, a street corridor like "
             "Bloomington's banner, and it fails the people test outright: the figures are hundreds "
             "of pixels tall and plainly identifiable. The programme accepted 10-20px silhouettes at "
             "Travis County and refused roughly 67px figures at Durham. This is far past both."),
     "band": "Identifiable faces across the whole band."},
    {"key": "-", "file": "opt-b7.jpg", "verdict": "rejected",
     "title": "Sunset over the range, with smoke",
     "credit": "Zach Dischner, CC BY 2.0",
     "origin": "Flatirons On Fire (6009468495) - 8308x2275",
     "why": ("The most dramatic sky of any candidate and the wrong subject: the band across it is "
             "wildfire smoke, and a parked car and a standing figure sit in the near field. A civic "
             "banner should not open a resident's page with a fire."),
     "band": "Smoke fills the upper band; the car and figure sit at the lower edge."},
]


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


baselines = "".join(card(b, uri(b["file"]), baseline=True) for b in BASELINES)
candidates = "".join(card(o, uri(os.path.join(B, o["file"]))) for o in OPTIONS)

HTML = f"""<title>The Boulder Banner</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Archivo:wght@500;600&family=Newsreader:opsz,wght@6..72,400;6..72,500&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>{CSS}</style>
<div class="wrap">
  <header>
    <p class="label">Knight programme &middot; slice 9 &middot; stage 5</p>
    <h1>Boulder, against the two Colorado frames already taken</h1>
    <p class="standfirst">Every frame is the production render, at real CSS and real aspect. One file
      shows two different pictures: a phone keeps 96.9% of the 540-pixel height, a desktop keeps the
      middle 52.5%, rows 128 to 412.</p>
    <p class="callout">Colorado is the first slice where <strong>two</strong> compositions are already
      spoken for. The state banner is the Denver skyline, and Colorado Springs took Garden of the Gods
      <em>because</em> of it. Boulder has to be neither &mdash; and Boulder's signature view is rock,
      which is what makes this a real test rather than a formality.</p>
  </header>

  <section>
    <p class="label">the two baselines</p>
    <h2>What Boulder has to differ from</h2>
    {baselines}
  </section>

  <hr class="rule">
  <section>
    <p class="label">the candidates</p>
    <h2>Boulder</h2>
    <p class="standfirst">Five candidates, all free-licensed, all from Wikimedia Commons. Two are
      rejected and both are shown, because <em>why</em> they fail is the useful part.</p>
    {candidates}
  </section>

  <div class="next">
    <p class="label">what happens once you choose</p>
    <ol>
      <li>The chosen frame is already composed at 1700&times;540, JPEG q90 progressive.</li>
      <li>Upload to <span class="mono">cities/boulder.jpg</span> in the
        <span class="mono">politician_photos</span> bucket.</li>
      <li>Add one <span class="mono">match:'exact'</span> key scoped to CO. Load-bearing as ever:
        <em>Boulder City, Nevada</em> is a separate city, already seated in production.</li>
      <li>Record it in <span class="mono">banner_review.md</span> with the credit its licence
        requires, and regenerate <span class="mono">banners.json</span>.</li>
    </ol>
  </div>
</div>
"""

with open(OUT, "w", encoding="utf-8") as fh:
    fh.write(HTML)
print(f"wrote {OUT}  ({os.path.getsize(OUT) / 1024 / 1024:.2f} MB)")
