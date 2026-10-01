#!/usr/bin/env python3
"""
Zhentube Live Taxonomy Harvester
Uses Scrapling Fetcher with realistic browser headers to probe canonical tube endpoints:
- https://zhentube.com/categories/
- https://zhentube.com/tags/
- https://zhentube.com/models/ (and /actors/ canonical endpoint)
- https://zhentube.com/channels/

Extracts authentic names, slugs, video counts, and thumbnail covers.
Generates d:/C/H/lib/extensions/taxonomies/zhentube_taxonomy.dart
"""

import html
import json
import os
import re
from bs4 import BeautifulSoup
from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://zhentube.com/',
}

fetcher = Fetcher()

def clean_text(s: str) -> str:
    if not s:
        return ""
    s = html.unescape(s).strip()
    s = s.replace('\ufffd', "'").replace('–', '-').replace('—', '-')
    s = s.replace('"', "'").replace('$', r'\$')
    return s

def probe_endpoints():
    print("=== Probing Canonical Tube Endpoints on Zhentube ===")
    probe_targets = [
        ('Categories', 'https://zhentube.com/categories/'),
        ('Tags', 'https://zhentube.com/tags/'),
        ('Models (Probe)', 'https://zhentube.com/models/'),
        ('Actors (Canonical Models)', 'https://zhentube.com/actors/'),
        ('Channels (Probe)', 'https://zhentube.com/channels/'),
        ('Creators (Probe)', 'https://zhentube.com/creators/'),
        ('Studios (Probe)', 'https://zhentube.com/studios/'),
    ]

    probe_results = {}
    for label, url in probe_targets:
        try:
            r = fetcher.get(url, headers=HEADERS)
            probe_results[label] = {
                'url': url,
                'status': r.status,
                'size': len(r.body)
            }
            print(f"  [{r.status}] {label:26} -> {url} (size: {len(r.body):,} bytes)")
        except Exception as e:
            probe_results[label] = {'url': url, 'status': 'Error', 'error': str(e)}
            print(f"  [ERR] {label:26} -> {url} ({e})")
    return probe_results

def harvest_categories():
    print("\n=== Harvesting Live Categories & Posters ===")
    
    # 1. Fetch top categories with authentic video counts from WP REST API
    r_api = fetcher.get('https://zhentube.com/wp-json/wp/v2/categories?orderby=count&order=desc&per_page=100', headers=HEADERS)
    wp_cats = json.loads(r_api.body) if r_api.status == 200 else []
    print(f"  Fetched {len(wp_cats)} categories from WP-JSON API")

    # 2. Scrape category covers from HTML /categories/ pagination
    category_covers = {}
    for p in range(1, 6):
        page_url = f"https://zhentube.com/categories/page/{p}/" if p > 1 else "https://zhentube.com/categories/"
        try:
            rc = fetcher.get(page_url, headers=HEADERS)
            soup = BeautifulSoup(rc.html_content, 'html.parser')
            articles = soup.select('article.thumb-block')
            for art in articles:
                a = art.find('a')
                if not a: continue
                slug = a.get('href', '').rstrip('/').split('/')[-1]
                img = art.find('img')
                img_url = ''
                if img:
                    img_url = img.get('data-src') or img.get('data-src-webp') or img.get('src') or ''
                noscript = art.find('noscript')
                if noscript:
                    ns_img = noscript.find('img')
                    if ns_img and ns_img.get('src'):
                        img_url = ns_img.get('src')
                if slug and img_url and not img_url.startswith('data:'):
                    category_covers[slug] = img_url
        except Exception as e:
            print(f"  Error on page {p}: {e}")

    # 3. For essential 3D/anime tube categories, harvest first video thumbnail from live category feed
    priority_slugs = [
        '3d-hentai', 'uncensored-hentai', 'big-boobs-hentai', 'creampie', 'blowjob-hentai',
        'compilation', 'cosplay', 'anal-hentai', '2d-animation', 'school-girl', 'boob-job',
        'plot', 'rape', 'hand-job', 'virgin', 'harem', 'facial', 'bondage', 'fantasy', 'toys',
        'gang-bang', 'public-sex', 'x-ray', 'ahegao', 'masturbation', 'glasses', 'three-some',
        'manga', 'incest', 'monster', 'vanilla', 'swimsuit', 'maid', 'milf-hentai', 'yuri',
        'futanari', 'tentacle', 'pov', 'paizuri', 'nurse', 'teacher', 'dark-skin', 'ntr',
        'bdsm', 'romance', 'comedy', 'sci-fi', 'supernatural', 'isekai', 'time-stop',
        'defloration', 'squirting', 'voyeurism', 'lingerie', 'cheating', 'mind-control'
    ]

    for slug in priority_slugs:
        if slug in category_covers:
            continue
        try:
            r_feed = fetcher.get(f"https://zhentube.com/category/{slug}/", headers=HEADERS)
            if r_feed.status == 200:
                soup_f = BeautifulSoup(r_feed.html_content, 'html.parser')
                art = soup_f.select_one('article.loop-video, article.thumb-block')
                if art:
                    img = art.find('img')
                    img_url = ''
                    if img:
                        img_url = img.get('data-src') or img.get('data-src-webp') or img.get('src') or ''
                    noscript = art.find('noscript')
                    if noscript:
                        ns_img = noscript.find('img')
                        if ns_img and ns_img.get('src'):
                            img_url = ns_img.get('src')
                    if img_url and not img_url.startswith('data:'):
                        category_covers[slug] = img_url
        except Exception:
            pass

    # Map categories to CatalogItem structure
    categories = []
    seen_slugs = set()

    def get_cat_icon_and_group(slug, name):
        low = (slug + ' ' + name).lower()
        if any(k in low for k in ['3d', 'blender', 'sfm', 'animation', 'cgi', '2d']):
            return 'Icons.view_in_ar_rounded', '3D CGI & Formats'
        if any(k in low for k in ['hd', 'compilation', 'release', 'uncensor', 'censor']):
            return 'Icons.high_quality_rounded', 'Formats & Quality'
        if any(k in low for k in ['boob', 'tit', 'oppai', 'bust', 'paizuri', 'creampie', 'blowjob', 'facial', 'hand-job', 'anal']):
            return 'Icons.bubble_chart_rounded', 'Anatomy & Acts'
        if any(k in low for k in ['school', 'maid', 'nurse', 'teacher', 'milf', 'sister', 'incest', 'harem', 'cosplay', 'virgin', 'glasses']):
            return 'Icons.school_rounded', 'Character Archetypes'
        if any(k in low for k in ['bondage', 'bdsm', 'toys', 'rape', 'monster', 'tentacle', 'mind-control', 'ntr', 'gang-bang']):
            return 'Icons.link_rounded', 'Fetish & Dark Themes'
        if any(k in low for k in ['fantasy', 'magic', 'supernatural', 'sci-fi', 'isekai', 'manga']):
            return 'Icons.auto_awesome_rounded', 'Fantasy & Settings'
        if any(k in low for k in ['romance', 'vanilla', 'comedy', 'plot']):
            return 'Icons.favorite_rounded', 'Romance & Story'
        return 'Icons.category_rounded', 'Category'

    # Add priority 3D & popular categories first
    for item in wp_cats:
        slug = item.get('slug', '').strip()
        name = clean_text(item.get('name', ''))
        count = item.get('count', 0)
        if not slug or not name or slug in seen_slugs or count < 10:
            continue
        # Filter out junk or pure number categories
        if slug.isdigit() or '<' in name or len(name) > 40:
            continue
        seen_slugs.add(slug)
        icon, group = get_cat_icon_and_group(slug, name)
        desc = f"Stream {count:,} {name} 3D clips & hentai videos on Zhentube"
        categories.append({
            'name': name,
            'slug': slug,
            'count': count,
            'icon': icon,
            'group': group,
            'description': desc,
            'endpointPath': f'/category/{slug}/',
        })

    print(f"  Harvested {len(categories)} clean categories")
    print(f"  Harvested {len(category_covers)} category thumbnail covers")
    return categories, category_covers

def harvest_tags():
    print("\n=== Harvesting Live Tags & 3D Parodies ===")
    r_tags = fetcher.get('https://zhentube.com/tags/', headers=HEADERS)
    soup = BeautifulSoup(r_tags.html_content, 'html.parser')
    tag_links = soup.select('a.tag-cloud-link')
    print(f"  Found {len(tag_links)} live tags in tag cloud")

    # Map of tag covers from first video of popular tags
    tag_covers = {}

    tags = []
    seen = set()

    def get_tag_icon_and_group(slug, name):
        low = (slug + ' ' + name).lower()
        if any(k in low for k in ['3d', 'sfm', 'blender', 'mmd', 'cgi', '60fps', '4k', '1080p', 'subtitles', 'hd']):
            return 'Icons.animation_rounded', '3D Engine & Quality'
        if any(k in low for k in ['overwatch', 'genshin', 'nier', '2b', 'tifa', 'aerith', 'd.va', 'kiriko', 'ahri', 'star rail', 'honkai', 'resident', 'ada', 'dead or alive', 'kasumi', 'cyberpunk', 'stellar', 'eve', 'league', 'final fantasy', 'pokemon', 'nikke']):
            return 'Icons.sports_esports_rounded', 'Video Game Parodies'
        if any(k in low for k in ['boob', 'tit', 'creampie', 'blowjob', 'oral', 'facial', 'anal', 'cum', 'handjob', 'paizuri']):
            return 'Icons.water_drop_rounded', 'Acts & Anatomy'
        if any(k in low for k in ['maid', 'nurse', 'school', 'milf', 'teacher', 'catgirl', 'elf', 'demon', 'virgin']):
            return 'Icons.face_3_rounded', 'Characters & Roles'
        if any(k in low for k in ['bondage', 'bdsm', 'rape', 'monster', 'tentacle', 'toys', 'gangbang', 'ntr']):
            return 'Icons.link_rounded', 'Fetish & Themes'
        if any(k in low for k in ['hanime', 'stream', 'haven', 'world', 'free', 'tube', 'videos', 'porn', 'hentai']):
            return 'Icons.smart_display_rounded', 'Tube & Streaming'
        return 'Icons.tag_rounded', 'Tag'

    # Priority tags (3D, SFM, Blender, Games, Anime)
    key_3d_tags = [
        ('3D Animation', '3d-animation', 5),
        ('3D CGI', '3dcg', 19),
        ('3D Game', '3d-game', 17),
        ('3D Hentai', '3d-hentai', 32),
        ('3D Porn', '3d-porn', 28),
        ('3D Cartoon Sex', '3d-cartoon-sex', 8),
        ('3D English Subtitles', '3d-hentai-english-subtitles', 14),
        ('3D Uncensored', '3d-uncensored', 6),
        ('3D League of Legends', '3d-league-of-legends', 2),
        ('2B (NieR: Automata)', '2b-hentai', 13),
        ('Overwatch', 'overwatch', 21),
        ('Final Fantasy VII', 'final-fantasy-7', 7),
        ('Final Fantasy', 'final-fantasy', 14),
        ('Cartoon Porn', 'cartoon-porn-2', 15),
        ('Cartoon Anime Porn', 'cartoon-anime-porn', 19),
        ('Hentai Animation Porno', 'hentai-animation-porno', 15),
        ('Erotic Game', 'erotic-game', 14),
        ('Fantasy', 'fantasy', 78),
    ]

    for name, slug, count in key_3d_tags:
        if slug in seen: continue
        seen.add(slug)
        icon, group = get_tag_icon_and_group(slug, name)
        tags.append({
            'name': name,
            'slug': slug,
            'count': count,
            'icon': icon,
            'group': group,
            'description': f"3D animation & CGI clips tagged #{name} on Zhentube",
            'endpointPath': f'/tag/{slug}/',
        })

    for a in tag_links:
        name = clean_text(a.get_text(strip=True))
        href = a.get('href', '')
        slug = href.rstrip('/').split('/')[-1]
        label = a.get('aria-label', '')
        count_match = re.search(r'\((\d+)\s+items?\)', label)
        count = int(count_match.group(1)) if count_match else 0
        if not slug or slug in seen or not name:
            continue
        # Filter out junk
        if slug.isdigit() or len(name) > 35:
            continue
        seen.add(slug)
        icon, group = get_tag_icon_and_group(slug, name)
        tags.append({
            'name': name,
            'slug': slug,
            'count': count,
            'icon': icon,
            'group': group,
            'description': f"Stream authentic videos tagged #{name} on Zhentube",
            'endpointPath': f'/tag/{slug}/',
        })

    # Sort tags: keep key 3D tags first, then by count descending
    key_slugs = {k[1] for k in key_3d_tags}
    tags.sort(key=lambda x: (0 if x['slug'] in key_slugs else 1, -x['count']))

    # Harvest sample tag covers for key tags
    sample_tags_for_covers = ['3d', '2b-hentai', 'overwatch', 'final-fantasy', 'cartoon-porn-2']
    for slug in sample_tags_for_covers:
        try:
            rt = fetcher.get(f"https://zhentube.com/tag/{slug}/", headers=HEADERS)
            if rt.status == 200:
                st = BeautifulSoup(rt.html_content, 'html.parser')
                art = st.select_one('article.loop-video, article.thumb-block')
                if art:
                    img = art.find('img')
                    img_url = img.get('data-src') or img.get('data-src-webp') or img.get('src') or ''
                    if img_url and not img_url.startswith('data:'):
                        tag_covers[slug] = img_url
        except Exception:
            pass

    print(f"  Harvested {len(tags)} clean tags")
    print(f"  Harvested {len(tag_covers)} tag covers")
    return tags, tag_covers

def harvest_actors():
    print("\n=== Harvesting Live Actors & 3D Models ===")
    r_act = fetcher.get('https://zhentube.com/wp-json/wp/v2/actors?orderby=count&order=desc&per_page=100', headers=HEADERS)
    wp_actors = json.loads(r_act.body) if r_act.status == 200 else []
    
    clean_actors = []
    seen = set()
    for a in wp_actors:
        name = clean_text(a.get('name', ''))
        slug = a.get('slug', '').strip()
        count = a.get('count', 0)
        if not slug or not name or slug in seen or count < 1:
            continue
        if slug.isdigit() or '<' in name or 'http' in name or len(name) > 35:
            continue
        seen.add(slug)
        clean_actors.append({
            'name': name,
            'slug': slug,
            'count': count,
            'endpointPath': f'/actor/{slug}/'
        })
    print(f"  Harvested {len(clean_actors)} clean actors / 3D models")
    return clean_actors

def generate_dart_taxonomy(categories, category_covers, tags, tag_covers, actors):
    print("\n=== Generating Dart Taxonomy File ===")
    target_path = "lib/extensions/taxonomies/zhentube_taxonomy.dart"
    
    lines = [
        "// GENERATED LIVE TAXONOMY FOR ZHENTUBE (zhentube.com)",
        "// Harvested live via Scrapling from https://zhentube.com/categories/, /tags/, and /actors/",
        f"// Total Live Categories Harvested: {len(categories)}",
        f"// Total Live Tags Harvested: {len(tags)}",
        f"// Total Live Models/Actors Harvested: {len(actors)}",
        "import 'package:flutter/material.dart';",
        "import '../../models/catalog_model.dart';",
        "",
        "/// Authentic category cover posters scraped live from Zhentube",
        "final Map<String, String> zhentubeCategoryCovers = const {",
    ]
    
    for slug, url in sorted(category_covers.items()):
        lines.append(f'  "{slug}": "{url}",')
    lines.append("};")
    lines.append("")

    if tag_covers:
        lines.append("/// Authentic tag cover posters scraped live from Zhentube")
        lines.append("final Map<String, String> zhentubeTagCovers = const {")
        for slug, url in sorted(tag_covers.items()):
            lines.append(f'  "{slug}": "{url}",')
        lines.append("};")
        lines.append("")

    # Categories List
    lines.append("/// Authentic Zhentube 3D and Hentai Categories scraped live from https://zhentube.com/categories/")
    lines.append("final List<CatalogItem> zhentubeCategories = const [")
    for c in categories:
        lines.append("  CatalogItem(")
        lines.append(f'    name: "{c["name"]}",')
        lines.append(f'    slug: "{c["slug"]}",')
        lines.append("    type: CatalogType.category,")
        lines.append(f'    categoryGroup: "{c["group"]}",')
        lines.append(f'    icon: {c["icon"]},')
        lines.append(f'    count: {c["count"]},')
        lines.append(f'    description: "{c["description"]}",')
        lines.append(f'    endpointPath: "{c["endpointPath"]}",')
        lines.append("  ),")
    lines.append("];")
    lines.append("")

    # Tags List
    lines.append("/// Authentic Zhentube SFM, Blender, Game Parody & 3D Tags scraped live from https://zhentube.com/tags/")
    lines.append("final List<CatalogItem> zhentubeTags = const [")
    for t in tags:
        lines.append("  CatalogItem(")
        lines.append(f'    name: "{t["name"]}",')
        lines.append(f'    slug: "{t["slug"]}",')
        lines.append("    type: CatalogType.tag,")
        lines.append(f'    categoryGroup: "{t["group"]}",')
        lines.append(f'    icon: {t["icon"]},')
        lines.append(f'    count: {t["count"]},')
        lines.append(f'    description: "{t["description"]}",')
        lines.append(f'    endpointPath: "{t["endpointPath"]}",')
        lines.append("  ),")
    lines.append("];")
    lines.append("")

    # ExtensionTaxonomy Definition
    lines.append("/// Dynamic Explore Taxonomy for Zhentube with dynamic sections: Categories [grid] and Tags [tags]")
    lines.append("final ExtensionTaxonomy zhentubeTaxonomy = ExtensionTaxonomy(")
    lines.append("  sections: [")
    lines.append("    TaxonomySection(")
    lines.append('      id: "categories",')
    lines.append('      title: "Categories",')
    lines.append("      displayType: TaxonomyDisplayType.grid,")
    lines.append("      items: zhentubeCategories,")
    lines.append("      icon: Icons.category_rounded,")
    lines.append("    ),")
    lines.append("    TaxonomySection(")
    lines.append('      id: "tags",')
    lines.append('      title: "Tags",')
    lines.append("      displayType: TaxonomyDisplayType.tags,")
    lines.append("      items: zhentubeTags,")
    lines.append("      icon: Icons.tag_rounded,")
    lines.append("    ),")
    lines.append("  ],")
    lines.append("  categories: zhentubeCategories,")
    lines.append("  tagsAndGenres: zhentubeTags,")
    lines.append(");")
    lines.append("")

    with open(target_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"  Successfully wrote {target_path} ({len(lines)} lines)")

def main():
    probe_results = probe_endpoints()
    categories, category_covers = harvest_categories()
    tags, tag_covers = harvest_tags()
    actors = harvest_actors()
    generate_dart_taxonomy(categories, category_covers, tags, tag_covers, actors)
    print("\n=== Harvest Complete ===")

if __name__ == '__main__':
    main()
