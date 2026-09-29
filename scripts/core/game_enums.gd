class_name GameEnums
extends RefCounted

enum SlimeCommandMode {
	AUTO,
	FOLLOW,
	WAIT,
	MOVE_TO,
	FORCE_TASK,
	ASSIGNED_ZONE,
	REST,
}

enum TaskType {
	CHOP,
	MINE,
	HARVEST,
	PLANT,
	HAUL,
	BUILD,
}

enum TaskState {
	PENDING,
	CLAIMED,
	RUNNING,
	COMPLETED,
	CANCELED,
}

static func command_name(value: int) -> String:
	return SlimeCommandMode.keys()[value]

static func task_name(value: int) -> String:
	return TaskType.keys()[value]
