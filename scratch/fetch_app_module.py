import urllib.request
import re

req = urllib.request.Request(
    'https://hentai.ht/assets/App-9oySkwmC.js',
    headers={
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://hentai.ht/',
    }
)
try:
    with urllib.request.urlopen(req) as resp:
        content = resp.read().decode('utf-8', errors='ignore')
        print(f"App-9oySkwmC.js fetched: {len(content)} characters")
        with open("scratch/App.js", "w", encoding="utf-8") as out:
            out.write(content)
        # Search for paths
        paths = re.findall(r'["\'](/api/[^"\']*)["\']', content)
        print("API paths found in App.js:", set(paths))
        # Search for fetch calls
        fetches = re.findall(r'fetch\(([^)]+)\)', content)
        print("Fetch calls in App.js:", set(fetches[:10]))
        # Search for m3u8 or mp4
        streams = re.findall(r'https?://[^\s"\'`<>]+', content)
        print("URLs in App.js:", set(streams[:15]))
except Exception as e:
    print("Error fetching App.js:", e)
