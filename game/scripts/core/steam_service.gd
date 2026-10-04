extends Node
## Steamworks wrapper. Works as a no-op when the GodotSteam extension is not present,
## so the game always runs DRM-free. When GodotSteam is installed the "Steam" singleton
## exists and achievements / rich presence / leaderboards are forwarded to it.

var steam: Object = null
var available := false

## Store payments. "direct": no payment is taken and the product is granted at once (development / before
## the Steam store is wired). "steam": Steam microtransactions through our own backend, which holds the
## publisher Web API key and calls ISteamMicroTxn InitTxn / FinalizeTxn (see docs/STEAM_PAYMENTS.md).
const PAYMENTS_SETTING := "idle_party/payments/mode"
const BACKEND_SETTING := "idle_party/payments/backend_url"
var _pending: Dictionary = {}   # order_id -> {cb, product}


func _ready() -> void:
	if Engine.has_singleton("Steam"):
		steam = Engine.get_singleton("Steam")
		var init: Variant = steam.call("steamInitEx", false)
		available = init is Dictionary and int(init.get("status", 1)) == 0
	EventBus.achievement_unlocked.connect(_on_achievement)
	if available and steam.has_signal("microtransaction_auth_response"):
		steam.connect("microtransaction_auth_response", _on_txn_auth)
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


# ------------------------------------------------------------------ Steam Cloud
## Test hook: a Dictionary stands in for Steam Remote Storage when set (unit tests, no Steam).
var fake_cloud: Variant = null


func cloud_enabled() -> bool:
	if fake_cloud != null:
		return true
	if not available or not bool(Settings.get_v("steam_cloud", true)):
		return false
	return bool(steam.call("isCloudEnabledForAccount")) and bool(steam.call("isCloudEnabledForApp"))


func cloud_write(file: String, text: String) -> bool:
	if fake_cloud != null:
		fake_cloud[file] = text
		return true
	if not cloud_enabled():
		return false
	var buf := text.to_utf8_buffer()
	return bool(steam.call("fileWrite", file, buf, buf.size()))


func cloud_read(file: String) -> String:
	if fake_cloud != null:
		return str(fake_cloud.get(file, ""))
	if not cloud_enabled() or not bool(steam.call("fileExists", file)):
		return ""
	var size := int(steam.call("getFileSize", file))
	if size <= 0:
		return ""
	var res: Variant = steam.call("fileRead", file, size)
	if res is Dictionary and res.has("buf"):
		return (res["buf"] as PackedByteArray).get_string_from_utf8()
	return ""


# ------------------------------------------------------------------ payments
func payment_mode() -> String:
	var m := str(ProjectSettings.get_setting(PAYMENTS_SETTING, "direct"))
	return "steam" if m == "steam" and available and backend_url() != "" else "direct"


func backend_url() -> String:
	return str(ProjectSettings.get_setting(BACKEND_SETTING, ""))


## Starts a real-money purchase. cb(ok: bool, order_id: String) is called when it is settled.
func purchase(product: Dictionary, cb: Callable) -> void:
	if payment_mode() == "direct":
		cb.call(true, "dev_%d_%d" % [TimeService.unix_now(), randi()])
		return
	# 1) our backend calls InitTxn; Steam then shows the overlay to the player
	var body := {"steamid": str(steam.call("getSteamID")), "item": int(product.get("steam_item", 0)),
		"product": str(product["id"]), "language": DataDB.lang}
	_post("/init", body, func(ok: bool, res: Dictionary):
		if not ok or str(res.get("order_id", "")) == "":
			cb.call(false, "")
			return
		_pending[str(res["order_id"])] = {"cb": cb, "product": product})


## 2) the player approved or declined in the Steam overlay; 3) the backend finalizes the order.
func _on_txn_auth(_app_id: int, order_id: int, authorized: bool) -> void:
	var key := str(order_id)
	if not _pending.has(key):
		return
	var cb: Callable = _pending[key]["cb"]
	_pending.erase(key)
	if not authorized:
		cb.call(false, "")
		return
	_post("/finalize", {"order_id": key}, func(ok: bool, res: Dictionary):
		cb.call(ok and str(res.get("result", "")) == "OK", "steam_" + key))


func _post(path: String, body: Dictionary, done: Callable) -> void:
	var req := HTTPRequest.new()
	req.timeout = 30.0
	add_child(req)
	req.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, data: PackedByteArray):
		req.queue_free()
		var parsed: Variant = JSON.parse_string(data.get_string_from_utf8()) if result == HTTPRequest.RESULT_SUCCESS else null
		done.call(code == 200 and parsed is Dictionary, parsed if parsed is Dictionary else {}))
	var err := req.request(backend_url().trim_suffix("/") + path, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		req.queue_free()
		done.call(false, {})
