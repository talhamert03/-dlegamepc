class_name SpriteLib
extends RefCounted
## Builds and caches SpriteFrames from generated sprite sheets.

static var _cache: Dictionary = {}
static var _meta: Dictionary = {}


static func _anim_meta(dir: String) -> Dictionary:
	if _meta.has(dir):
		return _meta[dir]
	var path := dir + "anims.json"
	var d: Dictionary = {}
	if FileAccess.file_exists(path):
		var p: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if p is Dictionary:
			d = p
	_meta[dir] = d
	return d


static func frames_for(kind: String, id: String) -> SpriteFrames:
	var key := kind + ":" + id
	if _cache.has(key):
		return _cache[key]
	var dir := "res://assets/sprites/heroes/" if kind == "hero" else "res://assets/sprites/enemies/"
	var meta := _anim_meta(dir)
	var path := dir + id + ".png"
	if not ResourceLoader.exists(path) or meta.is_empty():
		_cache[key] = null
		return null
	var tex: Texture2D = load(path)
	var info: Dictionary = meta.get("sheets", {}).get(id, meta)
	var fw: int = int(info.get("frame_w", meta.get("frame_w", 64)))
	var fh: int = int(info.get("frame_h", meta.get("frame_h", 56)))
	var anims: Dictionary = info.get("anims", meta.get("anims", {}))
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for an in anims:
		var a: Dictionary = anims[an]
		sf.add_animation(an)
		sf.set_animation_speed(an, float(a.get("fps", 8)))
		sf.set_animation_loop(an, bool(a.get("loop", false)))
		for i in int(a.get("count", 1)):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2((int(a["start"]) + i) * fw, 0, fw, fh)
			sf.add_frame(an, at)
	_cache[key] = sf
	return sf


static func sheet_info(kind: String, id: String) -> Dictionary:
	var dir := "res://assets/sprites/heroes/" if kind == "hero" else "res://assets/sprites/enemies/"
	var meta := _anim_meta(dir)
	var info: Dictionary = meta.get("sheets", {}).get(id, {})
	if info.is_empty():
		info = {"frame_w": meta.get("frame_w", 64), "frame_h": meta.get("frame_h", 56),
			"root": meta.get("root", [28, 54])}
	return info


static func impact_frame(kind: String, id: String, anim: String) -> int:
	var dir := "res://assets/sprites/heroes/" if kind == "hero" else "res://assets/sprites/enemies/"
	var meta := _anim_meta(dir)
	var info: Dictionary = meta.get("sheets", {}).get(id, meta)
	return int(info.get("anims", {}).get(anim, {}).get("impact", 3))


static var _hd: Dictionary = {}
static var _anim: Dictionary = {}


## Animated chibi sheet (6 x 4 cells: idle, move, attack, hurt+death) metadata:
## {"cw","ch","ax","ay","h","fly"} or {} when the unit has no sheet yet.
static func anim_meta(kind: String, id: String) -> Dictionary:
	if _anim.is_empty():
		var path := "res://assets/hd/anim/meta.json"
		if FileAccess.file_exists(path):
			var p: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if p is Dictionary:
				_anim = p
		if _anim.is_empty():
			_anim = {"_": {}}
	return _anim.get(kind, {}).get(id, {})


## First idle frame of a chibi sheet as a small texture (map markers, party slots); null without a sheet.
static func chibi_frame(kind: String, id: String, frame := 0) -> Texture2D:
	var tex := anim_sheet(kind, id)
	if tex == null:
		return null
	var m := anim_meta(kind, id)
	var cw := float(m["cw"])
	var ch := float(m["ch"])
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2((frame % 6) * cw, (frame / 6) * ch, cw, ch)
	return at


static func anim_sheet(kind: String, id: String) -> Texture2D:
	if anim_meta(kind, id).is_empty():
		return null
	var p := "res://assets/hd/anim/%s/%s.png" % [kind, id]
	return load(p) if ResourceLoader.exists(p) else null


## HD (AI-illustrated) art metadata: {kind: {id: {"w","h","foot_x"}}}
static func hd_meta(kind: String, id: String) -> Dictionary:
	if _hd.is_empty():
		var path := "res://assets/hd/meta.json"
		if FileAccess.file_exists(path):
			var p: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if p is Dictionary:
				_hd = p
		if _hd.is_empty():
			_hd = {"_": {}}
	return _hd.get(kind, {}).get(id, {})


## HD battle sprite (kind: "heroes" | "enemies"), or null when only the pixel sheet exists.
static func hd_sprite(kind: String, id: String) -> Texture2D:
	if hd_meta(kind, id).is_empty():
		return null
	var p := "res://assets/hd/%s/%s.png" % [kind, id]
	return load(p) if ResourceLoader.exists(p) else null


static func _tag_hd(t: Texture2D, lsize: Vector2) -> Texture2D:
	if t and not t.has_meta("hd"):
		t.set_meta("hd", true)
		t.set_meta("lsize", lsize)
	return t


static func portrait(id: String) -> Texture2D:
	var hd := "res://assets/hd/portraits/%s.png" % id
	if ResourceLoader.exists(hd):
		return _tag_hd(load(hd), Vector2(96, 144))
	var p := "res://assets/portraits/%s.png" % id
	return load(p) if ResourceLoader.exists(p) else null


static func hero_icon(id: String) -> Texture2D:
	var key := "icon:" + id
	if _cache.has(key):
		return _cache[key]
	var t: Texture2D = null
	var hd := "res://assets/hd/icons/%s.png" % id
	if ResourceLoader.exists(hd):
		t = _tag_hd(load(hd), Vector2(20, 20))
	else:
		var p := "res://assets/sprites/heroes/icons/%s.png" % id
		t = load(p) if ResourceLoader.exists(p) else null
	_cache[key] = t
	return t


static func item_icon(item: Dictionary) -> Texture2D:
	var bt: String = item.get("btype", "")
	var tier := int(item.get("tier", 0))
	var w: String = item.get("weight", "") if item.get("cat", "") in ["armor", "acc"] else ""
	# HD painted icon: plain look for tiers 0-2, ornate enchanted look from tier 3 on
	var hd_name := ("%s_%s" % [bt, w]) if w != "" else bt
	var hp := "res://assets/hd/items/%s_%s.png" % [hd_name, "b" if tier >= 3 else "a"]
	if _cache.has(hp):
		return _cache[hp]
	if ResourceLoader.exists(hp):
		var ht := _tag_hd(load(hp), Vector2(16, 16))
		_cache[hp] = ht
		return ht
	var cands := []
	if w != "":
		cands.append("res://assets/sprites/items/%s_%s_t%d.png" % [bt, w, tier])
	cands.append("res://assets/sprites/items/%s_t%d.png" % [bt, tier])
	cands.append("res://assets/sprites/items/%s.png" % bt)
	for c in cands:
		if _cache.has(c):
			return _cache[c]
		if ResourceLoader.exists(c):
			var t: Texture2D = _crisp(load(c))
			_cache[c] = t
			return t
	return null


## Pixel icon pre-scaled 4x (nearest) so it can be drawn at any size with smooth filtering and stay crisp.
static func _crisp(t: Texture2D) -> Texture2D:
	if t == null:
		return null
	var img := t.get_image()
	if img == null:
		return t
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(img.get_width() * 4, img.get_height() * 4, Image.INTERPOLATE_NEAREST)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func skill_icon(sid: String) -> Texture2D:
	var hp := "res://assets/hd/skills/%s.png" % sid
	if _cache.has(hp):
		return _cache[hp]
	if ResourceLoader.exists(hp):
		var ht := _tag_hd(load(hp), Vector2(20, 20))
		_cache[hp] = ht
		return ht
	var p := "res://assets/sprites/skills/%s.png" % sid
	if _cache.has(p):
		return _cache[p]
	var t: Texture2D = load(p) if ResourceLoader.exists(p) else null
	_cache[p] = t
	return t
