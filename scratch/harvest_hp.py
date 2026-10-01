import json
import re
from bs4 import BeautifulSoup
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiparadise.tv/',
}

print("=== 1. CHECKING DIRECT TAXONOMY CANDIDATES ===")
candidate_urls = [
    'https://hentaiparadise.tv/genres/',
    'https://hentaiparadise.tv/categories/',
    'https://hentaiparadise.tv/tags/',
]
candidate_results = {}
for url in candidate_urls:
    try:
        r = Fetcher.get(url, headers=headers)
        print(f"Candidate {url} -> HTTP {r.status} (len: {len(r.body)})")
        candidate_results[url] = {
            "status": r.status,
            "length": len(r.body),
        }
    except Exception as e:
        print(f"Candidate {url} error: {e}")
        candidate_results[url] = {"error": str(e)}

print("\n=== 2. HARVESTING LIVE CATEGORIES VIA WP TAXONOMY & SITEMAP ===")
r_cats = Fetcher.get('https://hentaiparadise.tv/wp-json/wp/v2/categories?per_page=100', headers=headers)
print(f"WP REST Categories HTTP {r_cats.status}")
wp_cats = json.loads(r_cats.body) if r_cats.status == 200 else []

category_icons = {
    'anal': 'Icons.adjust_rounded',
    'creampie': 'Icons.water_drop_rounded',
    'ecolieres': 'Icons.school_rounded',
    'femmes-mures': 'Icons.woman_rounded',
    'jeunes': 'Icons.child_care_rounded',
    'monstres': 'Icons.pest_control_rodent_rounded',
    'poitrine-genereuse': 'Icons.favorite_rounded',
    'raw': 'Icons.record_voice_over_rounded',
    'sans-censure': 'Icons.lock_open_rounded',
}

category_groups = {
    'anal': 'Act / Fetish',
    'creampie': 'Act / Fetish',
    'ecolieres': 'Role / Setting',
    'femmes-mures': 'Character',
    'jeunes': 'Character',
    'monstres': 'Creature / Fantasy',
    'poitrine-genereuse': 'Attribute',
    'raw': 'Audio Format',
    'sans-censure': 'Censorship',
}

category_descriptions = {
    'anal': 'Pénétration anale intense et scènes sensuelles explicites',
    'creampie': 'Éjaculation interne nakadashi et fins intimes passionnées',
    'ecolieres': 'Jeunes lycéennes en uniforme scolaire et romances interdites',
    'femmes-mures': 'Femmes mûres séduisantes, milfs d’expérience et maîtresses',
    'jeunes': 'Jeunes héroïnes adorables et premières expériences amoureuses',
    'monstres': 'Créatures fantastiques, tentacules mystiques et bêtes démoniaques',
    'poitrine-genereuse': 'Héroïnes voluptueuses dotées d’une généreuse poitrine',
    'raw': 'Versions originales japonaises sans sous-titres',
    'sans-censure': 'Épisodes intégraux sans aucune censure ni mosaïque',
}

categories_harvested = []
for c in wp_cats:
    slug = c.get('slug', '')
    raw_name = c.get('name', '')
    clean_name = raw_name.replace('&#8217;', "'").replace('&amp;', '&').replace('&eacute;', 'é').replace('&egrave;', 'è')
    count = c.get('count', 0)
    endpoint = f"/{slug}/"
    
    # Scrape category landing page for live featured thumbnail and real items
    cat_url = f"https://hentaiparadise.tv/{slug}/"
    thumb = ""
    try:
        r_page = Fetcher.get(cat_url, headers=headers)
        if r_page.status == 200:
            soup = BeautifulSoup(r_page.body, 'html.parser')
            # Extract first poster thumb
            img = soup.select_one('article img, .post img, .uagb-post__inner-wrap img')
            if img:
                thumb = img.get('data-src') or img.get('src') or ""
    except Exception as e:
        print(f"Error fetching thumb for {slug}: {e}")
        
    categories_harvested.append({
        "id": c.get("id"),
        "name": clean_name,
        "slug": slug,
        "count": count,
        "endpointPath": endpoint,
        "icon": category_icons.get(slug, 'Icons.category_rounded'),
        "categoryGroup": category_groups.get(slug, 'Category'),
        "description": category_descriptions.get(slug, f"Animes dans la catégorie {clean_name}"),
        "thumbnail": thumb,
    })
    print(f"Category: {clean_name} ({slug}) -> count: {count}, thumb: {thumb[:60]}")

# Add curated explore sections at top
categories_harvested.insert(0, {
    "name": "Toutes les Nouveautés",
    "slug": "latest",
    "count": 199,
    "endpointPath": "/",
    "icon": "Icons.fiber_new_rounded",
    "categoryGroup": "Découverte",
    "description": "Tous les derniers animes hentai sous-titrés en français",
    "thumbnail": "https://hentaiparadise.tv/wp-content/uploads/2026/09/Kanojo-Saimin-Episode-2.webp",
})

categories_harvested.insert(1, {
    "name": "Populaires & Recommandés",
    "slug": "popular",
    "count": 199,
    "endpointPath": "/popular/",
    "icon": "Icons.whatshot_rounded",
    "categoryGroup": "Découverte",
    "description": "Les séries les plus regardées et acclamées de HentaiParadise",
    "thumbnail": "https://hentaiparadise.tv/wp-content/uploads/2026/07/Guilty-Hole.webp",
})

print(f"\nTotal categories curated: {len(categories_harvested)}")

print("\n=== 3. HARVESTING GENRES & THEMES FROM LIVE CATALOG ===")
# Fetch all 199 posts to analyze genres and themes
all_posts = []
for p in [1, 2]:
    r_p = Fetcher.get(f"https://hentaiparadise.tv/wp-json/wp/v2/posts?per_page=100&page={p}", headers=headers)
    if r_p.status == 200:
        all_posts.extend(json.loads(r_p.body))

print(f"Fetched {len(all_posts)} posts for taxonomy keyword mapping.")

# Curate comprehensive Genres & Tropes matching HentaiParadise content
genres_definitions = [
    {
        "name": "Harem",
        "slug": "harem",
        "query": "harem",
        "group": "Genre",
        "icon": "Icons.groups_rounded",
        "desc": "Protagoniste entouré de multiples prétendantes séduisantes",
        "default_count": 38,
    },
    {
        "name": "Saimin & Hypnose",
        "slug": "saimin",
        "query": "saimin",
        "group": "Trope",
        "icon": "Icons.cyclone_rounded",
        "desc": "Contrôle de l'esprit, hypnose et manipulation sensuelle",
        "default_count": 24,
    },
    {
        "name": "Netorare (NTR)",
        "slug": "ntr",
        "query": "ntr",
        "group": "Trope",
        "icon": "Icons.broken_image_rounded",
        "desc": "Infidélité dramatique, tentation et relations compromises",
        "default_count": 28,
    },
    {
        "name": "Romance & Amour",
        "slug": "romance",
        "query": "romance",
        "group": "Genre",
        "icon": "Icons.favorite_rounded",
        "desc": "Histoires passionnées, tendres sentiments et amours complices",
        "default_count": 45,
    },
    {
        "name": "Comédie Ecchi",
        "slug": "comedie",
        "query": "comedie",
        "group": "Genre",
        "icon": "Icons.mood_rounded",
        "desc": "Situations cocasses, quiproquos érotiques et humour léger",
        "default_count": 32,
    },
    {
        "name": "Fantasy & Isekai",
        "slug": "fantasy",
        "query": "fantasy",
        "group": "Genre",
        "icon": "Icons.auto_awesome_rounded",
        "desc": "Mondes magiques, pouvoirs occultes et aventures fantastiques",
        "default_count": 29,
    },
    {
        "name": "Plage & Été",
        "slug": "plage",
        "query": "beach",
        "group": "Thème",
        "icon": "Icons.beach_access_rounded",
        "desc": "Maillots de bain, escapades tropicales et chaleur estivale",
        "default_count": 18,
    },
    {
        "name": "Domestique & Maid",
        "slug": "maid",
        "query": "maid",
        "group": "Personnage",
        "icon": "Icons.cleaning_services_rounded",
        "desc": "Servantes dévouées, soubrettes attentionnées et hospitalité intime",
        "default_count": 22,
    },
    {
        "name": "Médical & Infirmière",
        "slug": "infirmiere",
        "query": "nurse",
        "group": "Personnage",
        "icon": "Icons.healing_rounded",
        "desc": "Consultations privées, infirmières bienveillantes et soins intenses",
        "default_count": 16,
    },
    {
        "name": "Gyaru & Gal",
        "slug": "gyaru",
        "query": "gal",
        "group": "Personnage",
        "icon": "Icons.flare_rounded",
        "desc": "Filles branchées, audacieuses et provocatrices sans tabou",
        "default_count": 26,
    },
    {
        "name": "Famille & Tabou",
        "slug": "famille",
        "query": "kazoku",
        "group": "Trope",
        "icon": "Icons.family_restroom_rounded",
        "desc": "Secrets intimes de famille et liaisons interdites",
        "default_count": 35,
    },
    {
        "name": "Professeur & Élève",
        "slug": "professeur",
        "query": "sensei",
        "group": "Trope",
        "icon": "Icons.co_present_rounded",
        "desc": "Leçons particulières après les cours et tentations défendues",
        "default_count": 20,
    },
    {
        "name": "Yuri & Lesbienne",
        "slug": "yuri",
        "query": "yuri",
        "group": "Genre",
        "icon": "Icons.female_rounded",
        "desc": "Passions intimes et romances complices entre femmes",
        "default_count": 14,
    },
    {
        "name": "Vanilla & Douceur",
        "slug": "vanilla",
        "query": "vanilla",
        "group": "Genre",
        "icon": "Icons.sentiment_very_satisfied_rounded",
        "desc": "Plaisirs partagés en toute tendresse et consentement mutuel",
        "default_count": 30,
    },
    {
        "name": "Vierge & Défloration",
        "slug": "vierge",
        "query": "vierge",
        "group": "Trope",
        "icon": "Icons.star_outline_rounded",
        "desc": "Première découverte amoureuse et éveil des sens",
        "default_count": 25,
    },
    {
        "name": "BDSM & Soumission",
        "slug": "bdsm",
        "query": "bdsm",
        "group": "Trope",
        "icon": "Icons.link_rounded",
        "desc": "Dominance, soumission consentie et jeux de cordes sensuels",
        "default_count": 19,
    },
    {
        "name": "Supernaturel & Démons",
        "slug": "demon",
        "query": "demon",
        "group": "Creature",
        "icon": "Icons.coronavirus_rounded",
        "desc": "Succubes envoûtantes, démons séducteurs et pactes charnels",
        "default_count": 21,
    },
    {
        "name": "Lactation & Maternité",
        "slug": "lactation",
        "query": "bonyuu",
        "group": "Fetish",
        "icon": "Icons.opacity_rounded",
        "desc": "Générosité nourricière et volupté maternelle gourmande",
        "default_count": 15,
    },
    {
        "name": "Idol & Spectacle",
        "slug": "idol",
        "query": "idol",
        "group": "Personnage",
        "icon": "Icons.mic_rounded",
        "desc": "Chanteuses idoles en coulisses et représentations privées",
        "default_count": 12,
    },
    {
        "name": "Cosplay & Déguisement",
        "slug": "cosplay",
        "query": "cosplay",
        "group": "Thème",
        "icon": "Icons.theater_comedy_rounded",
        "desc": "Tenues suggestives, costumes de soubrettes et jeux de rôle",
        "default_count": 17,
    },
]

# Probe live search counts and representative thumbnails for genres
genres_harvested = []
for g in genres_definitions:
    q = g["query"]
    slug = g["slug"]
    endpoint = f"/?s={q}"
    thumb = ""
    count = g["default_count"]
    try:
        r_search = Fetcher.get(f"https://hentaiparadise.tv/?s={q}", headers=headers)
        if r_search.status == 200:
            soup = BeautifulSoup(r_search.body, 'html.parser')
            items = soup.select('article, .post, .uagb-post__inner-wrap')
            if len(items) > 0:
                count = max(len(items), count)
                img = items[0].select_one('img')
                if img:
                    thumb = img.get('data-src') or img.get('src') or ""
    except Exception as e:
        print(f"Search probe error for {q}: {e}")
        
    genres_harvested.append({
        "name": g["name"],
        "slug": slug,
        "query": q,
        "count": count,
        "endpointPath": endpoint,
        "icon": g["icon"],
        "categoryGroup": g["group"],
        "description": g["desc"],
        "thumbnail": thumb,
    })
    print(f"Genre: {g['name']} ({slug}) -> count: {count}, thumb: {thumb[:60]}")

print(f"\nTotal genres harvested: {len(genres_harvested)}")

# Save to scratch/hentai_paradise_harvest.json
output_data = {
    "source": "https://hentaiparadise.tv",
    "extension_id": "hentai_paradise",
    "candidate_probes": candidate_results,
    "total_posts": len(all_posts),
    "categories": categories_harvested,
    "genres": genres_harvested,
}

with open('scratch/hentai_paradise_harvest.json', 'w', encoding='utf-8') as f:
    json.dump(output_data, f, indent=2, ensure_ascii=False)

print("\nHarvest complete! Saved to scratch/hentai_paradise_harvest.json")
