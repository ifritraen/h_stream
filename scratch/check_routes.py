from scrapling.fetchers import Fetcher
import re

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

routes = [
    "/categories",
    "/genres",
    "/studios",
    "/tags",
    "/brands",
    "/series",
    "/browse",
    "/channels",
    "/makers",
    "/producers",
    "/creators",
]

for r in routes:
    url = f"{BASE_URL}{r}"
    try:
        page = Fetcher.get(url, headers=HEADERS, timeout=10)
        # Check actual URL / title
        html = page.body.decode('utf-8', errors='ignore')
        title_m = re.search(r'<title>(.*?)</title>', html)
        title = title_m.group(1) if title_m else 'No title'
        eyebrow = re.search(r'class="[^"]*eyebrow[^"]*"[^>]*>(.*?)<', html)
        lib_title = re.search(r'class="[^"]*lib-title[^"]*"[^>]*>(.*?)<', html)
        h1 = re.search(r'<h1[^>]*>(.*?)</h1>', html)
        print(f"{r} -> status: {page.status}, len: {len(page.body)}, title: {title}, h1: {h1.group(1) if h1 else None}, lib_title: {lib_title.group(1) if lib_title else None}")
    except Exception as e:
        print(f"{r} -> Error: {e}")
