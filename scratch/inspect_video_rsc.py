from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()
r = fetcher.get('https://hentaverse.com/video/binetsu-hime-episode-1', headers=headers, timeout=15)
html = r.body.decode('utf-8', errors='ignore')

with open('scratch/video_page_full.html', 'w', encoding='utf-8') as f:
    f.write(html)

print("Saved scratch/video_page_full.html, len:", len(html))

# Let's extract RSC chunks from video page
chunks = re.findall(r'self\.__next_f\.push\(\[(\d+),"(.*?)"\]\)', html, re.DOTALL)
all_unescaped = []
for c_num, c_str in chunks:
    try:
        unescaped = json.loads(f'"{c_str}"')
        all_unescaped.append(unescaped)
    except Exception:
        all_unescaped.append(c_str.replace('\\"', '"').replace('\\\\', '\\'))

video_rsc = "\n".join(all_unescaped)
with open('scratch/video_rsc.txt', 'w', encoding='utf-8') as f:
    f.write(video_rsc)
print("Saved scratch/video_rsc.txt, len:", len(video_rsc))

# Let's find how categories/tags are stored for this video
# Look for "categories" or "tags" or "genres" in video_rsc
cat_match = re.findall(r'"categories":(\[[^\]]+\])', video_rsc)
print("Categories match in video RSC:", len(cat_match))
for cm in cat_match[:3]:
    print("  cm:", cm[:300])

tag_match = re.findall(r'"tags":(\[[^\]]+\])', video_rsc)
print("Tags match in video RSC:", len(tag_match))
for tm in tag_match[:3]:
    print("  tm:", tm[:300])
