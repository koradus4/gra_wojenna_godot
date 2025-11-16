## Kontener mapy hex bazujący na JSON
extends Node2D
class_name HexGridTemplate

const HexTileTemplate = preload("res://scripts/hex_tile_template.gd")
const HexUtilsTemplate = preload("res://scripts/hex_utils_template.gd")

@export var map_data_path := "res://data/map_data_template.json"

var hex_size := 32.0
var cols := 0
var rows := 0
var background_meta := {}
var map_size := Vector2.ZERO
var tiles: Dictionary = {}
var background_sprite: Sprite2D
var offset := Vector2.ZERO

func _ready():
	load_map()
	load_background()
	print("HexGridTemplate gotowe | heksy:", tiles.size())

func load_map():
	if not FileAccess.file_exists(map_data_path):
		push_error("Brak pliku mapy: %s" % map_data_path)
		return
	var file := FileAccess.open(map_data_path, FileAccess.READ)
	var json_text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_text) != OK:
		push_error("Błąd JSON: %s" % json.get_error_message())
		return
	var data := json.data
	var meta := data.get("meta", {})
	hex_size = meta.get("hex_size", hex_size)
	cols = meta.get("cols", cols)
	rows = meta.get("rows", rows)
	background_meta = meta.get("background", {})
	offset = Vector2.ZERO
	for key in data.get("terrain", {}).keys():
		var coords := key.split(",")
		if coords.size() != 2:
			continue
		var q := int(coords[0])
		var r := int(coords[1])
		var tile_data := data["terrain"][key]
		create_tile(q, r, tile_data)
	_apply_spawn_points(data.get("spawn_points", {}))
	_apply_key_points(data.get("key_points", {}))
	if map_size == Vector2.ZERO:
		map_size = _estimate_map_size()

func create_tile(q: int, r: int, data: Dictionary):
	var tile: HexTileTemplate = HexTileTemplate.new(q, r)
	tile.hex_size = hex_size
	tile.load_from_data(data)
	tile.position = HexUtilsTemplate.axial_to_pixel(q, r, hex_size) + offset
	add_child(tile)
	tiles["%d,%d" % [q, r]] = tile

func load_background():
	var width := int(background_meta.get("width", cols * hex_size * 1.5))
	var height := int(background_meta.get("height", rows * hex_size * 1.5))
	var img := Image.create(width, height, false, Image.FORMAT_RGB8)
	var color_data := background_meta.get("color", [48, 64, 40])
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
