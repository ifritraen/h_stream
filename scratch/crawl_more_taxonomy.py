from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()

pages_to_check = [
    'https://hentaverse.com/',
    'https://hentaverse.com/trending',
    'https://hentaverse.com/newest',
]

all_taxonomy = {}

def extract_from_html(html):
    chunks = re.findall(r'self\.__next_f\.push\(\[(\d+),"(.*?)"\]\)', html, re.DOTALL)
    all_unescaped = []
    for c_num, c_str in chunks:
        try:
            all_unescaped.append(json.loads(f'"{c_str}"'))
        except Exception:
            all_unescaped.append(c_str.replace('\\"', '"').replace('\\\\', '\\'))
    full_rsc = "\n".join(all_unescaped)
    
    # Match all category/tag JSON objects
    # Pattern: {"id":"cmbkj...","name":"...","description":"...","slug":"...","image":"...","videosCount":...}
    matches = re.finditer(r'\{[^{}]*?"id":"(cmbkj[a-zA-Z0-9]+)"[^{}]*?\}', full_rsc)
    for m in matches:
        try:
            data = json.loads(m.group(0))
            slug = data.get('slug')
            if slug and ('name' in data):
                if slug not in all_taxonomy or (data.get('videosCount') and not all_taxonomy[slug].get('videosCount')):
                    all_taxonomy[slug] = data
        except Exception:
            pass

# Also load existing categories and video rsc
with open('scratch/categories_rsc.txt', 'r', encoding='utf-8') as f:
    rsc = f.read()
    matches = re.finditer(r'\{[^{}]*?"id":"(cmbkj[a-zA-Z0-9]+)"[^{}]*?\}', rsc)
    for m in matches:
        try:
            data = json.loads(m.group(0))
            slug = data.get('slug')
            if slug and 'name' in data:
                all_taxonomy[slug] = data
        except Exception:
            pass

with open('scratch/video_rsc.txt', 'r', encoding='utf-8') as f:
    rsc = f.read()
    matches = re.finditer(r'\{[^{}]*?"id":"(cmbkj[a-zA-Z0-9]+)"[^{}]*?\}', rsc)
    for m in matches:
        try:
            data = json.loads(m.group(0))
            slug = data.get('slug')
            if slug and 'name' in data:
                if slug not in all_taxonomy or (data.get('videosCount') and not all_taxonomy[slug].get('videosCount')):
                    all_taxonomy[slug] = data
        except Exception:
            pass

for url in pages_to_check:
    try:
        r = fetcher.get(url, headers=headers, timeout=15)
        html = r.body.decode('utf-8', errors='ignore')
        extract_from_html(html)
        print(f"Checked {url}, total taxonomy collected so far: {len(all_taxonomy)}")
    except Exception as e:
        print(f"Error on {url}: {e}")

print(f"\nFinal count of taxonomy items: {len(all_taxonomy)}")
for slug, d in sorted(all_taxonomy.items()):
    cnt = d.get('videosCount', 'N/A')
    img = d.get('image', 'N/A')
    print(f"  {d.get('name')} (slug: {slug}, count: {cnt}, img: {img})")
