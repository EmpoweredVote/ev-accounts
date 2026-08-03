# Is the composed-URL defect inside the `OK` set too? — a 100-row sample

**Question.** 1535 established that 1,166 row-citations in the `GONE` tail point at pages that never
existed. The 08-02 sweep classified **15,405 URLs / 51,092 live row-citations as `OK` on reachability
alone** — and a composed URL that happens to resolve passes that test. Is this a tail problem or a
corpus problem?

**Answer: a tail problem.** Hard URL defects run at **3% in the OK set (95% CI 1.0–8.5%)**, against
effectively 100% of the never-archived tail. But a *different* defect — the page is the right page and
does not carry the specific the row asserts — runs at **16% (CI 10.1–24.4%)**, and that is the larger
finding here.

| verdict | n | what it means |
|---|---|---|
| **SUPPORTED** | 78 | every applicable signal landed |
| **PARTIAL** | 16 | right page; an asserted bill number or quoted span is not on it |
| **UNSUPPORTED** | 3 | no applicable signal landed |
| INCONCLUSIVE (JS shell) | 1 | `stevehiltonforgovernor.com` — but its **archive verifies**, name and all |
| INCONCLUSIVE (soft-404) | 1 | counted as a URL defect below |
| FETCH_FAILED | 1 | re-probed by hand: a real **404**, counted below |

| defect class | rate | 95% CI | extrapolated to 51,092 citations |
|---|---|---|---|
| **URL dead or wrong** | 3/100 | 1.0 – 8.5% | 524 – 4,318 |
| page right, asserted specific absent | 16/100 | 10.1 – 24.4% | 5,158 – 12,477 |
| any failure to verify | 19/100 | 12.5 – 27.8% | 6,394 – 14,193 |

## Method

Sample: 100 **distinct rows**, drawn with a fixed-seed (20260802) Fisher–Yates shuffle over all 51,092
OK-classified citations sorted by `(url, politician_id, topic_id)` — reproducible and auditable, not
"whatever the query returned". 54 hosts; the largest are en.wikipedia.org (16),
www.ontheissues.org (13), leginfo.legislature.ca.gov (9), mgaleg.maryland.gov (7).

🔴 **The test adapts to the page type, because one rule would manufacture failures.** Sixteen of these
citations are state bill texts, and a bill page has no reason to name the legislator — scoring it
`NAME_ABSENT` would be the same class of error as testing a campaign site for our own chair label.
Three signals are collected and a citation fails only when **every applicable one** fails:

- **BILL** — the row names a measure (`SB 684`, `H.R. 7120`, `LD 2077`); is it on the page?
- **NAME** — is the politician named?
- **QUOTE** — does a verbatim quoted span appear?

Where the live page failed, the **Wayback capture was tested too**, to separate "never right" from
"rewritten since" — the rot-without-breaking mode this workstream has flagged but never measured.

## 🔴 The first run of this detector was wrong four ways

It reported 6 UNSUPPORTED. Hand-checking every one against the page found **three were my bugs**, and
fixing them also surfaced a defect the first run had *missed*:

| bug | effect | evidence |
|---|---|---|
| surname kept trailing punctuation | `"Thomas H. Kean, Jr."` → surname `Kean,` matched nothing on a League of Conservation Voters page **entirely about Thomas Kean** | false UNSUPPORTED |
| Maine's bill format absent from the pattern | `LD 2077` unmatched, so a page **literally titled "Summary of LD 2077"** scored unsupported | false UNSUPPORTED |
| bare letter+number matched as a bill | `S25`, `S23`, `S31` — Los Angeles **council file numbers** — became five phantom "asserted bills" for Tim McOsker | false PARTIAL |
| soft-404 test required a space | mgaleg.maryland.gov 302s a bad member id to a page titled exactly **`NotFound`**, served as HTTP 200 | **missed a real defect** |

That is the fourth time on this workstream that the first cut of a detector over-fired. The numbers
above are from the corrected run; the raw first-run output is not what is reported.

## The 3 URL defects

| politician | topic | URL | what it is |
|---|---|---|---|
| Jennifer White Holland | Voting Rights | `mgaleg.maryland.gov/…/Members/Details/holland03` | **soft-404** — 302s to a page titled `NotFound`, HTTP 200. The member id is wrong. |
| Karen Ross | Climate Change | `plantingseedsblog.cdfa.ca.gov/wordpress/index.php/2024/09/27/…` | **404** — redirects (drops `/wordpress/`) and dies. The sweep saw a 200 earlier today. |
| Simon Cataldo | Healthcare Access | `malegislature.gov/Committees/Detail/J28` | **wrong page** — J28 is the Joint Committee on **Housing**; the row says he sits on the Joint Committee on **Mental Health, Substance Use and Recovery**. |

All three carry a second source, so none is currently unsupported for a voter.

⚠ Two more scored UNSUPPORTED and are **weak rather than wrong**: both Karina Talamantes rows cite real,
topical Sacramento city press releases (the CityStart Blueprint, the Climate Action Plan) that simply
do not name her — the rows claim she was part of the council that adopted them. The page is the right
page for the *policy*; it is not evidence about *her*. Their archives agree, so this is not rot.

## The 16 PARTIALs are the real story

In 13 of 16 the politician **is** named on the page — it is the right person's page — but a specific is
not there: an asserted bill number in 9, a quoted span in 7. Examples: Phil King's Texas Senate page
does not mention `SB 6`/`SB 7`; Hakeem Jeffries's OnTheIssues page does not contain
*"tax breaks for billionaires, permanent; tax breaks for everybody else, expire"*;
Lindsay Sabadosa's Wikipedia article does not mention `H.1239`.

⚠ **This is not automatically a defect.** 14 of the 16 rows carry a second source, and a row that cites
a person-page *and* a bill-page can legitimately name a bill the person-page omits. What it does mean
is that **the cited page alone does not let a reader check the claim** — the same class 1518 addressed
when it corrected 16 quotes, and the same class the 11 contradicted Act on Mass rows fall into.

Distinguishing "second source covers it" from "nothing covers it" needs the row's *other* sources
tested as well, which this sample did not do. That is the obvious next measurement, and it is cheap:
the same tool, run over all sources of a row rather than one.

## What this settles

- **Do not extrapolate the composed-URL finding to the corpus.** At 3% (CI 1.0–8.5%) the OK set is not
  the tail. Re-researching 51,092 citations is not warranted by this evidence.
- **The `GONE` tail remains the right place to spend** — 1,166 rows there, with the operator decision
  still open in `NEXT-composed-citations.md`.
- **A second sample is worth it before acting on the 16%**: same 100 rows, but test *every* source on
  each row. If the second source covers the specific, the 16% is mostly benign; if it does not, it is a
  bigger queue than the tail.

Artifacts: `2026-08-02-ok-sample.json` (the seeded sample, reproducible) ·
`2026-08-02-ok-verify.jsonl` (per-row signals, live and archive) · `scripts/_tmp-ok-sample.mjs` ·
`scripts/_tmp-ok-verify.mjs`.
