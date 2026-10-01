from scrapling.fetchers import Fetcher
import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
fetcher = Fetcher()

print("Fetching catalog...")
r = fetcher.get("https://hentai.ht/catalog")
print(f"Catalog status: {r.status}, length: {len(r.text)}")

# Print first 1000 characters of catalog text
print("Catalog text snippet:")
print(r.text[:1000])

# Inspect all 'a' tags
a_tags = r.css('a')
print(f"Total 'a' tags: {len(a_tags)}")
hrefs = [a.attrib.get('href', '') for a in a_tags]
print(f"Sample hrefs: {hrefs[:25]}")

# Look for anime cards/containers
cards = r.css('div.card, div.item, div.anime, div.title, article, div.grid > div')
print(f"Candidate card elements: {len(cards)}")

# Check collections
r_coll1 = fetcher.get("https://hentai.ht/collections/recently-published")
print(f"Recently published status: {r_coll1.status}, length: {len(r_coll1.text)}")
coll1_hrefs = [a.attrib.get('href', '') for a in r_coll1.css('a')]
print(f"Recently published hrefs: {coll1_hrefs[:20]}")

# Check homepage
r_home = fetcher.get("https://hentai.ht/")
home_hrefs = [a.attrib.get('href', '') for a in r_home.css('a')]
print(f"Homepage hrefs: {home_hrefs[:25]}")
