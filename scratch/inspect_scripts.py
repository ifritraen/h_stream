from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()
page = fetcher.get('https://hentaverse.com/categories/', headers=headers, timeout=15)

html = page.html if hasattr(page, 'html') else page.body.decode('utf-8', errors='ignore')

# Check script tags
scripts = page.css('script')
print(f"Total script tags: {len(scripts)}")
for i, s in enumerate(scripts):
    s_id = s.attrib.get('id', '')
    s_src = s.attrib.get('src', '')
    s_type = s.attrib.get('type', '')
    text = s.get_all_text().strip()
    print(f"Script {i}: id='{s_id}', src='{s_src}', type='{s_type}', text_len={len(text)}")
    if '__NEXT_DATA__' in s_id or 'json' in s_type:
        print("  JSON Content Preview:", text[:500])
        try:
            data = json.loads(text)
            print("  JSON keys:", list(data.keys()))
            if 'props' in data:
                print("  pageProps keys:", list(data['props'].get('pageProps', {}).keys()))
                # Save data to inspect
                with open('scratch/next_data_categories.json', 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2)
                print("  Saved next_data_categories.json!")
        except Exception as e:
            print("  JSON parse error:", e)

# Also search for API endpoints or json in text
api_matches = set(re.findall(r'/(?:api|v\d+)/[a-zA-Z0-9_\-/]+', html))
print(f"API endpoints found in HTML: {api_matches}")

# Also search for categories in raw HTML or scripts
cat_matches = set(re.findall(r'/categories/[a-zA-Z0-9_\-]+', html))
print(f"/categories/... matches: {len(cat_matches)} -> {list(cat_matches)[:20]}")
