from scrapling.fetchers import Fetcher
import json

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

res = Fetcher.get(f"{BASE_URL}/api/browse?genres=Vanilla", headers=HEADERS, timeout=10)
data = json.loads(res.body)
print(json.dumps(data['videos'][0], indent=2))
