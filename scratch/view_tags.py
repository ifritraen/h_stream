import json

with open('scratch/only_hentai_stuff_raw.json', encoding='utf-8') as f:
    data = json.load(f)

tags = data['tags']
print(f'Total tags: {len(tags)}')
print('Sample tags:')
for t in tags[:50]:
    print(f"{t['slug']}: {t['name']}")
