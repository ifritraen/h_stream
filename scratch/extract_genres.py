from scrapling.parser import Adaptor
from bs4 import BeautifulSoup
import re
import json

with open('scratch/genres.html', 'r', encoding='utf-8', errors='ignore') as f:
    html = f.read()

soup = BeautifulSoup(html, 'html.parser')

genres = []
seen = set()

# Look for genre cards
for a in soup.find_all('a', href=re.compile(r'/archive\?genre=')):
    href = a.get('href', '')
    m = re.search(r'genre=([a-zA-Z0-9_\-]+)', href)
    if not m:
        continue
    slug = m.group(1)
    if slug in seen:
        continue
    seen.add(slug)
    
    # Let's find container
    container = a.find_parent('div', class_=re.compile(r'col|card|rounded'))
    name = ""
    desc = ""
    if container:
        # Title usually in h2, h3, h4, or strong
        title_el = container.find(['h2', 'h3', 'h4', 'h5', 'strong'])
        if title_el:
            name = title_el.get_text().strip()
        desc_el = container.find('p')
        if desc_el:
            desc = desc_el.get_text().strip()
    if not name:
        name = slug.replace('-', ' ').title()
        
    genres.append({
        'slug': slug,
        'name': name,
        'description': desc,
        'endpointPath': f'/archive?genre={slug}',
    })

print(f"Extracted {len(genres)} genres:")
for g in genres[:10]:
    print(g)

with open('scratch/extracted_genres.json', 'w', encoding='utf-8') as f:
    json.dump(genres, f, indent=2, ensure_ascii=False)
