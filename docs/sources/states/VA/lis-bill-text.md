---
profile: va-lis-bill-text
version: 1
scope: state:VA
body: legislature
match:
  url_prefixes:
    - https://legacylis.virginia.gov/cgi-bin/legp604.exe?131+ful+
    - https://legacylis.virginia.gov/cgi-bin/legp604.exe?201+ful+
    - https://legacylis.virginia.gov/cgi-bin/legp604.exe?221+ful+
    - https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+ful+
page_kind: bill-text
rules:
  vote_block: whole-page
  chamber: bill-origin
  name_format: surname
  amendment_text: marked
seat_titles:
  Senator: upper
  State Senator: upper
  Delegate: lower
  Representative: lower
  State Representative: lower
controls:
  - batch: 2026-10-22-shadow-vr-ioquinn
    snapshot: "b35a35c3"
    person: Israel D. O'Quinn
    office_title: Delegate
    instrument: HB 46 (2022)
    record_kind: vote
    provision_quote: "The State Board of Elections shall provide an ID-ONLY provisional ballot envelope that requires no follow-up action by the registrar or electoral board"
    expect: pass
---
# Virginia LIS — bill and chapter text (legacylis `+ful+`)

**Page:** `legacylis.virginia.gov/cgi-bin/legp604.exe?<session>+ful+<doc>`, where `<session>` is the
two-digit year plus a session digit (`131` = 2013 regular, `201` = 2020, `221` = 2022, `231` = 2023)
and `<doc>` is a chapter (`CHAP0725`), a bill as filed (`SB1256`, `HB1444`) or a substitute (`HB46H1`).
Fetchable by code. Add a session's prefix here when a batch first cites it.

**What it proves:** the provision (quote it as `provision_quote`). The page names no member who voted,
so it is never an actor page: pair it with the vote page (`+vot+`) in one record group.

**Amendment markup (`amendment_text: marked`):** an amending bill prints deleted Code text inside
`<s>` tags. Read as plain text, the deleted words run on with the kept ones — a coder sees "his
Commonwealth of Virginia voter registration card, his social security card, his valid Virginia
driver's license" as one list, when the first two were struck. The marked path (`htmlMarkedText`)
turns each `<s>` run into a `[deleted: …]` fence. Added text is underlined or italic in the HTML and
needs no fence. The page links an external stylesheet, so `amendment_markup` reads `unknown` and
CONFIRM fails closed with `amendment-markup-lost` on an amending page; the fences are still in the
coder's text. Send such a row to a person rather than loosen the rule.

**Traps:** a chapter page (`CHAPnnnn`) prints its bill number only as `[S 1256]` / `[H 19]`, which
the bill-number check does not read, so pair it with the `+sum+` page (which prints `SB 1256`). Cite the
version the vote was on. A House substitute (`HB46H1`) is the text of a House
passage vote; the chapter (`CHAPnnnn`) is the text of the final votes. The `+sum+` page is the bill's
history (which motion each vote was on), not its text.
