## Prosty zestaw narzędzi dla współrzędnych heksagonalnych
class_name HexUtilsTemplate

const SQRT3 := 1.7320508075688772

static func get_hex_vertices(center: Vector2, hex_size: float) -> PackedVector2Array:
	var vertices := PackedVector2Array()
	for i in range(6):
		var angle := (PI / 180.0) * (60 * i)
		var x := center.x + hex_size * cos(angle)
		var y := center.y + hex_size * sin(angle)
		vertices.append(Vector2(x, y))
	return vertices

static func axial_to_pixel(q: int, r: int, hex_size: float) -> Vector2:
	# Flat-top axial coordinates (prostokątna mapa)
	# Każdy hex: width = 2*size, height = size*√3
	var hex_height := hex_size * SQRT3
	var column_spacing := 1.5 * hex_size
	
	# Axial: każda kolumna to 1.5*size w prawo, każdy wiersz to √3*size w dół
	var x := q * column_spacing
	var y := r * hex_height + (q % 2) * (hex_height / 2.0)
	
	return Vector2(x, y)

static func pixel_to_axial(pos: Vector2, hex_size: float) -> Vector2i:
	var q := (SQRT3 / 3.0 * pos.x - 1.0 / 3.0 * pos.y) / hex_size
	var r := (2.0 / 3.0 * pos.y) / hex_size
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
	var rx: float = round(x)
	var ry: float = round(y)
	var rz: float = round(z)
	var x_diff: float = abs(rx - x)
	var y_diff: float = abs(ry - y)
	var z_diff: float = abs(rz - z)
	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector2i(int(rx), int(ry))
