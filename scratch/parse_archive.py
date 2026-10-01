from scrapling.fetchers import Fetcher
from scrapling.parser import Adaptor

f = Fetcher()
r = f.get('https://www.hentaiworld.me/archive')
doc = Adaptor(r.body.decode('utf-8'))

print("Forms:")
for form in doc.css('form'):
    print("Form action:", form.attrib.get('action'), "method:", form.attrib.get('method'))
    for inp in form.css('input, select, button'):
        print("   ", inp.tag, inp.attrib.get('name'), inp.attrib.get('type'), inp.attrib.get('value'))

print("\nSelects:")
for sel in doc.css('select'):
    print("Select:", sel.attrib.get('name'), sel.attrib.get('id'))
    for opt in sel.css('option'):
        print("  Option:", opt.attrib.get('value'), "->", opt.css('::text').get())

print("\nLinks in archive:")
for a in doc.css('a'):
    href = a.attrib.get('href', '')
    text = ''.join(a.css('::text').getall()).strip()
    if any(k in href for k in ['sort', 'order', 'type', 'genre', 'category', 'status']):
        print(f"  {text} -> {href}")
