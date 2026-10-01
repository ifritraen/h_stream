import sys
sys.stdout.reconfigure(encoding='utf-8')
from scrapling.fetchers import Fetcher
import re

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaistream.xxx/',
}

res = fetcher.get('https://hentaistream.xxx/', headers=headers)
print("Homepage status:", res.status)

# Find all unique links
all_links = set()
for a in res.css('a'):
    href = a.attrib.get('href')
    text = a.text
    if href:
        all_links.add((href, text.strip() if text else ""))

print("Unique links on homepage:")
for href, text in sorted(all_links):
    if any(k in href for k in ['genre', 'tag', 'cat', 'sort', 'popular', 'top', 'list', 'page', 'video']):
        print(f"  {href} -> '{text}'")

# Also check video page to see what tags are on video pages!
video_links = [h for h, t in all_links if '/hentai/' in h or '/video/' in h or '/watch/' in h or re.search(r'/[a-z0-9-]+/', h)]
print(f"\nSample video/post links: {video_links[:5]}")

if video_links:
    sample_video_url = video_links[0]
    if not sample_video_url.startswith('http'):
        sample_video_url = f"https://hentaistream.xxx{sample_video_url}"
    print(f"\nFetching sample video page: {sample_video_url}")
    vres = fetcher.get(sample_video_url, headers=headers)
    print("Video page status:", vres.status)
    tag_links = vres.css('a[href*="/tag/"], a[href*="/genre/"], a[href*="/category/"]').getall()
    print(f"Found {len(tag_links)} tag/genre links on video page:")
    for t in tag_links[:20]:
        print("  ", t)
