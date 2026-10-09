"""Generic name-x-topic local-news sweep for a Knight city slice.

    python sweep.py <config.json>

Config: {"out": "<dir>", "outlets": [{"name":..,"search":"...{q}..."}],
         "members": {"Full Name": ["Alias", ...]}, "topics": {"topic-key": "search words"}}

Why name AND topic: a name-only search returns an outlet's top ~25 results for a
person, which is election and process coverage. Measured on WFAE, adding the
topic surfaced 9-15 articles per query that a name-only sweep never saw.

Two guards, both earned:
  - an article counts only when a member's name matches as a PHRASE in the body
    (a surname alone matched a musician called Owens, another called Mayfield,
    and a jazz singer called Mayo);
  - per-query counts print, so a uniform zero cannot pass as a result.
"""
import io, json, os, re, subprocess, sys, time, urllib.parse, html as H
from links import article_links

ART = re.compile(r'href="(https?://[^"]*?/20\d\d[-/]\d\d[-/]\d\d/[^"#?]+)"')
# A title immediately before the surname counts as naming the person, mirroring
# the verifier's own rule. Requiring the full phrase in every article missed
# Christine King entirely: Miami coverage writes "Commissioner King".
TITLE = (r'(?:commissioner|county commissioner|council ?member|councilman|councilwoman|'
         r'mayor|vice mayor|chair|chairman|chairwoman|alderman|supervisor|trustee)')
SKIP = re.compile(r"\.(jpg|png|svg|gif|webp|mp3|pdf)$", re.I)


def curl(url, dest):
    # No User-Agent: some civic WAFs 403 a browser UA on curl's TLS fingerprint
    # while serving a bare request normally (charlottenc.gov does exactly this).
    pr = subprocess.run(["curl", "-sS", "-L", "-m", "35", "-o", dest, "-w", "%{http_code}", url],
                        capture_output=True, text=True)
    return (pr.stdout or "").strip()[-3:]


def body(raw):
    b = re.sub(r"(?is)<(script|style|noscript|svg|nav|footer|aside)[^>]*>.*?</\1>", " ", raw)
    t = H.unescape(re.sub(r"(?s)<[^>]+>", "\n", b)).replace("​", "")
    return re.sub(r"[ \t\xa0]+", " ", t)


def main():
    cfg = json.load(io.open(sys.argv[1], encoding="utf-8"))
    out = cfg["out"]
    raw_dir = os.path.join(out, "raw")
    os.makedirs(raw_dir, exist_ok=True)
    fetched = {}
    hits = {}
    for member, aliases in cfg["members"].items():
        hits[member] = {}
        for topic, words in cfg["topics"].items():
            urls = []
            for o in cfg["outlets"]:
                q = urllib.parse.quote("%s %s" % (aliases[0], words))
                tmp = os.path.join(raw_dir, "_s.html")
                if curl(o["search"].replace("{q}", q), tmp) != "200":
                    continue
                raw = io.open(tmp, encoding="utf-8", errors="replace").read()
                # links.article_links resolves relative hrefs against the page,
                # accepts query strings, and is not tied to NPR's dated-URL shape.
                urls += article_links(raw, o["search"].replace("{q}", q), limit=6)
                time.sleep(0.2)
            kept = []
            for u in dict.fromkeys(urls):
                key = re.sub(r"[^a-z0-9]+", "-", u.lower())[-80:]
                af = os.path.join(raw_dir, key + ".html")
                if u not in fetched:
                    fetched[u] = curl(u, af) == "200"
                    time.sleep(0.15)
                if not fetched[u] or not os.path.exists(af):
                    continue
                txt = body(io.open(af, encoding="utf-8", errors="replace").read()).lower()
                surname = aliases[0].split()[-1].lower()
                named = any(a.lower() in txt for a in aliases) or bool(
                    re.search(TITLE + r"\s+" + re.escape(surname) + r"\b", txt))
                if named:
                    kept.append(u)
            hits[member][topic] = kept
            print("  %-24s %-26s searched=%2d named=%2d" % (member, topic, len(set(urls)), len(kept)),
                  flush=True)
        io.open(os.path.join(out, "hits.json"), "w", encoding="utf-8").write(
            json.dumps(hits, indent=1, ensure_ascii=False))
    print("TOTAL named article-topic pairs:",
          sum(len(v) for m in hits.values() for v in m.values()))


if __name__ == "__main__":
    main()
