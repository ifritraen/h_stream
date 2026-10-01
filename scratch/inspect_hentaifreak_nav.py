from scrapling.fetchers import Fetcher
from urllib.parse import urlparse

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaifreak.org/',
}

fetcher = Fetcher()
page = fetcher.get('https://hentaifreak.org/', headers=headers, timeout=15)

print(f"Status: {page.status}")

# Collect all <a> links
links = page.css('a')
print(f"Total <a> tags: {len(links)}")

seen_hrefs = set()
href_list = []
for a in links:
    href = a.attrib.get('href', '').strip()
    text = a.get_all_text().strip()
    if href and href not in seen_hrefs:
        seen_hrefs.add(href)
        href_list.append((href, text))

print("\n--- All Unique Links ---")
for href, text in href_list:
    if any(k in href for k in ['category', 'genre', 'tag', 'sort', 'order', 'type', 'filter', 'popular', 'video', 'series']):
        print(f"Taxonomy/Content link: {href} -> Text: '{text}'")

print("\n--- Menu / Nav structure ---")
nav_elements = page.css('nav, header, .menu, #menu, .navbar, .navigation, ul.nav')
for i, nav in enumerate(nav_elements):
    print(f"Nav {i} tag={nav.tag} class={nav.attrib.get('class')} id={nav.attrib.get('id')}:")
    for a in nav.css('a'):
        print(f"   {a.attrib.get('href')} | text: '{a.get_all_text().strip()}'")

print("\n--- Any lists / widgets / sidebar ---")
widgets = page.css('.widget, aside, .sidebar, footer')
for i, w in enumerate(widgets):
    print(f"Widget {i} class={w.attrib.get('class')}:")
    for a in w.css('a')[:10]:
        print(f"   {a.attrib.get('href')} | text: '{a.get_all_text().strip()}'")
