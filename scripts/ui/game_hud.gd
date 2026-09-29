extends CanvasLayer

const TOOL_ATLAS: Texture2D = preload("res://assets/sprout_lands/tools/tools.png")
const ITEM_ATLAS: Texture2D = preload("res://assets/sprout_lands/items/all_items.png")
const INVENTORY_SLOT_WIDGET := preload("res://scripts/ui/inventory_slot_widget.gd")

@onready var status_label: Label = $StatusPanel/Margin/Status
@onready var hotbar_container: HBoxContainer = $HotbarPanel/Margin/Hotbar
@onready var help_label: Label = $HelpPanel/Margin/Help
@onready var feedback_label: Label = $Feedback
@onready var calendar_panel: PanelContainer = $CalendarPanel
@onready var calendar_title: Label = $CalendarPanel/Margin/Content/Title
@onready var calendar_body: Label = $CalendarPanel/Margin/Content/Body
@onready var slime_panel: PanelContainer = $SlimePanel
@onready var slime_status: Label = $SlimePanel/Margin/Status
@onready var bestiary_panel: PanelContainer = $BestiaryPanel
@onready var bestiary_title: Label = $BestiaryPanel/Margin/Content/Title
@onready var bestiary_body: Label = $BestiaryPanel/Margin/Content/Body
@onready var habitat_panel: PanelContainer = $HabitatPanel
@onready var habitat_title: Label = $HabitatPanel/Margin/Content/Title
@onready var habitat_body: Label = $HabitatPanel/Margin/Content/Body
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var inventory_title: Label = $InventoryPanel/Margin/Content/Title
@onready var inventory_summary: Label = $InventoryPanel/Margin/Content/Summary
@onready var inventory_grid: GridContainer = $InventoryPanel/Margin/Content/Grid
@onready var inventory_detail: Label = $InventoryPanel/Margin/Content/Detail
@onready var inventory_organize_button: Button = $InventoryPanel/Margin/Content/Actions/OrganizeButton
@onready var inventory_close_button: Button = $InventoryPanel/Margin/Content/Actions/CloseButton
@onready var shop_panel: PanelContainer = $ShopPanel
@onready var shop_title: Label = $ShopPanel/Margin/Content/Title
@onready var shop_balance: Label = $ShopPanel/Margin/Content/Balance
@onready var shop_offers: VBoxContainer = $ShopPanel/Margin/Content/Offers
@onready var shop_close_button: Button = $ShopPanel/Margin/Content/CloseButton
@onready var machine_panel: PanelContainer = $MachinePanel
@onready var machine_status: Label = $MachinePanel/Margin/Status
@onready var mine_panel: PanelContainer = $MinePanel
@onready var mine_status: Label = $MinePanel/Margin/Status

var player: PlayerController
var _feedback_time_left: float = 0.0
var _hotbar_built: bool = false
var _slot_panels: Array[PanelContainer] = []
var _slot_icons: Array[TextureRect] = []
var _slot_names: Array[Label] = []
var _slot_amounts: Array[Label] = []
var _inventory_built: bool = false
var _inventory_slot_widgets: Array[InventorySlotWidget] = []
var _pending_split_source: int = -1
var _active_shop: SeedShop

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_bind_player")
	help_label.text = "WASD mover | 1-0/scroll hotbar | clique/ESPACO usar | E interagir | I inventario | C calendario | B bestiario | H habitat"
	calendar_panel.visible = false
	bestiary_panel.visible = false
	habitat_panel.visible = false
	inventory_panel.visible = false
	shop_panel.visible = false
	machine_panel.visible = false
	mine_panel.visible = false

	inventory_organize_button.pressed.connect(_on_inventory_organize_pressed)
	inventory_close_button.pressed.connect(_close_inventory)
	shop_close_button.pressed.connect(_close_shop)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_C:
				_toggle_calendar()
				get_viewport().set_input_as_handled()
			KEY_B:
				_toggle_bestiary()
				get_viewport().set_input_as_handled()
			KEY_H:
				_toggle_habitat()
				get_viewport().set_input_as_handled()
			KEY_I:
				_toggle_inventory()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				if _any_menu_open():
					_close_all_menus()
					get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if player == null:
		_bind_player()

	if _feedback_time_left > 0.0:
		_feedback_time_left -= delta
		if _feedback_time_left <= 0.0:
			feedback_label.text = ""

	_refresh_status()
	_refresh_hotbar()
	_refresh_nearby_slime()
	_refresh_nearby_machine()
	_refresh_mine_status()

func _bind_player() -> void:
	player = get_tree().get_first_node_in_group("player") as PlayerController
	if player == null:
		return

	if not player.feedback_requested.is_connected(_show_feedback):
		player.feedback_requested.connect(_show_feedback)

	if not player.shop_requested.is_connected(_open_shop):
		player.shop_requested.connect(_open_shop)

	if not player.inventory.inventory_changed.is_connected(_on_inventory_changed):
		player.inventory.inventory_changed.connect(_on_inventory_changed)

	if not _hotbar_built:
		_build_hotbar()
	if not _inventory_built:
		_build_inventory_panel()

	_refresh_inventory_panel()

func _build_hotbar() -> void:
	if player == null:
		return

	for child in hotbar_container.get_children():
		child.queue_free()

	_slot_panels.clear()
	_slot_icons.clear()
	_slot_names.clear()
	_slot_amounts.clear()

	for index in range(player.inventory.slots.size()):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(66, 72)
		hotbar_container.add_child(panel)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_top", 3)
		margin.add_theme_constant_override("margin_right", 4)
		margin.add_theme_constant_override("margin_bottom", 3)
		panel.add_child(margin)

		var column := VBoxContainer.new()
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		margin.add_child(column)

		var key_label := Label.new()
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.add_theme_font_size_override("font_size", 10)
		key_label.text = _slot_key_text(index)
		column.add_child(key_label)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		column.add_child(icon)

		var name_label := Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.custom_minimum_size.x = 56
		column.add_child(name_label)

		var amount_label := Label.new()
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		amount_label.add_theme_font_size_override("font_size", 10)
		panel.add_child(amount_label)
		amount_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		amount_label.offset_right = -5.0
		amount_label.offset_bottom = -4.0
		amount_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

		_slot_panels.append(panel)
		_slot_icons.append(icon)
		_slot_names.append(name_label)
		_slot_amounts.append(amount_label)

	_hotbar_built = true

func _refresh_status() -> void:
	if player == null:
		status_label.text = "Carregando..."
		return

	var charge_text := ""
	if player.tools.is_charging:
		charge_text = " | Carga %d" % player.tools.charge_stage

	var event_text := ""
	var current_event := CalendarEvents.get_current_event_name()
	if not current_event.is_empty():
		event_text = "\nEvento: %s" % current_event

	var tool_level_text := ""
	var water_text := ""
	var selected := player.inventory.get_selected_stack()
	if selected != null and not selected.is_empty():
		if selected.item.kind == ItemDefinition.ItemKind.TOOL:
			tool_level_text = " · Nv.%d" % player.tools.get_tool_level(selected.item.tool_type)

			if selected.item.tool_type == ToolController.ToolType.WATERING_CAN:
				water_text = "\nAgua: %d / %d" % [
					player.tools.current_water,
					player.tools.get_water_capacity(),
				]

	status_label.text = "%s  %s\nClima: %s · Amanha: %s%s\nOuro: %dg · Remessa: %dg\nEnergia: %.0f / %.0f\nSelecionado: %s%s%s%s" % [
		GameClock.get_date_text(),
		GameClock.get_time_text(),
		WeatherManager.get_weather_name(),
		WeatherManager.get_tomorrow_weather_name(),
		event_text,
		Economy.gold,
		Economy.get_pending_total(),
		player.energy.current_energy,
		player.energy.maximum_energy,
		player.get_selected_item_name(),
		tool_level_text,
		charge_text,
		water_text,
	]

func _refresh_hotbar() -> void:
	if player == null or not _hotbar_built:
		return

	for index in range(player.inventory.slots.size()):
		var slot := player.inventory.get_slot(index)
		var selected := index == player.inventory.selected_slot
		_apply_slot_style(_slot_panels[index], selected)

		if slot == null or slot.is_empty():
			_slot_icons[index].texture = null
			_slot_names[index].text = ""
			_slot_amounts[index].text = ""
			continue

		_slot_icons[index].texture = _get_item_icon(slot.item)
		var quality_marker := InventorySlotData.get_quality_marker(slot.quality)
		_slot_names[index].text = "%s%s" % [slot.item.display_name, quality_marker]
		_slot_amounts[index].text = str(slot.amount) if slot.item.max_stack > 1 else ""

func _get_item_icon(item: ItemDefinition) -> Texture2D:
	if item == null or item.icon_sheet == ItemDefinition.IconSheet.NONE:
		return null

	var atlas_texture := AtlasTexture.new()
	match item.icon_sheet:
		ItemDefinition.IconSheet.TOOLS:
			atlas_texture.atlas = TOOL_ATLAS
		ItemDefinition.IconSheet.ITEMS:
			atlas_texture.atlas = ITEM_ATLAS
		_:
			return null

	var size := item.icon_cell_size
	atlas_texture.region = Rect2(
		Vector2(item.icon_cell.x * size, item.icon_cell.y * size),
		Vector2(size, size)
	)
	return atlas_texture

func _apply_slot_style(panel: PanelContainer, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.08, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.83, 0.34) if selected else Color(0.35, 0.42, 0.34)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)

func _slot_key_text(index: int) -> String:
	if index < 9:
		return str(index + 1)
	if index == 9:
		return "0"
	return "-"

func _show_feedback(text: String) -> void:
	feedback_label.text = text
	_feedback_time_left = 2.2

func _toggle_calendar() -> void:
	var next_visible := not calendar_panel.visible
	bestiary_panel.visible = false
	habitat_panel.visible = false
	inventory_panel.visible = false
	shop_panel.visible = false
	_active_shop = null
	calendar_panel.visible = next_visible
	_update_menu_pause()

	if calendar_panel.visible:
		_refresh_calendar_panel()

func _toggle_bestiary() -> void:
	var next_visible := not bestiary_panel.visible
	calendar_panel.visible = false
	habitat_panel.visible = false
	inventory_panel.visible = false
	shop_panel.visible = false
	_active_shop = null
	bestiary_panel.visible = next_visible
	_update_menu_pause()

	if bestiary_panel.visible:
		_refresh_bestiary_panel()

func _toggle_habitat() -> void:
	var next_visible := not habitat_panel.visible
	calendar_panel.visible = false
	bestiary_panel.visible = false
	inventory_panel.visible = false
	shop_panel.visible = false
	_active_shop = null
	habitat_panel.visible = next_visible
	_update_menu_pause()

	if habitat_panel.visible:
		_refresh_habitat_panel()

func _toggle_inventory() -> void:
	var next_visible := not inventory_panel.visible
	calendar_panel.visible = false
	bestiary_panel.visible = false
	habitat_panel.visible = false
	shop_panel.visible = false
	_active_shop = null
	inventory_panel.visible = next_visible
	_pending_split_source = -1
	_update_menu_pause()

	if inventory_panel.visible:
		_refresh_inventory_panel()

func _close_inventory() -> void:
	inventory_panel.visible = false
	_pending_split_source = -1
	_update_menu_pause()

func _update_menu_pause() -> void:
	get_tree().paused = (
		calendar_panel.visible
		or bestiary_panel.visible
		or habitat_panel.visible
		or inventory_panel.visible
		or shop_panel.visible
	)

func _any_menu_open() -> bool:
	return (
		calendar_panel.visible
		or bestiary_panel.visible
		or habitat_panel.visible
		or inventory_panel.visible
		or shop_panel.visible
	)

func _close_all_menus() -> void:
	calendar_panel.visible = false
	bestiary_panel.visible = false
	habitat_panel.visible = false
	inventory_panel.visible = false
	shop_panel.visible = false
	_active_shop = null
	_pending_split_source = -1
	_update_menu_pause()

func _refresh_calendar_panel() -> void:
	calendar_title.text = "%s · Ano %d" % [
		GameClock.get_season_name(),
		GameClock.year,
	]

	var lines: Array[String] = []
	lines.append("SEG  TER  QUA  QUI  SEX  SAB  DOM")

	for week in range(4):
		var cells: Array[String] = []
		for weekday in range(7):
			var day := week * 7 + weekday + 1
			var marker := "*" if day == GameClock.day_of_season else " "
			var event := CalendarEvents.get_event(GameClock.season_index, day)
			var event_marker := "!" if not event.is_empty() else " "
			cells.append("%s%02d%s" % [marker, day, event_marker])
		lines.append("  ".join(cells))

	lines.append("")
	lines.append("* hoje   ! evento")
	lines.append("")

	var events := CalendarEvents.get_events_for_season(GameClock.season_index)
	for event in events:
		lines.append("Dia %02d · %s" % [
			int(event.get("day", 0)),
			str(event.get("name", "")),
		])

	calendar_body.text = "\n".join(lines)

func _refresh_nearby_slime() -> void:
	if player == null:
		slime_panel.visible = false
		return

	var nearest: SlimeCreature = null
	var nearest_distance := 120.0

	for node in get_tree().get_nodes_in_group("slime_creature"):
		var slime := node as SlimeCreature
		if slime == null:
			continue

		var distance := player.global_position.distance_to(slime.global_position)
		if distance < nearest_distance:
			nearest = slime
			nearest_distance = distance

	if nearest == null:
		slime_panel.visible = false
		return

	slime_panel.visible = true
	slime_status.text = nearest.get_status_text()

func _refresh_bestiary_panel() -> void:
	var individuals := SlimeDiscovery.get_all_individuals()
	var traits := SlimeDiscovery.get_discovered_traits()

	bestiary_title.text = "Bestiario Genetico · %d slimes" % individuals.size()

	var lines: Array[String] = []
	if individuals.is_empty():
		lines.append("Nenhum slime registrado.")
	else:
		for record in individuals:
			lines.append("%s · %s · %s" % [
				str(record.get("display_name", "Slime")),
				str(record.get("species", "Slime")),
				str(record.get("rarity", "Comum")),
			])
			lines.append("  %s · %s" % [
				str(record.get("sex", "")),
				str(record.get("personality", "")),
			])
			lines.append("  Tam %.2f · Met %.2f · Vit %.2f · Prod %.2f" % [
				float(record.get("gene_size", 1.0)),
				float(record.get("gene_metabolism", 1.0)),
				float(record.get("gene_vitality", 1.0)),
				float(record.get("gene_production", 1.0)),
			])

			var rarity_reasons := str(record.get("rarity_reasons", ""))
			if not rarity_reasons.is_empty():
				lines.append("  Motivos: %s" % rarity_reasons)

	lines.append("")
	lines.append("Descobertas geneticas:")
	if traits.is_empty():
		lines.append("  Nenhuma descoberta rara ainda.")
	else:
		for trait_name in traits:
			lines.append("  • %s" % trait_name)

	bestiary_body.text = "\n".join(lines)

func _refresh_habitat_panel() -> void:
	var habitats := get_tree().get_nodes_in_group("slime_habitat")
	if habitats.is_empty():
		habitat_title.text = "Habitat"
		habitat_body.text = "Nenhum habitat construido."
		return

	var habitat := habitats[0] as SlimeHabitat
	if habitat == null:
		habitat_title.text = "Habitat"
		habitat_body.text = "Habitat indisponivel."
		return

	habitat_title.text = habitat.get_status_text()

	var lines: Array[String] = []
	lines.append("Bioma: %s" % habitat.get_biome_name())
	lines.append("Capacidade: %d / %d" % [
		habitat.registered_slimes.size(),
		habitat.capacity,
	])

	var care_total := 0.0
	var attention_count := 0
	for resident in habitat.registered_slimes:
		if resident == null or not is_instance_valid(resident):
			continue
		care_total += resident.get_care_score()
		if resident.get_priority_need_text() not in ["BEM CUIDADO", "PRONTO PARA REPRODUCAO"]:
			attention_count += 1

	var valid_count := maxi(habitat.registered_slimes.size(), 1)
	lines.append("Cuidado medio: %.0f%% · Precisam de atencao: %d" % [
		care_total / float(valid_count),
		attention_count,
	])
	lines.append("")
	lines.append("Moradores:")

	if habitat.registered_slimes.is_empty():
		lines.append("  Nenhum slime registrado.")
	else:
		for slime in habitat.registered_slimes:
			if slime == null or not is_instance_valid(slime):
				continue
			lines.append("  %s · %s · %s" % [
				slime.display_name,
				slime.get_species_name(),
				slime.get_rarity_name(),
			])
			lines.append("    Fome %.0f%% · Humor %.0f%% · Afeto %.0f%%" % [
				slime.satiety,
				slime.happiness,
				slime.affection,
			])
			lines.append("    Acao: %s" % slime.get_priority_need_text())

	lines.append("")
	lines.append("Nascimentos especiais neste bioma:")
	match habitat.biome_type:
		SlimeHabitat.HabitatBiome.GROVE:
			lines.append("  Slime Musgo: Primavera/Outono")
		SlimeHabitat.HabitatBiome.WETLAND:
			lines.append("  Afinidade com chuva")
		SlimeHabitat.HabitatBiome.FROST:
			lines.append("  Afinidade com neve")
		_:
			lines.append("  Nenhuma especie exclusiva do bioma")

	lines.append("Outras condicoes: chuva noturna, neve, sol de Verao e noite profunda.")
	habitat_body.text = "\n".join(lines)


func _build_inventory_panel() -> void:
	if player == null or _inventory_built:
		return

	for child in inventory_grid.get_children():
		child.queue_free()

	_inventory_slot_widgets.clear()

	for index in range(player.inventory.slots.size()):
		var widget := INVENTORY_SLOT_WIDGET.new() as InventorySlotWidget
		inventory_grid.add_child(widget)
		widget.slot_selected.connect(_on_inventory_slot_selected)
		widget.slot_drop_requested.connect(_on_inventory_slot_drop_requested)
		widget.split_requested.connect(_on_inventory_split_requested)
		_inventory_slot_widgets.append(widget)

	_inventory_built = true

func _refresh_inventory_panel() -> void:
	if player == null or not _inventory_built:
		return

	inventory_title.text = "Inventario"
	inventory_summary.text = "%d / %d slots usados · %dg" % [
		player.inventory.get_used_slot_count(),
		player.inventory.slots.size(),
		Economy.gold,
	]

	for index in range(player.inventory.slots.size()):
		var slot := player.inventory.get_slot(index)
		var item: ItemDefinition = null
		var amount := 0
		var texture: Texture2D = null

		if slot != null and not slot.is_empty():
			item = slot.item
			amount = slot.amount
			texture = _get_item_icon(item)

		_inventory_slot_widgets[index].configure(
			index,
			item,
			amount,
			texture,
			index == player.inventory.selected_slot,
			slot.quality if slot != null and not slot.is_empty() else InventorySlotData.Quality.NORMAL
		)

	_refresh_inventory_detail()

func _refresh_inventory_detail() -> void:
	if player == null:
		inventory_detail.text = ""
		return

	var stack := player.inventory.get_selected_stack()
	if stack == null or stack.is_empty():
		inventory_detail.text = "Slot selecionado vazio."
		return

	var item := stack.item
	var details: Array[String] = []
	details.append("%s · x%d" % [item.display_name, stack.amount])
	if stack.quality > InventorySlotData.Quality.NORMAL:
		details.append("Qualidade: %s" % InventorySlotData.get_quality_name(stack.quality))
	details.append("Tipo: %s" % _item_kind_name(item.kind))

	if item.buy_price > 0:
		details.append("Compra: %dg" % item.buy_price)
	if item.sell_price > 0:
		var adjusted_sell_price := InventorySlotData.get_adjusted_sell_price(item.sell_price, stack.quality)
		details.append("Venda: %dg cada · Stack: %dg" % [
			adjusted_sell_price,
			adjusted_sell_price * stack.amount,
		])

	if item.kind == ItemDefinition.ItemKind.TOOL:
		details.append("Nivel: %d" % player.tools.get_tool_level(item.tool_type))
	elif item.kind == ItemDefinition.ItemKind.SEED and item.crop_to_plant != null:
		details.append("Cultivo: %s · %d dias" % [
			item.crop_to_plant.display_name,
			item.crop_to_plant.growth_days,
		])
		details.append("Estacao: %s" % item.crop_to_plant.get_season_names())

	if _pending_split_source >= 0:
		details.append("Dividir stack: clique direito em um slot vazio.")

	inventory_detail.text = "\n".join(details)

func _item_kind_name(kind: int) -> String:
	match kind:
		ItemDefinition.ItemKind.TOOL:
			return "Ferramenta"
		ItemDefinition.ItemKind.SEED:
			return "Semente"
		ItemDefinition.ItemKind.CROP:
			return "Colheita"
		ItemDefinition.ItemKind.MATERIAL:
			return "Material"
		ItemDefinition.ItemKind.FOOD:
			return "Alimento"
		ItemDefinition.ItemKind.FERTILIZER:
			return "Fertilizante"
		_:
			return "Item"

func _on_inventory_slot_selected(index: int) -> void:
	if player == null:
		return

	player.inventory.set_selected_slot(index)
	_pending_split_source = -1
	_refresh_inventory_panel()

func _on_inventory_slot_drop_requested(from_index: int, to_index: int) -> void:
	if player == null:
		return

	_pending_split_source = -1
	if player.inventory.move_or_merge_stack(from_index, to_index):
		_show_feedback("Inventario reorganizado.")
	_refresh_inventory_panel()

func _on_inventory_split_requested(index: int) -> void:
	if player == null:
		return

	if _pending_split_source < 0:
		var source := player.inventory.get_slot(index)
		if source == null or source.is_empty() or source.amount <= 1 or source.item.max_stack <= 1:
			_show_feedback("Esse stack nao pode ser dividido.")
			return

		_pending_split_source = index
		player.inventory.set_selected_slot(index)
		_show_feedback("Clique direito em um slot vazio para dividir o stack.")
		_refresh_inventory_panel()
		return

	var source_index := _pending_split_source
	_pending_split_source = -1

	if source_index == index:
		_show_feedback("Divisao cancelada.")
		_refresh_inventory_panel()
		return

	if player.inventory.split_stack_half(source_index, index):
		_show_feedback("Stack dividido.")
	else:
		_show_feedback("O destino precisa estar vazio.")

	_refresh_inventory_panel()

func _on_inventory_organize_pressed() -> void:
	if player == null:
		return

	_pending_split_source = -1
	player.inventory.organize_slots()
	_show_feedback("Stacks organizados.")
	_refresh_inventory_panel()

func _on_inventory_changed() -> void:
	_refresh_inventory_panel()


func _open_shop(shop: SeedShop) -> void:
	if shop == null or player == null:
		return

	calendar_panel.visible = false
	bestiary_panel.visible = false
	habitat_panel.visible = false
	inventory_panel.visible = false

	_active_shop = shop
	shop_panel.visible = true
	_update_menu_pause()
	_refresh_shop_panel()

func _close_shop() -> void:
	shop_panel.visible = false
	_active_shop = null
	_update_menu_pause()

func _refresh_shop_panel() -> void:
	if _active_shop == null or player == null:
		return

	shop_title.text = "Banca da Fazenda · %s" % GameClock.get_season_name()
	shop_balance.text = "Seu Ouro: %dg" % Economy.gold

	for child in shop_offers.get_children():
		child.queue_free()

	var offers := _active_shop.get_current_offers()
	if offers.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Nenhuma oferta nesta estacao."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shop_offers.add_child(empty_label)
		return

	for item in offers:
		if item == null:
			continue

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 74)
		row.add_theme_constant_override("separation", 10)
		shop_offers.add_child(row)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var name_label := Label.new()
		name_label.text = item.display_name
		name_label.add_theme_font_size_override("font_size", 16)
		info.add_child(name_label)

		var offer_detail := "%dg cada" % item.buy_price
		if item.crop_to_plant != null:
			offer_detail += " · %d dias · venda base %dg" % [
				item.crop_to_plant.growth_days,
				item.crop_to_plant.sell_value,
			]
		elif item.kind == ItemDefinition.ItemKind.FERTILIZER:
			offer_detail += " · +%d colheita · melhora qualidade" % item.fertility_bonus

		var detail_label := Label.new()
		detail_label.text = offer_detail
		detail_label.add_theme_font_size_override("font_size", 12)
		detail_label.modulate = Color(0.78, 0.80, 0.74)
		info.add_child(detail_label)

		var buy_one := Button.new()
		buy_one.text = "Comprar 1"
		buy_one.disabled = not Economy.can_afford(item.buy_price)
		buy_one.pressed.connect(_on_shop_buy.bind(item.id, 1))
		row.add_child(buy_one)

		var buy_five := Button.new()
		buy_five.text = "Comprar 5"
		buy_five.disabled = not Economy.can_afford(item.buy_price * 5)
		buy_five.pressed.connect(_on_shop_buy.bind(item.id, 5))
		row.add_child(buy_five)

func _on_shop_buy(item_id: StringName, amount: int) -> void:
	if _active_shop == null or player == null:
		return

	var message := _active_shop.purchase(player, item_id, amount)
	_show_feedback(message)
	_refresh_shop_panel()
	_refresh_inventory_panel()


func _refresh_nearby_machine() -> void:
	if player == null:
		machine_panel.visible = false
		return

	var nearest: SlimeCrystallizer = null
	var nearest_distance := 115.0

	for node in get_tree().get_nodes_in_group("slime_crystallizer"):
		var machine := node as SlimeCrystallizer
		if machine == null:
			continue

		var distance := player.global_position.distance_to(machine.global_position)
		if distance < nearest_distance:
			nearest = machine
			nearest_distance = distance

	if nearest == null:
		machine_panel.visible = false
		return

	machine_panel.visible = true
	machine_status.text = nearest.get_status_text()


func _refresh_mine_status() -> void:
	if player == null:
		mine_panel.visible = false
		return

	var active_mine: MineArea = null
	for node in get_tree().get_nodes_in_group("mine_area"):
		var mine := node as MineArea
		if mine != null and mine.contains_position(player.global_position):
			active_mine = mine
			break

	if active_mine == null:
		mine_panel.visible = false
		return

	mine_panel.visible = true
	mine_status.text = "%s · Picareta Nv.%d · Fe %d · Ag %d · Au %d" % [
		active_mine.area_name.capitalize(),
		player.tools.get_tool_level(ToolController.ToolType.PICKAXE),
		player.inventory.count_item(&"iron_ore"),
		player.inventory.count_item(&"silver_ore"),
		player.inventory.count_item(&"gold_ore"),
	]
