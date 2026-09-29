class_name ItemDefinition
extends Resource

enum ItemKind {
	TOOL,
	SEED,
	CROP,
	MATERIAL,
	FOOD,
}

@export var id: StringName
@export var display_name: String = "Item"
@export var kind: ItemKind = ItemKind.MATERIAL
@export_range(1, 999, 1) var max_stack: int = 99
@export var tint: Color = Color.WHITE

# Used only when kind == TOOL.
@export var tool_type: int = -1

# Used only when kind == SEED.
@export var crop_to_plant: CropDefinition
