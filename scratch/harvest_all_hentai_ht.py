import requests
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

session = requests.Session()
session.headers.update({
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Origin': 'https://hentai.ht',
    'Referer': 'https://hentai.ht/',
})

# 1. Post age confirmation
r_post = session.post("https://hentai.ht/api/v1/age-confirmation", json={})
print(f"POST age-confirmation status: {r_post.status_code}")
cookie_val = session.cookies.get('__Secure-hht_age')
print(f"Cookie received: {cookie_val[:30]}...")

# 2. Fetch /api/v1/catalog/meta
r_meta = session.get("https://hentai.ht/api/v1/catalog/meta")
meta_data = r_meta.json()
print("Meta facets keys:", meta_data.get('facets', {}).keys())

tags = meta_data.get('facets', {}).get('tags', [])
studios = meta_data.get('facets', {}).get('studios', [])
years = meta_data.get('facets', {}).get('years', [])

print(f"Harvested {len(tags)} tags, {len(studios)} studios, {len(years)} years")
print("Top 10 tags:", tags[:10])
print("Top 10 studios:", studios[:10])

# 3. Fetch /api/v1/catalog page 1
r_cat = session.get("https://hentai.ht/api/v1/catalog?page=1")
cat_data = r_cat.json()
print(f"\nCatalog page 1 status: {r_cat.status_code}")
print(f"Catalog keys: {cat_data.keys()}")
items = cat_data.get('items', [])
print(f"Items on page 1: {len(items)}")
if items:
    print("Sample item 1:", json.dumps(items[0], indent=2))

# 4. Fetch playback for sample title
sample_slug = items[0].get('slug') or 'overflow'
r_play = session.get(f"https://hentai.ht/api/v1/playback/{sample_slug}/1?language=eng&censorship=censored")
print(f"\nPlayback for {sample_slug}/1 status: {r_play.status_code}")
if r_play.status_code == 200:
    play_data = r_play.json()
    print("Playback keys:", play_data.keys())
    print("Sample playback:", json.dumps(play_data, indent=2))
else:
    # Try with language=en
    r_play2 = session.get(f"https://hentai.ht/api/v1/playback/{sample_slug}/1?language=en&censorship=censored")
    print(f"Playback with language=en: {r_play2.status_code}, body: {r_play2.text[:200]}")

# 5. Save everything to scratch/hentai_ht_harvest.json
output_data = {
    'catalogCount': meta_data.get('catalogCount', 615),
    'tags': tags,
    'studios': studios,
    'years': years,
    'sampleItems': items[:30]
}

with open("scratch/hentai_ht_harvest.json", "w", encoding="utf-8") as f:
    json.dump(output_data, f, indent=2, ensure_ascii=False)

print("Saved scratch/hentai_ht_harvest.json successfully!")
