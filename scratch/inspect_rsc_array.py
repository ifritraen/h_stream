import re
import json

with open('scratch/categories_rsc.txt', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's find all slugs in categories_rsc.txt
slugs = re.findall(r'"slug":"([^"]+)"', text)
print(f"Total slugs in RSC: {len(slugs)} -> {set(slugs)}")

# Find all occurrences of "uploads/categories/
imgs = re.findall(r'"uploads/categories/([^"]+)"', text)
print(f"Total images in RSC: {len(imgs)} -> {set(imgs)}")

# Let's inspect the entire JSON array that starts with [{"id":
start = text.find('[{"id":')
print("Start of array:", start)
if start != -1:
    # Find matching closing bracket
    depth = 0
    end = -1
    for i in range(start, len(text)):
        if text[i] == '[':
            depth += 1
        elif text[i] == ']':
            depth -= 1
            if depth == 0:
                end = i
                break
    print("End of array:", end)
    if end != -1:
        arr_str = text[start:end+1]
        try:
            data = json.loads(arr_str)
            print("Successfully loaded array! Items:", len(data))
            with open('scratch/all_harvested_categories.json', 'w', encoding='utf-8') as f_out:
                json.dump(data, f_out, indent=2, ensure_ascii=False)
            print("Saved all_harvested_categories.json successfully!")
            for idx, c in enumerate(data):
                print(f"{idx+1}. {c['name']} (slug: {c['slug']}, count: {c.get('videosCount')})")
        except Exception as e:
            print("JSON load error:", e)
            print("Near error snippet:", arr_str[:500])
