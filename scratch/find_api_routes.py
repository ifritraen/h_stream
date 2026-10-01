from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()
r = fetcher.get('https://hentaverse.com/categories/school-girl', headers=headers, timeout=10)
html = r.body.decode('utf-8', errors='ignore')

# Check for pagination links, buttons, or page numbers
links = r.css('a, button')
page_links = []
for el in links:
    text = el.get_all_text().strip()
    href = el.attrib.get('href', '')
    if any(p in text for p in ['Next', 'Prev', '1', '2', '3', 'Load More']):
        page_links.append((text, href, el.attrib))

print("Page links/buttons found:", page_links[:15])

# Check for API endpoints in JS chunks on this page
js_files = re.findall(r'src="(/_next/static/chunks/[^"]+)"', html)
print(f"JS chunk files on category page: {len(js_files)}")

# Search for /api/ in html
api_routes = set(re.findall(r'["\'](/api/[^"\']+)["\']', html))
print("API routes in HTML:", api_routes)

# Let's inspect a couple of JS chunks to see if they fetch /api/videos or similar
for js in js_files[:5]:
    js_url = f"https://hentaverse.com{js}"
    try:
        jr = fetcher.get(js_url, headers=headers, timeout=10)
        js_text = jr.body.decode('utf-8', errors='ignore')
        apis = set(re.findall(r'/(?:api|v\d+)/[a-zA-Z0-9_\-/]+', js_text))
        if apis:
            print(f"Found APIs in {js}: {apis}")
    except Exception as e:
        pass
