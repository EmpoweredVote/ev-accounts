"""Show the quoted passages for one member x topic from a sweep corpus.

    python passages.py <corpus-dir> "<Member Name>" [topic-key]

Only passages that carry a direct quotation are shown: a chair has to be named
by the person's own words or a recorded act, never by a reporter's label.
"""
import glob, html as H, io, json, os, re, sys

TITLE = (r'(?:commissioner|county commissioner|council ?member|councilman|councilwoman|'
         r'mayor|vice mayor|chair|chairman|chairwoman|alderman|supervisor|trustee)')


def blocks(raw):
    b = re.sub(r"(?is)<(script|style|noscript|svg|nav|footer|aside)[^>]*>.*?</\1>", " ", raw)
    t = H.unescape(re.sub(r"(?s)<[^>]+>", "\n", b)).replace("​", "")
    t = re.sub(r"[ \t\xa0]+", " ", t)
    t = re.sub(r"\n\s*\n+", "\n", t)
    return [l.strip() for l in t.split("\n") if len(l.strip()) > 90]


def main():
    corpus, member = sys.argv[1], sys.argv[2]
    only = sys.argv[3] if len(sys.argv) > 3 else None
    hits = json.load(io.open(os.path.join(corpus, "hits.json"), encoding="utf-8"))
    cfgs = glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)), "*_cfg*.json"))
    aliases = [member]
    for c in cfgs:
        d = json.load(io.open(c, encoding="utf-8"))
        if member in d.get("members", {}):
            aliases = d["members"][member]
            break
    surname = aliases[0].split()[-1]
    pat = re.compile(TITLE + r"\s+" + re.escape(surname) + r"\b", re.I)

    total = 0
    for topic, urls in hits.get(member, {}).items():
        if only and topic != only:
            continue
        shown = 0
        for u in urls:
            key = re.sub(r"[^a-z0-9]+", "-", u.lower())[-80:]
            af = os.path.join(corpus, "raw", key + ".html")
            if not os.path.exists(af):
                continue
            for blk in blocks(io.open(af, encoding="utf-8", errors="replace").read()):
                if '“' not in blk and '"' not in blk:
                    continue
                if not (any(a.lower() in blk.lower() for a in aliases) or pat.search(blk)):
                    continue
                # The quote must be ATTRIBUTED TO the member, not merely about
                # them, and attribution is ADJACENT: "Matlow said" / "said Matlow"
                # / "Commissioner Matlow told WLRN". A looser proximity test let
                # through an opponent's attack — quoted, on topic, naming him, and
                # useless as a chair — because "Commissioner Matlow, I think it is
                # unacceptable," he said put the surname near a speech verb.
                sn = re.escape(surname)
                verb = r"(?:said|wrote|told|added|argued|explained|asked)"
                if not (re.search(r"\b%s\b(?:\s+\w+){0,3}\s+%s\b" % (sn, verb), blk, re.I)
                        or re.search(r"\b%s\s+(?:\w+\s+){0,2}%s\b" % (verb, sn), blk, re.I)):
                    continue
                if shown == 0:
                    print("\n" + "=" * 92)
                    print("#### %s / %s" % (member, topic))
                if shown >= 4:
                    break
                print("  URL:", u[:116])
                print("   -", blk[:460])
                shown += 1
                total += 1
            if shown >= 4:
                break
    print("\npassages shown:", total)


if __name__ == "__main__":
    main()
