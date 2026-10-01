import re
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup
from collections import Counter
from concurrent.futures import ThreadPoolExecutor

headers = {'User-Agent': 'Mozilla/5.0'}

# 1. Fetch homepage and page 2, 3 to get ~90 video URLs
video_urls = []
for p in ['', 'new/2/', 'new/3/']:
    url = f'https://hentaipro.net/{p}'
    res = Fetcher.get(url, headers=headers)
    soup = BeautifulSoup(res.body, 'html.parser')
    for a in soup.select('article a, .h2-card a'):
        href = a.get('href', '')
        if href.endswith('.html') and href not in video_urls:
            video_urls.append(href)

print(f"Collected {len(video_urls)} video URLs for tag inspection")

# 2. Extract tags from video detail pages
def get_video_tags(v_url):
    try:
        res = Fetcher.get(v_url, headers=headers)
        soup = BeautifulSoup(res.body, 'html.parser')
        tags = []
        for chip in soup.select('.h2-chiprow a.tag, a.tag'):
            href = chip.get('href', '')
            name = chip.get_text(strip=True)
            if href and name:
                path = href.replace('https://sexhentai.net', '').replace('https://hentaipro.net', '')
                tags.append((path, name))
        
        # Also get studio if present
        studio_el = soup.select_one('a[href*="/studio/"]')
        if studio_el:
            spath = studio_el.get('href', '').replace('https://sexhentai.net', '').replace('https://hentaipro.net', '')
            sname = studio_el.get_text(strip=True)
            tags.append((spath, sname))
            
        return tags
    except Exception as e:
        return []

with ThreadPoolExecutor(max_workers=10) as ex:
    tag_lists = list(ex.map(get_video_tags, video_urls[:50]))

tag_counter = Counter()
for t_list in tag_lists:
    for t in t_list:
        tag_counter[t] += 1

print(f"\nExtracted {len(tag_counter)} distinct tags from 50 video pages:")
for (path, name), count in tag_counter.most_common(50):
    print(f"  {path:35} | {name:25} | count in sample: {count}")
