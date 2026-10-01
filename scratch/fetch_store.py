import urllib.request
import re

req = urllib.request.Request(
    'https://hentai.ht/assets/store-DGH5-S3y.js',
    headers={
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://hentai.ht/',
    }
)
try:
    with urllib.request.urlopen(req) as resp:
        content = resp.read().decode('utf-8', errors='ignore')
        print(f"store fetched: {len(content)} characters")
        with open("scratch/store.js", "w", encoding="utf-8") as out:
            out.write(content)
        # Search for paths
        fetches = re.findall(r'fetch\([^\)]+\)', content)
        print("Fetches in store.js:", set(fetches[:10]))
        paths = re.findall(r'["\'](/[a-zA-Z0-9_/.-]+)["\']', content)
        print("Paths in store.js:", set([p for p in paths if not p.endswith('.js') and not p.endswith('.svg')][:20]))
except Exception as e:
    print("Error fetching store.js:", e)
