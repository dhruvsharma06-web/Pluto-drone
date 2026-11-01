import sys,os,glob
from ultralytics import YOLO
from PIL import Image,ImageDraw,ImageFont
w,src,out=sys.argv[1],sys.argv[2],sys.argv[3]; m=YOLO(w)
F=ImageFont.load_default(size=40); T=320
for sp in ['train','valid','test']:
    os.makedirs(f'{out}/labels/{sp}',exist_ok=True); fs=sorted(glob.glob(f'{src}/{sp}/*.jpg')); tiles=[]
    for i,f in enumerate(fs):
        r=m.predict(f,conf=0.25,iou=0.5,agnostic_nms=True,imgsz=800,verbose=False,device=0)[0]
        b=r.boxes; rows=[]
        im=Image.open(f).convert('RGB'); d=ImageDraw.Draw(im)
        for (x,y,ww,hh),c,p,(x1,y1,x2,y2) in zip(b.xywhn.tolist(),b.cls.tolist(),b.conf.tolist(),b.xyxy.tolist()):
            rows.append(f'{int(c)} {x:.6f} {y:.6f} {ww:.6f} {hh:.6f}')
            col=(0,255,255) if c==0 else (255,0,255)
            d.rectangle([x1,y1,x2,y2],outline=col,width=8); d.text((x1+6,y1+4),f"{'CW' if c==0 else 'CCW'} {p:.2f}",fill=col,font=F)
        d.text((10,10),f'{sp}{i}',fill=(255,255,0),font=F)
        open(f'{out}/labels/{sp}/'+os.path.basename(f)[:-4]+'.txt','w').write('\n'.join(rows)+('\n' if rows else ''))
        im.thumbnail((T,T)); tiles.append(im)
    for k in range(0,len(tiles),20):
        M=Image.new('RGB',(5*T,4*T),'white')
        for j,t in enumerate(tiles[k:k+20]): M.paste(t,((j%5)*T,(j//5)*T))
        M.save(f'{out}/sheet_{sp}_{k//20}.jpg',quality=85)
    print(sp,len(fs))
