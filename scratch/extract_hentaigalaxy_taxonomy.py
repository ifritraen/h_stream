import json
import re
from pathlib import Path
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaigalaxy.me/',
}

# 1. Probing mirrors via Scrapling Fetcher
mirrors = [
    'https://hentaigalaxy.me',
    'https://hentaigalaxy.tv',
    'https://hentaigalaxy.xyz',
    'https://hentaigalaxy.com',
]

active_mirror = None
print("[Scrapling] Probing live mirrors...")
for m in mirrors:
    try:
        page = Fetcher.get(m, headers=headers, timeout=5)
        if page.status == 200:
            active_mirror = m
            print(f"Active mirror found: {m}")
            break
    except Exception as e:
        print(f"Mirror {m} probe error: {e}")

# 2. Extract canonical taxonomy from existing source routes and filters
source_file = Path("lib/extensions/sources/hentai_galaxy_extension.dart")
content = source_file.read_text(encoding="utf-8")

# Extract tabs
tabs = re.findall(r'ExtensionTab\(\s*id:\s*"([^"]+)",\s*title:\s*"([^"]+)"', content)
print(f"Extracted Tabs: {tabs}")

# Extract sample items to aggregate real tags and series
tags_found = set()
studios_found = set()
series_found = set()
for m in re.finditer(r'tags:\s*\[(.*?)\]', content):
    raw_tags = m.group(1)
    for t in re.findall(r'"([^"]+)"', raw_tags):
        tags_found.add(t)

for m in re.finditer(r'studio:\s*"([^"]+)"', content):
    studios_found.add(m.group(1))

for m in re.finditer(r'title:\s*"([^"]+)"', content):
    title = m.group(1)
    if ":" in title:
        series_found.add(title.split(":")[0].strip())
    else:
        series_found.add(title.strip())

print(f"Unique Tags found in source: {len(tags_found)}")
print(f"Unique Studios found: {len(studios_found)}")
print(f"Unique Series found: {len(series_found)}")

# Output summary to scratch
summary = {
    "active_mirror": active_mirror,
    "tabs": tabs,
    "tags": sorted(list(tags_found)),
    "studios": sorted(list(studios_found)),
    "series": sorted(list(series_found)),
}

with open("scratch/hentaigalaxy_harvested_summary.json", "w", encoding="utf-8") as f:
    json.dump(summary, f, indent=2)

print("Harvested summary written to scratch/hentaigalaxy_harvested_summary.json")
