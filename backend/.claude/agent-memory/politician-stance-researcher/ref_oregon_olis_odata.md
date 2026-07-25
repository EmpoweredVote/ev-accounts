---
name: ref-oregon-olis-odata
description: Oregon OLIS OData API gives individual roll-call votes + sponsorships for any legislator with no rate limit; plus the withdrawal-motion trap that makes Nay votes misleading
metadata:
  type: reference
---

**`https://api.oregonlegislature.gov/odata/ODataService.svc/` is the single best source for any Oregon
legislator.** Public, unauthenticated, no rate limit, clean JSON with `&$format=json`. Use it instead
of scraping the JS-heavy OLIS web UI or extracting PDFs.

**Why:** it returns the legislator's *individual* vote on every measure, which is the evidence tier the
stance work needs. Discovered during the Kropf HD-54 remediation (see [[stance-jason-kropf-or-hd54]]),
where it produced 2,927 individually-confirmed votes in a few minutes.

**How to apply:**

| Collection | Filter | Yield |
|---|---|---|
| `Legislators` | `$filter=LastName eq 'X'` | `LegislatorCode` (e.g. `Rep Kropf`) + every session they served. **Cheapest seating-date guard there is** — use it before citing any bill. |
| `MeasureVotes` | `$filter=VoteName eq 'Rep X'` | Individual votes: `Vote`, `ActionText`, `ActionDate`. Page `$top=1000&$skip=N`. |
| `MeasureSponsors` | `$filter=LegislatoreCode eq 'Rep X'` | Sponsorships, `SponsorLevel` = `Chief` or `Regular`. **Field name really is misspelled `LegislatoreCode`.** |
| `Measures` | `$filter=SessionKey eq '2023R1'` | `CatchLine`, `MeasureSummary`, `ChapterNumber`, `Vetoed`. Fetch per session and join to votes. |

Session keys look like `2021R1` (regular), `2022R1` (short), `2021S1`/`2021S2` (special), `2021I1`
(interim).

### TRAP — Oregon "Motion to withdraw from committee" Nay votes are NOT content stances

Minority members move to withdraw a bill from committee to force a floor vote. **Majority members vote
Nay as a bloc to defend committee process, regardless of the bill's merits.** Proof: Kropf voted Nay on
the motion to withdraw HB 4147 (2022R1), a bill letting incarcerated people vote — a bill he plainly
favours. On HB 3115 (2021R1) and HB 2107 (2023R1) he voted Nay on the procedural motion and **Aye on
final passage of the same bill.**

**Only score `Third reading` / `Passed` / `concurred in Senate amendments` votes.** Exclude motions to
withdraw, refer/re-refer, postpone, and to substitute a Minority Report. Filter `ActionText`.

### Strongest tier: bills they floor-CARRIED

`MeasureVotes.ActionText` contains `Carried by <Name>`. A floor carrier speaks for the bill — their own
act, stronger than sponsorship. Grep for it; it surfaces their signature legislation instantly.

### Other Oregon fetch notes

- Citation URL: `https://olis.oregonlegislature.gov/liz/<SESSION>/Measures/Overview/<BILL>`. It is a
  SPA that **returns HTTP 200 even for a nonexistent measure** — status code proves nothing. Verify via
  the embedded `<title>` (e.g. `HB4002 2024 Regular Session`).
  **Confirmed 2026-07-25 with a control:** a real measure yields
  `<title>HB3546 2025 Regular Session - Oregon Legislative Information System`, while a fake
  (`SB9999`) yields `<title> Oregon Legislative Information System` — an **empty** title. So the
  one-liner audit is: `curl -sL <url> | grep -oiE '<title>[^<]*'` and assert the bill number **and the
  session year** both appear. This also catches citing the right bill number in the wrong session.
- `bendbulletin.com/?s=<q>` and `oregoncapitalchronicle.com/?s=<q>` both work with a plain browser UA,
  no `r.jina.ai` proxy needed. Bend Bulletin result links omit `www.`.
  **Stronger form (2026-07-25): do NOT route bendbulletin through `r.jina.ai` — it fails.** Jina
  returned HTTP 422 `TimeoutError: page.goto Timeout 15000ms` on `bendbulletin.com/?s=...` even with
  `x-no-cache: true`. Plain curl + full desktop Chrome UA returns search results and complete article
  bodies. Article prose lives in `<p>` tags with apostrophes as `&#8217;` → U+2019 `’`; **normalize
  HTML entities before string-matching any quote**, or a correct quote reads as a mismatch.
- Ballotpedia served fine over plain curl this session (no Playwright needed). Its value for Oregon
  legislators is often just the **campaign-site contact email**, which is how to find a campaign domain
  that doesn't match the obvious name pattern.

### TRAP — `LegislatorCode` is re-keyed when a same-surname member arrives

Bobby Levy (R, HD 58) was `Rep Levy` through 2022R1; when Emerson Levy (D, HD 53) was seated in 2023
the codes became `Rep Levy B` and `Rep Levy E`. So `oregonlegislature.gov/levy` is **Bobby**, and
`/levyE` is Emerson. **Never filter Oregon data on surname alone** — always resolve the code via
`Legislators?$filter=FirstName eq '<First>'` and read back `DistrictNumber` + `Party` to confirm.

### Search + fetch notes (added during the Emerson Levy HD-53 remediation)

- `html.duckduckgo.com` CAPTCHA'd immediately; **`mojeek.com/search?q=`** worked first try and is the
  better search engine for Oregon local races.
- WordPress campaign sites behind **mod_security** (e.g. `emersonvotes.com`) return `406 Not
  Acceptable` on `*-sitemap.xml` for short User-Agents while serving HTML pages 200. Send a full
  desktop Chrome UA for every request on such a host, then read `page-sitemap.xml` /
  `post-sitemap.xml` for the real page list — a campaign `/issues/` page is often empty while
  `/priorities/` holds the platform.
- `oregonlegislature.gov/<member>/Pages/{biography,news,legislative-accomplishments}.aspx` render as
  SharePoint chrome with **zero body content** over curl. Don't budget time for them.
- Bend Bulletin **rots its own opinion URLs**: guest columns 302 to the Opinion section landing page.
  Recover the body from `archive.org/wayback/available?url=<path>` then fetch the snapshot.
  *Partial contradiction 2026-07-25:* a 2024 guest column
  (`/2024/10/16/guest-column-anthony-broadman-showing-up-for-central-oregon/`) served **200 with the
  full body** over plain curl. Try direct first; fall back to Wayback only on an actual 302.

### Performance note

`Measures?$filter=SessionKey eq '2025R1'` is ~5.3 MB / ~3,300 entries. **Parsing it with a bash
`while read` loop over `grep -o` per field times out (>2 min).** Split on `<entry>` in node instead —
the same job finishes in seconds. Same for a 1.4 MB `MeasureVotes` payload (976 votes).

### Bend / Deschutes specifics

See [[ref-bend-oregon-sources]] for the county voters'-pamphlet PDF path
(`/assets/displaypdf/<node>`, **not** `/nodes/download/<node>`), the
`(This information furnished by X.)` attribution rule, and the Bend camping-code council vote.
