from bs4 import BeautifulSoup

with open('scratch/categories.html', 'r', encoding='utf-8') as f:
    soup = BeautifulSoup(f.read(), 'html.parser')

h1 = soup.find_all(['h1', 'h2', 'h3'])
for h in h1[:10]:
    print(h.name, h.get_text(strip=True))

# Check pagination or breadcrumb or title
print("Title:", soup.title.string if soup.title else "None")
print("Meta description:", soup.find('meta', {'name': 'description'}))
print("Canonical link:", soup.find('link', {'rel': 'canonical'}))
