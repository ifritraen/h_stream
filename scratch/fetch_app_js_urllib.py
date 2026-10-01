import urllib.request
import re

req = urllib.request.Request(
    'https://hentai.ht/assets/app.js',
    headers={
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'Referer': 'https://hentai.ht/',
    }
)
try:
    with urllib.request.urlopen(req) as resp:
        content = resp.read().decode('utf-8', errors='ignore')
        print(f"app.js fetched: {len(content)} characters")
        # Find stream or video or embed endpoints
        urls = re.findall(r'https?://[^\s"\'`<>]+', content)
        print("Sample URLs found in app.js:", urls[:20])
        # Look for video file or api pattern
        matches = re.findall(r'["\'](/[^"\']*(?:api|video|stream|embed|watch|title|catalog)[^"\']*)["\']', content)
        print("Paths found in app.js:", set(matches[:30]))
except Exception as e:
    print("Error fetching app.js:", e)
