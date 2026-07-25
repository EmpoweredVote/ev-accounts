#!/usr/bin/env py
"""
Validate a Bend-OR stance payload BEFORE pushing it.

Two passes:
  1. STRUCTURAL — keys present, value in 1-5, >=1 source, non-empty reasoning,
     external_id in the allowed roster, topic_key in the allowed topic set.
  2. QUOTE MATCH — re-fetch every source and confirm quote_text is actually a
     substring of the page. This is the pass that caught 14 bad rows in waves 2-5.

Match tiers, reported per row:
  EXACT      quote appears verbatim in the fetched text
  NORMALIZED appears after collapsing whitespace + normalizing dashes/quotes
             (a real earlier case: the source literally prints "net-zero -energy",
             so a MISSING is sometimes a source typo, not a fabrication)
  PARTIAL    a long run of the quote appears; likely truncation or a splice —
             INSPECT, do not auto-trust
  MISSING    not found in any source — treat as fabricated until proven otherwise

Usage:
  py scripts/validate-stance-quotes.py wave6-park.json [more.json ...]
  py scripts/validate-stance-quotes.py path/to/other-wave.json
  (run from backend/; bare names resolve against data/stance-research/bend-or/,
   fetched pages cache to that dir's .qcache/)

ROSTER and ALLOWED_TOPICS below are per-wave guards — update them for a new
cohort, or every row will (correctly) fail the roster/topic scope check.

TWO THINGS THIS CANNOT CHECK — do them by hand:
  1. Attribution. An exact match ANYWHERE in a multi-column voters' pamphlet does
     not prove the quote is that candidate's. Check the hit's position against the
     "(This information furnished by X.)" delimiters.
  2. The `reasoning` field. Only `quote_text` is string-matched, so indirect
     speech dressed up in quotation marks hides in `reasoning`.
"""
import json
import sys
import re
import os
import hashlib
import unicodedata
import urllib.request
import urllib.error

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# Default payload location; override per-invocation by passing a path that
# exists relative to the cwd, or an absolute path.
DIR = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "data", "stance-research",
                                   "bend-or"))
CACHE = os.path.join(DIR, ".qcache")


def resolve_payload(name: str) -> str:
    """Absolute path wins; then cwd-relative; then the default payload dir."""
    if os.path.isabs(name):
        return name
    if os.path.exists(name):
        return os.path.abspath(name)
    return os.path.join(DIR, name)
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/126.0 Safari/537.36")

ROSTER = {
    # --- wave 6: Bend-La Pine school board ---
    -4101981: "Jenn Lynch", -4101982: "Marcus LeGrand", -4101983: "Cameron Fischer",
    -4101984: "Shirley Olson", -4101985: "Amy Tatom", -4101986: "Ross Tomlin",
    -4101987: "Kina Chadwick",
    # --- wave 6: Bend Metro Park & Recreation District board ---
    -4105821: "Cary Schneider", -4105822: "Deb Schoen", -4105823: "Nathan Hovekamp",
    -4105824: "Jodie Schiffman", -4105825: "Donna Owens",
    # --- wave 7: Oregon state-leg, Bend ballot (party-prior remediation) ---
    -4120053: "Emerson Levy", -4120054: "Jason Kropf", -4110027: "Anthony Broadman",
    -4129001: "Michael Summers",
}

# Earliest session a member could possibly have voted in, from their verified
# term_start. A row citing an earlier session is FABRICATED no matter how real
# the URL is — this is how the party-prior seed slipped past every presence
# check (7 of its 8 bill-cited rows attributed pre-seating votes).
SEATED = {
    -4120053: (2023, "Emerson Levy seated 2023-01-09"),
    -4120054: (2021, "Jason Kropf seated 2021-01-11"),
    -4110027: (2025, "Anthony Broadman seated in the SENATE 2025-01-13 "
                     "(his Jan-2021 term was Bend City Council)"),
}
# Matches OLIS session codes in a URL or in prose: 2023R1, 2024R1, 2019S1 ...
SESSION_RE = re.compile(r"\b(19|20)(\d{2})\s?([RS])(\d)\b")

ALLOWED_TOPICS = {
    # wave 6 (local boards)
    "school-vouchers", "childcare", "civil-rights", "trans-athletes", "taxes",
    "local-environment", "growth-and-development", "climate-change",
    # wave 7 (state legislature)
    "abortion", "healthcare", "housing", "rent-regulation", "residential-zoning",
    "fossil-fuels", "homelessness", "homelessness-response",
    "public-safety-approach", "jail-capacity", "local-immigration",
    "transportation-priorities", "economic-development", "voting-rights",
    "redistricting", "campaign-finance", "data-centers",
}

REQUIRED_KEYS = {"external_id", "name", "topic_key", "value", "reasoning",
                 "sources", "quote_text"}


def norm(s: str) -> str:
    """Aggressive normalization for tier-2 matching."""
    s = unicodedata.normalize("NFKD", s)
    # unify dashes and quotes
    s = re.sub(r"[‐-―−\-]+", "-", s)
    s = re.sub(r"[‘’ʼ`']", "'", s)
    s = re.sub(r"[“”\"]", '"', s)
    s = s.replace(" ", " ")
    s = s.lower()
    # collapse all whitespace AND drop spaces around hyphens, so
    # "net-zero -energy" == "net-zero energy" == "netzeroenergy"-ish
    s = re.sub(r"\s*-\s*", "-", s)
    s = re.sub(r"\s+", " ", s)
    return s.strip()


def strip_html(html: str) -> str:
    # Only de-tag things that are actually HTML. PDF-extracted text can contain
    # bare '<' / '>' and tag-stripping it would silently delete real content.
    if "</" not in html[:200000]:
        return html
    html = re.sub(r"(?is)<(script|style|noscript)[^>]*>.*?</\1>", " ", html)
    html = re.sub(r"(?s)<!--.*?-->", " ", html)
    html = re.sub(r"(?s)<[^>]+>", " ", html)
    for ent, ch in (("&nbsp;", " "), ("&amp;", "&"), ("&quot;", '"'),
                    ("&#39;", "'"), ("&rsquo;", "’"), ("&lsquo;", "‘"),
                    ("&ldquo;", "“"), ("&rdquo;", "”"),
                    ("&mdash;", "—"), ("&ndash;", "–"), ("&lt;", "<"),
                    ("&gt;", ">")):
        html = html.replace(ent, ch)
    html = re.sub(r"&#x?[0-9a-fA-F]+;", " ", html)
    return html


PDFTOTEXT = r"C:\Program Files\Git\mingw64\bin\pdftotext.exe"
if not os.path.exists(PDFTOTEXT):
    PDFTOTEXT = "pdftotext"


def _pdf_to_text(raw: bytes) -> str:
    """
    BoardBook minutes and county voters' pamphlets are PDFs. Extract BOTH the
    default and the -layout rendition and concatenate: -layout preserves
    columns (needed for the two-column pamphlet) but letter-spacing in the
    pamphlet corrupts words under -layout, while the default flow reads them
    cleanly. Searching the union avoids blaming an agent for an extractor bug.
    """
    import subprocess
    import tempfile
    out = []
    with tempfile.TemporaryDirectory() as td:
        pdf = os.path.join(td, "in.pdf")
        with open(pdf, "wb") as f:
            f.write(raw)
        for args in ([], ["-layout"]):
            try:
                res = subprocess.run(
                    [PDFTOTEXT, *args, pdf, "-"],
                    capture_output=True, timeout=120)
                out.append(res.stdout.decode("utf-8", errors="replace"))
            except Exception:
                pass
    return "\n\n".join(out)


def _docx_to_text(raw: bytes) -> str:
    """BPRD publishes board summaries as .docx. Pull the paragraph text out."""
    import io
    import zipfile
    try:
        with zipfile.ZipFile(io.BytesIO(raw)) as z:
            parts = [n for n in z.namelist()
                     if n.startswith("word/") and n.endswith(".xml")]
            chunks = []
            for n in sorted(parts):
                xml = z.read(n).decode("utf-8", errors="replace")
                # paragraph + tab + break boundaries become whitespace
                xml = re.sub(r"(?i)</w:p>|<w:br/?>|</w:tr>", "\n", xml)
                xml = re.sub(r"(?i)<w:tab/?>", "\t", xml)
                chunks.append(re.sub(r"(?s)<[^>]+>", "", xml))
            return "\n".join(chunks)
    except Exception:
        return ""


def _get(url: str, timeout: int = 45) -> str:
    headers = {
        "User-Agent": UA,
        "Accept": "text/html,application/xhtml+xml,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
    }
    if url.startswith("https://r.jina.ai/"):
        # Without this, r.jina.ai can return HTTP 200 with an EMPTY body for
        # 403-walled origins (bendoregon.gov) — a silent failure that reads as
        # success and would turn a good quote into a false MISSING.
        headers["x-no-cache"] = "true"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
    if raw[:5] == b"%PDF-" or raw[:1024].lstrip()[:5] == b"%PDF-":
        return _pdf_to_text(raw)
    if raw[:2] == b"PK" and b"word/" in raw[:8000]:
        return _docx_to_text(raw)
    return raw.decode("utf-8", errors="replace")


def _cached(url: str, variant: str) -> str | None:
    key = hashlib.sha256((variant + "|" + url).encode()).hexdigest()[:20]
    path = os.path.join(CACHE, f"{variant}-{key}.txt")
    if os.path.exists(path) and os.path.getsize(path) > 0:
        with open(path, encoding="utf-8") as f:
            return f.read()
    return None


def _store(url: str, variant: str, text: str) -> None:
    os.makedirs(CACHE, exist_ok=True)
    key = hashlib.sha256((variant + "|" + url).encode()).hexdigest()[:20]
    with open(os.path.join(CACHE, f"{variant}-{key}.txt"), "w",
              encoding="utf-8") as f:
        f.write(text)


def fetch_variants(url: str) -> list[tuple[str, str]]:
    """
    Return every text rendition of `url` we can get: the direct HTML AND the
    r.jina.ai rendition. We search BOTH rather than picking one, because a
    direct fetch often succeeds while silently returning only nav + headline
    (opb.org does exactly this — 2 KB of chrome, article body loaded by JS),
    which would make a perfectly good quote look fabricated.
    """
    os.makedirs(CACHE, exist_ok=True)
    out: list[tuple[str, str]] = []

    hit = _cached(url, "direct")
    if hit is not None:
        out.append((hit, "direct/cache"))
    else:
        try:
            t = strip_html(_get(url))
            _store(url, "direct", t)
            out.append((t, "direct"))
        except Exception as e:
            out.append(("", f"direct-failed({type(e).__name__})"))

    hit = _cached(url, "jina")
    if hit is not None:
        out.append((hit, "jina/cache"))
    else:
        try:
            t = _get("https://r.jina.ai/" + url, timeout=75)
            _store(url, "jina", t)
            out.append((t, "jina"))
        except Exception as e:
            out.append(("", f"jina-failed({type(e).__name__})"))

    return out


# Markers that a fetch returned a wall/shell rather than the content.
WALL_RE = re.compile(
    r"(?i)(subscribe to (?:continue|read)|already a subscriber|"
    r"you have reached your (?:article|free) limit|"
    r"enable javascript|checking your browser|access denied|"
    r"are you a robot|unusual traffic|cloudflare|"
    r"attention required|403 forbidden|please verify you are a human)")


def looks_substantive(text: str) -> bool:
    """A page we can trust a negative result from."""
    t = text.strip()
    # A machine-readable API response is fully substantive even when short —
    # OLIS OData roll-call queries return a few hundred bytes of real JSON, and
    # judging them by length flags the single best kind of source as a "shell".
    if t[:1] in "[{" and ('"value"' in t[:400] or t.endswith(("}", "]"))):
        try:
            json.loads(t)
            return True
        except Exception:
            pass
    if len(t) < 2500:
        return False
    if WALL_RE.search(t[:4000]) and len(t) < 8000:
        return False
    return True


def longest_run(needle_n: str, hay_n: str) -> int:
    """Longest prefix-anchored run of needle words found in hay (word count)."""
    words = needle_n.split()
    best = 0
    for start in range(len(words)):
        lo, hi = 0, len(words) - start
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if " ".join(words[start:start + mid]) in hay_n:
                lo = mid
            else:
                hi = mid - 1
        best = max(best, lo)
    return best


def main(files: list[str]) -> int:
    problems, checked, quoted = [], 0, 0
    tally: dict[str, int] = {}

    for fname in files:
        fpath = resolve_payload(fname)
        print(f"\n{'='*78}\nPAYLOAD  {os.path.basename(fpath)}\n{'='*78}")
        with open(fpath, encoding="utf-8") as f:
            rows = json.load(f)

        by_person: dict[str, int] = {}
        for i, r in enumerate(rows):
            checked += 1
            tag = f"{r.get('name','?')}/{r.get('topic_key','?')}"
            by_person[r.get("name", "?")] = by_person.get(r.get("name", "?"), 0) + 1

            # ---- pass 1: structural ----
            missing_keys = REQUIRED_KEYS - set(r)
            if missing_keys:
                problems.append(f"[SCHEMA] row {i} {tag}: missing keys {sorted(missing_keys)}")
            if r.get("external_id") not in ROSTER:
                problems.append(f"[ROSTER] {tag}: external_id {r.get('external_id')} not in this wave's roster")
            elif ROSTER[r["external_id"]] != r.get("name"):
                problems.append(f"[ROSTER] {tag}: external_id {r['external_id']} is {ROSTER[r['external_id']]!r}, payload says {r.get('name')!r}")
            if r.get("topic_key") not in ALLOWED_TOPICS:
                problems.append(f"[TOPIC] {tag}: topic_key not in allowed set for this wave")
            if not isinstance(r.get("value"), int) or not 1 <= r.get("value", 0) <= 5:
                problems.append(f"[VALUE] {tag}: value={r.get('value')!r} not an int 1-5")
            if not str(r.get("reasoning", "")).strip():
                problems.append(f"[REASONING] {tag}: empty")
            srcs = [s for s in (r.get("sources") or []) if str(s).strip()]
            if not srcs:
                problems.append(f"[SOURCE] {tag}: no source URL")

            # ---- pass 1b: legislative-session plausibility ----
            # A cited session predating the member's term_start means the vote
            # cannot be theirs. Deterministic, and independent of any fetch.
            seated = SEATED.get(r.get("external_id"))
            if seated:
                first_year, why = seated
                blob = " ".join(srcs) + " " + str(r.get("reasoning", ""))
                # dedupe: the same session usually appears in both the URL and
                # the prose, and one row should raise one finding
                bad_sessions = sorted({
                    m.group(0) for m in SESSION_RE.finditer(blob)
                    if int(m.group(1) + m.group(2)) < first_year})
                for sess in bad_sessions:
                    problems.append(
                        f"[PRE-SEATING] {tag}: cites session {sess} but {why} "
                        f"— a vote in that session cannot be theirs")

            # ---- pass 2: quote match ----
            q = str(r.get("quote_text", "") or "").strip()
            if not q:
                # An empty quote is legitimate, but it must NOT mean the row's
                # sources go unread — that is exactly where an unfalsifiable
                # claim can hide. Confirm every source is reachable and real.
                reach = []
                for s in srcs:
                    best = "unreachable"
                    for text, how in fetch_variants(s):
                        if text.strip() and looks_substantive(text):
                            best = f"ok:{how}"
                            break
                        if text.strip():
                            best = f"wall/shell:{how}"
                    reach.append(f"{best}")
                    if best == "unreachable":
                        problems.append(f"[SOURCE-UNREACHABLE] {tag}: {s} returned nothing — claim cannot be checked")
                    elif best.startswith("wall"):
                        problems.append(f"[SOURCE-WALLED] {tag}: {s} returned only a wall/shell — verify the claim by hand")
                print(f"  ok(no-quote)   {tag}  v={r.get('value')}  sources[{len(srcs)}]: {', '.join(reach)}")
                tally["no-quote"] = tally.get("no-quote", 0) + 1
                continue
            quoted += 1

            verdict, where, run_info = "MISSING", "", ""
            qn = norm(q)
            any_substantive = False
            fetch_notes: list[str] = []

            for s in srcs:
                if verdict in ("EXACT", "NORMALIZED", "PUNCT"):
                    break
                for text, how in fetch_variants(s):
                    if not text.strip():
                        fetch_notes.append(f"{s} [{how}]")
                        continue
                    substantive = looks_substantive(text)
                    any_substantive = any_substantive or substantive
                    if not substantive:
                        fetch_notes.append(f"{s} [{how}: wall/shell {len(text)}b]")
                    if q in text:
                        verdict, where, run_info = "EXACT", f"{s} [{how}]", ""
                        break
                    if qn and qn in norm(text):
                        verdict, where, run_info = "NORMALIZED", f"{s} [{how}]", ""
                        break
                    # Terminal punctuation only: sources routinely read
                    # `…time equals money,” Norris said` while the payload
                    # closes the quote with a period. Benign, not fabrication.
                    qcore = qn.strip(" .,;:!?\"'’”“-")
                    if len(qcore.split()) >= 6 and qcore in norm(text):
                        verdict, where, run_info = "PUNCT", f"{s} [{how}]", ""
                        break
                    run = longest_run(qn, norm(text))
                    total = len(qn.split())
                    if total and run >= max(6, int(total * 0.6)) and verdict != "PARTIAL":
                        verdict, where = "PARTIAL", f"{s} [{how}]"
                        run_info = f" longest run {run}/{total} words"

            # A negative result is only meaningful if we actually READ a real page.
            if verdict == "MISSING" and not any_substantive:
                verdict = "UNVERIFIABLE"
                where = "; ".join(fetch_notes[:3])

            label = {"EXACT": "ok(exact)", "NORMALIZED": "ok(norm)",
                     "PUNCT": "ok(punct)", "PARTIAL": "INSPECT",
                     "MISSING": "FAIL", "UNVERIFIABLE": "UNVERIFIABLE"}[verdict]
            print(f"  {label:<14} {tag}  v={r.get('value')}  {where}{run_info}")
            tally[verdict] = tally.get(verdict, 0) + 1
            if verdict == "MISSING":
                problems.append(f"[QUOTE-MISSING] {tag}: quote absent from a source page we DID read in full -> {q[:110]!r}")
            elif verdict == "PARTIAL":
                problems.append(f"[QUOTE-PARTIAL] {tag}:{run_info} — inspect for splicing/truncation -> {q[:110]!r}")
            elif verdict == "UNVERIFIABLE":
                problems.append(f"[QUOTE-UNVERIFIABLE] {tag}: every source fetch returned a wall/shell — verify by hand (Playwright/archive.org) before trusting -> {q[:110]!r}")

        print("\n  per-person rows: " + ", ".join(f"{k} {v}" for k, v in sorted(by_person.items())))

    print(f"\n{'='*78}")
    print(f"{checked} rows checked, {quoted} carried a quote.")
    print("  quote verdicts: " + (", ".join(f"{k}={v}" for k, v in sorted(tally.items())) or "none"))
    if problems:
        print(f"\n{len(problems)} PROBLEM(S) — do NOT push until each is resolved or the row is dropped:")
        for p in problems:
            print("  - " + p)
        return 1
    print("\nAll rows passed structural + quote validation.")
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1:]))
