import sys
import json
import re
import requests

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.iwara.tv/',
}

# 1. Inspect search type=users results
r_u = requests.get('https://api.iwara.tv/search?type=users&query=mmd&limit=3', headers=headers)
print("Users search sample:")
print(json.dumps(r_u.json(), indent=2)[:800])

# 2. Check how tags are structured across /tags endpoint
# We saw count: 3008 tags!
r_tags = requests.get('https://api.iwara.tv/tags?limit=50', headers=headers)
tags_data = r_tags.json()
print(f"Total tags: {tags_data.get('count')}")
tag_types = set()
for t in tags_data.get('results', []):
    tag_types.add(t.get('type'))
print(f"Tag types seen in first 50: {tag_types}")

# 3. Check web HTML to find Nuxt / Next / Vue bundles or API routes
r_page = requests.get('https://www.iwara.tv/videos', headers=headers)
print("Page length:", len(r_page.text))
js_files = re.findall(r'src="([^"]+\.js)"', r_page.text)
print("JS files:", js_files[:5])
