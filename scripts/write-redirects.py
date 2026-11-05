"""Write safe legacy redirects after Quarto renders the public publication."""
from pathlib import Path
import csv, html, os

root = Path("docs").resolve()
def destination(old, new):
    old_path = root / old
    filename, separator, anchor = new.partition("#")
    relative = os.path.relpath(root / filename, old_path.parent).replace(os.sep, "/")
    if separator: relative += "#" + anchor
    old_path.parent.mkdir(parents=True, exist_ok=True)
    old_path.write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta http-equiv="refresh" content="0; url={html.escape(relative, quote=True)}"><link rel="canonical" href="{html.escape(relative, quote=True)}"><title>Moved | Baltimore Ballot</title></head><body><p>This page has moved to <a href="{html.escape(relative, quote=True)}">Baltimore Ballot</a>.</p></body></html>')

with Path("data/measures.csv").open(newline="") as f: measures = list(csv.DictReader(f))
with Path("data/GUIDE_MAPPING.csv").open(newline="") as f: mapping = list(csv.DictReader(f))
for row in mapping:
    match = next((m for m in measures if m["id"] == row["measure_id"]), None)
    if match: destination(f"measures/{row['old_id']}.html", match["guide_path"].replace(".qmd", ".html"))
destination("guide/index.html", "elections/2026/general/index.html")
destination("tracker.html", "elections/2026/general/index.html")
destination("geography.html", "index.html")
destination("spending.html", "index.html")
destination("methods.html", "about.html#editorial-standards")
destination("articles/index.html", "index.html")
