from scrapling.fetchers import Fetcher
import json
import re

fetcher = Fetcher()

# 1. Inspect Inline 0 schema
r = fetcher.get("https://hentai.ht/")
body = r.body.decode('utf-8', errors='ignore')
schema_match = re.search(r'<script type="application/ld\+json"[^>]*>(.*?)</script>', body, re.DOTALL)
if schema_match:
    try:
        data = json.loads(schema_match.group(1))
        print("Schema JSON keys:", data.keys())
        if '@graph' in data:
            print(f"Graph items count: {len(data['@graph'])}")
            for item in data['@graph'][:5]:
                print(f"  Type: {item.get('@type')}, Name/ID: {item.get('name') or item.get('@id')}")
    except Exception as e:
        print("Schema parse error:", e)

# 2. Inspect /assets/app.js
rapp = fetcher.get("https://hentai.ht/assets/app.js")
print(f"\n/assets/app.js status: {rapp.status}, length: {len(rapp.body)}")
js = rapp.body.decode('utf-8', errors='ignore')

# Search for endpoints, URLs, API paths in app.js
api_patterns = re.findall(r'["\'](/(?:api|v1|v2|catalog|title|stream|watch|data|json)[^"\']*)["\']', js)
print("API / Endpoint paths in app.js:", set(api_patterns[:30]))

# Search for domain or CDN references
cdn_patterns = re.findall(r'https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?:/[a-zA-Z0-9._~:/?#[\]@!$&\'()*+,;=-]*)?', js)
print("Domains found in app.js:", set(re.findall(r'https?://([a-zA-Z0-9.-]+)', js)))

# Search for video player or stream patterns
player_matches = re.findall(r'[a-zA-Z0-9_$]+(?:\.m3u8|\.mp4)', js)
print("Media matches:", set(player_matches[:20]))

# Look for video URL constructor / template string
stream_templates = re.findall(r'[`"\'][^`"\']*(?:stream|video|player|hls|m3u8|embed)[^`"\']*[`"\']', js, re.IGNORECASE)
print("Stream templates / mentions:", set(stream_templates[:20]))
