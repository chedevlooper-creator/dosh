# -*- coding: utf-8 -*-
"""
Дош seviye üreteci — tekrarsız, tutarlı, gerçek Çeçence.

Amaç (kullanıcı isteği):
  * 1. seviyeden itibaren hatasız, düzenli bir seviye yapısı
  * AYNI KELİME OYUN BOYUNCA İKİ KEZ GELMESİN (ne grid ne bonus)
  * saçma/dolgu bonus tekrarları yok

Yöntem: doğrulanmış kelime havuzundan (cechen_curated + master + words)
geri-izlemeli (backtracking) çapraz bulmaca yerleştirici ile her seviyeyi
kurar; çark = grid kelimelerinin grafem-bazlı eleman-maksimumu; bonus =
çarktan kurulabilen, daha önce kullanılmamış gerçek kelimeler. Çıktı:
assets/levels/levels.json ve assets/i18n/ce.json (info_ anlamları yenilenir).

Grafem mantığı lib/core/graphemes.dart ile birebir aynıdır.
"""
import json
import os
import re
import random
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # dosh/
ASSETS = os.path.join(ROOT, 'assets')

PAL = 'Ӏ'  # Ӏ


def normalize(s):
    s = s.lower()
    out = []
    for ch in s:
        if ch in ('ӏ', 'Ӏ', 'i'):  # küçük palochka, palochka, latin i (lower'dan sonra)
            out.append(PAL)
        else:
            out.append(ch)
    return ''.join(out).strip()


DIGRAPHS = set(normalize(d) for d in
               ['аь', 'гӀ', 'кх', 'къ', 'кӀ', 'оь', 'пӀ', 'тӀ', 'уь',
                'хь', 'хӀ', 'цӀ', 'чӀ', 'юь', 'яь'])


def split_graphemes(w):
    w = normalize(w)
    res = []
    i = 0
    while i < len(w):
        if i + 1 < len(w) and w[i:i + 2] in DIGRAPHS:
            res.append(w[i:i + 2])
            i += 2
        else:
            res.append(w[i])
            i += 1
    return res


def is_clean(w):
    w = normalize(w)
    if not w:
        return False
    for ch in w:
        if not (0x0400 <= ord(ch) <= 0x04FF):
            return False
    gl = len(split_graphemes(w))
    return 2 <= gl <= 6


def read(path):
    with open(path, encoding='utf-8') as f:
        return f.read()


# ----------------------------------------------------------------------------
# 1. Kelime havuzu + anlamlar
# ----------------------------------------------------------------------------
VOCAB = set()
MEANINGS = {}
CURATED = set()

# Yabancı/uygunsuz görünen alıntı kelimeler bonus havuzundan da çıkarılır.
BLACKLIST = set(normalize(w) for w in [
    'гитара', 'кофе', 'кухни', 'банан', 'ананас', 'инжир', 'пилот', 'артист',
    'юрист', 'книга', 'книшка', 'кни', 'кино', 'такси', 'росси', 'оьрсий',
    'россий', 'термин', 'минот', 'налог', 'росс', 'имам', 'закат', 'зайтун',
])

curated = read(os.path.join(ROOT, 'cechen_curated_for_game.txt'))
for line in curated.splitlines():
    line = line.strip()
    if not line or line.startswith('#') or line.startswith('['):
        continue
    if '—' in line:
        left, right = line.split('—', 1)
        w = normalize(left.strip())
        m = right.strip()
        if is_clean(w):
            VOCAB.add(w)
            CURATED.add(w)
            if m and not m.startswith('...') and not m.startswith('…'):
                MEANINGS[w] = m

for fn in ['cechen_words.txt', 'cechen_words_master.txt']:
    p = os.path.join(ROOT, fn)
    if not os.path.exists(p):
        continue
    for tok in re.split(r'[^Ѐ-ӿ]+', read(p)):
        w = normalize(tok)
        if is_clean(w):
            VOCAB.add(w)

# Var olan ce.json'daki anlamları yalnızca curated'da olmayan kelimeler için
# YEDEK olarak değil — güvenilirlik için yalnızca curated anlamlarını
# kullanıyoruz (kullanıcı "saçma" anlam istemiyor). ce.json anlamları es geçilir.

VOCAB = {w for w in VOCAB if w not in BLACKLIST or w in CURATED}
GMAP = {w: split_graphemes(w) for w in VOCAB}
LEN = {w: len(GMAP[w]) for w in VOCAB}

print(f"Havuz: {len(VOCAB)} kelime, {len(MEANINGS)} anlam, {len(CURATED)} curated")


# ----------------------------------------------------------------------------
# 2. Çapraz bulmaca yerleştirici (backtracking)
# ----------------------------------------------------------------------------
def place(word_strs):
    """word_strs interlock edilebiliyorsa yerleşim listesi döndürür, yoksa None."""
    splits = [GMAP.get(w) or split_graphemes(w) for w in word_strs]
    n = len(splits)
    grid = {}
    placements = [None] * n

    def cells_for(gs, r, c, d):
        if d == 'across':
            return [((r, c + i), gs[i]) for i in range(len(gs))]
        return [((r + i, c), gs[i]) for i in range(len(gs))]

    def valid_placement(gs, r, c, d):
        """Gerçek çapraz bulmaca kuralları: yalnız dik kesişim; uç-uca
        birleşme ve paralel-bitişik dokunma YOK. Eklenecek hücreleri döndürür."""
        L = len(gs)
        cells = cells_for(gs, r, c, d)
        # Kelimenin başından önce ve sonundan sonra boş olmalı (uzatma/birleşme yok)
        if d == 'across':
            if (r, c - 1) in grid or (r, c + L) in grid:
                return None
        else:
            if (r - 1, c) in grid or (r + L, c) in grid:
                return None
        added = []
        crossed = False
        for (rr, cc), g in cells:
            if (rr, cc) in grid:
                if grid[(rr, cc)] != g:
                    return None
                crossed = True  # dik kesişim
            else:
                # Boş hücrenin dik komşuları boş olmalı (paralel kelime dokunmaz)
                if d == 'across':
                    if (rr - 1, cc) in grid or (rr + 1, cc) in grid:
                        return None
                else:
                    if (rr, cc - 1) in grid or (rr, cc + 1) in grid:
                        return None
                added.append(((rr, cc), g))
        if not crossed:
            return None
        return added

    def rec(idx):
        if idx == n:
            return True
        gs = splits[idx]
        if idx == 0:
            cells = cells_for(gs, 0, 0, 'across')
            for rc, g in cells:
                grid[rc] = g
            placements[0] = (0, 0, 'across')
            if rec(1):
                return True
            for rc, g in cells:
                del grid[rc]
            placements[0] = None
            return False
        opts = []
        for (er, ec), eg in list(grid.items()):
            for i, g in enumerate(gs):
                if g == eg:
                    opts.append((er, ec - i, 'across'))
                    opts.append((er - i, ec, 'down'))
        seen = set()
        for (r, c, d) in opts:
            if (r, c, d) in seen:
                continue
            seen.add((r, c, d))
            added = valid_placement(gs, r, c, d)
            if added is None:
                continue
            for rc, g in added:
                grid[rc] = g
            placements[idx] = (r, c, d)
            if rec(idx + 1):
                return True
            for rc, g in added:
                del grid[rc]
            placements[idx] = None
        return False

    if not rec(0):
        return None
    min_r = min(r for r, c in grid)
    min_c = min(c for r, c in grid)
    return [
        {'word': word_strs[i],
         'row': placements[i][0] - min_r,
         'col': placements[i][1] - min_c,
         'dir': placements[i][2]}
        for i in range(n)
    ]


def wheel_multiset(words):
    """Grid kelimeleri için eleman-maksimum çark çoklu kümesi."""
    acc = Counter()
    for w in words:
        c = Counter(GMAP[w])
        for g, k in c.items():
            acc[g] = max(acc[g], k)
    return acc


def buildable(word, wheel):
    c = Counter(GMAP.get(word) or split_graphemes(word))
    for g, k in c.items():
        if wheel.get(g, 0) < k:
            return False
    return True


# ----------------------------------------------------------------------------
# 3. Seviye kurucu
# ----------------------------------------------------------------------------
rng = random.Random(20260614)

# Zorluk eğrisi
NUMW = [2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4]
CAP = [3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6]
BONUS = [0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4]
PAD_LETTERS = [normalize(x) for x in
               ['а', 'р', 'т', 'н', 'к', 'о', 'и', 'л', 'с', 'м', 'е', 'х', 'б', 'д', 'у', 'г']]

USED = set(normalize(w) for w in ['дош', 'до', 'шод', 'дошо'])  # tutorial rezerve

by_len = {}
for w in VOCAB:
    by_len.setdefault(LEN[w], []).append(w)


def grid_pref(words):
    # Anlamı olan + curated kelimeleri öne al (anlamlı sözlük için).
    return sorted(words, key=lambda w: (w not in MEANINGS, w not in CURATED, rng.random()))


def build_grid(num_words, cap, restarts=600):
    best = None
    for _ in range(restarts):
        # Spine: cap uzunluğunda (yoksa cap-1) kullanılmamış kelime, anlamlı tercih
        spine_pool = [w for L in (cap, cap - 1) for w in by_len.get(L, []) if w not in USED]
        if not spine_pool:
            continue
        spine_pool = grid_pref(spine_pool)
        spine = spine_pool[rng.randrange(min(len(spine_pool), 40))]
        chosen = [spine]
        placement = place(chosen)
        for _ in range(num_words - 1):
            cur_g = set(g for w in chosen for g in GMAP[w])
            cand = [w for w in VOCAB
                    if w not in USED and w not in chosen
                    and 2 <= LEN[w] <= cap
                    and (set(GMAP[w]) & cur_g)]
            cand = grid_pref(cand)
            added = False
            for w in cand[:120]:
                trial = place(chosen + [w])
                if trial is not None:
                    chosen.append(w)
                    placement = trial
                    added = True
                    break
            if not added:
                break
        if len(chosen) == num_words and placement is not None:
            return chosen, placement
        if best is None or len(chosen) > len(best[0]):
            if placement is not None:
                best = (chosen, placement)
    return best  # hedefe ulaşamazsa en iyi (>=2)


def pick_bonus(grid_words, wheel, target):
    if target == 0:
        return [], wheel
    pad = list(PAD_LETTERS)
    wheel = Counter(wheel)
    while True:
        cands = [w for w in VOCAB
                 if w not in USED and w not in grid_words
                 and buildable(w, wheel)]
        # Kısa ve anlamlı olanları öne al; çeşitlilik için karıştır
        cands = sorted(cands, key=lambda w: (LEN[w], w not in MEANINGS, rng.random()))
        if len(cands) >= target or not pad:
            return cands[:target], wheel
        # Çarkı yaygın bir harfle genişlet (daha çok bonus aç)
        wheel[pad.pop(0)] += 1


levels = []

# Tutorial (id 0) — mevcut haliyle korunur
levels.append({
    "id": 0,
    "letters": ["д", "о", "ш", "о"],
    "words": [
        {"word": "дош", "row": 0, "col": 0, "dir": "across"},
        {"word": "до", "row": 2, "col": 1, "dir": "across"},
    ],
    "bonus": ["шод"],
})

report = []
for i in range(30):
    num = NUMW[i]
    cap = CAP[i]
    res = build_grid(num, cap)
    if res is None:
        raise SystemExit(f"Seviye {i+1}: grid kurulamadı")
    grid_words, placement = res
    for w in grid_words:
        USED.add(w)
    wheel = wheel_multiset(grid_words)
    bonus, wheel = pick_bonus(grid_words, wheel, BONUS[i])
    for w in bonus:
        USED.add(w)
    # Çark listesi (çoklu küme; digraflar tek eleman)
    letters = []
    for g, k in wheel.items():
        letters.extend([g] * k)
    rng.shuffle(letters)
    levels.append({
        "id": i + 1,
        "letters": letters,
        "words": [{"word": p['word'], "row": p['row'], "col": p['col'], "dir": p['dir']}
                  for p in placement],
        "bonus": bonus,
    })
    report.append((i + 1, len(grid_words), grid_words, len(bonus), bonus, len(letters)))

# ----------------------------------------------------------------------------
# 4. Tekrar denetimi (kullanıcı şartı: aynı kelime iki kez gelmesin)
# ----------------------------------------------------------------------------
seen = Counter()
for lv in levels:
    for w in lv['words']:
        seen[normalize(w['word'])] += 1
    for b in lv['bonus']:
        seen[normalize(b)] += 1
dups = {w: c for w, c in seen.items() if c > 1}
if dups:
    raise SystemExit(f"TEKRAR VAR: {dups}")
print("Tekrar yok ✓  Toplam benzersiz kelime:", len(seen))

# Test kısıtları
game = levels[1:]
b_counts = [len(l['bonus']) for l in game]
print("Bonus dizisi:", b_counts)
print("ilk5:", sum(b_counts[:5]), "son5:", sum(b_counts[-5:]), "toplam:", sum(b_counts))
mono = all(b_counts[i] >= b_counts[i - 1] for i in range(1, len(b_counts)))
print("monoton:", mono)

# ----------------------------------------------------------------------------
# 5. Yaz: levels.json
# ----------------------------------------------------------------------------
with open(os.path.join(ASSETS, 'levels', 'levels.json'), 'w', encoding='utf-8') as f:
    json.dump(levels, f, ensure_ascii=False, indent=2)

# ----------------------------------------------------------------------------
# 6. ce.json info_ anlamlarını yenile (yalnız kullanılan kelimeler, curated anlam)
# ----------------------------------------------------------------------------
ce_path = os.path.join(ASSETS, 'i18n', 'ce.json')
with open(ce_path, encoding='utf-8') as f:
    ce = json.load(f)
base = {k: v for k, v in ce.items() if not k.startswith('info_')}
used_words = sorted(seen.keys())
info = {}
for w in used_words:
    if w in MEANINGS:
        info[f'info_{w}'] = MEANINGS[w]
merged = {}
merged.update(base)
for k in sorted(info.keys()):
    merged[k] = info[k]
with open(ce_path, 'w', encoding='utf-8') as f:
    json.dump(merged, f, ensure_ascii=False, indent=2)

print(f"info_ anahtarları: {len(info)} (kullanılan {len(seen)} kelimeden)")
print("\nSeviye raporu:")
for (lid, ng, gw, nb, bw, nl) in report:
    print(f"  S{lid:2d}: {ng} kelime {gw} | çark {nl} | {nb} bonus {bw}")
