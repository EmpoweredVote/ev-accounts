---
profile: az-azleg-bill-text
version: 2
scope: state:AZ
body: legislature
match:
  url_prefixes:
    - https://www.azleg.gov/legtext/
page_kind: bill-text
rules:
  vote_block: whole-page
  chamber: bill-origin
  name_format: surname
  amendment_text: marked
seat_titles:
  Senator: upper
  State Senator: upper
  Representative: lower
  State Representative: lower
controls:
  - batch: 2026-09-26-shadow-gowan
    snapshot: "dcb501dd"
    person: David Gowan
    office_title: State Senator
    instrument: HB 2552 (2023)
    record_kind: vote
    provision_quote: "This state or a city, town, county or political subdivision of this state may not use any of the following voting methods"
    expect: pass
---
# Arizona Legislature — bill text (azleg legtext)

**Page:** `www.azleg.gov/legtext/<leg>leg/<session>/bills/<BILL><version>.htm` (also `.pdf`). The `.htm`
version is fetchable by code. Versions: `H` = House engrossed, `S` = Senate engrossed, and so on.

**What it proves:** the provision (quote it as `provision_quote`). The page names **no member**, so it
is never an actor page: pair it with the roll call (`azleg-bill-status`) in one record group.

**Traps:** cite the version the vote was on (the engrossed version of the chamber that voted), not a
later amended one.

**Amendment markup (`amendment_text: marked`):** an amending bill's `.htm` page strikes through deleted
text in the HTML; the snapshot path (`htmlToMarkedText`) turns each struck run into a `[deleted: …]`
fence. Added text prints in CAPITALS and needs no fence — it is the law. A page with only additions and
no deletions carries no fence at all, so CONFIRM cannot tell "no deletions on this page" from "a
deletion the fence-writer missed" — it reads `amendment_markup: 'unknown'` and, on a page that also says
"is amended to read," fails closed with `amendment-markup-lost`. That is a known false positive on an
additions-only amendment; send it to a person rather than loosen the rule.
