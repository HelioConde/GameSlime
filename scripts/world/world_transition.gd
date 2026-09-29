class_name WorldTransition
extends Node2D

@export var interaction_radius: float = 62.0
@export var target_position: Vector2 = Vector2.ZERO
@export_range(0, 5, 1) var minimum_pickaxe_level: int = 0
@export var transition_name: String = "Passagem"
@export var entrance_style: bool = true

func _ready() -> void:
	add_to_group("world_transition")
	queue_redraw()

func can_interact(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius

func interact(player: PlayerController) -> String:
	if player == null or not can_interact(player.global_position):
		return ""

	var pickaxe_level := player.tools.get_tool_level(ToolController.ToolType.PICKAXE)
	if pickaxe_level < minimum_pickaxe_level:
		return "%s bloqueada · precisa Picareta Nv.%d." % [
			transition_name,
			minimum_pickaxe_level,
		]

	player.velocity = Vector2.ZERO
	player.global_position = target_position

	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.reset_smoothing()

	if entrance_style:
		return "Voce entrou em %s." % transition_name
	return "Voce saiu de %s." % transition_name

func _draw() -> void:
	if entrance_style:
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(-34, 24),
				Vector2(-30, -5),
				Vector2(-18, -28),
				Vector2(18, -28),
				Vector2(30, -5),
				Vector2(34, 24),
			]),
			Color(0.24, 0.25, 0.24)
		)
		draw_rect(Rect2(-22, -14, 44, 38), Color(0.055, 0.06, 0.055), true)
		draw_arc(Vector2(0, -12), 21.0, PI, TAU, 20, Color(0.42, 0.40, 0.35), 4.0)
	else:
		draw_rect(Rect2(-25, -12, 50, 28), Color(0.34, 0.27, 0.18), true)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(-28, -12),
				Vector2(0, -28),
				Vector2(28, -12),
			]),
			Color(0.46, 0.38, 0.27)
		)

	draw_circle(Vector2(32, -32), 8.0, Color(0.96, 0.80, 0.28, 0.95))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(29, -28),
		"E",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color(0.12, 0.10, 0.06)
	)
