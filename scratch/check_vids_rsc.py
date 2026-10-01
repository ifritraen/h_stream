from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()
r = fetcher.get('https://hentaverse.com/categories/school-girl', headers=headers, timeout=10)
html = r.body.decode('utf-8', errors='ignore')

chunks = re.findall(r'self\.__next_f\.push\(\[(\d+),"(.*?)"\]\)', html, re.DOTALL)
all_unescaped = []
for c_num, c_str in chunks:
    try:
        all_unescaped.append(json.loads(f'"{c_str}"'))
    except Exception:
        all_unescaped.append(c_str.replace('\\"', '"').replace('\\\\', '\\'))

full_rsc = "\n".join(all_unescaped)

# Search for video objects in RSC
v_objs = re.findall(r'\{"id":"[a-zA-Z0-9_\-]+","title":".*?","slug":".*?".*?\}', full_rsc)
print(f"Video objects matched in RSC: {len(v_objs)}")
if v_objs:
    print("First video object:", v_objs[0][:300])

# Also check for "videos":\[...\]
v_arr = re.findall(r'"videos":\s*(\[\{.*?\}\])', full_rsc)
print(f"Videos array matches in RSC: {len(v_arr)}")
if v_arr:
    try:
        parsed_vids = json.loads(v_arr[0])
        print("Parsed videos from array:", len(parsed_vids))
        print("Keys in video item:", list(parsed_vids[0].keys()))
        print("Sample video:", parsed_vids[0])
    except Exception as e:
        print("Parse error on v_arr:", e)
