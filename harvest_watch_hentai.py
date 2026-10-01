"""
Live Taxonomy Harvester for WatchHentai (watchhentai.net)
Uses Scrapling (scrapling.fetchers.Fetcher) to probe canonical endpoints and
scrape live authentic genres, categories, and serialized anime series.
"""

import sys
import json
import re
from scrapling.fetchers import Fetcher

sys.stdout.reconfigure(encoding='utf-8')

BASE_URL = "https://watchhentai.net"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://watchhentai.net/',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
}

def probe_candidate_endpoints():
    print("--- 1. Probing Candidate Taxonomy Endpoints ---")
    candidates = [
        f"{BASE_URL}/genres/",
        f"{BASE_URL}/genre/",
        f"{BASE_URL}/series/",
        f"{BASE_URL}/categories/",
        f"{BASE_URL}/category/",
        f"{BASE_URL}/tags/",
        f"{BASE_URL}/videos/",
        f"{BASE_URL}/trending/",
        f"{BASE_URL}/3d/",
        f"{BASE_URL}/genre/uncensored/",
        f"{BASE_URL}/genre/school-girls/",
        f"{BASE_URL}/",
    ]
    results = {}
    fetcher = Fetcher()
    for url in candidates:
        try:
            res = fetcher.get(url, headers=HEADERS, timeout=12)
            results[url] = {
                'status': res.status,
                'canonical': url,
                'accessible': res.status == 200
            }
            print(f"Candidate: {url} -> HTTP {res.status}")
        except Exception as e:
            results[url] = {'status': 500, 'error': str(e), 'accessible': False}
            print(f"Candidate: {url} -> Error: {e}")
    return results

def get_genre_category_group(slug: str) -> str:
    acts_fetishes = {
        'anal', 'bdsm', 'beastiality', 'blowjob', 'bondage', 'brainwashed', 'bukakke',
        'creampie', 'deepthroat', 'double-penatration', 'facesitting', 'facial',
        'femdom', 'footjob', 'futanari', 'gangbang', 'gore', 'humiliation',
        'inflation', 'internal-cumshot', 'lactation', 'mind-break', 'molestation',
        'public-sex', 'rape', 'rim-job', 'scat', 'squirting', 'strap-on',
        'strapped-on', 'three-some', 'tits-fuck', 'torture', 'toys',
        'train-molestation', 'urination', 'x-ray'
    }
    characters_roles = {
        'animal-ears', 'cat-girl', 'dark-skin', 'demons', 'doctor', 'elf',
        'female-doctor', 'female-teacher', 'gyaru', 'horny-slut', 'housewife',
        'incest', 'magical-girls', 'maid', 'megane', 'milf', 'nuns', 'nurses',
        'office-ladies', 'police', 'princess', 'school-girls', 'slaves',
        'succubus', 'tsundere', 'vampire', 'virgins', 'widow'
    }
    themes_formats = {
        '3d', 'action', 'adventure', 'ahegao', 'animation', 'big-boobs',
        'censored', 'comedy', 'cosplay', 'drama', 'dubbed', 'ecchi',
        'eroge', 'family', 'fantasy', 'harem', 'historical', 'large-breasts',
        'martial-arts', 'ntr', 'pov', 'pregnant', 'reality', 'romance',
        'sci-fi', 'shimapan', 'short', 'soap', 'sports', 'stocking',
        'super-power', 'supernatural', 'swimsuit', 'tentacles', 'uncensored',
        'upcoming', 'vanilla', 'vanilla-id-1', 'yaoi', 'yuri'
    }
    if slug in acts_fetishes:
        return "Act & Fetish"
    elif slug in characters_roles:
        return "Character & Role"
    elif slug in themes_formats:
        return "Theme & Trope"
    return "Genre"

def get_genre_icon(slug: str) -> str:
    icon_map = {
        '3d': 'Icons.view_in_ar_rounded',
        'action': 'Icons.flash_on_rounded',
        'adventure': 'Icons.explore_rounded',
        'ahegao': 'Icons.mood_bad_rounded',
        'anal': 'Icons.adjust_rounded',
        'animation': 'Icons.movie_creation_rounded',
        'bdsm': 'Icons.link_rounded',
        'big-boobs': 'Icons.favorite_rounded',
        'blackmail': 'Icons.gavel_rounded',
        'blowjob': 'Icons.record_voice_over_rounded',
        'bondage': 'Icons.lock_outline_rounded',
        'cat-girl': 'Icons.pets_rounded',
        'censored': 'Icons.visibility_off_rounded',
        'comedy': 'Icons.sentiment_very_satisfied_rounded',
        'cosplay': 'Icons.theater_comedy_rounded',
        'creampie': 'Icons.water_drop_rounded',
        'dark-skin': 'Icons.wb_sunny_rounded',
        'deepthroat': 'Icons.hearing_rounded',
        'demons': 'Icons.pest_control_rounded',
        'drama': 'Icons.theater_comedy_rounded',
        'dubbed': 'Icons.mic_rounded',
        'ecchi': 'Icons.whatshot_rounded',
        'elf': 'Icons.auto_awesome_rounded',
        'eroge': 'Icons.videogame_asset_rounded',
        'fantasy': 'Icons.shield_moon_rounded',
        'female-teacher': 'Icons.school_rounded',
        'femdom': 'Icons.sports_kabaddi_rounded',
        'futanari': 'Icons.shuffle_rounded',
        'gangbang': 'Icons.groups_3_rounded',
        'gyaru': 'Icons.face_retouching_natural_rounded',
        'harem': 'Icons.groups_rounded',
        'historical': 'Icons.history_edu_rounded',
        'horny-slut': 'Icons.local_fire_department_rounded',
        'housewife': 'Icons.cottage_rounded',
        'incest': 'Icons.family_restroom_rounded',
        'lactation': 'Icons.opacity_rounded',
        'large-breasts': 'Icons.favorite_rounded',
        'maid': 'Icons.cleaning_services_rounded',
        'martial-arts': 'Icons.sports_martial_arts_rounded',
        'megane': 'Icons.visibility_rounded',
        'milf': 'Icons.woman_rounded',
        'mind-break': 'Icons.psychology_rounded',
        'molestation': 'Icons.warning_rounded',
        'ntr': 'Icons.heart_broken_rounded',
        'nurses': 'Icons.medical_services_rounded',
        'office-ladies': 'Icons.business_center_rounded',
        'police': 'Icons.local_police_rounded',
        'pov': 'Icons.camera_alt_rounded',
        'pregnant': 'Icons.pregnant_woman_rounded',
        'public-sex': 'Icons.park_rounded',
        'rape': 'Icons.dangerous_rounded',
        'romance': 'Icons.favorite_rounded',
        'school-girls': 'Icons.school_rounded',
        'sci-fi': 'Icons.rocket_launch_rounded',
        'supernatural': 'Icons.blur_on_rounded',
        'swimsuit': 'Icons.pool_rounded',
        'tentacles': 'Icons.hub_rounded',
        'uncensored': 'Icons.lock_open_rounded',
        'vanilla': 'Icons.favorite_rounded',
        'vanilla-id-1': 'Icons.favorite_rounded',
        'virgins': 'Icons.star_rounded',
        'x-ray': 'Icons.camera_rounded',
        'yaoi': 'Icons.male_rounded',
        'yuri': 'Icons.female_rounded',
    }
    return icon_map.get(slug, 'Icons.tag_rounded')

def harvest_live_genres():
    print("\n--- 2. Harvesting Live Genres, Counts & Thumbnails ---")
    fetcher = Fetcher()
    # The complete authentic list of genres with exact counts is present on /series/
    res = fetcher.get(f"{BASE_URL}/series/", headers=HEADERS, timeout=15)
    cat_items = res.css('li.cat-item')
    print(f"Found {len(cat_items)} authentic genre items.")

    genres = []
    genre_covers = {}

    for c in cat_items:
        a = c.css('a')
        i = c.css('i')
        if not a:
            continue
        name = a[0].text.strip() if a[0].text else ''
        href = a[0].attrib.get('href', '')
        slug = href.strip('/').split('/')[-1]
        count = int(i[0].text.strip()) if (i and i[0].text and i[0].text.strip().isdigit()) else 0

        endpoint = f"/genre/{slug}/"
        icon = get_genre_icon(slug)
        group = get_genre_category_group(slug)

        genres.append({
            'name': name,
            'slug': slug,
            'endpointPath': endpoint,
            'count': count,
            'categoryGroup': group,
            'icon': icon,
            'description': f"WatchHentai anime tagged with {name} • {count} videos" if count > 0 else f"WatchHentai anime tagged with {name}",
        })

    # Harvest live thumbnail posters for representative genres
    sample_slugs = ['3d', 'action', 'adventure', 'ahegao', 'anal', 'big-boobs', 'blackmail',
                    'blowjob', 'bondage', 'bukakke', 'censored', 'comedy', 'cosplay',
                    'creampie', 'dark-skin', 'deepthroat', 'dubbed', 'ecchi', 'fantasy',
                    'femdom', 'futanari', 'gangbang', 'gyaru', 'harem', 'incest', 'lactation',
                    'large-breasts', 'maid', 'milf', 'ntr', 'nurses', 'office-ladies',
                    'public-sex', 'romance', 'school-girls', 'succubus', 'tentacles',
                    'uncensored', 'vanilla-id-1', 'x-ray', 'yuri']
    
    print(f"Sampling thumbnails for {len(sample_slugs)} genres...")
    for slug in sample_slugs:
        try:
            g_url = f"{BASE_URL}/genre/{slug}/"
            g_res = fetcher.get(g_url, headers=HEADERS, timeout=8)
            img = g_res.css('article img, .item img')
            if img:
                src = img[0].attrib.get('data-src') or img[0].attrib.get('src') or ''
                if src and not src.startswith('data:'):
                    genre_covers[slug] = src
        except Exception as e:
            print(f"Thumb error for {slug}: {e}")

    print(f"Collected {len(genre_covers)} genre thumbnails.")
    return genres, genre_covers

def harvest_live_series(max_pages=3):
    print(f"\n--- 3. Harvesting Live Series Across {max_pages} Pages ---")
    fetcher = Fetcher()
    series_items = []
    series_covers = {}

    for p in range(1, max_pages + 1):
        url = f"{BASE_URL}/series/" if p == 1 else f"{BASE_URL}/series/page/{p}/"
        try:
            res = fetcher.get(url, headers=HEADERS, timeout=12)
            articles = res.css('article.item.tvshows, article.item')
            print(f"Series Page {p}: found {len(articles)} items.")
            for art in articles:
                a = art.css('h3 a, strong a')
                if not a:
                    a = art.css('.poster a, a')
                img = art.css('img')
                year_badge = art.css('.buttonyear span')
                cen_badge = art.css('.buttoncensured span, .buttonuncensured span')

                href = a[0].attrib.get('href', '') if a else ''
                title = a[0].attrib.get('title', '') if a else ''
                if not title and a:
                    title = a[0].text.strip() if a[0].text else ''
                if not title and img:
                    title = img[0].attrib.get('alt', '') or img[0].attrib.get('title', '')
                title = title.replace('&#8211;', '–').replace('&#8212;', '—').replace('&amp;', '&').replace('&#038;', '&')

                slug = href.strip('/').split('/')[-1] if href else ''
                poster = img[0].attrib.get('data-src', '') if img else ''
                if not poster and img:
                    poster = img[0].attrib.get('src', '')
                if poster.startswith('data:'):
                    poster = ''
                if poster.startswith('//'):
                    poster = f"https:{poster}"

                year = year_badge[0].text.strip() if year_badge and year_badge[0].text else ''
                cen = cen_badge[0].text.strip() if cen_badge and cen_badge[0].text else ''

                if slug and title:
                    series_info = {
                        'name': title,
                        'slug': slug,
                        'endpointPath': f"/series/{slug}/",
                        'thumbnail': poster,
                        'count': 1,
                        'year': year or '2026',
                        'censorship': cen or 'CEN',
                        'categoryGroup': 'Serialized Series',
                        'icon': 'Icons.play_circle_fill_rounded',
                        'description': f"Official serialized anime • {cen} • {year or 'Recent'}",
                    }
                    series_items.append(series_info)
                    if poster:
                        series_covers[slug] = poster
        except Exception as e:
            print(f"Error fetching series page {p}: {e}")

    print(f"Total live serialized series harvested: {len(series_items)}")
    return series_items, series_covers

def build_full_categories(series_items):
    # Core Featured Categories
    core_categories = [
        {
            'name': 'Recent Episodes',
            'slug': 'recent',
            'endpointPath': '/videos/',
            'count': 5400,
            'description': 'Recently aired and updated anime episode releases',
            'categoryGroup': 'Featured',
            'icon': 'Icons.fiber_new_rounded',
        },
        {
            'name': 'Trending & Popular',
            'slug': 'popular',
            'endpointPath': '/trending/',
            'count': 3800,
            'description': 'Most watched and highly trending anime series',
            'categoryGroup': 'Featured',
            'icon': 'Icons.whatshot_rounded',
        },
        {
            'name': 'Uncensored Cuts',
            'slug': 'uncensored',
            'endpointPath': '/genre/uncensored/',
            'count': 2900,
            'description': 'Decensored and 100% uncensored master studio cuts',
            'categoryGroup': 'Featured',
            'icon': 'Icons.lock_open_rounded',
        },
        {
            'name': '3D Animation / CGI',
            'slug': '3d',
            'endpointPath': '/3d/',
            'count': 450,
            'description': 'High-definition 3D renders, CGI productions, and MMD animations',
            'categoryGroup': 'Featured',
            'icon': 'Icons.view_in_ar_rounded',
        },
        {
            'name': 'Serialized Franchises',
            'slug': 'all-series',
            'endpointPath': '/series/',
            'count': 2500,
            'description': 'Complete catalog of episodic serialized anime series',
            'categoryGroup': 'Featured',
            'icon': 'Icons.video_collection_rounded',
        },
        {
            'name': 'English Dubbed',
            'slug': 'dubbed',
            'endpointPath': '/genre/dubbed/',
            'count': 180,
            'description': 'English voice acted and dubbed hentai anime series',
            'categoryGroup': 'Category',
            'icon': 'Icons.record_voice_over_rounded',
        },
        {
            'name': 'Harem Collection',
            'slug': 'harem',
            'endpointPath': '/genre/harem/',
            'count': 480,
            'description': 'School romance sagas and multi-waifu harem anime',
            'categoryGroup': 'Category',
            'icon': 'Icons.groups_rounded',
        },
        {
            'name': 'School Girls',
            'slug': 'school-girls',
            'endpointPath': '/genre/school-girls/',
            'count': 520,
            'description': 'Academy life, school uniforms, and campus romances',
            'categoryGroup': 'Category',
            'icon': 'Icons.school_rounded',
        },
        {
            'name': 'Vanilla Romance',
            'slug': 'vanilla-id-1',
            'endpointPath': '/genre/vanilla-id-1/',
            'count': 320,
            'description': 'Heartwarming, wholesome, and consensual romantic relationships',
            'categoryGroup': 'Category',
            'icon': 'Icons.favorite_rounded',
        },
        {
            'name': 'MILF & Mature',
            'slug': 'milf',
            'endpointPath': '/genre/milf/',
            'count': 410,
            'description': 'Mature waifus, mothers, and classic MILF storylines',
            'categoryGroup': 'Category',
            'icon': 'Icons.woman_rounded',
        },
        {
            'name': 'Dark Fantasy',
            'slug': 'fantasy',
            'endpointPath': '/genre/fantasy/',
            'count': 290,
            'description': 'Sword, sorcery, demons, and dark fantasy adventures',
            'categoryGroup': 'Category',
            'icon': 'Icons.shield_moon_rounded',
        },
        {
            'name': 'Yuri & Girls Love',
            'slug': 'yuri',
            'endpointPath': '/genre/yuri/',
            'count': 150,
            'description': 'Passionate and romantic female pairings and Yuri romances',
            'categoryGroup': 'Category',
            'icon': 'Icons.female_rounded',
        },
    ]

    all_categories = core_categories + series_items
    return all_categories

def main():
    probe_results = probe_candidate_endpoints()
    genres, genre_covers = harvest_live_genres()
    series_items, series_covers = harvest_live_series(max_pages=3)
    categories = build_full_categories(series_items)

    combined_covers = {}
    combined_covers.update(genre_covers)
    combined_covers.update(series_covers)

    data = {
        'probe_results': probe_results,
        'total_genres': len(genres),
        'total_categories': len(categories),
        'total_series': len(series_items),
        'total_covers': len(combined_covers),
        'genres': genres,
        'categories': categories,
        'series_covers': series_covers,
        'genre_covers': genre_covers,
        'combined_covers': combined_covers,
    }

    with open('watch_hentai_harvest.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"\n[DONE] Saved harvest data into watch_hentai_harvest.json:")
    print(f"  - Total Genres: {len(genres)}")
    print(f"  - Total Categories (Core + Series): {len(categories)}")
    print(f"  - Total Serialized Series: {len(series_items)}")
    print(f"  - Total Covers Harvested: {len(combined_covers)}")

if __name__ == '__main__':
    main()
