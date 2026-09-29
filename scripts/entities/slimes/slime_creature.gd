class_name SlimeCreature
extends CharacterBody2D

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

	_rng.seed = hash(String(name))
	_choose_wander_target()

	GameClock.time_changed.connect(_on_time_changed)
	GameClock.day_started.connect(_on_day_started)
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
	affection = minf(affection + 4.0, 100.0)
	happiness = minf(happiness + 6.0, 100.0)
	affection_changed.emit(self, affection)
	needs_changed.emit(self)

	return "Voce fez carinho em %s. Afeto %.0f%%" % [display_name, affection]

func get_status_text() -> String:
	return "%s · Fome %.0f%% · Energia %.0f%% · Humor %.0f%% · Afeto %.0f%% · %d dias" % [
		display_name,
		satiety,
		energy,
		happiness,
		affection,
		age_days,
	]

func get_save_data() -> Dictionary:
	return {
		"node_name": String(name),
		"slime_id": String(slime_id),
		"position": [global_position.x, global_position.y],
		"home_position": [_home_position.x, _home_position.y],
		"satiety": satiety,
		"energy": energy,
		"happiness": happiness,
		"affection": affection,
		"age_days": age_days,
		"last_petted_day": last_petted_day,
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
	last_petted_day = int(data.get("last_petted_day", -1))
	_choose_wander_target()
	needs_changed.emit(self)
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
	velocity = direction * move_speed

func _choose_wander_target() -> void:
	var angle := _rng.randf_range(0.0, TAU)
	var distance := _rng.randf_range(16.0, wander_radius)
	_wander_target = _home_position + Vector2.from_angle(angle) * distance

func _feed() -> void:
	satiety = minf(satiety + 30.0, 100.0)
	happiness = minf(happiness + 8.0, 100.0)
	affection = minf(affection + 1.0, 100.0)
	needs_changed.emit(self)
	affection_changed.emit(self, affection)

func _on_time_changed(_day: int, _hour: int, _minute: int) -> void:
	satiety = maxf(satiety - 0.18, 0.0)

	if velocity.length_squared() > 1.0:
		energy = maxf(energy - 0.10, 0.0)
	else:
		energy = minf(energy + 0.03, 100.0)

	if satiety < 25.0:
		happiness = maxf(happiness - 0.15, 0.0)
	elif satiety > 60.0:
		happiness = minf(happiness + 0.02, 100.0)

	needs_changed.emit(self)

func _on_day_started(_day: int) -> void:
	age_days += 1
	energy = minf(energy + 32.0, 100.0)

	if satiety >= 55.0 and happiness >= 55.0:
		_create_daily_product()

	needs_changed.emit(self)

func _create_daily_product() -> void:
	var drop := DROP_SCENE.instantiate() as ItemDrop
	if drop == null or get_parent() == null:
		return

	get_parent().add_child(drop)
	drop.global_position = global_position + Vector2(_rng.randf_range(-12.0, 12.0), 12.0)
	drop.configure(&"slime_gel", 1, slime_color)
	product_created.emit(self, &"slime_gel", 1)

func _draw() -> void:
	var squash := sin(_bounce_time * 4.0) * 1.2
	var body_y := 14.0 - squash

	draw_circle(Vector2(0, 2 + squash), body_y, slime_color)
	draw_circle(Vector2(-8, -4 + squash), 8.5, slime_color.lightened(0.05))
	draw_circle(Vector2(8, -4 + squash), 8.5, slime_color.lightened(0.05))

	draw_circle(Vector2(-5, -3 + squash), 2.0, Color(0.06, 0.08, 0.07))
	draw_circle(Vector2(5, -3 + squash), 2.0, Color(0.06, 0.08, 0.07))
	draw_line(Vector2(-3, 4 + squash), Vector2(3, 4 + squash), Color(0.06, 0.08, 0.07), 1.2)

	if happiness < 30.0:
		draw_arc(Vector2(0, 9 + squash), 4.0, PI, TAU, 12, Color(0.08, 0.10, 0.08), 1.0)
