import json, re, sys, subprocess, os

def fetch_wiktionary_cat(category, limit=500, cont=None):
    """Fetch a category of words from English Wiktionary"""
    url = f'https://en.wiktionary.org/w/api.php?action=query&list=categorymembers&cmtitle=Category:{category}&cmlimit={limit}&format=json'
    if cont:
        url += f'&cmcontinue={cont}'
    result = subprocess.run(['curl', '-s', url, '-H', 'User-Agent: Mozilla/5.0'], 
                          capture_output=True, text=True, timeout=30)
    data = json.loads(result.stdout)
    items = data['query']['categorymembers']
    next_cont = data.get('continue', {}).get('cmcontinue', None)
    return items, next_cont

def extract_cyrillic_words(items, min_len=2, max_len=6):
    words = set()
    for item in items:
        title = item['title']
        if re.match(r'^[А-Яа-яӀӏ]+$', title) and min_len <= len(title) <= max_len:
            words.add(title.lower())
    return words

# Fetch multiple categories
categories = [
    'Chechen_nouns',
    'Chechen_adjectives',
    'Chechen_verbs',
    'Chechen_adverbs',
]

all_words = set()

for cat in categories:
    print(f'Fetching {cat}...', file=sys.stderr)
    items, cont = fetch_wiktionary_cat(cat, 500)
    words = extract_cyrillic_words(items)
    all_words.update(words)
    print(f'  Got {len(words)} words, continue={cont}', file=sys.stderr)
    
    # Follow continuation up to 3 times
    i = 0
    while cont and i < 5:
        items, cont = fetch_wiktionary_cat(cat, 500, cont)
        words = extract_cyrillic_words(items)
        all_words.update(words)
        i += 1
        print(f'  Page {i+1}: +{len(words)}, continue={cont}', file=sys.stderr)

print(f'\nTotal unique words: {len(all_words)}', file=sys.stderr)
for w in sorted(all_words):
    print(w)
