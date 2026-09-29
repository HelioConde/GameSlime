class_name SlimeHabitat
extends Node2D

enum HabitatBiome {
	MEADOW,
	GROVE,
	WETLAND,
	FROST,
}

signal slime_registered(slime: SlimeCreature)
signal slime_unregistered(slime: SlimeCreature)

@export var habitat_size: Vector2 = Vector2(300, 190)
@export_range(1, 20, 1) var capacity: int = 6
@export var habitat_name: String = "Habitat Verde"
@export var biome_type: HabitatBiome = HabitatBiome.MEADOW

var registered_slimes: Array[SlimeCreature] = []

func _ready() -> void:
	add_to_group("slime_habitat")
	call_deferred("_register_nearby_slimes")
	queue_redraw()

func contains_position(world_position: Vector2) -> bool:
	var local := to_local(world_position)
	var half := habitat_size * 0.5
	return (
		local.x >= -half.x
		and local.x <= half.x
		and local.y >= -half.y
		and local.y <= half.y
	)

func can_register() -> bool:
	return registered_slimes.size() < capacity

func register_slime(slime: SlimeCreature) -> bool:
	if slime == null:
		return false

	if slime in registered_slimes:
		return true

	if not can_register():
		return false

	registered_slimes.append(slime)
	slime.habitat = self
	slime_registered.emit(slime)
	return true

func unregister_slime(slime: SlimeCreature) -> void:
	if slime == null or slime not in registered_slimes:
		return

	registered_slimes.erase(slime)
	if slime.habitat == self:
		slime.habitat = null
	slime_unregistered.emit(slime)

func get_random_point(rng: RandomNumberGenerator, margin: float = 22.0) -> Vector2:
	var half := habitat_size * 0.5 - Vector2.ONE * margin
	var local_point := Vector2(
		rng.randf_range(-half.x, half.x),
		rng.randf_range(-half.y, half.y)
	)
	return to_global(local_point)

func clamp_inside(world_position: Vector2, margin: float = 18.0) -> Vector2:
	var local := to_local(world_position)
	var half := habitat_size * 0.5 - Vector2.ONE * margin
	local.x = clampf(local.x, -half.x, half.x)
	local.y = clampf(local.y, -half.y, half.y)
	return to_global(local)

func get_status_text() -> String:
	return "%s · %s · %d/%d slimes" % [
		habitat_name,
		get_biome_name(),
		registered_slimes.size(),
		capacity,
	]

func get_biome_name() -> String:
	match biome_type:
		HabitatBiome.MEADOW:
			return "Prado"
		HabitatBiome.GROVE:
			return "Bosque"
		HabitatBiome.WETLAND:
			return "Umido"
		HabitatBiome.FROST:
			return "Gelado"
		_:
			return "Habitat"

func _register_nearby_slimes() -> void:
	for node in get_tree().get_nodes_in_group("slime_creature"):
		var slime := node as SlimeCreature
		if slime == null or slime.habitat != null:
			continue
		if contains_position(slime.global_position):
			register_slime(slime)

func _draw() -> void:
	var half := habitat_size * 0.5
	var rect := Rect2(-half, habitat_size)

	draw_rect(rect, Color(0.28, 0.62, 0.30, 0.06), true)
	draw_rect(rect, Color(0.52, 0.36, 0.18, 0.95), false, 4.0)

	# Visual fence posts.
	for x in range(int(-half.x), int(half.x) + 1, 32):
		draw_rect(Rect2(Vector2(x - 2, -half.y - 4), Vector2(4, 12)), Color(0.66, 0.43, 0.21), true)
		draw_rect(Rect2(Vector2(x - 2, half.y - 8), Vector2(4, 12)), Color(0.66, 0.43, 0.21), true)

	for y in range(int(-half.y), int(half.y) + 1, 32):
		draw_rect(Rect2(Vector2(-half.x - 4, y - 2), Vector2(12, 4)), Color(0.66, 0.43, 0.21), true)
		draw_rect(Rect2(Vector2(half.x - 8, y - 2), Vector2(12, 4)), Color(0.66, 0.43, 0.21), true)
