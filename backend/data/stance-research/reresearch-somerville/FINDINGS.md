# Somerville MA — re-research of the 62 rows retired by migrations 1564/1565

**Date:** 2026-08-06 · **Outcome: 32 of 62 restored** by migration 1570. **30 stay blank.**
Full per-row reasoning lives in the migration header. This is the record of method and of what is owed.

## Why nothing was re-pointable

All 62 rows cited `somervillejournal.com` (the **eighth fabricated cluster**, retired by 1565), the
invented `somervillema.gov/city-council/members/<name>` scheme, or real city **programme pages that name
nobody** (`/somervision`, `/climate-forward`, `/office-immigrant-services-and-integration`,
`/somerville-heart-program`) — the attribute-prior class. The evidence base had to be rebuilt entirely.

## 🔴 The best evidence base in this workstream — and the path to it

`webapi.legistar.com/v1/somervillema` is **open, unauthenticated, and returns per-member roll calls by
name, including Nays.** That is qualitatively better than PDF minutes: no extraction step, no
column-alignment trap, and contested votes are visible.

⚠ **The obvious path fails.** `matters/{id}/histories` returns `[]` for every matter, exactly as in
Carson. There is no top-level `/eventitems` collection (404). The path that works:

```
events → events/{id}/eventitems → eventitems/{id}/votes      (match on EventItemMatterFile)
```

Harvested with `harvest-rollcalls.mjs`: **371 recorded roll calls, 2025-08-28 → 2026-07-27.**

⚠ **Many items are voice votes with no roll call. They are evidence of nothing either way.** Two
matters that look tailor-made for this cluster are voice votes and therefore unusable:
`24-1604` *"Reaffirming Somerville's commitment as a Sanctuary and Trust Act City"* and
`26-1041` *"In support of rent control negotiations…"*. **Rent Regulation is owed by five members and
stays blank for all five solely because of this.**

⚠ Name parsing: the API returned a councillor as `Jr.` (surname split on a suffix) — do not key member
matching on the last whitespace-delimited token.

## What the 32 rest on

| Topic | Rows | Basis |
|---|---|---|
| Local Immigration Enforcement | 10 | `26-0919` (2026-05-28) and `26-0522` (2026-07-09) — amendments to Section 2-6, the **Welcoming Communities Ordinance**, Somerville's sanctuary/Trust Act law, the second "to further enhance civil rights protections". All ten Aye on 26-0919. Reinforced by `26-1054`, $350,000 to Immigrant Legal Services, all Aye. |
| Affordable Housing | 9 | `26-1015` (2026-06-25) — **$1,000,000** from the Community Benefits Stabilization Fund into the Housing Assistance Stabilization Fund. |
| Public Safety Approach | 7 | The body-worn-camera and police-grant series — **the only contested votes in 371 roll calls**, which is exactly what makes them discriminating. |
| Civil Rights | 3 | `26-1135` (2026-06-25) — restore funding for cut positions in the **Racial and Social Justice Department**, all Aye. |
| Transportation Priorities | 3 | Blue Bike station appropriations `26-0270` / `26-0202` (March 2026). |

### The contested police record, which is what separates the members

Across 37 police/surveillance roll calls, nay counts among the ten:

| Member | Aye | Nay | Chair |
|---|---|---|---|
| Jon Link | 14 | **5** | 2 |
| Naima Sait | 32 | **4** | 2 |
| Wilfred N. Mbah | 19 | **3** | 2 |
| Ben Ewen-Campen | 34 | **2** | 2 |
| Kristen E. Strezo | 31 | **2** | 2 |
| Matthew McLaughlin | 36 | 0 | 3 |
| Lance L. Davis | 27 | 0 | 3 |

(J.T. Scott leads the Council with 8 nays but is **not owed** this topic.)

Ewen-Campen and Strezo are a distinct shape worth preserving: both **supported the body-worn-camera
grant and voted against the surveillance policy and impact report meant to govern it** — a vote for the
equipment and against its surveillance framework. Their stored reasoning says exactly that.

## 🔴 The 30 blanks

Residential Zoning 9 · Rent Regulation 5 · Env Protection vs Development 5 · Homelessness 3 ·
Deportation 2 · Climate Change 2 · Fossil Fuels 1 · Econ Dev Incentives 1 · Immigration 1 ·
Affordable Housing 1.

Two causes, both structural:

1. **Voice votes.** Somerville legislates heavily by voice vote; the position-bearing matters on rent
   control and sanctuary reaffirmation both went that way.
2. **Appointments and reports are not positions.** Most housing and climate roll calls are confirmations
   to the Affordable Housing Trust, Fair Housing Commission or Climate Action Commission, or receipt of
   reports. Confirming three trustees is not a housing stance.

🔴 **Matthew McLaughlin's Affordable Housing row is blank because he was ABSENT** for the $1,000,000
appropriation. His other housing votes are appointments and reports. Being absent is not a position —
the migration asserts this row cannot be created.

## Chip

Somerville's `hasContext` was never flipped (the city kept 8 answers after 1565). It remains **true**,
now correctly so: all ten councillors are back above zero.
