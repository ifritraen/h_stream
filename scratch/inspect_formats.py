from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()
page_anime = fetcher.get("https://haho.moe/anime", headers=headers, timeout=15)

# Check all links on /anime that have query parameters or path filters
links = page_anime.css('a')
print("Checking links on /anime:")
seen = set()
for a in links:
    href = a.attrib.get('href', '')
    text = "".join(a.css('::text').getall()).strip()
    if any(k in href for k in ['type', 'format', 's=', 'status', 'order', 'filter', 'genre', 'mode']) or any(k in text.lower() for k in ['format', 'series', 'ova', 'movie', 'special', 'sort']):
        if (href, text) not in seen:
            seen.add((href, text))
            print(f"Filter/Nav: {href} -> {text}")

# Check any forms or select elements
selects = page_anime.css('select')
for sel in selects:
    name = sel.attrib.get('name', '')
    print(f"\nSelect: name={name}")
    for opt in sel.css('option'):
        val = opt.attrib.get('value', '')
        txt = "".join(opt.css('::text').getall()).strip()
        print(f"  Option: {val} -> {txt}")
