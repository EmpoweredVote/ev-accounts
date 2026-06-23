#!/usr/bin/env python3
"""Download + process Springfield MO headshots (16) to 600x750 from CLEAN alternate sources
(replacing the ringed 198px city-directory thumbnails). Council = Springfield Daily Citizen
press photos + employer/campaign; SPS board = official sps.org meet-the-board portraits.
Run: python data/stance-research/springfield-mo/_headshots.py
"""
import requests, os, json, base64
from PIL import Image
from io import BytesIO

REVIEW_DIR = 'data/stance-research/springfield-mo/headshots'
os.makedirs(REVIEW_DIR, exist_ok=True)

SDC = 'https://sgfcitizen.org/government/elections/'  # press photos credited Springfield Daily Citizen
BOARD = 'https://www.sps.org/about/board/meet-the-board'

# (external_id, name, title, image_url, source_page, license)
SUBJECTS = [
    (-2970000001,'Jeff Schrag','Mayor','https://sgfcitizen.org/wp-content/uploads/2025/02/0I3A3844.jpg','https://sgfcitizen.org/voices-opinion/opinion/in-their-own-words-mayoral-candidate-jeff-schrag/','press_use'),
    (-2970000002,'Heather Hardinger','Council Member, General Seat A','https://sgfcitizen.org/wp-content/uploads/2025/02/Z8_000186-copy_v2_4web-1.jpg','https://sgfcitizen.org/government/elections/april-2025-election-results-for-general-seat-a/','press_use'),
    (-2970000003,'Craig Hosmer','Council Member, General Seat B','https://sgfcitizen.org/wp-content/uploads/2025/04/Z6III_000208-copy_v2_4web.jpg','https://sgfcitizen.org/government/elections/april-2025-election-results-for-general-seat-b-and-zone-1/','press_use'),
    (-2970000004,'Callie Carroll','Council Member, General Seat C','https://sgfcitizen.org/wp-content/uploads/2023/03/Callie_Carroll_0603D750_-copy_v2_4web.jpg','https://sgfcitizen.org/government/elections/callie-carroll-derek-lee-and-brandon-jenson-win-races-for-springfield-city-council/','press_use'),
    (-2970000005,'Derek Lee','Council Member, General Seat D','https://sgfcitizen.org/wp-content/uploads/2023/03/Derek_Lee_0638D750_-copy_v2_4web.jpg','https://sgfcitizen.org/government/elections/callie-carroll-derek-lee-and-brandon-jenson-win-races-for-springfield-city-council/','press_use'),
    (-2970000006,'Monica Horton','Council Member, Zone 1','https://i0.wp.com/sgfcitizen.org/wp-content/uploads/2023/03/Monica_Horton_0594D750_-copy_v2_4web.jpg?ssl=1','https://sgfcitizen.org/government/elections/north-springfield-will-be-represented-by-uncontested-city-council-members-get-to-know-them-here/','press_use'),
    (-2970000007,'Abe McGull','Council Member, Zone 2','https://i0.wp.com/sgfcitizen.org/wp-content/uploads/2023/03/Abe_McGull_0552D750_-copy_v2_4web.jpg?ssl=1','https://sgfcitizen.org/government/elections/north-springfield-will-be-represented-by-uncontested-city-council-members-get-to-know-them-here/','press_use'),
    (-2970000008,'Brandon Jenson','Council Member, Zone 3','https://uwozarks.org/media/uploads/2025/06/Brandon-Jenson-300x300.jpg','https://uwozarks.org/team/brandon-jenson/','press_use'),
    (-2970000009,'Bruce Adib-Yazdi','Council Member, Zone 4','https://images.squarespace-cdn.com/content/v1/63dc7043a28b6016236acfda/8e7e88da-56ad-4417-bf9d-58daff0b1658/8L5A4894+head+and+shoulders.jpeg?format=1000w','https://www.bruceaforsgfcouncil.com/','press_use'),
    (-2928860001,'Judy Brunner','Board President','https://resources.finalsite.net/images/f_auto,q_auto/v1765214306/springfieldpublicschoolsmoorg/gqlypdkkheue4qqc6cmt/JudyBrunner.png',BOARD,'press_use'),
    (-2928860002,'Sarah Hough','Board Vice President','https://resources.finalsite.net/images/f_auto,q_auto/v1765214590/springfieldpublicschoolsmoorg/sqgefhjtqbyxhksl1gst/SarahHough.png',BOARD,'press_use'),
    (-2928860003,'Danielle Kincaid','Board Member','https://resources.finalsite.net/images/f_auto,q_auto/v1765214383/springfieldpublicschoolsmoorg/ijf9koph1bvibluoocun/DanielleKincaid.png',BOARD,'press_use'),
    (-2928860004,'Maryam Mohammadkhani','Board Member','https://resources.finalsite.net/images/f_auto,q_auto/v1765214621/springfieldpublicschoolsmoorg/rvwhirtb0udcgrmm0b6u/MaryamMohammadkhani.png',BOARD,'press_use'),
    (-2928860005,'Susan Provance','Board Member','https://resources.finalsite.net/images/f_auto,q_auto/v1765214670/springfieldpublicschoolsmoorg/aooesrcbywiows5tb3v2/SusanProvance.png',BOARD,'press_use'),
    (-2928860006,'Gail Smart','Board Member','https://resources.finalsite.net/images/f_auto,q_auto/v1765214698/springfieldpublicschoolsmoorg/ewem4ilr1gfwcwletrag/GailSmart.png',BOARD,'press_use'),
    (-2928860007,'Shurita Thomas-Tate','Board Member','https://resources.finalsite.net/images/f_auto,q_auto/v1765214735/springfieldpublicschoolsmoorg/rnmqzduwgb38nowmlj26/ShuritaThomas-Tate.png',BOARD,'press_use'),
]

def process(url):
    r = requests.get(url, headers={'User-Agent':'Mozilla/5.0'}, timeout=25); r.raise_for_status()
    img = Image.open(BytesIO(r.content)).convert('RGB'); w,h = img.size; tr = 4/5
    if w/h > tr:
        nw = int(h*tr); left=(w-nw)//2; img=img.crop((left,0,left+nw,h))
    else:
        nh = int(w/tr); top=(h-nh)//2; img=img.crop((0,top,w,top+nh))
    return img.resize((600,750), Image.LANCZOS), (w,h)

out=[]
for ext,name,title,url,page,lic in SUBJECTS:
    try:
        img,orig = process(url)
        fn=f'{ext}.jpg'; img.save(os.path.join(REVIEW_DIR,fn),'JPEG',quality=90)
        buf=BytesIO(); img.save(buf,'JPEG',quality=70); b64=base64.b64encode(buf.getvalue()).decode()
        out.append({'external_id':ext,'full_name':name,'title':title,'source_page':page,'image_url':url,
                    'license':lic,'orig_size':orig,'file':fn,'data_uri':'data:image/jpeg;base64,'+b64,'ok':True})
        print(f'OK   {name:22} orig {orig[0]}x{orig[1]} -> 600x750')
    except Exception as e:
        out.append({'external_id':ext,'full_name':name,'title':title,'image_url':url,'ok':False,'error':str(e)})
        print(f'FAIL {name:22} {e}')

with open(os.path.join(REVIEW_DIR,'_review.json'),'w') as f: json.dump(out,f,indent=2)
print(f'\n{sum(1 for o in out if o["ok"])}/{len(out)} processed.')
