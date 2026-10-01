import json
import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('scratch/categories_parsed.json', 'r', encoding='utf-8') as f:
    cats = json.load(f)

print(f"Total categories parsed: {len(cats)}")
for i, c in enumerate(cats):
    print(f"{i+1}. name='{c.get('name')}', slug='{c.get('slug')}', count={c.get('videosCount')}, img='{c.get('image')}'")
