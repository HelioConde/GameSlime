class_name SlimeCreature
extends CharacterBody2D

enum BiologicalSex {
	MALE,
	FEMALE,
}

enum Personality {
	CURIOUS,
	CALM,
	PLAYFUL,
	SHY,
}

enum RarityTier {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

signal needs_changed(slime: SlimeCreature)
signal affection_changed(slime: SlimeCreature, affection: float)
signal product_created(slime: SlimeCreature, item_id: StringName, amount: int)

const DROP_SCENE := preload("res://scenes/world/item_drop.tscn")

@export var slime_id: StringName = &"green_slime"
@export var display_name: String = "Broto"
@export var slime_color: Color = Color(0.30, 0.92, 0.50)
@export var move_speed: float = 38.0
@export var wander_radius: float = 110.0
@export var interaction_radius: float = 48.0
@export var biological_sex: BiologicalSex = BiologicalSex.MALE
@export var personality: Personality = Personality.CURIOUS

@export_group("Genetics")
@export_range(0.75, 1.35, 0.01) var gene_size: float = 1.0
@export_range(0.75, 1.35, 0.01) var gene_metabolism: float = 1.0
@export_range(0.75, 1.35, 0.01) var gene_vitality: float = 1.0
@export_range(0.75, 1.50, 0.01) var gene_production: float = 1.0

@export_group("Needs")
@export_range(0.0, 100.0, 0.1) var starting_satiety: float = 82.0
@export_range(0.0, 100.0, 0.1) var starting_energy: float = 90.0
@export_range(0.0, 100.0, 0.1) var starting_happiness: float = 72.0
@export_range(0.0, 100.0, 0.1) var starting_affection: float = 0.0

var satiety: float
var energy: float
var happiness: float
var affection: float
var age_days: int = 0
var last_petted_day: int = -1
var last_bred_day: int = -1
var mutation_tag: String = ""
var habitat: SlimeHabitat

var _home_position: Vector2
var _wander_target: Vector2
var _wander_wait: float = 0.0
var _rng := RandomNumberGenerator.new()
var _bounce_time: float = 0.0

func _ready() -> void:
	add_to_group("slime_creature")
	satiety = starting_satiety
	energy = starting_energy
	happiness = starting_happiness
	affection = starting_affection
	_home_position = global_position
	call_deferred("_find_habitat")

	_rng.seed = hash(String(name))
	_choose_wander_target()

	GameClock.time_changed.connect(_on_time_changed)
	GameClock.day_started.connect(_on_day_started)
	call_deferred("_register_discovery")
	queue_redraw()

func _physics_process(delta: float) -> void:
	_bounce_time += delta

	if energy <= 12.0:
		velocity = Vector2.ZERO
		_wander_wait = maxf(_wander_wait, 1.0)
	else:
		_tick_wander(delta)

	move_and_slide()
	queue_redraw()

func _register_discovery() -> void:
	SlimeDiscovery.register_slime(self)

func can_interact(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius

func interact(player: PlayerController) -> String:
	if player == null or not can_interact(player.global_position):
		return ""

	var selected := player.inventory.get_selected_stack()
	if selected != null and not selected.is_empty():
		if selected.item.kind in [ItemDefinition.ItemKind.CROP, ItemDefinition.ItemKind.FOOD]:
			var food_name := selected.item.display_name
			if player.inventory.remove_item(selected.item.id, 1):
				_feed()
				return "%s comeu %s. Saciedade %.0f%% · Humor %.0f%%" % [
					display_name,
					food_name,
					satiety,
					happiness,
				]

	if last_petted_day == GameClock.day:
		return "%s ja recebeu carinho hoje. Afeto %.0f%%" % [display_name, affection]

	last_petted_day = GameClock.day
	var affection_gain := 4.0
	var happiness_gain := 6.0

	match personality:
		Personality.PLAYFUL:
			affection_gain = 6.0
			happiness_gain = 9.0
		Personality.SHY:
			affection_gain = 2.5
			happiness_gain = 4.0
		Personality.CALM:
			happiness_gain = 5.0

	affection = minf(affection + affection_gain, 100.0)
	happiness = minf(happiness + happiness_gain, 100.0)
	affection_changed.emit(self, affection)
	needs_changed.emit(self)

	return "Voce fez carinho em %s. Afeto %.0f%%" % [display_name, affection]

func get_status_text() -> String:
	var mutation_text := "" if mutation_tag.is_empty() else " · Mutacao %s" % mutation_tag
	return "%s · %s · %s\n%s · %s%s\nFome %.0f%% · Energia %.0f%% · Humor %.0f%% · Afeto %.0f%% · %d dias" % [
		display_name,
		get_sex_name(),
		get_personality_name(),
		get_species_name(),
		get_rarity_name(),
		mutation_text,
		satiety,
		energy,
		happiness,
		affection,
		age_days,
	]

func get_personality_name() -> String:
	match personality:
		Personality.CURIOUS:
			return "Curioso"
		Personality.CALM:
			return "Calmo"
		Personality.PLAYFUL:
			return "Brincalhao"
		Personality.SHY:
			return "Timido"
		_:
			return "Slime"

func get_sex_name() -> String:
	return "Macho" if biological_sex == BiologicalSex.MALE else "Femea"

func get_species_name() -> String:
	match slime_id:
		&"green_slime":
			return "Slime Verde"
		&"moss_slime":
			return "Slime Musgo"
		&"storm_slime":
			return "Slime Tempestade"
		&"frost_slime":
			return "Slime Geada"
		&"solar_slime":
			return "Slime Solar"
		&"moon_slime":
			return "Slime Lunar"
		_:
			return String(slime_id).capitalize()

func get_rarity_tier() -> int:
	var score := get_rarity_score()

	if score >= 7:
		return RarityTier.LEGENDARY
	if score >= 5:
		return RarityTier.EPIC
	if score >= 3:
		return RarityTier.RARE
	if score >= 2:
		return RarityTier.UNCOMMON
	return RarityTier.COMMON

func get_rarity_name() -> String:
	match get_rarity_tier():
		RarityTier.COMMON:
			return "Comum"
		RarityTier.UNCOMMON:
			return "Incomum"
		RarityTier.RARE:
			return "Raro"
		RarityTier.EPIC:
			return "Epico"
		RarityTier.LEGENDARY:
			return "Lendario"
		_:
			return "Comum"

func get_rarity_score() -> int:
	var score := 0

	for gene in [gene_size, gene_metabolism, gene_vitality, gene_production]:
		if gene <= 0.85 or gene >= 1.20:
			score += 1

	if not mutation_tag.is_empty():
		score += 2

	match slime_id:
		&"moss_slime", &"storm_slime":
			score += 2
		&"frost_slime", &"solar_slime":
			score += 3
		&"moon_slime":
			score += 4

	return score

func get_genetics_text() -> String:
	return "Tam %.2f · Met %.2f · Vit %.2f · Prod %.2f" % [
		gene_size,
		gene_metabolism,
		gene_vitality,
		gene_production,
	]

func can_breed() -> bool:
	return (
		age_days >= 3
		and last_bred_day != GameClock.day
		and satiety >= 60.0
		and energy >= 50.0
		and happiness >= 60.0
		and affection >= 8.0
	)

func mark_bred() -> void:
	last_bred_day = GameClock.day
	satiety = maxf(satiety - 12.0, 0.0)
	energy = maxf(energy - 18.0, 0.0)
	happiness = minf(happiness + 3.0, 100.0)
	needs_changed.emit(self)

func configure_child_from_parents(parent_a: SlimeCreature, parent_b: SlimeCreature, seed_value: int) -> void:
	var child_rng := RandomNumberGenerator.new()
	child_rng.seed = seed_value

	biological_sex = BiologicalSex.MALE if child_rng.randi_range(0, 1) == 0 else BiologicalSex.FEMALE
	personality = parent_a.personality if child_rng.randf() < 0.5 else parent_b.personality

	gene_size = _inherit_gene(parent_a.gene_size, parent_b.gene_size, child_rng)
	gene_metabolism = _inherit_gene(parent_a.gene_metabolism, parent_b.gene_metabolism, child_rng)
	gene_vitality = _inherit_gene(parent_a.gene_vitality, parent_b.gene_vitality, child_rng)
	gene_production = clampf(
		(parent_a.gene_production + parent_b.gene_production) * 0.5 + child_rng.randf_range(-0.05, 0.05),
		0.75,
		1.50
	)

	slime_color = parent_a.slime_color.lerp(parent_b.slime_color, child_rng.randf_range(0.38, 0.62))
	slime_color.r = clampf(slime_color.r + child_rng.randf_range(-0.025, 0.025), 0.0, 1.0)
	slime_color.g = clampf(slime_color.g + child_rng.randf_range(-0.025, 0.025), 0.0, 1.0)
	slime_color.b = clampf(slime_color.b + child_rng.randf_range(-0.025, 0.025), 0.0, 1.0)

	mutation_tag = ""
	slime_id = &"green_slime"
	_apply_environmental_mutation(child_rng)
	_apply_special_species_conditions(child_rng, parent_a, parent_b)

	satiety = 82.0
	energy = 88.0
	happiness = 68.0
	affection = 0.0
	age_days = 0
	last_petted_day = -1
	last_bred_day = -1
	_home_position = global_position
	_choose_wander_target()
	needs_changed.emit(self)
	SlimeDiscovery.register_slime(self)
	queue_redraw()

func _apply_environmental_mutation(child_rng: RandomNumberGenerator) -> void:
	var roll := child_rng.randf()

	if WeatherManager.is_snowing() and GameClock.season_index == GameClock.Season.WINTER and roll < 0.18:
		mutation_tag = "Neve"
		slime_color = slime_color.lerp(Color(0.62, 0.90, 1.0), 0.42)
		gene_vitality = clampf(gene_vitality + 0.08, 0.75, 1.35)
		return

	if WeatherManager.is_raining() and roll < 0.14:
		mutation_tag = "Chuva"
		slime_color = slime_color.lerp(Color(0.30, 0.67, 1.0), 0.32)
		gene_production = clampf(gene_production + 0.08, 0.75, 1.50)
		return

	if GameClock.season_index == GameClock.Season.SUMMER and WeatherManager.current_weather == WeatherManager.Weather.CLEAR and roll < 0.10:
		mutation_tag = "Solar"
		slime_color = slime_color.lerp(Color(1.0, 0.83, 0.30), 0.28)
		gene_vitality = clampf(gene_vitality + 0.04, 0.75, 1.35)
		return

	if GameClock.season_index == GameClock.Season.FALL and roll < 0.08:
		mutation_tag = "Outono"
		slime_color = slime_color.lerp(Color(0.88, 0.48, 0.24), 0.25)
		gene_metabolism = clampf(gene_metabolism - 0.05, 0.75, 1.35)

func _apply_special_species_conditions(
	child_rng: RandomNumberGenerator,
	parent_a: SlimeCreature,
	parent_b: SlimeCreature
) -> void:
	var hour := GameClock.get_hour()
	var parent_habitat := parent_a.habitat if parent_a.habitat != null else parent_b.habitat
	var biome := SlimeHabitat.HabitatBiome.MEADOW
	if parent_habitat != null:
		biome = parent_habitat.biome_type

	# Extremely rare night lineage. High affection makes the condition intentional,
	# not something the player gets by accident immediately.
	if (hour >= 22 or hour < 2) and parent_a.affection >= 40.0 and parent_b.affection >= 40.0:
		if child_rng.randf() < 0.16:
			slime_id = &"moon_slime"
			slime_color = slime_color.lerp(Color(0.58, 0.48, 0.95), 0.48)
			gene_vitality = clampf(gene_vitality + 0.06, 0.75, 1.35)
			return

	if WeatherManager.is_snowing() and GameClock.season_index == GameClock.Season.WINTER:
		if child_rng.randf() < 0.32:
			slime_id = &"frost_slime"
			slime_color = slime_color.lerp(Color(0.70, 0.94, 1.0), 0.55)
			gene_vitality = clampf(gene_vitality + 0.06, 0.75, 1.35)
			return

	if WeatherManager.is_raining() and (hour >= 18 or hour < 6):
		if child_rng.randf() < 0.28:
			slime_id = &"storm_slime"
			slime_color = slime_color.lerp(Color(0.28, 0.48, 0.82), 0.52)
			gene_production = clampf(gene_production + 0.05, 0.75, 1.50)
			return

	if (
		GameClock.season_index == GameClock.Season.SUMMER
		and WeatherManager.current_weather == WeatherManager.Weather.CLEAR
		and hour >= 11
		and hour <= 16
	):
		if child_rng.randf() < 0.24:
			slime_id = &"solar_slime"
			slime_color = slime_color.lerp(Color(1.0, 0.78, 0.22), 0.50)
			gene_vitality = clampf(gene_vitality + 0.04, 0.75, 1.35)
			return

	if biome == SlimeHabitat.HabitatBiome.GROVE:
		if GameClock.season_index in [GameClock.Season.SPRING, GameClock.Season.FALL]:
			if child_rng.randf() < 0.26:
				slime_id = &"moss_slime"
				slime_color = slime_color.lerp(Color(0.24, 0.55, 0.25), 0.48)
				gene_metabolism = clampf(gene_metabolism - 0.04, 0.75, 1.35)

func _inherit_gene(value_a: float, value_b: float, child_rng: RandomNumberGenerator) -> float:
	return clampf((value_a + value_b) * 0.5 + child_rng.randf_range(-0.05, 0.05), 0.75, 1.35)

func get_save_data() -> Dictionary:
	return {
		"node_name": String(name),
		"display_name": display_name,
		"slime_id": String(slime_id),
		"rarity_tier": get_rarity_tier(),
		"position": [global_position.x, global_position.y],
		"home_position": [_home_position.x, _home_position.y],
		"satiety": satiety,
		"energy": energy,
		"happiness": happiness,
		"affection": affection,
		"age_days": age_days,
		"last_petted_day": last_petted_day,
		"last_bred_day": last_bred_day,
		"biological_sex": biological_sex,
		"personality": personality,
		"gene_size": gene_size,
		"gene_metabolism": gene_metabolism,
		"gene_vitality": gene_vitality,
		"gene_production": gene_production,
		"mutation_tag": mutation_tag,
		"slime_color": [slime_color.r, slime_color.g, slime_color.b, slime_color.a],
	}

func load_save_data(data: Dictionary) -> void:
	var saved_position: Array = data.get("position", [])
	if saved_position.size() >= 2:
		global_position = Vector2(float(saved_position[0]), float(saved_position[1]))

	var saved_home: Array = data.get("home_position", [])
	if saved_home.size() >= 2:
		_home_position = Vector2(float(saved_home[0]), float(saved_home[1]))
	else:
		_home_position = global_position

	satiety = clampf(float(data.get("satiety", starting_satiety)), 0.0, 100.0)
	energy = clampf(float(data.get("energy", starting_energy)), 0.0, 100.0)
	happiness = clampf(float(data.get("happiness", starting_happiness)), 0.0, 100.0)
	affection = clampf(float(data.get("affection", starting_affection)), 0.0, 100.0)
	age_days = maxi(int(data.get("age_days", 0)), 0)
	display_name = str(data.get("display_name", display_name))
	slime_id = StringName(str(data.get("slime_id", String(slime_id))))
	last_petted_day = int(data.get("last_petted_day", -1))
	last_bred_day = int(data.get("last_bred_day", -1))
	biological_sex = clampi(int(data.get("biological_sex", biological_sex)), BiologicalSex.MALE, BiologicalSex.FEMALE)
	personality = clampi(int(data.get("personality", personality)), Personality.CURIOUS, Personality.SHY)
	gene_size = clampf(float(data.get("gene_size", gene_size)), 0.75, 1.35)
	gene_metabolism = clampf(float(data.get("gene_metabolism", gene_metabolism)), 0.75, 1.35)
	gene_vitality = clampf(float(data.get("gene_vitality", gene_vitality)), 0.75, 1.35)
	gene_production = clampf(float(data.get("gene_production", gene_production)), 0.75, 1.50)
	mutation_tag = str(data.get("mutation_tag", mutation_tag))

	var saved_color: Array = data.get("slime_color", [])
	if saved_color.size() >= 4:
		slime_color = Color(
			float(saved_color[0]),
			float(saved_color[1]),
			float(saved_color[2]),
			float(saved_color[3])
		)

	_choose_wander_target()
	needs_changed.emit(self)
	SlimeDiscovery.register_slime(self)
	queue_redraw()

func _tick_wander(delta: float) -> void:
	if _wander_wait > 0.0:
		_wander_wait -= delta
		velocity = Vector2.ZERO
		return

	if global_position.distance_to(_wander_target) <= 6.0:
		_wander_wait = _rng.randf_range(0.8, 2.4)
		_choose_wander_target()
		velocity = Vector2.ZERO
		return

	var direction := global_position.direction_to(_wander_target)
	var personality_speed := 1.0
	match personality:
		Personality.CURIOUS:
			personality_speed = 1.12
		Personality.CALM:
			personality_speed = 0.82
		Personality.PLAYFUL:
			personality_speed = 1.18
		Personality.SHY:
			personality_speed = 0.90

	velocity = direction * move_speed * personality_speed

func _choose_wander_target() -> void:
	if habitat != null and is_instance_valid(habitat):
		_wander_target = habitat.get_random_point(_rng)
		return

	var angle := _rng.randf_range(0.0, TAU)
	var distance := _rng.randf_range(16.0, wander_radius)
	_wander_target = _home_position + Vector2.from_angle(angle) * distance

func _find_habitat() -> void:
	if habitat != null:
		return

	var nearest: SlimeHabitat = null
	var nearest_distance := INF

	for node in get_tree().get_nodes_in_group("slime_habitat"):
		var candidate := node as SlimeHabitat
		if candidate == null or not candidate.contains_position(global_position):
			continue

		var distance := global_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance

	if nearest != null:
		nearest.register_slime(self)

func _feed() -> void:
	satiety = minf(satiety + 30.0, 100.0)
	happiness = minf(happiness + 8.0, 100.0)
	affection = minf(affection + 1.0, 100.0)
	needs_changed.emit(self)
	affection_changed.emit(self, affection)

func _on_time_changed(_day: int, _hour: int, _minute: int) -> void:
	satiety = maxf(satiety - (0.18 * gene_metabolism), 0.0)

	if velocity.length_squared() > 1.0:
		energy = maxf(energy - (0.10 / gene_vitality), 0.0)
	else:
		energy = minf(energy + 0.03, 100.0)

	if satiety < 25.0:
		happiness = maxf(happiness - 0.15, 0.0)
	elif satiety > 60.0:
		happiness = minf(happiness + 0.02, 100.0)

	needs_changed.emit(self)

func _on_day_started(_day: int) -> void:
	age_days += 1
	energy = minf(energy + (32.0 * gene_vitality), 100.0)

	if satiety >= 55.0 and happiness >= 55.0:
		_create_daily_product()

	needs_changed.emit(self)

func _create_daily_product() -> void:
	var drop := DROP_SCENE.instantiate() as ItemDrop
	if drop == null or get_parent() == null:
		return

	get_parent().add_child(drop)
	drop.global_position = global_position + Vector2(_rng.randf_range(-12.0, 12.0), 12.0)
	var amount := 2 if gene_production >= 1.20 else 1
	drop.configure(&"slime_gel", amount, slime_color)
	product_created.emit(self, &"slime_gel", amount)

func _draw() -> void:
	var squash := sin(_bounce_time * 4.0) * 1.2
	var body_y := (14.0 - squash) * gene_size
	var side_offset := 8.0 * gene_size
	var lobe_radius := 8.5 * gene_size

	draw_circle(Vector2(0, 2 + squash), body_y, slime_color)
	draw_circle(Vector2(-side_offset, -4 + squash), lobe_radius, slime_color.lightened(0.05))
	draw_circle(Vector2(side_offset, -4 + squash), lobe_radius, slime_color.lightened(0.05))

	draw_circle(Vector2(-5, -3 + squash), 2.0, Color(0.06, 0.08, 0.07))
	draw_circle(Vector2(5, -3 + squash), 2.0, Color(0.06, 0.08, 0.07))
	draw_line(Vector2(-3, 4 + squash), Vector2(3, 4 + squash), Color(0.06, 0.08, 0.07), 1.2)

	if happiness < 30.0:
		draw_arc(Vector2(0, 9 + squash), 4.0, PI, TAU, 12, Color(0.08, 0.10, 0.08), 1.0)
