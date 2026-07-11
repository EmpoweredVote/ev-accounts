# Senate 2026 headshot wave — 15 pinned no-photo skips (2026-07-10)

Wave complete: 99/114 imported (93 BP race-page pass + 6 agent finds), all Chris-approved.
Remaining 15 below searched exhaustively by agents (trails summarized; full trails in session
agent outputs). Verify query: active/filed race_candidates on 2026 U.S. Senate races with
politician_id set and no politician_images row — returns exactly these 15.

2026-07-11 politician_context source-mine cross-check (post-stance-wave): re-ran the verify
query — still exactly these 15. Mined inform.politician_context + politician_context_evidence
URLs for all 15 pids; only Vail, Saucerman, Stevens had stance-wave sources, all chased and
dead-ended (dated notes inline below). No pins lifted; calendar unchanged.

## Re-check calendar

- **Alaska (5)** — re-check when the AK Division of Elections posts the 2026 primary
  **official election pamphlet** (candidate-submitted photos; primary is Aug-18, pamphlet
  typically posted ~4-6 weeks prior):
  - Earl D. Southworth (Alaskan Party; FB page login-walled, no other footprint)
  - Fred C. Grauberger (R, Chugiak perennial; zero web presence)
  - Heather McElwain (R, Wasilla; localcandidates.org profile 403/429-walled — retry that too)
  - Richard B. Mayers (photo EXISTS at static.votesmart.org/canphoto/33965.jpg but 403 on all
    fetch paths incl. Wayback; IL-based perennial/agitator — flag for content review before use)
  - Shirley A. Saucerman (nonpartisan, Anchorage MD; saucermanfordemocracy.com has landscape
    photo only; FB login-walled) — 2026-07-11: confirmed site is single-page, sole image is
    Alaska scenery (no person photo at all); no about/bio page exists
- **New Hampshire (4)** — re-check ~Sept (primary Sep-8; Citizens Count sometimes adds photos):
  - David Jarvis, John Vail (sendnomoney.org has only old India travel snapshots;
    2026-07-11: citizenscount.org/candidate/john-vail profile exists but shows the
    "no photo provided" silhouette — keep on the Sept Citizens Count re-check),
    Richard McMenamon II, Sabrina Smith (X @6O3Sabrina active but avatar unfetchable;
    603sabrina.com parked). NOTE: BP NH race page "Kevin Smith" photo ≠ Sabrina Smith.
- **Minnesota (3)** — primary Aug-11; low hope (blogger-confirmed zero-presence candidates):
  - George H Kalberer, Kurt Michael Anderson (kurtmichaelanderson2026.org filed w/ SOS but
    domain dead — retry), Peter John Murgic
- **Delaware (1)** — Travis Stevens: own site travisjackstevens.com uses a **Meta-AI-generated
  placeholder headshot** (watermarked) — rejected on principle; re-check for a real photo later.
  2026-07-11: GoFundMe (gofundme.com/f/help-travis-jack-stevens-register-for-senate) hero +
  organizer profile photos are ALSO AI-generated (mangled DE flag heraldry, waxy render) —
  same synthetic set, rejected.
- **Oklahoma (1)** — Sevier White (Lib, Norman, 77yo retired teacher; Vote-USA literal
  "No Photo"; OK Lib Party FB post unfetchable).
- **Tennessee (1)** — Catherine Barcel "Barcy" Whitson (Ind, Chattanooga; TN SOS filing only;
  all Whitson web hits are unconfirmed homonyms).

## Related data flag (not photo work)

ME 2026-06-09 primary race carries 3 stale NULL-pid race_candidates rows: Susan Collins,
David Costello, Graham Platner (withdrew 7/8) — belongs to the held dual-pid merge todo
(`.planning/todos/` senate dual-pid item). "Daniel J. Sullivan Jr." AK (-66000068) got the
incumbent Sen. Dan Sullivan official portrait — that row is a dual-pid placeholder; when the
merge lands, keep whichever pid survives pointing at an image.
