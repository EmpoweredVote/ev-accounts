# Indio, CA — deep seed (city, Desert Sands USD, Coachella Valley USD)

Compiled **2026-11-27**. Migrations `CC_0523`–`CC_0526`, all applied to production on 2026-11-28.

## What was already there

The City of Indio and its five by-district council seats (X0023 `indio-ca-council-district-1..5`), all held
and all matching the city's roster. Each had a photo; the photos are crops of the city's current official
portraits, but carried an unsupported `us_government_work` licence and no origin page. No Clerk, no Treasurer,
no races, and **no school board at all** for either district that serves Indio.

## Seats after this pass

| Body | Seats | Geography | Source |
|---|---|---|---|
| City Council | 5 (unchanged) | X0023 council districts | indio.org roster; 2025-12-05 reorganization notice |
| City Clerk | 1 — Cynthia Hernandez | city outline (G4110 `0636448`) | indio.org "Other Elected Officials" |
| City Treasurer | 1 — Rob Rockwell | city outline | same |
| Desert Sands USD | 5 — Watson (1), Alvarez (2), Pearce (3), Porras (4), Duran (5) | **X0002 trustee areas `0611110-ta-1..5`** | dsusd.us board page; district's own 2022 trustee map |
| Coachella Valley USD | 7 — García, Arredondo, Acuña Jr. (Area 1); Callimanis, Gonzalez (2); Tortez (3); Vargas (4) | whole district (G5420 `0609070`) | cvusd.us/trustees |

Indio falls in DSUSD Trustee Areas 2, 3, 4 and 5 (City Hall is in Area 4), and its southern edge is in CVUSD
(all of that part in CVUSD Trustee Area 1).

## Handovers written (incoming holders)

- **Indio D4: Felipe Ortiz from 2026-12-02**, replacing Oscar Ortiz (did not run). Ortiz 2,147 v Becerra 1,208.
  The date is the council meeting where the oath is on the agenda (item 13.2, agenda of 2026-12-02).
- **CVUSD Area 1: Loretta Perez from 2026-12-11**, replacing Joey Acuña Jr. (did not file). Term start fixed by
  Ed. Code 5017(a) (second Friday in December).
- Re-elected, no change: Fermon (D2, 1,935 v 1,892), Holmes (D3), García (CVUSD Area 1).

## Sources (all read 2026-11-27)

- indio.org council, staff-directory, "Other Elected Officials" and Clerk pages (Akamai blocks curl; read with
  headless Chrome).
- City of Indio, Notice of City Council Reorganization, 2025-12-05 (indio.org showpublisheddocument 6316).
- Indio City Council agenda packet, 2026-12-02 (indio.civicweb.net document 200455): items 6.2, 13.1
  (Resolution No. 10617 with the certified figures), 13.2, 14.1.
- Riverside County ROV: final candidate list, Nov 3 2026 (printed 2026-09-11); results, update #27 (2026-11-25).
- dsusd.us board members page; DSUSD trustee-area map (Google My Maps KML, "Approved January 18, 2022") —
  `dsusd-trustee-areas-2022.kml`, converted to `dsusd-trustee-areas.geojson`.
- cvusd.us/trustees and /trustee-area-boundaries (map published as an image only).
- Felipe Ortiz headshot: ortizforindio.com; identity cross-checked against the captioned campaign banner in
  Greater Palm Springs Business Insider, 2026-05-15.

Processed headshots are in `headshots/`.

## Open items (dated)

1. **After 2026-12-02** — read the minutes: confirm Felipe Ortiz's oath date, and retitle the D2/D3 offices
   ("Mayor", "Mayor Pro Tem") to whoever the rotation (Resolution No. 9507, item 14.1) names.
2. **After 2026-12-15** — confirm DSUSD Areas 2 and 5 (Alvarez, Duran) at DSUSD's Annual Organizational Meeting
   (2026-12-15). Neither was on the ballot: the Desert Sun (2026-08-14, "See who's running for school boards across
   Coachella Valley") says "Neither candidate faces an opponent", but no reachable source names the two filers.
   Searched 2026-11-28 and NOT found in: the ROV's final candidate list and its 2026-08-31 proof list (both print
   on-ballot contests only); the county election calendar in Board of Supervisors item 2.15 of 2026-09-22 (lists the
   seats, no names); the supervisors' proceedings Aug 25 – Nov 3 (no in-lieu appointment yet — Ed. Code 5326 puts it
   just before December); DSUSD's old agenda portal (ends 2022). ▶ Next places: the supervisors' first December
   agenda (rivcocob.org/2026-agendas-and-proceedings), and DSUSD's 2026-12-15 agenda on Simbli.
   ✅ **CVUSD Area 2 is CONFIRMED**: the Desert Sun's election report (updated 2026-11-06, "Newcomers hold early leads
   in Coachella Valley school board races") says Callimanis "ran unopposed" and "is set to serve her first full
   four-year term representing Trustee Area 2". Nothing to change.
3. **CVUSD trustee areas** — every CVUSD address currently sees all seven trustees. Get polygons (district GIS,
   or union the ROV's precinct-level statement of votes for "Mbr Gov Bd Coachella Valley USD, TA 1") and repoint
   to X0002 `0609070-ta-N`, as `CC_0519` did for Fremont.
4. **DSUSD photos are x6 upscales** of 100x127 thumbnails — the only size the district publishes. Replace when
   larger ones are found. No photo yet for Loretta Perez.
5. **Stances** — no stance research was run in this pass.
