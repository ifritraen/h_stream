import json

with open('scratch/all_hentaverse_categories.json', 'r', encoding='utf-8') as f:
    primary28 = {c['slug']: c for c in json.load(f)}

with open('scratch/hentaverse_harvested_taxonomy.json', 'r', encoding='utf-8') as f:
    all_harvested = json.load(f)

all_items = {item['slug']: item for item in all_harvested['all']}

print(f"Primary 28 categories on /categories/ page: {len(primary28)}")
print(f"Total taxonomy items found across site: {len(all_items)}")

categories = []
tags = []

for slug, item in all_items.items():
    if slug in primary28:
        # Merge counts/images if better
        merged = dict(primary28[slug])
        if item.get('videosCount', 0) > merged.get('videosCount', 0):
            merged['videosCount'] = item['videosCount']
        categories.append(merged)
    else:
        tags.append(item)

print(f"\nCategories (Curated /categories/): {len(categories)}")
for c in sorted(categories, key=lambda x: x['slug']):
    print(f"  CAT: {c['name']} ({c['slug']}) - {c.get('videosCount')} videos")

print(f"\nTags / Genres (Content Tropes): {len(tags)}")
for t in sorted(tags, key=lambda x: x['slug']):
    print(f"  TAG: {t['name']} ({t['slug']}) - {t.get('videosCount')} videos")
