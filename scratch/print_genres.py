import json

with open('scratch/harvested_genres.json', 'r', encoding='utf-8') as f:
    genres = json.load(f)

print(f"Total genres: {len(genres)}")
for g in genres:
    print(f"  {g['slug']}: {g['name']} ({g['count']}) -> {g['description'][:60]}...")
