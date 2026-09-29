extends CanvasLayer

const TOOL_ATLAS: Texture2D = preload("res://assets/sprout_lands/tools/tools.png")
const ITEM_ATLAS: Texture2D = preload("res://assets/sprout_lands/items/all_items.png")

@onready var status_label: Label = $StatusPanel/Margin/Status
@onready var hotbar_container: HBoxContainer = $HotbarPanel/Margin/Hotbar
@onready var help_label: Label = $HelpPanel/Margin/Help
@onready var feedback_label: Label = $Feedback
@onready var calendar_panel: PanelContainer = $CalendarPanel
@onready var calendar_title: Label = $CalendarPanel/Margin/Content/Title
@onready var calendar_body: Label = $CalendarPanel/Margin/Content/Body

var player: PlayerController
var _feedback_time_left: float = 0.0
var _hotbar_built: bool = false
var _slot_panels: Array[PanelContainer] = []
var _slot_icons: Array[TextureRect] = []
var _slot_names: Array[Label] = []
var _slot_amounts: Array[Label] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_bind_player")
	help_label.text = "WASD mover | 1-0/scroll hotbar | clique/ESPACO usar | E interagir | C calendario"
	calendar_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_C:
			_toggle_calendar()
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

func _bind_player() -> void:
	player = get_tree().get_first_node_in_group("player") as PlayerController
	if player == null:
		return

	if not player.feedback_requested.is_connected(_show_feedback):
		player.feedback_requested.connect(_show_feedback)

	if not _hotbar_built:
		_build_hotbar()

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

	status_label.text = "%s  %s\nClima: %s · Amanha: %s%s\nEnergia: %.0f / %.0f\nSelecionado: %s%s%s%s" % [
		GameClock.get_date_text(),
		GameClock.get_time_text(),
		WeatherManager.get_weather_name(),
		WeatherManager.get_tomorrow_weather_name(),
		event_text,
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
		_slot_names[index].text = slot.item.display_name
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
	calendar_panel.visible = not calendar_panel.visible
	get_tree().paused = calendar_panel.visible

	if calendar_panel.visible:
		_refresh_calendar_panel()

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
