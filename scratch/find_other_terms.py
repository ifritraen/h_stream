with open('scratch/categories_rsc.txt', 'r', encoding='utf-8') as f:
    text = f.read()

for term in ['throat-fucking', 'softcore', 'anal']:
    pos = text.find(term)
    print(f"Term: {term} at {pos}")
    if pos != -1:
        print(text[max(0, pos-150):min(len(text), pos+200)])
        print("="*60)
