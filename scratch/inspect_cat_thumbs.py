from bs4 import BeautifulSoup

with open('scratch/categories.html', 'r', encoding='utf-8') as f:
    soup = BeautifulSoup(f.read(), 'html.parser')

cat_elements = soup.select('.gallery_cat, .cat_text a')
print("Total category elements on categories.html:", len(cat_elements))
for c in cat_elements:
    print(c.get_text(strip=True), c.get('href') if c.name == 'a' else c.parent.get('href'))

# Let's also check if there is an image associated with each category
for thumb in soup.select('.thumb'):
    cat_link = thumb.select_one('.cat_text a')
    img = thumb.select_one('.inner_thumb img')
    if cat_link and img:
        print(f"Cat: {cat_link.get_text(strip=True)} ({cat_link.get('href')}) -> Img: {img.get('data-src') or img.get('src')}")
