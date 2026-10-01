from scrapling.fetchers import Fetcher
import re

fetcher = Fetcher()
r = fetcher.get("https://hentai.ht/")
body = r.body.decode('utf-8', errors='ignore')

# Find all script src
scripts = re.findall(r'<script[^>]*src=[\'"]([^\'"]+)[\'"]', body)
print("Scripts found:", scripts)

# Find any inline scripts
inline = re.findall(r'<script(?![^>]*src)[^>]*>(.*?)</script>', body, re.DOTALL)
print(f"Inline scripts found: {len(inline)}")
for idx, s in enumerate(inline):
    print(f"Inline {idx} ({len(s)} chars): {s[:150]}...")

# Also check catalog page HTML
rcat = fetcher.get("https://hentai.ht/catalog")
cat_body = rcat.body.decode('utf-8', errors='ignore')
cat_scripts = re.findall(r'<script[^>]*src=[\'"]([^\'"]+)[\'"]', cat_body)
print("Catalog scripts:", cat_scripts)
