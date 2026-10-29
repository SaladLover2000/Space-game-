from pathlib import Path
import json,math,sys
from PIL import Image,ImageDraw,ImageFont
w=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parent
p=Path(sys.argv[2]) if len(sys.argv)>2 else Path(__file__).resolve().parents[1]
data=json.loads((w/'visual-preview.json').read_text())
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',21)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',15)
result=Image.new('RGBA',(1380,620),'#070d17');dr=ImageDraw.Draw(result)
dr.text((24,12),'GAME-ASSET SOFTWARE PREVIEW / cream armor, panel paint and chain service hoist',font=font,fill='#bde5df')
bg=Image.open(p/'assets/art/robot-workshop-v1.png').convert('RGBA')
hardware=Image.open(p/'assets/art/maintenance-hardware-v1.png').convert('RGBA')
def draw_piece(canvas,atlas,src,rect,theta=0,lift=0,config=None):
    x,y,ww,hh=rect;y-=lift
    crop=atlas.crop(tuple(round(v) for v in (src[0],src[1],src[0]+src[2],src[1]+src[3])))
    scale=min((canvas.width-12)/68,(canvas.height-12)/74)
    ox=(canvas.width-68*scale)/2+34*scale;oy=(canvas.height-74*scale)/2+65*scale
    if config: scale,ox,oy=config
    c=math.cos(theta);s=math.sin(theta);px=x+ww/2;py=y
    a=c/scale*crop.width/ww;b=s/scale*crop.width/ww
    cc=(c*(-ox/scale-px)+s*(-oy/scale-py)+ww/2)*crop.width/ww
    d=-s/scale*crop.height/hh;e=c/scale*crop.height/hh
    f=(-s*(-ox/scale-px)+c*(-oy/scale-py))*crop.height/hh
    warped=crop.transform(canvas.size,Image.Transform.AFFINE,(a,b,cc,d,e,f),Image.Resampling.NEAREST)
    canvas.alpha_composite(warped)
for index,robot in enumerate(data['robots']):
    panel=bg.resize((440,510),Image.Resampling.NEAREST)
    if index<2:
        for part in data['lift']:draw_piece(panel,hardware,part['source'],part['rect'])
    atlas=Image.open(w/f"preview-{robot['name']}-atlas.png").convert('RGBA')
    for part in robot['pieces']: draw_piece(panel,atlas,part['source'],part['rect'],part['rotation'],8 if index<2 else 0)
    result.alpha_composite(panel,(20+index*460,52))
    dr.text((30+index*460,570),['Ivory ceramic / hoisted','Crimson panels + ivory / hoisted','Articulated service pose'][index],font=font,fill='#e5e5d8')
dr.text((24,602),'Rendered from the actual game textures and joint poses; this is not a captured game window.',font=small,fill='#a8b9c9')
result.convert('RGB').save(w/'robot-service-software-preview.png')
ship=Image.new('RGBA',(1536,1024),'#040a16');ship.alpha_composite(Image.open(w/'preview-painted-hull.png').convert('RGBA'))
fin_atlas=Image.open(w/'preview-fins-atlas.png').convert('RGBA')
for part in data['fins']:
    sx,sy,sw,sh=part['source'];crop=fin_atlas.crop((round(sx),round(sy),round(sx+sw),round(sy+sh)))
    x,y,ww,hh=part['rect'];dest=(round((x+33)*1536/333),round((y+39)*1024/228));extent=(round(ww*1536/333),round(hh*1024/228))
    crop=crop.resize(extent,Image.Resampling.NEAREST)
    if part['flip_y']:crop=crop.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    ship.alpha_composite(crop,dest)
ship.convert('RGB').save(w/'ship-paint-fins-software-preview.png')

bridge=Image.open(w/'preview-bridge-bg.png').convert('RGBA').resize((1380,600),Image.Resampling.NEAREST)
back=Image.open(w/'preview-bridge-atlas.png').convert('RGBA')
actor=data['bridge']
for part in actor['pieces']: draw_piece(bridge,back,part['source'],part['rect'],part['rotation'],config=(actor['scale'],*actor['feet']))
bridge.convert('RGB').save(w/'bridge-software-preview.png')

