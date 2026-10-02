extends Node
## Steamworks wrapper. Works as a no-op when the GodotSteam extension is not present,
## so the game always runs DRM-free. When GodotSteam is installed the "Steam" singleton
## exists and achievements / rich presence / leaderboards are forwarded to it.

var steam: Object = null
var available := false


func _ready() -> void:
	if Engine.has_singleton("Steam"):
		steam = Engine.get_singleton("Steam")
		var init: Variant = steam.call("steamInitEx", false)
		available = init is Dictionary and int(init.get("status", 1)) == 0
	EventBus.achievement_unlocked.connect(_on_achievement)
	EventBus.zone_changed.connect(func(_z): update_presence())


func _process(_d: float) -> void:
	if available:
		steam.call("run_callbacks")


func _on_achievement(ach_id: String) -> void:
	if available:
		steam.call("setAchievement", ach_id)
		steam.call("storeStats")


func update_presence() -> void:
	if not available:
		return
	var z: Dictionary = DataDB.zone(int(GameState.progress.get("zone", 0)))
	var txt := "%s - Lv %d" % [DataDB.tx(z.get("name", {})), GameState.max_hero_level()]
	steam.call("setRichPresence", "steam_display", txt)


func submit_score(board: String, score: int) -> void:
	if available:
		steam.call("findLeaderboard", board)
		steam.call("uploadLeaderboardScore", score, true)
