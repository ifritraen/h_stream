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

# Extract allTags JSON
all_tags_match = re.search(r'"allTags":(\[.*?\])(?:,"allBrands"|,"allStudios"|,"[a-zA-Z]+":)', html_b)
if all_tags_match:
    tags_json_str = all_tags_match.group(1)
    tags = json.loads(tags_json_str)
    print(f"Total allTags harvested: {len(tags)}")
    print(f"Sample tags (first 10): {tags[:10]}")
    print(f"Sample tags (last 5): {tags[-5:]}")
else:
    print("Could not match allTags regex!")

# Extract allBrands JSON
all_brands_match = re.search(r'"allBrands":(\[.*?\])(?:,"loggedIn"|,"[a-zA-Z]+":)', html_b)
if all_brands_match:
    brands_json_str = all_brands_match.group(1)
    brands = json.loads(brands_json_str)
    print(f"\nTotal allBrands harvested: {len(brands)}")
    print(f"Sample brands (first 10): {brands[:10]}")
else:
    print("Could not match allBrands regex!")
