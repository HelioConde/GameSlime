class_name SlimeDiscoveryManager
extends Node

signal discovery_updated

var _individuals: Dictionary = {}
var _traits: Dictionary = {}

func register_slime(slime: SlimeCreature) -> void:
	if slime == null:
		return

	var key := String(slime.name)
	_individuals[key] = {
		"node_name": key,
		"display_name": slime.display_name,
		"slime_id": String(slime.slime_id),
		"sex": slime.get_sex_name(),
		"personality": slime.get_personality_name(),
		"gene_size": slime.gene_size,
		"gene_metabolism": slime.gene_metabolism,
		"gene_vitality": slime.gene_vitality,
		"gene_production": slime.gene_production,
		"color": [
			slime.slime_color.r,
			slime.slime_color.g,
			slime.slime_color.b,
			slime.slime_color.a,
		],
	}

	_register_trait_discoveries(slime)
	discovery_updated.emit()

func get_all_individuals() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _individuals.values():
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))

	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("display_name", "")) < str(b.get("display_name", ""))
	)
	return result

func get_discovered_traits() -> Array[String]:
	var result: Array[String] = []
	for key in _traits.keys():
		result.append(str(key))
	result.sort()
	return result

func get_save_data() -> Dictionary:
	return {
		"individuals": _individuals.duplicate(true),
		"traits": _traits.duplicate(true),
	}

func load_save_data(data: Dictionary) -> void:
	var saved_individuals = data.get("individuals", {})
	var saved_traits = data.get("traits", {})

	_individuals = saved_individuals.duplicate(true) if saved_individuals is Dictionary else {}
	_traits = saved_traits.duplicate(true) if saved_traits is Dictionary else {}
	discovery_updated.emit()

func _register_trait_discoveries(slime: SlimeCreature) -> void:
	if slime.gene_size >= 1.20:
		_traits["Tamanho grande"] = true
	if slime.gene_size <= 0.85:
		_traits["Tamanho pequeno"] = true
	if slime.gene_metabolism <= 0.85:
		_traits["Metabolismo eficiente"] = true
	if slime.gene_metabolism >= 1.20:
		_traits["Metabolismo acelerado"] = true
	if slime.gene_vitality >= 1.20:
		_traits["Vitalidade alta"] = true
	if slime.gene_production >= 1.20:
		_traits["Producao alta"] = true
