"""Software asset/pose preview, not a GPU screenshot or gameplay capture."""
import json,math,sys
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
scratch,project=map(Path,sys.argv[1:3])
art=project/'assets/art'
data=json.loads((scratch/'room-preview.json').read_text())
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',19)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',14)
W,H=520,340
out=Image.new('RGBA',(W*3+32,H*2+128),'#070d17')
draw=ImageDraw.Draw(out)
draw.text((16,8),'ROOM & ROBOT SOFTWARE PREVIEW / actual game assets and joint geometry',font=font,fill='#bde5df')
fixture=Image.open(art/'cabin-fixtures-v1.png').convert('RGBA')
atlas=Image.open(art/'engine-modules-v1.png').convert('RGBA')
def paste_region(canvas,image,source,dest):
 x,y,w,h=source;dx,dy,dw,dh=dest
 image=image.crop(tuple(round(v) for v in (x,y,x+w,y+h))).resize((max(1,round(dw)),max(1,round(dh))),Image.Resampling.NEAREST)
 canvas.alpha_composite(image,(round(dx),round(dy)))
def actor(canvas,frame,sx,sy,ox,oy):
 for part in frame['pieces']:
  source=part['source'];x,y,w,h=source
  texture=Image.open(scratch/part['texture']).convert('RGBA').crop(tuple(round(v) for v in (x,y,x+w,y+h)))
  pts=[(ox+v[0]*sx,oy+v[1]*sy) for v in part['points']]
  px,py=pts[0];ax,ay=pts[1][0]-px,pts[1][1]-py;bx,by=pts[3][0]-px,pts[3][1]-py
  det=ax*by-ay*bx
  if abs(det)<0.0001:continue
  a=by/det*texture.width;b=-bx/det*texture.width;c=-a*px-b*py
  d=-ay/det*texture.height;e=ax/det*texture.height;f=-d*px-e*py
  warped=texture.transform(canvas.size,Image.Transform.AFFINE,(a,b,c,d,e,f),Image.Resampling.NEAREST)
  canvas.alpha_composite(warped)
for i,frame in enumerate(data['frames']):
 name=frame['name']
 if name.startswith('engine'):
  panel=Image.open(art/'engine-bay-mounts-v1.png').convert('RGBA').resize((W,H),Image.Resampling.NEAREST)
  for part in frame['engine']:
   x,y,w,h=part['rect'];paste_region(panel,atlas,part['source'],(x*W,y*H,w*W,h*H))
   if part['tier']==3:
    dr=ImageDraw.Draw(panel);dr.line([(x*W+w*W*.2,y*H+h*H*.86),(x*W+w*W*.2,y*H+h*H*.86+10),(x*W+w*W*.85,y*H+h*H*.86+10),(x*W+w*W*.85,y*H+h*H*.86-5)],fill='#aa8050',width=3)
  actor(panel,frame,H/80,H/80,W*.20,H*.96)
 elif name=='bridge-seated':
  panel=Image.open(art/'immersive-cockpit-damaged-v2.png').convert('RGBA').resize((W,H),Image.Resampling.NEAREST)
  # Bridge window sky is a live game layer; this preview shows its dark pixel-space color.
  ImageDraw.Draw(panel).polygon([(W*.10,H*.15),(W*.88,H*.15),(W*.92,H*.45),(W*.08,H*.45)],fill='#0a1328')
  actor(panel,frame,H/60,H/60,W*.405,H*.96)
  original=Image.open(art/"immersive-cockpit-damaged-v2.png").convert("RGBA");ow,oh=original.size
  paste_region(panel,original,(ow*.277,oh*.65,ow*.245,oh*.29),(W*.277,H*.65,W*.245,H*.29))
 else:
  panel=Image.open(scratch/(name+'-background.png')).convert('RGBA').resize((W,H),Image.Resampling.NEAREST)
  paste_region(panel,fixture,(95,20,660,740),(0,0,35/77*W,46/49*H))
  paste_region(panel,fixture,(985,105,970,620),(36/77*W,0,34/77*W,46/49*H))
  actor(panel,frame,W/77,H/49,(58 if name=='quarters-working' else 18)/77*W,46/49*H)
  if name=='charging':ImageDraw.Draw(panel).text((W*.31,H*.12),'z z z',font=font,fill='#b2c8d0')
 x=8+(i%3)*(W+8);y=42+(i//3)*(H+40)
 out.alpha_composite(panel,(x,y))
 label={'charging':'Charging / optics off, orange core','charged':'Full battery / blue optics restored','quarters-working':'Workbench / connected bending pose','engine-damaged':'Damaged assemblies / maintenance','engine-upgraded':'Installed maximum-tier machinery','bridge-seated':'Rear seated navigation pose'}[name]
 draw.text((x+5,y+H+5),label,font=small,fill='#e1e4da')
draw.text((16,out.height-24),'Software composition from game textures and exported vertices. No visible game window was opened.',font=small,fill='#a8b9c9')
out.convert('RGB').save(scratch/'room-refinement-software-preview.png')
