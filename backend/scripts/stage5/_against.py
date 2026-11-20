"""A vote whose Yea is a vote against the bill: a Yea to accept a committee's Majority report that the bill Ought Not to
Pass (Maine, runner 2026-11-20: "Both, with the flag"). Maine's committees report out every bill, and accepting that report
kills the bill with no later vote on it, so the chamber's vote on it is its vote on the bill.

The finding keeps its literal act (the record says Yea, and legiscan_merge cross-checks the line's word against it) and
carries `against_bill: true`. Every tool that reads a Yea as support reads `act_for_bill(f)` instead. The motion's
wordings are the ones the Maine reader accepts (`meMajorityReport` in src/lib/stateRollCallEvidence.ts); stage5Prefill.ts
holds the same rule as `againstTheBill`.
"""
import re

# read with every space dropped and in lower case, as meMajorityReport reads it: the PDFs split words ("Accept M ajority")
HOUSE = re.compile(r'^acc(?:ept)?maj(?:ontp|otnp|oughtnottopass)(?:-a|-am|asamended)?(?:byca(?:-[a-z]|"[a-z]"))?(?:rep|rpt|report)?$')
SENATE = re.compile(r'^accept(?:ance)?majorityoughtnot(?:to)?pass(?:asamended(?:bycommitteeamendment"[a-z]")?)?(?:report)?(?:fromthecommitteeon[a-z,&\'’-]+)?$')


def against_the_bill(motion):
    m = re.sub(r'^(?:House|Senate) ', '', (motion or '').strip())  # convert.py writes the chamber first
    t = re.sub(r'\s+', '', re.sub(r'\([^)]*\)', ' ', m)).rstrip('.?').lower()
    return bool(HOUSE.match(t) or SENATE.match(t))


def act_for_bill(f):
    """The act as it bears on the bill: a Yea against the bill is a No, and a Nay on that motion a Yes."""
    a = f.get('act')
    if f.get('against_bill') and a in ('yea', 'nay'): return 'nay' if a == 'yea' else 'yea'
    return a


def act_words(f):
    """The act as printed, with what it means for the bill when the two differ."""
    return f"{f.get('act')} (a vote against the bill)" if f.get('against_bill') and f.get('act') in ('yea', 'nay') else f.get('act')
