# Non-resolving cited hosts — what the 42 actually are

Follow-up to the citation-level sweep (`2026-08-04-citation-host-resolve.md`). Nothing retired, no
migration. **Next free number is still 1549.**

## 🔴 CORRECTION — it is 23 hosts, not 42, and the "48 resolver errors" were mostly the same artifact

The resolve pass reported **42 NO_DNS entries and 48 errors**. That headline was wrong, and the reason is
worth keeping: my host regex assumed every source begins with a scheme, so a **scheme-less** source was
returned whole and then failed DNS as if it were a hostname.

| bucket | count | what it really is |
|---|---|---|
| genuine non-resolving hosts | **23** | real DNS failures, the queue below |
| scheme-less URL artifacts inside NO_DNS | **19** | `lapublicpress.org/2026/03/…`, `ballotpedia.org/john_logsdon` — real hosts, no scheme |
| `EBADNAME` "errors" | most of 48 | same scheme-less class, plus `#fragment` forms (`erickakopp.com#priorities-section`) |
| `ESERVFAIL` — real hosts | 4 | resolver failures, **UNKNOWN not absent**; re-checked by hand below |

They all belong to the **312 scheme-less citations / 166 rows** class already recorded, not to a dead-host
class. Any count of "dead hosts" that includes them is inflated.

## ✅ Resolved by hand this session

| host | rows | verdict |
|---|---|---|
| `house.utleg.gov` | 6 | ✅ **LIVE** — HTTP 200, 74,535 bytes. The `ESERVFAIL` was a resolver hiccup. False alarm; nothing owed. |
| `bilalmahmood.com` | 12 | ✅ **REPOINTABLE_ALL** — 29 archived siblings, and all 3 cited paths captured **8 times each**. Re-point to Wayback (migs 1519/1531/1539 pattern). |
| `willametteweek.com` | **57** | 🔴 **COMPOSED HOSTNAME with a real twin.** See below. |
| `davidredkey4congress.com` | 7 (all sole-sourced) | ⚠ **Real candidate** — David Wayne Redkey, 2026 AZ-1 Democratic primary (Ballotpedia, BallotReady, Good Party). Lapsed campaign domain, **not** an invented outlet. Re-source. |
| `chapmanforcongress.com` | 5 (all sole-sourced) | ⚠ **Real candidate** — Frank Chapman, 2026 WY at-large, FEC committee **H6WY01157 "Chapman for Congress"**. Lapsed domain. Re-source. |

### 🔴 `willametteweek.com` — 57 rows, the largest single-host exposure found so far

Willamette Week is a real Portland alt-weekly, but **its domain has always been `wweek.com`**. The cited
host does not resolve, and this is the `clark.house.gov` shape: a composed hostname pointing at content
that genuinely exists elsewhere.

- 5 distinct cited URLs, all of the form
  `willametteweek.com/news/2024/10/30/portland-council-district-N-candidates-answer-our-questions/`.
- All 5 return **HTTP 404 on `wweek.com`** (with a 112KB 404 body — the reverse of the empty-200 trap;
  here the status is what counts).
- `wweek.com`'s archived October 2024 news holds **127 URLs and none of that shape**.
- ✅ **But WW's real per-district 2024 coverage exists**: `WW's Fall 2024 Endorsements: Portland City
  Council District 1/2/3/4`, dated **2024-10-16**, plus a `wweek.com/citycouncil/` candidate hub. The
  endorsements include candidate interviews, which is plausibly where these positions came from.
- So the **date and slug are fabricated while the underlying journalism is real.** These 57 rows are a
  **per-row re-point-and-verify queue**, not a bulk operation: each row's claim has to be found in the
  real endorsement page before its citation is rewritten. Affects **12 Portland councilors** — Novick (7),
  Avalos (7), Koyama Lane (5), Pirtle-Guiney (5), Wilson (5), Kanal (5), Morillo (5), Green (4),
  Zimmerman (4), Dunphy (4), Smith (3), Ryan (3).

## ⚠ The restraint that governs the remaining ~18 hosts

Of the 23, the overwhelming majority are **single-cycle campaign domains**: `dutra4whittier.com`,
`maryannforwhittier.com`, `octavioforwhittier.com`, `monteiro4council2022.com`, `kateforbloomington.org`,
`craigandresforprosper.com`, `davidfbristol.com`, `bradknott.com`, `kennethforla.com`,
`vivioforcongress.com`, `allenrwaters.com`, `markhenderson.org`, `act.juliabrownley.com`.

**A lapsed campaign domain is the normal end state of a real campaign site.** Redkey and Chapman prove
the point: both are verifiably real candidates whose domains no longer resolve. So "does not resolve" is
**not** evidence of fabrication, and these must not be reported as invented outlets. The same restraint
already applied to `octavioforwhittier.com`, `kennethforla.com`, `fairshareforma.com` and the four thin
hosts. **The practical question for these rows is whether a citation can be recovered (Wayback) or must
be re-sourced — not whether someone made the outlet up.**

Non-campaign hosts in the queue, which deserve the closer look: `boli.oregon.gov` (3 sole-sourced —
likely composed, Oregon serves BOLI at `oregon.gov/boli`), `m.lasvegassun.com` (a retired mobile
subdomain of a real paper — probably re-pointable to `lasvegassun.com`), `metromayor.org`,
`downeylegend.com`, `rightnowmn.org`, `cambridgeresidentsalliance.org`, `tracinskiletter.com`,
`walthampatch.com`, `publicleadershipinstitute.org`.

## ⛔ BLOCKED — archive.org throttling, and the two tooling failures behind it

`scripts/classify-dead-cited-hosts.mjs` is committed and correct, but could not complete this session:

1. **First version returned `UNKNOWN` for every host.** Three availability-API rounds per URL with no
   backoff throttled the script into non-answers. It was *right* to refuse to call that absence — a
   throttled reply is indistinguishable from a real absence — but it produced nothing. Rewritten to use
   **CDX exact-URL match as the primary test** with exponential backoff.
2. **A `nohup` background run died with its parent shell after one host**, silently, writing no artifact.
   On this platform, do not fire-and-forget; the script now takes `--from/--to/--pace/--maxurls` and is
   meant to be run in **foreground chunks** whose partial outputs are merged.
3. Even chunked, 14 hosts × 3 probes exceeded 9 minutes because archive.org is now rate-limiting this
   IP after the day's CDX volume. **Resume on a fresh quota**, or space the probes over a longer window.

⚠ Whoever resumes: the classification standard is migration 1548's — reproduce absence, measure per-host
sibling coverage, and verify a real control in the same run — and the output is a reading queue. Do not
convert a `NO_ARCHIVE_CAMPAIGN_WEAK` into a retirement without a hand read.
