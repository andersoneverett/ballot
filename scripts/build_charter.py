#!/usr/bin/env python3
"""Turn data/charter.xml (City of Baltimore Law Library, Open Law Library schema)
into Quarto pages under charter/. Run by the "Build charter pages" workflow."""
import html, re, sys, pathlib
from lxml import etree

SRC = pathlib.Path("data/charter.xml")
OUT = pathlib.Path("charter")
NS = "{https://open.law/schemas/library}"
CITY = "https://codes.baltimorecity.gov/us/md/cities/baltimore/charter"
RELEASE = "October 15, 2026 release (publication 2026-09-28)"
ARTICLE_META = 'toc: true\ntoc-title: "In This Article"\ntoc-depth: 3\npage-navigation: true\n'

def tag(el):
    return el.tag.replace(NS, "") if isinstance(el.tag, str) else ""

def slug(s):
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")

def esc(s):
    return html.escape(s or "", quote=False)

def cite_href(path):
    parts = [p.strip() for p in (path or "").split("|") if p.strip()]
    if not parts:
        return None
    href = "article-%s.html" % slug(parts[0])
    if len(parts) > 1:
        href += "#s-" + slug(parts[1].replace("§", ""))
    return href

def inline(el):
    out = [esc(el.text)]
    for child in el:
        t = tag(child)
        inner = inline(child)
        if t == "cite":
            href = cite_href(child.get("path"))
            out.append('<a href="%s">%s</a>' % (html.escape(href, quote=True), inner) if href else inner)
        else:
            out.append(inner)
        out.append(esc(child.tail))
    return "".join(out)

def label(el):
    num = el.findtext(NS + "num") or ""
    head = el.findtext(NS + "heading") or ""
    return num, head

def render_blocks(el, depth=0):
    parts = []
    for child in el:
        t = tag(child)
        if t in ("prefix", "num", "heading", "meta"):
            continue
        if t == "text":
            parts.append("<p>%s</p>" % inline(child))
        elif t == "para":
            num, head = label(child)
            lead = ""
            if num:
                lead += '<span class="charter-num">%s</span> ' % esc(num)
            if head:
                lead += '<span class="charter-subhead">%s</span> ' % esc(head)
            parts.append('<div class="charter-para charter-depth-%d">' % min(depth + 1, 4))
            if lead:
                parts.append("<p>%s</p>" % lead.strip())
            parts.append(render_blocks(child, depth + 1))
            parts.append("</div>")
        elif t == "annotations":
            items = [inline(a) for a in child if tag(a) == "annotation"]
            kinds = {a.get("type", "Note") for a in child if tag(a) == "annotation"}
            if items:
                parts.append('<p class="charter-history"><strong>%s:</strong> %s</p>' % (esc(", ".join(sorted(kinds))), "; ".join(items)))
        else:
            txt = inline(child).strip()
            if txt:
                parts.append("<p>%s</p>" % txt)
    return "\n".join(p for p in parts if p)

def collect(container, trail=()):
    """Yield (container-heading trail, section) for every section below a container."""
    for child in container:
        t = tag(child)
        if t == "section":
            yield trail, child
        elif t == "container":
            num, head = label(child)
            pre = child.findtext(NS + "prefix") or ""
            yield from collect(child, trail + (("%s %s" % (pre, num)).strip() + (" \u2014 " + head if head else ""),))

def front(title, extra=""):
    return '---\ntitle: "%s"\n%s---\n\n' % (title.replace('"', "'"), extra)

def disclaimer(article_num=None):
    link = "%s/%s" % (CITY, article_num) if article_num else CITY
    return ('::: {.charter-note}\nSource: [City of Baltimore Law Library](%s), %s. '
            'This copy is for reading and searching and is not the official version. '
            'Charter amendments adopted after this release, including the November 2026 ballot questions, '
            'may not appear yet.\n:::\n\n' % (link, RELEASE))

def main():
    if not SRC.exists():
        sys.exit("Missing %s" % SRC)
    root = etree.parse(str(SRC)).getroot()
    articles = [c for c in root if tag(c) == "container"]
    if not articles:
        sys.exit("No articles found in charter.xml")
    OUT.mkdir(exist_ok=True)
    for old in OUT.glob("*.qmd"):
        old.unlink()
    index_rows, total = [], 0
    for art in articles:
        pre = art.findtext(NS + "prefix") or "Article"
        num, head = label(art)
        title = ("%s %s" % (pre, num)).strip() + (" \u2014 " + head if head else "")
        secs = list(collect(art))
        total += len(secs)
        page = [front(title, ARTICLE_META), disclaimer(num)]
        last = None
        for trail, s in secs:
            if trail != last and trail:
                page.append("\n## %s\n" % " / ".join(trail))
            last = trail
            sn, sh = label(s)
            page.append("\n### \u00a7 %s. %s {#s-%s}\n" % (sn, sh, slug(sn)))
            page.append("```{=html}\n%s\n```\n" % render_blocks(s))
            page.append('[View this section on the City site](%s/%s/%s)\n' % (CITY, num, html.escape(sn, quote=True)))
        name = "article-%s.qmd" % slug(num)
        (OUT / name).write_text("\n".join(page), encoding="utf-8")
        index_rows.append((title, name.replace(".qmd", ".html"), len(secs)))
    idx = [front("Charter of Baltimore City", "page-navigation: true\n"), disclaimer(),
           "Read and search the full City Charter. Pick an article:\n"]
    for title, href, n in index_rows:
        idx.append("- [%s](%s) (%d sections)" % (title, href, n))
    (OUT / "index.qmd").write_text("\n".join(idx) + "\n", encoding="utf-8")
    print("Wrote %d articles, %d sections" % (len(articles), total))

if __name__ == "__main__":
    main()
