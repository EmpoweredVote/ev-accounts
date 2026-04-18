# Phase 120: Bio + Photo Authoring Methodology

**Purpose:** Establish a repeatable method for authoring politician/candidate bios and sourcing headshots. Reusable by Phase 124 (45-candidate app-wide batch) per Phase 124 success criterion BIO-02.

**Scope of origin:** Authored during Phase 120 (contested Monroe County May 5 races, ~5-10 candidates). Designed for reuse at larger batch sizes without modification.

---

## Bio Sourcing Rules

- **Single named source per bio** (D-14). Extract facts from ONE URL, lightly compress into one sentence. Never synthesize across multiple sources — no LLM-composed bios that merge facts from campaign site + news article + Wikipedia.
- **Source URL must be recorded** in the phase's REVIEW-DATA.md alongside the bio text. Every bio row has a matching source citation.
- **Source priority (highest to lowest):**
  1. Official government pages (e.g., `*.gov` biographical page, official candidate filing)
  2. Campaign websites (candidate's own about/bio page)
  3. News articles (local paper, reputable regional outlet, candidate profile pieces)
  4. Social media profiles (LinkedIn, official X/Bluesky bio) — use only when nothing better exists
- If no source meets any tier, use the fallback pattern (see Fallback section).

## Tone and Voice

- **Neutral factual tone** (D-11). Dry, objective facts only: role, background, reason for running.
- **No editorial voice**, no superlatives, no endorsement language, no comparative framing ("unlike the incumbent," "the best choice for").
- **Not marketing copy** — this is reference information for voters, not persuasion.
- **Example (good):** "Monroe County educator and longtime community volunteer seeking County Council District 3 seat."
- **Example (bad):** "Dedicated public servant with a proven track record running to shake up county government." (editorializing, vague, persuasive)

## Length

- **Target: 120-180 characters, one sentence** (D-12).
- **Hard maximum: 180 characters.** The import script validates length before writing; over-length bios are rejected.
- One sentence only — no compound bios, no multi-paragraph narratives. If the source has more detail than fits, compress; do not expand.
- Character count includes spaces and punctuation.

## Antipartisan Constraint

- **Party affiliation is omitted from bios** (D-13). Consistent with the platform's antipartisan principle (see [feedback_antipartisan.md]).
- **Exception:** Party may appear ONLY if it is the candidate's literal professional or service role. Examples:
  - OK: "served as Monroe County GOP chair 2018-2022"
  - OK: "president of Monroe County Democrats"
  - NOT OK: "Republican candidate for County Council"
  - NOT OK: "Democrat running to replace retiring incumbent"
- **Default stance:** when in doubt, omit party. The `race_candidates.primary_party` field displays party separately in the UI — bios should not duplicate it.

## Fallback

- **When insufficient public information exists** about a candidate (no findable campaign site, no news coverage, no government bio): use the office-title-only fallback (D-15).
- **Format:** `"Candidate for [office title]."`
- **Examples:**
  - "Candidate for Monroe County Council District 3."
  - "Candidate for United States Representative, Ninth District."
- **Do not invent facts to pad.** A short fallback is better than a fabricated bio. Missing info is itself a signal to voters.
- The fallback sentence still fits within the 180-char limit for every conceivable race title.

## Photo Source Priority

- **Order (D-08), highest to lowest:**
  1. Official government photos (chamber.gov headshot, county employee directory)
  2. Campaign website (candidate's own "About" page photo)
  3. Social media profiles (LinkedIn headshot, official X avatar)
  4. News article photos (local paper, candidate profile feature)
- **Always download and re-upload** to Supabase Storage CDN (D-09). **Never hotlink.** Source URLs break before primary day; re-hosted photos are stable.
- **If no photo is findable:** proceed without (D-10). The ev-ui missing-photo fallback (initials avatar) is acceptable — do not block bio authoring on photo sourcing.

## Photo Upload Checklist

For each photo that will be written to the DB:

1. **Download** image from the source URL to a local temp path.
2. **Upload** to Supabase Storage bucket `politician_photos` at path `<batch_prefix>/<slug>.<ext>` (example: `monroe_2026/jane-smith.jpg`).
3. **Always set `contentType`** on the upload call: `'image/jpeg'` or `'image/png'`. Never omit — Supabase defaults to `text/plain`, which causes browsers to refuse to render the image in an `<img>` tag (RESEARCH.md Pitfall 7).
4. **INSERT** into `essentials.politician_images` with `type='default'` and the public CDN URL. This is the primary render path in `PoliticianProfile.jsx`.
5. **UPDATE** `essentials.politicians.photo_custom_url` with the same CDN URL. This is the fallback render path.
6. **Both writes are required.** A `photo_custom_url`-only update will not render on profiles whose `politician_images` row is missing (RESEARCH.md Pitfall 2).
7. **Verify the CDN URL** resolves with a 200 + correct `Content-Type` header before considering the upload complete.

## Review Process

- All bios and photo URLs are compiled into a per-phase **REVIEW-DATA.md** table (D-06).
- **Table columns:** `name | bio text | bio source URL | photo source URL | candidate_id | notes`.
- **User reviews and approves/edits** before the import script runs (D-05). This is a mandatory gate — no bios or photos are written to the DB without human sign-off on the REVIEW-DATA.md.
- **Source citations** live in REVIEW-DATA.md (no `bio_source_url` DB column needed at this batch size). If Phase 124 or later decides to store citations in the DB for traceability, a migration can be added then — do not preemptively add one for Phase 120.
- **After import:** append a verification table to the REVIEW-DATA.md showing which candidates were written vs. skipped vs. errored.

## Antipatterns to Avoid

- Hotlinking photos from campaign/social sites — always re-host to Supabase Storage.
- `photo_custom_url`-only updates without a `politician_images` row — photo will not render.
- LLM-synthesized multi-source bios — single source, single sentence, extracted and compressed.
- Party framing ("Republican candidate," "Democrat running for...") — omit unless it's a literal professional role.
- Rendering bio_text via `dangerouslySetInnerHTML` — use React text-node render to get default HTML escaping (XSS mitigation from the threat model).
- Skipping the user review gate — D-05/D-06 require human approval on REVIEW-DATA.md before import.

## Reusability Checklist (for Phase 124)

When reusing this methodology at the 45-candidate batch scale:

- [ ] Create a new batch prefix for the Storage path (e.g., `phase124_2026/`)
- [ ] Reuse the REVIEW-DATA.md format — same columns, same approval gate
- [ ] Reuse the import script pattern from Plan 03 (transaction-per-candidate, dual photo write)
- [ ] Re-run the scoping query adapted for the relevant races/dates
- [ ] Consider adding a `bio_source_url` column migration if DB-stored citations become valuable at 45-candidate scale (not required)
- [ ] Keep the 180-char hard limit and single-source rule — these do not scale-degrade
- [ ] Keep the antipartisan constraint — it is invariant across all phases

---

*Authored:* 2026-04-16
*Phase:* 120-contested-race-bio-photo-authoring (Plan 01)
*Reused by:* Phase 124 (planned) — 45-candidate app-wide batch
