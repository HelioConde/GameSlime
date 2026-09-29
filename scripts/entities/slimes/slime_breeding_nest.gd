class_name SlimeBreedingNest
extends Node2D

signal child_born(child: SlimeCreature, parent_a: SlimeCreature, parent_b: SlimeCreature)

const SLIME_SCENE := preload("res://scenes/slimes/slime_creature.tscn")

@export var interaction_radius: float = 68.0
@export var breeding_radius: float = 185.0

func _ready() -> void:
	add_to_group("slime_breeding_nest")
	queue_redraw()

func can_interact(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius

func interact(player: PlayerController) -> String:
	if player == null or not can_interact(player.global_position):
		return ""

	var habitat := _find_habitat()
	if habitat != null and not habitat.can_register():
		return "%s esta cheio (%d/%d)." % [
			habitat.habitat_name,
			habitat.registered_slimes.size(),
			habitat.capacity,
		]

	var nearby := _get_nearby_slimes()
	var candidates := _get_nearby_eligible_slimes()

	if nearby.size() < 2:
		return "Ninho: aproxime 2 slimes do habitat."

	if candidates.size() < 2:
		return _build_readiness_message(nearby)

	var pair := _find_pair(candidates)
	if pair.is_empty():
		return "Ninho: os slimes elegiveis precisam ser de sexos opostos."

	var parent_a := pair[0] as SlimeCreature
	var parent_b := pair[1] as SlimeCreature
	var child := _create_child(parent_a, parent_b)

	if child == null:
		return "Nao foi possivel gerar o filhote."

	parent_a.mark_bred()
	parent_b.mark_bred()
	child_born.emit(child, parent_a, parent_b)

	return "%s e %s tiveram %s! Genes: %s" % [
		parent_a.display_name,
		parent_b.display_name,
		child.display_name,
		child.get_genetics_text(),
	]

func _find_habitat() -> SlimeHabitat:
	for node in get_tree().get_nodes_in_group("slime_habitat"):
		var habitat := node as SlimeHabitat
		if habitat != null and habitat.contains_position(global_position):
			return habitat
	return null

func _get_nearby_slimes() -> Array[SlimeCreature]:
	var result: Array[SlimeCreature] = []

	for node in get_tree().get_nodes_in_group("slime_creature"):
		var slime := node as SlimeCreature
		if slime == null:
			continue
		if slime.global_position.distance_to(global_position) <= breeding_radius:
			result.append(slime)

	return result

func _build_readiness_message(slimes: Array[SlimeCreature]) -> String:
	var details: Array[String] = []

	for slime in slimes:
		var blockers := slime.get_breeding_blockers()
		if blockers.is_empty():
			details.append("%s: pronto" % slime.display_name)
		else:
			details.append("%s: %s" % [
				slime.display_name,
				", ".join(blockers),
			])

	return "Ninho · " + " | ".join(details)

func _get_nearby_eligible_slimes() -> Array[SlimeCreature]:
	var result: Array[SlimeCreature] = []

	for node in get_tree().get_nodes_in_group("slime_creature"):
		var slime := node as SlimeCreature
		if slime == null:
			continue
		if slime.global_position.distance_to(global_position) > breeding_radius:
			continue
		if not slime.can_breed():
			continue

		result.append(slime)

	return result

func _find_pair(candidates: Array[SlimeCreature]) -> Array[SlimeCreature]:
	for a_index in range(candidates.size()):
		for b_index in range(a_index + 1, candidates.size()):
			var a := candidates[a_index]
			var b := candidates[b_index]

			if a.biological_sex != b.biological_sex:
				return [a, b]

	return []

func _create_child(parent_a: SlimeCreature, parent_b: SlimeCreature) -> SlimeCreature:
	var child := SLIME_SCENE.instantiate() as SlimeCreature
	if child == null or get_parent() == null:
		return null

	var child_index := get_tree().get_nodes_in_group("slime_creature").size() + 1
	child.name = "SlimeChild%d" % child_index
	child.display_name = "Geleca %d" % child_index
	child.position = position + Vector2(0, 42)
	get_parent().add_child(child)

	var seed_value := int(
		GameClock.year * 1000000
		+ GameClock.day * 1000
		+ child_index * 17
		+ hash(String(parent_a.name))
		+ hash(String(parent_b.name))
	)
	child.configure_child_from_parents(parent_a, parent_b, seed_value)
	return child

func _draw() -> void:
	draw_circle(Vector2.ZERO, 34.0, Color(0.45, 0.30, 0.17, 0.92))
	draw_circle(Vector2.ZERO, 28.0, Color(0.72, 0.54, 0.30, 0.95))
	draw_arc(Vector2.ZERO, 35.0, 0.0, TAU, 32, Color(0.24, 0.16, 0.09), 3.0)

	draw_circle(Vector2(-8, -2), 8.0, Color(0.92, 0.42, 0.56, 0.88))
	draw_circle(Vector2(8, -2), 8.0, Color(0.92, 0.42, 0.56, 0.88))
	draw_circle(Vector2(0, 5), 9.0, Color(0.92, 0.42, 0.56, 0.88))

	draw_circle(Vector2(30, -30), 8.0, Color(0.96, 0.80, 0.28, 0.95))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(27, -26),
		"E",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color(0.12, 0.10, 0.06)
	)
