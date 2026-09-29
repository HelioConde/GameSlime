class_name InventorySlotWidget
extends PanelContainer

signal slot_drop_requested(from_index: int, to_index: int)
signal slot_selected(index: int)
signal split_requested(index: int)

var slot_index: int = -1
var can_drag: bool = false
var drag_label: String = ""

var _icon: TextureRect
var _name_label: Label
var _amount_label: Label
var _key_label: Label
var _built: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(118, 92)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_build_content()

func configure(
	index: int,
	item: ItemDefinition,
	amount: int,
	icon_texture: Texture2D,
	selected: bool,
	quality: int = InventorySlotData.Quality.NORMAL
) -> void:
	if not _built:
		_build_content()

	slot_index = index
	can_drag = item != null and amount > 0
	drag_label = item.display_name if item != null else ""

	_key_label.text = str(index + 1)
	_icon.texture = icon_texture

	if item == null or amount <= 0:
		_name_label.text = "Vazio"
		_amount_label.text = ""
	else:
		var marker := InventorySlotData.get_quality_marker(quality)
		_name_label.text = "%s%s" % [item.display_name, marker]
		_amount_label.text = "x%d" % amount if item.max_stack > 1 else ""

	_apply_style(selected)

func _build_content() -> void:
	if _built:
		return

	_built = true

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 2)
	margin.add_child(column)

	_key_label = Label.new()
	_key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_key_label.add_theme_font_size_override("font_size", 9)
	_key_label.modulate = Color(0.72, 0.76, 0.70)
	column.add_child(_key_label)

	_icon = TextureRect.new()
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.custom_minimum_size = Vector2(38, 38)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	column.add_child(_icon)

	_name_label = Label.new()
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.custom_minimum_size.x = 100
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name_label.add_theme_font_size_override("font_size", 10)
	column.add_child(_name_label)

	_amount_label = Label.new()
	_amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_amount_label.add_theme_font_size_override("font_size", 10)
	add_child(_amount_label)
	_amount_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_amount_label.offset_right = -7.0
	_amount_label.offset_bottom = -6.0
	_amount_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _apply_style(selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.09, 0.07, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.82, 0.30) if selected else Color(0.33, 0.40, 0.32)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	add_theme_stylebox_override("panel", style)

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return

	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return

	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		slot_selected.emit(slot_index)
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		split_requested.emit(slot_index)

func _get_drag_data(_at_position: Vector2):
	if not can_drag or slot_index < 0:
		return null

	var preview := PanelContainer.new()
	var label := Label.new()
	label.text = drag_label
	label.add_theme_font_size_override("font_size", 12)
	preview.add_child(label)
	preview.custom_minimum_size = Vector2(110, 32)
	set_drag_preview(preview)

	return {
		"type": "inventory_slot",
		"slot": slot_index,
	}

func _can_drop_data(_at_position: Vector2, data) -> bool:
	if not (data is Dictionary):
		return false

	var dictionary := data as Dictionary
	return (
		str(dictionary.get("type", "")) == "inventory_slot"
		and int(dictionary.get("slot", -1)) >= 0
		and slot_index >= 0
	)

func _drop_data(_at_position: Vector2, data) -> void:
	if not _can_drop_data(Vector2.ZERO, data):
		return

	var dictionary := data as Dictionary
	var from_index := int(dictionary.get("slot", -1))
	slot_drop_requested.emit(from_index, slot_index)
