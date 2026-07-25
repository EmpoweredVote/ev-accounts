#!/usr/bin/env py
"""
SOURCE-SUPPORTS-CLAIM CHECK

The gap left by every other gate. Phase 149 checks only that a `sources` URL
EXISTS. `validate-stance-quotes.py` checks that a quote appears in its source —
but the contaminated rows carry no quote, so there is nothing to match and they
pass. This asks the different question: *does the cited page actually carry a
statement on this topic's axis at all?*

Three layers, cheapest first. Nothing here writes to the database.

  L1 STRUCTURAL (no network)
      bio-only     the only source is a Ballotpedia/Wikipedia BIOGRAPHY page,
                   which carries no policy content for any topic
      party-prior  reasoning uses party/geography as the evidence ("Portland
                   area Democrat with progressive environmental positions")
      no-artifact  reasoning names no bill, no date, no vote and no quote —
                   there is no checkable claim in it at all
      aggregator   sourced to a known AI-content-farm / uncited aggregator

  L2 TOPICAL (fetch + vocabulary, deterministic)
      Builds each topic's vocabulary FROM THE DB — its title, question_text and
      all five stance texts — then keeps only discriminating terms (those used
      by <= MAX_TOPICS topics), so "government"/"should" are dropped while
      "abortion"/"voucher"/"encampment" are kept. Then counts how many distinct
      discriminating terms the fetched page contains.
        0 terms   -> UNSUPPORTED   the page cannot support a claim on this axis
        1..2      -> WEAK          probably incidental mentions
        3+        -> TOPICAL       on-topic; chair correctness still unknown
      A page we could not actually read is UNVERIFIABLE, never UNSUPPORTED —
      a blocked fetch is a different problem from a bad row.

  L3 QUEUE
      TOPICAL rows are the ones a deterministic test cannot finish: the page
      discusses the axis, but whether it supports the ASSIGNED CHAIR needs
      judgement. Those are written to an adjudication queue with the matching
      snippets already extracted, so a model pass never has to re-fetch.

Usage
  py scripts/check-source-supports.py --state OR --title-like Representative
  py scripts/check-source-supports.py --external-ids -4120053,-4120054
  py scripts/check-source-supports.py --snapshot data/.../retired-preseating-snapshot.json
  py scripts/check-source-supports.py --state OR --limit 50 --json out.json --queue q.json

`--snapshot` scores rows from a retirement snapshot instead of the live DB, which
is how this check is calibrated against known-bad and known-good sets.
"""
import argparse
import importlib.util
import json
import os
import re
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))

# Reuse the validator's hard-won fetch/extract layer (HTML + PDF + docx, direct
# and r.jina.ai renditions, x-no-cache, on-disk cache) rather than rebuild it.
_spec = importlib.util.spec_from_file_location(
    "vq", os.path.join(HERE, "validate-stance-quotes.py"))
vq = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(vq)

STOP = set("""a an the and or but if then than that this these those of in on at to for from by with
without within into over under about across after before during between as is are was were be been
being am do does did doing have has had having he she it they them their his her its our your my we
you i not no nor so such only own same too very can will just should would could may might must
government governments public policy policies people person state states federal local national law
laws legal require required requires requiring ensure ensuring allow allowing allows provide provides
providing providing support supports supporting oppose opposes opposing new current existing all any
more most less least other others while where when who whom which what how why also each both either
neither than through per via up down out off again further once here there because until against
among during above below between both few many some such rather instead including include includes
level levels approach approaches system systems program programs make makes making made keep keeps
set sets use uses used using need needs needed""".split())

AGGREGATORS = ("decodethevote", "electionsfla", "predictionedge", "civoren",
               "ontheissues", "votesmart.org/candidate", "isidewith")
BIO_RE = re.compile(r"(?i)^https?://(?:www\.)?(?:ballotpedia\.org|en\.wikipedia\.org/wiki)/"
                    r"[A-Z][A-Za-z0-9_%.'-]*(?:_[A-Za-z0-9_%.'-]+)*/?$")
PARTY_PRIOR_RE = re.compile(
    r"(?i)(progressive voting record|conservative voting record|"
    r"(?:democrat|republican)\s+(?:focused|with|from)|area (?:democrat|republican)|"
    r"district priorities|as (?:a )?(?:democrat|republican)\b|"
    r"consistent(?:ly)? (?:progressive|conservative)|party[- ]line)")
# Something concrete enough to check: a bill, a dated action, or a quotation.
ARTIFACT_RE = re.compile(
    r"(?i)(\b(?:HB|SB|HJR|SJR|HR|SR|AB|HF|SF)\s?\d{2,5}\b|"
    r"\b(19|20)\d{2}\b|voted|vote |sponsor|carried|moved|testimony|"
    r"ordinance|resolution|measure|proposition|amendment|[“\"'])")

MAX_TOPICS = 3          # a term used by more than this many topics is generic
WEAK_MAX = 2            # 1..WEAK_MAX distinct terms = WEAK, above = TOPICAL

# Two kinds of NON-TEXT source, both legitimate but neither prose:
#   - OLIS measure pages: a JS shell whose only real content is the <title>
#   - OData API queries: machine-readable roll calls, no policy prose at all
# Scoring either for topic vocabulary produces false accusations against
# perfectly good vote-based rows. The claim they carry is a VOTE, and a vote is
# verified against the OData API by sweep-or-preseating.mjs — not by reading text.
NON_TEXT_RE = re.compile(
    r"(?i)^https?://(?:olis\.oregonlegislature\.gov/liz/[^/]+/Measures/"
    r"|api\.oregonlegislature\.gov/odata"
    r"|\w+\.legiscan\.com/api"
    r"|clerk\.house\.gov/(?:evs|Votes)"
    r"|www\.senate\.gov/legislative/LIS/roll_call)")


def spa_source(url: str) -> bool:
    return bool(NON_TEXT_RE.match((url or "").strip()))


# A dead source URL is a distinct, unambiguous defect and deserves its own
# verdict rather than being lumped in with "page says nothing on this axis".
# Note these arrive as HTTP 200 bodies via the r.jina.ai fallback, so a status
# check alone does not catch them.
NOTFOUND_RE = re.compile(
    r"(?i)\b(page not found|404 not found|404 error|"
    r"page you (?:are looking for|requested) (?:could not be found|does not exist)|"
    r"this page (?:doesn'?t|does not) exist|"
    r"we can'?t find (?:the|that) page|article not found)\b")


def looks_dead(text: str) -> bool:
    return bool(NOTFOUND_RE.search(text[:3000]))


_TEXT_MEMO: dict = {}


def readable_text(url: str) -> tuple[str, str]:
    """
    First READABLE rendition wins, memoised per process.

    validate-stance-quotes.py deliberately fetches direct AND r.jina.ai and
    searches both, because a quote may survive in only one. Here we just need one
    substantive rendition, so stopping at the first halves the network cost — the
    difference between this finishing and being killed at 600s.
    """
    if url in _TEXT_MEMO:
        return _TEXT_MEMO[url]
    best = ("", "unreadable")
    for text, how in vq.fetch_variants(url):
        if text.strip() and vq.looks_substantive(text):
            best = (text, how)
            break
        if text.strip() and best[0] == "":
            best = ("", f"wall/shell:{how}")
    _TEXT_MEMO[url] = best
    return best


def words(text: str) -> list[str]:
    return [w for w in re.findall(r"[a-z][a-z-]{2,}", (text or "").lower())
            if w not in STOP and len(w) > 3]


def build_topic_vocab(rows) -> dict:
    """rows: (topic_key, blob). Keep only discriminating terms."""
    per = {}
    for key, blob in rows:
        per.setdefault(key, set()).update(words(blob))
    spread = Counter()
    for terms in per.values():
        for t in terms:
            spread[t] += 1
    return {k: {t for t in terms if spread[t] <= MAX_TOPICS} for k, terms in per.items()}


def structural_flags(row) -> list[str]:
    flags = []
    srcs = [s for s in (row["sources"] or []) if str(s).strip()]
    reasoning = row.get("reasoning") or ""
    if srcs and all(BIO_RE.match(s.strip()) for s in srcs):
        flags.append("bio-only")
    if any(a in s.lower() for s in srcs for a in AGGREGATORS):
        flags.append("aggregator")
    if PARTY_PRIOR_RE.search(reasoning):
        flags.append("party-prior")
    if not ARTIFACT_RE.search(reasoning) and not (row.get("quote_text") or "").strip():
        flags.append("no-artifact")
    return flags


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--state")
    ap.add_argument("--title-like")
    ap.add_argument("--external-ids")
    ap.add_argument("--topic")
    ap.add_argument("--snapshot", help="score rows from a retirement snapshot instead of the DB")
    ap.add_argument("--limit", type=int)
    ap.add_argument("--json", help="write the full per-row report here")
    ap.add_argument("--queue", help="write the L3 model-adjudication queue here")
    ap.add_argument("--no-fetch", action="store_true", help="L1 only")
    ap.add_argument("--resume", metavar="REPORT",
                    help="skip rows already present in REPORT and merge into it; "
                         "makes long runs incremental and idempotent")
    a = ap.parse_args()

    import psycopg2
    from psycopg2.extras import RealDictCursor
    dsn = os.environ.get("DATABASE_URL")
    if not dsn:
        for line in open(os.path.join(HERE, "..", ".env"), encoding="utf-8", errors="replace"):
            if line.startswith("DATABASE_URL="):
                dsn = line.split("=", 1)[1].strip().strip('"').strip("'")
                break
    conn = psycopg2.connect(dsn)
    cur = conn.cursor(cursor_factory=RealDictCursor)

    # topic vocabulary, derived from the compass itself
    cur.execute("""
        SELECT t.topic_key,
               t.title || ' ' || coalesce(t.question_text,'') || ' ' ||
               string_agg(coalesce(s.text,''), ' ') AS blob
          FROM inform.compass_topics t
          LEFT JOIN inform.compass_stances s ON s.topic_id = t.id
         WHERE t.is_live AND t.is_active
         GROUP BY t.topic_key, t.title, t.question_text""")
    vocab = build_topic_vocab([(r["topic_key"], r["blob"]) for r in cur.fetchall()])
    print(f"topic vocabulary: {len(vocab)} topics, "
          f"median {sorted(len(v) for v in vocab.values())[len(vocab)//2]} discriminating terms\n")

    # rows under test
    if a.snapshot:
        snap = json.load(open(a.snapshot, encoding="utf-8"))
        rows = [{"external_id": r.get("external_id"), "full_name": r.get("full_name"),
                 "topic_key": r.get("topic_key"), "value": r.get("value"),
                 "reasoning": r.get("reasoning"), "sources": r.get("sources") or [],
                 "quote_text": ""} for r in snap["rows"]]
        print(f"scoring {len(rows)} rows from snapshot {os.path.basename(a.snapshot)}")
    else:
        where, params = ["1=1"], []
        if a.state:
            where.append("o.representing_state = %s"); params.append(a.state)
        if a.title_like:
            where.append("o.title ILIKE %s"); params.append(f"%{a.title_like}%")
        if a.topic:
            where.append("t.topic_key = %s"); params.append(a.topic)
        if a.external_ids:
            ids = [int(x) for x in a.external_ids.split(",")]
            where.append("p.external_id = ANY(%s)"); params.append(ids)
        sql = f"""
            SELECT DISTINCT p.external_id, p.full_name, t.topic_key, pa.value,
                   pc.reasoning, pc.sources,
                   coalesce((SELECT q.quote_text FROM essentials.quotes q
                              WHERE q.politician_id = p.id
                                AND lower(q.topic_key) = t.topic_key LIMIT 1), '') AS quote_text
              FROM inform.politician_context pc
              JOIN inform.politician_answers pa
                ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
              JOIN inform.compass_topics t   ON t.id = pc.topic_id
              JOIN essentials.politicians p  ON p.id = pc.politician_id
              LEFT JOIN essentials.offices o ON o.politician_id = p.id
             WHERE {' AND '.join(where)}
             ORDER BY p.full_name, t.topic_key"""
        if a.limit:
            sql += f" LIMIT {a.limit}"
        cur.execute(sql, params)
        rows = cur.fetchall()
        print(f"scoring {len(rows)} live rows")
    conn.close()

    prior, done = [], set()
    if a.resume and os.path.exists(a.resume):
        prior = json.load(open(a.resume, encoding="utf-8"))
        done = {(str(r["external_id"]), r["topic_key"]) for r in prior}
        rows = [r for r in rows
                if (str(r["external_id"]), r["topic_key"]) not in done]
        print(f"resume: {len(done)} rows already scored; {len(rows)} left this pass")

    report, queue = list(prior), []
    tally = Counter(r["verdict"] for r in prior)
    for r in prior:
        for f in r.get("flags", []):
            tally[f"flag:{f}"] += 1
    def flush():
        # Persist as we go. A long run can be killed by a timeout, and a report
        # written only at the end means every fetch is thrown away.
        if a.json:
            json.dump(report, open(a.json, "w", encoding="utf-8"), indent=2)
        if a.queue:
            json.dump(queue, open(a.queue, "w", encoding="utf-8"), indent=2)

    for i, r in enumerate(rows, 1):
        if i % 25 == 0 or i == len(rows):
            print(f'  ...{i}/{len(rows)} (report {len(report)})', flush=True)
            flush()
        flags = structural_flags(r)
        terms = vocab.get(r["topic_key"], set())
        srcs = [s for s in (r["sources"] or []) if str(s).strip()]
        verdict, hits, best, readable = "NO-SOURCE", set(), "", False

        textual = [s for s in srcs if not spa_source(s)]
        if len(textual) < len(srcs):
            flags.append("non-text-source")

        dead_srcs = []
        if textual and not a.no_fetch:
            for s in textual:
                text, how = readable_text(s)
                if not text:
                    continue
                if looks_dead(text):
                    dead_srcs.append(s)
                    continue
                readable = True
                found = {t for t in terms if t in text.lower()}
                if len(found) > len(hits):
                    hits, best = found, f"{s} [{how}]"
            if dead_srcs and not readable:
                verdict = "SOURCE-DEAD"
                best = f"{dead_srcs[0]} [404/not-found]"
                flags.append("dead-link")
            elif not readable:
                verdict = "UNVERIFIABLE"
            elif not hits:
                verdict = "UNSUPPORTED"
            elif len(hits) <= WEAK_MAX:
                verdict = "WEAK"
            else:
                verdict = "TOPICAL"
        elif srcs and not textual:
            # Every source is a legislative measure page: nothing to read here.
            # Not a defect on its own — route the claim to the OData vote check.
            verdict = "VOTE-CLAIM-ONLY"
        elif srcs:
            verdict = "L1-ONLY"

        # ---- composite: structural verdict overrides a permissive text score ----
        # A Ballotpedia BIOGRAPHY page does contain policy vocabulary incidentally
        # (committee lists, election history), so L2 alone scores it TOPICAL. But a
        # row whose ONLY source is a bio page AND whose reasoning names no bill, no
        # date, no vote and no quote has nothing that could be checked against
        # anything. That is unsupportable on its face, whatever words the page holds.
        if "bio-only" in flags and "no-artifact" in flags:
            verdict = "UNSUPPORTED-STRUCTURAL"
        elif verdict in ("TOPICAL", "WEAK") and (
                "bio-only" in flags or "aggregator" in flags or "party-prior" in flags):
            verdict = "SUSPECT"

        tally[verdict] += 1
        for f in flags:
            tally[f"flag:{f}"] += 1
        rec = {"external_id": r["external_id"], "full_name": r["full_name"],
               "topic_key": r["topic_key"], "value": (None if r["value"] is None else float(r["value"])),
               "verdict": verdict, "flags": flags,
               "topic_terms_found": sorted(hits)[:12], "n_terms": len(hits),
               "best_source": best, "sources": srcs}
        report.append(rec)
        if verdict in ("TOPICAL", "SUSPECT"):
            queue.append({**rec, "reasoning": r["reasoning"],
                          "question": "Does this source state a position on this topic's axis that "
                                      "supports the assigned chair? Answer supports / contradicts / "
                                      "silent, and quote the sentence."})

    # ---- report ----
    print()
    for k, v in tally.most_common():
        print(f"  {k:<22} {v}")
    ACTIONABLE = ("UNSUPPORTED", "UNSUPPORTED-STRUCTURAL", "NO-SOURCE", "SOURCE-DEAD")
    bad = [r for r in report if r["verdict"] in ACTIONABLE]
    print(f"\nACTIONABLE (retire or re-research): {len(bad)} rows "
          f"across {len({r['external_id'] for r in bad})} politicians")
    for r in bad[:25]:
        print(f"   {r['full_name']} / {r['topic_key']} = {r['value']}  "
              f"flags={','.join(r['flags']) or '-'}")
    if len(bad) > 25:
        print(f"   ... and {len(bad)-25} more")

    if a.json:
        json.dump(report, open(a.json, "w", encoding="utf-8"), indent=2)
        print(f"\nwrote {a.json}")
    if a.queue:
        # Derive from the MERGED report, not from this pass's accumulator — with
        # --resume the accumulator only holds rows scored in the current pass.
        need = [r for r in report if r["verdict"] in ("TOPICAL", "SUSPECT")]
        conn2 = psycopg2.connect(dsn)
        cur2 = conn2.cursor(cursor_factory=RealDictCursor)
        cur2.execute("""
            SELECT p.external_id, t.topic_key, pc.reasoning
              FROM inform.politician_context pc
              JOIN inform.compass_topics t  ON t.id = pc.topic_id
              JOIN essentials.politicians p ON p.id = pc.politician_id""")
        reasons = {(str(x["external_id"]), x["topic_key"]): x["reasoning"]
                   for x in cur2.fetchall()}
        conn2.close()
        q = [{**r,
              "reasoning": reasons.get((str(r["external_id"]), r["topic_key"]), ""),
              "question": "Does this source state a position on this topic's axis that "
                          "supports the assigned chair? Answer supports / contradicts / "
                          "silent, and quote the sentence."}
             for r in need]
        json.dump(q, open(a.queue, "w", encoding="utf-8"), indent=2)
        print(f"wrote {a.queue} ({len(q)} rows needing model adjudication)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
