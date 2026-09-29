class_name GridTargeting
extends RefCounted

static func get_tool_cells(origin: Vector2i, facing: Vector2i, stage: int) -> Array[Vector2i]:
	var direction := _sanitize_facing(facing)
	var perpendicular := Vector2i(-direction.y, direction.x)
	var cells: Array[Vector2i] = []

	match clampi(stage, 0, 5):
		0:
			cells.append(origin + direction)
		1:
			for distance in range(1, 4):
				cells.append(origin + direction * distance)
		2:
			for distance in range(1, 6):
				cells.append(origin + direction * distance)
		3:
			for depth in range(1, 4):
				for lateral in range(-1, 2):
					cells.append(origin + direction * depth + perpendicular * lateral)
		4:
			for depth in range(1, 6):
				for lateral in range(-1, 2):
					cells.append(origin + direction * depth + perpendicular * lateral)
		5:
			for depth in range(1, 6):
				for lateral in range(-2, 3):
					cells.append(origin + direction * depth + perpendicular * lateral)

	return cells

static func _sanitize_facing(facing: Vector2i) -> Vector2i:
	if facing == Vector2i.ZERO:
		return Vector2i.DOWN

	if abs(facing.x) > abs(facing.y):
		return Vector2i(1 if facing.x > 0 else -1, 0)

	return Vector2i(0, 1 if facing.y > 0 else -1)
