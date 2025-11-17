import json
import math

# Wczytaj mapę
with open('data/map_data.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Nowe wymiary: +10 kolumn, +10 wierszy
old_cols = data['meta']['cols']
old_rows = data['meta']['rows']
new_cols = old_cols + 10
new_rows = old_rows + 10

# Przesuń wszystkie heksy o (5,5) żeby wycentrować
terrain = data['terrain']
new_terrain = {}

for key, value in terrain.items():
    q, r = map(int, key.split(','))
    new_q = q + 5
    new_r = r + 5
    new_key = f"{new_q},{new_r}"
    new_terrain[new_key] = value

# Wypełnij nowe brzegi plains
hex_size = data['meta']['hex_size']
for q in range(new_cols):
    for r in range(new_rows):
        key = f"{q},{r}"
        if key not in new_terrain:
            new_terrain[key] = {
                "type": "plains",
                "elevation": 0,
                "variant": 0
            }

# Zaktualizuj meta
data['meta']['cols'] = new_cols
data['meta']['rows'] = new_rows
# Przelicz rozmiar tła (flat-top: width = cols * 1.5 * size, height = rows * sqrt(3) * size)
sqrt3 = math.sqrt(3)
data['meta']['background']['width'] = int(new_cols * 1.5 * hex_size + hex_size)
data['meta']['background']['height'] = int(new_rows * sqrt3 * hex_size)

data['terrain'] = new_terrain

# Zapisz
with open('data/map_data.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2)

print(f"Mapa rozszerzona z {old_cols}×{old_rows} do {new_cols}×{new_rows}")
print(f"Wszystkie heksy przesunięte o (5,5)")
print(f"Nowe wymiary tła: {data['meta']['background']['width']}×{data['meta']['background']['height']}")
