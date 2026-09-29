# South Dakota Legislature portrait permission — email draft, 2026-09-28

## 🔴🔴 STATUS: **SENT 2026-09-28. DO NOT SEND IT AGAIN.**

Sent by Cantrell from `chris@empowered.vote` to `LRC@sdlegislature.gov`, with the signature
corrected to **Chris Cantrell / Empowered Vote** first (see the notes at the foot — this is
correspondence, not a legal form). **EVERY EARLIER LINE CALLING THIS LETTER "NOT SENT" IS
SUPERSEDED.** A second request would be a duplicate to a government body.

⚠ **The confirmation is the operator's word, not an in-page receipt.** North Dakota's request was a
web form and returned *"Thank you! Your request has been sent."* on screen; this is ordinary email,
so there is no such artifact and none should be claimed.

🔴 **NOTHING IS IMPORTED AND `photo_license` STAYS `unknown` ON ALL 105.** A sent request is not a
grant, and neither is silence. Only a reply moves that field, and only to what the reply says.

---

## 🟢 THE REPLY CAME, 2026-09-29. IT IS NOT A GRANT AND IT IS NOT A REFUSAL.

> On Tue, Sep 29, 2026, 10:59 AM LRC <lrc@sdlegislature.gov> wrote:
>
> **"You will need to ask each legislator individually as they are the ones who can grant
> permission for use."**

From the Council as a body. No named person, so **do not attribute this to an individual.**

🔴 **READ WHAT IT SAYS, NOT WHAT IT FEELS LIKE.** It is tempting to file this as "South Dakota said
no" — the first refusal of the programme — and an early draft of the site copy did exactly that.
The Council did not refuse. It said **it does not hold the right**, and the individual member does.
Those are different facts and only one of them is true:

| Tempting reading | What was actually written |
| --- | --- |
| "SD rejected us" | The LRC declined to grant *centrally*. |
| "SD has a blanket policy against press use" | No policy was stated. One member could say yes tomorrow. |
| "Leadership decided this" | The LRC is staff. It publishes the notice; it does not hold the copyright interest it points at. |

⚠ **What IS fairly said**: the LRC publishes the "Use by Permission Only" notice (see above), then
declines to act on it and moves 105 separate requests onto the person asking. Naming that as the
Council's decision is accurate. Calling it a refusal is not.

### What changed as a result

- **`photo_license` still does not move.** A routing is not a grant. It stays `unknown` on all 105.
- **`CC_0184`** adds `essentials.photo_restrictions` + `politicians.photo_restriction_code`, marks
  the 105, and stores the voter-facing explanation. 🔴 It writes **no** `photo_custom_url` — see
  that migration's header for why a placeholder in that column would corrupt coverage.
- **The site now explains itself** instead of showing an initials avatar that implies we never
  looked: a plain figure on the card, and the Council's own sequence of events above the group.

### 🔴 THE RESERVATION COVERS THE LEGISLATURE'S FILES, NOT THE MEMBERS' LIKENESSES

A separate, approved source needs nothing from the LRC. Measured on a pilot of 8 (2026-09-29),
**6 carried a Ballotpedia portrait** and 4 of the 5 compared were **plainly different
photographs** — different clothing, backdrop and sitting.

⚠ **BUT BALLOTPEDIA SOMETIMES REHOSTS THE RESERVED FILE.** Spencer Gosch's Ballotpedia portrait
**is** the Legislature's portrait, re-cropped — same backdrop, lapel pin, tie knot and expression.
At thumbnail size it reads as a different picture. So **"it is on Ballotpedia" does not make it
usable**; every candidate must be compared against
`lawmakerdocuments.blob.core.usgovcloudapi.net` before import.

⚠ **A crop-tolerant similarity scorer was written for this and DELETED.** Tested against the five
pilot pairs, it scored Gosch — the known same photo — at **0.47**, below pairs that are plainly
different. A detector that fails its control is worse than none, because its numbers look like
findings. The comparison is made by looking at a contact sheet.

⚠ **`PictureSmall` / `Picture` URLs contain RAW SPACES** (`.../sm_arlint, amber rep-6194 rt js.webp`).
`curl` rejects them unencoded — "URL rejected: Malformed input" — and in a loop that failure is
silent. It cost four of five pilot downloads. Percent-encode the path.

---

**Original draft note, 2026-09-28, kept verbatim.** All 105 South Dakota legislators are
seated in production (SD-2, 2026-09-28) from the Legislature's own public roster and session
journals, and **not one portrait has been copied, stored or displayed.**

▶ **THIS IS A DIFFERENT POSTURE FROM ND-5, KS-5 AND WICHITA, AND THE DIFFERENCE IS DELIBERATE**
(ruling, Cantrell, 2026-09-28). Those waves imported first and disclosed afterwards, because the
publisher's terms were **silent** — North Dakota's were found only later, in the body of a request
form. South Dakota is not silent. Every legislator profile page renders, immediately above the
member's details and attached to the portrait:

> Use by Permission Only.

An explicit reservation read *before* any use is not the same fact as silence, so the ND-5 posture
does not carry. We ask first.

⚠ **THE STRUCTURED FIELD IS EMPTY AND THE PAGE IS NOT.** `api/SessionMembers/Session/71` returns a
`PictureCopyright` and a `PictureSmallCopyright` field for every member, and **all 105 are null**,
while all 105 carry a live `Picture` URL on `lawmakerdocuments.blob.core.usgovcloudapi.net`. A
machine reading only the API would conclude there is no restriction. The notice exists **only as
rendered page text**, and it is a template element — confirmed on more than one profile, not a
one-off. ▶ **Read the page, not only the feed.**

## Who it goes to

| | | |
| --- | --- | --- |
| **To** | Legislative Research Council | `LRC@sdlegislature.gov` |
| | Capitol Building, 3rd Floor, 500 East Capitol Avenue, Pierre, SD 57501-5070 | (605) 773-3251 |

That is the address the LRC publishes on its own Contact Us page, and the LRC is the body whose
copyright notice appears on the site. No address here was constructed from a naming convention;
the staff listing publishes no individual mailbox for this, so the published desk is the correct
route rather than a guess at a named officer.

---

## The email

**Subject:** Permission request — South Dakota legislator portraits for a free civic lookup service

Dear Legislative Research Council,

I am writing to ask permission to display the official portraits of the 105 members of the 101st
South Dakota Legislature on Empowered Vote, a free, non-profit service that helps residents find out
who represents them.

Nothing has been copied or published. I am asking before any use, because each legislator's profile
page carries the notice "Use by Permission Only."

**What the service does.** A resident enters their address and sees the people who represent them —
their state senator, their two state representatives, their city council members and their county
commissioners — with each person's name, office and district. We have already built South Dakota's
legislative districts and seated all 105 members from your own published roster and from the House
and Senate journals of the 100th Session. The portrait is what lets a resident recognise the person
the page is describing.

**What I am asking for.** Permission to display each member's official portrait beside that member's
entry, and, if you would prefer we use them, any higher-resolution files or a specific credit line.
We will credit the Legislature in whatever form you specify, and we will remove any portrait on
request, without argument.

**One thing you should know before you decide.** Empowered Vote also publishes policy positions for
officials where we have researched them and can cite a source for each one — for example, how a
legislator has voted or what they have sponsored on a given issue. Those positions are claims about
the individual, and they sit on the same page as the portrait. We have not yet researched positions
for South Dakota legislators, but we expect to. I am telling you this before you answer so that your
decision about the photograph is an informed one.

**To be clear about scope:** a grant of permission to use the photograph is not an endorsement of
anything else on the page, and I would not represent it as one. It covers the portrait and nothing
else. Our editorial record stands or falls on its own sourcing, and is not something I am asking you
to approve.

If it would help, I am happy to send the list of the 105 members we have seated, or to answer any
question about how the images would be stored and served.

With thanks for your time,

Chris Cantrell
Empowered Vote
chris@empowered.vote

---

## Notes for whoever sends this

- ✅ **The signature was CORRECTED 2026-09-28 before sending.** The draft read "BJ Cantrell /
  Empowered Vote Inc". He goes by **Chris Cantrell**, and that is what **correspondence** says;
  **BJ Robert Cantrell** is the full legal name and is for **forms that demand one** — the North
  Dakota photo request was signed that way because it was a legal form. This is an email, so it
  takes the Wichita letter's form. Do not "make them consistent"; they differ on purpose.
- 🔴 **The compass disclosure is its own paragraph and it comes BEFORE the ask is closed out.** The
  standing rule: a sourced position is a claim about a real person, and a permission request that
  hides it is not an accurate request. *"An accurate form is worth more than a granted one."*
- 🔴 **The letter asks about the photograph and nothing else.** An earlier draft in the Wichita wave
  invited the publisher to say whether it would rather its portraits "did not appear beside that
  kind of content" — which hands a government a say over whether we cover its own elected officials.
  Do not reintroduce that.
- ⚠ **Do not claim a file size or format we have not measured.** North Dakota's natives were
  157x196; South Dakota's have not been measured, and the letter therefore asks what they have
  rather than asserting what we need.
- ⚠ **If the answer is no**, the fallback is NOT a news or campaign photograph. Those carry a
  stronger and more actively enforced copyright than a portrait a legislature publishes so residents
  can recognise a member. A refusal means South Dakota's legislators render without a portrait until
  something changes, and that is the honest outcome.
- ▶ **If the answer is yes**, record the grant, its scope and its date in `sd.md` and in the
  `politician_images` source line, the way MN-6's grant was recorded. A granted licence that nobody
  can find later is worth very little.
