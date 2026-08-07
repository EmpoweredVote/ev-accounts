# Dead cited hosts — re-point-and-verify pass, 2026-08-07

Works the queue left by `2026-08-04-dead-host-classification.{json,md}`.
**Read-only so far. No migration written, nothing repaired, nothing retired.**

## The queue was wrong twice before any row was examined

**1. It was never "blocked".** The worklist carried "~18 hosts unclassified, blocked on archive.org
rate limits". The 08-04 artifact holds **26 hosts + 2 controls, 0 UNKNOWN, both controls
`CONTROL_OK`**. The classification finished. Migrations 1557–1562 then cleared four more hosts
(`bilalmahmood`, `willametteweek`, `dutra4whittier`, `walthampatch`).

**2. Re-derived from prod: 22 hosts / 52 live rows — 29 sole-sourced, 23 co-sourced.** Only the 29
are exposure; a co-sourced row still has a working citation. Co-sourced are PARKED by operator
ruling 2026-08-07.

## 🔴 The finding that matters: 8 of 22 hosts were never dead

The classification tested the apex domain **after stripping `www.`**. These domains publish an A
record only on the `www` subdomain, and the stored citations already use the working form.

Probing every distinct stored URL exactly as stored: **14 of 30 return HTTP 200 with real content.**

| host | stored form | apex | www |
|---|---|---|---|
| `davidredkey4congress.com` | `www.` | NXDOMAIN | **200** |
| `tracinskiletter.com` | `www.` | NXDOMAIN | **200** |
| `bradknott.com` | `www.` | NXDOMAIN | **200** |
| `markhenderson.org` | `www.` | NXDOMAIN | **200** |
| `allenrwaters.com` | `www.` | NXDOMAIN | **200** |
| `cambridgeresidentsalliance.org` | `www.` | NXDOMAIN | **200** |
| `rightnowmn.org` | `www.` | NXDOMAIN | **200** |
| `publicleadershipinstitute.org` | apex | **200** | NXDOMAIN |

**Generalise: resolve the host AS CITED. Normalising `www.` away before a DNS test invents a dead
host.** This is the same family as the scheme-less citations (1549) — a probe that reshapes the value
before testing it measures something other than the citation.

⚠ I re-pointed nothing on the strength of this: I had already verified all 7 Redkey rows against
Wayback captures before discovering the live site made that unnecessary. Wasted effort, not a wrong
result — but it is why the live-URL probe must come FIRST, before any archive work.

## Outcome for the 29 sole-sourced rows

### A. Never broken — no action (14 rows)

| politician | rows | host |
|---|---|---|
| David Redkey | 7 | `www.davidredkey4congress.com` (5 paths, all 200) |
| Robert Tracinski | 4 | `www.tracinskiletter.com` (5 paths, all 200) |
| Mark Henderson | 2 | `www.markhenderson.org` |
| Luisa de Paula Santos | 1 | `www.cambridgeresidentsalliance.org` |

⚠ Tracinski nearly became an eighth invented-outlet cluster: 4 rows cite articles with zero Wayback
captures on a host that failed DNS. **All four articles are live and return 200.** Newsletter article
pages simply are not archived. Zero captures + failed apex DNS is not evidence of fabrication.

### B. Genuinely dead, capture verified to CARRY the claims → re-point (7 rows)

| politician | rows | capture | note |
|---|---|---|---|
| Frank Chapman | 5 | `20260511050003` | see domain-reuse warning below |
| Mary Ann Pacheco | 2 | `20231215180833` | all 6 distinctive terms present |

🔴 **`chapmanforcongress.com/issues/` has 13 captures: 2003 ×1, 2014 ×11, 2026 ×1.** The domain was
reused across cycles, so 12 of 13 belong to a different candidate's campaign. `REPOINTABLE_ALL` in
the 08-04 classification only asked *was this URL ever captured*, never *is the capture
contemporaneous*. Re-pointing to the first available capture would have cited a stranger's platform
under Chapman's name. **Always filter to the claim's period and confirm identity.**

⚠ Two term-matching false negatives caught by reading the passage instead of trusting the count:
"free market" scored 0 on a page reading "free-**market** system"; and an empty CDX result for
Redkey's tariffs path was urlkey normalisation — the `www.` query form returned a 200 capture.

### C. Genuinely dead, NO usable support — needs an operator decision (8 rows)

| politician | rows | host | finding |
|---|---|---|---|
| Christina Stephenson | 3 | `boli.oregon.gov` | **COMPOSED HOSTNAME — confirmed.** Oregon serves BOLI at `www.oregon.gov/boli` (200). The cited host has no DNS and no captures, i.e. it never existed. `clark.house.gov` shape. |
| Alex Monteiro | 2 | `monteiro4council2022.com` | Two captures exist (2022-01-17, 2023-03-15) and **neither carries the claims** — no "retail", "restaurants", "high wages", "firefighters", "first responders" on either. The row cites the site ROOT; the specifics are not there. |
| Octavio Martinez | 2 | `octavioforwhittier.com` | No DNS, zero captures. Lapsed campaign domain. |
| Claudia Frometa | 1 | `downeylegend.com` | No DNS, zero captures of the cited article. |

**On Stephenson specifically — two defects, not one.** Besides the composed host, the fabricated URL
is appended into the voter-facing `reasoning` text itself ("...in the workplace.
https://boli.oregon.gov/pages/news.aspx"), so `Citations.jsx` renders an invented URL as prose. That
is live today.

Re-pointing Stephenson to the real BOLI site is **not** available: the cited path is a news INDEX,
and a landing page is not coverage (the ruling that flipped Newton and Portland). Attributing her
three broad characterisations to a news index would manufacture support.

**Monteiro is repairable in principle** — the archived site has a "Priorities" sub-page the claims may
rest on. Checking it was deliberately NOT done: adding a page the row never cited invents sourcing
the author never used (the ruling that left two rows unrepaired in 1557). Flagging it as an option,
not doing it unasked.

## Recommended

1. **Re-point the 7 verified rows** (Chapman 5, Pacheco 2) to their contemporaneous captures. Same
   shape as 1557/1559.
2. **Decide the 8 in group C.** My reading: Stephenson's 3 are the strongest retirement candidates —
   the host never existed and the reasoning is contaminated with the invented URL. Monteiro's 2,
   Martinez's 2 and Frometa's 1 are ordinary lapsed-campaign-domain cases where the claim is probably
   true but unverifiable; the standing rule is **verified absent → retire, never unsure → retire**,
   and "the page is gone" is not the same as "the claim was never supported".
3. **Fix the probe, not just the data** — `citation-host-resolve.mjs` should resolve the host as
   cited. Eight false dead hosts came from one `www.` strip.
