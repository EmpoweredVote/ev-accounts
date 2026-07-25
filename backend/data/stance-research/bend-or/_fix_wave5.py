#!/usr/bin/env python3
"""Validation fixes on the Chang + Adair agent output before pushing.

CHANG (5 -> 4 rows)
  * DROP residential-zoning=3 — axis mismatch. The evidence is county RURAL large-lot land use;
    the topic scale is about neighbourhood density/upzoning. The agent itself flagged it as lower
    confidence.
  * growth-and-development and housing: quotes EMPTIED. Both were the reporter's INDIRECT speech
    ("Chang said it is not just about building more housing but being intentional..."; "It's very
    difficult to build a house on a 2-acre lot and make it affordable, he said.") — no quotation
    marks in the source. Stances kept, substance moved into reasoning. This is the second time this
    defect appeared, despite an explicit warning in the prompt.
  * local-environment quote KEPT — it comes from a guest column he authored, so it is his own text.

ADAIR (11 -> 5 rows)
  * DROP abortion=4 — sourced to a 2022 vote on the COUNTY EMPLOYEE HEALTH PLAN's abortion
    exclusion. That is a benefits-coverage decision, not a position on legality, which is what the
    abortion scale measures. Publishing a legality chair for a congressional candidate off a
    coverage vote is a category error. No federal statement on abortion was found.
  * DROP medicare/aid=4 — single source is an opposition-leaning outlet describing her campaign
    account resharing other senators' posts. No first-person words, no vote.
  * DROP healthcare=4 — rests on a 2017 social-media line ("#repeal Obamacare. Now. Now. Now.")
    reported by that same outlet, plus reshares; the second source is her candidacy announcement,
    which is silent on healthcare. Nine-year-old evidence via a hostile intermediary is not enough
    for a live federal race, and chairs 4 vs 5 are arguable from it.
  * DROP climate-change=3 — the agent flagged it thin: a vague 2022 forum acknowledgement that
    doesn't locate a chair.
  * DROP homelessness-response=2 — no quote, 2022 forum, and chair 2 asserts a services-before-
    enforcement SEQUENCING she never states; her own campaign page's framing is enforcement-
    flavoured ("Fought the drug and homelessness crisis head-on").
  * DROP local-environment=3 — derived from the same Thornburgh resort vote already used for
    growth-and-development; an inference about environmental philosophy, not a stated position.
  * taxes=4 KEPT but re-quoted. The original quote ("one of the very highest tax states") is one she
    explicitly labels "a state issue". KLCC separately reports a concrete FEDERAL agenda — extending
    tax cuts for tips, overtime and social-security recipients — so the value stands on that.
  * deportation quote re-cut to the source's exact wording; voting-rights reasoning enriched with
    the two facts that pin the chair (she endorses photo ID, and explicitly says "I strongly
    support mail voting", which rules out chair 5).

Run: py data/stance-research/bend-or/_fix_wave5.py
"""
import json

CH = 'data/stance-research/bend-or/wave5-chang.json'
AD = 'data/stance-research/bend-or/wave5-adair.json'

# ---------------- Chang ----------------
rows = json.load(open(CH, encoding='utf-8'))
out = []
for r in rows:
    k = r['topic_key']
    if k == 'residential-zoning':
        print('DROPPED  Chang residential-zoning=3 — rural large-lot evidence vs a density scale')
        continue
    if k == 'growth-and-development':
        r['quote_text'] = ''
        r['reasoning'] = (
            "Bend Bulletin coverage of his 2020 commission run reports that he would make it a "
            "priority to encourage denser development on land still available inside the county's "
            "cities, and that growth should be 'intentional about where it goes' — the paper's "
            "indirect speech, so no verbatim quote is published. His own April 2026 guest column "
            "attacks converting farmland to rural residential as water-intensive. Directing growth "
            "to where services and water already exist is chair 2; chair 1's growth limits and "
            "annexation votes are absent, and chair 3's build-infrastructure-ahead framing is not "
            "what he argues."
        )
        print('EMPTIED  Chang growth quote (reporter indirect speech), reasoning rewritten')
    if k == 'housing':
        r['quote_text'] = ''
        r['reasoning'] = (
            "In the same 2020 Bend Bulletin piece he argues, in the paper's indirect speech, that "
            "it is very difficult to build a house on a 2-acre lot and make it affordable, and "
            "proposes that the county DONATE parcels it owns to cities for housing development. "
            "Public land contributed to affordable projects is targeted public help — chair 3 — "
            "rather than the county building and operating housing itself (1/2) or deregulating "
            "(4/5). No verbatim quote is published because the source paraphrases him."
        )
        print('EMPTIED  Chang housing quote (reporter indirect speech), reasoning rewritten')
    out.append(r)
json.dump(out, open(CH, 'w', encoding='utf-8'), indent=2, ensure_ascii=False)
print(f'  chang rows kept: {len(out)}\n')

# ---------------- Adair ----------------
DROP = {
    'abortion': 'county employee health-plan coverage vote is not a position on legality',
    'medicare/aid': 'opposition-outlet description of reshares; no first-person evidence',
    'healthcare': '2017 line via a hostile intermediary + reshares; chairs 4/5 arguable',
    'climate-change': 'vague 2022 forum acknowledgement; does not locate a chair',
    'homelessness-response': 'no quote; chair 2 asserts sequencing she never states',
    'local-environment': 'derived from the resort vote already used for growth; inference not position',
}
TAXES = (
    "CONGRESSIONAL campaign (May 2026). KLCC reports her campaign priorities include extending tax "
    "cuts for tips, overtime and recipients of social-security benefits — a concrete federal "
    "tax-cutting agenda, which is what places her at chair 4 rather than chair 3's keep-it-as-is. "
    "Caveat recorded: her 'highest tax states' remark is one she explicitly calls 'a state issue', "
    "so it is not used as the federal basis, and chair 4's 'scale back public services to match' is "
    "not something she says — she pairs the cuts with federal-debt discipline instead."
)
VOTING = (
    "CONGRESSIONAL campaign (2026 Oregon Capital Chronicle primary voter guide, asked directly about "
    "the SAVE Act). Two facts pin the chair: she endorses a photo-ID requirement ('an overwhelming "
    "majority of Americans... believe a photo ID should be required to vote'), and she explicitly "
    "says 'Oregon has been voting by mail for over 25 years, and I strongly support mail voting' — "
    "which rules out chair 5's elimination of mail voting. Standardised ID paired with preserved "
    "access is chair 3; chair 4 was not chosen because she proposes no voter-roll purges and leads "
    "with preserving access."
)
rows = json.load(open(AD, encoding='utf-8'))
out = []
for r in rows:
    k = r['topic_key']
    if k in DROP:
        print(f'DROPPED  Adair {k}={r["value"]} — {DROP[k]}')
        continue
    if k == 'taxes':
        r['reasoning'] = TAXES
        r['quote_text'] = ("The federal debt needs to be very closely monitored. We've got to leave "
                           "something for our next generation.")
        print('RE-QUOTED Adair taxes=4 to her federal-scope quote; reasoning rewritten')
    if k == 'voting-rights':
        r['reasoning'] = VOTING
        print('ENRICHED Adair voting-rights=3 reasoning (photo ID + pro-mail-voting)')
    if k == 'deportation':
        r['quote_text'] = ("violent criminals who are in this country illegally should not be "
                           "protected and released into our communities; they should be deported")
        print('RE-CUT   Adair deportation quote to the source\'s exact wording')
    out.append(r)
json.dump(out, open(AD, 'w', encoding='utf-8'), indent=2, ensure_ascii=False)
print(f'  adair rows kept: {len(out)}')
