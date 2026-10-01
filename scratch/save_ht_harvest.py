import requests
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

session = requests.Session()
session.headers.update({
    'User-Agent': 'Mozilla/5.0 Chrome/130.0.0.0 Safari/537.36',
    'Origin': 'https://hentai.ht',
    'Referer': 'https://hentai.ht/',
})

session.post("https://hentai.ht/api/v1/age-confirmation", json={})
r_meta = session.get("https://hentai.ht/api/v1/catalog/meta")
meta = r_meta.json()

r_cat = session.get("https://hentai.ht/api/v1/catalog?page=1")
cat = r_cat.json()

harvest = {
    'catalogCount': meta.get('catalogCount', 615),
    'tags': meta.get('facets', {}).get('tags', []),
    'studios': meta.get('facets', {}).get('studios', []),
    'years': meta.get('facets', {}).get('years', []),
    'sampleTitles': cat.get('titles', [])[:30]
}

with open("scratch/hentai_ht_harvest.json", "w", encoding="utf-8") as f:
    json.dump(harvest, f, indent=2, ensure_ascii=False)

print(f"Hentai.ht Harvest Complete: {len(harvest['tags'])} tags, {len(harvest['studios'])} studios, {len(harvest['years'])} years, {len(harvest['sampleTitles'])} titles saved.")
