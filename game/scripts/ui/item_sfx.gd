class_name ItemSfx
extends RefCounted
## Item handling sounds by material: blades ring out of the scabbard, plate and mail clank, bows creak and
## twang, leather rustles, jewellery tinkles, staves and orbs shimmer, instruments are plucked.

const WEIGHT_CAT := {"heavy": "metal", "medium": "metal", "holy": "cloth", "light": "cloth"}
const TYPE_CAT := {
	"sword": "blade", "greatsword": "blade", "axe": "blade", "dagger": "blade", "scythe": "blade", "dagger_off": "blade",
	"mace": "metal", "shield": "metal", "scepter": "metal",
	"bow": "bow", "crossbow": "bow", "quiver": "bow",
	"staff": "magic", "holy_staff": "magic", "wand": "magic", "orb": "magic", "tome": "magic",
	"lute": "music", "flute": "music",
	"ring": "jewel", "amulet": "jewel", "charm": "jewel",
	"belt": "cloth", "cape": "cloth",
}


static func category(item: Dictionary) -> String:
	if item.is_empty():
		return "cloth"
	var bt := str(item.get("btype", ""))
	if TYPE_CAT.has(bt):
		return TYPE_CAT[bt]
	return WEIGHT_CAT.get(str(item.get("weight", "")), "cloth")


## Picked up / clicked / started dragging.
static func pick(item: Dictionary) -> void:
	if not item.is_empty():
		AudioManager.play("pick_" + category(item), 0.06, 0.55)


## Put on a hero.
static func equip(item: Dictionary) -> void:
	if not item.is_empty():
		AudioManager.play("equip_" + category(item), 0.05, 0.7)


## Put down in the bag / stash.
static func drop() -> void:
	AudioManager.play("item_drop", 0.08, 0.5)
