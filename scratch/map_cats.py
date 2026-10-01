from bs4 import BeautifulSoup

with open('scratch/categories.html', 'r', encoding='utf-8') as f:
    soup = BeautifulSoup(f.read(), 'html.parser')

cat_map = {}
for thumb in soup.select('.thumb'):
    cat_id = thumb.get('data-categories')
    cat_link = thumb.select_one('.cat_text a')
    if cat_id and cat_link:
        cat_map[cat_id] = cat_link.get_text(strip=True)

print("data-categories mapping:", cat_map)
