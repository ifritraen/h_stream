import sys
import io
import re
from bs4 import BeautifulSoup

for filename, name in [
    ('scratch/page__categories_.html', 'Categories'),
    ('scratch/page__tags_.html', 'Tags'),
    ('scratch/page__genres_.html', 'Genres'),
]:
    with open(filename, 'r', encoding='utf-8') as f:
        html_content = f.read()
    soup = BeautifulSoup(html_content, 'html.parser')
    print(f"=== {name} ({len(html_content)} bytes) ===")
    
    # Check title, h1, h2
    print("Title:", soup.title.get_text(strip=True) if soup.title else "No title")
    print("h1:", [h.get_text(strip=True) for h in soup.find_all('h1')])
    print("h2:", [h.get_text(strip=True) for h in soup.find_all('h2')[:10]])
    
    # Check classes of containers
    divs = soup.find_all('div', class_=True)
    classes = set()
    for d in divs:
        for c in d.get('class', []):
            classes.add(c)
    print("Sample classes:", list(classes)[:20])
    
    # Look for links containing /category/, /tag/, /genre/
    cat_links = soup.select('a[href*="/categor"]')
    tag_links = soup.select('a[href*="/tag"]')
    genre_links = soup.select('a[href*="/genre"]')
    print(f"Links found: category={len(cat_links)}, tag={len(tag_links)}, genre={len(genre_links)}")
    
    # Sample links
    all_links = soup.find_all('a')
    print(f"Total links: {len(all_links)}")
    for a in all_links[:10]:
        print("  a:", a.get('href'), "| text:", a.get_text(strip=True), "| img:", bool(a.find('img')))
