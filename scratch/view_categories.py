import json

with open('scratch/only_hentai_stuff_raw.json', encoding='utf-8') as f:
    data = json.load(f)

print('Categories count:', len(data['categories']))
for c in data['categories']:
    print(f"{c['slug']}: {c['name']} ({c['count']} videos) -> {c['cover']}")
