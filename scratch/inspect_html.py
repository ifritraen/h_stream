from bs4 import BeautifulSoup
import re

with open('scratch/categories.html', 'r', encoding='utf-8') as f:
    cat_soup = BeautifulSoup(f.read(), 'html.parser')

print("--- CATEGORIES INSPECTION ---")
# Look for main content container
main = cat_soup.find('main') or cat_soup.find('div', class_='container') or cat_soup.find('body')
links = cat_soup.find_all('a', href=re.compile(r'/category/'))
print(f"Found {len(links)} links with /category/")

for i, a in enumerate(links[:15]):
    parent = a.parent
    img = a.find('img')
    img_src = img.get('src') or img.get('data-src') if img else None
    print(f"Link {i}: text='{a.get_text(strip=True)}', href='{a.get('href')}', img='{img_src}'")
    # print parent snippet
    # print(f"   Parent tag: {parent.name}, class: {parent.get('class')}")

print("\n--- TAGS INSPECTION ---")
with open('scratch/tags.html', 'r', encoding='utf-8') as f:
    tag_soup = BeautifulSoup(f.read(), 'html.parser')

tag_links = tag_soup.find_all('a', href=re.compile(r'/tag/'))
print(f"Found {len(tag_links)} links with /tag/")

for i, a in enumerate(tag_links[:15]):
    print(f"Tag {i}: text='{a.get_text(strip=True)}', href='{a.get('href')}'")
