## Prosty zestaw narzędzi dla współrzędnych heksagonalnych
class_name HexUtilsTemplate

const SQRT3 := 1.7320508075688772

static func get_hex_vertices(center: Vector2, hex_size: float) -> PackedVector2Array:
	var vertices := PackedVector2Array()
	for i in range(6):
		var angle := (PI / 180.0) * (60 * i - 30)
		var x := center.x + hex_size * cos(angle)
		var y := center.y + hex_size * sin(angle)
		vertices.append(Vector2(x, y))
	return vertices

static func axial_to_pixel(q: int, r: int, hex_size: float) -> Vector2:
	var col := q
	var row := r + int(q / 2)
	var horizontal_spacing := 1.5 * hex_size
	var hex_height := SQRT3 * hex_size
	var x := hex_size + col * horizontal_spacing
	var y := (hex_size * SQRT3 / 2.0) + row * hex_height
	if col % 2 == 1:
		y += hex_height / 2.0
	return Vector2(x, y)

static func pixel_to_axial(pos: Vector2, hex_size: float) -> Vector2i:
	var q := (2.0 / 3.0 * pos.x) / hex_size
	var r := (-1.0 / 3.0 * pos.x + SQRT3 / 3.0 * pos.y) / hex_size
	return _cube_round(q, r, -q - r)

static func get_neighbors(hex: Vector2i) -> Array[Vector2i]:
	var dirs := [
		Vector2i(+1, 0), Vector2i(+1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, +1), Vector2i(0, +1)
	]
	var neighbors: Array[Vector2i] = []
	for dir in dirs:
		neighbors.append(Vector2i(hex.x + dir.x, hex.y + dir.y))
	return neighbors

static func hex_distance(a: Vector2i, b: Vector2i) -> int:
	return int((abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2)

static func _cube_round(x: float, y: float, z: float) -> Vector2i:
	var rx := round(x)
	var ry := round(y)
	var rz := round(z)
	var x_diff := abs(rx - x)
	var y_diff := abs(ry - y)
	var z_diff := abs(rz - z)
	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector2i(int(rx), int(ry))
