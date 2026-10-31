"""Check deployed-site metadata contracts and local link targets, stdlib only."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit, unquote
import json
import struct
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1] / 'docs'
BASE = 'https://sinanback.github.io/virtual-display-manager/'

class Page(HTMLParser):
    def __init__(self, text):
        super().__init__()
        self.tags = []
        self.schemas = []
        self.in_schema = False
        self.schema_text = ''
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        self.tags.append((tag, attrs))
        if tag == 'script' and attrs.get('type') == 'application/ld+json':
            self.in_schema = True
            self.schema_text = ''

    def handle_data(self, data):
        if self.in_schema:
            self.schema_text += data

    def handle_endtag(self, tag):
        if tag == 'script' and self.in_schema:
            self.schemas.append(json.loads(self.schema_text))
            self.in_schema = False

    def attrs(self, tag):
        return [attrs for name, attrs in self.tags if name == tag]

    def link(self, rel):
        return [a for a in self.attrs('link') if a.get('rel') == rel]

pages = {}
titles = []
for file in ROOT.rglob('index.html'):
    text = file.read_text(encoding='utf-8')
    assert '127.0.0.1' not in text and 'localhost' not in text, f'Preview URL leaked: {file}'
    page = Page(text)
    assert len(page.attrs('h1')) == 1, f'Exactly one H1 required: {file}'
    canonical = page.link('canonical')
    assert len(canonical) == 1 and canonical[0]['href'].startswith(BASE)
    canonical = canonical[0]['href']
    assert canonical not in pages, f'Duplicate canonical: {canonical}'
    pages[canonical] = (file, page)
    title = text.split('<title>', 1)[1].split('</title>', 1)[0]
    assert title not in titles, f'Duplicate title: {file}'
    titles.append(title)
    meta = {a.get('name', a.get('property')): a.get('content') for a in page.attrs('meta')}
    for field in ('description', 'viewport', 'robots', 'og:title', 'og:description', 'og:image', 'og:url', 'twitter:card'):
        assert meta.get(field), f'Missing {field}: {file}'
    assert 'noindex' not in meta['robots']
    assert meta['og:url'] == canonical
    assert page.schemas, f'No structured data: {file}'
    for schema in page.schemas:
        assert schema['@context'] == 'https://schema.org'
        for node in schema['@graph']:
            assert 'aggregateRating' not in node and 'review' not in node, 'Do not invent reviews'
    for tag, attrs in page.tags:
        for field in ('href', 'src'):
            value = attrs.get(field, '')
            if value.startswith(BASE):
                relative = unquote(value.removeprefix(BASE).split('#', 1)[0])
                target = ROOT / relative
                if value.endswith('/') or not relative:
                    target /= 'index.html'
                assert target.exists(), f'Broken internal link {value} from {file}'
        if tag == 'img':
            assert 'alt' in attrs, f'Missing image alternative text: {file}'
            assert attrs.get('width') and attrs.get('height'), f'Missing image dimensions: {file}'
            target = ROOT / attrs['src'].removeprefix(BASE)
            if target.suffix == '.png':
                width, height = struct.unpack('>II', target.read_bytes()[16:24])
                assert (width, height) == (int(attrs['width']), int(attrs['height'])), f'Image aspect ratio incorrect: {target}'

assert len(pages) == 6, f'Expected six content pages, got {len(pages)}'
for canonical, (file, page) in pages.items():
    alts = {a['hreflang']: a['href'] for a in page.link('alternate')}
    assert set(alts) == {'tr', 'en', 'x-default'}
    assert alts['x-default'] == alts['tr']
    for code in ('tr', 'en'):
        assert alts[code] in pages
        other = pages[alts[code]][1]
        assert other.attrs('html')[0]['lang'] == code
        assert {a['hreflang']: a['href'] for a in other.link('alternate')} == alts, f'Non-reciprocal hreflang: {file}'

ns = {'s': 'http://www.sitemaps.org/schemas/sitemap/0.9'}
sitemap = ET.parse(ROOT / 'sitemap.xml')
locations = {entry.text for entry in sitemap.findall('s:url/s:loc', ns)}
assert locations == set(pages), 'Sitemap must contain precisely the canonical content pages'
not_found = Page((ROOT / '404.html').read_text(encoding='utf-8'))
assert any('noindex' in a.get('content', '') for a in not_found.attrs('meta'))
assert (ROOT / '.nojekyll').exists()
print('PASS: six unique indexable pages, reciprocal TR/EN hreflang, canonical URLs, JSON-LD, sitemap, local links and exact image dimensions.')
