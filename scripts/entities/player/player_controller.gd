class_name PlayerController
extends CharacterBody2D

const PLAYER_MOVE_TEXTURE: Texture2D = preload("res://assets/sprout_lands/characters/player_premium.png")
const PLAYER_ACTION_TEXTURE: Texture2D = preload("res://assets/sprout_lands/characters/player_actions.png")
const FEEDBACK_BURST_SCENE := preload("res://scenes/vfx/world_feedback_burst.tscn")
const WORLD_FORAGE_DEFINITIONS: Array[ItemDefinition] = [
	preload("res://resources/items/wild_flower.tres"),
	preload("res://resources/items/wild_berry.tres"),
	preload("res://resources/items/wild_mushroom.tres"),
	preload("res://resources/items/wild_root.tres"),
]

signal feedback_requested(text: String)
signal shop_requested(shop: SeedShop)

@export var move_speed: float = 165.0
@export var acceleration: float = 1050.0
@export var deceleration: float = 1350.0
@export_range(0.25, 1.0, 0.05) var charge_move_multiplier: float = 0.80
@export var starting_seed_amount: int = 15
@export var movement_animation_fps: float = 8.0
@export var tool_action_animation_fps: float = 10.0

@export_group("Starting Items")
@export var starter_hoe_item: ItemDefinition
@export var starter_watering_can_item: ItemDefinition
@export var starter_axe_item: ItemDefinition
@export var starter_pickaxe_item: ItemDefinition
@export var starter_seed_item: ItemDefinition
@export var starter_crop_item: ItemDefinition
@export var wood_item: ItemDefinition
@export var stone_item: ItemDefinition
@export var slime_gel_item: ItemDefinition
@export var copper_ore_item: ItemDefinition
@export var summer_seed_item: ItemDefinition
@export var summer_crop_item: ItemDefinition
@export var fall_seed_item: ItemDefinition
@export var fall_crop_item: ItemDefinition
@export var winter_seed_item: ItemDefinition
@export var winter_crop_item: ItemDefinition
@export var spring_berry_seed_item: ItemDefinition
@export var spring_berry_crop_item: ItemDefinition
@export var summer_corn_seed_item: ItemDefinition
@export var summer_corn_crop_item: ItemDefinition
@export var fall_eggplant_seed_item: ItemDefinition
@export var fall_eggplant_crop_item: ItemDefinition
@export var winter_kale_seed_item: ItemDefinition
@export var winter_kale_crop_item: ItemDefinition
@export var slime_crystal_item: ItemDefinition
@export var iron_ore_item: ItemDefinition
@export var silver_ore_item: ItemDefinition
@export var gold_ore_item: ItemDefinition

@onready var energy: EnergyComponent = $Energy
@onready var tools: ToolController = $ToolController
@onready var inventory: InventoryComponent = $Inventory
@onready var visual: Sprite2D = $Visual

var facing: Vector2i = Vector2i.DOWN
var farm_field: FarmField
var _action_flash_cells: Array[Vector2i] = []
var _action_flash_time: float = 0.0
var _movement_anim_time: float = 0.0
var _tool_action_active: bool = false
var _tool_action_elapsed: float = 0.0
var _tool_action_type: int = -1

func _ready() -> void:
	add_to_group("player")

	if not GameClock.day_started.is_connected(_on_day_started):
		GameClock.day_started.connect(_on_day_started)

	inventory.selected_slot_changed.connect(_on_selected_slot_changed)
	_seed_starting_inventory()
	call_deferred("_find_world_systems")
	_sync_selected_item()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if farm_field == null:
		_find_world_systems()

	var input_direction := Vector2.ZERO
	if not _tool_action_active:
		input_direction = _read_movement_input()
		if input_direction != Vector2.ZERO:
			_update_facing(input_direction)

		var speed_multiplier := charge_move_multiplier if tools.is_charging else 1.0
		var target_velocity := input_direction.normalized() * move_speed * speed_multiplier
		var rate := acceleration if input_direction != Vector2.ZERO else deceleration
		velocity = velocity.move_toward(target_velocity, rate * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)

	tools.update_charge(delta)

	if _tool_action_active:
		_update_tool_action_animation(delta)
	else:
		_update_visual_animation(delta, input_direction)

	if _action_flash_time > 0.0:
		_action_flash_time -= delta

	move_and_slide()
	_collect_nearby_drops()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if _tool_action_active:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			inventory.set_selected_slot(inventory.selected_slot - 1)
			get_viewport().set_input_as_handled()
			return

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			inventory.set_selected_slot(inventory.selected_slot + 1)
			get_viewport().set_input_as_handled()
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_primary_action_pressed()
			else:
				_primary_action_released()
			get_viewport().set_input_as_handled()
			return

		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_interact()
			get_viewport().set_input_as_handled()
			return

	if not (event is InputEventKey) or event.echo:
		return

	if event.pressed:
		var hotbar_index := _hotbar_index_from_key(event.physical_keycode)
		if hotbar_index >= 0:
			inventory.set_selected_slot(hotbar_index)
			return

		match event.physical_keycode:
			KEY_SPACE:
				_primary_action_pressed()
			KEY_E:
				_interact()
	else:
		if event.physical_keycode == KEY_SPACE:
			_primary_action_released()

func restore_after_sleep() -> void:
	energy.restore_full()

func refill_watering_can() -> void:
	tools.refill_water()

func get_target_cells() -> Array[Vector2i]:
	if farm_field == null:
		return []

	var stack := inventory.get_selected_stack()
	if stack == null or stack.is_empty():
		return []

	var origin := farm_field.world_to_cell(global_position)

	if stack.item.kind == ItemDefinition.ItemKind.SEED:
		return farm_field.filter_valid_cells(
			GridTargeting.get_tool_cells(origin, facing, 0)
		)

	if stack.item.kind != ItemDefinition.ItemKind.TOOL:
		return []

	var stage := tools.charge_stage if tools.is_charging else 0
	return farm_field.filter_valid_cells(
		GridTargeting.get_tool_cells(origin, facing, stage)
	)

func get_selected_item_name() -> String:
	var stack := inventory.get_selected_stack()
	if stack == null or stack.is_empty():
		return "Vazio"
	return stack.item.display_name

func _primary_action_pressed() -> void:
	var stack := inventory.get_selected_stack()
	if stack == null or stack.is_empty():
		feedback_requested.emit("Slot vazio.")
		return

	match stack.item.kind:
		ItemDefinition.ItemKind.TOOL:
			tools.select_tool(stack.item.tool_type)
			if tools.is_chargeable_tool(stack.item.tool_type):
				tools.begin_charge()
			else:
				_use_instant_tool(stack.item.tool_type)
		ItemDefinition.ItemKind.SEED:
			_plant_selected_seed(stack)
		_:
			feedback_requested.emit("%s ainda nao possui uso direto." % stack.item.display_name)

func _primary_action_released() -> void:
	if tools.is_charging:
		_release_tool()

func _release_tool() -> void:
	var result := tools.release_charge()
	if result.is_empty() or farm_field == null:
		return

	var tool := int(result["tool"])
	var stage := int(result["stage"])
	var origin := farm_field.world_to_cell(global_position)
	var cells := farm_field.filter_valid_cells(
		GridTargeting.get_tool_cells(origin, facing, stage)
	)

	if cells.is_empty():
		feedback_requested.emit("Nenhum tile valido.")
		return

	var energy_cost := tools.get_energy_cost(stage, tool)
	if not energy.can_spend(energy_cost):
		feedback_requested.emit("Energia insuficiente.")
		return

	if tool == ToolController.ToolType.WATERING_CAN and not tools.can_spend_water(stage):
		feedback_requested.emit("O regador esta sem agua suficiente.")
		return

	var affected := 0

	match tool:
		ToolController.ToolType.HOE:
			affected = farm_field.apply_hoe(cells)
		ToolController.ToolType.WATERING_CAN:
			affected = farm_field.apply_water(cells)

	if affected <= 0:
		feedback_requested.emit("Nada para fazer aqui.")
		return

	energy.spend(energy_cost)

	if tool == ToolController.ToolType.WATERING_CAN:
		tools.spend_water(stage)

	_flash_cells(cells)

	var burst_color := Color(0.64, 0.42, 0.22)
	if tool == ToolController.ToolType.WATERING_CAN:
		burst_color = Color(0.36, 0.72, 1.0)

	for cell in cells:
		_spawn_feedback_burst(farm_field.cell_to_world(cell), burst_color, 5, 34.0)

	_start_tool_action(tool)

func _use_instant_tool(tool_type: int) -> void:
	var target := _find_resource_target()
	if target == null:
		feedback_requested.emit("Nenhum recurso ao alcance.")
		return

	var energy_cost := tools.get_energy_cost(0, tool_type)
	if not energy.can_spend(energy_cost):
		feedback_requested.emit("Energia insuficiente.")
		return

	var level := tools.get_tool_level(tool_type)
	var result := target.apply_tool_hit(tool_type, level)

	if not bool(result.get("success", false)):
		feedback_requested.emit(str(result.get("reason", "Nao foi possivel usar a ferramenta.")))
		return

	energy.spend(energy_cost)

	var remaining := int(result.get("remaining_hits", 0))
	if bool(result.get("depleted", false)):
		feedback_requested.emit("Recurso quebrado!")
	else:
		feedback_requested.emit("Golpe acertou. Faltam %d." % remaining)

	_start_tool_action(tool_type)

func _find_resource_target() -> HarvestableResource:
	var target_point := global_position + Vector2(facing) * 34.0
	var best: HarvestableResource = null
	var best_distance := 38.0

	for node in get_tree().get_nodes_in_group("harvestable_resource"):
		var resource := node as HarvestableResource
		if resource == null:
			continue

		var distance := resource.global_position.distance_to(target_point)
		if distance <= best_distance:
			best = resource
			best_distance = distance

	return best

func _collect_nearby_drops() -> void:
	for node in get_tree().get_nodes_in_group("world_drop"):
		var drop := node as ItemDrop
		if drop == null or not drop.can_pickup(global_position):
			continue

		var collected := drop.try_collect(inventory)
		if collected > 0:
			var definition := inventory.get_definition(drop.item_id)
			var item_name := definition.display_name if definition != null else str(drop.item_id)
			feedback_requested.emit("Coletou %s x%d." % [item_name, collected])

func _plant_selected_seed(stack: InventorySlotData) -> void:
	if farm_field == null or stack.item.crop_to_plant == null:
		return

	var seed_id := stack.item.id
	var crop := stack.item.crop_to_plant
	var target := _get_front_cell()

	if not farm_field.is_valid_cell(target):
		feedback_requested.emit("Nao da para plantar aqui.")
		return

	if not farm_field.can_plant(target):
		feedback_requested.emit(farm_field.get_cell_hint(target))
		return

	if not farm_field.can_plant_crop_now(crop):
		feedback_requested.emit(farm_field.get_crop_season_hint(crop))
		return

	if not farm_field.plant_crop(target, crop):
		return

	inventory.remove_item(seed_id, 1)
	feedback_requested.emit("Plantou %s." % crop.display_name)
	_flash_cells([target])
	_spawn_feedback_burst(
		farm_field.cell_to_world(target),
		Color(0.52, 0.86, 0.36),
		7,
		38.0
	)

func _interact() -> void:
	for node in get_tree().get_nodes_in_group("sleep_spot"):
		var sleep_spot := node as SleepSpot
		if sleep_spot != null and sleep_spot.can_interact(global_position):
			var sleep_message := sleep_spot.interact(self)
			if not sleep_message.is_empty():
				feedback_requested.emit(sleep_message)
				return

	for node in get_tree().get_nodes_in_group("water_source"):
		var water_source := node as WaterSource
		if water_source != null and water_source.can_interact(global_position):
			var water_message := water_source.interact(self)
			if not water_message.is_empty():
				feedback_requested.emit(water_message)
				return

	for node in get_tree().get_nodes_in_group("tool_upgrade_station"):
		var station := node as ToolUpgradeStation
		if station != null and station.can_interact(global_position):
			var upgrade_message := station.interact(self)
			if not upgrade_message.is_empty():
				feedback_requested.emit(upgrade_message)
				return

	for node in get_tree().get_nodes_in_group("shipping_bin"):
		var shipping_bin := node as ShippingBin
		if shipping_bin != null and shipping_bin.can_interact(global_position):
			var shipping_message := shipping_bin.interact(self)
			if not shipping_message.is_empty():
				feedback_requested.emit(shipping_message)
				return

	for node in get_tree().get_nodes_in_group("seed_shop"):
		var seed_shop := node as SeedShop
		if seed_shop != null and seed_shop.can_interact(global_position):
			shop_requested.emit(seed_shop)
			return

	for node in get_tree().get_nodes_in_group("slime_crystallizer"):
		var crystallizer := node as SlimeCrystallizer
		if crystallizer != null and crystallizer.can_interact(global_position):
			var machine_message := crystallizer.interact(self)
			if not machine_message.is_empty():
				feedback_requested.emit(machine_message)
				return

	for node in get_tree().get_nodes_in_group("world_transition"):
		var transition := node as WorldTransition
		if transition != null and transition.can_interact(global_position):
			var transition_message := transition.interact(self)
			if not transition_message.is_empty():
				feedback_requested.emit(transition_message)
				return

	for node in get_tree().get_nodes_in_group("slime_breeding_nest"):
		var nest := node as SlimeBreedingNest
		if nest != null and nest.can_interact(global_position):
			var breeding_message := nest.interact(self)
			if not breeding_message.is_empty():
				feedback_requested.emit(breeding_message)
				return

	var slime := _find_interactable_slime()
	if slime != null:
		var slime_message := slime.interact(self)
		if not slime_message.is_empty():
			feedback_requested.emit(slime_message)
			return

	if farm_field == null:
		return

	var target := _get_front_cell()
	if not farm_field.is_valid_cell(target):
		return

	if farm_field.can_harvest(target):
		var cell_data := farm_field.get_cell(target)
		if cell_data == null or cell_data.crop == null:
			return

		var harvest_item := inventory.get_definition(cell_data.crop.harvest_item_id)
		if harvest_item == null:
			feedback_requested.emit("Item de colheita nao registrado.")
			return

		var expected_amount := farm_field.get_harvest_amount(target)
		if expected_amount <= 0:
			return

		if not inventory.can_add_item(harvest_item, expected_amount):
			feedback_requested.emit("Inventario cheio.")
			return

		var harvest := farm_field.harvest_cell(target)
		if harvest.is_empty():
			return

		var amount := int(harvest["amount"])
		inventory.add_item(harvest_item, amount)
		feedback_requested.emit("Colheu %s x%d." % [harvest_item.display_name, amount])
		_flash_cells([target])
		_spawn_feedback_burst(
			farm_field.cell_to_world(target),
			harvest_item.tint.lightened(0.12),
			10,
			56.0
		)
		return

	feedback_requested.emit(farm_field.get_cell_hint(target))

func _find_interactable_slime() -> SlimeCreature:
	var nearest: SlimeCreature = null
	var nearest_distance := INF

	for node in get_tree().get_nodes_in_group("slime_creature"):
		var slime := node as SlimeCreature
		if slime == null or not slime.can_interact(global_position):
			continue

		var distance := global_position.distance_to(slime.global_position)
		if distance < nearest_distance:
			nearest = slime
			nearest_distance = distance

	return nearest

func _seed_starting_inventory() -> void:
	var definitions: Array[ItemDefinition] = [
		starter_hoe_item,
		starter_watering_can_item,
		starter_axe_item,
		starter_pickaxe_item,
		starter_seed_item,
		starter_crop_item,
		wood_item,
		stone_item,
		slime_gel_item,
		copper_ore_item,
		summer_seed_item,
		summer_crop_item,
		fall_seed_item,
		fall_crop_item,
		winter_seed_item,
		winter_crop_item,
		spring_berry_seed_item,
		spring_berry_crop_item,
		summer_corn_seed_item,
		summer_corn_crop_item,
		fall_eggplant_seed_item,
		fall_eggplant_crop_item,
		winter_kale_seed_item,
		winter_kale_crop_item,
		slime_crystal_item,
		iron_ore_item,
		silver_ore_item,
		gold_ore_item,
	]

	for definition in WORLD_FORAGE_DEFINITIONS:
		definitions.append(definition)

	for definition in definitions:
		inventory.register_definition(definition)

	if starter_hoe_item != null:
		inventory.seed_slot(0, starter_hoe_item, 1)
	if starter_watering_can_item != null:
		inventory.seed_slot(1, starter_watering_can_item, 1)
	if starter_axe_item != null:
		inventory.seed_slot(2, starter_axe_item, 1)
	if starter_pickaxe_item != null:
		inventory.seed_slot(3, starter_pickaxe_item, 1)
	if starter_seed_item != null:
		inventory.seed_slot(4, starter_seed_item, starting_seed_amount)

func _sync_selected_item() -> void:
	var stack := inventory.get_selected_stack()
	if stack != null and not stack.is_empty() and stack.item.kind == ItemDefinition.ItemKind.TOOL:
		tools.select_tool(stack.item.tool_type)
	else:
		tools.cancel_charge()
	queue_redraw()

func _on_selected_slot_changed(_index: int) -> void:
	_sync_selected_item()

func _get_front_cell() -> Vector2i:
	var origin := farm_field.world_to_cell(global_position)
	var cells := GridTargeting.get_tool_cells(origin, facing, 0)
	return cells[0] if not cells.is_empty() else origin

func _spawn_feedback_burst(
	world_position: Vector2,
	color: Color,
	count: int = 8,
	burst_speed: float = 48.0
) -> void:
	if get_parent() == null:
		return

	var burst := FEEDBACK_BURST_SCENE.instantiate() as WorldFeedbackBurst
	if burst == null:
		return

	get_parent().add_child(burst)
	burst.global_position = world_position
	burst.configure(color, count, burst_speed)

func _flash_cells(cells: Array[Vector2i]) -> void:
	_action_flash_cells = cells.duplicate()
	_action_flash_time = 0.16
	queue_redraw()

func _hotbar_index_from_key(keycode: Key) -> int:
	match keycode:
		KEY_1:
			return 0
		KEY_2:
			return 1
		KEY_3:
			return 2
		KEY_4:
			return 3
		KEY_5:
			return 4
		KEY_6:
			return 5
		KEY_7:
			return 6
		KEY_8:
			return 7
		KEY_9:
			return 8
		KEY_0:
			return 9
		_:
			return -1

func _read_movement_input() -> Vector2:
	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0

	return direction

func _update_facing(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		facing = Vector2i.RIGHT if direction.x > 0.0 else Vector2i.LEFT
	elif not is_zero_approx(direction.y):
		facing = Vector2i.DOWN if direction.y > 0.0 else Vector2i.UP

func _start_tool_action(tool_type: int) -> void:
	var row := _get_tool_action_row(tool_type)
	if row < 0:
		return

	_tool_action_active = true
	_tool_action_elapsed = 0.0
	_tool_action_type = tool_type
	velocity = Vector2.ZERO

	visual.texture = PLAYER_ACTION_TEXTURE
	visual.hframes = 3
	visual.vframes = 12
	visual.frame_coords = Vector2i(0, row)

func _update_tool_action_animation(delta: float) -> void:
	if not _tool_action_active or visual == null:
		return

	_tool_action_elapsed += delta
	var row := _get_tool_action_row(_tool_action_type)
	var frame := mini(int(floor(_tool_action_elapsed * tool_action_animation_fps)), 2)
	visual.frame_coords = Vector2i(frame, row)

	var duration := 3.0 / maxf(tool_action_animation_fps, 1.0)
	if _tool_action_elapsed >= duration:
		_finish_tool_action()

func _finish_tool_action() -> void:
	_tool_action_active = false
	_tool_action_elapsed = 0.0
	_tool_action_type = -1

	visual.texture = PLAYER_MOVE_TEXTURE
	visual.hframes = 8
	visual.vframes = 24
	visual.frame_coords = Vector2i(0, _get_facing_animation_row())

func _get_tool_action_row(tool_type: int) -> int:
	var base_row := -1

	match tool_type:
		ToolController.ToolType.AXE:
			base_row = 0
		ToolController.ToolType.HOE, ToolController.ToolType.PICKAXE:
			base_row = 4
		ToolController.ToolType.WATERING_CAN:
			base_row = 8
		_:
			return -1

	return base_row + _get_facing_direction_offset()

func _get_facing_direction_offset() -> int:
	match facing:
		Vector2i.DOWN:
			return 0
		Vector2i.UP:
			return 1
		Vector2i.LEFT:
			return 2
		Vector2i.RIGHT:
			return 3
		_:
			return 0

func _update_visual_animation(delta: float, input_direction: Vector2) -> void:
	if visual == null:
		return

	var row := _get_facing_animation_row()

	if input_direction == Vector2.ZERO:
		_movement_anim_time = 0.0
		visual.frame_coords = Vector2i(0, row)
		return

	_movement_anim_time += delta
	var frame := int(floor(_movement_anim_time * movement_animation_fps)) % 8
	visual.frame_coords = Vector2i(frame, row)

func _get_facing_animation_row() -> int:
	match facing:
		Vector2i.DOWN:
			return 0
		Vector2i.UP:
			return 1
		Vector2i.LEFT:
			return 2
		Vector2i.RIGHT:
			return 3
		_:
			return 0

func _find_world_systems() -> void:
	farm_field = get_tree().get_first_node_in_group("farm_field") as FarmField

func _on_day_started(_day: int) -> void:
	energy.restore_full()

func _draw() -> void:
	_draw_target_preview()
	_draw_action_flash()

func _draw_target_preview() -> void:
	if _tool_action_active:
		return
	if farm_field == null:
		return

	var stack := inventory.get_selected_stack()
	if stack == null or stack.is_empty():
		return

	var preview_color := Color(0.75, 0.48, 0.22, 0.30)

	if stack.item.kind == ItemDefinition.ItemKind.SEED:
		preview_color = Color(0.55, 0.86, 0.32, 0.30)
	elif stack.item.kind == ItemDefinition.ItemKind.TOOL:
		match stack.item.tool_type:
			ToolController.ToolType.WATERING_CAN:
				preview_color = Color(0.29, 0.69, 1.0, 0.30)
			ToolController.ToolType.AXE, ToolController.ToolType.PICKAXE:
				preview_color = Color(0.95, 0.72, 0.28, 0.24)
	else:
		return

	for cell in get_target_cells():
		var center_global := farm_field.cell_to_world(cell)
		var center_local := to_local(center_global)
		var size := Vector2(farm_field.cell_size, farm_field.cell_size)
		var rect := Rect2(center_local - size * 0.5, size)
		draw_rect(rect, preview_color, true)
		draw_rect(rect, preview_color.lightened(0.35), false, 2.0)

func _draw_action_flash() -> void:
	if farm_field == null or _action_flash_time <= 0.0:
		return

	for cell in _action_flash_cells:
		var center_local := to_local(farm_field.cell_to_world(cell))
		draw_circle(center_local, 8.0, Color(1.0, 1.0, 1.0, 0.45))

func get_save_data() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y],
		"facing": [facing.x, facing.y],
		"energy": energy.current_energy,
		"selected_slot": inventory.selected_slot,
		"inventory": inventory.get_save_data(),
		"tools": tools.get_save_data(),
	}

func load_save_data(data: Dictionary) -> void:
	var saved_position: Array = data.get("position", [])
	if saved_position.size() >= 2:
		global_position = Vector2(float(saved_position[0]), float(saved_position[1]))

	var saved_facing: Array = data.get("facing", [])
	if saved_facing.size() >= 2:
		facing = Vector2i(int(saved_facing[0]), int(saved_facing[1]))
		if facing == Vector2i.ZERO:
			facing = Vector2i.DOWN

	energy.set_current_energy(float(data.get("energy", energy.maximum_energy)))

	var inventory_data: Array = data.get("inventory", [])
	inventory.load_save_data(inventory_data)
	inventory.set_selected_slot(int(data.get("selected_slot", 0)))

	var tool_data: Dictionary = data.get("tools", {})
	tools.load_save_data(tool_data)
	_sync_selected_item()

	_tool_action_active = false
	_finish_tool_action()
	queue_redraw()
