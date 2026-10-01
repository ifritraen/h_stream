import re
from scrapling.fetchers import Fetcher

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

page_genres = Fetcher.get(f"{BASE_URL}/genres", headers=HEADERS, timeout=15)
html = page_genres.body.decode('utf-8', errors='ignore')

# Print lines with cat-card
matches = re.findall(r'(\{\"href\":\"/genre/[^\"]+\"[^\}]*\}\],\[\"\$[^\n]+)', html)
if not matches:
    matches = re.findall(r'\"href\":\"(/genre/[^\"]+)\"[\s\S]*?(?=\"href\"|$)', html)

print(f"Total genre matches: {len(matches)}")
for i, m in enumerate(matches[:5]):
    print(f"--- MATCH {i} ---")
    print(m[:1000])
    print()
