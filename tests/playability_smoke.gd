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

		var initial_spawn_day := int(game_clock.day)
		game_clock.sleep_and_start_next_day()
		await get_tree().process_frame
		await get_tree().process_frame
		var next_day_spawns := get_tree().get_nodes_in_group("daily_world_spawn")
		_check(next_day_spawns.size() >= first_snapshot.size(), "uncollected natural spawns persist into next day")
		_check(next_day_spawns.size() <= WorldSpawnManager.MAX_NATURAL_SPAWNS, "natural spawn accumulation respects world cap")
		var found_previous_day_spawn := false
		for node in next_day_spawns:
			var drop := node as ItemDrop
			if drop != null and drop.spawned_day == initial_spawn_day:
				found_previous_day_spawn = true
				break
		_check(found_previous_day_spawn, "previous-day natural spawn remains before expiry")

		for _expiry_day in range(WorldSpawnManager.MATERIAL_LIFETIME_DAYS):
			game_clock.sleep_and_start_next_day()
			await get_tree().process_frame
			await get_tree().process_frame
		var stale_spawn_found := false
		for node in get_tree().get_nodes_in_group("daily_world_spawn"):
			var drop := node as ItemDrop
			if drop != null and drop.spawned_day == initial_spawn_day:
				stale_spawn_found = true
				break
		_check(not stale_spawn_found, "expired natural spawns are pruned automatically")
		_check(get_tree().get_nodes_in_group("daily_world_spawn").size() <= WorldSpawnManager.MAX_NATURAL_SPAWNS, "world spawn cap remains stable across multiple days")

		var saved_weather := int(WeatherManager.current_weather)
		var saved_clock := GameClock.get_save_data()
		GameClock.load_save_data({
			"day": 15,
			"minute_of_day": GameClock.START_MINUTE,
			"year": 1,
			"season_index": GameClock.Season.SPRING,
			"day_of_season": 15,
		})
		WeatherManager.current_weather = WeatherManager.Weather.CLOUDY
		var cloudy_pool := world_spawner.get_current_spawn_pool_ids()
		WeatherManager.current_weather = WeatherManager.Weather.RAIN
		var rainy_pool := world_spawner.get_current_spawn_pool_ids()
		_check(
			rainy_pool.count(&"wild_mushroom") > cloudy_pool.count(&"wild_mushroom"),
			"spring rain adds mushroom weight to natural forage pool"
		)
		GameClock.load_save_data({
			"day": 85,
			"minute_of_day": GameClock.START_MINUTE,
			"year": 1,
			"season_index": GameClock.Season.WINTER,
			"day_of_season": 1,
		})
		WeatherManager.current_weather = WeatherManager.Weather.CLOUDY
		var winter_cloudy_pool := world_spawner.get_current_spawn_pool_ids()
		WeatherManager.current_weather = WeatherManager.Weather.SNOW
		var winter_snow_pool := world_spawner.get_current_spawn_pool_ids()
		_check(
			winter_snow_pool.count(&"wild_root") > winter_cloudy_pool.count(&"wild_root"),
			"snow adds wild-root weight to winter forage pool"
		)
		GameClock.load_save_data(saved_clock)
		WeatherManager.current_weather = saved_weather

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
		_check(player.inventory.get_definition(&"basic_fertilizer") != null, "basic fertilizer definition registered")

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

	if player != null:
		# Tool charging, water and energy are part of the core farming loop.
		player.tools.hoe_level = 2
		player.tools.select_tool(ToolController.ToolType.HOE)
		player.tools.begin_charge()
		player.tools.update_charge(0.91)
		_check(player.tools.charge_stage == 2, "hoe charge reaches level-two area threshold")
		var charged_result := player.tools.release_charge()
		_check(int(charged_result.get("stage", -1)) == 2, "charged tool releases the reached stage")

		player.tools.watering_can_level = 2
		player.tools.current_water = 0
		var water_source := main.get_node_or_null("WaterSource") as WaterSource
		_check(water_source != null, "water source exists")
		if water_source != null:
			player.global_position = water_source.global_position
			var refill_message := water_source.interact(player)
			_check(refill_message.contains("cheio"), "water source confirms refill")
			_check(player.tools.current_water == player.tools.get_water_capacity(), "water source refills to current capacity")
			var water_before := player.tools.current_water
			_check(player.tools.spend_water(2), "watering can spends water for charged area")
			_check(player.tools.current_water == water_before - player.tools.get_water_cost(2), "watering uses exact water cost")

		player.energy.set_current_energy(10.0)
		_check(player.energy.spend(2.0), "tool energy can be spent")
		_check(is_equal_approx(player.energy.current_energy, 8.0), "energy spends exact tool cost")
		player.energy.set_current_energy(0.0)
		_check(
			is_equal_approx(player.get_movement_speed_multiplier(), player.exhausted_move_multiplier),
			"zero energy applies exhausted movement multiplier"
		)
		player.energy.restore_full()
		_check(is_equal_approx(player.get_movement_speed_multiplier(), 1.0), "restored energy returns normal movement speed")

	if player != null and farm != null:
		var fertilizer := player.inventory.get_definition(&"basic_fertilizer")
		var starter_crop := player.starter_seed_item.crop_to_plant
		_check(fertilizer != null, "fertilizer is available to player inventory catalog")
		if fertilizer != null and starter_crop != null:
			var fertilizer_cell := Vector2i(8, 4)
			farm.apply_hoe([fertilizer_cell])
			player.inventory.seed_slot(10, fertilizer, 1)
			player.inventory.set_selected_slot(10)
			player.global_position = farm.cell_to_world(fertilizer_cell) - Vector2(farm.cell_size, 0)
			player.facing = Vector2i.RIGHT
			player.call("_primary_action_pressed")
			var fertilized_data := farm.get_cell(fertilizer_cell)
			_check(fertilized_data.fertility_bonus == fertilizer.fertility_bonus, "fertilizer applies configured soil bonus")
			_check(player.inventory.count_item(&"basic_fertilizer") == 0, "fertilizer use consumes exactly one item")
			_check(farm.plant_crop(fertilizer_cell, starter_crop), "crop can be planted on fertilized soil")
			fertilized_data.ready_to_harvest = true
			fertilized_data.growth_days_completed = starter_crop.growth_days
			fertilized_data.crop_stage = starter_crop.visual_stages
			var base_fertilized_yield := starter_crop.get_harvest_amount(game_clock.day, fertilizer_cell)
			var fertilized_quality := farm.get_harvest_quality(fertilizer_cell)
			_check(
				farm.get_harvest_amount(fertilizer_cell) == base_fertilized_yield + fertilizer.fertility_bonus,
				"fertilizer increases harvest by exact configured bonus"
			)
			_check(
				fertilized_quality in [InventorySlotData.Quality.SILVER, InventorySlotData.Quality.GOLD],
				"fertilizer upgrades crop quality above normal"
			)
			_check(save_manager.save_game(), "fertilized soil save succeeds")
			fertilized_data.fertility_bonus = 0
			_check(save_manager.load_game(), "fertilized soil reload succeeds")
			fertilized_data = farm.get_cell(fertilizer_cell)
			_check(fertilized_data.fertility_bonus == fertilizer.fertility_bonus, "fertilizer survives save and load")
			_check(farm.get_harvest_quality(fertilizer_cell) == fertilized_quality, "fertilized crop quality is deterministic across save and load")
			var fertilizer_harvest := farm.harvest_cell(fertilizer_cell)
			_check(not fertilizer_harvest.is_empty(), "fertilized crop harvest succeeds")
			_check(int(fertilizer_harvest.get("quality", -1)) == fertilized_quality, "harvest returns deterministic fertilizer quality")
			_check(farm.get_cell(fertilizer_cell).fertility_bonus == 0, "single-cycle crop clears fertilizer after harvest")

		var recovery_cell := Vector2i(9, 5)
		farm.apply_hoe([recovery_cell])
		var recovery_data := farm.get_cell(recovery_cell)
		recovery_data.fertility_bonus = 1
		recovery_data.idle_tilled_days = 1
		_check(save_manager.save_game(), "idle tilled soil save succeeds")
		recovery_data.idle_tilled_days = 0
		_check(save_manager.load_game(), "idle tilled soil reload succeeds")
		recovery_data = farm.get_cell(recovery_cell)
		_check(recovery_data.idle_tilled_days == 1, "idle tilled soil age survives save and load")
		recovery_data.idle_tilled_days = farm.empty_soil_recovery_days - 1
		farm.call("_on_day_ended", game_clock.day)
		_check(not recovery_data.tilled, "abandoned tilled soil returns to grass")
		_check(recovery_data.fertility_bonus == 0, "soil recovery removes abandoned fertilizer")

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
		hud.call("_toggle_calendar")
		_check(get_tree().paused, "calendar pauses the game")
		hud.call("_toggle_calendar")
		_check(not get_tree().paused, "calendar closes without leaving pause")

		hud.call("_toggle_bestiary")
		_check(get_tree().paused, "bestiary pauses the game")
		hud.call("_toggle_bestiary")
		_check(not get_tree().paused, "bestiary closes without leaving pause")

		hud.call("_toggle_habitat")
		_check(get_tree().paused, "habitat menu pauses the game")
		hud.call("_toggle_habitat")
		_check(not get_tree().paused, "habitat menu closes without leaving pause")

		hud.call("_toggle_inventory")
		_check(get_tree().paused, "inventory pauses the game")
		var escape_event := InputEventKey.new()
		escape_event.pressed = true
		escape_event.physical_keycode = KEY_ESCAPE
		hud.call("_unhandled_input", escape_event)
		_check(not get_tree().paused, "ESC closes inventory and resumes game")

		var menu_shop := main.get_node_or_null("SeedShop") as SeedShop
		if menu_shop != null:
			hud.call("_open_shop", menu_shop)
			_check(get_tree().paused, "shop pauses the game")
			hud.call("_unhandled_input", escape_event)
			_check(not get_tree().paused, "ESC closes shop and resumes game")

		hud.call("_close_all_menus")
		_check(not get_tree().paused, "closing all menus resumes the game")

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

				# Verify the full return path: Abyss -> Deep -> Shallow -> Farm.
				var abyss_exit := main.get_node_or_null("AbyssMineExit") as WorldTransition
				var deep_exit := main.get_node_or_null("DeepMineExit") as WorldTransition
				var shallow_exit := main.get_node_or_null("MineExit") as WorldTransition
				var shallow_area := main.get_node_or_null("MineArea") as MineArea
				_check(abyss_exit != null and deep_exit != null and shallow_exit != null, "all mine exits exist")
				if abyss_exit != null and deep_exit != null and shallow_exit != null and shallow_area != null:
					player.global_position = abyss_exit.global_position
					var abyss_exit_message := abyss_exit.interact(player)
					_check(abyss_exit_message.contains("saiu"), "abyss exit interaction succeeds")
					_check(deep_area.contains_position(player.global_position), "abyss exit returns to deep mine")

					player.global_position = deep_exit.global_position
					var deep_exit_message := deep_exit.interact(player)
					_check(deep_exit_message.contains("saiu"), "deep mine exit interaction succeeds")
					_check(shallow_area.contains_position(player.global_position), "deep exit returns to shallow mine")

					player.global_position = shallow_exit.global_position
					var shallow_exit_message := shallow_exit.interact(player)
					_check(shallow_exit_message.contains("saiu"), "shallow mine exit interaction succeeds")
					_check(player.global_position.x < 1280.0, "shallow exit returns player to farm")

					# Repeated farm save/load must preserve the same stable position.
					var farm_save_position := player.global_position
					for _save_cycle in range(3):
						_check(save_manager.save_game(), "repeated farm save succeeds")
						player.global_position += Vector2(15.0, 10.0)
						_check(save_manager.load_game(), "repeated farm load succeeds")
						_check(player.global_position.is_equal_approx(farm_save_position), "repeated farm load preserves position")

				# Reaching 02:00 in a mine must pass out and return the player home tired.
				player.global_position = Vector2(3700.0, 360.0)
				player.energy.set_current_energy(25.0)
				var passout_day := int(game_clock.day)
				game_clock.minute_of_day = GameClock.END_MINUTE - 10
				game_clock.advance_minutes(10)
				await get_tree().process_frame
				await get_tree().process_frame
				_check(int(game_clock.day) == passout_day + 1, "02:00 passout advances to next day")
				_check(game_clock.last_transition_was_passout, "02:00 rollover is marked as passout")
				_check(player.global_position.is_equal_approx(player.morning_spawn_position), "passout returns player to morning spawn")
				_check(
					is_equal_approx(player.energy.current_energy, player.energy.maximum_energy * player.passout_energy_ratio),
					"passout restores only configured partial energy"
				)
				_check(save_manager.has_save(), "passout day rollover keeps autosave valid")

				game_clock.sleep_and_start_next_day()
				await get_tree().process_frame
				await get_tree().process_frame
				_check(not game_clock.last_transition_was_passout, "voluntary sleep is not marked as passout")
				_check(is_equal_approx(player.energy.current_energy, player.energy.maximum_energy), "voluntary sleep restores full energy")

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

	# Save v6 must remain loadable after additive v7 farm/ecology fields.
	_check(save_manager.save_game(), "v7 save exists before v6 compatibility test")
	var v6_file := FileAccess.open("user://savegame.json", FileAccess.READ)
	_check(v6_file != null, "save can be read for v6 compatibility test")
	if v6_file != null:
		var v6_data = JSON.parse_string(v6_file.get_as_text())
		v6_file.close()
		if v6_data is Dictionary:
			v6_data["version"] = 6
			var v6_farm: Dictionary = v6_data.get("farm", {})
			var v6_cells: Array = v6_farm.get("cells", [])
			for cell_entry_variant in v6_cells:
				if cell_entry_variant is Dictionary:
					var cell_entry := cell_entry_variant as Dictionary
					cell_entry.erase("fertility_bonus")
					cell_entry.erase("idle_tilled_days")
			var v6_player: Dictionary = v6_data.get("player", {})
			var v6_inventory: Array = v6_player.get("inventory", [])
			for inventory_entry_variant in v6_inventory:
				if inventory_entry_variant is Dictionary:
					(inventory_entry_variant as Dictionary).erase("quality")
			var v6_world: Dictionary = v6_data.get("world", {})
			var v6_drops: Array = v6_world.get("drops", [])
			for drop_entry_variant in v6_drops:
				if drop_entry_variant is Dictionary:
					var drop_entry := drop_entry_variant as Dictionary
					drop_entry.erase("natural_spawn")
					drop_entry.erase("spawned_day")
					drop_entry.erase("expires_after_days")
			var v6_write := FileAccess.open("user://savegame.json", FileAccess.WRITE)
			_check(v6_write != null, "synthetic v6 save can be written")
			if v6_write != null:
				v6_write.store_string(JSON.stringify(v6_data))
				v6_write.close()
				_check(save_manager.load_game(), "additive v6 save loads successfully in save v7")

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
			var has_fertilizer_offer := false
			for shop_offer in offers:
				if shop_offer != null and shop_offer.id == &"basic_fertilizer":
					has_fertilizer_offer = true
					break
			_check(has_fertilizer_offer, "seed shop always offers basic fertilizer")
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

								player.inventory.clear_all()
								player.inventory.seed_slot(
									0,
									harvest_item,
									2,
									InventorySlotData.Quality.GOLD
								)
								player.inventory.set_selected_slot(0)
								player.global_position = shipping_bin.global_position
								var gold_quality_message := shipping_bin.interact(player)
								var gold_unit_price := InventorySlotData.get_adjusted_sell_price(
									harvest_item.sell_price,
									InventorySlotData.Quality.GOLD
								)
								var gold_quality_total := gold_unit_price * 2
								_check(gold_quality_message.contains("Ouro"), "shipping message identifies gold quality")
								_check(economy.get_pending_total() == gold_quality_total, "gold quality shipment uses adjusted price")
								var gold_before_quality_sale := int(economy.gold)
								game_clock.sleep_and_start_next_day()
								await get_tree().process_frame
								await get_tree().process_frame
								_check(
									int(economy.gold) == gold_before_quality_sale + gold_quality_total,
									"gold quality shipment pays exact adjusted value"
								)
								_check(economy.get_pending_total() == 0, "quality shipment clears after payout")

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

		var quality_crop := player.inventory.get_definition(&"starter_turnip")
		if quality_crop != null:
			player.inventory.clear_all()
			player.inventory.add_item(quality_crop, 3, InventorySlotData.Quality.NORMAL)
			player.inventory.add_item(quality_crop, 2, InventorySlotData.Quality.SILVER)
			player.inventory.add_item(quality_crop, 1, InventorySlotData.Quality.GOLD)
			_check(player.inventory.get_used_slot_count() == 3, "different qualities occupy separate stacks")
			_check(player.inventory.count_item(quality_crop.id) == 6, "quality stacks still count toward total item amount")
			_check(
				player.inventory.count_item(quality_crop.id, InventorySlotData.Quality.SILVER) == 2,
				"silver quality count stays separate"
			)
			_check(
				player.inventory.count_item(quality_crop.id, InventorySlotData.Quality.GOLD) == 1,
				"gold quality count stays separate"
			)
			player.inventory.organize_slots()
			_check(player.inventory.get_used_slot_count() == 3, "organize does not merge different qualities")
			_check(save_manager.save_game(), "quality inventory save succeeds")
			player.inventory.clear_all()
			_check(save_manager.load_game(), "quality inventory reload succeeds")
			_check(
				player.inventory.count_item(quality_crop.id, InventorySlotData.Quality.SILVER) == 2,
				"silver quality survives save and load"
			)
			_check(
				player.inventory.count_item(quality_crop.id, InventorySlotData.Quality.GOLD) == 1,
				"gold quality survives save and load"
			)

	if player != null:
		# World drops must remain when inventory is full and collect after space is freed.
		var forage_def := player.inventory.get_definition(&"wild_flower")
		var stone_for_fill := player.inventory.get_definition(&"stone")
		if forage_def != null and stone_for_fill != null:
			for index in range(player.inventory.slots.size()):
				player.inventory.seed_slot(index, stone_for_fill, stone_for_fill.max_stack)
			var test_drop := load("res://scenes/world/item_drop.tscn").instantiate() as ItemDrop
			main.add_child(test_drop)
			test_drop.configure(forage_def.id, 1, forage_def.tint)
			_check(test_drop.try_collect(player.inventory) == 0, "full inventory leaves world drop uncollected")
			_check(test_drop.amount == 1, "blocked pickup preserves world drop amount")
			player.inventory.get_slot(11).clear()
			player.inventory.inventory_changed.emit()
			_check(test_drop.try_collect(player.inventory) == 1, "world drop collects after freeing inventory space")
			await get_tree().process_frame

		# Tool upgrades must consume exact resources once and fail atomically.
		var upgrade_station := main.get_node_or_null("ToolUpgradeStation") as ToolUpgradeStation
		if upgrade_station != null:
			player.inventory.clear_all()
			player.inventory.seed_slot(0, player.starter_pickaxe_item, 1)
			player.inventory.seed_slot(1, player.copper_ore_item, 5)
			player.inventory.set_selected_slot(0)
			player.tools.pickaxe_level = 0
			player.global_position = upgrade_station.global_position
			economy.gold = 500
			var upgrade_message := upgrade_station.interact(player)
			_check(upgrade_message.contains("nivel 1"), "pickaxe level one upgrade succeeds")
			_check(player.tools.pickaxe_level == 1, "pickaxe upgrade changes exactly one level")
			_check(player.inventory.count_item(&"copper_ore") == 0, "pickaxe upgrade consumes exact copper")
			_check(int(economy.gold) == 300, "pickaxe upgrade consumes exact gold")
			var failed_gold_before := int(economy.gold)
			var failed_level_before := player.tools.pickaxe_level
			upgrade_station.interact(player)
			_check(int(economy.gold) == failed_gold_before, "failed upgrade does not spend gold")
			_check(player.tools.pickaxe_level == failed_level_before, "failed upgrade does not change tool level")

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

	# Rain must replace manual watering for crop growth.
	if player != null and farm != null:
		var rain_crop := player.starter_seed_item.crop_to_plant
		var rain_cell := Vector2i(1, 3)
		if rain_crop != null and rain_crop.can_grow_in_season(game_clock.season_index):
			farm.apply_hoe([rain_cell])
			_check(farm.plant_crop(rain_cell, rain_crop), "rain test crop can be planted")
			var rain_data := farm.get_cell(rain_cell)
			var weather_before_rain_test := int(WeatherManager.current_weather)
			WeatherManager.current_weather = WeatherManager.Weather.RAIN
			farm.call("_apply_current_weather")
			_check(rain_data.watered_today, "rain waters planted tilled soil")
			var rain_growth_before := rain_data.growth_days_completed
			game_clock.sleep_and_start_next_day()
			await get_tree().process_frame
			await get_tree().process_frame
			_check(
				rain_data.growth_days_completed == rain_growth_before + 1,
				"rain-watered crop advances growth at day end"
			)
			WeatherManager.current_weather = weather_before_rain_test

	# Seven consecutive day rollovers must remain playable and autosaved.
	var seven_day_start := int(game_clock.day)
	for _index in range(7):
		game_clock.sleep_and_start_next_day()
		await get_tree().process_frame
		await get_tree().process_frame
		_check(not get_tree().paused, "day rollover never leaves game paused")
		_check(save_manager.has_save(), "day rollover keeps a valid save")
	_check(int(game_clock.day) == seven_day_start + 7, "seven consecutive days advance without softlock")

	# Calendar, season changes, crop withering and seasonal shop must stay coherent.
	if player != null and farm != null:
		var season_crop := player.starter_seed_item.crop_to_plant
		var season_cell := Vector2i(3, 2)
		farm.apply_hoe([season_cell])
		if season_crop != null:
			farm.plant_crop(season_cell, season_crop)

	game_clock.load_save_data({
		"day": 28,
		"minute_of_day": GameClock.START_MINUTE,
		"year": 1,
		"season_index": GameClock.Season.SPRING,
		"day_of_season": 28,
	})
	WeatherManager.refresh_for_current_day()
	var spring_weather := int(WeatherManager.current_weather)
	WeatherManager.refresh_for_current_day()
	_check(int(WeatherManager.current_weather) == spring_weather, "weather is deterministic for the same date")
	game_clock.sleep_and_start_next_day()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(game_clock.season_index == GameClock.Season.SUMMER, "spring day 28 advances to summer")
	_check(game_clock.day_of_season == 1, "new season begins on day one")
	if farm != null:
		_check(farm.get_cell(Vector2i(3, 2)).crop == null, "out-of-season spring crop withers in summer")

	var seasonal_shop := main.get_node_or_null("SeedShop") as SeedShop
	if seasonal_shop != null:
		var summer_offers := seasonal_shop.get_current_offers()
		var has_summer_seed := false
		for offer in summer_offers:
			if offer != null and offer.id == &"summer_tomato_seed":
				has_summer_seed = true
				break
		_check(has_summer_seed, "seed shop switches to summer offers")

	# Multi-season crops must survive a compatible season boundary.
	if farm != null:
		var corn_crop := load("res://resources/crops/summer_corn.tres") as CropDefinition
		var corn_cell := Vector2i(4, 2)
		farm.apply_hoe([corn_cell])
		_check(corn_crop != null and corn_crop.can_grow_in_season(GameClock.Season.FALL), "corn supports summer and fall")
		if corn_crop != null:
			_check(farm.plant_crop(corn_cell, corn_crop), "multi-season corn can be planted in summer")
			game_clock.load_save_data({
				"day": 56,
				"minute_of_day": GameClock.START_MINUTE,
				"year": 1,
				"season_index": GameClock.Season.SUMMER,
				"day_of_season": 28,
			})
			game_clock.sleep_and_start_next_day()
			await get_tree().process_frame
			await get_tree().process_frame
			_check(game_clock.season_index == GameClock.Season.FALL, "summer day 28 advances to fall")
			_check(farm.get_cell(corn_cell).crop == corn_crop, "compatible multi-season crop survives season change")
			if seasonal_shop != null:
				var fall_offers := seasonal_shop.get_current_offers()
				var has_fall_corn_seed := false
				for offer in fall_offers:
					if offer != null and offer.id == &"summer_corn_seed":
						has_fall_corn_seed = true
						break
				_check(has_fall_corn_seed, "fall shop keeps multi-season corn seed available")

	game_clock.load_save_data({
		"day": 112,
		"minute_of_day": GameClock.START_MINUTE,
		"year": 1,
		"season_index": GameClock.Season.WINTER,
		"day_of_season": 28,
	})
	game_clock.sleep_and_start_next_day()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(game_clock.year == 2, "winter day 28 advances to next year")
	_check(game_clock.season_index == GameClock.Season.SPRING, "new year returns to spring")
	_check(game_clock.day_of_season == 1, "new year starts on spring day one")

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
