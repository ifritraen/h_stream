from scrapling.fetchers import Fetcher
import re

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

test_urls = [
    f"{BASE_URL}/brand/pink-pineapple",
    f"{BASE_URL}/studio/pink-pineapple",
    f"{BASE_URL}/browse?brand=Pink+Pineapple",
    f"{BASE_URL}/browse?brand=pink-pineapple",
    f"{BASE_URL}/api/search?brand=Pink+Pineapple",
    f"{BASE_URL}/api/search?q=Pink+Pineapple",
]

for u in test_urls:
    try:
        p = Fetcher.get(u, headers=HEADERS, timeout=10)
        print(f"{u} -> status: {p.status}, len: {len(p.body)}")
        html = p.body.decode('utf-8', errors='ignore')
        m = re.search(r'<title>(.*?)</title>', html)
        if m:
            print("  Title:", m.group(1))
    except Exception as e:
        print(f"{u} -> {e}")
