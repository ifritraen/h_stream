import urllib.request
import re

req = urllib.request.Request(
    'https://hentai.ht/assets/useCatalog-Bn00lZKp.js',
    headers={
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://hentai.ht/',
    }
)
try:
    with urllib.request.urlopen(req) as resp:
        content = resp.read().decode('utf-8', errors='ignore')
        print(f"useCatalog fetched: {len(content)} characters")
        with open("scratch/useCatalog.js", "w", encoding="utf-8") as out:
            out.write(content)
        # Search for fetch calls
        fetches = re.findall(r'fetch\([^\)]+\)', content)
        print("Fetches in useCatalog.js:", set(fetches[:10]))
        # Search for paths
        paths = re.findall(r'["\'](/[^"\']*)["\']', content)
        print("Paths in useCatalog.js:", set([p for p in paths if not p.endswith('.js')][:20]))
except Exception as e:
    print("Error fetching useCatalog.js:", e)
