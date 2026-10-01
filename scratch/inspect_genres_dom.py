from scrapling.fetchers import Fetcher
from scrapling.parser import Adaptor
import json

f = Fetcher()

# 1. Parse all genres from /genres
r = f.get('https://www.hentaiworld.me/genres')
doc = Adaptor(r.body.decode('utf-8'))

# Find genre cards
genre_items = []
# Each genre seems to have a title, description, and link
cards = doc.css('.col-12, .col-md-6, .col-lg-4, .genre-item, .card, div[class*="col"]')
print(f"Found {len(cards)} container elements")

# Let's inspect the exact DOM structure of /genres
for a in doc.css('a[href*="/archive?genre="]'):
    href = a.attrib.get('href', '')
    slug = href.split('genre=')[-1].split('&')[0]
    # Parent card or container
    parent = a.parent
    text = a.text.strip() if a.text else ''
    # Let's see parent or sibling text
    all_text = ' '.join(parent.css('::text').getall()).strip()
    print(f"Slug: {slug} | Href: {href} | Link text: {text}")
    print(f"   Parent text: {all_text[:100]}...")

# 2. Check /archive?genre=milf to see cards structure and count
print("\n--- Probing /archive?genre=milf ---")
r_milf = f.get('https://www.hentaiworld.me/archive?genre=milf')
doc_milf = Adaptor(r_milf.body.decode('utf-8'))
titles = doc_milf.css('.name, .title, h2, h3, a.name')
print("Titles found:", len(titles))
for t in titles[:5]:
    print("  Title:", t.text.strip())

# Check pagination
pag_links = doc_milf.css('.pagination a, a[href*="page"]')
print("Pagination links:", len(pag_links))
for p in pag_links:
    print("  Pag:", p.attrib.get('href'), p.text.strip())
