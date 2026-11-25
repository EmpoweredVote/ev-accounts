# Brief — Indiana cities Wave B (10,000-34,000 people): collect each city's elected offices, current holders and council map source

You are collecting sources for Indiana cities. You do NOT write to any database. You write one JSON
file per city and save the raw pages you read. A later step verifies every name against your saved pages,
so a name that is not in a saved page will be thrown away.

Data folder: `/Users/chrisandrews/Documents/GitHub/_worktrees/ev-accounts/in-cities-wave-b/backend/data/seed-in-cities-wave-b/`
City list (geoid, name, slug): `wave-b-cities.json` in that folder.

## Hard rules

1. **Never take a person's name, a date or a seat number from WebFetch output or a search summary.** Those tools
   invent names. Use WebSearch/WebFetch only to FIND the right URL. Then download the page with `curl` and read
   the text yourself:
   ```bash
   curl -sL --max-time 30 -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130 Safari/537.36" \
     -H "Accept: text/html,application/xhtml+xml" -H "Accept-Language: en-US,en;q=0.9" \
     "<url>" -o raw/<slug>/<short-name>.html
   ```
   Every page you take a fact from must be saved under `raw/<slug>/`. Check the saved file actually contains the
   names (grep it). A 200 response can be an error page, a bot check or a different city.
2. **The city's own website outranks everything** (council page, mayor page, clerk page, city code). Use
   Ballotpedia or news only to fill a gap, and say so in `notes`.
3. If you cannot confirm something, leave it `null` and say why in `notes`. A blank is correct; a guess is a defect.
4. Budget: at most ~40 web searches per city. Do not research stances, bios, photos or finance.

## What state law says (so you know what to look for)

- Most Wave B cities are **third class**. Some kept second-class status after shrinking below 34,000 (check).
- **Second class city** (most cities of 34,000+): Common Council = **6 district members + 3 at-large members**;
  a **City Clerk**; a **Mayor**.
- **Third class city**: usually **5 district + 2 at-large**, or by ordinance **4 district + 3 at-large**; a
  **Clerk-Treasurer**; a **Mayor**. A few use other layouts allowed by ordinance; report what the city shows.
- A city's class can differ from what its population suggests. Report what the city itself shows: how many council
  seats, how many by district and how many at-large, and whether it has a City Clerk or a Clerk-Treasurer.
- Some cities also elect a **city court judge**. Record it if the city has one (it is out of scope for now, but we
  want to know).
- At-large seats in Indiana are NOT numbered. Do not invent "Seat 1/2/3".

## What to collect per city

1. **Structure**: council size, district count, at-large count, clerk title, city court judge (yes/no/unknown),
   and the page that shows it (ideally the city code's "elected officials" section or the council page).
2. **Current holders** as of today (late November 2026): Mayor, Clerk (or Clerk-Treasurer), and every council member with
   their district number or "at-large". Note anyone appointed mid-term (caucus replacement) and when, if the page says.
3. **Council district map source**, in this order of preference:
   a. An ArcGIS REST layer (FeatureServer or MapServer) of the council districts, run by the city or county.
      Search `"<city> council districts" arcgis`, look in the city/county GIS portal, open data hub, or the county
      "GIS" page. For a candidate layer, confirm with:
      `curl -s "<layer url>/query?where=1%3D1&returnCountOnly=true&f=json"` → count should equal the district count,
      and `curl -s "<layer url>/query?where=1%3D1&outFields=*&returnGeometry=false&f=json"` → record the field that
      holds the district number. Paste both outputs (trimmed) into `notes`.
   b. If no layer: a PDF or image map, or the council-district ordinance listing the precincts in each district
      (Indiana districts are built from whole precincts). Give the URL.
   c. **The map must be the CURRENT one (the post-2020-census redraw, usually adopted in 2022 or 2023).** Wave A
      found two city layers that were the OLD map (Anderson's dated 2007, Crown Point's pre-2022), and nothing in a
      layer says so. For every layer you report, record its evidence of date: a year in the layer or service name,
      the service description, `editingInfo.lastEditDate` from `<layer url>?f=json`, a population field (sum it and
      compare with the city's 2020 census count), or the ordinance number. If the city also publishes a PDF map with
      an adoption date, SAVE it under `raw/<slug>/` too, so the two can be compared. Say plainly in `vintage` if you
      cannot tell.
   d. **The precinct list matters most for small cities.** Indiana districts are built from whole precincts. If the
      city's redistricting ordinance (or a map that labels each precinct with its district) is online, save it. We can
      build the map from the state's 2026 precinct layer with it.
   e. Known dead ends, do not spend searches on them: Schneider "Beacon" county viewers (behind a bot check and a
      terms gate, and data export is off); Hamilton County's `gis1.hamiltoncounty.in.gov` (refuses scripts).

## Output: `cities/<slug>.json`

```json
{
  "slug": "michigan-city-in",
  "geoid": "1848798",
  "name": "Michigan City",
  "structure": {
    "council_size": 9, "district_seats": 6, "at_large_seats": 3,
    "clerk_title": "City Clerk",
    "city_court_judge": "yes|no|unknown",
    "source_url": "...", "source_file": "raw/evansville-in/code.html",
    "council_name": "Evansville City Council"
  },
  "holders": [
    {"office": "Mayor", "name": "...", "source_url": "...", "source_file": "raw/...", "note": null},
    {"office": "City Clerk", "name": "...", "source_url": "...", "source_file": "raw/...", "note": null},
    {"office": "Council Member, District 1", "name": "...", "source_url": "...", "source_file": "raw/...", "note": null},
    {"office": "Council Member, At Large", "name": "...", "source_url": "...", "source_file": "raw/...", "note": null}
  ],
  "council_map": {
    "kind": "arcgis|pdf|ordinance|none",
    "url": "...", "feature_count": 6, "district_field": "DISTRICT",
    "vintage": "2022 redistricting ordinance ...", "notes": "..."
  },
  "notes": "anything uncertain, conflicts between sources, gaps"
}
```

Write names exactly as the city page spells them (keep middle initials and suffixes; drop honorifics like "Hon.",
"Councilman", "Dr."). When done, return a 3-line summary per city: structure, how many holders found / expected,
map kind.
