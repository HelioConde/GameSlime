class_name ItemDefinition
extends Resource

enum ItemKind {
	TOOL,
	SEED,
	CROP,
	MATERIAL,
	FOOD,
}

enum IconSheet {
	NONE,
	TOOLS,
	ITEMS,
}

@export var id: StringName
@export var display_name: String = "Item"
@export var kind: ItemKind = ItemKind.MATERIAL
@export_range(1, 999, 1) var max_stack: int = 99
@export var tint: Color = Color.WHITE

@export_group("Icon")
@export var icon_sheet: IconSheet = IconSheet.NONE
@export var icon_cell: Vector2i = Vector2i.ZERO
@export_range(8, 64, 1) var icon_cell_size: int = 16

# Used only when kind == TOOL.
@export var tool_type: int = -1

# Used only when kind == SEED.
@export var crop_to_plant: CropDefinition
