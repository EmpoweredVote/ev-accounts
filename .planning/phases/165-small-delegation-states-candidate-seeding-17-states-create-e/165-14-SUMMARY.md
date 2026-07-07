---
phase: 165-small-delegation-states-candidate-seeding-17-states-create-e
plan: 14
state: HI+NH
status: complete
completed: 2026-07-07
requirements: [USHC3-05]
---

# 165-14 SUMMARY — HI + NH stance research pushed to PROD (largest paired load)

## What was built
hi/nh-2026-house scaffolds (live federal-24 scale) + stance research for all 32 new HI/NH candidates, pushed to PROD in multiple 3-concurrency waves. **227 answers (HI 54 + NH 173), 0 unsourced, 0 surname leaks; 189 quotes.**

## Coverage
- **HI (54 answers, 11/13 sourced):** -150101 Booker 5, -150102 Fatula 8, -150103 Keohokalole 13 (state-senate record + Civil Beat Q&A), -150104 Kiswanto 5, -150105 Berning 1, -150106 Conley 4, -150107 Lam 3 (2024 Civil Beat Senate Q&A, staleness flagged), -150201 Basin 1, -150202 Guithues 8, -150203 King 2 (novelist/IA-congressman homonyms ruled out; hashtag-mined row dropped in verification), -150204 Awa 4 (his anti-abortion state vote correctly honest-skipped as not chair-placeable).
- **NH (173 answers, ALL 19/19 sourced — 0 skips):** NH-1 open field: Beriont 19, Chadzynski 11 (documented ICE position shift scored on recency), Conlin 2, Emerson 1, Howard 10, Shaheen 9, Spinosa 15 (surprise-rich libertarian-Dem — evidence beat priors), Sullivan 8, Urrutia 8, Anderson 4, Bailey 11, Cole 9 (sitting state rep, roll-call-backed), DiLorenzo 5, Noveletsky 10; NH-2: Beauchemin 12, Callis 9 (left-of-party answers faithfully reported), Nicholson 8, Orlando 8, Lily Tang Williams 14.
- **Whole-record honest-skips (gate-pin for 165-17, trails in hi _SKIPS.md):** **-150205 Edward Codelia** (survey answered but mechanism-free — no placeable chair), **-150206 Randall Terry** (identity UNRESOLVED: Ballotpedia links the filer to the national activist but Hawaii-local sources are silent; per hard rule his national positions were NOT used — consistent with the 165-06 headshot purge).
- Incumbents Case/Tokuda/Goodlander partial-tier → skipped; NH-1 has no incumbent.

## Method notes
citizenscount.org = NH's authoritative questionnaire source (multi-cycle surveys, roll-call data). Playwright MCP died mid-plan; agents pivoted to WebFetch/jina/DDG paths without fabricating Ballotpedia content. Verification passes dropped 2 unsupported HI rows (Basin abortion inference, King hashtag-mining) and caught 1 hallucinated quote fragment (Urrutia) before push.

## Self-Check: PASSED
0 unsourced on PROD for all 30 pushed targets; every new HI/NH candidate sourced or pinned-skipped with trails. Gate pins: -150205, -150206.
