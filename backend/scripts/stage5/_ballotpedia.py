"""Ballotpedia is a source only for a Candidate Connection survey answer, cited as its #Campaign_themes deep link
(ruling 2026-11-02, Chris Andrews). Any other Ballotpedia page (bio, election, measure, Ballotpedia News) is a lead,
never a source_url or an evidence row, blanks included; the stance gate refuses it (ballotpedia-non-survey)."""
import re


def ballotpedia_non_survey(url):
    m = re.match(r'https?://([^/#?]+)', (url or '').strip(), re.I)
    return bool(m) and re.search(r'(^|\.)ballotpedia\.org$', m.group(1), re.I) is not None and '#Campaign_themes' not in url
