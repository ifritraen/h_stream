import re
import json

with open('scratch/categories_page.html', 'r', encoding='utf-8') as f:
    html = f.read()

# Find all category objects
# Pattern: "id":"...","name":"...","description":"...","metaTitle":...,"slug":"...","image":"...","createdAt":...,"videosCount":...
cat_matches = re.findall(r'\{"id":"[a-zA-Z0-9]+","name":"(?:[^"\\]|\\.)*?","description":"(?:[^"\\]|\\.)*?",.*?"slug":"(?:[^"\\]|\\.)*?",.*?"videosCount":\d+\}', html)
print(f"Total category objects matched via regex: {len(cat_matches)}")

parsed_cats = []
seen_slugs = set()
for cm in cat_matches:
    # Unescape
    clean = cm.replace('\\"', '"').replace('\\\\', '\\').replace('\\n', '\n')
    try:
        data = json.loads(clean)
        slug = data.get('slug')
        if slug and slug not in seen_slugs:
            seen_slugs.add(slug)
            parsed_cats.append(data)
    except Exception as e:
        # Fallback manual extraction
        name = re.search(r'"name":"(.*?)"', clean)
        slug = re.search(r'"slug":"(.*?)"', clean)
        cnt = re.search(r'"videosCount":(\d+)', clean)
        img = re.search(r'"image":"(.*?)"', clean)
        desc = re.search(r'"description":"(.*?)"', clean)
        if slug and slug.group(1) not in seen_slugs:
            seen_slugs.add(slug.group(1))
            parsed_cats.append({
                "name": name.group(1) if name else slug.group(1),
                "slug": slug.group(1),
                "videosCount": int(cnt.group(1)) if cnt else 0,
                "image": img.group(1) if img else "",
                "description": desc.group(1) if desc else "",
            })

print(f"Parsed unique categories: {len(parsed_cats)}")
for i, c in enumerate(parsed_cats):
    print(f"{i+1}. {c['name']} (slug: {c['slug']}, count: {c['videosCount']}, image: {c.get('image', '')})")

with open('scratch/all_harvested_categories.json', 'w', encoding='utf-8') as out_f:
    json.dump(parsed_cats, out_f, indent=2, ensure_ascii=False)
