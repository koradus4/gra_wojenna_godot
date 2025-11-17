## Minimalny heks wyświetlany na siatce
extends Node2D
class_name HexTileTemplate

const HexUtilsTemplate = preload("res://scripts/hex_utils_template.gd")

var q := 0
var r := 0
var hex_size := 32.0
var terrain_key := "teren_płaski"
var move_mod := 0
var defense_mod := 0
var tile_type := ""
var value := 0
var spawn_nation := ""

var polygon: Polygon2D
var border: Line2D
var label: Label
var highlight_polygon: Polygon2D

func _init(hex_q: int = 0, hex_r: int = 0):
	q = hex_q
	r = hex_r

func _ready():
	polygon = Polygon2D.new()
	add_child(polygon)

	highlight_polygon = Polygon2D.new()
	highlight_polygon.color = Color(0.0, 1.0, 0.0, 0.25)
	highlight_polygon.visible = false
	add_child(highlight_polygon)

	border = Line2D.new()
	border.width = 2.0
	border.default_color = Color(0.1, 0.1, 0.1)
	add_child(border)

	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.position = Vector2(-hex_size * 0.6, -hex_size * 0.3)
	add_child(label)

	update_visual()

func load_from_data(data: Dictionary):
	terrain_key = data.get("terrain_key", terrain_key)
	move_mod = data.get("move_mod", move_mod)
	defense_mod = data.get("defense_mod", defense_mod)
	tile_type = data.get("type", tile_type)
	value = data.get("value", value)
	spawn_nation = data.get("spawn_nation", spawn_nation)
	update_visual()

func update_visual():
	if not polygon:
		return

	var vertices := HexUtilsTemplate.get_hex_vertices(Vector2.ZERO, hex_size)
	polygon.polygon = vertices
	if highlight_polygon:
		highlight_polygon.polygon = vertices

	polygon.color = _get_terrain_color()

	if border:
		border.clear_points()
		for v in vertices:
			border.add_point(v)
		border.add_point(vertices[0])

	if label:
		if spawn_nation:
			label.text = "★ " + spawn_nation
			label.modulate = Color(1, 1, 0)
		elif tile_type and value > 0:
			label.text = str(value)
			label.modulate = Color(1, 1, 1)
		else:
			label.text = ""

func set_highlighted(enabled: bool):
	if highlight_polygon:
		highlight_polygon.visible = enabled

func _get_terrain_color() -> Color:
	# Najpierw sprawdź type (z JSON)
	if tile_type:
		match tile_type:
			"plains":
				return Color(0.57, 0.66, 0.42, 0.5)
			"forest":
				return Color(0.25, 0.45, 0.25, 0.65)
			"mountains":
				return Color(0.45, 0.36, 0.28, 0.6)
			"water":
				return Color(0.2, 0.4, 0.75, 0.6)
			"swamp":
				return Color(0.38, 0.45, 0.35, 0.6)
			"city":
				return Color(0.53, 0.48, 0.46, 0.6)
	
	# Fallback na terrain_key (legacy)
	match terrain_key:
		"teren_płaski":
			return Color(0.57, 0.66, 0.42, 0.5)
		"las":
			return Color(0.25, 0.45, 0.25, 0.65)
		"góry":
			return Color(0.45, 0.36, 0.28, 0.6)
		"woda", "mała rzeka":
			return Color(0.2, 0.4, 0.75, 0.6)
		"bagno":
			return Color(0.38, 0.45, 0.35, 0.6)
		"miasto":
			return Color(0.53, 0.48, 0.46, 0.6)
		_:
			return Color(0.6, 0.6, 0.6, 0.3)
