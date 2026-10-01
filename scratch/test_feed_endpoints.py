from scrapling.fetchers import Fetcher
import json
import urllib.parse

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

# 1. Test /genre/vanilla
res_genre = Fetcher.get(f"{BASE_URL}/genre/vanilla", headers=HEADERS, timeout=10)
print(f"/genre/vanilla status: {res_genre.status}, len: {len(res_genre.body)}")

# 2. Test /genre/vanilla?page=2
res_genre_p2 = Fetcher.get(f"{BASE_URL}/genre/vanilla?page=2", headers=HEADERS, timeout=10)
print(f"/genre/vanilla?page=2 status: {res_genre_p2.status}, len: {len(res_genre_p2.body)}")

# 3. Test /api/browse?genres=Vanilla
res_api_genre = Fetcher.get(f"{BASE_URL}/api/browse?genres=Vanilla", headers=HEADERS, timeout=10)
print(f"/api/browse?genres=Vanilla status: {res_api_genre.status}")
try:
    data = json.loads(res_api_genre.body)
    print(f"  total: {data.get('total')}, pages: {data.get('pages')}, videos: {len(data.get('videos', []))}")
    if data.get('videos'):
        print(f"  sample: {data['videos'][0]['title']}")
except Exception as e:
    print(f"  JSON parse error: {e}")

# 4. Test /api/browse?brands=Pink+Pineapple
res_api_brand = Fetcher.get(f"{BASE_URL}/api/browse?brands=Pink%20Pineapple", headers=HEADERS, timeout=10)
print(f"/api/browse?brands=Pink%20Pineapple status: {res_api_brand.status}")
try:
    data = json.loads(res_api_brand.body)
    print(f"  total: {data.get('total')}, pages: {data.get('pages')}, videos: {len(data.get('videos', []))}")
    if data.get('videos'):
        print(f"  sample: {data['videos'][0]['title']}")
except Exception as e:
    print(f"  JSON parse error: {e}")

# 5. Test /api/browse?brands=Pink%20Pineapple&page=2
res_api_brand_p2 = Fetcher.get(f"{BASE_URL}/api/browse?brands=Pink%20Pineapple&page=2", headers=HEADERS, timeout=10)
print(f"/api/browse?brands=Pink%20Pineapple&page=2 status: {res_api_brand_p2.status}")
try:
    data = json.loads(res_api_brand_p2.body)
    print(f"  total: {data.get('total')}, pages: {data.get('pages')}, videos: {len(data.get('videos', []))}")
except Exception as e:
    print(f"  JSON parse error: {e}")
