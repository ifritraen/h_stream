import sys
import io
import re
import json
import time
from concurrent.futures import ThreadPoolExecutor
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaipro.net/',
}

print("=== 1. CHECKING DIRECT TAXONOMY ENDPOINTS ===")
endpoints = [
    'https://hentaipro.net/categories/',
    'https://hentaipro.net/tags/',
    'https://hentaipro.net/genres/',
]
for ep in endpoints:
    res = Fetcher.get(ep, headers=headers)
    print(f"Fetched {ep} -> HTTP {res.status} (final URL: {getattr(res, 'url', 'N/A')})")

print("\n=== 2. FETCHING LIVE SITEMAP TAXONOMY ===")
sitemap_res = Fetcher.get('https://hentaipro.net/sitemap.xml', headers=headers)
sitemap_xml = sitemap_res.body if isinstance(sitemap_res.body, str) else sitemap_res.body.decode('utf-8', errors='ignore')
all_urls = re.findall(r'<loc>(.*?)</loc>', sitemap_xml)
print(f"Total sitemap URLs: {len(all_urls)}")

# Extract categories, studios, and tags
category_slugs = []
studio_slugs = []
tag_slugs = []

for u in all_urls:
    if u.endswith('.html'):
        continue
    path = u.replace('https://sexhentai.net', '').replace('https://hentaipro.net', '')
    parts = [p for p in path.split('/') if p]
    if len(parts) == 1 and parts[0] not in ['series', 'year', 'tag', 'studio']:
        category_slugs.append(parts[0])
    elif len(parts) == 2 and parts[0] == 'studio':
        studio_slugs.append(parts[1])
    elif len(parts) == 2 and parts[0] == 'tag':
        tag_slugs.append(parts[1])

print(f"Discovered: {len(category_slugs)} categories, {len(studio_slugs)} studios, {len(tag_slugs)} tags")

# English display names & metadata mapping
CATEGORY_META = {
    '2d': ('2D Anime', 'Format', 'Icons.movie_filter_rounded', 'Classic Japanese hand-drawn 2D animation'),
    '3d': ('3D Animation', 'Format', 'Icons.view_in_ar_rounded', 'High quality 3D CGI and SFM rendered hentai'),
    'ahegao': ('Ahegao', 'Expression', 'Icons.sentiment_very_satisfied_rounded', 'Exaggerated facial expressions of ecstasy and pleasure'),
    'anal': ('Anal', 'Action', 'Icons.adjust_rounded', 'Anal penetration and back-door stimulation'),
    'bao-cao-su': ('Condom', 'Item', 'Icons.shield_rounded', 'Safe sex and condom fetish scenes'),
    'bao-dam': ('Sadism / Violence', 'Kink', 'Icons.warning_amber_rounded', 'Rough, intense, and aggressive bondage sessions'),
    'big-boobs': ('Big Boobs', 'Body', 'Icons.lens_blur_rounded', 'Buxom heroines with massive and voluminous breasts'),
    'big-girls': ('Big Girls (BBW)', 'Body', 'Icons.face_3_rounded', 'Curvy, chubby, and thick full-figured women'),
    'bondage': ('Bondage & BDSM', 'Kink', 'Icons.link_rounded', 'Rope bondage, shibari, restraints, and submissive play'),
    'bu-liem': ('Oral & Licking', 'Action', 'Icons.sentiment_satisfied_rounded', 'Passionate fellatio, cunnilingus, and body licking'),
    'co-che': ('Censored', 'Format', 'Icons.visibility_off_rounded', 'Standard censored Japanese broadcast releases'),
    'cosplay': ('Cosplay', 'Costume', 'Icons.theater_comedy_rounded', 'Anime, gaming, and maid costume roleplaying'),
    'da-ngam': ('Dark Skin', 'Body', 'Icons.wb_sunny_rounded', 'Tanned and dark-skinned gyaru and island heroines'),
    'de-con': ('Breeding', 'Trope', 'Icons.child_care_rounded', 'Breeding desire and impregnation kink'),
    'do-boi': ('Swimsuit', 'Costume', 'Icons.pool_rounded', 'Bikini, one-piece, and school swimsuit encounters'),
    'double-penetration': ('Double Penetration', 'Action', 'Icons.call_split_rounded', 'Simultaneous double penetration scenes'),
    'du-vu': ('Paizuri / Titfuck', 'Action', 'Icons.front_hand_rounded', 'Breast intercourse and cleavage handiwork'),
    'elf': ('Elf', 'Character', 'Icons.forest_rounded', 'High elves, dark elves, and mystical fantasy races'),
    'fantasy': ('Fantasy', 'Genre', 'Icons.auto_awesome_rounded', 'Magic, swords, sorcery, and otherworldly adventures'),
    'femdom': ('Femdom', 'Dynamics', 'Icons.shield_rounded', 'Dominant mistresses taking complete sexual control'),
    'foot-job': ('Footjob', 'Action', 'Icons.do_not_step_rounded', 'Sensual sole, toe, and foot stimulation'),
    'furry': ('Furry & Kemono', 'Creature', 'Icons.pets_rounded', 'Anthropomorphic animal heroes and lovers'),
    'futanari': ('Futanari', 'Gender', 'Icons.transgender_rounded', 'Hermaphrodite heroines with male genitalia'),
    'gai-quay': ('Gyaru / Delinquent', 'Character', 'Icons.flash_on_rounded', 'Bold, stylish gyaru and delinquent girls'),
    'gang-bang': ('Gangbang', 'Action', 'Icons.groups_rounded', 'Multiple male partners with a single female heroine'),
    'giao-vien': ('Teacher', 'Character', 'Icons.school_rounded', 'Seductive female teachers and after-school private lessons'),
    'goblin': ('Goblin', 'Creature', 'Icons.pest_control_rounded', 'Underground goblins raiding fantasy adventuresses'),
    'guro': ('Guro & Horror', 'Kink', 'Icons.dangerous_rounded', 'Extreme horror and grotesque adult animations'),
    'harem': ('Harem', 'Dynamics', 'Icons.groups_rounded', 'Lucky protagonist surrounded by multiple loving girls'),
    'hiep-dam': ('Non-Con / Forced', 'Trope', 'Icons.lock_rounded', 'Forced encounters and reluctant surrender'),
    'idol': ('Idol', 'Character', 'Icons.mic_rounded', 'Famous pop idols caught in scandals and dressing-room fun'),
    'josei': ('Josei', 'Demographic', 'Icons.person_pin_circle_rounded', 'Mature adult animation aimed at adult female viewers'),
    'kemonomimi': ('Kemonomimi', 'Character', 'Icons.cruelty_free_rounded', 'Catgirls, foxgirls, and animal-eared beauties'),
    'khong-che': ('Uncensored', 'Format', 'Icons.lock_open_rounded', 'Decensored and fully uncensored anime footage'),
    'loan-luan': ('Incest', 'Dynamics', 'Icons.family_restroom_rounded', 'Forbidden stepmother, sister, and aunt relationships'),
    'loli': ('Petite / Loli', 'Body', 'Icons.child_care_rounded', 'Petite and small-statured anime heroines'),
    'maid': ('Maid', 'Character', 'Icons.cleaning_services_rounded', 'Devoted French maids and personal estate servants'),
    'mang-thai': ('Pregnant', 'Body', 'Icons.pregnant_woman_rounded', 'Expectant mothers and pregnant belly passion'),
    'megane': ('Glasses (Megane)', 'Body', 'Icons.visibility_rounded', 'Bookish, shy, and seductive bespectacled girls'),
    'milf': ('MILF', 'Character', 'Icons.woman_rounded', 'Sensual mature mothers, housewives, and older women'),
    'mind-break': ('Mind Break', 'Psychological', 'Icons.cyclone_rounded', 'Heroines losing inhibition and reason from intense pleasure'),
    'monster': ('Monster Girl', 'Creature', 'Icons.bug_report_rounded', 'Slimes, demons, harpies, and mythical beast lovers'),
    'ngu': ('Sleep Sex', 'Trope', 'Icons.bedtime_rounded', 'Somnophilia and nocturnal bedroom surprises'),
    'ntr': ('NTR / Netorare', 'Drama', 'Icons.broken_image_rounded', 'Cuckoldry, stolen lovers, and heartbreak drama'),
    'nu-sinh': ('Schoolgirl', 'Character', 'Icons.backpack_rounded', 'High school uniforms, sailor suits, and classroom romance'),
    'plot': ('Story Rich', 'Quality', 'Icons.auto_stories_rounded', 'Compelling storylines, deep lore, and high production value'),
    'quay-roi': ('Chikan / Molestation', 'Trope', 'Icons.subway_rounded', 'Crowded train and public transit groper scenarios'),
    'scat': ('Scat', 'Extreme', 'Icons.delete_outline_rounded', 'Extreme niche scatological fetish animation'),
    'sex-toy': ('Sex Toys', 'Item', 'Icons.vibration_rounded', 'Vibrators, dildos, remote eggs, and pleasure gadgets'),
    'shota': ('Shota', 'Character', 'Icons.boy_rounded', 'Young male protagonists with mature older women'),
    'softcore': ('Softcore / Ecchi', 'Format', 'Icons.spa_rounded', 'Sensual ecchi and teasing non-penetrative visuals'),
    'stocking': ('Stockings & Pantyhose', 'Costume', 'Icons.checkroom_rounded', 'Black tights, fishnets, thigh-highs, and garterbelts'),
    'sua-me': ('Lactation', 'Body', 'Icons.water_drop_rounded', 'Lactating breasts and nursemaid feeding'),
    'succubus': ('Succubus', 'Character', 'Icons.nightlight_round', 'Demonic dream temptresses draining life energy'),
    'thac-loan': ('Orgy', 'Dynamics', 'Icons.diversity_3_rounded', 'Uninhibited multi-partner party sex and wild gatherings'),
    'thoi-mien': ('Hypnosis', 'Psychological', 'Icons.remove_red_eye_rounded', 'Hypnotic pendulum, trance, and mind manipulation'),
    'threesome': ('Threesome', 'Dynamics', 'Icons.group_work_rounded', 'MFF and FFM three-way sexual encounters'),
    'thu-dam': ('Masturbation', 'Action', 'Icons.touch_app_rounded', 'Solo hand play, mirror masturbation, and secret climax'),
    'thu-thai': ('Impregnation', 'Trope', 'Icons.favorite_rounded', 'Internal ejaculation aimed at conceiving offspring'),
    'thuoc-kich-duc': ('Aphrodisiac', 'Item', 'Icons.medication_rounded', 'Love potions, heat drugs, and aphrodisiac intoxication'),
    'tieu-tien': ('Omorashi', 'Kink', 'Icons.water_rounded', 'Bladder holding, desperation, and urination accidents'),
    'tong-tinh': ('Blackmail', 'Drama', 'Icons.phonelink_lock_rounded', 'Coercion, illicit photos, and extortion compliance'),
    'trap': ('Trap / Otokonoko', 'Gender', 'Icons.wc_rounded', 'Cute crossdressing boys and androgynous cuties'),
    'tsundere': ('Tsundere', 'Personality', 'Icons.mood_bad_rounded', 'Prickly and harsh exteriors hiding burning affection'),
    'ugly-bastard': ('Ugly Bastard', 'Character', 'Icons.face_retouching_off_rounded', 'Unattractive, lecherous men seducing pristine beauties'),
    'vanilla': ('Vanilla Romance', 'Genre', 'Icons.favorite_rounded', 'Pure mutual love, sweet passion, and gentle intimacy'),
    'virgin': ('Virgin / First Time', 'Trope', 'Icons.stars_rounded', 'Defloration, first sexual experiences, and innocence lost'),
    'vu-lep': ('Flat Chest', 'Body', 'Icons.straighten_rounded', 'Slender and flat-chested petite heroines'),
    'wafuku': ('Kimono / Wafuku', 'Costume', 'Icons.dry_cleaning_rounded', 'Traditional Japanese yukata, miko robes, and silk kimonos'),
    'x-ray': ('X-Ray Internal View', 'Visual', 'Icons.biotech_rounded', 'Cross-section internal penetration anatomical animations'),
    'xuc-tu': ('Tentacles', 'Creature', 'Icons.hub_rounded', 'Alien, abyssal, and demonic tentacle invasions'),
    'y-ta': ('Nurse', 'Character', 'Icons.medical_services_rounded', 'Hospital night shift nurses and naughty medical checkups'),
    'yaoi': ('Yaoi / BL', 'Genre', 'Icons.male_rounded', 'Male-on-male romantic and passionate animation'),
    'yuri': ('Yuri / GL', 'Genre', 'Icons.female_rounded', 'Lesbian girls-love, tender romance, and sweet passion'),
}

STUDIO_NAMES = {
    'pink-pineapple': 'Pink Pineapple',
    'poro': 'PoRO',
    'queen-bee': 'Queen Bee',
    'seven': 'Seven',
    'bunny-walker': 'Bunny Walker',
    'milky': 'Milky',
    'maplestar': 'Maplestar',
    't-rex': 'T-Rex',
    'nur': 'Nur',
    'majin': 'Majin',
    'arms': 'Arms',
    'hoods-entertainment': 'Hoods Entertainment',
    'valkyria': 'Valkyria',
    'natural-high': 'Natural High',
    'ziz': 'ZIZ',
    'vicineko': 'Vicineko',
    'jackerman': 'Jackerman',
    'h69-verse': 'H69 Verse',
    'bootleg': 'Bootleg',
    'ms-pictures': 'MS Pictures',
    'chu-chu': 'Chu-Chu',
    'chocolat': 'Chocolat',
    'discovery': 'Discovery',
    'mary-jane': 'Mary Jane',
    'platinum-milky': 'Platinum Milky',
    'umemaro-3d': 'Umemaro 3D',
    'suiseisha': 'Suiseisha',
    'showten': 'Showten',
    'office-takeout': 'Office Takeout',
    'magic-bus': 'Magic Bus',
}

print("\n=== 3. SCRAPING CATEGORY DATA ===")

def scrape_category(slug):
    url = f'https://hentaipro.net/{slug}/'
    try:
        res = Fetcher.get(url, headers=headers)
        if res.status != 200:
            return None
        soup = BeautifulSoup(res.body, 'html.parser')
        
        # Real title from h1
        h1 = soup.select_one('h1.h2-section__title, h1')
        raw_name = h1.get_text(strip=True) if h1 else slug
        
        # Meta info
        meta = CATEGORY_META.get(slug)
        if meta:
            display_name, group, icon, desc = meta
        else:
            display_name = raw_name.replace('Hentai ', '').replace('Phim ', '').strip() or slug.capitalize()
            group = 'Category'
            icon = 'Icons.category_rounded'
            desc = f'High definition {display_name} anime and 3D videos on HentaiPro.'
            
        # First cover image
        card = soup.select_one('article.h2-card, article, .video-card')
        cover = ''
        if card:
            img = card.select_one('img')
            if img:
                cover = img.get('data-src') or img.get('data-lazy-src') or img.get('src') or ''
                if cover.startswith('//'):
                    cover = 'https:' + cover
        
        # Pagination for total count
        pages = []
        for a in soup.find_all('a'):
            href = a.get('href', '')
            if '/page/' in href:
                m = re.search(r'/page/(\d+)/', href)
                if m:
                    pages.append(int(m.group(1)))
        max_page = max(pages) if pages else 1
        cards_count = len(soup.select('article.h2-card, article, .video-card'))
        count = max_page * 30 if max_page > 1 else cards_count
        
        return {
            'slug': slug,
            'name': display_name,
            'vietnameseName': raw_name,
            'categoryGroup': group,
            'icon': icon,
            'description': desc,
            'cover': cover,
            'count': count,
            'endpointPath': f'/{slug}/',
            'type': 'category',
        }
    except Exception as e:
        print(f"Error scraping category {slug}: {e}")
        return None

with ThreadPoolExecutor(max_workers=12) as ex:
    categories_harvested = [c for c in ex.map(scrape_category, category_slugs) if c]

print(f"Successfully harvested {len(categories_harvested)} live categories!")

print("\n=== 4. SCRAPING TOP STUDIOS AND TAGS ===")

def scrape_studio(slug):
    url = f'https://hentaipro.net/studio/{slug}/'
    try:
        res = Fetcher.get(url, headers=headers)
        if res.status != 200:
            return None
        soup = BeautifulSoup(res.body, 'html.parser')
        
        name = STUDIO_NAMES.get(slug, slug.replace('-', ' ').title())
        
        card = soup.select_one('article.h2-card, article, .video-card')
        cover = ''
        if card:
            img = card.select_one('img')
            if img:
                cover = img.get('data-src') or img.get('src') or ''
                if cover.startswith('//'):
                    cover = 'https:' + cover
                    
        pages = []
        for a in soup.find_all('a'):
            href = a.get('href', '')
            if '/page/' in href:
                m = re.search(r'/page/(\d+)/', href)
                if m:
                    pages.append(int(m.group(1)))
        max_page = max(pages) if pages else 1
        cards_count = len(soup.select('article.h2-card, article, .video-card'))
        count = max_page * 30 if max_page > 1 else cards_count
        
        if count == 0:
            return None
            
        return {
            'slug': slug,
            'name': name,
            'categoryGroup': 'Studio',
            'icon': 'Icons.business_rounded',
            'description': f'Official releases from animation studio {name} on HentaiPro.',
            'cover': cover,
            'count': count,
            'endpointPath': f'/studio/{slug}/',
            'type': 'tag',
        }
    except Exception as e:
        print(f"Error studio {slug}: {e}")
        return None

# Top studios from sitemap
top_studios = list(STUDIO_NAMES.keys())
with ThreadPoolExecutor(max_workers=10) as ex:
    studios_harvested = [s for s in ex.map(scrape_studio, top_studios) if s]

print(f"Successfully harvested {len(studios_harvested)} studios!")

# Also add special tags
special_tags = [
    {
        'slug': 'recent-updates',
        'name': 'Recent Updates',
        'categoryGroup': 'Feature',
        'icon': 'Icons.fiber_new_rounded',
        'description': 'Latest episodes and newly published hentai anime releases',
        'cover': categories_harvested[0]['cover'] if categories_harvested else '',
        'count': 3500,
        'endpointPath': '/',
        'type': 'tag',
    },
    {
        'slug': 'most-viewed',
        'name': 'Most Viewed',
        'categoryGroup': 'Ranking',
        'icon': 'Icons.whatshot_rounded',
        'description': 'Highest viewed and most popular anime streams on HentaiPro',
        'cover': categories_harvested[1]['cover'] if len(categories_harvested) > 1 else '',
        'count': 1200,
        'endpointPath': '/?orderby=views',
        'type': 'tag',
    },
    {
        'slug': 'full-hd',
        'name': '1080p Full HD',
        'categoryGroup': 'Quality',
        'icon': 'Icons.high_quality_rounded',
        'description': 'Crystal clear 1080p master high-definition streams',
        'cover': '',
        'count': 2800,
        'endpointPath': '/',
        'type': 'tag',
    },
    {
        'slug': 'subbed',
        'name': 'English Subbed',
        'categoryGroup': 'Audio/Subtitle',
        'icon': 'Icons.subtitles_rounded',
        'description': 'Original Japanese audio with accurate subtitles',
        'cover': '',
        'count': 3200,
        'endpointPath': '/',
        'type': 'tag',
    }
]

all_tags = special_tags + studios_harvested

# Save raw harvest JSON
with open('scratch/hentai_pro_harvest.json', 'w', encoding='utf-8') as f:
    json.dump({
        'categories': categories_harvested,
        'tags': all_tags,
    }, f, indent=2, ensure_ascii=False)

print(f"Saved raw harvest to scratch/hentai_pro_harvest.json")
print(f"Total categories: {len(categories_harvested)}, Total tags/studios: {len(all_tags)}")
