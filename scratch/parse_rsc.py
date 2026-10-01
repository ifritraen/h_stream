import re
import json

with open('scratch/categories_page.html', 'r', encoding='utf-8') as f:
    html = f.read()

# Let's see the context around "shota"
idx = html.find('shota')
print("Index of shota:", idx)
if idx != -1:
    print(html[idx-200:idx+300])

# Next.js RSC chunks are typically in self.__next_f.push([1, "..."])
# Let's search for self.__next_f.push
chunks = re.findall(r'self\.__next_f\.push\(\[(\d+),"(.*?)"\]\)', html, re.DOTALL)
print(f"Total self.__next_f chunks: {len(chunks)}")

all_unescaped = []
for c_num, c_str in chunks:
    # Unescape JS string
    try:
        unescaped = json.loads(f'"{c_str}"')
        all_unescaped.append(unescaped)
    except Exception as e:
        # Fallback raw replacement
        all_unescaped.append(c_str.replace('\\"', '"').replace('\\\\', '\\'))

full_rsc = "\n".join(all_unescaped)
with open('scratch/categories_rsc.txt', 'w', encoding='utf-8') as f:
    f.write(full_rsc)
print("Saved scratch/categories_rsc.txt, len:", len(full_rsc))

# Look for categories inside full_rsc
cat_arr_match = re.search(r'\[\{"id":"[a-zA-Z0-9]+","name":.*?\}\]', full_rsc)
if cat_arr_match:
    print("Found category array match! len:", len(cat_arr_match.group(0)))
    try:
        cats = json.loads(cat_arr_match.group(0))
        print("Parsed categories count:", len(cats))
        print("First 3 categories:", cats[:3])
        with open('scratch/categories_parsed.json', 'w', encoding='utf-8') as out_f:
            json.dump(cats, out_f, indent=2)
    except Exception as e:
        print("Parse error on cat_arr_match:", e)
else:
    print("No cat_arr_match regex, searching for bracketed structures...")
    # Find all objects with "videosCount"
    obj_matches = re.findall(r'\{[^{}]*"name"[^{}]*"slug"[^{}]*"videosCount":\s*\d+[^{}]*\}', full_rsc)
    print("Found object matches:", len(obj_matches))
    if obj_matches:
        print("First match:", obj_matches[0])
