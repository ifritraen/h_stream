from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup
from collections import Counter
import re

headers = {'User-Agent': 'Mozilla/5.0'}
res = Fetcher.get('https://hentaipro.net/', headers=headers)
soup = BeautifulSoup(res.body, 'html.parser')

video_links = []
for a in soup.select('article a, .h2-card a'):
    href = a.get('href', '')
    if href.endswith('.html') and href not in video_links:
        video_links.append(href)

print(f"Found {len(video_links)} videos on homepage. Sampling 10...")

all_tax_links = Counter()
video_meta_tags = set()

for v_url in video_links[:10]:
    vres = Fetcher.get(v_url, headers=headers)
    vsoup = BeautifulSoup(vres.body, 'html.parser')
    title = vsoup.title.get_text(strip=True) if vsoup.title else "Unknown"
    
    # Check all links inside video details
    v_links = []
    for a in vsoup.find_all('a'):
        h = a.get('href', '')
        t = a.get_text(strip=True)
        if not h.endswith('.html') and h not in ['https://sexhentai.net/', 'https://sexhentai.net', 'https://sexhentai.net/dang-nhap/', 'https://sexhentai.net/dang-ky/']:
            h_clean = h.replace('https://sexhentai.net', '').replace('https://hentaipro.net', '')
            all_tax_links[(h_clean, t)] += 1
            v_links.append((h_clean, t))
    print(f"Video '{title[:30]}': {len(v_links)} tax links: {v_links[:5]}")

print("\nTop taxonomy links found on video pages:")
for (h, t), c in all_tax_links.most_common(30):
    print(f"  {h} ({t}) -> seen {c} times")
