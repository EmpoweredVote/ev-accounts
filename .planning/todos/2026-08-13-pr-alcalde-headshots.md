# PR alcalde headshots — 78 targets, no consolidated source (2026-08-13)

Follows migration 1728, which seated all 78 alcaldes. **All 78 have no photograph of any kind**
(`politician_images` 0, `photo_custom_url` 0, `photo_origin_url` 0; external_id band `-723xxxx`).
They are now the largest headshot gap in the database.

**This cohort is NOT like the legislature.** The 82 legislators (migration 1723) came from two
chamber rosters in a single pass. There is no equivalent here, and that is a property of the data,
not a crawler failure — every source below was checked, not inferred.

## 🔴 Verified negatives — do not re-hunt these

| Source | Result |
|---|---|
| **Federación de Alcaldes** (PNP, 37) `prmayors.com` | Members-only. Login/register wall, no public directory. 3 images, all the seal. |
| **Asociación de Alcaldes** (PPD, 41) `aa-pr.com` | Pure login page ("Credenciales / Usuario / Password"). Nothing public. |
| **Wikidata** | All 78 municipios present (class `Q263639`, FIPS on `P882`) but only **4 heads of government and 2 images**. |
| **CISA `.gov` registry** | Only **4 of 78** municipios hold a `.gov` domain: arroyopr.gov, bayamonpr.gov, mayaguezpr.gov, penuelaspr.gov. |
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
- ✅ **Bayamón** — 256×256, found on the first pass, dropped by a later aspect filter; re-check

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

## Where it stands

**~7 verifiable portraits of 78** (3–4 municipal + 4 Ballotpedia). Nothing has been imported.

## What is left, in order of expected value

1. **Ballotpedia infobox re-extraction** with the filename guard, driven through Playwright to dodge
   the 202. 50 pages exist; the 12-with-images figure came from a naive selector and is probably an
   undercount of what the infobox holds.
2. **Per-municipio search for the 48 unknown sites** — but weigh it against the measured ~10% yield
   from the 30 already found.
3. **Facebook / press photos** would cover most of the island (PR municipios are very active on
   Facebook and the alcalde is usually pictured) but sit **outside the current source policy**:
   licence is unclear and FB CDN URLs expire. **Needs Chris's explicit ruling before use.**

## Name handling for this cohort

`full_name` keeps the CEE rendering including the parenthetical nickname
(`Carlos Rubén (Tito) Ramírez Irizarry`); `first_name`/`last_name` are split on the Spanish
[given…][paternal][maternal] rule with nicknames stripped. **Resolve by `external_id` (-723xxxx) or
by municipio, never by name** — and remember `Florida` and `San Sebastián` resolve off-island.
