"""Article-link extraction that is not tied to one publisher's URL shape.

Three separate misses in this session all came from assuming NPR's
`/section/2026-10-03/slug` form:
  - wusf.org serves the same shape but as RELATIVE hrefs, so an absolute-only
    regex found none;
  - thebradentontimes.com uses `/stories/<slug>,<id>` with no date at all, and
    its search lives at /browse.html, not ?s=;
  - wusfnews.wusf.usf.edu renders results client-side, so the server HTML has
    none regardless of pattern.
Each looked like "this city has no coverage". Resolve links against the page's
own base and accept any slug-shaped path on the same host.
"""
import re
from urllib.parse import urljoin, urlparse

DATED = re.compile(r"/20\d\d[-/]\d\d[-/]\d\d/")
SLUGGY = re.compile(r"/[a-z0-9]+(?:-[a-z0-9]+){2,}", re.I)
SKIP = re.compile(r"\.(jpg|jpeg|png|svg|gif|webp|mp3|mp4|pdf|xml|css|js)(\?|$)", re.I)
JUNK = re.compile(r"/(tags?|topics?|people|authors?|search|browse|category|podcast|show)s?/", re.I)


def article_links(html, page_url, limit=8):
    """Return absolute article URLs found on a search-results page."""
    host = urlparse(page_url).netloc
    out = []
    # Accept hrefs carrying a query string: thebradentontimes.com emits
    # `/stories/<slug>,<id>?` and an earlier pattern that excluded '?' rejected
    # every real search result while keeping the sidebar — which read as "this
    # city has no coverage". Strip the query instead of refusing the URL.
    for href in re.findall(r'''href=["']([^"']+)["']''', html):
        if href.startswith(("mailto:", "javascript:", "#")):
            continue
        absu = urljoin(page_url, href)
        p = urlparse(absu)
        if p.netloc != host or SKIP.search(p.path):
            continue
        path = p.path
        if JUNK.search(path):
            continue
        is_article = bool(DATED.search(path)) or path.startswith("/stories/") \
            or (SLUGGY.search(path) and path.count("/") <= 4)
        if not is_article:
            continue
        clean = p.scheme + "://" + p.netloc + p.path
        if clean not in out:
            out.append(clean)
        if len(out) >= limit:
            break
    return out


if __name__ == "__main__":
    import io, sys
    html = io.open(sys.argv[1], encoding="utf-8", errors="replace").read()
    for u in article_links(html, sys.argv[2], limit=12):
        print(u)
