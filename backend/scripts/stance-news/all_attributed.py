"""Print every ATTRIBUTED quoted passage in a corpus, once, with its member.

One pass over the corpus beats per-member calls when the attributed count is
small: for Florida the funnel was 10,600 blocks -> 377 naming a member -> 66
quoted -> 22 attributed, so the whole judgement set fits on a screen.
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
    corpora = sys.argv[1].split(",")
    cfgs = sys.argv[2].split(",")
    members = {}
    for c in cfgs:
        members.update(json.load(io.open(c, encoding="utf-8"))["members"])
    seen = set()
    n = 0
    for corpus in corpora:
        for f in glob.glob(os.path.join(corpus, "raw", "*.html")):
            for blk in blocks(io.open(f, encoding="utf-8", errors="replace").read()):
                if '“' not in blk and '"' not in blk:
                    continue
                for m, aliases in members.items():
                    sn = re.escape(aliases[0].split()[-1])
                    if not (re.search(r"\b%s\b(?:\s+\w+){0,3}\s+%s\b" % (sn, VERB), blk, re.I)
                            or re.search(r"\b%s\s+(?:\w+\s+){0,2}%s\b" % (VERB, sn), blk, re.I)):
                        continue
                    k = (m, blk[:80])
                    if k in seen:
                        break
                    seen.add(k)
                    n += 1
                    print("[%s]  %s" % (m, os.path.basename(f)[:58]))
                    print("   ", blk[:430].encode("ascii", "replace").decode())
                    print()
                    break
    print("attributed passages:", n)


if __name__ == "__main__":
    main()
