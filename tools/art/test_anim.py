import sys
from PIL import Image
from chars import *
from poses import *
from test_sheet import V
SP="/tmp/claude-0/-home-user--dlegamepc/83754d3e-dfa8-5878-aa29-a40ad9936a1f/scratchpad/"
rows=[]
anims=["idle","run","attack","skill","hit","death","victory"]
for v in V[: int(sys.argv[1]) if len(sys.argv)>1 else 8]:
    rig = build_rig("battle", v)
    m = rig.template
    fam = FAMILY[CLASS_WEAPON[v.cls]]
    A = anim_side(fam)
    frames=[]
    for an in anims:
        for p in A[an]:
            d = world_to_delta(rig.skeleton, {k:v2 for k,v2 in p.items() if not k.startswith("_")})
            a,_ = render(rig, d, (m["W"],m["H"]), ss=4, root_offset=p.get("_root",(0,0)), face_ctx=face_ctx(rig, expr=p.get("_expr","normal")))
            frames.append(to_image(a))
    rows.append(frames)
W,H=64,56; k=2
n=max(len(r) for r in rows)
sheet=Image.new("RGBA",(W*n*k//2, H*len(rows)*k),(54,46,60,255))
for j,r in enumerate(rows):
    for i,im in enumerate(r[:n//2*1+0] if False else r):
        if i >= n//2: break
        sheet.alpha_composite(im.resize((W*k,H*k),Image.NEAREST),(i*W*k,j*H*k))
sheet.save(SP+"anim_a.png")
sheet=Image.new("RGBA",(W*(n-n//2)*k, H*len(rows)*k),(54,46,60,255))
for j,r in enumerate(rows):
    for i,im in enumerate(r[n//2:]):
        sheet.alpha_composite(im.resize((W*k,H*k),Image.NEAREST),(i*W*k,j*H*k))
sheet.save(SP+"anim_b.png")
print(n)
