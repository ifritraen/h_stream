import json
import re

with open('scratch/video_rsc.txt', 'r', encoding='utf-8') as f:
    text = f.read()

# Match all objects with "id":"cmbkj..."
objs = re.findall(r'\{"id":"(cmbkj[a-zA-Z0-9]+)",.*?"name":"(.*?)",.*?"slug":"(.*?)".*?\}', text)
print(f"Total objects matched in video_rsc: {len(objs)}")

# Let's also do a broader search for all JSON-like objects with "slug" and "name"
all_items = {}
matches = re.finditer(r'\{[^{}]*?"id":"(cmbkj[a-zA-Z0-9]+)"[^{}]*?\}', text)
for m in matches:
    obj_str = m.group(0)
    try:
        data = json.loads(obj_str)
        slug = data.get('slug')
        if slug:
            all_items[slug] = data
    except Exception:
        pass

print(f"Direct JSON loaded items from video_rsc: {len(all_items)}")

# Let's inspect the entire `video_rsc.txt` for all slugs
slug_matches = set(re.findall(r'"slug":"([a-zA-Z0-9_\-]+)"', text))
print(f"All slugs in video_rsc: {len(slug_matches)}")
print(sorted(list(slug_matches)))
