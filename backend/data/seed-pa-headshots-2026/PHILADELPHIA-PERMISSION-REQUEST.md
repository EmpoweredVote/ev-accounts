# Philadelphia portraits — permission request, and why PA-5 stopped at seven seats

**Status: OPEN. 7 seated Philadelphia officials carry no portrait, deliberately.**
Ruling: Cantrell, 2026-09-18 — **the refusal applies where it is published.** Record the debt, ask
for permission, ship everything else. This is MN-5's route, which MN-6 closed in a day when the
Minnesota House answered — see `backend/data/seed-mn-headshots-2026/HOUSE-PERMISSION-REQUEST.md`.

## The seven seats

| Office | Holder | Publisher of the portrait |
| --- | --- | --- |
| Mayor | Cherelle L. Parker | `phila.gov` |
| City Controller | Christy Brady | `controller.phila.gov` |
| District Attorney | Larry Krasner | `phillyda.org` |
| Register of Wills | John Sabatina | `phila.gov` |
| City Commissioner | Lisa Deeley | `vote.phila.gov` |
| City Commissioner | Omar Sabir | `vote.phila.gov` |
| City Commissioner | Seth Bluestein | `vote.phila.gov` |

⚠ **The Sheriff is NOT in this group.** Rochelle Bilal's portrait is published on
`phillysheriff.com`, which carries no site terms, so it ships on the same footing as Georgia's and
Florida's. It is owed as ordinary work, not as a licence debt. The 17 City Council members are a
third, separate case: `phlcouncil.com` carries no terms either, but the site publishes **no
systematic headshot** — member pages carry event photographs. That is a sourcing problem, not a
rights problem. **Four different problems; do not sum them.**

## What the City publishes, and what it forbids

Re-read live 2026-09-19 at <https://www.phila.gov/terms-of-use/>, under *Copyright, Trademarks and
Service marks*:

> All other design, information, text, graphics, images, pages, interfaces, links, software, and
> other items and materials contained in or displayed on this Website, and the selection and
> arrangements thereof, are the property of the City of Philadelphia. All rights are reserved.
> Permission is granted to residents and citizens of the City of Philadelphia to copy electronically
> and to print single pages from the Website for the sole purpose of sharing information on the
> Website with other citizens and residents, and on the condition that the pages are copied,
> printed, and shared without cost to the recipients and exactly as presented on the Website,
> without any addition or modification. **Distribution or republication in any other form or for any
> other purpose, including any commercial purpose or use, and any modification whatsoever, are
> strictly prohibited without the prior written permission of the City.**

`controller.phila.gov` repeats that clause verbatim. `phillyda.org` and `vote.phila.gov` link the
same page. So one grant, from the City, would cover all seven.

Two clauses bite, and the second is the one no workaround survives:

1. Republication in any other form requires **prior written permission**, and we do not have it.
2. **"Any modification whatsoever."** Our pipeline crops every portrait to a common 4:5 frame —
   that is what makes a wall of faces legible — so even a hotlink that avoided re-hosting would
   breach this clause the moment the crop is applied.

The narrow permission the page *does* grant — residents copying single pages, free, exactly as
presented — is not the use we make. We say so plainly below rather than argue our way into it.

## The request to send

### Where to send it — every address below was read off the City's own pages, 2026-09-19

**▶ TO: `CopyrightAgent@phila.gov`** — the City's **Designated Agent under the DMCA for phila.gov**,
Office of Innovation & Technology, 1234 Market Street, Philadelphia, PA 19107, (215) 686-8101.

🟢 **This address is published in Section IV(E) of the very page that carries the clause we need
waived** (<https://www.phila.gov/terms-of-use/>). It is the only copyright-specific contact the City
publishes anywhere, and OIT is the office that runs phila.gov. That makes it the best-evidenced
first address, not a guess.

⚠ **But read its remit honestly: a DMCA agent handles TAKEDOWNS, not licensing.** Expect the
request to be referred onward — so **ask for the referral explicitly in the first message**, which
the letter's closing paragraph already does. Do not read a referral as a refusal.

**Escalation, if that produces nothing:** the **Law Department**, 1515 Arch St., 17th Floor,
Philadelphia, PA 19102, **(215) 683-5000**. It is the office that would actually give "the prior
written permission of the City", and it is the body that wrote the terms of use.
⚠ **The Law Department publishes no email address** — verified, not assumed. It is a telephone
route, which is why it is second and not first.

**Copy each office that publishes one of the seven portraits.** Each one can speak for its own
image, and three of them are separately elected offices rather than parts of the administration:

| Seat | Portrait published on | Contact, as published |
| --- | --- | --- |
| Mayor Cherelle L. Parker | `phila.gov` | Web form at <https://www.phila.gov/contact/> · City Hall, Office 215 · (215) 686-2181. **No email published.** |
| Register of Wills John Sabatina | `phila.gov` | **`rowonline@phila.gov`** · City Hall Room 180 · (215) 686-2233 |
| City Controller Christy Brady | `controller.phila.gov` | **`controller@phila.gov`** · (215) 686-6680 |
| City Commissioner Lisa Deeley | `vote.phila.gov` | **`Lisa.Deeley@phila.gov`** |
| City Commissioner Omar Sabir | `vote.phila.gov` | **`Omar.Sabir@phila.gov`** |
| City Commissioner Seth Bluestein | `vote.phila.gov` | **`Seth.Bluestein@phila.gov`** |
| District Attorney Larry Krasner | `phillyda.org` | Contact form at <https://phillyda.org/contact/> · Three South Penn Square, Philadelphia, PA 19107 · 215-686-8000. **No email published.** |

⚠ **`phillyda.org` returns HTTP 403 to `curl` and to plain `fetch`, browser User-Agent or not.** It
answers normally in a real browser. If a later session reports that site as down, that is the WAF,
not an outage — and the DA's office publishes **no** general email, only the form. That was checked,
not assumed.

⚠ **Two of the seven have no email at all**, so the Mayor and the District Attorney reach us only
through a web form. Paste the letter into the form rather than shortening it: the disclosure bullets
are the part that must survive.

**Subject:** Permission to use official portraits of Philadelphia elected officials on a
non-commercial civic information site

> Empowered Vote is a non-profit civic information service. We publish a free, non-partisan
> directory that lets a resident enter an address and see every official who represents them, from
> their city council to Congress, each with a portrait so the person is recognisable.
>
> We have seated all 26 of Philadelphia's elected city and county offices, and the 253 members of
> the Pennsylvania General Assembly, on that directory. We would like permission to use the official
> portraits of seven Philadelphia officials, published on phila.gov, controller.phila.gov,
> phillyda.org and vote.phila.gov: Mayor Cherelle L. Parker, City Controller Christy Brady, District
> Attorney Larry Krasner, Register of Wills John Sabatina, and City Commissioners Lisa Deeley, Omar
> Sabir and Seth Bluestein.
>
> We are asking on these terms:
>
> - We would store our own copy rather than hotlink, so that our pages add no load to City servers
>   and do not break when files are re-organised.
> - We would crop each portrait to a common 4:5 frame, which is how they are displayed beside one
>   another. We understand the terms of use prohibit "any modification whatsoever", and **this is the
>   specific permission we are asking for.** No other editing is applied — no retouching, no
>   recolouring, and nothing that changes what the photograph depicts.
> - We would carry whatever credit you require, recorded with the image. If you can name the
>   photographer for each portrait, or give us a single credit that covers the set, we will use it.
> - The site is free to the public, carries no advertising and sells nothing.
> - **What sits beside the portrait, said plainly now rather than discovered later.** Alongside the
>   office and the term, we publish the official's positions on policy topics wherever we can
>   evidence them — each one a specific stated position, with the bill, the vote or the quotation we
>   drew it from cited next to it, so a reader can check our work. We do not publish a position we
>   cannot cite, we do not infer one from party membership, and we correct what we get wrong. So the
>   portrait does appear beside a page that asserts what we have found this official's positions to
>   be. We would rather you weighed that before granting permission than met it afterwards, and we
>   are glad to show you the live record for any of the seven first.
> - **The portrait itself is never used as a mark of approval.** It identifies the person, and
>   nothing on the site suggests that the City, this official or City staff endorse Empowered Vote,
>   or any candidate, party, campaign, product or cause. That is the only sense in which we say the
>   image carries no endorsement — it is not a claim that the page beside it is silent about the
>   official's own positions, because it is not.
>
> We are writing to you because yours is the copyright contact the City publishes on its terms-of-use
> page. We understand that a designated agent's role is takedown notices rather than licensing, so if
> this belongs with another office — the Law Department, or each official's own staff — **we would be
> grateful if you would tell us which, and we will write to them instead.** A pointer is as useful to
> us as an answer.
>
> If a blanket permission is not possible, we would also welcome any alternative you prefer: an
> uncropped display, a different credit, or a different source file.

## 🔴 "No endorsement" means the PORTRAIT, not the page — say both

Ruling (Cantrell, 2026-09-19), on reading the draft. The inherited MN sentence — *"never in a way
that suggests the City, its officials or its staff endorse anything"* — is true of the **image** and
misleading about the **site**. A sourced compass is exactly a visual assertion of what a politician
holds: a 4 on abortion is a claim about that person, shown with the evidence behind it. Someone
granting permission on the strength of that one sentence could reasonably feel they had not been
told.

So the request now carries **two separate bullets**, and any future one must too:

1. **Disclose the positions.** The record beside the portrait states what we found this official's
   positions to be, each cited. Say it before the grant, not after.
2. **Scope the endorsement clause to the image.** The portrait is not a mark of approval for
   Empowered Vote or for any candidate, party, product or cause — and say explicitly that this is
   *not* a claim the surrounding page is silent about the official's own positions.

⚠ **The Minnesota House granted on the OLD wording** (Mike Cook, 2026-09-17), which carried the
single ambiguous sentence. **Ruling (Cantrell, 2026-09-19): leave Minnesota alone — no follow-up,
no re-approach.** That grant stands, the work shipped, and nothing was misrepresented that a visitor
to the site could not see at once. It is recorded here so the thinner disclosure is on the record
rather than quietly overwritten, and so **this** letter's shape is what the next one inherits.

## Until a reply arrives

- The seven seats stay **blank**. A blank is honest; a portrait we have no right to crop is not.
- **Do not** substitute a copy from a news site, a campaign site or a social account. A different
  publisher is a different rights question, and press and campaign images are not ours either.
- **Do not** hotlink as a workaround. It dodges the hosting question and still breaches the
  no-modification clause, and it re-creates the hotlink defect CC_0019 removed.
- **Do not read the Sheriff's shipped portrait as precedent for these seven.** Different publisher,
  different terms, and that is the whole ruling.
- A per-person hunt on Wikimedia Commons is the fallback if permission is refused. Measure the yield
  before spending time on it: Minnesota's equivalent was about 11%.

## If it is granted

Record the grant **verbatim**, with the grantor's name and the date, in this file and in the
migration that writes the URLs — the way MN-6 recorded Mike Cook's answer.
🔴 **A grant is to us, not to the files.** A later session must not read "Philadelphia portraits are
fine" as a property of the image. Anyone else copying them is in exactly the position we are in now.
