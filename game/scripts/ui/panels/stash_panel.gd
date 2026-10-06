extends PanelWindow
## Shared stash with 7 purchasable tabs (6x6 each).

var tab := 0
var _tabs: HBoxContainer
var _grid: GridContainer
var _slots: Array = []
var _info: Label
var _buy: Button


const SLOT := 24.0
const GAP := 3.0
var _bed: Control
var _cap: Control
var _host: Control


## An iron-bound chest seen from above: numbered tab plates (lock / coin / gem when not yet open), a plank
## floor with iron bands under the 6x6 grid, a capacity bar and the move / sort buttons.
func build(c: Control) -> void:
	_host = c
	var w := c.size.x
	_tabs = W.hbox(2)
	c.add_child(_tabs)
	var tw := (w - 2.0 * 6) / 7.0
	for i in 7:
		_tabs.add_child(_tab_plate(i, tw))
	var gw := 6 * SLOT + 5 * GAP
	_bed = Control.new()
	_bed.position = Vector2((w - gw) / 2.0 - 7, 17)
	_bed.size = Vector2(gw + 14, gw + 14)
	_bed.draw.connect(_draw_bed)
	c.add_child(_bed)
	_grid = W.grid(6, int(GAP))
	_grid.position = Vector2(7, 7)
	_bed.add_child(_grid)
	for i in int(DataDB.bal("stash.slots_per_tab", 36)):
		var s := ItemSlot.new(SLOT)
		s.source = "stash"
		s.left_clicked.connect(_on_click)
		s.right_clicked.connect(_on_click)
		s.dropped.connect(_on_drop)
		_grid.add_child(s)
		_slots.append(s)
	var y := _bed.position.y + _bed.size.y + 4
	_cap = Control.new()
	_cap.position = Vector2(0, y)
	_cap.size = Vector2(w, 11)
	c.add_child(_cap)
	_info = UITheme.label("", UITheme.C_DIM, 8, UITheme.font_body)
	_info.visible = false
	c.add_child(_info)
	# locked tab: a big price plate in the middle of the chest
	_buy = UITheme.button("", "gold", _buy_tab, Vector2(gw - 30, 18))
	c.add_child(_buy)
	_buy.size = Vector2(gw - 30, 18)
	_buy.position = Vector2((w - _buy.size.x) / 2.0, _bed.position.y + _bed.size.y / 2.0 + 6)
	var bw := (w - 4.0) / 3.0
	var by := y + 15
	var row := [[DataDB.t("btn_to_bag"), "brown", _all_to_bag, DataDB.t("stash_to_bag_tip")],
		[DataDB.t("btn_to_stash"), "brown", _all_to_stash, DataDB.t("stash_to_stash_tip")],
		[DataDB.t("btn_sort"), "gold", _sort_tab, DataDB.t("stash_sort_tip")]]
	for i in row.size():
		var b := UITheme.button(str(row[i][0]), str(row[i][1]), row[i][2], Vector2(bw, 15))
		b.tooltip_text = str(row[i][3])
		c.add_child(b)
		b.size = Vector2(bw, 15)
		b.position = Vector2(i * (bw + 2.0), by)
	EventBus.inventory_changed.connect(refresh)
	_set_tab(0)


## Tab plate: number on a wooden tag; open tabs bronze, the current one crimson, closed ones show how they
## open (gold coin = with gold, gem = in the store).
func _tab_plate(i: int, tw: float) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(tw, 14)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func():
		AudioManager.play("ui_click", 0.05, 0.5)
		_set_tab(i))
	b.mouse_entered.connect(b.queue_redraw)
	b.mouse_exited.connect(b.queue_redraw)
	b.draw.connect(func():
		var ci := b.get_canvas_item()
		var r := Rect2(Vector2.ZERO, b.size)
		var open := i < GameState.stash_tabs
		var cur := i == tab
		var hov := b.is_hovered()
		var top := UISkin.RIBBON_TOP if cur else (Color("#6A4A2E") if open else Color("#2E2824"))
		var bot := UISkin.RIBBON_BOT.darkened(0.2) if cur else (Color("#3A2416") if open else Color("#171412"))
		UISkin.fill(ci, r, 3, top.lightened(0.1 if hov else 0.0), bot)
		UISkin.stroke(ci, r, 3, UISkin.OUTLINE, 1.0)
		UISkin.stroke(ci, r.grow(-1.0), 2, Color("#F2CB7A", 0.85) if cur else Color(UISkin.BRONZE, 0.4 if open else 0.15), 0.8)
		var f := UITheme.font_title
		if open:
			var t := str(i + 1)
			var w2 := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
			b.draw_string(f, Vector2((r.size.x - w2) / 2.0, 10.5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#FFE7B0") if cur else Color("#E8D4B0"))
		else:
			var gold := i == GameState.stash_tabs and _gold_tab()
			var ic := UITheme.icon("gold" if gold else ("gem" if i == GameState.stash_tabs else "lock"))
			if ic:
				b.draw_texture_rect(ic, Rect2(r.get_center() - Vector2(4, 4), Vector2(8, 8)), false, Color(1, 1, 1, 0.9 if i == GameState.stash_tabs else 0.45)))
	return b


func _draw_bed() -> void:
	var ci := _bed.get_canvas_item()
	var r := Rect2(Vector2.ZERO, _bed.size)
	# plank floor
	UISkin.fill(ci, r, 4, Color("#4A3020"), Color("#24160C"))
	var ph := r.size.y / 6.0
	for k in range(1, 6):
		_bed.draw_line(Vector2(3, k * ph), Vector2(r.size.x - 3, k * ph), Color(0, 0, 0, 0.35), 1.0)
		_bed.draw_line(Vector2(3, k * ph + 1), Vector2(r.size.x - 3, k * ph + 1), Color(1, 0.85, 0.6, 0.05), 0.6)
	# iron bands across, riveted
	for bx in [r.size.x * 0.28, r.size.x * 0.72]:
		UISkin.fill(ci, Rect2(bx - 3, 1, 6, r.size.y - 2), 0, Color("#5A5A64"), Color("#2A2A30"))
		for k in 6:
			UISkin.rivet(ci, Vector2(bx, 6 + k * (r.size.y - 12) / 5.0), 1.1)
	UISkin.stroke(ci, r, 4, UISkin.OUTLINE, 1.4)
	UISkin.stroke(ci, r.grow(-1.5), 3, Color(UISkin.BRONZE, 0.5), 0.8)
	for p in [Vector2(4, 4), Vector2(r.size.x - 4, 4), Vector2(4, r.size.y - 4), r.size - Vector2(4, 4)]:
		UISkin.rivet(ci, p, 1.6)
	if tab >= GameState.stash_tabs:
		_bed.draw_rect(r.grow(-2), Color(0.03, 0.02, 0.02, 0.7))
		var lk := UITheme.icon("lock")
		if lk:
			_bed.draw_texture_rect(lk, Rect2(r.get_center() - Vector2(12, 30), Vector2(24, 24)), false, Color(1, 0.9, 0.7, 0.85))
		var t := DataDB.t("tab_locked")
		var f := UITheme.font_title
		var w2 := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		_bed.draw_string(f, Vector2(r.get_center().x - w2 / 2.0, r.get_center().y + 4), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#E8D4B0"))


func _set_tab(i: int) -> void:
	tab = i
	for k in _tabs.get_child_count():
		_tabs.get_child(k).queue_redraw()
	refresh()


func refresh() -> void:
	if _grid == null:
		return
	var unlocked := tab < GameState.stash_tabs
	var items: Array = GameState.stash[tab] if unlocked else []
	for i in _slots.size():
		var s: ItemSlot = _slots[i]
		s.set_item(items[i] if i < items.size() else {})
		s.key = [tab, items[i]["uid"]] if i < items.size() else null
		s.compare_hero = W.current_hero()
		s.dim = not unlocked
		s.visible = unlocked
	var costs: Array = DataDB.bal("stash.tab_costs", [])
	_buy.visible = not unlocked and tab == GameState.stash_tabs
	if not unlocked:
		if _gold_tab():
			var cost: int = int(costs[min(GameState.stash_tabs, costs.size() - 1)])
			_buy.text = DataDB.t("buy_tab", {"g": F.fmt_num(cost)})
		else:
			_buy.text = DataDB.t("buy_tab_real", {"price": Shop.price_text(Shop.product("stash_tab"))})
	for ch in _cap.get_children():
		ch.queue_free()
	var n := items.size()
	_cap.add_child(Fancy.bar(_cap.size.x, 11, float(n) / maxf(1.0, _slots.size()), Color("#C9A04E") if n < _slots.size() else Color("#D0503A"),
		DataDB.t("stash_capacity", {"n": n, "m": _slots.size()}) if unlocked else DataDB.t("tab_locked")))
	_bed.queue_redraw()
	for k in _tabs.get_child_count():
		_tabs.get_child(k).queue_redraw()


## Sort the open tab: rarest first, then by slot, then by item level.
func _sort_tab() -> void:
	if tab >= GameState.stash_tabs:
		return
	var order := ["weapon", "offhand", "helm", "chest", "gloves", "boots", "belt", "cape", "amulet", "ring", "charm"]
	GameState.stash[tab].sort_custom(func(x, y):
		var rx := ItemUtil.rarity_rank(str(x.get("rarity", "common")))
		var ry := ItemUtil.rarity_rank(str(y.get("rarity", "common")))
		if rx != ry:
			return rx > ry
		var sx := order.find(str(x.get("slot", "")))
		var sy := order.find(str(y.get("slot", "")))
		if sx != sy:
			return sx < sy
		return int(x.get("ilvl", 0)) > int(y.get("ilvl", 0)))
	AudioManager.play("ui_click", 0.05, 0.6)
	refresh()


## Tabs 2 and 3 open with gold; further tabs are a real-money convenience.
func _gold_tab() -> bool:
	return GameState.stash_tabs < int(DataDB.bal("stash.gold_tabs", 3))


func _buy_tab() -> void:
	if not _gold_tab():
		var p := Shop.product("stash_tab")
		var txt := DataDB.t("stash_tab_confirm", {"price": Shop.price_text(p)})
		if SteamService.payment_mode() == "direct":
			txt += "\n" + DataDB.t("shop_test_note")
		W.confirm(content, txt, func():
			Shop.buy("stash_tab", func(res: Dictionary):
				if res.is_empty():
					EventBus.notify.emit(DataDB.t("shop_failed"), UITheme.C_RED)
					return
				AudioManager.play("coin", 0.05, 0.9)
				Toast.show_reward(UITheme.icon("chest"), DataDB.t("stash_tab_opened", {"n": GameState.stash_tabs}), "")
				_set_tab(GameState.stash_tabs - 1)), DataDB.t("shop_buy"))
		return
	var costs: Array = DataDB.bal("stash.tab_costs", [])
	var cost: int = int(costs[min(GameState.stash_tabs, costs.size() - 1)])
	if GameState.spend_gold(cost):
		GameState.stash_tabs += 1
		_set_tab(GameState.stash_tabs - 1)
	else:
		EventBus.notify.emit(DataDB.t("not_enough_gold"), UITheme.C_RED)


func _on_click(s: ItemSlot) -> void:
	if s.item.is_empty():
		return
	if not GameState.move_to_bag(tab, str(s.item["uid"])):
		EventBus.notify.emit(DataDB.t("bag_full"), UITheme.C_RED)
	WindowManager.hide_tooltip()


func _on_drop(_s: ItemSlot, data: Dictionary) -> void:
	if data.get("source", "") == "bag":
		GameState.move_to_stash(str(data["item"]["uid"]), tab)


func _all_to_bag() -> void:
	if tab >= GameState.stash_tabs:
		return
	for it in GameState.stash[tab].duplicate():
		if not GameState.move_to_bag(tab, it["uid"]):
			break


func _all_to_stash() -> void:
	if tab >= GameState.stash_tabs:
		return
	for it in GameState.bag.duplicate():
		if it.get("locked", false):
			continue
		if not GameState.move_to_stash(it["uid"], tab):
			break
