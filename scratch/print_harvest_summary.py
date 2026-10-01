import json
with open('d:/C/H/scratch/hentai_ocean_harvested.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print('=== TOP 15 GENRES ===')
for g in data['genres'][:15]:
    thumb = g['thumbnail'][:60] if g['thumbnail'] else 'none'
    print(f"{g['name']:20} count={g['count']:4} thumb={thumb}")

print('\n=== TOP 15 PLAYLISTS / SERIES ===')
for p in data['playlists'][:15]:
    thumb = p['thumbnail'][:60] if p['thumbnail'] else 'none'
    print(f"{p['name']:40} eps={p['episodes']:2} thumb={thumb}")
