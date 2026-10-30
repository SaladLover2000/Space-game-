"""Software composition of exported runtime geometry; never a gameplay screenshot."""
from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
import json,math,sys
scratch,project,out=map(Path,sys.argv[1:4]);data=json.loads((scratch/'visual-actions.json').read_text())
W,H=map(int,data['size']);PW,PH=600,360
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',18)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',15)
sheet=Image.new('RGBA',(PW*3+32,(PH+40)*3+84),'#0a1220');title=ImageDraw.Draw(sheet)
title.text((12,8),'LITTLE ORBIT / SOFTWARE ASSET & POSE PREVIEW — NOT A GAMEPLAY SCREENSHOT',font=font,fill='#f5e9cd')
def box(dr,r,fill,outline=None,width=1):
 x,y,w,h=r;dr.rectangle((x,y,x+w,y+h),fill=fill,outline=outline,width=width)
def paste(canvas,img,src,dest):
 x,y,w,h=src;dx,dy,dw,dh=dest
 crop=img.crop(tuple(round(v) for v in (x,y,x+w,y+h))).resize((max(1,round(dw)),max(1,round(dh))),Image.Resampling.NEAREST)
 canvas.alpha_composite(crop,(round(dx),round(dy)))
def actors(canvas,actors):
 for actor in actors:
  ox,oy=actor['feet'];s=actor['scale']
  for part in actor['pieces']:
   x,y,w,h=part['source'];texture=Image.open(scratch/part['texture']).convert('RGBA').crop(tuple(round(v) for v in (x,y,x+w,y+h)))
   pts=[(ox+p[0]*s,oy+p[1]*s) for p in part['points']]
   px,py=pts[0];ax,ay=pts[1][0]-px,pts[1][1]-py;bx,by=pts[3][0]-px,pts[3][1]-py;det=ax*by-ay*bx
   if abs(det)<0.0001:continue
   a=by/det*texture.width;b=-bx/det*texture.width;c=-a*px-b*py;d=-ay/det*texture.height;e=ax/det*texture.height;f=-d*px-e*py
   canvas.alpha_composite(texture.transform(canvas.size,Image.Transform.AFFINE,(a,b,c,d,e,f),Image.Resampling.NEAREST))
def part(dr,kind,p,s=2):
 x,y=p
 if kind%3==0:
  pts=[(x+math.cos(i*math.tau/32)*(5 if i%4 in(0,3) else 6)*s,y+math.sin(i*math.tau/32)*(5 if i%4 in(0,3) else 6)*s) for i in range(32)]
  dr.polygon(pts,fill='#162433')
  for i in range(8):box(dr,(x+math.cos(i*math.tau/8)*3.6*s-s,y+math.sin(i*math.tau/8)*3.6*s-s,2*s,2*s),'#d7d0b8')
  box(dr,(x-1.8*s,y-1.8*s,3.6*s,3.6*s),'#b98b48');box(dr,(x-.8*s,y-.8*s,1.6*s,1.6*s),'#162433')
 else:
  box(dr,(x-5*s,y-3*s,10*s,6*s),'#162433');box(dr,(x-4*s,y-2*s,8*s,4*s),'#d7d0b8')
  for i in (-3,3):box(dr,(x+i*s,y-3.5*s,1.5*s,7*s),'#b98b48')
def rack(dr):
 box(dr,(W*.79,H*.65,W*.19,H*.13),'#142331')
 for y in (.08,.54,.92):
  box(dr,(W*.79,H*(.65+.13*y),W*.19,H*.13*.07),'#162433');box(dr,(W*.79,H*(.65+.13*y),W*.19,1),'#b98b48')
 for x in (.02,.93):box(dr,(W*(.79+.19*x),H*.65,W*.19*.05,H*.13),'#586873')
 box(dr,(W*.73-3,H*.79-3,W*.12+6,H*.07+6),'#172330')
 box(dr,(W*.73,H*.79,W*.12,H*.07*.16),'#bb9559')
 for x in(.735,.84):box(dr,(W*x,H*.85,W*.008,H*.10),'#64717b')
for idx,frame in enumerate(data['frames']):
 original=Image.open(scratch/frame['background']).convert('RGBA')
 panel=original.resize((W,H),Image.Resampling.NEAREST);dr=ImageDraw.Draw(panel)
 kind=frame['kind']
 if kind=='bridge':
  sky=Image.open(scratch/frame['sky']).convert('RGBA').resize((W,H),Image.Resampling.NEAREST)
  mask=Image.new('L',(W,H));ImageDraw.Draw(mask).polygon([tuple(p) for p in frame['corners']],fill=255);panel.paste(sky,(0,0),mask);dr=ImageDraw.Draw(panel)
  for x,y in frame['stars']:box(dr,(x,y,1,1),'#9baec0')
  for planet in frame['planets']:
   layer=Image.new('RGBA',(W,H));tex=Image.open(scratch/planet['texture']).convert('RGBA');paste(layer,tex,(0,0,*tex.size),planet['rect']);layer.putalpha(Image.composite(layer.getchannel('A'),Image.new('L',(W,H)),mask));panel.alpha_composite(layer)
  dr=ImageDraw.Draw(panel);box(dr,frame['keyboard'],'#10202c');x,y,w,h=frame['keyboard']
  for r in range(2):
   for c in range(12):box(dr,(x+w*c/12,y+h*r/2,w*.065,h*.32),'#b7b7a7')
 elif kind=='charging':
  tex=Image.open(project/'assets/art/cabin-fixtures-v1.png').convert('RGBA')
  paste(panel,tex,(95,20,660,740),(0,0,35/77*W,46/49*H));paste(panel,tex,(985,105,970,620),(36/77*W,0,34/77*W,46/49*H))
 elif kind=='engine':
  for sup in frame['supports']:
   x,y,w,h=sup['rect']
   for px in(x+w*.15,x+w*.85):
    box(dr,(px-3,y+h,6,max(0,sup['floor']-y-h)),'#162433');box(dr,(px-1,y+h,2,max(0,sup['floor']-y-h)),'#586873');box(dr,(px-9,sup['floor']-3,18,6),'#162433')
    for cy in range(int(sup['ceiling']),int(y),6):box(dr,(px-2,cy,4,4),None,'#586873')
   box(dr,(x-4,y+h,w+8,5),'#b98b48')
  if frame['task']!=3:
   for band,color in enumerate(('#52616c','#bac1bc','#7e8b8d','#495a66','#24333e')):box(dr,(W*.49,H*.46+H*.035*band/5,W*.30,H*.035/5+1),color)
   for f in (.04,.34,.65,.95):box(dr,(W*(.49+f*.30)-1,H*.46-2,3,H*.035+4),'#b79660')
  for y in(.28,.58):
   points=[(W*.18,H*y),(W*.18,H*(y-.06)),(W*.69,H*(y-.06)),(W*.69,H*y)];dr.line(points,fill='#352f28',width=7);dr.line(points,fill='#b58c55',width=3)
  atlas=Image.open(scratch/frame['atlas']).convert('RGBA')
  for a in frame['assemblies']:paste(panel,atlas,a['source'],a['rect'])
  dr=ImageDraw.Draw(panel)
  if frame['task']<3:
   rack(dr)
   for p in frame['sort_parts']:part(dr,p['id'],p['position'],H/260)
  else:
   for part_data in frame['tray_parts']:
    r=part_data['rect'];box(dr,r,'#152535','#bc965d',2);paste(panel,atlas,part_data['source'],(r[0]+6,r[1]+6,r[2]-12,r[3]-12))
 elif kind=='hull':
  # Exterior bitmap has a calibrated 333 x228 world rectangle at (-33,-39).
  panel=Image.new('RGBA',(W,H),'#0a1220')
  for x,y,w,h in frame['skin_regions']:
   paste(panel,original,((x+33)/333*original.width,(y+39)/228*original.height,w/333*original.width,h/228*original.height),(35+(x+33)/333*830,(y+39)/228*540,w/333*830,h/228*540))
  components=Image.open(scratch/frame['engine_atlas']).convert('RGBA')
  dr=ImageDraw.Draw(panel)
  for mount in frame.get('mounts',[]):
   x,y,w,h=mount['rect'];box(dr,(35+(x+33)/333*830,(y+39)/228*540,w/333*830,h/228*540),'#'+mount['color'])
  for p in frame['engine_parts']:
   x,y,w,h=p['rect'];paste(panel,components,p['source'],(35+(x+33)/333*830,(y+39)/228*540,w/333*830,h/228*540))
  dr=ImageDraw.Draw(panel)
  def tr(p):return (35+(p[0]+33)/333*830,(p[1]+39)/228*540)
  surface=panel.copy()
  for poly in frame['plates']:
   pts=[tr(p) for p in poly];cx=sum(x for x,y in pts)/len(pts);cy=sum(y for x,y in pts)/len(pts)
   dr.polygon(pts,fill='#152331');inner=[(x*.93+cx*.07,y*.93+cy*.07) for x,y in pts]
   mask=Image.new('L',panel.size);ImageDraw.Draw(mask).polygon(inner,fill=255);panel.paste(surface,(0,0),mask);dr=ImageDraw.Draw(panel);dr.line(inner+[inner[0]],fill='#e3dac2',width=2)
   for x,y in pts:
    bx=x*.77+cx*.23;by=y*.77+cy*.23;box(dr,(bx-2,by-2,4,4),'#253541');box(dr,(bx-1,by-1,2,2),'#c49b56')
   dr.line([inner[0],inner[1]],fill='#566877',width=2)
 actors(panel,frame['actors'])
 dr=ImageDraw.Draw(panel)
 if kind=='bridge':
  ow,oh=original.size;paste(panel,original,(ow*.277,oh*.65,ow*.245,oh*.29),(W*.277,H*.65,W*.245,H*.29))
 if kind=='engine' and frame['task']==2 and frame['held']>=0:part(dr,frame['held'],frame['hand'],H/260)
 if kind=='engine' and frame['task']==1:
  hx,hy=frame['hand'];s=frame['scale'];pts=[(-.7,2),(.7,2),(.7,-3.8),(2.1,-5),(2.1,-7),(1.1,-7),(.8,-5.6),(-.8,-5.6),(-1.1,-7),(-2.1,-7),(-2.1,-5),(-.7,-3.8)]
  dr.polygon([(hx+x*s,hy+y*s) for x,y in pts],fill='#b8c1bc');dr.line([(hx,hy+1.5*s),(hx,hy-4.7*s)],fill='#586873',width=2)
 x=8+(idx%3)*(PW+8);y=40+(idx//3)*(PH+40)
 sheet.alpha_composite(panel.resize((PW,PH),Image.Resampling.NEAREST),(x,y));title.text((x+3,y+PH+5),frame['name'],font=small,fill='#eee1c2')
title.text((12,sheet.height-25),'Actual textures and exported joint/window/assembly geometry; software composition, not GPU or desktop capture.',font=small,fill='#a7b5c6')
sheet.convert('RGB').save(out)
print(out)
