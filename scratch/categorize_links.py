import json
from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()
page = fetcher.get("https://hentaitube.online/", headers=HEADERS, timeout=10)

# Check top navigation / header
nav = page.css('nav, header, .nav, .menu, ul')
print(f"Total nav elements: {len(nav)}")

# Let's extract all sections of links
genres = []
studios = []
years = []
others = []

for a in page.css('a'):
    href = a.attrib.get('href', '')
    text = a.text.strip() if a.text else ''
    if not href or not text:
        continue
    if '/genre/' in href:
        genres.append((text, href))
    elif '/studio/' in href:
        studios.append((text, href))
    elif '/release-year/' in href or '/year/' in href:
        years.append((text, href))
    else:
        others.append((text, href))

# Deduplicate
def dedup(lst):
    seen = set()
    res = []
    for t, h in lst:
        if h not in seen:
            seen.add(h)
            res.append((t, h))
    return res

genres = dedup(genres)
studios = dedup(studios)
years = dedup(years)

print(f"Genres count: {len(genres)}")
print(f"Studios count: {len(studios)}")
print(f"Years count: {len(years)}")

print("\n--- All Genres ---")
for t, h in genres:
    print(f"  {t} -> {h}")

print("\n--- Studios Sample ---")
for t, h in studios[:20]:
    print(f"  {t} -> {h}")

print("\n--- Others Sample ---")
for t, h in dedup(others)[:30]:
    print(f"  {t} -> {h}")
