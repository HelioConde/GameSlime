class_name BasicSfxManager
extends Node

const SAMPLE_RATE := 22050
const PLAYER_COUNT := 6

var enabled: bool = true
var master_volume_db: float = -10.0
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _index in range(PLAYER_COUNT):
		var player := AudioStreamPlayer.new()
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_players.append(player)

func play_cue(cue: StringName) -> void:
	if not enabled or _players.is_empty():
		return

	var spec := _get_cue_spec(cue)
	if spec.is_empty():
		return

	var cache_key := "%s:%s:%s" % [
		String(cue),
		str(spec.get("frequency", 440.0)),
		str(spec.get("duration", 0.08)),
	]
	var stream := _cache.get(cache_key) as AudioStreamWAV
	if stream == null:
		stream = _create_tone(
			float(spec.get("frequency", 440.0)),
			float(spec.get("duration", 0.08)),
			float(spec.get("end_frequency", spec.get("frequency", 440.0)))
		)
		_cache[cache_key] = stream

	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stop()
	player.stream = stream
	player.volume_db = master_volume_db + float(spec.get("volume_offset_db", 0.0))
	player.pitch_scale = float(spec.get("pitch", 1.0))
	player.play()

func play_tool(tool_type: int, depleted: bool = false) -> void:
	match tool_type:
		ToolController.ToolType.HOE:
			play_cue(&"hoe")
		ToolController.ToolType.WATERING_CAN:
			play_cue(&"water")
		ToolController.ToolType.AXE:
			play_cue(&"wood_break" if depleted else &"wood_hit")
		ToolController.ToolType.PICKAXE:
			play_cue(&"rock_break" if depleted else &"rock_hit")

func _get_cue_spec(cue: StringName) -> Dictionary:
	match cue:
		&"hoe":
			return {"frequency": 150.0, "end_frequency": 105.0, "duration": 0.075, "volume_offset_db": -2.0}
		&"water":
			return {"frequency": 520.0, "end_frequency": 310.0, "duration": 0.12, "volume_offset_db": -5.0}
		&"wood_hit":
			return {"frequency": 190.0, "end_frequency": 145.0, "duration": 0.055, "volume_offset_db": -2.0}
		&"wood_break":
			return {"frequency": 235.0, "end_frequency": 105.0, "duration": 0.13, "volume_offset_db": -1.0}
		&"rock_hit":
			return {"frequency": 760.0, "end_frequency": 600.0, "duration": 0.045, "volume_offset_db": -4.0}
		&"rock_break":
			return {"frequency": 880.0, "end_frequency": 330.0, "duration": 0.12, "volume_offset_db": -3.0}
		&"pickup":
			return {"frequency": 740.0, "end_frequency": 980.0, "duration": 0.07, "volume_offset_db": -5.0}
		&"plant":
			return {"frequency": 330.0, "end_frequency": 430.0, "duration": 0.08, "volume_offset_db": -5.0}
		&"harvest":
			return {"frequency": 620.0, "end_frequency": 880.0, "duration": 0.11, "volume_offset_db": -3.0}
		&"confirm":
			return {"frequency": 560.0, "end_frequency": 720.0, "duration": 0.08, "volume_offset_db": -5.0}
		&"warning":
			return {"frequency": 210.0, "end_frequency": 165.0, "duration": 0.14, "volume_offset_db": -3.0}
		&"sleep":
			return {"frequency": 420.0, "end_frequency": 245.0, "duration": 0.22, "volume_offset_db": -6.0}
		&"upgrade":
			return {"frequency": 520.0, "end_frequency": 1040.0, "duration": 0.18, "volume_offset_db": -3.0}
		_:
			return {}

func _create_tone(start_frequency: float, duration: float, end_frequency: float) -> AudioStreamWAV:
	var sample_count := maxi(int(duration * float(SAMPLE_RATE)), 1)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)

	var phase := 0.0
	for index in range(sample_count):
		var progress := float(index) / float(maxi(sample_count - 1, 1))
		var frequency := lerpf(start_frequency, end_frequency, progress)
		phase += TAU * frequency / float(SAMPLE_RATE)

		var attack := clampf(progress / 0.08, 0.0, 1.0)
		var release := clampf((1.0 - progress) / 0.32, 0.0, 1.0)
		var envelope := attack * release
		var sample := clampi(roundi(sin(phase) * envelope * 11500.0), -32768, 32767)
		var unsigned_sample := sample & 0xFFFF
		bytes[index * 2] = unsigned_sample & 0xFF
		bytes[index * 2 + 1] = (unsigned_sample >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
