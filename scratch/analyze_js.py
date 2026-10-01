import sys
import re
import requests

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.iwara.tv/',
}

r = requests.get('https://www.iwara.tv/main.838884031a28ff0e346d.js', headers=headers)
print("JS bundle size:", len(r.text))
js = r.text

# Search for api endpoints, tag types, params
endpoints = set(re.findall(r'["\'](/api/[^"\']+|/videos[^"\']*|/tags[^"\']*|/search[^"\']*)["\']', js))
print("Endpoints found:", endpoints)

# Find query param patterns
params = set(re.findall(r'([a-zA-Z0-9_]+)=', js[:100000]))
video_refs = set(re.findall(r'videos\?[^"\']+', js))
print("Videos queries:", video_refs)

# Check for categories or tag types
tag_types_matches = re.findall(r'type[:\s]+["\'](general|category|character|franchise|author|source|series)["\']', js, re.I)
print("Tag type matches in JS:", set(tag_types_matches))

# Let's search for "sort" or "rating" or "tags" in JS
matches = re.findall(r'\{[^{}]*sort[^{}]*\}', js)
for m in matches[:5]:
    print("Sort obj:", m)
