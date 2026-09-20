# Minnesota House portraits — permission request, and why MN-5 stopped

**Status: OPEN. 133 seated House members carry no portrait, deliberately.**
Decision: Cantrell, 2026-09-16 — record the debt, ask for permission, ship everything else.

## What the House publishes, and what it forbids

Every member's profile page carries an official portrait at
`https://www.house.mn.gov/hinfo/memberimgls94/<district>.gif` — 525x675, one per district, and the
page's `alt` names the member. As a source it is ideal: complete, consistent, and the chamber's own.

The *Photo and Digital Image Use Policy* (updated 2024-10-23,
<https://www.house.mn.gov/hinfo/photo_use.htm>) refuses the use this programme makes of it:

> The House retains copyright in perpetuity to its photographs and digital still images.
> Permission to use a photograph or digital image must be obtained in advance from House Public
> Information Services. The following credits must be used: Copyright Minnesota House of
> Representatives. Photo by (insert photographer's name). **A photograph or image may not be
> digitally altered in any way, including cropping.** A photograph may not be sold for for-profit
> purposes, including use on a website or printed materials.

Three clauses bite, and the second is the one no workaround survives:

1. Permission is required **in advance**, and we do not have it.
2. **No cropping.** Our pipeline crops every portrait to 4:5 — that is what makes a wall of faces
   legible — so even a hotlink that avoided re-hosting would still breach this clause the moment the
   crop is applied.
3. No use "on a website" for for-profit purposes.

Spec §7.1 already answers this: *a photographer's copyright is a refusal*. The Georgia and Florida
chambers carry no comparable policy, which is why GA-6 and FL-7 could import 233 and 159 portraits
without this question arising. **Minnesota is the first chamber in the programme to publish one.**

⚠ **The Senate is a different question and was answered separately.** It publishes no photo policy;
its portraits are 1200x1500 and carry a photographer's initials in EXIF but no rights statement. The
67 Senate portraits shipped as `press_use`, the same treatment Georgia's 233 had.

## The request to send

To: House Public Information Services — 651-296-1341 (the policy page names Mike Cook)
Subject: Permission to use Minnesota House member portraits on a non-commercial civic information site

> Empowered Vote is a non-profit civic information service. We publish a free, non-partisan directory
> that lets a resident enter an address and see every official who represents them, from their city
> council to Congress, each with a portrait so the person is recognisable.
>
> We would like permission to use the official member portraits published at
> house.mn.gov/hinfo/memberimgls94/ for the 134 members of the Minnesota House, on these terms:
>
> - We would store our own copy rather than hotlink, so that our pages do not add load to House
>   servers and do not break when files are re-organised.
> - We would crop each portrait to a common 4:5 frame, which is how they are displayed beside one
>   another. We understand the policy forbids alteration including cropping, and this is the specific
>   permission we are asking for. No other editing is applied — no retouching, no recolouring, and
>   nothing that changes what the photograph depicts.
> - We would carry the credit the policy requires: "Copyright Minnesota House of Representatives.
>   Photo by (photographer)". If you can tell us the photographer for each portrait, or a single
>   credit that covers the set, we will record it with the image.
> - The site is free to the public, carries no advertising and sells nothing. Portraits would appear
>   only beside the member's own record, never in a way that suggests the House, its members or its
>   staff endorse anything.

>
> If a blanket permission is not possible, we would welcome any alternative you prefer — an
> uncropped display, a different credit, or a different source file.


## 🔴 THIS LETTER'S "no endorsement" SENTENCE IS SUPERSEDED — DO NOT COPY IT FORWARD

Correction 2026-09-19, made while drafting the Philadelphia request from this template.

The sentence *"never in a way that suggests the House, its members or its staff endorse anything"*
is true of the **photograph** and misleading about the **site**. A sourced compass is precisely a
visual assertion of what a politician holds — a 4 on abortion is a claim about that person, shown
with its evidence. A grantor reading only that sentence could reasonably feel they had not been
told.

The corrected shape splits it in two, and every future request must carry both:

1. **Disclose the positions** — the record beside the portrait states what we found this official's
   positions to be, each one cited. Said before the grant, not after.
2. **Scope the endorsement clause to the image** — the portrait is not a mark of approval for
   Empowered Vote or for any candidate, party, product or cause, and say explicitly that this is
   *not* a claim the surrounding page is silent about the official's own positions.

Worked example: `backend/data/seed-pa-headshots-2026/PHILADELPHIA-PERMISSION-REQUEST.md`.

⚠ **Mike Cook's grant (2026-09-17) was given against the wording above, and it stands.** Nothing was
misrepresented that a visitor to the site could not see at once, and MN-6 shipped on it. This note
exists so the thinner disclosure is on the record rather than quietly overwritten, and so the next
letter inherits the corrected version. A short follow-up note to Mr Cook is available if wanted.

## Until a reply arrives

- The 133 House seats stay **blank**. A blank is honest; a portrait we have no right to crop is not.
- **Do not** substitute Open States: its MN House images are the same `house.mn.gov` files under the
  same copyright, re-pointed rather than re-licensed.
- **Do not** hotlink as a workaround. It dodges the hosting clause and still breaches the no-cropping
  clause, and it re-creates the hotlink defect CC_0019 removed.
- A per-member hunt is the fallback if permission is refused. It is expensive and partial: of all
  people Wikidata records as Minnesota House members, only about 11% carry a freely-licensed image
  (Senate 21%), measured 2026-09-16.
