# Senate 2026 stance wave — run plan (started 2026-07-10)

## ✅ WAVE COMPLETE 2026-07-11 — all 44 batches pushed
**Final PROD totals: 601 stance answers across 99 of 119 candidates; 475 quotes (all Read&Rank-selected); 20 zero-stance candidates = exactly the 20 pinned skips in `_SKIPS.md` (verified 1:1).** Side-flags in `.planning/todos/2026-07-10-senate-seed-recheck-calendar.md`: McCants TN + Rikleen/Gates MA + Beardsley DE withdrawals, Waters RI dormant-Senate-run, Burbank NE Aug-3 decision deadline. Party fixes applied: Bech→I, Harrington→I, + 3 MA backfills. Grayson AK researched-but-excluded (2004-stale; rows preserved in alaska-pri-4.csv).

## (historical) RESUME STATE (2026-07-10 23:05 PDT — session limit hit, agents blocked until limit reset)
- **24/44 batches pushed to PROD: 311 answers, 53 politicians covered, 230 quotes (all RR-selected), 12 skip pins in `_SKIPS.md`.**
- Failed on limit (no CSV written, safe to redispatch): alaska-pri-4 (Mayers/Grayson/Kohlhaas), rhode-island-pri-1 (Waters/Burbridge/Muñoz), rhode-island-pri-2 (McKay).
- Never started: delaware-pri-1/2, colorado-gen-1, idaho-gen-1, oklahoma-gen-1, tennessee-gen-1..3, gen-mixed-1..9 (20 batches, ~54 candidates).
- TO RESUME: dispatch remaining `_batches.json` entries (status != pushed) 3-at-a-time using the kansas-pri-1-shaped prompt (scale block = `_TOPIC_SCALE_FULL.txt`, output CSV per batch id, sonnet, WebFetch-only). Validate → `node --import tsx data/stance-research/senate-2026/_push.mts <csv>` → update status.
- Source intel accumulated: Citizens Count = NH goldmine; Ballotpedia 403-even-via-jina most of session (wiki api.php sometimes); r.jina.ai for elections.alaska.gov (TLS broken) + walled news; FEC api DEMO_KEY rate-limited; iSideWith = AI-inferred grids, excluded.
- Open side-flags in `.planning/todos/2026-07-10-senate-seed-recheck-calendar.md`: McCants TN withdrawal (conflicting), Rikleen + Gates MA withdrawals (verify vs certified ballot), Bech party NULL.

**Scope (user-confirmed):** ALL 119 zero-stance Senate 2026 candidates, including full primary fields — "we serve the citizens"; primary voters in KS/MN/NH/AK deserve discernment tools. Ordered by primary date (Aug 4 first).

## State files (this dir)
- `_roster.json` — 119 candidates (pid, name, party, state, first_election), sorted by date
- `_batches.json` — 44 agent batches with `status` field (pending → dispatched-waveN → done → pushed)
- `_TOPIC_SCALE_FULL.txt` — federal-24 scales regenerated fresh from live DB 2026-07-10
- `_topics_live.json` — all 44 live topics w/ ids + stance texts
- `<batch-id>.csv` — agent outputs, header: `pid,full_name,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3,quote_text,quote_deidentified`

## Orchestration rules (locked)
- politician-stance-researcher agents, **model sonnet**, **3 concurrent max**, WebFetch-only (no WebSearch/Playwright)
- Every prompt embeds: five-chairs framing + FULL 24-topic scale texts + correct-person guard + honest-skip rule + CSV spec (pid UUID column, RFC-4180)
- Ballotpedia fallback: `/wiki/api.php?action=parse&page=X&format=json&prop=wikitext`; r.jina.ai proxy for walled news
- Wave 1 (kansas-pri-1..3) = validation wave — check CSV format, source URL reality, chair-fit before scaling
- Push each state batch to PROD after validation (CSVs are gitignored → PROD is the durable store). Push = politician_answers + politician_context upserts keyed by pid, then quotes to essentials.quotes (readrank_selected only when de-id passes surname leak-check; new candidates have no existing selection → new quote becomes the pick)
- After each state completes: re-run zero-stance count for that state, log honest skips (candidate with 0 findable topics = pinned skip, note in `_SKIPS.md` with search trail)

## Special flags
- **AK "Daniel J. Sullivan Jr." (pid via roster, R)** — NOT incumbent Sen. Dan Sullivan; homonym challenger. Warn agent hard; wrong-person risk high.
- AK is RCV → over-indulge thoroughness (memory: rcv-thoroughness)
- MA candidates (Deaton, Bech, Rikleen, Gates) have no external_id — pre-existing pols, push by pid as usual
- OK D runoff Aug-25 (Priest vs N'Kiyla Thomas)

## Wave order (by primary date)
1. KS ×4 + VA ×1 (Aug 4) — wave 1 = kansas-pri-1..3 DISPATCHED
2. TN-pri ×2 (Aug 6)
3. MN-pri ×4 (Aug 11)
4. AK ×5, FL ×1, WY ×2 (Aug 18)
5. OK-pri ×1 (Aug 25), MA ×1 (Sep 1)
6. NH ×4 (Sep 8), RI ×2 (Sep 9), DE ×2 (Sep 15)
7. Generals: CO/ID/OK/TN ×~6 + gen-mixed ×9 (Nov 3)

## Prompt template
Reuse the kansas-pri-1 prompt shape: swap CANDIDATES block (name/party/pid), race context line (state, primary date, seat holder), state-specific source patterns (local news outlets, SOS candidate lists), output CSV path `C:/EV-Accounts/backend/data/stance-research/senate-2026/<batch-id>.csv`. Scale block = paste `_TOPIC_SCALE_FULL.txt` verbatim.
