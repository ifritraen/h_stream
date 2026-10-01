from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()

# Test category page
cat_url = 'https://hentaverse.com/categories/school-girl'
res = fetcher.get(cat_url, headers=headers, timeout=15)
text = res.text
print(f"URL {cat_url} status: {res.status if hasattr(res, 'status') else 'OK'}, len: {len(text)}")

with open('scratch/cat_school_girl.html', 'w', encoding='utf-8') as f:
    f.write(text)

# Check video links or card elements
links = res.css('a')
video_links = set()
for a in links:
    href = a.attrib.get('href', '')
    if '/hentai/' in href or '/video/' in href or '/watch/' in href:
        video_links.add(href)

print(f"Video links found on category page: {len(video_links)} -> {list(video_links)[:5]}")

# Check tags on category page
tag_matches = set(re.findall(r'/(?:tag|tags|genre|genres)/[a-zA-Z0-9_\-]+', text))
print("Tag/genre links on category page:", tag_matches)

# Let's inspect a video page to see how tags and videos are structured
if video_links:
    first_vid = list(video_links)[0]
    vid_url = first_vid if first_vid.startswith('http') else f"https://hentaverse.com{first_vid}"
    print(f"\nFetching video page: {vid_url}")
    v_res = fetcher.get(vid_url, headers=headers, timeout=15)
    v_text = v_res.text
    print(f"Video page len: {len(v_text)}")
    with open('scratch/video_page.html', 'w', encoding='utf-8') as f:
        f.write(v_text)
    
    # Check tags on video page
    v_links = v_res.css('a')
    v_tag_links = set()
    for a in v_links:
        href = a.attrib.get('href', '')
        v_tag_links.add(href)
    print(f"All links on video page: {len(v_tag_links)}")
    print("Links with /tag or /genre or /category:", [h for h in v_tag_links if any(x in h for x in ['tag', 'genre', 'cat'])])
