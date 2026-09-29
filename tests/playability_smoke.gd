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
	var economy = get_tree().root.get_node_or_null("Economy")

	_check(save_manager != null, "SaveManager autoload exists")
	_check(game_clock != null, "GameClock autoload exists")
	_check(economy != null, "Economy autoload exists")
	if save_manager == null or game_clock == null or economy == null:
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

	var world_spawner := main.get_node_or_null("WorldSpawnManager") as WorldSpawnManager
	_check(world_spawner != null, "world spawn manager exists")
	if world_spawner != null:
		var daily_spawns := get_tree().get_nodes_in_group("daily_world_spawn")
		_check(daily_spawns.size() >= 4 and daily_spawns.size() <= 7, "new day creates bounded random world spawns")
		var first_snapshot := world_spawner.get_daily_spawn_snapshot()
		world_spawner.refresh_for_current_day()
		var second_snapshot := world_spawner.get_daily_spawn_snapshot()
		_check(first_snapshot == second_snapshot, "same day world spawns are deterministic")
		_check(save_manager.save_game(), "world spawn snapshot save succeeds")
		world_spawner.refresh_for_current_day()
		_check(save_manager.load_game(), "world spawn snapshot reload succeeds")
		_check(world_spawner.get_daily_spawn_snapshot() == first_snapshot, "world spawns survive save and load")

	var world_bounds := main.get_node_or_null("WorldBounds") as StaticBody2D
	_check(world_bounds != null, "world bounds exist")
	if world_bounds != null:
		_check(world_bounds.get_child_count() == 5, "world bounds cover outer edges and farm divider")

	if player != null and world_bounds != null:
		var original_position := player.global_position
		player.global_position = Vector2(640.0, 24.0)
		var boundary_collision := player.move_and_collide(Vector2(0.0, -80.0))
		_check(boundary_collision != null, "north world boundary blocks the player")
		_check(player.global_position.y >= 0.0, "player cannot leave the visible world vertically")
		player.global_position = Vector2(1240.0, 360.0)
		var farm_divider_collision := player.move_and_collide(Vector2(100.0, 0.0))
		_check(farm_divider_collision != null, "farm divider blocks hidden mine staging area")
		_check(player.global_position.x < 1280.0, "player stays on farm side without using mine transition")
		player.global_position = original_position

	var solid_interactables := ["ShippingBin", "SeedShop", "ToolUpgradeStation", "WaterSource"]
	for node_name in solid_interactables:
		var interactable := main.get_node_or_null(NodePath(node_name))
		_check(interactable != null, "%s exists" % node_name)
		if interactable != null:
			_check(
				interactable.get_node_or_null("StaticBody2D/CollisionShape2D") != null,
				"%s blocks player movement" % node_name
			)

	if player != null:
		_check(player.inventory.slots.size() == 12, "inventory has 12 slots")
		_check(player.inventory.get_definition(&"wild_flower") != null, "wild flower definition registered")
		_check(player.inventory.get_definition(&"wild_berry") != null, "wild berry definition registered")
		_check(player.inventory.get_definition(&"wild_mushroom") != null, "wild mushroom definition registered")
		_check(player.inventory.get_definition(&"wild_root") != null, "wild root definition registered")

		var forage_food := player.inventory.get_definition(&"wild_berry")
		if forage_food != null:
			player.inventory.seed_slot(11, forage_food, 1)
			player.inventory.set_selected_slot(11)
			player.energy.set_current_energy(100.0)
			player.call("_primary_action_pressed")
			_check(player.inventory.count_item(&"wild_berry") == 0, "eating forage consumes one item")
			_check(player.energy.current_energy > 100.0, "eating forage restores energy")
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

	var hud := main.get_node_or_null("GameHUD")
	_check(hud != null, "game HUD exists")
	if hud != null:
		hud.call("_toggle_inventory")
		_check(get_tree().paused, "inventory pauses the game")
		hud.call("_close_all_menus")
		_check(not get_tree().paused, "closing menus resumes the game")

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

			var deep_entrance := main.get_node_or_null("DeepMineEntrance") as WorldTransition
			var deep_area := main.get_node_or_null("DeepMineArea") as MineArea
			_check(deep_entrance != null, "deep mine entrance exists")
			_check(deep_area != null, "deep mine area exists")
			if deep_entrance != null and deep_area != null:
				player.global_position = deep_entrance.global_position
				player.tools.pickaxe_level = 1
				var deep_before := player.global_position
				var deep_blocked := deep_entrance.interact(player)
				_check(player.global_position == deep_before, "deep mine blocks pickaxe level 1")
				_check(deep_blocked.contains("Picareta Nv.2"), "deep mine explains level 2 requirement")
				player.tools.pickaxe_level = 2
				var deep_entered := deep_entrance.interact(player)
				_check(deep_entered.contains("entrou"), "deep mine confirms entry")
				_check(deep_area.contains_position(player.global_position), "player arrives inside deep mine")

			var abyss_entrance := main.get_node_or_null("AbyssMineEntrance") as WorldTransition
			var abyss_area := main.get_node_or_null("AbyssMineArea") as MineArea
			_check(abyss_entrance != null, "abyss mine entrance exists")
			_check(abyss_area != null, "abyss mine area exists")
			if abyss_entrance != null and abyss_area != null:
				player.global_position = abyss_entrance.global_position
				player.tools.pickaxe_level = 2
				var abyss_before := player.global_position
				var abyss_blocked := abyss_entrance.interact(player)
				_check(player.global_position == abyss_before, "abyss mine blocks pickaxe level 2")
				_check(abyss_blocked.contains("Picareta Nv.3"), "abyss mine explains level 3 requirement")
				player.tools.pickaxe_level = 3
				var abyss_entered := abyss_entrance.interact(player)
				_check(abyss_entered.contains("entrou"), "abyss mine confirms entry")
				_check(abyss_area.contains_position(player.global_position), "player arrives inside abyss mine")

				var saved_mine_position := player.global_position
				_check(save_manager.save_game(), "save inside abyss mine succeeds")
				player.global_position = Vector2(640.0, 560.0)
				_check(save_manager.load_game(), "load inside abyss mine succeeds")
				_check(player.global_position.is_equal_approx(saved_mine_position), "mine position survives save and load")
				_check(abyss_area.contains_position(player.global_position), "loaded player remains inside abyss mine")

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

	if player != null:
		var shop := main.get_node_or_null("SeedShop") as SeedShop
		_check(shop != null, "seed shop exists")
		if shop != null:
			var offers := shop.get_current_offers()
			_check(not offers.is_empty(), "seasonal shop has offers")
			if not offers.is_empty():
				var stone := player.inventory.get_definition(&"stone")
				_check(stone != null, "stone definition available for full-inventory test")
				if stone != null:
					for index in range(player.inventory.slots.size()):
						player.inventory.seed_slot(index, stone, stone.max_stack)

					var gold_before := int(economy.gold)
					var offer := offers[0] as ItemDefinition
					var purchase_message := shop.purchase(player, offer.id, 1)
					_check(
						int(economy.gold) == gold_before,
						"full inventory purchase does not spend gold"
					)
					_check(
						purchase_message.contains("sem espaco"),
						"full inventory purchase explains why it failed"
					)

					# A mature crop must remain in the ground when the inventory is full.
					var crop := player.starter_seed_item.crop_to_plant
					var harvest_item := player.inventory.get_definition(crop.harvest_item_id) if crop != null else null
					_check(crop != null, "starter crop definition exists")
					_check(harvest_item != null, "starter harvest item is registered")
					if crop != null and harvest_item != null and farm != null:
						var harvest_cell := Vector2i(5, 4)
						farm.apply_hoe([harvest_cell])
						_check(farm.plant_crop(harvest_cell, crop), "test crop can be planted")
						var crop_data := farm.get_cell(harvest_cell)
						crop_data.ready_to_harvest = true
						crop_data.growth_days_completed = crop.growth_days
						crop_data.crop_stage = crop.visual_stages

						player.global_position = farm.cell_to_world(harvest_cell) - Vector2(farm.cell_size, 0)
						player.facing = Vector2i.RIGHT
						player.call("_interact")
						_check(farm.can_harvest(harvest_cell), "full inventory does not destroy mature crop")
						_check(player.inventory.count_item(harvest_item.id) == 0, "blocked harvest adds no item")

						player.inventory.get_slot(player.inventory.slots.size() - 1).clear()
						player.inventory.inventory_changed.emit()
						player.call("_interact")
						_check(not farm.can_harvest(harvest_cell), "harvest succeeds after freeing one slot")
						_check(player.inventory.count_item(harvest_item.id) == 1, "successful harvest adds exactly one item")

						# Regrowing crops remain planted and use deterministic multi-yield harvests.
						var berry_crop := load("res://resources/crops/spring_berry.tres") as CropDefinition
						var berry_item := player.inventory.get_definition(&"spring_berry")
						_check(berry_crop != null and berry_crop.regrow_days > 0, "regrowing crop definition exists")
						if berry_crop != null and berry_item != null:
							var regrow_cell := Vector2i(6, 4)
							farm.apply_hoe([regrow_cell])
							_check(farm.plant_crop(regrow_cell, berry_crop), "regrowing crop can be planted")
							var regrow_data := farm.get_cell(regrow_cell)
							regrow_data.ready_to_harvest = true
							regrow_data.growth_days_completed = berry_crop.growth_days
							regrow_data.crop_stage = berry_crop.visual_stages
							var expected_berry_amount := farm.get_harvest_amount(regrow_cell)
							var berry_harvest := farm.harvest_cell(regrow_cell)
							_check(int(berry_harvest.get("amount", 0)) == expected_berry_amount, "crop harvest yield is deterministic")
							_check(regrow_data.crop == berry_crop, "regrowing crop remains planted after harvest")
							_check(not regrow_data.ready_to_harvest, "regrowing crop returns to growth state")

						# Shipping must survive save/load and pay exactly once on the next day.
						var harvest_slot := -1
						for slot_index in range(player.inventory.slots.size()):
							var slot := player.inventory.get_slot(slot_index)
							if slot != null and not slot.is_empty() and slot.item.id == harvest_item.id:
								harvest_slot = slot_index
								break
						_check(harvest_slot >= 0, "harvest stack can be selected for shipping")
						if harvest_slot >= 0:
							player.inventory.set_selected_slot(harvest_slot)
							var shipping_bin := main.get_node_or_null("ShippingBin") as ShippingBin
							_check(shipping_bin != null, "shipping bin exists")
							if shipping_bin != null:
								player.global_position = shipping_bin.global_position
								var shipping_message := shipping_bin.interact(player)
								var expected_value := harvest_item.sell_price
								_check(shipping_message.contains("Enviado"), "shipping accepts sellable crop")
								_check(player.inventory.count_item(harvest_item.id) == 0, "shipping removes crop once")
								_check(economy.get_pending_total() == expected_value, "shipping queues exact sale value")
								_check(save_manager.save_game(), "pending shipment save succeeds")
								_check(save_manager.load_game(), "pending shipment reload succeeds")
								_check(economy.get_pending_total() == expected_value, "pending shipment survives reload")

								var gold_before_shipping := int(economy.gold)
								game_clock.sleep_and_start_next_day()
								await get_tree().process_frame
								await get_tree().process_frame
								_check(int(economy.gold) == gold_before_shipping + expected_value, "shipment pays exact value next day")
								_check(economy.get_pending_total() == 0, "shipment clears after payout")
								var gold_after_shipping := int(economy.gold)
								game_clock.sleep_and_start_next_day()
								await get_tree().process_frame
								await get_tree().process_frame
								_check(int(economy.gold) == gold_after_shipping, "shipment cannot pay twice")

	if player != null:
		# Inventory manipulation must conserve item totals.
		var stone_def := player.inventory.get_definition(&"stone")
		var wood_def := player.inventory.get_definition(&"wood")
		if stone_def != null and wood_def != null:
			player.inventory.clear_all()
			player.inventory.seed_slot(0, stone_def, 10)
			player.inventory.seed_slot(1, stone_def, 5)
			player.inventory.seed_slot(2, wood_def, 7)
			var total_stone_before := player.inventory.count_item(&"stone")
			var total_wood_before := player.inventory.count_item(&"wood")
			_check(player.inventory.split_stack_half(0, 3), "inventory can split stacks")
			_check(player.inventory.move_or_merge_stack(1, 0), "inventory can merge equal stacks")
			_check(player.inventory.move_or_merge_stack(2, 4), "inventory can move stacks")
			player.inventory.organize_slots()
			_check(player.inventory.count_item(&"stone") == total_stone_before, "inventory operations conserve stone")
			_check(player.inventory.count_item(&"wood") == total_wood_before, "inventory operations conserve wood")

	# Crop growth must advance only after watered days.
	if player != null and farm != null:
		var natural_crop := player.starter_seed_item.crop_to_plant
		if natural_crop != null and natural_crop.can_grow_in_season(game_clock.season_index):
			var growth_cell := Vector2i(2, 2)
			farm.apply_hoe([growth_cell])
			_check(farm.plant_crop(growth_cell, natural_crop), "natural growth crop can be planted")
			var growth_data := farm.get_cell(growth_cell)
			var growth_before_dry_day := growth_data.growth_days_completed
			game_clock.sleep_and_start_next_day()
			await get_tree().process_frame
			await get_tree().process_frame
			_check(
				growth_data.growth_days_completed == growth_before_dry_day,
				"unwatered crop does not advance growth"
			)
			for _growth_day in range(natural_crop.growth_days):
				farm.apply_water([growth_cell])
				game_clock.sleep_and_start_next_day()
				await get_tree().process_frame
				await get_tree().process_frame
			_check(farm.can_harvest(growth_cell), "watered crop reaches harvest naturally")

	# Seven consecutive day rollovers must remain playable and autosaved.
	var seven_day_start := int(game_clock.day)
	for _index in range(7):
		game_clock.sleep_and_start_next_day()
		await get_tree().process_frame
		await get_tree().process_frame
		_check(not get_tree().paused, "day rollover never leaves game paused")
		_check(save_manager.has_save(), "day rollover keeps a valid save")
	_check(int(game_clock.day) == seven_day_start + 7, "seven consecutive days advance without softlock")

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
