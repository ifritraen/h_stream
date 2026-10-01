from scrapling.fetchers import Fetcher
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

# 1. Inspect a playlist page
test_pl_url = "https://hentai.sh/playlist/cmpsnu0xn000rirbwlmwmgjtu"
resp_pl = Fetcher.get(test_pl_url, headers=headers)
html_pl = resp_pl.body.decode('utf-8', errors='ignore')
print(f"Playlist {test_pl_url} status: {resp_pl.status}, len: {len(html_pl)}")

# Extract title, creator, count, video cards
title = re.search(r'<h1[^>]*>(.*?)</h1>', html_pl)
print("Playlist title:", title.group(1) if title else "none")

video_links = re.findall(r'href="(/video/[^"]+)"', html_pl)
print(f"Found {len(video_links)} videos in playlist. Sample: {video_links[:5]}")

# 2. Extract all playlists from community page
resp_com = Fetcher.get('https://hentai.sh/community', headers=headers)
html_com = resp_com.body.decode('utf-8', errors='ignore')

# find all playlist cards: href="/playlist/..."
cards = re.findall(r'<a[^>]+href="(/playlist/[^"]+)"[^>]*>.*?</a>', html_com, re.DOTALL)
print(f"\nTotal playlist cards on community page: {len(cards)}")
for c in cards[:5]:
    print("--- Card sample ---")
    print(c[:300])
