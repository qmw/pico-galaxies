-- voidstorm
-- arcade shooter. all sprites
-- generated with krea 2 pixel art

-- sprite sheet slots: x,y,size
sp={ship={0,0,16},dra={16,0,16},drb={32,0,16},
saa={48,0,16},sab={64,0,16},mine={80,0,16},
div={96,0,16},ast={112,0,16},ex1={0,16,16},
ex2={16,16,16},ex3={32,16,16},pow={48,16,8},
shd={56,16,8},bmb={48,24,8},boss={64,16,32},
pla={96,16,32},p_lush={0,48,16},p_rock={16,48,16},
p_ice={32,48,16},p_hive={48,48,16},freighter={64,48,16},
dome={80,48,8},i_food={88,48,8},i_ore={80,56,8},
i_coin={88,56,8},i_colonist={96,48,8},flagship={0,64,32}}

et={
 drone={hp=3,s={"dra","drb"},pts=100,r=6,an=6},
 saucer={hp=7,s={"saa","sab"},pts=250,r=7,an=10},
 diver={hp=2,s={"div"},pts=150,r=6},
 mine={hp=5,s={"mine"},pts=200,r=6},
 ast={hp=9,s={"ast"},pts=50,r=7},
}

-- draw a sheet sprite centred,
-- with scale / squash / flips
function dspr(n,x,y,s,fx,fy,sq)
 local d=sp[n] s=s or 1
 local w,h=d[3]*s*(sq or 1),d[3]*s
 sspr(d[1],d[2],d[3],d[3],x-w/2,y-h/2,w,h,fx,fy)
end

function whiteout()
 for c=1,15 do pal(c,7) end
end

function _init()
 cartdata("voidstorm_krea2")
 hi=dget(0)
 stars={}
 for i=1,70 do
  add(stars,{x=rnd(128),y=rnd(128),z=1+flr(rnd(3))})
 end
 plx,ply=90,20
 t,spd,shake,flash,hs=0,1,0,0,0
 parts,rings,fx,pops={},{},{},{}
 st="title"
 music(0)
end

function newgame()
 p={lives=3,pw=1} c,mis,score=nil,nil,0
 startplay()
end

-- reset the shooter; keeps lives/score across campaign missions
function startplay()
 p.x,p.y,p.vx,p.vy,p.shield,p.inv,p.bombs,p.cd,p.bank,p.dead=64,110,0,0,0,90,2,0,0,0
 if c then p.pw=c.wpn end
 bul,ebul,en,items,q={},{},{},{},{}
 parts,rings,fx,pops={},{},{},{}
 combo,ctime,wave,wt=1,0,0,30
 boss,banner,bt,fr=nil,"",0,nil
 if mis then
  mis.s0,mis.l0=score,p.lives
  if mis.k=="convoy" then fr={x=64,y=150,hp=10,fl=0} end
 end
 st="play"
 sfx(8)
end

-- ===== vfx =====
function part(x,y,vx,vy,l,cols,r,k)
 add(parts,{x=x,y=y,vx=vx,vy=vy,l=l,ml=l,c=cols,r=r or 0,k=k or 0})
end

function sparks(x,y,n,cols,sp_)
 for i=1,n do
  local a,s=rnd(),rnd(sp_ or 3)+.5
  part(x,y,cos(a)*s,sin(a)*s,8+rnd(12),cols or {7,10,9,8},0,1)
 end
end

function ring(x,y,r,vr,c,l)
 add(rings,{x=x,y=y,r=r,vr=vr,c=c,l=l})
end

function explode(x,y,sz)
 add(fx,{x=x,y=y,t=0,s=sz})
 sparks(x,y,6+sz*6,nil,1.5+sz)
 for i=1,2+sz*2 do
  part(x+rnd(8)-4,y+rnd(8)-4,rnd(1)-.5,rnd(1)-.7,20+rnd(20),{5,5,2,1},2+rnd(sz*2),2)
 end
 ring(x,y,2,1.5+sz*.5,sz>1 and 10 or 7,10+sz*3)
 shake=max(shake,sz*2.5)
 sfx(sz>1 and 2 or 1)
end

function pop(x,y,txt,c)
 add(pops,{x=x,y=y,s=txt,l=40,c=c or 7})
end

-- ===== spawning =====
function spawnwave()
 wave+=1 dif=wave
 if mis then
  if wave>mis.n then missionend(true) return end
  dif=mis.lv+wave
 end
 bt=90 spd=4
 if mis and mis.boss and wave==mis.n or not mis and wave%5==0 then
  banner="warning!" sfx(9)
  boss={x=64,y=-40,hp=160+dif*30,t=0,fl=0,ph=0,dead=0}
  if mis and mis.boss>1 then boss.f,boss.hp=1,900 end
  boss.mhp=boss.hp
  return
 end
 banner=mis and mis.k.." "..wave.."/"..mis.n or "wave "..wave
 sfx(8)
 local n=5+dif*2
 for i=1,n do
  local r,k=rnd(),"drone"
  if dif>1 and r<.22 then k="diver"
  elseif dif>2 and r<.40 then k="saucer"
  elseif dif>3 and r<.52 then k="mine"
  elseif r<.65 then k="ast" end
  add(q,{d=40+i*(28-min(dif,12)),k=k})
 end
 -- drone squadrons
 local sx=24+rnd(80)
 for i=0,3 do add(q,{d=20+i*10,k="drone",x=sx}) end
end

function spawn(k,x)
 local d=et[k]
 local e={k=k,x=x or 12+rnd(104),y=-12,hp=d.hp+flr(dif/4),t=flr(rnd(60)),fl=0}
 e.x0=e.x
 if k=="saucer" then e.ty=16+rnd(40) end
 if k=="ast" then e.vx=rnd(.6)-.3 e.vy=.5+rnd(.6) end
 if k=="diver" then e.y=-10 e.vy=0 e.vx=0 end
 add(en,e)
end

function eshoot(x,y,a,s)
 add(ebul,{x=x,y=y,vx=cos(a)*s,vy=sin(a)*s,t=0})
end

function aim(x,y)
 return atan2(p.x-x,p.y-y)
end

-- ===== update =====
function _update60()
 t+=1
 if hs>0 then hs-=1 return end
 shake=max(0,shake-.4) flash=max(0,flash-1)
 spd+=(1-spd)*.03
 for s in all(stars) do
  s.y+=s.z*.35*spd
  if s.y>128 then s.y=0 s.x=rnd(128) end
 end
 ply+=.04*spd
 if ply>170 then ply=-40 plx=20+rnd(88) end
 updvfx()
 if st=="title" then
  if btnp(4) then newcamp() end
  if btnp(5) then newgame() end
 elseif st=="play" then
  updplay()
 elseif st=="map" then
  updmap()
 else
  if t>60 and btnp(5) then st="title" t=0 music(0) end
 end
end

function updvfx()
 for i=#parts,1,-1 do
  local o=parts[i]
  o.x+=o.vx o.y+=o.vy
  o.vx*=.92 o.vy*=.92
  if o.k==2 then o.y-=.15 o.r+=.05 end
  o.l-=1
  if o.l<=0 then deli(parts,i) end
 end
 for i=#rings,1,-1 do
  local o=rings[i]
  o.r+=o.vr o.vr*=.93 o.l-=1
  if o.l<=0 then deli(rings,i) end
 end
 for i=#fx,1,-1 do
  local o=fx[i] o.t+=1
  if o.t>24 then deli(fx,i) end
 end
 for i=#pops,1,-1 do
  local o=pops[i] o.y-=.4 o.l-=1
  if o.l<=0 then deli(pops,i) end
 end
end

function updplay()
 if bt>0 then bt-=1 end
 if ctime>0 then ctime-=1 else combo=1 end
 updplayer()
 -- spawn queue
 for i=#q,1,-1 do
  local s=q[i] s.d-=1
  if s.d<=0 then spawn(s.k,s.x) deli(q,i) end
 end
 if #q==0 and #en==0 and not boss then
  wt-=1
  if wt<=0 then spawnwave() wt=120 end
 end
 upden()
 if boss then updboss() end
 if fr then
  fr.y+=(100-fr.y)*.01 fr.x=64+sin(t/500)*30
  if fr.fl>0 then fr.fl-=1 end
  for b in all(ebul) do
   if hit(b.x,b.y,1,fr.x,fr.y,6) then
    del(ebul,b) fr.hp-=1 fr.fl=4 sparks(b.x,b.y,4,{10,9}) sfx(7)
   end
  end
  if fr.hp<=0 then explode(fr.x,fr.y,3) missionend() return end
 end
 updbullets()
 upditems()
end

function updplayer()
 if p.dead>0 then
  p.dead-=1
  if p.dead==0 then
   if p.lives<=0 then
    st="over" t=0
    if score>hi then hi=score dset(0,hi) end
    music(-1)
   else
    p.x,p.y,p.inv=64,110,150
   end
  end
  return
 end
 local dx,dy=0,0
 if btn(0) then dx=-1 end
 if btn(1) then dx=1 end
 if btn(2) then dy=-1 end
 if btn(3) then dy=1 end
 p.vx+=(dx*1.8-p.vx)*.3
 p.vy+=(dy*1.8-p.vy)*.3
 p.x=mid(6,p.x+p.vx,122)
 p.y=mid(10,p.y+p.vy,120)
 p.bank+=(dx-p.bank)*.2
 if p.inv>0 then p.inv-=1 end
 -- engine trail
 if t%2==0 then
  part(p.x-3+rnd(1),p.y+8,rnd(.4)-.2,1+rnd(1),6+rnd(4),{7,10,9,8,2},0,1)
  part(p.x+3+rnd(1),p.y+8,rnd(.4)-.2,1+rnd(1),6+rnd(4),{7,10,9,8,2},0,1)
 end
 -- fire
 p.cd-=1
 if btn(4) and p.cd<=0 then
  p.cd=6 p.mf=3 sfx(0)
  local w=p.pw
  shot(p.x-3,p.y-6,0) shot(p.x+3,p.y-6,0)
  if w>=2 then shot(p.x-5,p.y-4,-.4) shot(p.x+5,p.y-4,.4) end
  if w>=3 then shot(p.x-7,p.y-2,-.9) shot(p.x+7,p.y-2,.9) end
  if w>=4 then shot(p.x,p.y-8,0,1) end
 end
 -- bomb
 if btnp(5) and p.bombs>0 then
  p.bombs-=1 flash=8 shake=8 sfx(6)
  ring(p.x,p.y,4,8,7,30) ring(p.x,p.y,2,6,12,30)
  for b in all(ebul) do sparks(b.x,b.y,2,{12,7}) end
  ebul={}
  for e in all(en) do hurt(e,12) end
  if boss then boss.hp-=30 boss.fl=6 end
  p.inv=max(p.inv,60)
 end
end

function shot(x,y,vx,big)
 add(bul,{x=x,y=y,vx=vx,vy=-6,big=big})
end

function hurt(e,d)
 e.hp-=d e.fl=4
 if e.hp<=0 and not e.dead then
  e.dead=true
  kill(e)
 end
end

function kill(e)
 local d=et[e.k]
 explode(e.x,e.y,e.k=="ast" and 1 or 1+flr(rnd(2)))
 local pts=d.pts*combo
 score+=pts
 pop(e.x,e.y-6,pts..(combo>1 and " x"..combo or ""),combo>1 and 10 or 7)
 combo=min(combo+1,8) ctime=90
 if e.k=="mine" then
  for i=0,7 do eshoot(e.x,e.y,i/8+t/100,1) end
  ring(e.x,e.y,3,3,8,15)
 end
 if e.k=="ast" then
  for i=1,6 do
   local a=rnd()
   part(e.x,e.y,cos(a)*2,sin(a)*2,30,{4,4,5,2},1.5,3)
  end
 end
 if rnd()<.14 then
  local r=rnd()
  add(items,{x=e.x,y=e.y,k=r<.6 and "pow" or r<.85 and "shd" or "bmb",t=0})
 end
 del(en,e)
end

function upden()
 for e in all(en) do
  e.t+=1
  if e.fl>0 then e.fl-=1 end
  local k=e.k
  if k=="drone" then
   e.y+=.55+dif*.03
   e.x=e.x0+sin(e.t/100)*22
   if dif>2 and e.t%140==70 then eshoot(e.x,e.y+4,.75,1.1) sfx(5) end
  elseif k=="saucer" then
   if e.y<e.ty then e.y+=.8
   else
    e.x=e.x0+sin(e.t/180)*30
    if e.t%max(30,70-dif*3)==0 then
     local a=aim(e.x,e.y)
     for i=-1,1 do eshoot(e.x,e.y+5,a+i*.04,1.3) end
     sfx(5)
     ring(e.x,e.y+5,1,1,11,8)
    end
    if e.t>600 then e.y+=1.2 end
   end
  elseif k=="diver" then
   if e.t<50 then
    e.y+=(14-e.y)*.08
    e.x+=(p.x-e.x)*.02
   else
    if e.vy==0 then
     local a=aim(e.x,e.y)
     e.vx,e.vy=cos(a)*3.2,sin(a)*3.2
     sfx(5)
    end
    e.x+=e.vx e.y+=e.vy
    part(e.x,e.y-7,0,-.5,10,{10,9,8,2},1,2)
   end
  elseif k=="mine" then
   e.y+=.35 e.x=e.x0+sin(e.t/240)*8
  elseif k=="ast" then
   e.x+=e.vx e.y+=e.vy
  end
  if e.y>140 or e.x<-20 or e.x>148 then del(en,e) end
  -- ram player
  if p.dead==0 and hit(e.x,e.y,et[k].r,p.x,p.y,3) then
   phit() hurt(e,99)
  end
 end
end

function hit(x1,y1,r1,x2,y2,r2)
 local dx,dy=x1-x2,y1-y2
 return abs(dx)<r1+r2 and abs(dy)<r1+r2 and dx*dx+dy*dy<(r1+r2)^2
end

function phit()
 if p.inv>0 or p.dead>0 then return end
 if p.shield>0 then
  p.shield=0 p.inv=60
  sparks(p.x,p.y,20,{12,7,1})
  ring(p.x,p.y,10,2,12,12)
  sfx(4) shake=4
  return
 end
 p.lives-=1
 explode(p.x,p.y,3)
 sparks(p.x,p.y,30,{7,12,6,13},4)
 p.pw=max(1,p.pw-1)
 p.dead=90 hs=8 flash=4
 sfx(4)
end

function updboss()
 local b=boss
 b.t+=1
 if b.fl>0 then b.fl-=1 end
 if b.dead>0 then
  b.dead+=1
  if b.dead%5==0 then
   explode(b.x+rnd(28)-14,b.y+rnd(28)-14,1+flr(rnd(2)))
  end
  shake=max(shake,2)
  if b.dead>100 then
   explode(b.x,b.y,4)
   for i=1,3 do ring(b.x,b.y,i*4,4+i,({7,10,8})[i],40) end
   flash=10 hs=20
   score+=5000*combo
   pop(b.x,b.y,"+"..(5000*combo),10)
   for i=0,2 do add(items,{x=b.x-12+i*12,y=b.y,k=({"pow","shd","bmb"})[i+1],t=0}) end
   boss=nil wt=150
  end
  return
 end
 if b.y<30 then b.y+=.5 return end
 local rage=b.hp<b.mhp/2
 b.x=64+sin(b.t/(rage and 160 or 260))*36
 b.y=30+sin(b.t/120)*4
 local ph=flr(b.t/240)%3
 local f=b.t%240
 if ph==0 then
  -- spiral
  if f%(rage and 3 or 5)==0 then
   eshoot(b.x,b.y+6,b.t/45,1)
   if rage then eshoot(b.x,b.y+6,b.t/45+.5,1) end
  end
 elseif ph==1 then
  -- aimed fans
  if f%40==0 then
   local a=aim(b.x,b.y)
   for i=-3,3 do eshoot(b.x,b.y+10,a+i*.035,1.5) end
   sfx(5)
  end
 else
  -- ring bursts + escort drones
  if f%60==0 then
   for i=0,15 do eshoot(b.x,b.y,i/16+f/600,.9) end
   ring(b.x,b.y,6,3,14,14)
   sfx(5)
  end
  if f==120 then spawn("drone",b.x-20) spawn("drone",b.x+20) end
 end
 if rage and t%6==0 then
  part(b.x+rnd(24)-12,b.y+rnd(16)-8,0,-.5,25,{5,5,1},2,2)
 end
 if p.dead==0 and hit(b.x,b.y,13,p.x,p.y,3) then phit() end
end

function updbullets()
 for b in all(bul) do
  b.x+=b.vx b.y+=b.vy
  if b.y<-8 then del(bul,b) else
   local dmg=b.big and 2 or 1
   for e in all(en) do
    if hit(b.x,b.y,2,e.x,e.y,et[e.k].r) then
     sparks(b.x,b.y,2,{7,12})
     sfx(7)
     hurt(e,dmg) del(bul,b) break
    end
   end
   if boss and boss.y>=20 and boss.dead==0 and hit(b.x,b.y,2,boss.x,boss.y,13) then
    boss.hp-=dmg boss.fl=3
    sparks(b.x,b.y,2,{7,8,14})
    del(bul,b)
    if boss.hp<=0 then
     boss.dead=1 ebul={} hs=10
     sfx(2)
    end
   end
  end
 end
 for b in all(ebul) do
  b.x+=b.vx b.y+=b.vy b.t+=1
  if b.x<-6 or b.x>134 or b.y<-6 or b.y>134 then del(ebul,b)
  elseif p.dead==0 and hit(b.x,b.y,1,p.x,p.y,2) then
   del(ebul,b) phit()
  end
 end
end

function upditems()
 for it in all(items) do
  it.t+=1
  it.y+=.5
  local dx,dy=p.x-it.x,p.y-it.y
  if p.dead==0 and abs(dx)<28 and abs(dy)<28 then
   it.x+=dx*.08 it.y+=dy*.08
  end
  if t%6==0 then part(it.x+rnd(8)-4,it.y+rnd(8)-4,0,-.3,12,{7,10},0,1) end
  if p.dead==0 and hit(it.x,it.y,4,p.x,p.y,6) then
   local k=it.k
   if k=="pow" then
    if p.pw<4 then p.pw+=1 pop(it.x,it.y,"power up!",10)
    else score+=1000 pop(it.x,it.y,"+1000",10) end
   elseif k=="shd" then p.shield=1 pop(it.x,it.y,"shield!",12)
   else p.bombs=min(p.bombs+1,5) pop(it.x,it.y,"bomb!",8) end
   ring(it.x,it.y,2,2,7,10)
   sfx(3) del(items,it)
  elseif it.y>136 then del(items,it) end
 end
end

-- ===== draw =====
function _draw()
 cls(0)
 local sx,sy=rnd(shake)-shake/2,rnd(shake)-shake/2
 camera(sx,sy)
 drawbg()
 if st=="title" then drawtitle()
 elseif st=="map" then drawmap()
 elseif st=="win" then drawwin()
 else
  drawplay()
  if st=="over" then drawover() end
 end
 camera()
 if flash>0 then
  -- full-screen flash: draw bright, then fade
  -- dithered flash (no full-white frames)
  fillp(flash>5 and 0b0101101001011010 or 0b0111111111011111)
  rectfill(0,0,127,127,flash>5 and 7 or 12)
  fillp()
 end
end

function drawbg()
 -- planet drawn with a dimmed palette so it reads as backdrop
 for c,d in pairs({[7]=13,[14]=2,[15]=13,[9]=4,[10]=9,[8]=2,[13]=1,[6]=13,[12]=1,[2]=1,[4]=2}) do pal(c,d) end
 if (st!="map") dspr("pla",plx,ply,1.25)
 pal()
 for s in all(stars) do
  local c=({1,13,7})[s.z]
  if spd>1.5 then
   line(s.x,s.y,s.x,s.y-s.z*spd*1.5,c)
  else pset(s.x,s.y,c) end
 end
end

function drawship(x,y,big)
 local s=big or 1
 -- engine flames (animated)
 for i=-1,1,2 do
  local fl=2+rnd(2)+(btn(2) and 2 or 0)
  circfill(x+i*3*s,y+7*s+fl/2,(1.5+rnd(.8))*s,8)
  circfill(x+i*3*s,y+7*s,(1+rnd(.5))*s,10)
  pset(x+i*3*s,y+7*s,7)
 end
 dspr("ship",x,y,s,false,false,1-abs(p and p.bank or 0)*.25)
end

function drawplay()
 for it in all(items) do
  local bob=sin(it.t/40)*1.5
  circ(it.x,it.y+bob,6+sin(it.t/20),it.t%8<4 and 7 or 13)
  dspr(it.k,it.x,it.y+bob)
 end
 for e in all(en) do
  local d=et[e.k]
  local fr=d.s[1]
  if d.an then fr=d.s[flr(e.t/d.an)%#d.s+1] end
  local fx_,fy_=false,false
  if e.k=="ast" or e.k=="mine" then
   local f=flr(e.t/(e.k=="mine" and 6 or 12))%4
   fx_=f==1 or f==2 fy_=f>=2
  end
  -- generated diver faces up; flip so it dives nose-first
  if e.k=="diver" then fy_=true end
  if e.k=="diver" and e.t<50 and e.t%10<5 then
   line(e.x,e.y+8,e.x,127,2)
  end
  if e.fl>0 then whiteout() end
  local s=1
  if e.k=="mine" then s=1+sin(e.t/30)*.08 end
  dspr(fr,e.x,e.y,s,fx_,fy_)
  pal()
  if e.k=="mine" and e.t%30<15 then circfill(e.x,e.y,1,8) end
 end
 if boss then drawboss() end
 if fr then
  if fr.fl>0 then whiteout() end
  dspr("freighter",fr.x,fr.y)
  pal()
  rectfill(fr.x-5,fr.y+10,fr.x-5+fr.hp,fr.y+10,fr.hp>3 and 11 or 8)
 end
 -- enemy bullets
 for b in all(ebul) do
  local c=b.t%8<4 and 8 or 14
  circfill(b.x,b.y,2,c)
  pset(b.x,b.y,7)
 end
 -- player bullets
 for b in all(bul) do
  if b.big then
   rectfill(b.x-1,b.y-3,b.x+1,b.y+3,12)
   line(b.x,b.y-3,b.x,b.y+3,7)
  else
   line(b.x,b.y-2,b.x,b.y+2,12)
   pset(b.x,b.y-2,7)
  end
 end
 -- player
 if p.dead==0 and (p.inv==0 or t%6<3) then
  drawship(p.x,p.y)
  if p.mf and p.mf>0 then
   p.mf-=1
   circfill(p.x-3,p.y-7,1.5,7) circfill(p.x+3,p.y-7,1.5,7)
  end
  if p.shield>0 then
   for i=0,15 do
    local a=i/16+t/120
    if (i+t\4)%3>0 then
     pset(p.x+cos(a)*11,p.y+sin(a)*11,i%2==0 and 12 or 7)
    end
   end
  end
 end
 drawvfx()
 drawhud()
end

function drawboss()
 local b=boss
 if b.fl>0 then whiteout() end
 dspr(b.f and "flagship" or "boss",b.x,b.y)
 pal()
 -- pulsing eye glow
 local r=2+sin(t/30)
 circ(b.x,b.y-1,r+2,b.hp<b.mhp/2 and 8 or 14)
 -- charge telegraph before fans
 local f=b.t%240
 if flr(b.t/240)%3==1 and f%40>30 then
  circ(b.x,b.y+10,(40-f%40),8)
 end
end

function drawvfx()
 for o in all(rings) do
  circ(o.x,o.y,o.r,o.l<4 and 5 or o.c)
 end
 for o in all(fx) do
  local fr=o.t<5 and "ex1" or o.t<13 and "ex2" or "ex3"
  local s=(o.s>2 and 2.5 or o.s>1 and 1.5 or 1)*(.6+o.t/40)
  dspr(fr,o.x,o.y,s,o.t%8<4)
 end
 for o in all(parts) do
  local c=o.c[flr((1-o.l/o.ml)*#o.c)+1] or o.c[#o.c]
  if o.k==1 then
   line(o.x,o.y,o.x-o.vx,o.y-o.vy,c)
  elseif o.r>=1 then
   circfill(o.x,o.y,o.r*(o.l/o.ml)+.5,c)
  else pset(o.x,o.y,c) end
 end
 for o in all(pops) do
  local w=#o.s*2
  print(o.s,o.x-w+1,o.y+1,1)
  print(o.s,o.x-w,o.y,o.l%4<2 and o.c or 7)
 end
end

function oprint(s,x,y,c,o)
 for dx=-1,1 do for dy=-1,1 do
  print(s,x+dx,y+dy,o or 0)
 end end
 print(s,x,y,c)
end

function drawhud()
 oprint(score,2,2,7)
 oprint("hi "..max(hi,score),64-#("hi "..max(hi,score))*2,2,6)
 if combo>1 then oprint("x"..combo,2,9,10) end
 for i=1,min(p.lives,5) do sspr(0,0,16,16,128-i*9,1,8,8) end
 for i=1,p.bombs do sspr(48,24,8,8,128-i*7,10,6,6) end
 for i=1,4 do
  rectfill(2+(i-1)*5,124,5+(i-1)*5,125,i<=p.pw and 12 or 1)
 end
 if boss and boss.dead==0 then
  local w=boss.hp/boss.mhp*100
  rect(13,16,114,20,5)
  rectfill(14,17,14+max(0,w),19,t%10<5 and boss.hp<boss.mhp/2 and 8 or 14)
 end
 if bt>0 then
  local y=50+(bt>80 and (bt-80)*3 or 0)
  local s=banner
  local c=banner=="warning!" and (t%8<4 and 8 or 7) or 7
  print("\^w\^t"..s,64-#s*4+1,y+1,1)
  print("\^w\^t"..s,64-#s*4,y,c)
 end
end

function drawtitle()
 -- demo fly-by of krea sprites
 local dt=t%300
 dspr(flr(t/6)%2==0 and "dra" or "drb",dt*.6-20,40+sin(t/90)*6)
 dspr(flr(t/10)%2==0 and "saa" or "sab",148-dt*.5,26+sin(t/70)*4)
 local s="voidstorm"
 for i=1,#s do
  local ch=sub(s,i,i)
  local x=64-#s*4+(i-1)*8
  local y=58+sin(t/60+i/9)*3
  local c=({14,12,7,12})[flr(t/4+i)%4+1]
  print("\^w\^t"..ch,x+1,y+1,2)
  print("\^w\^t"..ch,x,y,c)
 end
 local by=96+sin(t/80)*2
 p=nil
 drawship(64,by)
 if t%40<28 then oprint("z campaign   x arcade",24,114,7,1) end
 oprint("z fire  x bomb  arrows move",10,121,6,1)
 if hi>0 then oprint("hi "..hi,64-#("hi "..hi)*2,2,10) end
end

function drawover()
 rectfill(14,44,113,84,0)
 rect(14,44,113,84,8)
 print("\^w\^tgame over",28,49,t%10<5 and 8 or 7)
 oprint("score "..score,64-#("score "..score)*2,64,7)
 local s=score>=hi and "new high score!" or "hi "..hi
 oprint(s,64-#s*2,71,10)
 if t>60 and t%40<28 then oprint("press x",50,78,6) end
end

-- ===== campaign (see design.md) =====
pn=split"lush,rocky,icy,hive"
pk=split"p_lush,p_rock,p_ice,p_hive"
base=split"2,4,7"

function newcamp()
 c={yr=1,cr=60,g={0,0,0},pr=split"2,4,7",pool=2,tax=10,
  aut=0,wpn=1,rc=25,sel=1,msg="welcome, governor"}
 pl={}
 local ty=split"1,2,3,4,2,3,4,1"
 for i=1,8 do
  local a,j=i/8,flr(rnd(#ty-1))+2
  add(pl,{x=64+cos(a)*(30+i%3*7),y=52+sin(a)*(22+i%2*12),
   t=i==1 and 1 or ty[j],pop=0,calm=0})
  if (i>1) deli(ty,j)
 end
 local h=pl[1]
 h.own,h.pop,h.known,h.name=true,2,true,"haven"
 p={lives=3,pw=1} score=0
 st="map" c.hold=true
end

function say(s) c.msg=s end
function pay(n)
 if (c.cr>=n) c.cr-=n return true
 say"not enough credits"
end

-- data-driven action menu for planet q
function acts(q)
 local a={}
 local function o(s,f) add(a,{s,f}) end
 if not q.known then
  o("scout (1 year)",function() q.known=true endturn() end)
 elseif q.t==4 then
  o("trade gifts 30cr",function()
   if (pay(30)) c.g[3]+=3 q.calm+=1 say"hive trades crystal"
  end)
  o("assault hive",function() mission{k="assault",n=3,lv=3,boss=1,q=q} end)
 elseif not q.own then
  o("found colony 40cr",function()
   if c.pool<1 then say"no colonists in pool"
   elseif pay(40) then c.pool-=1 q.own,q.pop=true,1 say"colony founded!" end
  end)
 else
  o("settle colonist",function()
   if (c.pool>0) c.pool-=1 q.pop+=1
  end)
  if (not q.def) o("build defense 50cr",function() if pay(50) then q.def=true end end)
  if q==pl[1] then
   o("convoy to market",function() mission{k="convoy",n=2,lv=1} end)
   o("recruit "..c.rc.."cr",function() if pay(c.rc) then c.pool+=1 c.rc+=5 end end)
   if (c.wpn<4) o("weapon lv"..(c.wpn+1).." 60cr",function() if pay(60) then c.wpn+=1 end end)
   o("repair hull 40cr",function() if pay(40) then p.lives+=1 end end)
  end
 end
 o("end year",endturn)
 if (c.aut>=100) o("declare independence",function() mission{k="war",n=4,lv=5,boss=2} end)
 return a
end

function endturn()
 c.yr+=1 say("year "..c.yr)
 local tp,cols=0,{}
 for q in all(pl) do
  if q.own then
   if (q.pop<1 and q!=pl[1]) q.own=false say"a colony was abandoned"
  end
  if q.own then
   tp+=q.pop add(cols,q)
   if (q.t<4) c.g[q.t]+=q.pop*2
  end
 end
 c.g[1]-=tp
 if c.g[1]<0 then
  c.g[1]=0
  local v=rnd(cols)
  if (v.pop>0) v.pop-=1 say"famine! a colonist died"
 elseif c.g[1]>=8 then
  c.g[1]-=8 c.pool+=1 say"a colonist was born"
 end
 if (c.yr%3==0 and c.tax<60) c.tax+=5 say("hegemony raises tax to "..c.tax.."%")
 if c.yr%2==0 then
  for i=1,3 do c.pr[i]=min(c.pr[i]+1,base[i]) end
 end
 c.aut=min(100,c.aut+ceil(tp*c.tax/25))
 for h in all(pl) do
  if h.t==4 and rnd()<.25-h.calm*.08 then
   local v=rnd(cols)
   say("hive raid on "..(v.name or pn[v.t]).."!")
   mission{k="raid",n=v.def and 1 or 2,lv=c.yr\3,q=v}
   return
  end
 end
end

function mission(m)
 mis=m startplay()
end

function missionend(win)
 local m=mis
 local sal=(score-m.s0)\20
 c.cr+=sal st="map" c.hold=true
 if m.k=="convoy" then
  if win then
   local inc=0
   for i=1,3 do
    inc+=c.g[i]*c.pr[i] c.g[i]=0
    c.pr[i]=max(1,c.pr[i]-1)
   end
   inc=flr(inc*fr.hp/10*(100-c.tax)/100)
   c.cr+=inc say("goods +"..inc.."cr")
  else say"freighter lost!" for i=1,3 do c.g[i]=0 end end
 elseif m.k=="raid" then
  if win and p.lives==m.l0 then c.aut=min(100,c.aut+5) say"raid repelled!"
  else
   if (not m.q.def) m.q.pop=max(0,m.q.pop-1)
   say"colony raided!"
  end
 elseif m.k=="assault" then
  m.q.t,m.q.calm=1,0 say"hive cleared!"
 else
  st="win" t=0
  if (score>hi) hi=score dset(0,hi)
 end
 if (sal>0) c.msg..=" salvage +"..sal
end

function updmap()
 if c.hold then
  c.hold=btn(4) or btn(5)
  return
 end
 local a=c.m
 if a then
  if (btnp(2)) c.mi=(c.mi-2)%#a+1
  if (btnp(3)) c.mi=c.mi%#a+1
  if (btnp(5)) c.m=nil
  if (btnp(4)) c.m=nil a[c.mi][2]()
 else
  if (btnp(0) or btnp(2)) c.sel=(c.sel-2)%#pl+1
  if (btnp(1) or btnp(3)) c.sel=c.sel%#pl+1
  if (btnp(4)) c.m,c.mi=acts(pl[c.sel]),1
 end
end

function drawmap()
 local h=pl[1]
 for q in all(pl) do
  if q.own and q!=h then
   for i=0,1,.08 do
    pset(h.x+(q.x-h.x)*i,h.y+(q.y-h.y)*i,(i*12-t/8)%2<1 and 13 or 1)
   end
  end
 end
 for i,q in ipairs(pl) do
  if q.known then dspr(pk[q.t],q.x,q.y)
  else circfill(q.x,q.y,5,1) print("?",q.x-1,q.y-2,13) end
  if (q.def) circ(q.x,q.y,9,12)
  if q.own then
   dspr("dome",q.x+6,q.y-6)
   oprint(q.pop,q.x+6,q.y+4,7)
  end
  if (q.t==4 and q.known and t%30<15) pset(q.x,q.y-9,11)
  if (i==c.sel) circ(q.x,q.y,11+sin(t/40),t%16<8 and 10 or 7)
 end
 -- top bar
 rectfill(0,0,127,8,1)
 print("year "..c.yr,2,2,7)
 dspr("i_coin",48,4) print(c.cr,54,2,10)
 dspr("i_colonist",78,4) print(c.pool,84,2,7)
 dspr("ship",104,4,.5) print(p.lives,110,2,7)
 -- bottom panel
 rectfill(0,97,127,127,0) rect(0,97,127,127,13)
 local ic=split"i_food,i_ore,pow"
 for i=1,3 do
  local x=2+(i-1)*30
  dspr(ic[i],x+4,104)
  print(c.g[i],x+9,102,7)
  print("$"..c.pr[i],x+9+#tostr(c.g[i])*4,102,5)
 end
 print("tax "..c.tax.."%",94,102,8)
 print("autonomy",2,109,12)
 rect(36,109,125,113,5)
 rectfill(37,110,37+c.aut*.87,112,c.aut>=100 and t%8<4 and 10 or 12)
 local q=pl[c.sel]
 local s=q.name or q.known and pn[q.t] or "unexplored"
 if (q.own) s..="  pop "..q.pop
 if (q.def) s..=" +def"
 print(s,2,116,q.t==4 and q.known and 11 or 6)
 print(c.msg,2,122,t%60<50 and 10 or 9)
 -- action menu
 local a=c.m
 if a then
  local mx=q.x>64 and 2 or 38
  rectfill(mx,12,mx+87,14+#a*7,0)
  rect(mx,12,mx+87,14+#a*7,12)
  for i,o in ipairs(a) do
   print((i==c.mi and ">" or " ")..o[1],mx+3,15+(i-1)*7,i==c.mi and 10 or 6)
  end
 end
end

function drawwin()
 local s="independence!"
 for i=1,#s do
  print("\^w\^t"..sub(s,i,i),12+(i-1)*8,40+sin(t/50+i/10)*3,({10,9,12,7})[flr(t/5+i)%4+1])
 end
 oprint("the colonies are free",22,64,7)
 oprint("year "..c.yr.."  score "..score,64-#("year "..c.yr.."  score "..score)*2,74,10)
 if (t%60==0) explode(20+rnd(88),20+rnd(60),1+flr(rnd(2)))
 drawvfx()
 if (t>90 and t%40<28) oprint("press x",50,100,6)
end
