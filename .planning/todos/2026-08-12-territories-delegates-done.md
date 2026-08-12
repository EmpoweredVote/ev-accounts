# Territories ✅ — six non-voting House seats (2026-08-12, migration 1719)

ADR 0003's second instance. All six territory/DC seats now exist, are explained, and **resolve
end-to-end from an address**.

| | Seat | Holder | Party | Bioguide | `voting_powers` |
|---|---|---|---|---|---|
| PR | Resident Commissioner | Pablo José Hernández | D | H001103 | `non_voting` |
| VI | Delegate, Virgin Islands | Stacey E. Plaskett | D | P000610 | `non_voting` |
| GU | Delegate, Guam | James C. Moylan | R | M001219 | `non_voting` |
| AS | Delegate, American Samoa | Aumua Amata Coleman Radewagen | R | R000600 | `non_voting` |
| MP | Delegate, Northern Mariana Islands | Kimberlyn King-Hinds | R | K000404 | `non_voting` |
| DC | Delegate, District of Columbia | Eleanor Holmes Norton | D | N000147 | `non_voting` |

Plus DC's **two shadow senators**, also flipped — they hold no seat in Congress at all, and leaving
them `full` asserted they vote in the Senate. All eight carry a required `representation_note`.
All six delegates have official Bioguide portraits; Norton had none before this.

Verified end-to-end: a point in San Juan, Charlotte Amalie, Hagåtña, Pago Pago, Saipan and Washington
each resolves through `ST_Covers` → district → office → holder to the correct delegate. That is the
only reliable test — `check:reachability` stays at baseline (`UNREACHABLE 40/40`).

## 🔴 Three things that would have gone wrong quietly

1. **ADR 0003 said territories were "a powers-only change". That was wrong about the data.** We held
   *nothing* for the five territories — no member, office, district or geometry. Five of six were a
   full seed. The ADR is corrected in place. Check the database before writing down how small a change
   will be.
2. **American Samoa's `<statedistrict>` in the Clerk of the House file is `AQ00`, not `AS00`.**
   Filtering on it returned five of six and made a sitting delegate's seat look vacant. Key on the
   `<state postal-code>` attribute. If anyone re-derives a delegate list, this will bite again.
3. **A monochrome check by pixel statistics would have rejected Plaskett.** Her Bioguide portrait is
   77% near-grey pixels — because the background is white, not because it is black and white. The
   contact sheet settled it in one look. Same lesson as the 120px size floor: *a statistic about an
   image is not a description of it.*

## Deliberate choices worth not undoing

- `representation_basis` stays **`residency`** for all six. These are geographic constituencies —
  every resident is represented — unlike Maine's tribal seats. That distinction is the whole reason
  ADR 0003 has two axes rather than one flag.
- Delegate-district `geo_id` is **FIPS || '98'** (PR 7298, VI 7898, GU 6698, AS 6098, MP 6998),
  matching DC's pre-existing `1198` and the Census convention. At-large *states* use FIPS || '00'
  (VT 5000, WY 5600) — do not confuse the two.
- `ocd_id` follows the shape already on the DC row (`.../state:pr/cd:98`). The OCD project itself
  prefers `territory:` for these; internal consistency won, and `ocd_id` gates only the admin
  dashboard, never address search.
- Polygons come from Census TIGERweb via `scripts/load-territory-boundaries.mjs`, which **verifies
  each polygon contains its own capital before writing**. Pago Pago is in the southern hemisphere and
  Saipan/Hagåtña sit near the antimeridian — the cases where a bad polygon fails silently.

## Not done

- **No territorial governments.** Governors, territorial legislatures and municipios are all absent.
  Puerto Rico alone has a governor, a bicameral legislature and 78 municipios. That is the next real
  tranche if PR is a priority, and it is much larger than this was.
- **No state-level (`G4000`) polygons** for the five territories — only the delegate districts they
  needed. Anything that maps territories at state level will still find nothing.
- PR's Resident Commissioner serves a **four-year** term (the only one); the others are two-year.
  Terms are open-ended here, so the 2026 general election will need the usual re-seating pass.
