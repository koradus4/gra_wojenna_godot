# Notatki: kontener mapy z projektu `gra_wojennna`

Poniżej znajdziesz odwołania do plików w głównym repozytorium oraz wskazówki, jak rozszerzać szablon:

## Gdzie szukać pełnych implementacji

| Element | Oryginalny plik |
| --- | --- |
| Siatka + logika tury | `scripts/hex_grid.gd` |
| Wizualizacja kafla | `scripts/hex_tile.gd` |
| Sterowanie kamerą | `scripts/camera_controller.gd` |
| Scena gry | `scenes/main.tscn` |
| Dane mapy | `data/map_data.json` |

Te pliki zawierają rozbudowane mechaniki (tokeny, graczy, UI, logi walki). Szablony w `mapa_godot` są ich lekką wersją przygotowaną jako punkt startowy.

## Najczęstsze modyfikacje

1. **Większa mapa / inne tło** – zmień `meta.cols`, `meta.rows` oraz rozmiar tła w JSON. `HexGridTemplate` automatycznie przeskaluje kamerę.
2. **Dodatkowe dane na heksie** – dopisz pola w JSON (np. `"supply": 10`) i rozszerz `HexTileTemplate.load_from_data`, aby je przechowywać lub pokazywać.
3. **Interakcja z tokenami** – w pełnej wersji tokeny są tworzone w `hex_grid.gd`. W nowym projekcie możesz dodać własną klasę `Token` i dołożyć ją podobnie jak kafle (`add_child`).
4. **Szerszy UI** – zobacz funkcję `setup_ui()` w `scripts/hex_grid.gd`, jeśli chcesz dodać panele tur, przyciski itp.

## Pomocne snippet-y

### Szybkie pobranie heksa pod kursorem
```gdscript
var hovered := $HexGrid.get_tile_at_mouse()
if hovered:
    print(hovered.q, hovered.r, hovered.terrain_key)
```

### Podświetlenie zakresu
```gdscript
func highlight_range(center: Vector2i, radius: int):
    for tile in $HexGrid.tiles.values():
        tile.set_highlighted(false)
    for tile in $HexGrid.tiles.values():
        var dist := HexUtilsTemplate.hex_distance(Vector2i(tile.q, tile.r), center)
        tile.set_highlighted(dist <= radius)
```

### Dodanie własnego JSON
```gdscript
@export var map_data_path := "res://data/twoja_mapa.json"
```

Powyższe przykłady pokażą się w Inspektorze Godota, jeśli skrypt ma adnotację `@export` (jak w szablonie).
