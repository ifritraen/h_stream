import json
import re

with open('scratch/categories_rsc.txt', 'r', encoding='utf-8') as f:
    text = f.read()

# Find all occurrences of "categories":[{...}]
all_categories = {}

# Match all JSON objects with id, name, slug, videosCount
# Let's find every `{"id":"cmbkj[a-zA-Z0-9]+",...}`
pattern = r'\{"id":"(cmbkj[a-zA-Z0-9]+)","name":"(.*?)","description":"(.*?)","metaTitle":".*?","metaDescription":".*?","slug":"(.*?)","image":"(.*?)","createdAt":".*?","updatedAt":".*?","videosCount":(\d+)\}'

matches = re.findall(pattern, text)
print(f"Total regex matches: {len(matches)}")
for m in matches:
    cid, name, desc, slug, img, count = m
    all_categories[slug] = {
        "id": cid,
        "name": name,
        "description": desc,
        "slug": slug,
        "image": f"https://hentaverse.com/{img}" if not img.startswith('http') else img,
        "videosCount": int(count)
    }

print(f"Unique categories found: {len(all_categories)}")
for slug, data in sorted(all_categories.items()):
    print(f"  {data['name']} (slug: {slug}, count: {data['videosCount']}, image: {data['image']})")

with open('scratch/all_hentaverse_categories.json', 'w', encoding='utf-8') as f:
    json.dump(list(all_categories.values()), f, indent=2, ensure_ascii=False)
print("Saved scratch/all_hentaverse_categories.json!")
