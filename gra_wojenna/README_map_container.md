# Szablon mapy heksagonalnej dla nowego projektu Godot

Ten folder zawiera kompletny, minimalny pakiet plików potrzebny do odtworzenia kontenera mapy heksagonalnej w świeżym projekcie Godot 4.x. Pliki są uproszczone względem pełnej gry (`gra_wojennna`) i skupiają się na trzech elementach:

1. **Ładowanie mapy z JSON** (`data/map_data_template.json`).
2. **Wyświetlanie kafli** (`scripts/hex_tile_template.gd`, `scripts/hex_utils_template.gd`).
3. **Kontener mapy + kamera** (`scripts/hex_grid_template.gd`, `scripts/camera_controller_template.gd`, `scenes/main_scene_template.tscn`).

## Jak użyć

1. **Utwórz nowy projekt Godot.**
2. Skopiuj katalogi `data/`, `scripts/` i `scenes/` z `wzor_do_godota/mapa_godot` do katalogu projektu (tak, aby ścieżki zaczynały się od `res://data`, `res://scripts` itd.).
3. W edytorze ustaw `scenes/main_scene_template.tscn` jako scenę startową albo załaduj ją i zapisz pod nową nazwą (`main.tscn`).
4. Uruchom scenę – zobaczysz siatkę heksagonalną z tłem, podświetleniem heksu pod kursorem oraz kamerę z zoomem i przeciąganiem.
5. Edytuj `data/map_data_template.json`, aby zmieniać rozmiar mapy, teren, spawn pointy i punkty kluczowe.

> Jeśli chcesz wpiąć system do istniejącego projektu, podmień tylko te części, które są potrzebne (np. sam `HexGridTemplate`), a resztę możesz zostawić przy aktualnym kodzie.

## Zawartość

| Ścieżka | Opis |
| --- | --- |
| `data/map_data_template.json` | Nieduża próbka danych mapy: metadane, heksy, spawn pointy i punkty kluczowe. |
| `scripts/hex_utils_template.gd` | Funkcje pomocnicze (konwersje axial↔pixel, wierzchołki heksu, sąsiedzi). |
| `scripts/hex_tile_template.gd` | Reprezentacja pojedynczego heksa (polygon, label, kolory terenów). |
| `scripts/hex_grid_template.gd` | Kontener mapy: wczytuje JSON, tworzy kafle, generuje tło i udostępnia dane kamerze. |
| `scripts/camera_controller_template.gd` | Sterowanie kamerą (zoom, drag, strzałki). |
| `scenes/main_scene_template.tscn` | Minimalna scena łącząca `HexGrid`, `Camera2D`, `CameraController` i prosty CanvasLayer z etykietą. |

## Najważniejsze kroki przy własnej scenie

1. **Dodaj `HexGrid`** jako `Node2D` i przypisz skrypt `hex_grid_template.gd`.
2. **Dodaj `Camera2D`** jako rodzeństwo `HexGrid` i ustaw `Current = On`.
3. **Dodaj `CameraController`** (`Node` ze skryptem `camera_controller_template.gd`) – oczekuje, że w tej samej scenie istnieją `Camera2D` i `HexGrid`.
4. **Dodaj warstwę UI** (np. `CanvasLayer`) dla komunikatów.
5. **Sprawdź ścieżkę `map_data_path`** we właściwościach `HexGrid`; wskaż swój JSON.

Po skopiowaniu tego pakietu do nowego projektu masz kompletną bazę do dalszego rozwijania (tokeny, tury, UI itp.).