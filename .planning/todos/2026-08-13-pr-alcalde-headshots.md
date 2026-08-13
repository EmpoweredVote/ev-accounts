# PR alcalde headshots — 78 targets, no consolidated source (2026-08-13)

Follows migration 1728, which seated all 78 alcaldes.

## ✅ WAVE 1 DONE — 8 imported, migration 1733 (2026-08-12). **70 remain.**

Humacao · San Juan · Gurabo (Commons, `public_domain`) · Mayagüez · Ponce (Ballotpedia,
`press_use`) · Caguas · Naranjito · Guaynabo (municipal sites, `press_use`). All 8 read back from
the public CDN as `image/jpeg`. Gate proved to fire, dry-run rolled back and confirmed reverted,
applied, re-applied idempotent.

🔴 **Do not re-import these 8.** Resolve the remaining 70 by the office join, never by name:
`d.district_type='LOCAL_EXEC' AND lower(d.state)='pr' AND d.label = '<Municipio> Mayor'`.
Note the label carries the **accented** municipio (`Mayagüez Mayor`) — a deaccented literal
silently matches nothing, which the 1733 seat guard caught live.

Baseline before wave 1: all 78 had no photograph of any kind (`politician_images` 0,
`photo_custom_url` 0, `photo_origin_url` 0). They were the largest headshot gap in the database.

**This cohort is NOT like the legislature.** The 82 legislators (migration 1723) came from two
chamber rosters in a single pass. There is no equivalent here, and that is a property of the data,
not a crawler failure — every source below was checked, not inferred.

## 🔴 Verified negatives — do not re-hunt these

| Source | Result |
|---|---|
| **Federación de Alcaldes** (PNP, 37) `prmayors.com` | Members-only. Login/register wall, no public directory. 3 images, all the seal. |
| **Asociación de Alcaldes** (PPD, 41) `aa-pr.com` | Pure login page ("Credenciales / Usuario / Password"). Nothing public. |
| **Wikidata** | All 78 municipios present (class `Q263639`, FIPS on `P882`) but only **4 heads of government and 2 images**. |
| **CISA `.gov` registry** | Only **4 of 78** municipios hold a `.gov` domain: arroyopr.gov, **bayamonpr.gov (NO DNS AT ALL — `getaddrinfo failed`; registry presence is not a resolvable host)**, mayaguezpr.gov, penuelaspr.gov. |
| **es.wikipedia, per-person** (2026-08-12, `data/pr-alcaldes/eswiki-person-sweep.json`) | Asked the question Wikidata's `P6` check did not: does an article *about this person* carry a portrait. **5 real hits, 3 of them already covered.** Net new: **Gurabo**. Also upgraded Humacao + San Juan. 🔴 **3 of 8 apparent hits were the WRONG PERSON** — see the two-surname trap below. |
| **pr.gov `/directorio-municipios`** | 78 cards, but they carry **escudos, flags, maps, geography and nicknames — no portraits and no website links.** Webflow, needs rendering; raw HTML has zero external links. |
| **pr.gov `/directorio-municipos/<slug>`** (note the typo'd path) | Per-municipio pages exist for all 78 — flag, escudo, map, terrain. **No alcalde portrait.** |

## Site discovery — 30 of 78 found, and Wikidata's URLs are mostly rot

- Wikidata `P856` gives 52 URLs, but only **17** are live AND name their own municipio.
  **24 point at the defunct `gobierno.pr/OCAM/DirectorioMunicipios/...` directory**, one at
  `pr.near-place.com` (a third-party directory, not a government site), 6 are dead, 4 live-but-wrong.
- A programmatic domain sweep (18 patterns × 78, ~1,300 requests, no search quota) found **13 more**.
  Useful PR patterns: `<x>.gov.pr`, `<x>pr.gov`, `municipiode<x>.com`, `<x>pr.com`, `<x>.org`,
  and **`ciudad<x>.com`** (Cabo Rojo = ciudadcaborojo.com, **Ponce = ciudadponce.com**).
- **48 municipios still have no known website.** They need a per-municipio search.

## 🔴 Municipal sites largely DO NOT publish the alcalde's face

Harvested all 30 known sites (render + follow `alcalde`/`biografía`/`mensaje` subpages, read each
`<img>` with its surrounding card text, no size floor). **Yield: 3 real portraits.**

- ✅ **Caguas** — `caguas.gov.pr/.../willie-200x300.jpg` (200×300)
- ✅ **Guaynabo** — `guaynabocity.gov.pr/.../Captura-de-Pantalla…` (199×300)
- ✅ **Naranjito** — `municipiodenaranjito.com` (800×829) — the best of the three
- ❌ **Bayamón — VERIFIED NEGATIVE, closed.** The "256×256, dropped by an aspect filter, re-check"
  note **did not reproduce and no such file exists.** What the site and Commons actually hold for
  Ramón Luis Rivera Cruz: the *Mensaje del Alcalde* **letter** (a text document with his signature),
  one **masked-face** photo filed twice, a biography **slideshow banner with type over it**, a
  mid-speech podium shot, and Commons' `Pedro_P._Ramon_R..jpg` — **two men at a window, in
  profile**. The **filename was the tell**, exactly as with Ballotpedia. Its live site is
  `municipiodebayamon.com`; `bayamonpr.gov` does not resolve. Its WP media library answers
  `/wp-json/wp/v2/media?search=…`, which is the cheap way to enumerate a WP site's portraits.

**What the scorer confidently returned instead**, all caught only by looking:
a **Gran Fiesta de Reyes event poster** (Juncos), the municipal **coat of arms** (Peñuelas, twice),
an **email/envelope icon** (Juncos), a **porch candid of two people** (Arroyo), a **crowd handshake**
(Rincón), and a **"Vida Buena en el Cafetal" promo graphic** (Yauco). Eighth wave running where the
contact sheet caught what every automated check passed.

## 🔴🔴 Ballotpedia — 50/78 pages exist, but naive extraction is WRONG-PERSON 8 times in 12

BP does cover PR alcaldes: **50 of 78 have a profile page**, only **12 carry any portrait**.
Taking the first `ballotpedia-api4` image on the page produced **8 wrong people** — on a BP page
that image is often another candidate in the same race. **The filename is the tell:**

| Municipio | Our alcalde | Filename actually returned |
|---|---|---|
| Caguas | William Miranda Torres | `RobertoLopez.jpe` |
| Gurabo | Rosachely Rivera Santana | `Noel_Coln_Garca_…` |
| Isabela | Miguel Méndez Pérez | `Cindy_Candelario…` |
| Maunabo | Ángel Omar Lafuente Amaro | `JorgeMarquezPere…` |
| Quebradillas | Heriberto Vélez Vélez | `Ramses_Ocasio_20…` |
| Rincón | Carlos López Bonilla | `Ada-Garcia-Monte…` |
| San Lorenzo | Jaime Alverio Ramos | `Hill-Roman-Abreu…` |
| Toa Alta | Clemente Agosto | `Josue_Gonzalez_2…` |

Only **4 pass a filename-vs-surname guard**: **Humacao** (Rosamar Trujillo Plumey), **Mayagüez**
(Jorge Luis Ramos Ruiz), **Ponce** (Marlese Sifre), **San Juan** (Miguel Romero).
**Next attempt must target the infobox image specifically AND keep the filename guard.**

🔴 **BP rate-limits silently — HTTP 202 with a ZERO-byte body.** It started doing this partway
through. Never judge by `r.ok`; back off, or drive it through Playwright as with the CEE portal.
🔴 `api.php?action=parse` is still dead (404). Scrape `ballotpedia.org/<Title>` directly.
BP title forms that worked: plain name, deaccented name, nickname-substituted
(`Tito Ramírez` for Carlos Ramírez Irizarry), middle-initial stripped.

## 🔴🔴 The two-surname trap — it fired THREE MORE TIMES, on es.wikipedia

Scoring article titles by surname-token overlap returned, for three of our alcaldes, three
**entirely different sitting officials**. Two matching surname tokens is **not** a match when
Spanish names carry two surnames drawn from a small pool:

| Municipio | Our alcalde | Title matched | Who that actually is |
|---|---|---|---|
| Carolina | José **Carlos** Aponte **Dalmau** | *José Luis Dalmau* | PPD Senate president |
| Coamo | **Juan Carlos** García Padilla | *Alejandro García Padilla* | **former Governor** |
| Toa Baja | **Bernardo Márquez García** | *José Bernardo Márquez* | sitting House rep (MVC) |

**Do not lower the ≥2-token bar — raise it.** The reliable discriminator is the one migration 1733's
gate now enforces in SQL: the pid must hold the `LOCAL_EXEC` office for the municipio the photo was
sourced for. Prefer a filename that names the *office* (`Alcaldesa_Rosachely_Rivera_Santana.jpg`).

## Two techniques worth reusing

- **Strip the WordPress `-WxH` thumbnail suffix to get the original.** Guaynabo's page served a
  199×300 thumbnail; `…-1.jpg` without the suffix is **500×754**, cutting the upscale 5.88× → 2.52×.
  (Caguas is a genuine 200×300 original — the suffix trick confirms that rather than fixing it.)
- **Read the Commons `extmetadata` license, never infer it from the domain.** All three Commons
  files are `Public domain / Government of Puerto Rico`, *better* than the `cc_by_sa` default — and
  the `Credit` field exposed the official source pages, which are new leads (below).

## New leads the Commons credits handed us (not yet swept)

- `https://sanjuan.pr/perfiles-de-casa-alcaldia…` — San Juan publishes **profile pages with
  portraits**. If other municipios run the same CMS, this is a pattern, not one site.
- `https://desarrollo.gurabopr.net/programas/of…` — Gurabo, on a **non-obvious subdomain** the
  18-pattern domain sweep would never have guessed. Sweep subdomains, not just apex patterns.

## Where it stands

**8 of 78 imported** (migration 1733). **70 remain.** Bayamón is closed as a negative, so the
realistic pool is 69 unknowns + Bayamón-if-it-ever-publishes-one.

## What is left, in order of expected value

1. **Ballotpedia infobox re-extraction** with the filename guard, driven through Playwright to dodge
   the 202. 50 pages exist; the 12-with-images figure came from a naive selector and is probably an
   undercount of what the infobox holds. **Wave 1 used only the 2 that already passed the guard, so
   this is still fully open.** (BP's S3 host `s3.amazonaws.com/ballotpedia-api4` serves images with
   no rate limiting — only `ballotpedia.org` page fetches 202.)
2. **The `sanjuan.pr` / `gurabopr.net` leads above**, then a **subdomain** sweep for the 48 unknown
   sites. Weigh against the measured ~10% portrait yield from the 30 sites already found —
   the WP `/wp-json/wp/v2/media?search=alcalde` enumeration makes each site much cheaper to check
   than a render-and-crawl.
3. **Facebook / press photos** would cover most of the island (PR municipios are very active on
   Facebook and the alcalde is usually pictured) but sit **outside the current source policy**:
   licence is unclear and FB CDN URLs expire. **Needs Chris's explicit ruling before use.**

## Method that worked, keep it

Harvest wide with **no size floor and no aspect filter** → **contact sheet** → look → only then
crop. A size floor is indistinguishable from an empty site, and every defect in this wave (the
letter, the mask, the banner, the two-men-at-a-window) passed every automated check and was caught
only by looking. Crop with a cascade that **only locates**; score face candidates on **position as
well as area** (it picked correctly through Ponce's 3-face and San Juan's 4-face detections), then
review the 600×750 production renders — not the source assets — before importing.

## Name handling for this cohort

`full_name` keeps the CEE rendering including the parenthetical nickname
(`Carlos Rubén (Tito) Ramírez Irizarry`); `first_name`/`last_name` are split on the Spanish
[given…][paternal][maternal] rule with nicknames stripped. **Resolve by `external_id` (-723xxxx) or
by municipio, never by name** — and remember `Florida` and `San Sebastián` resolve off-island.
