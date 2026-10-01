from scrapling.fetchers import Fetcher
import re

fetcher = Fetcher()

# Test tag filter
r_tag = fetcher.get("https://hentaidb.xyz/?tag=Big+Boobs")
print(f"Tag Big Boobs status: {r_tag.status}")
cards_tag = r_tag.css('a[href^="/s/"]')
print(f"Tag Big Boobs cards count: {len(cards_tag)}")

# Test search queries
for param in ['q', 'search', 's']:
    r_s = fetcher.get(f"https://hentaidb.xyz/?{param}=gal")
    cards = r_s.css('a[href^="/s/"]')
    print(f"Search param '{param}=gal': status={r_s.status}, cards={len(cards)}")

# Check if there is an explicit search form or input
r_home = fetcher.get("https://hentaidb.xyz/")
forms = r_home.css('form')
print(f"Forms found on homepage: {len(forms)}")
for f in forms:
    print(f"  action={f.attrib.get('action')} method={f.attrib.get('method')}")
    inputs = f.css('input')
    for inp in inputs:
        print(f"    input name={inp.attrib.get('name')} type={inp.attrib.get('type')}")
