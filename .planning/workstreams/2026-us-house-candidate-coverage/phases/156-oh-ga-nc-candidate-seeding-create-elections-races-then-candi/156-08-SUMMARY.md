# 156-08 SUMMARY — GA new-candidate stances

**Status:** COMPLETE ✅
**Data:** `backend/data/stance-research/ga-2026-house/` (6 CSVs) → pushed via `_push_relaxed.ts`

## Result — 5 covered / 13 whole-record skips (of 18 new GA candidates); 28 stance rows, 0 unsourced
GA has the thinnest field (many first-time challengers in safe/open GA seats with no fetchable platform). GA incumbents untouched (D-01). Pushed by UUID, 0-unsourced enforced.

### Covered (5)
| candidate | ext | topics | source |
|-----------|-----|--------|--------|
| Maura Keller (GA-3 D) | -130301 | 8 | maurakeller.com/issues |
| Shawn Harris (GA-14 D) | -131401 | 7 | shawnforgeorgia.com + AJC |
| Amanda Hollowell (GA-1 D) | -130102 | 6 | campaign site |
| John Cowan (GA-11 R) | -131101 | 5 | campaign issues page |
| Chris Harden (GA-11 D) | -131102 | 2 | Recap Report interview + electharden.com |

### Whole-record honest-skips (13, pinned in `156-verify.sql` `_stance_skip`)
James Duffe (-130401), John Salvesen (-130501), Anthony Kozycki (-130701), Pamela DeLancy (-131002), **Houston Gaines (-131001)**, **Jasmine Clark (-131301)**, Kevin Martin (-130601), Kelly Esti (-130801), Jim Kingston (-130101), **Jonathan Chavez (-131302)**, Caitlyn Gegen (-130901), Ceretta Smith (-131201), Matt Day (-130201).

**Notable skips:** Jasmine Clark (GA-13 vacancy D) and Houston Gaines (GA-10 open R) are sitting GA state legislators, but their roll-call records are behind the GA-legislature JS SPA (legis.ga.gov) — unreachable via WebFetch; Ballotpedia/OTI empty. Documented JS-wall skip (candidate for a future Playwright→roll-call enhancement pass, per [[project_150_playwright_stance_method]]). GA-13 vacancy nominees Clark + Chavez both skipped this pass.

## Verification
0-unsourced enforced by push filter (28/28 rows carry ≥1 fetched http source). Fetch-only-real-URLs discipline + push filter (155 precedent).

## Gate
0 unsourced for the GA race-scoped pids; every GA new candidate covered-or-skipped. `_stance_skip` now has OH (10) + GA (13) pins; NC appended by 156-09.
