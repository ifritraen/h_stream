from bs4 import BeautifulSoup
import urllib.parse
import re

with open('scratch/cat_page_full.html', 'r', encoding='utf-8') as f:
    html = f.read()

soup = BeautifulSoup(html, 'html.parser')
links = soup.select('a[href*="/video/"]')
print(f"Total /video/ links: {len(links)}")

seen = set()
for a in links:
    href = a.get('href', '')
    if not href or href in seen:
        continue
    seen.add(href)
    
    # Extract image
    img = a.select_one('img')
    cover = ''
    if img:
        srcset = img.get('srcset', '')
        src = img.get('src', '')
        # Check if next/image encoded
        match = re.search(r'url=([^&]+)', src or srcset)
        if match:
            cover = urllib.parse.unquote(match.group(1))
        elif src:
            cover = src
            
    # Extract title and duration
    text = a.get_text('\n').strip().split('\n')
    text = [t.strip() for t in text if t.strip()]
    title = ''
    duration = '24:00'
    for line in text:
        if re.match(r'^\d+:\d+$', line):
            duration = line
        elif len(line) > 3 and not any(line.startswith(x) for x in ['FHD', 'HD', '100%', '99%', '98%']):
            title = line
    if not title and img and img.get('alt'):
        alt = img.get('alt')
        title = re.sub(r'\s+thumbnail$', '', alt, flags=re.IGNORECASE)
    
    print(f"Parsed Video -> title: '{title}', duration: '{duration}', href: '{href}', cover: '{cover}'")
