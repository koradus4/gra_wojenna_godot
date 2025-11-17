## Przeciąganie oraz zoom kamery dla sceny z heksami
extends Node

@onready var camera: Camera2D = get_parent().get_node("Camera2D")
@onready var hex_grid = get_parent().get_node("HexGrid")

var zoom_speed := 0.1
var zoom_min := 0.3
var zoom_max := 2.5
var is_dragging := false
var drag_origin := Vector2.ZERO

func _ready():
	if not camera:
		push_error("CameraController wymaga Camera2D jako rodzeństwa")
		return
	# Kamera stała w centrum ekranu
	camera.position = Vector2(960, 540)
	var default_zoom := 1.0
	if hex_grid and hex_grid.has_method("get_default_zoom"):
		var viewport_size := get_viewport().get_visible_rect().size
		default_zoom = hex_grid.get_default_zoom(viewport_size)
	# Zoom = scale na HexGrid
	hex_grid.scale = Vector2(default_zoom, default_zoom)

func _input(event):
	if not camera:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_PLUS, KEY_EQUAL, KEY_KP_ADD]:
			_zoom(1.0 - zoom_speed)
		elif event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
			_zoom(1.0 + zoom_speed)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.0 - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0 + zoom_speed)
		elif event.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			is_dragging = event.pressed
			drag_origin = event.position
	if event is InputEventMouseMotion and is_dragging:
		var mouse_delta: Vector2 = (event.position - drag_origin)
		# Przesuń siatkę heksów, nie kamerę
		hex_grid.position += mouse_delta
		_clamp_map_position()
		hex_grid.update_visible_tiles()  # Culling po przesunięciu
		drag_origin = event.position

func _process(delta: float):
	var move := Vector2.ZERO
	var speed := 400.0
	if Input.is_action_pressed("ui_right"):
		move.x -= speed  # Odwrócone: prawo = przesuń mapę w lewo
	if Input.is_action_pressed("ui_left"):
		move.x += speed
	if Input.is_action_pressed("ui_down"):
		move.y -= speed
	if Input.is_action_pressed("ui_up"):
		move.y += speed
	if move.length() > 0:
		# Przesuń siatkę heksów, nie kamerę
		hex_grid.position += move * delta
		_clamp_map_position()
		hex_grid.update_visible_tiles()  # Culling po przesunięciu

func _clamp_map_position():
	if not hex_grid:
		return
	
	# Rozmiar kontenera: 1525×858, wycentrowany na ekranie
	var container_size := Vector2(1525, 858)
	var container_pos := Vector2((1920 - 1525) / 2.0, (1080 - 858) / 2.0)
	
	# Rozmiar mapy - muszę znaleźć skrajne punkty heksów
	var hex_height: float = hex_grid.hex_size * sqrt(3)
	var column_spacing: float = 1.5 * hex_grid.hex_size
	
	# Szerokość: ostatnia kolumna + pełna szerokość hexa (2*hex_size)
	var last_col_x: float = (hex_grid.cols - 1) * column_spacing
	var map_width_base: float = last_col_x + 2.0 * hex_grid.hex_size
	
	# Wysokość: najniższy hex (ostatni rząd + offset dla nieparzystych kolumn)
	# Sprawdzam czy ostatnia kolumna jest nieparzysta
	var last_col_offset: float = ((hex_grid.cols - 1) % 2) * (hex_height / 2.0)
	var last_row_y: float = (hex_grid.rows - 1) * hex_height + last_col_offset
	var map_height_base: float = last_row_y + hex_height
	
	# Pozycja heksów = HexGrid.position + offset - MINUS hex_size bo hexs wystają od swojego center!
	# Pierwszy hex (0,0) ma center w (0,0), ale lewy brzeg w (-hex_size, -hex_size)
	var map_left: float = hex_grid.position.x + (hex_grid.offset.x - hex_grid.hex_size) * hex_grid.scale.x
	var map_right: float = map_left + (map_width_base + hex_grid.hex_size) * hex_grid.scale.x
	var map_top: float = hex_grid.position.y + (hex_grid.offset.y - hex_grid.hex_size) * hex_grid.scale.y
	var map_bottom: float = map_top + (map_height_base + hex_grid.hex_size) * hex_grid.scale.y
	
	var container_left: float = container_pos.x
	var container_right: float = container_pos.x + container_size.x
	var container_top: float = container_pos.y
	var container_bottom: float = container_pos.y + container_size.y
	
	# Bufor: 1 hex z każdej strony dla płynnego przesuwania
	var hex_width_buffer: float = 2.0 * hex_grid.hex_size * hex_grid.scale.x
	var hex_height_buffer: float = 2.0 * hex_grid.hex_size * hex_grid.scale.y
	
	# Clamp: mapa nie może wyjść poza kontener (z buforem 1 hexa)
	# Prawy brzeg mapy musi być >= prawy brzeg kontenera - bufor
	if map_right < container_right + hex_width_buffer:
		hex_grid.position.x = (container_right + hex_width_buffer - (map_width_base + hex_grid.hex_size) * hex_grid.scale.x) - (hex_grid.offset.x - hex_grid.hex_size) * hex_grid.scale.x
	# Lewy brzeg mapy musi być <= lewy brzeg kontenera + bufor
	if map_left > container_left - hex_width_buffer:
		hex_grid.position.x = (container_left - hex_width_buffer) - (hex_grid.offset.x - hex_grid.hex_size) * hex_grid.scale.x
	# Dolny brzeg mapy musi być >= dolny brzeg kontenera - bufor
	if map_bottom < container_bottom + hex_height_buffer:
		hex_grid.position.y = (container_bottom + hex_height_buffer - (map_height_base + hex_grid.hex_size) * hex_grid.scale.y) - (hex_grid.offset.y - hex_grid.hex_size) * hex_grid.scale.y
	# Górny brzeg mapy musi być <= górny brzeg kontenera + bufor
	if map_top > container_top - hex_height_buffer:
		hex_grid.position.y = (container_top - hex_height_buffer) - (hex_grid.offset.y - hex_grid.hex_size) * hex_grid.scale.y

func _zoom(factor: float):
	var target: Vector2 = hex_grid.scale * factor
	target.x = clamp(target.x, zoom_min, zoom_max)
	target.y = clamp(target.y, zoom_min, zoom_max)
	hex_grid.scale = target
	hex_grid.update_visible_tiles()  # Culling po zoomie
