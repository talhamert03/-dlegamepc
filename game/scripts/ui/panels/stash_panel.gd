extends PanelWindow
## Shared stash with 7 purchasable tabs (6x6 each).

var tab := 0
var _tabs: HBoxContainer
var _grid: GridContainer
var _slots: Array = []
var _info: Label
var _buy: Button


func build(c: Control) -> void:
	var v := W.vbox(2)
	v.size = c.size
	c.add_child(v)
	_tabs = W.hbox(1)
	v.add_child(_tabs)
	for i in 7:
		var b := UITheme.button(str(i + 1), "brown", Callable(), Vector2(18, 12))
		var idx := i
		b.pressed.connect(func(): _set_tab(idx))
		_tabs.add_child(b)
	_grid = W.grid(6, 1)
	v.add_child(_grid)
	for i in int(DataDB.bal("stash.slots_per_tab", 36)):
		var s := ItemSlot.new()
		s.source = "stash"
		s.left_clicked.connect(_on_click)
		s.right_clicked.connect(_on_click)
		s.dropped.connect(_on_drop)
		_grid.add_child(s)
		_slots.append(s)
	_info = UITheme.label("", UITheme.C_DIM)
	v.add_child(_info)
	var bh := W.hbox(2)
	v.add_child(bh)
	_buy = UITheme.button("", "gold", _buy_tab)
	bh.add_child(_buy)
	bh.add_child(UITheme.button(DataDB.t("btn_to_bag"), "brown", _all_to_bag))
	bh.add_child(UITheme.button(DataDB.t("btn_to_stash"), "brown", _all_to_stash))
	EventBus.inventory_changed.connect(refresh)
	_set_tab(0)


func _set_tab(i: int) -> void:
	tab = i
	for k in _tabs.get_child_count():
		UITheme.set_button_color(_tabs.get_child(k), "orange" if k == i else ("brown" if k < GameState.stash_tabs else "gray"))
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
	var costs: Array = DataDB.bal("stash.tab_costs", [])
	_buy.visible = not unlocked
	if not unlocked:
		if _gold_tab():
			var cost: int = int(costs[min(GameState.stash_tabs, costs.size() - 1)])
			_buy.text = DataDB.t("buy_tab", {"g": F.fmt_num(cost)})
		else:
			_buy.text = DataDB.t("buy_tab_real", {"price": Shop.price_text(Shop.product("stash_tab"))})
		_info.text = DataDB.t("tab_locked")
	else:
		_info.text = "%d/%d" % [items.size(), _slots.size()]


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
