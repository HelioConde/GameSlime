class_name EnergyComponent
extends Node

signal energy_changed(current: float, maximum: float)
signal exhausted

@export var maximum_energy: float = 270.0
@export var starting_energy: float = 270.0

var current_energy: float

func _ready() -> void:
	current_energy = clampf(starting_energy, 0.0, maximum_energy)
	energy_changed.emit(current_energy, maximum_energy)

func can_spend(amount: float) -> bool:
	return amount <= 0.0 or current_energy >= amount

func spend(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if not can_spend(amount):
		return false

	current_energy = maxf(current_energy - amount, 0.0)
	energy_changed.emit(current_energy, maximum_energy)

	if is_zero_approx(current_energy):
		exhausted.emit()

	return true

func restore(amount: float) -> void:
	if amount <= 0.0:
		return
	current_energy = minf(current_energy + amount, maximum_energy)
	energy_changed.emit(current_energy, maximum_energy)

func restore_full() -> void:
	current_energy = maximum_energy
	energy_changed.emit(current_energy, maximum_energy)

func get_ratio() -> float:
	if maximum_energy <= 0.0:
		return 0.0
	return current_energy / maximum_energy

func set_current_energy(value: float) -> void:
	current_energy = clampf(value, 0.0, maximum_energy)
	energy_changed.emit(current_energy, maximum_energy)
