"""Check generated HTML rather than treating a successful render as sufficient."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import csv

root = Path('docs').resolve()
required = ['index.html', 'tracker.html', 'geography.html', 'spending.html', 'about.html', 'methods.html', 'guide/index.html', 'articles/index.html']
with Path('data/measures.csv').open() as f:
    required += [row['page'].replace('.qmd', '.html') for row in csv.DictReader(f)]
for name in required:
    assert (root / name).is_file(), f'Missing rendered page: {name}'

class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
    def handle_starttag(self, tag, attrs):
        if tag == 'a':
            href = dict(attrs).get('href')
            if href:
                self.links.append(href)

errors = []
for page in root.rglob('*.html'):
    text = page.read_text()
    assert '{{< include' not in text, f'Unexpanded include in {page}'
    parser = Links()
    parser.feed(text)
    for href in parser.links:
        parts = urlsplit(href)
        if parts.scheme or parts.netloc or not parts.path:
            continue
        path = unquote(parts.path)
        if path.startswith('/ballot/'):
            target = root / path.removeprefix('/ballot/')
        elif path.startswith('/'):
            target = root / path.lstrip('/')
        else:
            target = page.parent / path
        if not target.exists():
            errors.append((str(page.relative_to(root)), href))
assert not errors, f'Broken local links: {errors}'
with Path('data/results.csv').open() as f:
    results = list(csv.DictReader(f))
if not results:
    assert 'Awaiting certified results' in (root / 'tracker.html').read_text()
    for name in required:
        if name.startswith('measures/'):
            assert 'Awaiting certified results' in (root / name).read_text()
assert 'Baltimore Ballot' in (root / 'index.html').read_text()
print(f'PASS: {len(required)} required pages, local links, include expansion, and research empty states.')
