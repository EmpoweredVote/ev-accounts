# MS-5 — portrait permission request, Mississippi Legislature

**Status: DRAFT. NOT SENT.** Nothing goes to the Legislature until Cantrell approves the text and
the recipient. If this file ever says SENT, do not send it again — see the SD-5 precedent, where a
second copy of a pending letter was very nearly posted.

---

## What we are asking for, and why a letter is needed

The Legislature publishes a portrait for every sitting member at

```
https://billstatus.ls.state.ms.us/members/house/<name>.jpg
https://billstatus.ls.state.ms.us/members/senate/<name>.jpg
```

Measured 2026-09-28: **178 portraits, all present, typically 675×900** — larger than our 600×750
publishing size, so nothing would be upscaled. The filename comes from each member's own
`<IMG_NAME>` element in `members/{house,senate}/<slug>.xml`.

**There is no stated licence, in either direction.** The Legislature's own
`legislature.ms.gov/terms-and-conditions/` page has never been written: it still contains the
content-management system's placeholder text (*"This is an example of a general page. Aenean
ultricies mi vitae est… Lorem ipsum dolor sit amet…"*). So the page a reader would check for reuse
terms says nothing at all. Silence is not permission, which is exactly why this is a letter and not
an assumption.

This follows the shape that worked in Minnesota, where the House granted a blanket credit line for
133 portraits, and the one pending in South Dakota.

## Recipient

No email address is published for the Clerk of the House or the Secretary of the Senate. The
Legislature's own contact page lists exactly one address, for the office that operates the site
holding the files:

| route | detail | source |
| --- | --- | --- |
| **Email (primary)** | `webmaster@ls.ms.gov` | `legislature.ms.gov/contact/` — "For technical issues" |
| Phone (follow-up) | Legislative Reference Bureau, (601) 359-3135 | same page |
| Post | Mississippi State Capitol, 400 High Street, Jackson, MS 39201 | site footer |

▶ The webmaster runs the server the portraits sit on but may not be the officer who can grant
permission. The letter therefore asks to be redirected if that is the case, rather than assuming
the webmaster's silence or assent settles it.

## Disclosure — read this before editing the letter

The rule is that "no endorsement" scopes **the portrait only**, and anything else we publish about
the person gets its own disclosure ahead of the grant. Measured against production 2026-09-28:
**all 174 seated Mississippi legislators carry zero compass answers and zero reasoning rows.** We
publish no policy positions for any of them. The letter says that plainly and says what would
happen if it ever changed. Do not quietly drop that paragraph if stances are added later — update it.

---

## Letter

> **Subject:** Permission to display Mississippi legislator portraits on a nonpartisan voter guide
>
> To the Mississippi Legislature,
>
> I am writing to ask permission to copy and display the official portraits of sitting Mississippi
> legislators on Empowered Vote, a nonpartisan, free public service that helps people find out who
> represents them.
>
> **What we would use.** The 178 member portraits published at
> `billstatus.ls.state.ms.us/members/house/` and `.../members/senate/`, one per sitting member of
> the House and Senate. We would keep our own copy rather than link to yours, so that traffic from
> our site never falls on your servers.
>
> **Where it would appear.** A resident enters their address and sees the people who represent
> them. Each legislator appears as a portrait beside their name, chamber, district number and
> office. Nothing else is shown alongside the portrait.
>
> **What we do not publish about your members.** We record policy positions for some officials
> elsewhere in the country, always sourced to a specific bill, vote or public statement. **We
> currently hold no policy positions and no written assessments for any Mississippi legislator —
> none at all.** If we ever add them, each one would be sourced and attributed, and your granting
> permission for a portrait would not be an endorsement of that or of anything else we publish.
> This request covers the photographs and nothing more.
>
> **Credit.** We would credit the portraits however you prefer. A single line covering the whole
> set is easiest for us — for example "Mississippi Legislature" — and we would attach it to each
> record so the credit travels with the photograph wherever it is shown. If you would rather we
> credit a named photographer, or each chamber separately, tell us and we will do that instead.
>
> **We are not asking for exclusivity, and we claim nothing.** We would not resell the images or
> license them onward. If you later ask us to remove them, we will remove them and say so.
>
> **If you decline, that is a complete answer.** We would simply publish no portrait for
> Mississippi legislators. We would rather show a blank space than use a photograph we were not
> given permission to use.
>
> **One thing you may want to know either way.** Representative Grace Butler-Washington's member
> record points at `butler-washinton.jpg`, which returns a 404 — the file name in the record is
> missing an *n*. The photograph itself is on your server, at the correctly spelled
> `butler-washington.jpg`. Whatever you decide about our request, your own page for District 69 is
> likely showing a broken image.
>
> If permission is not yours to give, I would be grateful if you could tell me who to ask — the
> Clerk of the House, the Secretary of the Senate, or another office — and I will write to them
> instead.
>
> Thank you for your time.
>
> Chris Cantrell
> Empowered Vote
> chris@empowered.vote

---

## After it is sent

- [ ] Record the date sent and the exact address in this file, and in `ms.md`.
- [ ] Set `photo_license` to nothing and import nothing until a reply arrives. The 174 stay blank.
- [ ] On a grant: record the exact wording of the grant verbatim here. The credit goes in
      `politician_images.photo_license` on every row, so the obligation travels with the record
      instead of living in a planning file.
- [ ] On a refusal: the 174 stay blank permanently, and that fact gets written into `ms.md` so no
      later pass re-opens it.
- [ ] 🔴 **A grant is to us, not to the files.** Other publishers serving the same images are not
      covered by it, and neither is any other chamber or body.
