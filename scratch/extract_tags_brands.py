import sys
sys.stdout.reconfigure(encoding='utf-8')

from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

resp_b = Fetcher.get('https://hentai.sh/browse', headers=headers)
html_b = resp_b.body.decode('utf-8', errors='ignore')

# Search for allTags
idx = html_b.find('allTags')
print("Index of allTags:", idx)
if idx != -1:
    snippet = html_b[idx:idx+400]
    print("Snippet:", snippet)

# Let's extract the exact array string
tag_start = html_b.find('[', idx)
# Bracket counting
depth = 0
end = tag_start
for i in range(tag_start, len(html_b)):
    if html_b[i] == '[':
        depth += 1
    elif html_b[i] == ']':
        depth -= 1
        if depth == 0:
            end = i + 1
            break

raw_tags_str = html_b[tag_start:end]
print(f"Extracted raw_tags_str length: {len(raw_tags_str)}")
# Clean escaped quotes if needed
if '\\"' in raw_tags_str:
    clean_tags_str = raw_tags_str.replace('\\"', '"').replace('\\\\', '\\')
else:
    clean_tags_str = raw_tags_str

try:
    tags = json.loads(clean_tags_str)
    print(f"Successfully parsed {len(tags)} tags/genres!")
    print("First 5:", tags[:5])
    print("Last 5:", tags[-5:])
except Exception as e:
    print("JSON load error:", e)
    print("Snippet around error:", clean_tags_str[:300])

# Now for allBrands
b_idx = html_b.find('allBrands')
print("\nIndex of allBrands:", b_idx)
if b_idx != -1:
    b_tag_start = html_b.find('[', b_idx)
    depth = 0
    b_end = b_tag_start
    for i in range(b_tag_start, len(html_b)):
        if html_b[i] == '[':
            depth += 1
        elif html_b[i] == ']':
            depth -= 1
            if depth == 0:
                b_end = i + 1
                break
    raw_brands_str = html_b[b_tag_start:b_end]
    if '\\"' in raw_brands_str:
        clean_brands_str = raw_brands_str.replace('\\"', '"').replace('\\\\', '\\')
    else:
        clean_brands_str = raw_brands_str
    try:
        brands = json.loads(clean_brands_str)
        print(f"Successfully parsed {len(brands)} brands/studios!")
        print("First 5:", brands[:5])
        print("Last 5:", brands[-5:])
    except Exception as e:
        print("Brands JSON load error:", e)
