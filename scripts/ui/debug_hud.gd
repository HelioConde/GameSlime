extends CanvasLayer

@onready var label: Label = $Panel/Margin/Label
var player: PlayerController

func _ready() -> void:
	call_deferred("_find_player")

func _process(_delta: float) -> void:
	if player == null:
		_find_player()
	_render_status()

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player") as PlayerController

func _render_status() -> void:
	var selected_text := "nenhuma"

	if player != null and player.selected_slime != null:
		var slime := player.selected_slime
		var task_text := "sem tarefa"

		if slime.current_task != null:
			task_text = GameEnums.task_name(slime.current_task.type)

		selected_text = "%s | energia %.0f/%.0f | %s" % [
			GameEnums.command_name(slime.command_mode),
			slime.energy,
			slime.max_energy,
			task_text,
		]

	var pending := 0
	var active := 0

	for task_variant in TaskManager.get_tasks():
		var task := task_variant as TaskData
		if task == null:
			continue
		if task.state == GameEnums.TaskState.PENDING:
			pending += 1
		elif task.state in [GameEnums.TaskState.CLAIMED, GameEnums.TaskState.RUNNING]:
			active += 1

	label.text = """SLIME LAND FARM - CORE REBUILD
WASD mover | clique selecionar slime
G Auto | F Follow | H Wait | R Rest | M Move To | T Force Task
1 Chop | 2 Mine | 3 Harvest | 4 Plant | 5 Haul | 6 Build

Slime: %s
Tarefas pendentes: %d | ativas: %d""" % [selected_text, pending, active]
