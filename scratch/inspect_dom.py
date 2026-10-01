from scrapling.fetchers import Fetcher
import json

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()

# 1. Inspect /genre
page = fetcher.get("https://haho.moe/genre", headers=headers, timeout=15)
print("=== /genre ===")
links = page.css('a[href*="/genre/"]')
print(f"Total /genre/ links: {len(links)}")
for a in links[:10]:
    href = a.attrib.get('href', '')
    text = "".join(a.css('::text').getall()).strip()
    print(f"Link: href={href}, text={text}")

# Check container structure in /genre
items = page.css('.genre-loop li, .genre-item, .container li, ul.loop > li')
print(f"Items found with generic classes: {len(items)}")
if len(items) > 0:
    for it in items[:5]:
        print("Item:", "".join(it.css('::text').getall()).strip(), [img.attrib.get('src') for img in it.css('img')])
else:
    # print all main containers
    print("Main content sample:")
    main = page.css('main, .content, #content, .container')
    for m in main[:2]:
        print(f"Container: {m.attrib.get('class')}")
        print("".join(m.css('::text').getall())[:300])

# 2. Inspect /playlist
page_pl = fetcher.get("https://haho.moe/playlist", headers=headers, timeout=15)
print("\n=== /playlist ===")
pl_links = page_pl.css('a[href*="/playlist/"]')
print(f"Total /playlist/ links: {len(pl_links)}")
for a in pl_links[:10]:
    href = a.attrib.get('href', '')
    text = "".join(a.css('::text').getall()).strip()
    print(f"Playlist link: href={href}, text={text}")

# 3. Inspect /anime
page_anime = fetcher.get("https://haho.moe/anime", headers=headers, timeout=15)
print("\n=== /anime ===")
# check formats / sorts / types
navs = page_anime.css('nav a, .dropdown-item, .nav-item a, .filter a, .sidebar a')
for n in navs[:25]:
    href = n.attrib.get('href', '')
    text = "".join(n.css('::text').getall()).strip()
    if href and text:
        print(f"Nav/Filter: {href} -> {text}")
