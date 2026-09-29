extends CanvasLayer

@onready var status_label: Label = $StatusPanel/Margin/Status
@onready var hotbar_label: Label = $HotbarPanel/Margin/Hotbar
@onready var help_label: Label = $HelpPanel/Margin/Help
@onready var feedback_label: Label = $Feedback

var player: PlayerController
var _feedback_time_left: float = 0.0

func _ready() -> void:
	call_deferred("_bind_player")
	help_label.text = "WASD mover | 1-0/scroll hotbar | clique/ESPACO usar | E/clique direito interagir, colher, dormir ou encher regador"

func _process(delta: float) -> void:
	if player == null:
		_bind_player()

	if _feedback_time_left > 0.0:
		_feedback_time_left -= delta
		if _feedback_time_left <= 0.0:
			feedback_label.text = ""

	_refresh_status()
	_refresh_hotbar()

func _bind_player() -> void:
	player = get_tree().get_first_node_in_group("player") as PlayerController
	if player != null and not player.feedback_requested.is_connected(_show_feedback):
		player.feedback_requested.connect(_show_feedback)

func _refresh_status() -> void:
	if player == null:
		status_label.text = "Carregando..."
		return

	var charge_text := ""
	if player.tools.is_charging:
		charge_text = " | Carga %d" % player.tools.charge_stage

	var water_text := ""
	var selected := player.inventory.get_selected_stack()
	if selected != null and not selected.is_empty():
		if selected.item.kind == ItemDefinition.ItemKind.TOOL and selected.item.tool_type == ToolController.ToolType.WATERING_CAN:
			water_text = "\nAgua: %d / %d" % [
				player.tools.current_water,
				player.tools.get_water_capacity(),
			]

	status_label.text = "Dia %d  %s\nEnergia: %.0f / %.0f\nSelecionado: %s%s%s" % [
		GameClock.day,
		GameClock.get_time_text(),
		player.energy.current_energy,
		player.energy.maximum_energy,
		player.get_selected_item_name(),
		charge_text,
		water_text,
	]

func _refresh_hotbar() -> void:
	if player == null:
		hotbar_label.text = ""
		return

	var parts: Array[String] = []

	for index in range(player.inventory.slots.size()):
		var slot := player.inventory.get_slot(index)
		var key_text := str(index + 1) if index < 9 else ("0" if index == 9 else "-")
		var content := "vazio"

		if slot != null and not slot.is_empty():
			content = slot.item.display_name
			if slot.item.max_stack > 1:
				content += " x%d" % slot.amount

		var marker := ">" if index == player.inventory.selected_slot else " "
		parts.append("%s[%s] %s" % [marker, key_text, content])

	var first_line := " | ".join(parts.slice(0, 6))
	var second_line := " | ".join(parts.slice(6, 12))
	hotbar_label.text = "%s\n%s" % [first_line, second_line]

func _show_feedback(text: String) -> void:
	feedback_label.text = text
	_feedback_time_left = 2.2
