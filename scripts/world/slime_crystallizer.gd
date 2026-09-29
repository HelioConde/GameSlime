class_name SlimeCrystallizer
extends Node2D

const GEL_COST := 3
const COPPER_COST := 1
const PROCESS_MINUTES := 240

@export var interaction_radius: float = 60.0
@export var output_item: ItemDefinition

var processing: bool = false
var output_ready: bool = false
var ready_absolute_minute: int = 0

func _ready() -> void:
	add_to_group("slime_crystallizer")
	GameClock.time_changed.connect(_on_time_changed)
	GameClock.day_started.connect(_on_day_started)
	_refresh_processing_state()
	queue_redraw()

func can_interact(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius

func interact(player: PlayerController) -> String:
	if player == null or not can_interact(player.global_position):
		return ""

	_refresh_processing_state()

	if output_ready:
		return _collect_output(player)

	if processing:
		return "Cristalizador trabalhando · faltam %s." % _remaining_time_text()

	var selected := player.inventory.get_selected_stack()
	if selected == null or selected.is_empty() or selected.item.id != &"slime_gel":
		return "Selecione Gel de Slime. Receita: %d Gel + %d Cobre." % [
			GEL_COST,
			COPPER_COST,
		]

	var gel_owned := player.inventory.count_item(&"slime_gel")
	var copper_owned := player.inventory.count_item(&"copper_ore")

	if gel_owned < GEL_COST or copper_owned < COPPER_COST:
		return "Cristalizador precisa %d Gel + %d Cobre. Voce tem %d + %d." % [
			GEL_COST,
			COPPER_COST,
			gel_owned,
			copper_owned,
		]

	if not player.inventory.remove_item(&"slime_gel", GEL_COST):
		return "Falha ao consumir Gel de Slime."

	if not player.inventory.remove_item(&"copper_ore", COPPER_COST):
		player.inventory.add_item(player.slime_gel_item, GEL_COST)
		return "Falha ao consumir Minerio de Cobre."

	processing = true
	output_ready = false
	ready_absolute_minute = _get_absolute_minute() + PROCESS_MINUTES
	queue_redraw()

	return "Cristalizacao iniciada · pronta em 4 horas."

func get_status_text() -> String:
	_refresh_processing_state()

	if output_ready:
		return "Cristalizador · PRONTO PARA COLETAR"
	if processing:
		return "Cristalizador · processando · %s restantes" % _remaining_time_text()
	return "Cristalizador · vazio · receita: 3 Gel + 1 Cobre"

func get_save_data() -> Dictionary:
	return {
		"node_name": String(name),
		"processing": processing,
		"output_ready": output_ready,
		"ready_absolute_minute": ready_absolute_minute,
	}

func load_save_data(data: Dictionary) -> void:
	processing = bool(data.get("processing", false))
	output_ready = bool(data.get("output_ready", false))
	ready_absolute_minute = int(data.get("ready_absolute_minute", 0))
	_refresh_processing_state()
	queue_redraw()

func _collect_output(player: PlayerController) -> String:
	if output_item == null:
		return "Produto do cristalizador nao configurado."
	if not player.inventory.can_add_item(output_item, 1):
		return "Inventario cheio. Libere um slot para coletar o Cristal."

	var remaining := player.inventory.add_item(output_item, 1)
	if remaining > 0:
		return "Nao foi possivel guardar o Cristal."

	output_ready = false
	processing = false
	ready_absolute_minute = 0
	queue_redraw()
	return "Coletou Cristal de Slime x1 · valor de venda %dg." % output_item.sell_price

func _on_time_changed(_day: int, _hour: int, _minute: int) -> void:
	_refresh_processing_state()

func _on_day_started(_day: int) -> void:
	_refresh_processing_state()

func _refresh_processing_state() -> void:
	if not processing or output_ready:
		return

	if _get_absolute_minute() >= ready_absolute_minute:
		processing = false
		output_ready = true
		queue_redraw()

func _get_absolute_minute() -> int:
	return (GameClock.day - 1) * 1440 + GameClock.minute_of_day

func _remaining_time_text() -> String:
	var remaining := maxi(ready_absolute_minute - _get_absolute_minute(), 0)
	var hours := int(floor(float(remaining) / 60.0))
	var minutes := remaining % 60

	if hours > 0:
		return "%dh%02d" % [hours, minutes]
	return "%d min" % minutes

func _draw() -> void:
	var body_color := Color(0.28, 0.31, 0.34)
	var core_color := Color(0.30, 0.48, 0.42)

	if processing:
		core_color = Color(0.34, 0.82, 0.62)
	elif output_ready:
		core_color = Color(0.62, 1.0, 0.78)

	draw_rect(Rect2(-24, -24, 48, 48), body_color, true)
	draw_rect(Rect2(-18, -18, 36, 32), Color(0.16, 0.18, 0.20), true)
	draw_circle(Vector2(0, -2), 12.0, core_color)
	draw_circle(Vector2(0, -2), 7.0, core_color.lightened(0.18))
	draw_rect(Rect2(-15, 14, 30, 8), Color(0.42, 0.27, 0.16), true)

	if output_ready:
		var pulse := 0.72 + sin(Time.get_ticks_msec() * 0.004) * 0.18
		draw_arc(Vector2(0, -2), 17.0, 0.0, TAU, 24, Color(0.72, 1.0, 0.86, pulse), 2.0)

	draw_circle(Vector2(28, -29), 8.0, Color(0.96, 0.80, 0.28, 0.95))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(25, -25),
		"E",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color(0.12, 0.10, 0.06)
	)
