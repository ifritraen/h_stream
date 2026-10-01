import re
import json

with open('scratch/categories_page.html', 'r', encoding='utf-8') as f:
    html = f.read()

# Let's find JSON array of categories
# Look for pattern like [{"id":...,"name":...,"slug":...}] or similar
match = re.search(r'\[\{"id":"[a-zA-Z0-9]+","name":.+?"videosCount":\d+\}\]', html)
if not match:
    # Try finding starting with [{"id": and search for ending of array
    start_pos = html.find('{"id":"')
    print("Found '{\"id\":\"' at pos:", start_pos)
    if start_pos != -1:
        # Find the start of the array or object
        arr_start = html.rfind('[', 0, start_pos)
        print("arr_start:", arr_start)
        # Scan forward to find closing bracket
        # Let's extract candidate
        for end_pos in range(start_pos + 1000, len(html)):
            if html[end_pos] == ']':
                sub = html[arr_start:end_pos+1]
                try:
                    data = json.loads(sub)
                    if isinstance(data, list) and len(data) > 0 and 'name' in data[0]:
                        print(f"Successfully parsed categories array! Count: {len(data)}")
                        with open('scratch/harvested_categories.json', 'w', encoding='utf-8') as out_f:
                            json.dump(data, out_f, indent=2)
                        print("Saved scratch/harvested_categories.json!")
                        break
                except Exception:
                    pass

# Also let's search for tags or genres in the HTML!
print("\n--- Searching for tags / genres in categories_page.html ---")
tag_matches = set(re.findall(r'"(?:tags|genres|tag|genre)":\s*(\[[^\]]+\])', html))
print("Tag/genre json matches:", len(tag_matches))
for tm in tag_matches:
    print("  tm:", tm[:200])

all_words = set(re.findall(r'/(?:tag|tags|genre|genres)/[a-zA-Z0-9_\-]+', html))
print("Tag/genre url matches in HTML:", all_words)
