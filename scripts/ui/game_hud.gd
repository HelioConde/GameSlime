extends CanvasLayer

@onready var status_label: Label = $StatusPanel/Margin/Status
@onready var help_label: Label = $HelpPanel/Margin/Help
@onready var feedback_label: Label = $Feedback

var player: PlayerController
var _feedback_time_left: float = 0.0

func _ready() -> void:
	call_deferred("_bind_player")
	help_label.text = "WASD/Setas mover  |  1 Enxada  |  2 Regador  |  Segure clique/ESPACO e solte: usar  |  E/clique direito: interagir"

func _process(delta: float) -> void:
	if player == null:
		_bind_player()

	if _feedback_time_left > 0.0:
		_feedback_time_left -= delta
		if _feedback_time_left <= 0.0:
			feedback_label.text = ""

	_refresh_status()

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

	status_label.text = "Dia %d  %s\nEnergia: %.0f / %.0f\nFerramenta: %s%s" % [
		GameClock.day,
		GameClock.get_time_text(),
		player.energy.current_energy,
		player.energy.maximum_energy,
		player.tools.get_tool_name(),
		charge_text,
	]

func _show_feedback(text: String) -> void:
	feedback_label.text = text
	_feedback_time_left = 2.2
