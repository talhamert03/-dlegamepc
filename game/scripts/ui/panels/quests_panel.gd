extends PanelWindow
## Daily quests with progress bars and claimable rewards.

var _body: VBoxContainer


func build(c: Control) -> void:
	_body = W.vbox(3)
	_body.size = c.size
	c.add_child(_body)
	refresh()


func refresh() -> void:
	if _body == null:
		return
	Quests.ensure_daily()
	for ch in _body.get_children():
		ch.queue_free()
	_body.add_child(UITheme.label(DataDB.t("daily_quests"), UITheme.C_ORANGE))
	var list: Array = GameState.flags.get("daily", {}).get("list", [])
	for i in list.size():
		var q: Dictionary = list[i]
		var p: float = min(Quests.progress(q), float(q["target"]))
		_body.add_child(UITheme.label(DataDB.t("quest_" + str(q["id"]), {"n": F.fmt_num(float(q["target"]))}), UITheme.C_TEXT))
		var row := W.hbox(2)
		_body.add_child(row)
		var b := UITheme.bar(110, 4, Color("#7FE07A"))
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.max_value = float(q["target"])
		b.value = p
		row.add_child(b)
		var rw: Array = []
		for k in q["reward"]:
			rw.append("%s %s" % [F.fmt_num(float(q["reward"][k])), DataDB.t("gold") if k == "gold" else ItemUtil.material_name(k)])
		var idx := i
		var cb := UITheme.button(DataDB.t("claimed") if q["claimed"] else DataDB.t("btn_claim"), "gold", func():
			if Quests.claim(idx):
				AudioManager.play("coins")
			refresh(), Vector2(36, 11))
		cb.disabled = q["claimed"] or Quests.progress(q) < float(q["target"])
		cb.tooltip_text = ", ".join(rw)
		row.add_child(cb)
		_body.add_child(UITheme.label(", ".join(rw), UITheme.C_DIM))
