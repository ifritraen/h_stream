import re
import json

with open('scratch/categories_rsc.txt', 'r', encoding='utf-8') as f:
    full_rsc = f.read()

cat_arr_match = re.search(r'\[\{"id":"[a-zA-Z0-9]+","name":.*?\}\]', full_rsc)
if cat_arr_match:
    cats = json.loads(cat_arr_match.group(0))
    with open('scratch/categories_parsed.json', 'w', encoding='utf-8') as out_f:
        json.dump(cats, out_f, indent=2, ensure_ascii=False)
    print("Parsed and saved categories count:", len(cats))
