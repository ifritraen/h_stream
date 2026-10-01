import re
import json

with open('scratch/video_rsc.txt', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's search for "categories":\[.*?\]
matches = re.finditer(r'"categories":(\[\{.*?\}\])', text)
for m in matches:
    try:
        data = json.loads(m.group(1))
        print(f"Found categories array with {len(data)} items:")
        for item in data:
            print(f"  {item['name']} (slug: {item['slug']}, id: {item['id']})")
    except Exception as e:
        print("Error parsing categories array:", e)

# Also check for video details: title, url, poster/thumbnail, streams
title_m = re.search(r'"title":"(.*?)"', text)
if title_m:
    print("Video title:", title_m.group(1))

# Check for video players, m3u8 or mp4
urls = set(re.findall(r'https?://[^\s"\'<>]+\.(?:mp4|m3u8|webp|jpg|png)', text))
print("Media URLs in video RSC:", len(urls))
for u in sorted(list(urls)):
    print("  ", u)
