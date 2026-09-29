class_name WorldFeedbackBurst
extends Node2D

@export var lifetime: float = 0.34

var tint: Color = Color.WHITE
var particle_count: int = 8
var speed: float = 48.0

var _age: float = 0.0
var _directions: Array[Vector2] = []
var _sizes: Array[float] = []

func _ready() -> void:
	_build_particles()
	queue_redraw()

func configure(color: Color, count: int = 8, burst_speed: float = 48.0) -> void:
	tint = color
	particle_count = clampi(count, 1, 24)
	speed = maxf(burst_speed, 1.0)
	_age = 0.0
	_build_particles()
	queue_redraw()

func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	queue_redraw()

func _build_particles() -> void:
	_directions.clear()
	_sizes.clear()

	var count := maxi(particle_count, 1)
	var offset := fmod(global_position.x * 0.013 + global_position.y * 0.021, TAU)

	for index in range(count):
		var angle := offset + TAU * float(index) / float(count)
		var vertical_bias := -0.30 if index % 2 == 0 else 0.05
		var direction := Vector2.from_angle(angle)
		direction.y += vertical_bias
		_directions.append(direction.normalized())
		_sizes.append(0.75 + float(index % 4) * 0.16)

func _draw() -> void:
	if _directions.is_empty():
		return

	var progress := clampf(_age / maxf(lifetime, 0.01), 0.0, 1.0)
	var alpha := 1.0 - progress
	var gravity := Vector2(0, 44.0 * _age * _age)

	for index in range(_directions.size()):
		var travel := _directions[index] * speed * _age
		var position := travel + gravity
		var size := _sizes[index] * lerpf(2.8, 1.2, progress)
		var color := Color(tint.r, tint.g, tint.b, tint.a * alpha)
		draw_circle(position, size, color)
