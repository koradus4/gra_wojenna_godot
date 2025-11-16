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
var background_sprite: Sprite2D
var offset := Vector2.ZERO

func _ready():
	create_background()
	load_map()
	print("HexGridTemplate gotowe | heksy:", tiles.size())

func load_map():
	# TEST: kolumna heksów w dół (q=0, r=0..4)
	hex_size = 32.0
	cols = 1
	rows = 5
	offset = Vector2(41, 38)
	
	var test_data := {
		"terrain_key": "teren_płaski",
		"move_mod": 0,
		"defense_mod": 0
	}
	
	# Wypełnij całą szerokość kontenera kolumnami heksów
	# column_spacing = 1.5 * hex_size = 48px
	# Ramka 8px: szerokość wewnętrzna 1920 - 16 = 1904px
	# 39 kolumn (q=0-38) optymalnie wypełnia przestrzeń
	# Kolumny parzyste (0,2,4...): 19 heksów
	# Kolumny nieparzyste (1,3,5...): 18 heksów
	for q in range(39):
		var row_count := 19 if q % 2 == 0 else 18
		for r in range(row_count):
			create_tile(q, r, test_data)
	
	map_size = Vector2(800, 600)

func create_tile(q: int, r: int, data: Dictionary):
	var tile: HexTileTemplate = HexTileTemplate.new(q, r)
	tile.hex_size = hex_size
	tile.load_from_data(data)
	tile.position = HexUtilsTemplate.axial_to_pixel(q, r, hex_size) + offset
	add_child(tile)
	tiles["%d,%d" % [q, r]] = tile

func create_background():
	# Tło 1906x1073 w kolorze ciemnozielonym z brązową ramką
	var width := 1906
	var height := 1073
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
	
	if not background_sprite:
		background_sprite = Sprite2D.new()
		background_sprite.z_index = -1000
		background_sprite.centered = false
		add_child(background_sprite)
	
	background_sprite.texture = texture
	background_sprite.position = Vector2.ZERO
	map_size = Vector2(width, height)

func load_background():
	var width := int(background_meta.get("width", cols * hex_size * 1.5))
	var height := int(background_meta.get("height", rows * hex_size * 1.5))
	var img := Image.create(width, height, false, Image.FORMAT_RGB8)
	var color_data: Array = background_meta.get("color", [48, 64, 40])
	var color := Color(color_data[0] / 255.0, color_data[1] / 255.0, color_data[2] / 255.0)
	img.fill(color)
	var texture := ImageTexture.create_from_image(img)
	if not background_sprite:
		background_sprite = Sprite2D.new()
		background_sprite.z_index = -1000
		background_sprite.centered = false
		add_child(background_sprite)
	background_sprite.texture = texture
	background_sprite.position = Vector2.ZERO
	map_size = Vector2(width, height)

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
	return tiles.get("%d,%d" % [axial.x, axial.y], null)

func highlight_tile_at_mouse():
	for tile in tiles.values():
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
			var tile: HexTileTemplate = tiles.get(key, null)
			if tile:
				tile.spawn_nation = nation
				tile.update_visual()

func _apply_key_points(kp_data: Dictionary):
	for key in kp_data.keys():
		var tile: HexTileTemplate = tiles.get(key, null)
		if tile:
			tile.tile_type = kp_data[key].get("type", "")
			tile.value = kp_data[key].get("value", 0)
			tile.update_visual()

func _estimate_map_size() -> Vector2:
	var width := float(background_meta.get("width", cols * hex_size * 1.5))
	var height := float(background_meta.get("height", rows * hex_size * sqrt(3.0)))
	return Vector2(width, height)
