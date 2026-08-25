# NC stance campaign — the four wave-2b local bodies, probed 2026-08-25

Task 1 of the locals pass. The campaign memory says *probe Legistar/Granicus per body before
researching anyone*. This is that probe, and it changed two assumptions.

## What each body actually runs

| Body | People | System | Fetch | Narrative? |
|---|---|---|---|---|
| Durham City Council | 7 | CivicPlus AgendaCenter, `durhamnc.gov`, **catID 4** | `POST /AgendaCenter/UpdateCategoryList {year, catID}` → `/AgendaCenter/ViewFile/Minutes/_MMDDYYYY-<id>` PDFs | **Yes — the best of the four** |
| Durham County BOC | 8 | **Legistar `durhamcounty`** | `webapi.legistar.com/v1/durhamcounty/events`, `.../events/{id}/eventitems?MinutesNote=1` | **No** — see below |
| Asheville City Council | 7 | WordPress custom post type `meeting` | `wp-json/wp/v2/meetings` → ACF `meeting_minutes` → `docs.google.com/document/d/<id>/export?format=txt` | **Yes** |
| Buncombe County BOC | 10 | **CivicClerk, client `buncombeconc`**, categoryId **26** | `buncombeconc.api.civicclerk.com/v1/Events?$filter=categoryId eq 26` → `GetMeetingFileStream(fileId=N,plainText=false)` PDFs | **Yes** |

Harvest + topic scan scripts, and the 195-document text corpus they produce, live in the session
scratchpad (`harvest_locals.py`, `scan_topics.py`, `corpus/`). They are re-runnable from scratch;
the corpus itself is not committed because it is 13 MB of derived text.

## 🔴 Two corrections to what the campaign memory assumed

**1. "COUNTY minutes are action-only" is false as a rule — it is true of ONE county here.**
Buncombe's minutes are fully narrative and attribute positions to named commissioners
("Commissioner Sloan requested that the Board review and consider a draft letter…"). Durham
County's are not. The property is per-body and has to be tested per body, not inferred from
city-versus-county.

**Durham County is the weak one.** Legistar carries no minutes document at all for the Board of
County Commissioners — `EventMinutesFile` is null on every event, and `EventItemRollCallFlag` is 0
with no mover or seconder recorded, so there are **no per-member votes**. What exists is
`EventItemMinutesNote`: clerk shorthand, attributed by initials, e.g.
`MB - why membership going from 9 to 12` / `NA - concern around not being allowed to use nine months
to define what data cen…`. That is a *lead* — it says which commissioner engaged which item — but it
is not prose that can carry `reasoning`, and it is certainly not `quote_text`. Expect Durham County
to yield near zero from this source and to need a second source per row.

**2. `webapi.legistar.com/v1/durham/` returning HTTP 500 is not Durham City being off Legistar.**
Every wrong slug returns the same 500 with the body
`LegistarConnectionString setting is not set up in InSite for client`. Tested `durham`, `durhamnc`,
`cityofdurham`, `durhamcountync`, `asheville`, `ashevillenc`, `cityofasheville`, `buncombe`,
`buncombecounty`, `buncombenc` — all 500. Only `durhamcounty` is real. **A 500 there means "no such
client", not "server down".**

## Traps found while probing

- **Asheville's older minutes are not public.** Meetings before ~Dec 2025 carry a
  `drive.google.com/file/d/<id>/view` PDF link, and those files require a Google sign-in — confirmed
  with a real browser, not just curl (401 → `accounts.google.com/v3/signin`). From Dec 2025 the city
  switched to Google **Docs**, which export cleanly at `/export?format=txt`. **Usable Asheville
  window: 2025-12-09 → 2026-06-23, 11 meetings.**
- **Asheville publishes the same minutes document twice** — once on the agenda-briefing meeting and
  once on the formal meeting, because one combined document covers both. 21 downloads deduped to
  **11 unique**. Dedupe by content hash or the corpus double-counts every instrument.
- **The CivicClerk OData endpoint caps a page at 15 rows** whatever `$top` says. Paging by
  `$skip` per year took Buncombe from 21 documents to 51. A single unpaged query silently looks
  like a complete answer.
- **Buncombe's own AgendaCenter is empty** and its site search finds nothing; the live index is the
  CivicClerk API behind `buncombenc.gov/129/Agendas-Minutes`, discoverable only from the rendered
  page. Older Buncombe minutes also sit at `media.buncombenc.gov/common/Commissioners/<YYYYMMDD>/`
  with no index.
- Durham City's AgendaCenter needs the **`www.`** host: `durhamnc.gov/AgendaCenter/UpdateCategoryList`
  301s and drops the POST body.

## Corpus as harvested

| Body | Unique documents | Window |
|---|---|---|
| Durham City Council | 118 | 2024-01 → 2026-08 |
| Durham County BOC | 114 (minutes notes only) | 2024-01 → 2026-08 |
| Buncombe County BOC | 51 | 2024-05 → 2026-08 |
| Asheville City Council | 11 | 2025-12 → 2026-06 |

## Method for the locals

The legislature pass worked **bill-first** off sponsor lists. Councils have no sponsor lists, so the
equivalent is **instrument-first**: find the ordinance, resolution, rezoning or budget action in the
minutes, then read it across the whole body at once. `scan_topics.py` produces the candidate list by
matching topic vocabulary against paragraphs that also contain an instrument word (ordinance /
resolution / moved / motion / adopt / approve / rezone / budget amendment / public hearing). Every
hit still has to be read — the scan proposes, it does not decide.
