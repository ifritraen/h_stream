from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()

# Harvest from /categories/, /, /trending, /newest, and video pages
urls = [
    'https://hentaverse.com/categories/',
    'https://hentaverse.com/',
    'https://hentaverse.com/trending',
    'https://hentaverse.com/newest',
    'https://hentaverse.com/video/binetsu-hime-episode-1',
]

all_taxonomy = {}

for url in urls:
    try:
        r = fetcher.get(url, headers=headers, timeout=15)
        html = r.body.decode('utf-8', errors='ignore')
        chunks = re.findall(r'self\.__next_f\.push\(\[(\d+),"(.*?)"\]\)', html, re.DOTALL)
        all_unescaped = []
        for c_num, c_str in chunks:
            try:
                all_unescaped.append(json.loads(f'"{c_str}"'))
            except Exception:
                all_unescaped.append(c_str.replace('\\"', '"').replace('\\\\', '\\'))
        full_rsc = "\n".join(all_unescaped)
        
        matches = re.finditer(r'\{[^{}]*?"id":"(cmbkj[a-zA-Z0-9]+)"[^{}]*?\}', full_rsc)
        for m in matches:
            try:
                data = json.loads(m.group(0))
                slug = data.get('slug')
                if slug and 'name' in data:
                    if slug not in all_taxonomy:
                        all_taxonomy[slug] = data
                    else:
                        if data.get('videosCount', 0) > all_taxonomy[slug].get('videosCount', 0):
                            all_taxonomy[slug] = data
                        if not all_taxonomy[slug].get('image') and data.get('image'):
                            all_taxonomy[slug]['image'] = data['image']
                        if not all_taxonomy[slug].get('description') and data.get('description'):
                            all_taxonomy[slug]['description'] = data['description']
            except Exception:
                pass
    except Exception as e:
        print(f"Error harvesting {url}: {e}")

# Check categories page specifically to mark which ones are on /categories/ (featured categories)
r_cat = fetcher.get('https://hentaverse.com/categories/', headers=headers, timeout=15)
cat_html = r_cat.body.decode('utf-8', errors='ignore')
featured_category_slugs = set(re.findall(r'/categories/([a-zA-Z0-9_\-]+)', cat_html))

print(f"Featured Category Slugs on /categories/: {len(featured_category_slugs)}")
print(f"Total Taxonomy Items Discovered: {len(all_taxonomy)}")

categories_list = []
tags_list = []

for slug, item in sorted(all_taxonomy.items()):
    name = item.get('name', slug.replace('-', ' ').title())
    count = item.get('videosCount', 0)
    image = item.get('image', '')
    if image and not image.startswith('http'):
        image = f"https://hentaverse.com/{image}"
    desc = item.get('description', '')
    
    clean_item = {
        "id": item.get('id', ''),
        "name": name,
        "slug": slug,
        "count": count,
        "image": image,
        "description": desc,
        "endpointPath": f"/categories/{slug}",
    }
    
    if slug in featured_category_slugs:
        categories_list.append(clean_item)
    else:
        tags_list.append(clean_item)

print(f"Divided into Categories: {len(categories_list)}, Tags/Genres: {len(tags_list)}")

with open('scratch/hentaverse_harvested_taxonomy.json', 'w', encoding='utf-8') as f:
    json.dump({
        "categories": categories_list,
        "tags": tags_list,
        "all": list(all_taxonomy.values())
    }, f, indent=2, ensure_ascii=False)

print("Saved scratch/hentaverse_harvested_taxonomy.json successfully!")
