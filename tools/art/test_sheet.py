import sys
from PIL import Image
from chars import *
SP="/tmp/claude-0/-home-user--dlegamepc/83754d3e-dfa8-5878-aa29-a40ad9936a1f/scratchpad/"
V = [
 Variant("knight", hair="#2B2B3A", hair_style="short", eye="#5A6B8C", primary="#3D6FD6", secondary="#5B6475", female=False),
 Variant("berserker", hair="#C2502E", hair_style="spiky", eye="#4D8A5A", skin="#E2A882", female=False, beard=True),
 Variant("archer", hair="#F2CC5E", hair_style="ponytail", ears="elf"),
 Variant("assassin", hair="#2A2430", hair_style="short", eye="#C9414B", primary="#C9414B"),
 Variant("mage", hair="#E8E6F2", hair_style="long", eye="#6B5BD6", primary="#4A55B8", secondary="#2E3270", accent="#7FD8FF"),
 Variant("necromancer", hair="#3A3046", hair_style="short", eye="#7CE07A", primary="#5C3E80", skin="#E2C8C0", female=False),
 Variant("cleric", hair="#F5D57A", hair_style="twin", eye="#4FA0D8", primary="#E8B84A", secondary="#F4F0F6", accent="#FF9AC8"),
 Variant("bard", hair="#8A5A3A", hair_style="short", eye="#3E9E6A", primary="#3E9E6A", secondary="#E58A3A", female=False),
]
if __name__=="__main__":
    tpl = sys.argv[1] if len(sys.argv)>1 and __name__=="__main__" else "battle"
    imgs=[]
    for v in V:
        rig = build_rig(tpl, v)
        m = rig.template
        a,_ = render(rig, {}, (m["W"], m["H"]), ss=4, face_ctx=face_ctx(rig))
        imgs.append(to_image(a))
    W,H = imgs[0].size
    k = 4 if tpl=="battle" else 2
    sheet = Image.new("RGBA",(W*len(imgs)*k, H*k),(54,46,60,255))
    for i,im in enumerate(imgs):
        bg = Image.new("RGBA",(W,H),(0,0,0,0)); bg.alpha_composite(im)
        sheet.alpha_composite(bg.resize((W*k,H*k),Image.NEAREST),(i*W*k,0))
    sheet.save(SP+f"sheet_{tpl}.png")
    print(sheet.size)
