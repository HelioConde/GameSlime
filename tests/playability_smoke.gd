extends Node

var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PLAYABILITY] OK: ", message)
	else:
		push_error("[PLAYABILITY] FAIL: " + message)
		_failures.append(message)

func _run() -> void:
	var save_manager = get_tree().root.get_node_or_null("SaveManager")
	var game_clock = get_tree().root.get_node_or_null("GameClock")

	_check(save_manager != null, "SaveManager autoload exists")
	_check(game_clock != null, "GameClock autoload exists")
	if save_manager == null or game_clock == null:
		_finish()
		return

	save_manager.delete_save()

	var packed := load("res://scenes/world/main.tscn") as PackedScene
	_check(packed != null, "main scene loads")
	if packed == null:
		_finish()
		return

	var main := packed.instantiate()
	add_child(main)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var player := get_tree().get_first_node_in_group("player") as PlayerController
	var farm := get_tree().get_first_node_in_group("farm_field") as FarmField

	_check(player != null, "player exists")
	_check(farm != null, "farm exists")

	if player != null:
		_check(player.inventory.slots.size() == 12, "inventory has 12 slots")
		_check(player.inventory.get_definition(&"copper_ore") != null, "copper definition registered")
		_check(player.inventory.get_definition(&"iron_ore") != null, "iron definition registered")
		_check(player.inventory.get_definition(&"silver_ore") != null, "silver definition registered")
		_check(player.inventory.get_definition(&"gold_ore") != null, "gold definition registered")

	var patches := get_tree().get_nodes_in_group("daily_resource_patch")
	_check(patches.size() >= 4, "daily resource patches exist")

	for node in patches:
		var patch := node as DailyResourcePatch
		if patch == null:
			continue
		patch.ensure_resources()
		for index in range(patch.local_spawn_positions.size()):
			var resource_name := "%s%02d" % [patch.resource_name_prefix, index + 1]
			_check(
				main.has_node(NodePath(resource_name)),
				"daily resource spawned: %s" % resource_name
			)

	if player != null:
		var entrance := main.get_node_or_null("MineEntrance") as WorldTransition
		_check(entrance != null, "shallow mine entrance exists")
		if entrance != null:
			player.global_position = entrance.global_position
			var before := player.global_position
			player.tools.pickaxe_level = 0
			var blocked_message := entrance.interact(player)
			_check(player.global_position == before, "mine blocks pickaxe level 0")
			_check(blocked_message.contains("Picareta Nv.1"), "mine explains level requirement")

			player.tools.pickaxe_level = 1
			var entered_message := entrance.interact(player)
			_check(player.global_position == entrance.target_position, "mine opens at pickaxe level 1")
			_check(entered_message.contains("entrou"), "mine confirms entry")

	var old_day := int(game_clock.day)
	game_clock.sleep_and_start_next_day()
	await get_tree().process_frame
	await get_tree().process_frame

	_check(int(game_clock.day) == old_day + 1, "day rollover advances exactly one day")
	_check(save_manager.has_save(), "day rollover creates autosave")

	# Create a second save so the first one becomes the backup, then corrupt
	# the primary file. load_game() must recover from the backup.
	_check(save_manager.save_game(), "second save succeeds and creates backup")
	var corrupt_file := FileAccess.open("user://savegame.json", FileAccess.WRITE)
	_check(corrupt_file != null, "primary save can be opened for corruption test")
	if corrupt_file != null:
		corrupt_file.store_string("{corrupted")
		corrupt_file.close()
	_check(save_manager.load_game(), "corrupt primary save falls back to backup")

	for node in patches:
		var patch := node as DailyResourcePatch
		if patch == null:
			continue
		for index in range(patch.local_spawn_positions.size()):
			var resource_name := "%s%02d" % [patch.resource_name_prefix, index + 1]
			_check(
				main.has_node(NodePath(resource_name)),
				"daily resource exists before autosave: %s" % resource_name
			)

	save_manager.delete_save()
	main.queue_free()
	await get_tree().process_frame
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		print("[PLAYABILITY] PASS")
		get_tree().quit(0)
		return

	print("[PLAYABILITY] FAILURES: ", _failures.size())
	for failure in _failures:
		print(" - ", failure)
	get_tree().quit(1)
