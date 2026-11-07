import sys,glob,os
from PIL import Image,ImageDraw
d=sys.argv[1];files=sorted(f for f in glob.glob(d+'/*.jpg') if not f.endswith('sheet.jpg') and (len(sys.argv)<3 or os.path.basename(f).startswith(sys.argv[2])))
w=480;h=300;cols=3;rows=(len(files)+cols-1)//cols
sheet=Image.new('RGB',(w*cols,h*rows))
for i,f in enumerate(files):
    im=Image.open(f).resize((w,h));ImageDraw.Draw(im).text((8,6),os.path.basename(f)[:-4],fill=(255,255,0))
    sheet.paste(im,((i%cols)*w,(i//cols)*h))
sheet.save(d+'/sheet.jpg',quality=88);print(d+'/sheet.jpg')
