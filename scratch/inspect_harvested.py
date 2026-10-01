import json

with open('scratch/hentaverse_harvested_taxonomy.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print("Categories count:", len(data['categories']))
print("Tags count:", len(data['tags']))
print("All count:", len(data['all']))

print("\n--- Categories ---")
for c in data['categories'][:10]:
    print(f"  {c['name']} (slug: {c['slug']}, count: {c['count']}, img: {c['image']})")

print("\n--- Tags ---")
for t in data['tags'][:10]:
    print(f"  {t['name']} (slug: {t['slug']}, count: {t['count']}, img: {t['image']})")
