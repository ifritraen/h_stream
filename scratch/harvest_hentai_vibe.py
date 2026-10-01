import json
import re
import urllib.parse
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

DOMAINS = [
    'https://hentaivibe.com',
    'https://hentaivibe.org',
]

PROBE_ENDPOINTS = [
    '/categories',
    '/genres',
    '/playlists',
    '/tags',
    '/tags/',
    '/anal/',
    '/best.html',
    '/lastnews/',
]

def clean_tag_name(raw: str) -> str:
    cleaned = raw.strip()
    # Capitalize appropriately
    words = cleaned.split()
    return ' '.join(w.capitalize() if not w.isupper() else w for w in words)

def run_harvest():
    print("[*] Probing requested endpoints across domains...")
    for domain in DOMAINS:
        for ep in PROBE_ENDPOINTS:
            url = f"{domain}{ep}"
            try:
                resp = Fetcher.get(url, headers=HEADERS, timeout=8)
                body_len = len(resp.body) if hasattr(resp, 'body') else 0
                title = ""
                if body_len > 0:
                    soup = BeautifulSoup(resp.body, 'html.parser')
                    title = soup.title.string.strip() if soup.title and soup.title.string else ""
                print(f"    {url} -> {resp.status} (len: {body_len}) [{title[:40]}]")
            except Exception as e:
                print(f"    {url} -> Error: {e}")

    # Fetch master tags from hentaivibe.org/tags/
    live_domain = "https://hentaivibe.org"
    tags_url = f"{live_domain}/tags/"
    print(f"\n[*] Harvesting live tags from {tags_url}...")
    resp = Fetcher.get(tags_url, headers=HEADERS, timeout=10)
    soup = BeautifulSoup(resp.body, 'html.parser')

    container = soup.find(id='dle-content') or soup
    tag_links = container.find_all('a', href=lambda h: h and '/tags/' in h)
    print(f"[*] Found {len(tag_links)} raw tag elements in DOM")

    harvested_tags = []
    seen_slugs = set()

    for a in tag_links:
        raw_name = a.get_text(strip=True)
        href = a.get('href', '')
        title_attr = a.get('title', '')

        # Slug extraction from href: /tags/slug/ or /tags/slug%20name/
        slug_match = re.search(r'/tags/([^/]+)/?', href)
        if not slug_match:
            continue
        raw_slug = slug_match.group(1)
        slug = urllib.parse.unquote(raw_slug).strip().lower()

        if slug in seen_slugs or slug == 'tags' or not slug:
            continue
        seen_slugs.add(slug)

        # Count extraction from title="Publication found: 137"
        count = 0
        count_match = re.search(r'Publication found:\s*(\d+)', title_attr)
        if count_match:
            count = int(count_match.group(1))
        elif re.search(r'\d+', title_attr):
            count = int(re.search(r'\d+', title_attr).group(0))

        display_name = clean_tag_name(raw_name)
        # Custom display name corrections
        if slug == '3d':
            display_name = '3D / CGI'
        elif slug == 'bbc':
            display_name = 'BBC / Interracial'
        elif slug == 'bdsm':
            display_name = 'BDSM'
        elif slug == 'scifi':
            display_name = 'Sci-Fi'
        elif slug == '69':
            display_name = 'Position 69'
        elif slug == 'ada wong':
            display_name = 'Ada Wong'

        # Endpoint path
        endpoint = f"/tags/{raw_slug}/" if not raw_slug.endswith('/') else f"/tags/{raw_slug}"

        harvested_tags.append({
            'name': display_name,
            'slug': slug,
            'raw_slug': raw_slug,
            'count': count,
            'endpoint': endpoint,
        })

    # Sort tags by count descending
    harvested_tags.sort(key=lambda x: x['count'], reverse=True)
    print(f"[*] Processed {len(harvested_tags)} unique tags with authentic counts.")

    # Harvest thumbnails for top categories and tags
    print("\n[*] Sampling live thumbnails for top categories and tags...")
    thumbnails = {}

    # Sample top 25 tags for thumbnails
    for item in harvested_tags[:25]:
        slug = item['slug']
        raw_slug = item['raw_slug']
        tag_page_url = f"{live_domain}/tags/{raw_slug}/"
        try:
            r = Fetcher.get(tag_page_url, headers=HEADERS, timeout=6)
            s = BeautifulSoup(r.body, 'html.parser')
            img = s.select_one('a.poster img, .poster img, .img-fit-cover img')
            if img:
                src = img.get('src') or img.get('data-src') or ''
                if src.startswith('/'):
                    src = f"{live_domain}{src}"
                thumbnails[slug] = src
                print(f"    Thumb [{slug}]: {src}")
        except Exception as e:
            print(f"    Thumb [{slug}] error: {e}")

    # Also check homepage and anal thumbnails
    for path, key in [('/', 'latest'), ('/best.html', 'popular'), ('/anal/', 'anal')]:
        try:
            r = Fetcher.get(f"{live_domain}{path}", headers=HEADERS, timeout=6)
            s = BeautifulSoup(r.body, 'html.parser')
            img = s.select_one('a.poster img, .poster img')
            if img:
                src = img.get('src') or ''
                if src.startswith('/'):
                    src = f"{live_domain}{src}"
                thumbnails[key] = src
                print(f"    Thumb [{key}]: {src}")
        except Exception as e:
            print(f"    Thumb [{key}] error: {e}")

    # Build Categories structure
    categories = [
        {
            "name": "Vibe Latest",
            "slug": "latest",
            "categoryGroup": "Browse",
            "icon": "Icons.fiber_new_rounded",
            "count": 480,
            "description": "Latest curated ambient anime & 3D video additions",
            "endpointPath": "/lastnews/",
            "thumbnail": thumbnails.get('latest', '')
        },
        {
            "name": "Top Vibe / Popular",
            "slug": "popular",
            "categoryGroup": "Browse",
            "icon": "Icons.whatshot_rounded",
            "count": 217,
            "description": "Most watched and all-time top rated videos on HentaiVibe",
            "endpointPath": "/best.html",
            "thumbnail": thumbnails.get('popular', '')
        },
        {
            "name": "Anal Delights",
            "slug": "anal",
            "categoryGroup": "Featured",
            "icon": "Icons.adjust_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == 'anal'), 213),
            "description": "Passionate anal encounters, backdoor training, and deep climaxes",
            "endpointPath": "/anal/",
            "thumbnail": thumbnails.get('anal', '')
        },
        {
            "name": "3D & Cyber CGI",
            "slug": "3d",
            "categoryGroup": "Visual Formats",
            "icon": "Icons.view_in_ar_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == '3d'), 137),
            "description": "High fidelity 3D SFM, MMD, and Unreal Engine renders",
            "endpointPath": "/tags/3d/",
            "thumbnail": thumbnails.get('3d', '')
        },
        {
            "name": "Uncensored Vibe",
            "slug": "uncensored",
            "categoryGroup": "Censorship",
            "icon": "Icons.lock_open_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == 'uncensored'), 84),
            "description": "Pure decensored cuts and uncensored streaming with no mosaics",
            "endpointPath": "/tags/uncensored/",
            "thumbnail": thumbnails.get('uncensored', '')
        },
        {
            "name": "Creampie internal",
            "slug": "creampie",
            "categoryGroup": "Climax",
            "icon": "Icons.water_drop_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == 'creampie'), 48),
            "description": "Internal fillings, passionate breedings, and warm finishes",
            "endpointPath": "/tags/creampie/",
            "thumbnail": thumbnails.get('creampie', '')
        },
        {
            "name": "Busty & Big Boobs",
            "slug": "big boobs",
            "categoryGroup": "Body Type",
            "icon": "Icons.favorite_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == 'big boobs'), 52),
            "description": "Voluptuous heroines with massive natural busts and deep cleavage",
            "endpointPath": "/tags/big%20boobs/",
            "thumbnail": thumbnails.get('big boobs', '')
        },
        {
            "name": "Schoolgirls & Academy",
            "slug": "schoolgirl",
            "categoryGroup": "Archetypes",
            "icon": "Icons.school_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == 'schoolgirl'), 38),
            "description": "Seifuku uniforms, campus romance, and classroom encounters",
            "endpointPath": "/tags/schoolgirl/",
            "thumbnail": thumbnails.get('schoolgirl', '')
        },
        {
            "name": "Futanari & Dickgirls",
            "slug": "futanari",
            "categoryGroup": "Themes",
            "icon": "Icons.transgender_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == 'futanari'), 34),
            "description": "Well-endowed futa maidens dominating lovers and partners",
            "endpointPath": "/tags/futanari/",
            "thumbnail": thumbnails.get('futanari', '')
        },
        {
            "name": "Blowjob & Oral",
            "slug": "blowjob",
            "categoryGroup": "Acts",
            "icon": "Icons.face_retouching_natural_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == 'blowjob'), 42),
            "description": "Deep throat oral worship, messy facials, and mouth finishes",
            "endpointPath": "/tags/blowjob/",
            "thumbnail": thumbnails.get('blowjob', '')
        },
        {
            "name": "Rough & BDSM",
            "slug": "rough sex",
            "categoryGroup": "Hardcore",
            "icon": "Icons.local_fire_department_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == 'rough sex'), 30),
            "description": "Intense dominating sessions, bondage, spanking, and discipline",
            "endpointPath": "/tags/rough%20sex/",
            "thumbnail": thumbnails.get('rough sex', '')
        },
        {
            "name": "BBC & Interracial",
            "slug": "interracial",
            "categoryGroup": "Themes",
            "icon": "Icons.people_alt_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == 'interracial'), 28),
            "description": "Cross-cultural pairings, giant cocks, and intense contrast",
            "endpointPath": "/tags/interracial/",
            "thumbnail": thumbnails.get('interracial', '')
        },
        {
            "name": "Big Ass & PAWG",
            "slug": "big ass",
            "categoryGroup": "Body Type",
            "icon": "Icons.crop_portrait_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == 'big ass'), 36),
            "description": "Wide hips, round bubble butts, and intense doggy style view",
            "endpointPath": "/tags/big%20ass/",
            "thumbnail": thumbnails.get('big ass', '')
        },
        {
            "name": "Monsters & Fantasy",
            "slug": "monster",
            "categoryGroup": "Fantasy",
            "icon": "Icons.pets_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == 'monster'), 25),
            "description": "Orcs, goblins, beasts, tentacles, and mythical creatures",
            "endpointPath": "/tags/monster/",
            "thumbnail": thumbnails.get('monster', '')
        },
        {
            "name": "Sci-Fi & Cyberpunk",
            "slug": "scifi",
            "categoryGroup": "Settings",
            "icon": "Icons.rocket_launch_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == 'scifi'), 19),
            "description": "Futuristic cyborgs, android girls, spaceships, and lasers",
            "endpointPath": "/tags/scifi/",
            "thumbnail": thumbnails.get('scifi', '')
        },
        {
            "name": "Pure Romance & Vanilla",
            "slug": "romance",
            "categoryGroup": "Mood",
            "icon": "Icons.favorite_border_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == 'romance'), 16),
            "description": "Gentle lovemaking, wholesome intimacy, and affectionate couples",
            "endpointPath": "/tags/romance/",
            "thumbnail": thumbnails.get('romance', '')
        },
        {
            "name": "Harem & Maid Fantasy",
            "slug": "maid",
            "categoryGroup": "Archetypes",
            "icon": "Icons.cleaning_services_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == 'maid'), 14),
            "description": "Devoted maid servants, master submission, and harem suites",
            "endpointPath": "/tags/maid/",
            "thumbnail": thumbnails.get('maid', '')
        },
        {
            "name": "Gaming & Pop Parody",
            "slug": "ada wong",
            "categoryGroup": "Parody",
            "icon": "Icons.sports_esports_rounded",
            "count": next((t['count'] for t in harvested_tags if t['slug'] == 'ada wong'), 12),
            "description": "Video game heroines, resident evil, overwatch, and comic heroines",
            "endpointPath": "/tags/ada%20wong/",
            "thumbnail": thumbnails.get('ada wong', '')
        },
    ]

    result = {
        'total_tags': len(harvested_tags),
        'categories': categories,
        'tags': harvested_tags,
        'thumbnails': thumbnails,
    }

    with open('scratch/hentai_vibe_harvest.json', 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, ensure_ascii=False)

    print(f"\n[OK] Harvest completed successfully. Saved to scratch/hentai_vibe_harvest.json")

if __name__ == '__main__':
    run_harvest()
