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
	var viewport_size := get_viewport().get_visible_rect().size
	var default_zoom := 1.0
	if hex_grid and hex_grid.has_method("get_default_zoom"):
		default_zoom = hex_grid.get_default_zoom(viewport_size)
	camera.zoom = Vector2(default_zoom, default_zoom)
	if hex_grid and hex_grid.has_method("get_map_center"):
		camera.position = hex_grid.get_map_center()

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
		var mouse_delta: Vector2 = (event.position - drag_origin) / camera.zoom
		camera.position -= mouse_delta
		drag_origin = event.position

func _process(delta: float):
	if not camera:
		return
	var move := Vector2.ZERO
	var speed := 400.0 / camera.zoom.x
	if Input.is_action_pressed("ui_right"):
		move.x += speed
	if Input.is_action_pressed("ui_left"):
		move.x -= speed
	if Input.is_action_pressed("ui_down"):
		move.y += speed
	if Input.is_action_pressed("ui_up"):
		move.y -= speed
	if move.length() > 0:
		camera.position += move * delta

func _zoom(factor: float):
	var target := camera.zoom * factor
	target.x = clamp(target.x, zoom_min, zoom_max)
	target.y = clamp(target.y, zoom_min, zoom_max)
	camera.zoom = target
