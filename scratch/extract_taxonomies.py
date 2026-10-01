from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.onlyhentaistuff.com/',
}

# 1. Categories
res_cat = Fetcher.get('https://www.onlyhentaistuff.com/categories/', headers=headers)
soup_cat = BeautifulSoup(res_cat.body, 'html.parser')
categories = []
for item in soup_cat.select('a.item'):
    href = item.get('href', '')
    m = re.search(r'/categories/([^/]+)/?', href)
    if not m:
        continue
    slug = m.group(1)
    title_el = item.select_one('.title')
    title = title_el.get_text(strip=True) if title_el else item.get('title', slug)
    img = item.select_one('img')
    img_url = img.get('src') or img.get('data-original') or img.get('data-src') if img else ''
    if img_url.startswith('//'):
        img_url = 'https:' + img_url
    elif img_url.startswith('/'):
        img_url = 'https://www.onlyhentaistuff.com' + img_url

    count_el = item.select_one('.videos')
    count = 0
    if count_el:
        cm = re.search(r'([\d,]+)', count_el.get_text())
        if cm:
            count = int(cm.group(1).replace(',', ''))

    rating_el = item.select_one('.rating')
    rating = rating_el.get_text(strip=True) if rating_el else ''

    categories.append({
        'name': title,
        'slug': slug,
        'count': count,
        'cover': img_url,
        'rating': rating,
        'endpointPath': f'/categories/{slug}/',
    })

print(f'Total categories scraped: {len(categories)}')
for c in categories[:5]:
    print(c)

# 2. Tags
res_tags = Fetcher.get('https://www.onlyhentaistuff.com/tags/', headers=headers)
soup_tags = BeautifulSoup(res_tags.body, 'html.parser')
tags = []
seen_tag_slugs = set()
for a in soup_tags.select('a[href*="/tags/"]'):
    href = a.get('href', '')
    m = re.search(r'/tags/([^/]+)/?', href)
    if not m:
        continue
    slug = m.group(1)
    if slug in ('tags', 'all') or slug in seen_tag_slugs:
        continue
    seen_tag_slugs.add(slug)
    name = a.get_text(strip=True)
    if not name:
        continue

    # Check if parent or sibling has count
    parent = a.parent
    count = 0
    # check text around
    text = parent.get_text(strip=True)
    cm = re.search(r'\((\d+)\)', text)
    if cm:
        count = int(cm.group(1))

    tags.append({
        'name': name,
        'slug': slug,
        'count': count,
        'endpointPath': f'/tags/{slug}/',
    })

print(f'\nTotal tags scraped: {len(tags)}')
for t in tags[:10]:
    print(t)
