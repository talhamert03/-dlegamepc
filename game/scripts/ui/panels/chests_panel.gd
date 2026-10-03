extends PanelWindow
## Treasure chests window (also shown as a tab of the hero window): see ChestsView.


func build(c: Control) -> void:
	var v := ChestsView.new()
	v.size = c.size
	c.add_child(v)
