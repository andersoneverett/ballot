"""Validate the rendered public publication, including the intentional empty states."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import csv

root = Path("docs").resolve()
with Path("data/elections.csv").open(newline="") as f: cycles = list(csv.DictReader(f))
with Path("data/measures.csv").open(newline="") as f: measures = list(csv.DictReader(f))
with Path("data/articles.csv").open(newline="") as f: articles = list(csv.DictReader(f))
required = ["index.html", "about.html", "elections/index.html"]
required += [row["path"].replace(".qmd", ".html") for row in cycles if row["published"] == "true"]
required += [row["path"].replace(".qmd", ".html") for row in articles if row["status"] == "published"]
for name in required: assert (root / name).is_file(), f"Missing rendered page: {name}"

class Page(HTMLParser):
    def __init__(self): super().__init__(); self.links=[]; self.ids=set(); self.details=0; self.text=[]; self.skip=0
    def handle_starttag(self, tag, attrs):
        attrs=dict(attrs)
        if tag == "a" and attrs.get("href"): self.links.append(attrs["href"])
        if attrs.get("id"): self.ids.add(attrs["id"])
        if tag == "details": self.details += 1
        if tag in {"script", "style"}: self.skip += 1
    def handle_endtag(self, tag):
        if tag in {"script", "style"}: self.skip = max(0, self.skip - 1)
    def handle_data(self, data):
        if not self.skip: self.text.append(data)

pages = {}
errors = []
for page in root.rglob("*.html"):
    raw = page.read_text(encoding="utf-8")
    assert "{{< include" not in raw, f"Unexpanded include in {page}"
    parser = Page(); parser.feed(raw); pages[page] = parser
    for href in parser.links:
        parts = urlsplit(href)
        if parts.scheme or parts.netloc or not parts.path: continue
        target = (root / parts.path.removeprefix("/ballot/") if parts.path.startswith("/ballot/") else root / parts.path.lstrip("/") if parts.path.startswith("/") else page.parent / unquote(parts.path))
        if not target.exists(): errors.append((str(page.relative_to(root)), href))
assert not errors, f"Broken local links: {errors}"

for row in cycles:
    if row["published"] != "true": continue
    guide = root / row["path"].replace(".qmd", ".html")
    parsed = pages[guide]
    cycle_measures = [m for m in measures if m["cycle_id"] == row["cycle_id"]]
    assert parsed.details >= len(cycle_measures), f"Official wording missing from {guide}"
    for measure in cycle_measures:
        anchor = measure["guide_path"].split("#", 1)[1]
        assert anchor in parsed.ids, f"Missing guide anchor {anchor}"

public_text = "\n".join(" ".join(page.text) for page in pages.values())
for forbidden in ("How I Would Vote", "Original recommendation", "LEAN YES", "Vote: YES", "RStudio", "Codex", "Next reporting step", "Opening research file"):
    assert forbidden not in public_text, f"Public copy contains retired language: {forbidden}"
if not any(a["status"] == "published" for a in articles): assert "Reporting & analysis" not in public_text
if not list(csv.DictReader(Path("data/results.csv").open())):
    guide_text = "\n".join(" ".join(pages[root / c["path"].replace(".qmd", ".html")].text) for c in cycles if c["published"] == "true")
    assert "Certification pending." in guide_text
for stale in ("guide/index.html", "tracker.html", "geography.html", "spending.html", "methods.html"):
    assert (root / stale).is_file(), f"Missing legacy redirect {stale}"
print(f"PASS: {len(required)} public pages, {len(measures)} questions, local links, neutral copy, and legacy redirects.")
