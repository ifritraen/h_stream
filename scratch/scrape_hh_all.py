import json
import re
import sys
from scrapling.fetchers import Fetcher

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaihaven.red/',
}

print("=== 1. HARVESTING GENRES FROM https://hentaihaven.red/genres/ ===")
p_genres = Fetcher.get('https://hentaihaven.red/genres/', headers=headers, timeout=20)
genre_cards = p_genres.css('a.bg-tr')
print(f"Found {len(genre_cards)} genre cards on /genres/")

harvested_genres = []
for card in genre_cards:
    href = card.attrib.get('href', '').strip()
    slug_match = re.search(r'/(?:hentai/tag|genre)/([^/]+)/?', href)
    slug = slug_match.group(1) if slug_match else href.strip('/').split('/')[-1]
    
    h2 = card.css('h2')
    name = h2.first.get_all_text().strip() if h2 else slug.replace('-', ' ').title()
    
    # Description
    desc_el = card.css('div.cat_dsc p, .cat_dsc')
    description = desc_el.first.get_all_text().strip() if desc_el else f"Hentai Haven {name} collection"
    
    # Count
    count_el = card.css('span')
    count = 0
    if count_el:
        c_text = count_el.first.get_all_text().strip()
        try:
            count = int(re.sub(r'[^\d]', '', c_text))
        except:
            count = 0
            
    # Thumbnail
    img = card.css('figure img, img')
    thumb = img.first.attrib.get('src', '') if img else ''
    if not thumb and 'url(' in card.attrib.get('style', ''):
        url_match = re.search(r'url\(([^)]+)\)', card.attrib.get('style', ''))
        if url_match:
            thumb = url_match.group(1).strip('"\'')
            
    harvested_genres.append({
        'name': name,
        'slug': slug,
        'count': count,
        'description': description,
        'thumbnail': thumb,
        'endpointPath': f"/hentai/tag/{slug}/",
    })

print(f"Harvested {len(harvested_genres)} genres.")
for g in harvested_genres[:5]:
    print(f"  Genre: {g['name']} ({g['slug']}) - {g['count']} videos, thumb: {g['thumbnail']}")

print("\n=== 2. HARVESTING STUDIOS FROM WP API fox_brand ===")
harvested_studios = []
for page in range(1, 10):
    try:
        url = f"https://hentaihaven.red/wp-json/wp/v2/fox_brand?per_page=100&page={page}"
        res = Fetcher.get(url, headers=headers, timeout=15)
        if res.status != 200:
            break
        data = json.loads(res.body)
        if not data:
            break
        for item in data:
            count = item.get('count', 0)
            name = item.get('name', '').strip()
            slug = item.get('slug', '').strip()
            link = item.get('link', '').strip()
            path = f"/brand/{slug}/"
            harvested_studios.append({
                'name': name,
                'slug': slug,
                'count': count,
                'description': f"{name} anime studio archive • {count} releases" if count > 0 else f"{name} studio archive",
                'endpointPath': path,
            })
    except Exception as e:
        print(f"Page {page} error: {e}")
        break

# Sort studios by count descending
harvested_studios.sort(key=lambda x: x['count'], reverse=True)
print(f"Harvested {len(harvested_studios)} studios.")
for s in harvested_studios[:10]:
    print(f"  Studio: {s['name']} ({s['slug']}) - {s['count']} releases, path: {s['endpointPath']}")

print("\n=== 3. HARVESTING SERIES / CATEGORIES FROM https://hentaihaven.red/series/ ===")
harvested_series = []
# 3a. First get series with covers from grid view (pages 1-6)
seen_series_slugs = set()
for paged in range(1, 8):
    try:
        url = f"https://hentaihaven.red/series/?view=grid&paged={paged}"
        p = Fetcher.get(url, headers=headers, timeout=15)
        if p.status != 200:
            break
        cards = p.css('div.container .grid > a')
        if not cards:
            break
        for c in cards:
            href = c.attrib.get('href', '').strip()
            slug_match = re.search(r'/serie/([^/]+)/?', href)
            slug = slug_match.group(1) if slug_match else href.strip('/').split('/')[-1]
            if slug in seen_series_slugs:
                continue
            seen_series_slugs.add(slug)
            
            h2 = c.css('h2')
            name = h2.first.get_all_text().strip() if h2 else slug.replace('-', ' ').title()
            
            # Count
            h4 = c.css('h4')
            count = 1
            if h4:
                c_text = h4.first.get_all_text().strip()
                try:
                    count = int(re.sub(r'[^\d]', '', c_text))
                except:
                    count = 1
                    
            # Cover / thumb
            imgs = c.css('figure img, img')
            cover = ''
            for im in imgs:
                src = im.attrib.get('src', '').strip()
                if 'cover_' in src or 'cover' in src:
                    cover = src
                    break
            if not cover and imgs:
                cover = imgs.first.attrib.get('src', '').strip()
                
            harvested_series.append({
                'name': name,
                'slug': slug,
                'count': count,
                'description': f"Official serialized anime • {count} episodes",
                'thumbnail': cover,
                'endpointPath': f"/serie/{slug}/",
            })
    except Exception as e:
        print(f"Series grid paged {paged} error: {e}")
        break

print(f"Harvested {len(harvested_series)} rich series cards with covers.")
for s in harvested_series[:5]:
    print(f"  Series: {s['name']} ({s['slug']}) - {s['count']} eps, cover: {s['thumbnail']}")

# 3b. Also gather the remaining list view series from https://hentaihaven.red/series/
p_series_list = Fetcher.get('https://hentaihaven.red/series/', headers=headers, timeout=20)
list_links = p_series_list.css('ul.colum2 li a')
for a in list_links:
    href = a.attrib.get('href', '').strip()
    if not href or href.startswith('#') or '/serie/' not in href:
        continue
    slug_match = re.search(r'/serie/([^/]+)/?', href)
    slug = slug_match.group(1) if slug_match else href.strip('/').split('/')[-1]
    if slug in seen_series_slugs:
        continue
    seen_series_slugs.add(slug)
    name = a.get_all_text().strip()
    if not name:
        name = slug.replace('-', ' ').title()
    harvested_series.append({
        'name': name,
        'slug': slug,
        'count': 1,
        'description': f"Official serialized anime franchise",
        'thumbnail': '',
        'endpointPath': f"/serie/{slug}/",
    })

print(f"Total series gathered: {len(harvested_series)}")

print("\n=== 4. DEFINING CATEGORIES ===")
# Core Hentai Haven categories
core_categories = [
    {
        'name': "Most Viewed",
        'slug': "popular",
        'count': 5400,
        'description': "All-time most watched classic episodes",
        'thumbnail': "https://hentaihaven.red/wp-content/uploads/2022/08/cov_big-boobs.jpg",
        'endpointPath': "/?m_orderby=views",
    },
    {
        'name': "Latest Releases",
        'slug': "latest",
        'count': 4800,
        'description': "Recently added and newly aired anime episodes",
        'thumbnail': "https://hentaihaven.red/wp-content/uploads/2022/08/cov_ahegao.jpg",
        'endpointPath': "/?m_orderby=latest",
    },
    {
        'name': "Uncensored Archive",
        'slug': "uncensored",
        'count': 6200,
        'description': "Full uncensored and decensored master cuts",
        'thumbnail': "https://hentaihaven.red/wp-content/uploads/2022/08/cov_uncensored.jpg",
        'endpointPath': "/hentai/tag/uncensored/",
    },
    {
        'name': "3D Animation",
        'slug': "3d",
        'count': 2100,
        'description': "3D CGI animated renders and MMD productions",
        'thumbnail': "https://hentaihaven.red/wp-content/uploads/2022/08/cov_3d.jpg",
        'endpointPath': "/hentai/tag/3d/",
    },
    {
        'name': "MILF Classics",
        'slug': "milf",
        'count': 1800,
        'description': "Mature waifus and classic MILF storylines",
        'thumbnail': "https://hentaihaven.red/wp-content/uploads/2022/08/cov_milf.jpg",
        'endpointPath': "/hentai/tag/milf/",
    },
    {
        'name': "Harem Collection",
        'slug': "harem",
        'count': 2400,
        'description': "Multi-partner harem and school romance sagas",
        'thumbnail': "https://hentaihaven.red/wp-content/uploads/2022/08/cov_harem.jpg",
        'endpointPath': "/hentai/tag/harem/",
    },
    {
        'name': "Tentacle World",
        'slug': "tentacles",
        'count': 1100,
        'description': "Classic tentacle monster and eldritch encounters",
        'thumbnail': "https://hentaihaven.red/wp-content/uploads/2022/08/cov_tentacles.jpg",
        'endpointPath': "/hentai/tag/tentacles/",
    },
    {
        'name': "Yuri & Girls Love",
        'slug': "yuri",
        'count': 950,
        'description': "Romantic and passionate female couplings",
        'thumbnail': "https://hentaihaven.red/wp-content/uploads/2022/08/cov_yuri.jpg",
        'endpointPath': "/hentai/tag/yuri/",
    },
    {
        'name': "Dark Fantasy",
        'slug': "dark-fantasy",
        'count': 1400,
        'description': "Grimdark sword & sorcery fantasy adventures",
        'thumbnail': "https://hentaihaven.red/wp-content/uploads/2022/08/cov_dark-skin.jpg",
        'endpointPath': "/hentai/tag/dark-fantasy/",
    },
    {
        'name': "School Girls",
        'slug': "school-girls",
        'count': 3200,
        'description': "Academy life, uniforms, and campus romances",
        'thumbnail': "https://hentaihaven.red/wp-content/uploads/2022/08/cov_school-girls.jpg",
        'endpointPath': "/hentai/tag/school-girls/",
    },
    {
        'name': "Vanilla Romance",
        'slug': "vanilla",
        'count': 2100,
        'description': "Pure, consensual, and heartwarming romance stories",
        'thumbnail': "https://hentaihaven.red/wp-content/uploads/2022/08/cov_vanilla.jpg",
        'endpointPath': "/hentai/tag/vanilla/",
    },
    {
        'name': "Netorare (NTR)",
        'slug': "netorare",
        'count': 1650,
        'description': "High-stakes infidelity, cuckoldry, and drama",
        'thumbnail': "https://hentaihaven.red/wp-content/uploads/2022/08/cov_netorare.jpg",
        'endpointPath': "/hentai/tag/netorare/",
    },
]

# Merge core categories with top rich series
harvested_categories = list(core_categories)
for s in harvested_series[:48]:  # add top 48 rich series as serialized categories
    harvested_categories.append({
        'name': s['name'],
        'slug': s['slug'],
        'count': s['count'],
        'description': s['description'],
        'thumbnail': s.get('thumbnail', ''),
        'endpointPath': s['endpointPath'],
        'categoryGroup': 'Serialized Franchises',
    })

print(f"Total categories assembled: {len(harvested_categories)}")

result = {
    'genres': harvested_genres,
    'studios': harvested_studios,
    'categories': harvested_categories,
    'series': harvested_series,
}

with open('scratch/hentai_haven_harvest.json', 'w', encoding='utf-8') as f:
    json.dump(result, f, indent=2, ensure_ascii=False)

print("\nSuccessfully saved to scratch/hentai_haven_harvest.json!")
