from scrapling.fetchers import Fetcher
import json
import urllib.parse

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

# Test querying search API for a few studios
for studio in ["Pink Pineapple", "Ms Pictures", "Poro", "Queen Bee", "Mary Jane"]:
    q = urllib.parse.quote(studio)
    url = f"{BASE_URL}/api/search?q={q}&limit=3"
    res = Fetcher.get(url, headers=HEADERS, timeout=10)
    data = json.loads(res.body)
    vids = data.get('videos', [])
    print(f"Studio {studio}: {len(vids)} results")
    if vids:
        print(f"  Sample cover: {vids[0].get('cover') or vids[0].get('thumb')}")
