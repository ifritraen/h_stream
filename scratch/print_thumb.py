from bs4 import BeautifulSoup

with open('scratch/tags.html', 'r', encoding='utf-8') as f:
    soup = BeautifulSoup(f.read(), 'html.parser')

thumbs = soup.select('.row.galleries .thumb')
print(f"Total thumbs in tags page: {len(thumbs)}")
if thumbs:
    print(thumbs[0].prettify())
