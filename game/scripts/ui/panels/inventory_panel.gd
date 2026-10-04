extends PanelWindow
## Inventory: equipment of the selected hero, filters and the bag grid.

const EQUIP_LAYOUT := ["weapon", "helm", "chest", "gloves", "boots", "belt", "offhand", "cape", "amulet", "ring1", "ring2", "charm"]
const FILTERS := ["all", "weapon", "armor", "acc"]
const SLOT_ICONS := {"weapon": "sword", "offhand": "shield", "helm": "crown", "chest": "shield", "gloves": "hammer", "boots": "boot",
	"belt": "bag", "cape": "flag", "amulet": "gem", "ring1": "gem", "ring2": "gem", "charm": "sparkle"}

var filter := 0
var _equip_slots: Dictionary = {}
var _bag_grid: GridContainer
var _bag_slots: Array = []
var _filters: HBoxContainer
var _count: Label
var _sel_box: HBoxContainer
var _ctx_uid := ""


func build(c: Control) -> void:
	var v := W.vbox(2)
	v.size = c.size
	c.add_child(v)
	var eq := W.grid(6, 2)
	v.add_child(eq)
	for s in EQUIP_LAYOUT:
		var slot := ItemSlot.new()
		slot.source = "equip"
		slot.key = s
		slot.placeholder = UITheme.icon(SLOT_ICONS.get(s, "star"))
		slot.left_clicked.connect(_on_equip_click)
		slot.right_clicked.connect(_on_equip_click)
		slot.dropped.connect(_on_drop_equip)
		eq.add_child(slot)
		_equip_slots[s] = slot
	_filters = W.tabs([DataDB.t("tab_all"), DataDB.t("filter_weapon"), DataDB.t("filter_armor"), DataDB.t("filter_acc")], filter, _on_filter, (c.size.x - 6.0) / 4.0)
	v.add_child(_filters)
	var sc := W.scroll(Vector2(c.size.x, c.size.y - 98))
	v.add_child(sc)
	_bag_grid = W.grid(7, 1)
	sc.add_child(_bag_grid)
	var bottom := W.hbox(2)
	v.add_child(bottom)
	bottom.add_child(UITheme.button(DataDB.t("panel_stash"), "orange", func(): WindowManager.toggle_panel("stash")))
	bottom.add_child(UITheme.button(DataDB.t("panel_blacksmith"), "orange", func(): WindowManager.toggle_panel("blacksmith")))
	var sb := UITheme.icon_button("sort", func(): GameState.sort_bag(), DataDB.t("tip_sort"))
	bottom.add_child(sb)
	var sell := UITheme.button(DataDB.t("btn_sell_junk"), "red", _sell_junk)
	sell.tooltip_text = DataDB.t("tip_sell_junk")
	bottom.add_child(sell)
	_count = UITheme.label("", UITheme.C_DIM)
	bottom.add_child(_count)
	_sel_box = W.hbox(1)
	v.add_child(_sel_box)
	EventBus.inventory_changed.connect(refresh)
	EventBus.equipment_changed.connect(func(_h): refresh())
	refresh()


func _on_filter(i: int) -> void:
	filter = i
	W.set_tab_active(_filters, i)
	refresh()


func _matches(it: Dictionary) -> bool:
	match FILTERS[filter]:
		"weapon":
			return it.get("cat", "") == "weapon" or it.get("cat", "") == "offhand"
		"armor":
			return it.get("cat", "") == "armor"
		"acc":
			return it.get("cat", "") == "acc"
	return true


func refresh() -> void:
	if _bag_grid == null:
		return
	var hid := W.current_hero()
	var h: HeroState = GameState.heroes.get(hid)
	for s in EQUIP_LAYOUT:
		var slot: ItemSlot = _equip_slots[s]
		slot.set_item(h.equipment.get(s, {}) if h else {})
		slot.compare_hero = hid
	var items: Array = GameState.bag.filter(_matches)
	var need: int = max(GameState.bag_slots if filter == 0 else items.size(), 7)
	while _bag_slots.size() < need:
		var sl := ItemSlot.new()
		sl.source = "bag"
		sl.left_clicked.connect(_on_bag_click)
		sl.right_clicked.connect(_on_bag_right)
		sl.dropped.connect(_on_drop_bag)
		_bag_grid.add_child(sl)
		_bag_slots.append(sl)
	for i in _bag_slots.size():
		var sl: ItemSlot = _bag_slots[i]
		sl.visible = i < need
		sl.compare_hero = hid
		sl.set_item(items[i] if i < items.size() else {})
		sl.key = items[i]["uid"] if i < items.size() else null
		sl.selected = WindowManager.is_open("blacksmith") and WindowManager.panels["blacksmith"].is_selected(sl.key)
	_count.text = "%d/%d" % [GameState.bag.size(), GameState.bag_slots]
	for ch in _sel_box.get_children():
		ch.queue_free()
	_sel_box.add_child(W.hero_selector(hid, W.select_hero))


func _on_equip_click(slot: ItemSlot) -> void:
	if slot.item.is_empty():
		return
	GameState.unequip(W.current_hero(), str(slot.key))
	WindowManager.hide_tooltip()


func _on_bag_click(slot: ItemSlot) -> void:
	if slot.item.is_empty():
		return
	var uid: String = slot.item["uid"]
	if WindowManager.is_open("blacksmith"):
		WindowManager.panels["blacksmith"].pick_item(uid)
		refresh()
		return
	if Input.is_key_pressed(KEY_SHIFT):
		GameState.sell_item(uid)
		return
	if Input.is_key_pressed(KEY_CTRL):
		GameState.toggle_lock(uid)
		return
	if WindowManager.is_open("stash") and Input.is_key_pressed(KEY_ALT):
		GameState.move_to_stash(uid, WindowManager.panels["stash"].tab)
		return
	var err := GameState.equip_from_bag(W.current_hero(), uid)
	if err != "":
		EventBus.notify.emit(err, UITheme.C_RED)
	WindowManager.hide_tooltip()


func _on_bag_right(slot: ItemSlot) -> void:
	if slot.item.is_empty():
		return
	_ctx_uid = slot.item["uid"]
	var locked: bool = slot.item.get("locked", false)
	ContextMenu.open([
		[DataDB.t("ctx_equip"), func(): _on_ctx(0)],
		[DataDB.t("ctx_stash"), func(): _on_ctx(1)],
		[DataDB.t("ctx_sell") + "  (%s)" % F.fmt_num(ItemUtil.sell_price(slot.item)), func(): _on_ctx(2), Color("#F2C45A")],
		[DataDB.t("ctx_salvage"), func(): _on_ctx(3)],
		[DataDB.t("ctx_unlock") if locked else DataDB.t("ctx_lock"), func(): _on_ctx(4)],
	], WindowManager.desktop.get_local_mouse_position())


func _on_ctx(id: int) -> void:
	match id:
		0:
			var err := GameState.equip_from_bag(W.current_hero(), _ctx_uid)
			if err != "":
				EventBus.notify.emit(err, UITheme.C_RED)
		1:
			var tab := 0
			if WindowManager.is_open("stash"):
				tab = WindowManager.panels["stash"].tab
			if not GameState.move_to_stash(_ctx_uid, tab):
				EventBus.notify.emit(DataDB.t("stash_full"), UITheme.C_RED)
		2:
			GameState.sell_item(_ctx_uid)
		3:
			GameState.salvage_item(_ctx_uid)
		4:
			GameState.toggle_lock(_ctx_uid)


func _on_drop_equip(slot: ItemSlot, data: Dictionary) -> void:
	if data.get("source", "") == "bag":
		var err := GameState.equip_from_bag(W.current_hero(), str(data["item"]["uid"]), str(slot.key))
		if err != "":
			EventBus.notify.emit(err, UITheme.C_RED)


func _on_drop_bag(_slot: ItemSlot, data: Dictionary) -> void:
	match data.get("source", ""):
		"equip":
			GameState.unequip(W.current_hero(), str(data["key"]))
		"stash":
			GameState.move_to_bag(int(data["key"][0]), str(data["item"]["uid"]))


func _sell_junk() -> void:
	var total := 0
	for it in GameState.bag.duplicate():
		if it.get("locked", false):
			continue
		if ItemUtil.rarity_rank(it.get("rarity", "common")) <= ItemUtil.rarity_rank("magic"):
			total += GameState.sell_item(it["uid"])
	if total > 0:
		EventBus.notify.emit(DataDB.t("sold_for", {"g": F.fmt_num(total)}), UITheme.C_GOLD)
