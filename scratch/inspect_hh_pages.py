from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaihaven.red/',
}

def inspect_page(url):
    print(f"\n=================== {url} ===================")
    p = Fetcher.get(url, headers=headers, timeout=15)
    print(f"Status: {p.status}, Body len: {len(p.body)}")
    
    # Check links with genre/category/studio/series
    links = p.css('a')
    print(f"Total links: {len(links)}")
    
    # Look for list elements or grids
    sample_links = []
    for a in links:
        href = a.attrib.get('href', '')
        text = a.get_all_text().strip()
        if any(x in href for x in ['/genre/', '/category/', '/studio/', '/series/', '/tag/', '/brand/']):
            sample_links.append((text, href))
    
    print(f"Matching taxonomy links ({len(sample_links)}):")
    for t, h in sample_links[:20]:
        print(f"  {t} -> {h}")
    if len(sample_links) > 20:
        print(f"  ... and {len(sample_links)-20} more")

inspect_page('https://hentaihaven.red/genres/')
inspect_page('https://hentaihaven.red/categories/')
inspect_page('https://hentaihaven.red/studios/')
inspect_page('https://hentaihaven.red/series/')
