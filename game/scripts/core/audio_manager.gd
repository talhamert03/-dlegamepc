extends Node
## Music + SFX playback with pooling, pitch variation, rate limiting and focus ducking.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const POOL := 12

var _players: Array = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _cur_music := ""
var _cache: Dictionary = {}
var _last_play: Dictionary = {}
var focused := true


func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	add_child(_music_a)
	add_child(_music_b)
	EventBus.settings_changed.connect(_apply_volumes)
	_apply_volumes()


func _stream(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var s: AudioStream = null
	for ext in [".ogg", ".wav"]:
		if ResourceLoader.exists(path + ext):
			s = load(path + ext)
			break
	_cache[path] = s
	return s


func _vol(kind: String) -> float:
	if Settings.get_v("mute", false):
		return 0.0
	var v: float = float(Settings.get_v("vol_master", 0.4)) * float(Settings.get_v("vol_" + kind, 0.8))
	if not focused:
		v *= 1.0 - float(Settings.get_v("unfocus_duck", 0.6))
	return v


func play(name: String, pitch_var := 0.08, vol := 1.0) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_last_play.get(name, 0)) < 60:
		return
	_last_play[name] = now
	var s := _stream(SFX_DIR + name)
	if s == null:
		return
	var v := _vol("sfx") * vol
	if v <= 0.001:
		return
	for p in _players:
		if not p.playing:
			p.stream = s
			p.volume_db = linear_to_db(v)
			p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
			p.play()
			return


func play_music(name: String) -> void:
	if name == _cur_music:
		return
	_cur_music = name
	var s := _stream(MUSIC_DIR + name)
	var old := _music_a if _music_a.playing else _music_b
	var nxt := _music_b if old == _music_a else _music_a
	if s != null:
		if s is AudioStreamWAV:
			(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		nxt.stream = s
		nxt.volume_db = -60.0
		nxt.play()
		var tw := create_tween()
		tw.tween_property(nxt, "volume_db", linear_to_db(max(0.0001, _vol("music"))), 1.5)
	if old.playing:
		var tw2 := create_tween()
		tw2.tween_property(old, "volume_db", -60.0, 1.2)
		tw2.tween_callback(old.stop)


func set_focused(f: bool) -> void:
	if focused == f:
		return
	focused = f
	_apply_volumes()


func _apply_volumes() -> void:
	for p in [_music_a, _music_b]:
		if p and p.playing:
			p.volume_db = linear_to_db(max(0.0001, _vol("music")))
