import sys,os,glob
from PIL import Image,ImageOps
import pillow_heif; pillow_heif.register_heif_opener()
src,dst=sys.argv[1],sys.argv[2]
for sp in ['train','valid','test']:
    os.makedirs(os.path.join(dst,sp),exist_ok=True)
    for f in sorted(glob.glob(os.path.join(src,sp,'*.heic'))):
        im=ImageOps.exif_transpose(Image.open(f)).convert('RGB'); o=im.size
        im.thumbnail((1280,1280),Image.LANCZOS)
        im.save(os.path.join(dst,sp,os.path.basename(f)[:-5]+'.jpg'),quality=95)
    print(sp,len(os.listdir(os.path.join(dst,sp))),o,'->',im.size)
