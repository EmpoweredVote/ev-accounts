"""Measure the extraction funnel over a sweep corpus.

A steep drop at one stage is either the world or my filter. Printing every stage
makes that answerable instead of guessable.

    python funnel.py <corpus-dir> <cfg.json>
"""
import glob, html as H, io, json, os, re, sys

TITLE = (r'(?:commissioner|county commissioner|council ?member|councilman|councilwoman|'
         r'mayor|vice mayor|chair|chairman|chairwoman|alderman|supervisor|trustee)')
VERB = r"(?:said|wrote|told|added|argued|explained|asked)"


def blocks(raw):
    b = re.sub(r"(?is)<(script|style|noscript|svg|nav|footer|aside)[^>]*>.*?</\1>", " ", raw)
    t = H.unescape(re.sub(r"(?s)<[^>]+>", "\n", b)).replace("​", "")
    t = re.sub(r"[ \t\xa0]+", " ", t)
    t = re.sub(r"\n\s*\n+", "\n", t)
    return [l.strip() for l in t.split("\n") if len(l.strip()) > 90]


def main():
    corpus, cfgp = sys.argv[1], sys.argv[2]
    cfg = json.load(io.open(cfgp, encoding="utf-8"))
    members = cfg["members"]
    tot = named = quoted = attributed = 0
    per = {}
    for f in glob.glob(os.path.join(corpus, "raw", "*.html")):
        for blk in blocks(io.open(f, encoding="utf-8", errors="replace").read()):
            tot += 1
            low = blk.lower()
            for m, aliases in members.items():
                sn = aliases[0].split()[-1]
                if not (any(a.lower() in low for a in aliases)
                        or re.search(TITLE + r"\s+" + re.escape(sn) + r"\b", blk, re.I)):
                    continue
                named += 1
                d = per.setdefault(m, [0, 0, 0])
                d[0] += 1
                if '“' not in blk and '"' not in blk:
                    break
                quoted += 1
                d[1] += 1
                if (re.search(r"\b%s\b(?:\s+\w+){0,3}\s+%s\b" % (re.escape(sn), VERB), blk, re.I)
                        or re.search(r"\b%s\s+(?:\w+\s+){0,2}%s\b" % (VERB, re.escape(sn)), blk, re.I)):
                    attributed += 1
                    d[2] += 1
                break
    print("blocks total      %6d" % tot)
    print("naming a member   %6d" % named)
    print("  of which quoted %6d" % quoted)
    print("  of which attrib %6d" % attributed)
    print()
    for m, (n, q, a) in sorted(per.items(), key=lambda kv: -kv[1][2]):
        print("  %-26s named=%4d quoted=%3d attributed=%3d" % (m, n, q, a))


if __name__ == "__main__":
    main()
