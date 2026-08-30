# Knight Program — Florida Wave FL-7 (Florida assets) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close Florida's stage 5 — four banner keys and 71 headshots — and fix the banner lookup, which cannot currently express what Florida needs.

**Architecture:** Three parts, in this order. **(1)** Two additive changes to `getBuildingImages` in the *essentials* repo: an opt-in `match: 'exact'` per curated entry, and a `CURATED_COUNTY` tier keyed by county GEOID. **(2)** Four banners sourced, certified in the 6:1 desktop band, and approved as one Artifact. **(3)** 71 headshots hunted per body, approved as contact-sheet Artifacts, imported through the existing guarded importer. Banners go first because every open decision lives in them and the half is small; the headshot hunt is a long grind with no decisions in it, so a stall there still leaves the banners delivered.

**Tech Stack:** React 18 + Vite (essentials, Netlify), vitest; Node 24 + TypeScript (ev-accounts); Python 3 + Pillow for crops; Supabase Storage; `psql` against the session pooler.

**Spec:** [`docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`](../specs/2026-08-28-knight-cities-program-design.md) — §7 headshots, §8 banners, §9 approval artifacts.
**Slice notes:** [`.planning/knight-foundation/fl.md`](../../../.planning/knight-foundation/fl.md)
**Tracker:** [`.planning/knight-foundation/PROGRAM.md`](../../../.planning/knight-foundation/PROGRAM.md)

---

## Global Constraints

- 🔴 **TWO REPOS.** Banners live in **`C:\Transparent Motivations\essentials`** (`src/lib/buildingImages.js`), deployed by **Netlify**. Headshots live in **ev-accounts** (`C:/ev-accounts-knight`, branch `docs/knight-cities-program`). `treasury.municipalities` is **dead** — do not write to it.
- 🔴 **NEVER Facebook or any social network** for a headshot. Press, official and public-domain only. Campaign photos and official rosters are acceptable. **A photographer's copyright is a refusal.**
- 🔴 **Approval is ALWAYS a batch contact sheet published as an Artifact**, never one dialog per person. Do not ask per cohort — the rule is standing.
- 🔴 **Crop about one ear above the hair.** The upscale gate measures the **face** crop, not the frame. **Skip monochrome**, judicial portraits included.
- 🔴 **Report measured yield in USABLE headshots**, never a count of files touched.
- 🔴 **The image check is the MAGIC NUMBER**, never the file extension and never `r.ok` — **a WAF rejection can arrive as HTTP 200**.
- 🔴 **Overwriting a Supabase Storage path does NOT reliably purge the CDN.** Measured 2026-08-18 on `states/TX.jpg`. Every new banner takes a **new** filename; if one is ever replaced, version the filename (`-v2`).
- 🔴 **The Artifact CSP blocks external hosts.** The Supabase CDN will **not** load in an Artifact. Every image must be embedded as a `data:` URI. Page ≤ 16 MB, and base64 inflates by ~⅓.
- 🔴 **`photo_origin_url` records the SOURCE PAGE.** `politician_images.url` is the thing that renders. Putting a raw image URL in `photo_origin_url` "works" only because `HAS_RENDERABLE_PHOTO_SQL` accepts anything `LIKE 'http%'`, which makes a dead link count as coverage.
- **Do not touch `STATE_PANORAMAS` or `STATE_PANORAMA_FILES`.** Florida's state banner (`states/FL.jpg`, *Miami Late Afternoon Skyline*) is the adjacency constraint, not a thing to change.
- Migration numbering is irrelevant to this wave: **FL-7 writes no migration.** Headshots go in through `politician_images` via the existing importer.

---

## Measured starting position — do not re-derive

Measured against production 2026-08-30.

### Headshots: the debt is 71, not 72

| Government | People | With renderable photo | Needed |
| --- | --- | --- | --- |
| Miami-Dade County | 19 | **1** | 18 |
| Leon County | 13 | 0 | 13 |
| Palm Beach County | 12 | 0 | 12 |
| Manatee County | 11 | 0 | 11 |
| City of Miami | 6 | 0 | 6 |
| City of Bradenton | 6 | 0 | 6 |
| City of Tallahassee | 5 | 0 | 5 |
| **Total** | **72** | **1** | **71** |

The one covered is **Oliver Gilbert** (`-1212402`), who arrived with an image row from the FL 2026 US House candidate wave. Florida's 159 seated legislators are all covered and are **out of scope**.

⚠ The coverage predicate is `HAS_RENDERABLE_PHOTO_SQL` in `backend/src/lib/photoCoverage.ts`. It lives in exactly one place; do not re-inline it.

### 🔴🔴 The banner lookup is WRONG for Florida, and this is the wave that finds it

`getBuildingImages(representingCity, stateAbbrev)` matches curated city keys by **substring**:

```js
if (!city.includes(key)) continue;   // longest key first, then insertion order
```

Every Florida key we would add collides with a real, separate municipality:

| Key we need | Also matches | In our data? |
| --- | --- | --- |
| `'miami'` | **Miami Beach, Miami Gardens, Miami Lakes, Miami Shores, Miami Springs, North Miami, West Miami** | **No** — none is seated |
| `'bradenton'` | **Bradenton Beach** (a real Manatee city) | **No** |
| `'palm beach'` | West Palm Beach, Palm Beach Gardens, Royal Palm Beach, North Palm Beach | they are in the county, but **Boca Raton, Delray Beach and Jupiter are too, and match nothing** |

Long Beach and San José never hit this because their names have no local siblings. **Florida is the first slice where the lookup itself is wrong.**

### What `representing_city` actually holds

| Government | `district_type` | `offices.representing_city` |
| --- | --- | --- |
| City of Bradenton | `LOCAL` | `Bradenton` |
| City of Miami | `LOCAL` | `Miami` |
| City of Tallahassee | `LOCAL` | `Tallahassee` |
| **All four counties** | `COUNTY` | **NULL** |

So the three cities deliver an exact string to the lookup, and **a county address falls through to the postal-city guess**. A county key has nothing to key on by name — which is why §8.3's two options were both under-specified.

### The county GEOID is available, but not yet plumbed

- `essentialsService.getRepresentativesByAddress` **returns** `county: { geoid, name }` (via `pickCountyFromDistrictRows`).
- `src/routes/essentialsCandidates.ts:151` **serializes** it: `county: result.county ?? null`.
- `src/hooks/usePoliticianData.js` surfaces `locality` (which carries only `county_name`) and **drops `county`**.

▶ So the county tier needs **three small changes**, not a backend change: surface `county` in the hook, pass `county?.geoid` at the call site, and add the map. **Palm Beach County is `12099`.**

### Decisions this plan makes

1. **Only Palm Beach gets a county key.** Miami-Dade does not need one — Miami has a city banner — and adding one would change what Hialeah and Miami Beach see. Out of scope.
2. **Exact match is opt-in, not global.** Existing keys keep substring matching untouched. `'south portland'` vs `'portland'` and the LA county keys rely on it, and auditing 100+ entries is not this wave's job.
3. **Miami's banner cannot be a downtown skyline** (spec §8.1). Florida's state banner already is one.

---

## Task 0: Establish both worktrees and confirm the starting state

**Files:** none — verification only.

- [ ] **Step 1: Confirm the ev-accounts worktree and branch**

```bash
cd /c/ev-accounts-knight && git worktree list && git branch --show-current && git fetch origin && git status --short | grep -vE '^\?\?' | head
```

Expected: `docs/knight-cities-program`, no tracked changes. FL-6 is merged at `41f4c7b6` or later.

- [ ] **Step 2: Confirm the essentials repo and install**

```bash
cd "/c/Transparent Motivations/essentials" && git fetch origin && git status --short | head && npm ci && npx vitest run src/lib/buildingImages.test.js
```

Expected: the 3 existing describe blocks pass. ⚠ **`npm install` passing is not `npm ci` passing** — CI runs `ci`.

- [ ] **Step 3: Re-measure the headshot debt, so the number in the report is today's**

```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -At -F ' | ' -c "
SELECT g.name, count(*) AS people,
       count(*) FILTER (WHERE (img.politician_id IS NOT NULL
                          OR btrim(coalesce(p.photo_custom_url,'')) <> ''
                          OR (btrim(coalesce(p.photo_origin_url,'')) <> '' AND p.photo_origin_url LIKE 'http%'))) AS with_photo
  FROM essentials.governments g
  JOIN essentials.chambers c ON c.government_id=g.id
  JOIN essentials.offices o ON o.chamber_id=c.id
  JOIN essentials.office_current_holder och ON och.office_id=o.id
  JOIN essentials.politicians p ON p.id=och.politician_id
  LEFT JOIN (SELECT DISTINCT politician_id FROM essentials.politician_images) img ON img.politician_id=p.id
 WHERE g.state='FL' AND g.type <> 'State'
 GROUP BY g.name ORDER BY g.name;"
```

Expected: the table above, 72 people / 1 with a photo. **If it differs, stop and reconcile before hunting anything** — a changed count means someone else has been working the same cohort.

⚠ The knight worktree has **no `.env`** (a worktree carries tracked files only). Read `DATABASE_URL` from `/c/EV-Accounts/backend/.env` with the `set -a && . ./.env && set +a` form. 🔴 **A `PreToolUse` hook blocks `export $(...)`** — it degrades to a bare `export`, an environment dump, whenever the substitution is empty.

---

## Task 1: The banner lookup — opt-in exact match, and a county tier

**Files:**
- Modify: `C:\Transparent Motivations\essentials\src\lib\buildingImages.js`
- Modify: `C:\Transparent Motivations\essentials\src\hooks\usePoliticianData.js`
- Modify: `C:\Transparent Motivations\essentials\src\pages\Results.jsx:1280-1283`
- Test: `C:\Transparent Motivations\essentials\src\lib\buildingImages.test.js`

**Interfaces:**
- Produces: `getBuildingImages(representingCity, stateAbbrev, countyGeoId?)` — the third parameter is **optional**, so every existing caller keeps working unchanged. Returns `{ Local, State, Federal }` as before.
- Produces: `CURATED_COUNTY`, a module-private map `{ [countyGeoId: string]: { state: string, src: string } }`.
- Produces: `usePoliticianData()` return value gains `county` — `{ geoid: string, name: string } | null`.
- Consumes: nothing from later tasks. Task 3 fills in the four `src` URLs.

⚠ **Write this task with placeholder URLs that point at nothing yet.** The keys are wired in Task 1 and the files land in Task 3. A key whose object does not exist yet renders as a broken image, so **Task 1 must not be deployed on its own** — Tasks 1 and 3 ship together. This is called out again in Task 3.

- [ ] **Step 1: Write the failing tests**

Append to `src/lib/buildingImages.test.js`:

```js
describe('getBuildingImages — exact match is opt-in (FL-7)', () => {
  it('an exact-match key does NOT match a longer sibling city', () => {
    // 'miami' is exact, so Miami Beach must fall through to no local banner.
    expect(getBuildingImages('Miami Beach', 'FL').Local).toBeNull();
    expect(getBuildingImages('Miami Gardens', 'FL').Local).toBeNull();
    expect(getBuildingImages('North Miami', 'FL').Local).toBeNull();
  });

  it('an exact-match key still matches its own city, case-insensitively', () => {
    expect(getBuildingImages('Miami', 'FL').Local).toContain('/cities/');
    expect(getBuildingImages('miami', 'FL').Local).toContain('/cities/');
  });

  it('Bradenton is exact, so Bradenton Beach gets no city banner', () => {
    expect(getBuildingImages('Bradenton', 'FL').Local).toContain('/cities/');
    expect(getBuildingImages('Bradenton Beach', 'FL').Local).toBeNull();
  });

  it('existing substring keys are UNCHANGED', () => {
    // Bloomington has no exact flag; substring behaviour must survive untouched.
    expect(getBuildingImages('Bloomington', 'IN').Local).toBe(BLOOMINGTON_URL);
    expect(getBuildingImages('City of Bloomington', 'IN').Local).toBe(BLOOMINGTON_URL);
  });

  it('state scoping still applies to an exact key', () => {
    // A Miami in another state must not take Florida's banner.
    expect(getBuildingImages('Miami', 'OK').Local).toBeNull();
  });
});

describe('getBuildingImages — county tier (FL-7)', () => {
  it('returns the county banner when no city key matches', () => {
    expect(getBuildingImages('West Palm Beach', 'FL', '12099').Local).toContain('/counties/');
    expect(getBuildingImages('Boca Raton', 'FL', '12099').Local).toContain('/counties/');
    expect(getBuildingImages('Jupiter', 'FL', '12099').Local).toContain('/counties/');
  });

  it('a city banner WINS over the county banner', () => {
    // Miami is in Miami-Dade (12086), which has no county key; but the principle
    // is asserted with Palm Beach's geoid to prove precedence, not absence.
    expect(getBuildingImages('Miami', 'FL', '12099').Local).toContain('/cities/');
  });

  it('an unknown county geoid returns null, not a throw', () => {
    expect(getBuildingImages('Nowhere', 'FL', '99999').Local).toBeNull();
    expect(getBuildingImages('Nowhere', 'FL', null).Local).toBeNull();
    expect(getBuildingImages('Nowhere', 'FL').Local).toBeNull();
  });

  it('the county key is state-scoped', () => {
    expect(getBuildingImages('Anywhere', 'GA', '12099').Local).toBeNull();
  });
});
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd "/c/Transparent Motivations/essentials" && npx vitest run src/lib/buildingImages.test.js
```

Expected: FAIL. The exact-match tests fail because `'Miami Beach'.includes('miami')` is true today; the county tests fail because `CURATED_COUNTY` does not exist.

- [ ] **Step 3: Add the four Florida entries and the county map**

In `src/lib/buildingImages.js`, add to `CURATED_LOCAL` (keep the file's existing one-entry-per-line style, and put them with the other state groups):

```js
  // Florida — Knight program wave FL-7 (2026-08-30, operator-certified).
  // 🔴 match:'exact' is LOAD-BEARING. Substring matching would hand Miami's banner to
  // Miami Beach, Miami Gardens, Miami Lakes, Miami Shores, Miami Springs, North Miami and
  // West Miami, and Bradenton's to Bradenton Beach — all separate cities we do not seat.
  miami: { state: 'FL', match: 'exact', src: `${LOCAL_BASE}miami.jpg` },
  bradenton: { state: 'FL', match: 'exact', src: `${LOCAL_BASE}bradenton.jpg` },
  tallahassee: { state: 'FL', match: 'exact', src: `${LOCAL_BASE}tallahassee.jpg` },
```

If `LOCAL_BASE` does not already exist in the file, use the full literal URL in the same form as the neighbouring entries rather than introducing a constant — match the file's existing style.

Then, immediately after `CURATED_LOCAL`:

```js
/**
 * Curated COUNTY banners, keyed by county GEOID.
 *
 * 🔴 WHY A SEPARATE MAP, AND WHY GEOID. CURATED_LOCAL is keyed by the city label and
 * matched by substring, and a county cannot be expressed that way. A 'palm beach' key
 * would match West Palm Beach, Palm Beach Gardens and Royal Palm Beach — and match
 * NOTHING for Boca Raton, Delray Beach or Jupiter, which are equally in the county.
 * The GEOID is exact, complete and already on the address response.
 *
 * Only jurisdictions with NO city half belong here. Miami-Dade deliberately has no entry:
 * Miami has a city banner, and adding one would change what Hialeah and Miami Beach see.
 */
const CURATED_COUNTY = {
  // Palm Beach County, FL. Spec §8.3, decided 2026-08-28 (Cantrell): its own county key
  // rather than the Florida state banner, which is a Miami skyline and would collide with
  // Miami's own banner in the same slice.
  '12099': { state: 'FL', src: `${LOCAL_BASE.replace('/cities/', '/counties/')}palm-beach-fl.jpg` },
};
```

⚠ If `LOCAL_BASE` does not exist, write the literal:
`https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/counties/palm-beach-fl.jpg`

- [ ] **Step 4: Rewrite the match loop and add the county fallback**

Replace the city-matching loop inside `getBuildingImages` with:

```js
  let localImage = null;
  // Match the LONGEST key first so a more specific city name wins over one that
  // is a substring of it (e.g. "south portland" must beat "portland"). Otherwise
  // resolution order follows key length descending; ties keep insertion order.
  const curatedEntries = Object.entries(CURATED_LOCAL).sort(
    (a, b) => b[0].length - a[0].length
  );
  for (const [key, entry] of curatedEntries) {
    // An entry is either a single {state, src} or an ARRAY of state-scoped
    // variants for a city name that recurs across states (e.g. Fairview OR vs
    // Fairview TX). Pick the variant whose state matches the caller's; a
    // missing/unknown caller state or entry state is treated as match-allowed.
    //
    // 🔴 THE KEY TEST IS PER-VARIANT, because match:'exact' lives on the variant.
    // Entries without the flag keep the historical substring behaviour exactly.
    const variants = Array.isArray(entry) ? entry : [entry];
    const hit = variants.find((v) => {
      if (abbrev && v.state && v.state !== abbrev) return false;
      return v.match === 'exact' ? city === key : city.includes(key);
    });
    if (hit) {
      localImage = hit.src;
      break;
    }
  }

  // County tier: only when no city key matched. A city banner always wins — a Miami
  // address gets Miami, not Miami-Dade. Counties with a seated city half have no entry.
  if (!localImage && countyGeoId) {
    const countyEntry = CURATED_COUNTY[String(countyGeoId)];
    if (countyEntry && (!abbrev || !countyEntry.state || countyEntry.state === abbrev)) {
      localImage = countyEntry.src;
    }
  }
```

And change the signature and its JSDoc:

```js
/**
 * Get building images for each tier.
 * @param {string} representingCity - City name from politician data
 * @param {string} stateAbbrev - Two-letter state abbreviation (e.g., "IN", "CA")
 * @param {string} [countyGeoId] - 5-digit county GEOID from the address response
 *   (`county.geoid`). Optional: callers that omit it get city-only resolution, which
 *   is the pre-FL-7 behaviour.
 * @returns {{ Local: string, State: string, Federal: string }}
 */
export function getBuildingImages(representingCity, stateAbbrev, countyGeoId) {
```

- [ ] **Step 5: Run the tests to verify they pass**

```bash
cd "/c/Transparent Motivations/essentials" && npx vitest run src/lib/buildingImages.test.js
```

Expected: PASS, all describe blocks including the three that existed before.

- [ ] **Step 6: Prove the exact flag is what makes the sibling test pass**

Temporarily delete `match: 'exact'` from the `miami` entry and re-run. Expected: **the Miami Beach / Miami Gardens / North Miami assertions FAIL**, and nothing else does. Restore the flag and re-run to green.

🔴 **Do not skip this.** A test that passes for the wrong reason is the failure mode this step exists to catch — `toBeNull()` also passes if the key is simply missing.

- [ ] **Step 7: Surface the county GEOID in the hook**

In `src/hooks/usePoliticianData.js`, beside the existing `locality` state:

```js
  // FL-7: the county GEOID drives the county banner tier. The API has always returned
  // `county: { geoid, name }` (routes/essentialsCandidates.ts) — only `locality` was
  // surfaced, and it carries the county NAME, which cannot key a banner unambiguously.
  const [county, setCounty] = useState(null);
```

beside `setLocality(result.locality || null);`:

```js
        setCounty(result.county || null);
```

and extend the return:

```js
  return { data, phase, error, dataStatus, formattedAddress, tribalLand, locality, county };
```

Also update the `@returns` JSDoc at the top of the file to list `county` with its shape.

- [ ] **Step 8: Pass it at the call site**

In `src/pages/Results.jsx`, take `county` from the hook alongside `locality`, then change the memo (currently at ~line 1280):

```js
  const buildingImageMap = useMemo(
    () => getBuildingImages(representingCity, userState, county?.geoid ?? zipInfo?.county?.geoid),
    [representingCity, userState, county, zipInfo]
  );
```

⚠ `zipInfo?.county?.geoid` is the ZIP path, which already carried the county. Both paths now feed the same tier.

- [ ] **Step 9: Full check**

```bash
cd "/c/Transparent Motivations/essentials" && npx vitest run && npm run lint
```

Expected: all tests pass, lint clean. ⚠ Lint is gated in CI (`877af341`).

- [ ] **Step 10: Commit**

```bash
cd "/c/Transparent Motivations/essentials" && git add src/lib/buildingImages.js src/lib/buildingImages.test.js src/hooks/usePoliticianData.js src/pages/Results.jsx && git commit -F- <<'MSG'
feat(banners): opt-in exact city match, and a county tier keyed by GEOID

Florida is the first slice where the banner lookup itself is wrong. CURATED_LOCAL
matches by substring, so a 'miami' key hands Miami's banner to Miami Beach, Miami
Gardens, Miami Lakes, Miami Shores, Miami Springs, North Miami and West Miami —
seven separate cities we do not seat — and 'bradenton' takes Bradenton Beach.

match:'exact' is opt-in per variant. Every existing key keeps substring behaviour
untouched, because 'south portland' vs 'portland' and the LA county keys rely on
it and auditing them is not this wave's job.

The county tier exists because a county cannot be keyed by city label at all. A
'palm beach' key would match West Palm Beach and Royal Palm Beach while matching
NOTHING for Boca Raton or Jupiter, which are equally in the county. The GEOID is
exact and complete, and the API already returned it — only the hook dropped it.

A city banner always wins over the county. Miami-Dade has no county entry: Miami
has a city banner, and adding one would change what Hialeah and Miami Beach see.

The four src URLs point at objects that do not exist yet. DO NOT DEPLOY THIS
ALONE — the files land with the certified banners.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

---

## Task 2: Source and certify four banners — the approval gate

**Files:**
- Create: `C:\ev-accounts-knight\backend\data\knight-fl-banners\SOURCES.md`
- Create: a certification page, published as an Artifact

**Interfaces:**
- Consumes: nothing from Task 1 (the lookup does not need the images to exist).
- Produces: four approved image files on disk plus `SOURCES.md` recording, per banner: source URL, photographer/attribution, licence, and the composition noun phrase used for the adjacency test.

- [ ] **Step 1: Write down the adjacency constraint before looking at any photograph**

Florida's **state** banner is `states/FL.jpg` — *"Miami Late Afternoon Skyline"*, Euthman, CC BY 4.0 (the credit is in `buildingImages.js` around line 816).

Per spec §8.1, a city banner must not repeat the **composition** of its state banner or of a sibling city in the same state group. **Compare compositions, not subject nouns.** Four banners must therefore differ from the state banner and from each other:

| Key | Constraint |
| --- | --- |
| `miami` | 🔴 **CANNOT be a downtown skyline in any framing.** Its own skyline IS the state banner. Needs a different frame — street level, water level, a neighbourhood, a landmark at close range. |
| `tallahassee` | Must differ from Miami's chosen composition and from Bradenton's. |
| `bradenton` | Must differ from Miami's and Tallahassee's. |
| `12099` Palm Beach County | Must differ from the other three. It is a **county**, so a composition that reads as one specific downtown is a poor fit. |

Record the intended composition of each as a short noun phrase *before* sourcing, so the adjacency test is made against a stated intent rather than rationalised afterwards.

- [ ] **Step 2: Source candidates, licence first**

Acceptable: Wikimedia Commons with an explicit CC or public-domain licence; a government/official source that grants reuse; public domain. **A photographer's all-rights-reserved copyright is a refusal**, exactly as for headshots.

For each candidate record in `SOURCES.md`: source page URL, direct image URL, author, licence, pixel dimensions, and the one-phrase composition.

🔴 **The 6:1 desktop band is the aspect that matters**, so a candidate must have enough horizontal information to crop to roughly 6:1 without losing its subject. A tall portrait-orientation photograph is not a candidate however good it is.

- [ ] **Step 3: Build the certification page**

Load the `artifact-design` skill first (spec §9 requires it). The page must show, for each of the four keys:

- The **real 6:1 band at real CSS width**, not a thumbnail and not a described mock-up.
- The **rejected options** beside the proposed one.
- The **live baseline** — for the three cities that is the current gradient fallback (they have no banner today); for the state-adjacency test, Florida's `states/FL.jpg` shown at the same band so the composition comparison is visible rather than asserted.
- An explicit **neutral ground in both themes**, so the viewer's theme cannot tint the judgement.

🔴 **Every image must be embedded as a `data:` URI.** The Artifact CSP blocks the Supabase CDN and every other external host; a hotlinked `<img src>` renders as a broken box and the operator approves nothing but alt text. Keep the page ≤ 16 MB.

- [ ] **Step 4: Publish and hand over the link**

Publish with the Artifact tool. Use **one stable file path** for the slice so redeploys keep the same URL.

- [ ] **Step 5: STOP. Wait for approval.**

🔴 **This is a hard gate.** Do not upload anything, do not edit `buildingImages.js` further, and do not proceed to Task 3 until the operator has approved specific banners by name. If any is rejected, source replacements and republish the same path.

---

## Task 3: Upload the approved banners and ship the keys

**Files:**
- Modify: `C:\Transparent Motivations\essentials\src\lib\buildingImages.js` (attribution comments + final filenames)
- Create: four objects in Supabase Storage under `politician_photos/`

**Interfaces:**
- Consumes: Task 1's `CURATED_LOCAL` entries and `CURATED_COUNTY`; Task 2's approved files.
- Produces: four live URLs. After this task `getBuildingImages` resolves to real images.

- [ ] **Step 1: Produce the final crops**

Crop each approved image to the 6:1 band as certified. Keep the largest sensible resolution — these are hero banners, not thumbnails.

- [ ] **Step 2: Upload to Storage under NEW paths**

```
politician_photos/cities/miami.jpg
politician_photos/cities/tallahassee.jpg
politician_photos/cities/bradenton.jpg
politician_photos/counties/palm-beach-fl.jpg
```

🔴 **These must be new object paths, never an overwrite.** Overwriting does not reliably purge the Supabase CDN — measured 2026-08-18 on `states/TX.jpg`, where the old image still served seconds after upload without a cache-buster. If a banner is ever *replaced* later, version the filename (`miami-v2.jpg`) rather than overwriting and hoping.

⚠ `counties/` is a **new prefix** in this bucket. Confirm the upload succeeded by fetching the public URL and checking the **magic number**, not `r.ok` — a WAF rejection can arrive as HTTP 200.

- [ ] **Step 3: Verify each URL actually renders**

```bash
for u in miami tallahassee bradenton; do
  echo "== $u"; curl -s -o /tmp/$u.jpg -w "%{http_code} %{size_download}\n" \
    "https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cities/$u.jpg"
  head -c2 /tmp/$u.jpg | xxd | head -1
done
echo "== palm-beach-fl"; curl -s -o /tmp/pb.jpg -w "%{http_code} %{size_download}\n" \
  "https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/counties/palm-beach-fl.jpg"
head -c2 /tmp/pb.jpg | xxd | head -1
```

Expected: `200` with a non-trivial byte count, and the first two bytes `ffd8` (JPEG magic number) for all four.

- [ ] **Step 4: Record attribution in the file**

Add credit lines beside the existing block (the file already carries e.g. `//   FL - Miami Late Afternoon Skyline | Euthman | CC BY 4.0`), one per new banner, in the same format: subject, author, licence.

- [ ] **Step 5: Re-run the tests and lint**

```bash
cd "/c/Transparent Motivations/essentials" && npx vitest run && npm run lint
```

Expected: green.

- [ ] **Step 6: Commit and deploy**

```bash
cd "/c/Transparent Motivations/essentials" && git add src/lib/buildingImages.js && git commit -m "feat(banners): four Florida banners — Miami, Tallahassee, Bradenton, Palm Beach County

Operator-certified in the 6:1 desktop band. Miami is deliberately NOT a downtown
skyline: the Florida state banner is 'Miami Late Afternoon Skyline', and the
adjacency rule forbids repeating a composition.

Palm Beach County is the first COUNTY banner in the program (spec 8.3), keyed by
GEOID 12099 because it has no city half to key on.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

Then deploy through Netlify as the essentials repo normally does, and **confirm on the live site** that a Miami address, a Bradenton address, a Tallahassee address and a Boca Raton address each render the intended banner — and that a **Miami Beach** address renders the gradient, not Miami's banner.

🔴 **That Miami Beach check is the one that proves Task 1 worked in production**, not just in vitest.

---

## Task 4: Hunt 71 headshots and publish contact sheets — the second approval gate

**Files:**
- Create: `C:\EV-Accounts\backend\.tmp-all-candidates.json`
- Create: `C:\EV-Accounts\.tmp-cos-contactsheet.html` (produced by the renderer)
- Create: `C:\ev-accounts-knight\backend\data\knight-fl-headshots\LEDGER.md`

**Interfaces:**
- Consumes: nothing from earlier tasks. Independent of the banner half.
- Produces: `.tmp-all-candidates.json` — a JSON **array**, one object per subject, in exactly the shape `render-headshot-contact-sheet.py` and `import-headshot-candidates.py` both read:

```json
{
  "politician_id": "<uuid of the essentials.politicians row>",
  "name": "Damian Pardo",
  "office": "Commissioner, District 2",
  "cohort": "City of Miami",
  "url": "https://.../pardo.jpg",
  "page": "https://www.miami.gov/...",
  "license": "Official city portrait — public record",
  "positional": false
}
```

`url: null` means no candidate found; the renderer lists those under "no candidate found". `positional: true` when the **filename encodes a SEAT rather than a PERSON** (`D1.jpg`, `1.png`, a bare UUID) — those get a "verify face" flag, because that is exactly where off-by-one errors hide.

- [ ] **Step 1: Pull the roster with UUIDs**

```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -At -F '|' -c "
SELECT p.id, p.full_name, o.title, g.name
  FROM essentials.governments g
  JOIN essentials.chambers c ON c.government_id=g.id
  JOIN essentials.offices o ON o.chamber_id=c.id
  JOIN essentials.office_current_holder och ON och.office_id=o.id
  JOIN essentials.politicians p ON p.id=och.politician_id
  LEFT JOIN (SELECT DISTINCT politician_id FROM essentials.politician_images) img ON img.politician_id=p.id
 WHERE g.state='FL' AND g.type <> 'State'
   AND img.politician_id IS NULL
   AND btrim(coalesce(p.photo_custom_url,''))=''
   AND NOT (btrim(coalesce(p.photo_origin_url,'')) <> '' AND p.photo_origin_url LIKE 'http%')
 ORDER BY g.name, o.title;" > /tmp/fl-headshot-roster.txt && wc -l /tmp/fl-headshot-roster.txt
```

Expected: **71** rows.

- [ ] **Step 2: Work the source ladder, one cohort at a time**

Per spec §7, in order:

1. **The official city or county page.** Every one of these seven bodies publishes a roster with portraits. Start here for all 71.
2. **`<county>dems.org/elected-officials`** — this rescued 7 dead rows in an earlier wave. Applies to Miami-Dade, Palm Beach, Leon, Manatee.
3. **Local press.**
4. **Ballotpedia original** — 🔴 **drop `thumbs/200/300/` from the api4 path**; a 200×300 thumbnail becomes the 5533×8300 original.

🔴 **Ballotpedia homonyms hide behind a bare title. Test for state AND county** — this wave has four repeated surnames inside its own roster (Higgins, Regalado, Garcia, Fernandez) and two two-word surnames (Cohen Higgins, Levine Cava). A name match alone is not identification here.

🔴 **A FACE-FIRST scan beats reading filenames.** Look at the picture, then check the name.

Work **one cohort at a time** and record every attempt in `LEDGER.md` — URL tried, outcome, licence verdict — so a later wave does not re-walk dead ends.

- [ ] **Step 3: Write the candidates JSON**

Write all 71 entries, including the ones with `url: null`. **Do not omit the misses** — the contact sheet's "no candidate found" section is how the operator sees the real yield.

- [ ] **Step 4: Render the contact sheets**

```bash
cd /c/EV-Accounts/backend && py scripts/render-headshot-contact-sheet.py
```

Output: `../.tmp-cos-contactsheet.html`, self-contained, every frame the **actual production render** (4:5, 600×750, the same crop the importer applies).

Spec §7.2: one sheet per **body**, capped at 40 faces. All seven bodies are under 40, so this is one section per cohort. Set `cohort` to the government name so the sections come out right.

- [ ] **Step 5: Publish as an Artifact and hand over the link**

One page, all seven cohorts. 🔴 **Batch contact sheet, never one dialog per person** — do not ask per cohort, the rule is standing.

- [ ] **Step 6: STOP. Wait for approval.**

Record which names the operator rejects. Those become `--exclude` arguments in Task 5.

---

## Task 5: Import the approved headshots

**Files:**
- Modify: `essentials.politician_images` rows in production (through the importer, not by hand)
- Modify: `C:\ev-accounts-knight\backend\data\knight-fl-headshots\LEDGER.md`

**Interfaces:**
- Consumes: Task 4's `.tmp-all-candidates.json` and the operator's rejection list.
- Produces: image rows. No migration; no schema change.

- [ ] **Step 1: Dry run**

```bash
cd /c/EV-Accounts/backend && py scripts/import-headshot-candidates.py --dry-run
```

Reads the same candidates JSON, renders and reports, **writes nothing**. Check the reported count against the number of approved faces.

- [ ] **Step 2: Import, excluding the rejections**

```bash
cd /c/EV-Accounts/backend && py scripts/import-headshot-candidates.py --exclude "Name One" "Name Two"
```

What the importer already gets right, and must not be re-implemented:

- **Alpha is flattened onto WHITE** before RGB conversion. `convert("RGB")` alone turns transparent pixels **black**, which is how a circular-masked PNG portrait ships as a circle on a black square. Three El Paso County officials shipped exactly that before it was fixed.
- The image check is the **magic number**, never the extension and never `r.ok`.
- **`photo_origin_url` gets the SOURCE PAGE**, not the raw image URL.
- Anyone who already has an image row is **skipped**, so a re-run is a no-op — which is why Oliver Gilbert needs no special handling.

⚠ `--max-upscale` defaults to 1.0. 🔴 **The upscale gate measures the FACE crop, not the frame** — a large image with a small face still fails the bar that matters.

- [ ] **Step 3: Verify coverage, and report the yield honestly**

```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -At -F ' | ' -c "
SELECT g.name, count(*) AS people,
       count(*) FILTER (WHERE (img.politician_id IS NOT NULL
                          OR btrim(coalesce(p.photo_custom_url,'')) <> ''
                          OR (btrim(coalesce(p.photo_origin_url,'')) <> '' AND p.photo_origin_url LIKE 'http%'))) AS with_photo
  FROM essentials.governments g
  JOIN essentials.chambers c ON c.government_id=g.id
  JOIN essentials.offices o ON o.chamber_id=c.id
  JOIN essentials.office_current_holder och ON och.office_id=o.id
  JOIN essentials.politicians p ON p.id=och.politician_id
  LEFT JOIN (SELECT DISTINCT politician_id FROM essentials.politician_images) img ON img.politician_id=p.id
 WHERE g.state='FL' AND g.type <> 'State'
 GROUP BY g.name ORDER BY g.name;"
```

🔴 **Report the MEASURED YIELD IN USABLE HEADSHOTS**, per body, never a count of files touched and never a percentage of "attempted". If a cohort came out at 6 of 13, say 6 of 13 and say which sources were dead.

- [ ] **Step 4: Check for dead provenance links**

```bash
cd /c/EV-Accounts/backend && node scripts/verify-photo-origin-urls.mjs 2>&1 | tail -20
```

A dead `photo_origin_url` counts as coverage under `HAS_RENDERABLE_PHOTO_SQL`, which is exactly the false-positive this script exists to catch.

- [ ] **Step 5: Commit the ledger**

```bash
cd /c/ev-accounts-knight && git add backend/data/knight-fl-headshots/LEDGER.md && git commit -F- -- backend/data/knight-fl-headshots/LEDGER.md <<'MSG'
docs(knight-fl): headshot ledger for the Florida cohorts

Every URL tried, per person, with the outcome and the licence verdict — so the
next wave does not re-walk the dead ends. Yield is recorded per body in usable
headshots, not in files touched.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

⚠ 🔴 **Commit with an explicit pathspec.** Parallel sessions sweep each other's staged files, in both directions; staging explicit paths is not enough.

---

## Task 6: Update the ledger and close Florida's stage 5

**Files:**
- Modify: `.planning/knight-foundation/fl.md`
- Modify: `.planning/knight-foundation/PROGRAM.md`
- Modify: this plan — add a "Deviations found during execution" section per task, as FL-3 through FL-6 did

- [ ] **Step 1: `fl.md`**

- Wave table: FL-7 `✅ applied — <date>`, and the slice status line updated from "only stage 5 remains" to closed if the yield justifies it.
- Add `## FL-7 — Florida assets (applied …)` recording: the measured yield per body; the four banners with their compositions and licences; and 🔴 **the substring defect and its fix**, which is the transferable finding — every future slice with a `<Name> Beach` or `North <Name>` sibling hits it.
- Record that **Palm Beach County is the program's first county banner**, keyed by GEOID, and why a name key could not work.

- [ ] **Step 2: `PROGRAM.md`**

- Slice 1 row: stage 5 to `✅` if closed, or leave `WIP` with the measured yield stated.
- "Banners present": add the four; restate the count (was `long beach` and `san jose` only, 24 missing).
- Local and county seats table: fill in the **With headshot** column for the seven Florida rows — it currently reads 0 for all of them.
- Session log: one row, ending with the next action.

🔴 **Do not write "72 people" anywhere.** The debt was **71**; Oliver Gilbert already had a photo.

- [ ] **Step 3: Commit and push, checking both directions first**

```bash
cd /c/ev-accounts-knight && git fetch origin && git rev-list --left-right --count origin/docs/knight-cities-program...HEAD && git push origin docs/knight-cities-program
```

⚠ Never `--force` past a non-fast-forward.

---

## Plan self-review

**Spec coverage.** §7 headshots (two tiers, source ladder, standing rules, review unit) → Tasks 4 and 5; only the local/county tier applies, since Florida's 159 legislators are already covered. §7.1's six standing rules appear in Global Constraints and again at the step that can violate each. §7.2's "one sheet per body, capped at 40" → Task 4 Step 4, and all seven bodies are under the cap. §8 banners → Tasks 2 and 3. §8.1's adjacency rule and Miami's hard conflict → Task 2 Step 1, stated before any sourcing so the test is made against intent. §8.2 certification in the 6:1 band with rejected options and the live baseline → Task 2 Step 3. §8.3's open decision → resolved by Task 1's `CURATED_COUNTY`, with the reason recorded in the code comment rather than only in the ledger. §9's Artifact constraints (CSP, 16 MB, `data:` URIs, stable path, `artifact-design` first) → Task 2 Step 3 and Task 4 Step 5.

**Placeholder scan.** No "TBD" or "add appropriate error handling". Every code step carries the actual code. Task 2 deliberately does not name the four photographs — choosing them IS the task, and the constraint each must satisfy is stated instead. Task 5's `--exclude "Name One" "Name Two"` is a literal argument shape whose values come from the Task 4 gate, which is the only place they can come from.

**Type consistency.** `getBuildingImages(representingCity, stateAbbrev, countyGeoId)` has the same three-parameter signature in Task 1 Steps 4, 8 and the tests in Step 1. `CURATED_COUNTY` is keyed by string GEOID in the map, the lookup (`String(countyGeoId)`) and the tests. The candidates JSON keys — `politician_id`, `name`, `office`, `cohort`, `url`, `page`, `license`, `positional` — match the renderer's documented input and the importer's reader in Tasks 4 and 5. `usePoliticianData` returns `county` in Step 7 and is consumed as `county?.geoid` in Step 8.

**Gaps found and closed while writing.** Four. (1) The approved design said "keyed by county GEOID", but the GEOID was **not** surfaced to the frontend — `usePoliticianData` exposes `locality`, which carries only `county_name`. The API always returned `county`; the hook dropped it. That is now Task 1 Step 7, three lines, rather than a discovery mid-execution. (2) The exact-match flag cannot be tested at the entry level, because a `CURATED_LOCAL` value may be an **array** of state-scoped variants — so the key test had to move **inside** the variant `find`, which is a different loop shape from today's. (3) Task 1 wires keys to objects that do not exist until Task 3, so deploying Task 1 alone would ship four broken images; both tasks now say so. (4) The headshot debt is **71, not 72** — Oliver Gilbert arrived with a photo from the US House wave — and the importer skips anyone who already has an image row, so he needs no special case but the reported number must not be 72.
