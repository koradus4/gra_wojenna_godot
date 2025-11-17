## Kontener mapy hex bazujący na JSON
extends Node2D
class_name HexGridTemplate

const HexTileTemplate = preload("res://scripts/hex_tile_template.gd")
const HexUtilsTemplate = preload("res://scripts/hex_utils_template.gd")

@export var map_data_path := "res://data/map_data.json"

var hex_size := 32.0
var cols := 0
var rows := 0
var background_meta := {}
var map_size := Vector2.ZERO
var tiles: Dictionary = {}
var terrain_cache: Dictionary = {}  # Wszystkie dane z JSON
var visible_tiles: Dictionary = {}  # Tylko renderowane tile
var background_sprite: Sprite2D
var offset := Vector2.ZERO
var last_camera_pos := Vector2.ZERO
var camera_margin := 128.0

func _ready():
	# Pobierz istniejący Background node
	background_sprite = get_parent().get_node("Background")
	create_background()
	load_map()
	print("HexGridTemplate gotowe | heksy:", tiles.size())

func load_map():
	var file := FileAccess.open(map_data_path, FileAccess.READ)
	if not file:
		push_error("Nie można otworzyć mapy: " + map_data_path)
		return
	
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("Błąd parsowania JSON: " + json.get_error_message())
		return
	
	var data := json.data as Dictionary
	if not data:
		push_error("Błąd formatu JSON")
		return
	
	var meta := data.get("meta", {}) as Dictionary
	var terrain := data.get("terrain", {}) as Dictionary
	
	hex_size = float(meta.get("hex_size", 32))
	cols = int(meta.get("cols", 0))
	rows = int(meta.get("rows", 0))
	
	# Centrowanie: oblicz RZECZYWISTY rozmiar mapy
	var hex_height := hex_size * sqrt(3)
	var column_spacing := 1.5 * hex_size
	
	# Szerokość: ostatnia kolumna + pełna szerokość hexa
	var last_col_x := (cols - 1) * column_spacing
	var map_width := last_col_x + 2.0 * hex_size
	
	# Wysokość: najniższy hex (ostatni rząd + offset dla nieparzystych kolumn)
	var last_col_offset := ((cols - 1) % 2) * (hex_height / 2.0)
	var last_row_y := (rows - 1) * hex_height + last_col_offset
	var map_height := last_row_y + hex_height
	
	# Kontener: 1525×858, wycentrowany na ekranie 1920×1080
	var screen_center := Vector2(1920 / 2.0, 1080 / 2.0)
	var container_size := Vector2(1525, 858)
	var container_pos := screen_center - container_size / 2.0
	
	var container_center := container_pos + container_size / 2.0
	var map_center := Vector2(map_width / 2.0, map_height / 2.0)
	
	# Offset = pozycja kontenera + różnica między centrami
	offset = container_pos + (container_size / 2.0 - map_center)
	
	# Wczytaj dane heksów do cache (nie renderuj jeszcze)
	for key in terrain.keys():
		var coords: PackedStringArray = key.split(",")
		if coords.size() != 2:
			continue
		var q := int(coords[0])
		var r := int(coords[1])
		terrain_cache[key] = terrain[key]
	
	print("Załadowano mapę ", cols, "×", rows, " | heksy w cache:", terrain_cache.size())
	print("Offset centrujący:", offset)
	
	# Pierwszy rendering - pokaż tylko widoczne heksy
	update_visible_tiles()

func create_tile(q: int, r: int, data: Dictionary):
	var key := "%d,%d" % [q, r]
	# Jeśli hex już istnieje, nie twórz ponownie
	if visible_tiles.has(key):
		return
	
	var tile: HexTileTemplate = HexTileTemplate.new(q, r)
	tile.hex_size = hex_size
	tile.load_from_data(data)
	tile.position = HexUtilsTemplate.axial_to_pixel(q, r, hex_size) + offset
	add_child(tile)
	visible_tiles[key] = tile

func create_background():
	# Kontener zmniejszony o 20%: 1906*0.8=1525, 1073*0.8=858
	var width := 1525
	var height := 858
	var img := Image.create(width, height, false, Image.FORMAT_RGB8)
	var color := Color(0.19, 0.25, 0.16)
	img.fill(color)
	
	# Ramka brązowa 8px
	var border_color := Color(0.4, 0.25, 0.1)
	var border_width := 8
	
	for y in range(border_width):
		for x in range(width):
			img.set_pixel(x, y, border_color)
			img.set_pixel(x, height - 1 - y, border_color)
	
	for x in range(border_width):
		for y in range(height):
			img.set_pixel(x, y, border_color)
			img.set_pixel(width - 1 - x, y, border_color)
	
	var texture := ImageTexture.create_from_image(img)
	
	# Ustaw texture na istniejącym Background node
	if background_sprite:
		background_sprite.texture = texture
		background_sprite.centered = false
		# Wycentruj kontener na ekranie 1920×1080
		var screen_center := Vector2(1920 / 2.0, 1080 / 2.0)
		var container_center := Vector2(width / 2.0, height / 2.0)
		background_sprite.position = screen_center - container_center
	
	map_size = Vector2(width, height)

func load_background():
	# Usunięta funkcja - background tworzony w create_background()
	pass

func get_map_center() -> Vector2:
	return map_size * 0.5

func get_map_size() -> Vector2:
	return map_size

func get_default_zoom(viewport_size: Vector2) -> float:
	if viewport_size == Vector2.ZERO or map_size == Vector2.ZERO:
		return 1.0
	var zx := viewport_size.x / map_size.x
	var zy := viewport_size.y / map_size.y
	return min(zx, zy) * 0.9

func get_tile_at_mouse() -> HexTileTemplate:
	var mouse_pos := get_global_mouse_position()
	var axial := HexUtilsTemplate.pixel_to_axial(mouse_pos - offset, hex_size)
	return visible_tiles.get("%d,%d" % [axial.x, axial.y], null)

func highlight_tile_at_mouse():
	for tile in visible_tiles.values():
		tile.set_highlighted(false)
	var hovered := get_tile_at_mouse()
	if hovered:
		hovered.set_highlighted(true)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		highlight_tile_at_mouse()

func _apply_spawn_points(spawn_data: Dictionary):
	for nation in spawn_data.keys():
		for key in spawn_data[nation]:
			var tile: HexTileTemplate = visible_tiles.get(key, null)
			if tile:
				tile.spawn_nation = nation
				tile.update_visual()

func _apply_key_points(kp_data: Dictionary):
	for key in kp_data.keys():
		var tile: HexTileTemplate = visible_tiles.get(key, null)
		if tile:
			tile.tile_type = kp_data[key].get("type", "")
			tile.value = kp_data[key].get("value", 0)
			tile.update_visual()

func _estimate_map_size() -> Vector2:
	var width := float(background_meta.get("width", cols * hex_size * 1.5))
	var height := float(background_meta.get("height", rows * hex_size * sqrt(3.0)))
	return Vector2(width, height)

func update_visible_tiles():
	# Kontener: 1525×858, wycentrowany na ekranie
	var container_size := Vector2(1525, 858)
	var container_pos := Vector2((1920 - 1525) / 2.0, (1080 - 858) / 2.0)
	
	# Viewport w przestrzeni mapy (uwzględniając scale i position)
	var inv_scale := Vector2(1.0 / scale.x, 1.0 / scale.y)
	var viewport_min := (container_pos - position) * inv_scale - offset
	var viewport_max := (container_pos + container_size - position) * inv_scale - offset
	
	# Margines: 2 heksy z każdej strony
	var margin := 2.0 * hex_size * 2.0
	viewport_min -= Vector2(margin, margin)
	viewport_max += Vector2(margin, margin)
	
	# Sprawdź które heksy są w viewport
	var keys_to_show: Array[String] = []
	for key in terrain_cache.keys():
		var coords: PackedStringArray = key.split(",")
		if coords.size() != 2:
			continue
		var q := int(coords[0])
		var r := int(coords[1])
		var hex_pos := HexUtilsTemplate.axial_to_pixel(q, r, hex_size)
		
		# Czy hex jest w viewport?
		if hex_pos.x >= viewport_min.x and hex_pos.x <= viewport_max.x and \
		   hex_pos.y >= viewport_min.y and hex_pos.y <= viewport_max.y:
			keys_to_show.append(key)
	
	# Usuń heksy poza viewport
	var keys_to_remove: Array[String] = []
	for key in visible_tiles.keys():
		if not key in keys_to_show:
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		var tile = visible_tiles[key]
		remove_child(tile)
		tile.queue_free()
		visible_tiles.erase(key)
	
	# Dodaj nowe heksy w viewport
	for key in keys_to_show:
		if not visible_tiles.has(key):
			var coords: PackedStringArray = key.split(",")
			var q := int(coords[0])
			var r := int(coords[1])
			create_tile(q, r, terrain_cache[key])
