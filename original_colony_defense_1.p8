pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- pico galaxies: shared by every cart (voidstorm.p8 + the planet carts)
-- all sprites generated with krea 2 pixel art

-- sprite sheet slots: name,x,y,size (packed into one string to save tokens)
sp={}
for e in all(split(
 "ship,0,0,16|dra,16,0,16|drb,32,0,16|saa,48,0,16|sab,64,0,16|mine,80,0,16|div,96,0,16|ast,1"..
 "12,0,16|ex1,0,16,16|ex2,16,16,16|ex3,32,16,16|pow,48,16,8|shd,56,16,8|bmb,48,24,8|boss,64,"..
 "16,32|pla,96,16,32|p_lush,0,48,16|p_rock,16,48,16|p_ice,32,48,16|p_hive,48,48,16|freighter"..
 ",64,48,16|dome,80,48,8|i_food,88,48,8|i_ore,80,56,8|i_coin,88,56,8|i_colonist,96,48,8|flag"..
 "ship,0,64,32|t_grass,32,64,8|t_rock,40,64,8|t_crystal,48,64,8|t_water,56,64,8|nest,64,64,8"..
 "|b_farm,72,64,8|b_mine,80,64,8|b_harv,88,64,8|b_hab,96,64,8|b_turret,104,64,8|crawl_a,112,"..
 "64,8|crawl_b,120,64,8|b_hq,32,72,16|i_guns,48,72,8|i_cells,56,72,8","|")) do
 local a=split(e)
 sp[a[1]]={a[2],a[3],a[4]}
end

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

function hit(x1,y1,r1,x2,y2,r2)
 local dx,dy=x1-x2,y1-y2
 return abs(dx)<r1+r2 and abs(dy)<r1+r2 and dx*dx+dy*dy<(r1+r2)^2
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

-- original_colony_defense_1
-- planet verdant: real-time colony
-- defense with a trade run.
-- see design.md

-- terrain: 1 grass 2 rock 3 crystal 4 water 5 nest
tn=split"t_grass,t_rock,t_crystal,t_water,nest"
tname=split"grass,rock,crystal,water,nest"
gname=split"food,ore,crystal"
-- buildings. ok=terrain, o/c=ore/crystal cost,
-- w=needs worker, pr=produces (1-3 goods, 4 liberty)
bd={
 {n="farm",s="b_farm",ok={1},o=2,c=0,w=1,pr=1},
 {n="mine",s="b_mine",ok={2},o=1,c=0,w=1,pr=2},
 {n="harvester",s="b_harv",ok={3},o=3,c=0,w=1,pr=3},
 {n="habitat",s="b_hab",ok={1,2},o=3,c=1,cap=3},
 {n="turret",s="b_turret",ok={1,2},o=2,c=2},
 {n="assembly",s="dome",ok={1,2},o=4,c=2,w=1,pr=4},
 -- hq actions
 {n="load & launch",s="i_coin",o=0,c=0},
 {n="independence!",s="pow",o=0,c=0},
}
rc={11,9,12,14}
base=split"3,4,8"

function sn(n) return sp[n][2]\8*16+sp[n][1]\8 end

function _init()
 cartdata("original_colony_defense_1")
 t,shake,flash,lives,score=0,0,0,3,0
 parts,rings,fx,pops={},{},{},{}
 st="intro" music(0)
end

function msg(s,c) mtx,mt,mc=s,150,c or 7 end

function newgame()
 al,bul,ebul,blds,nests,m,bmap={},{},{},{},{},{},{}
 for y=0,13 do
  m[y]={}
  for x=0,15 do m[y][x]=1 end
 end
 for k in all(split"2,2,2,3,3,4,4") do
  local cx,cy,r=rnd(16),rnd(14),1+rnd(2)
  for y=0,13 do for x=0,15 do
   if ((x-cx)^2+(y-cy)^2<r*r) m[y][x]=k
  end end
 end
 for y=5,8 do for x=6,9 do m[y][x]=1 end end
 m[5][5],m[6][5],m[8][10],m[9][10],m[9][5]=1,1,2,2,3
 for i=1,2 do
  local x,y=i==1 and 0 or 15,2+flr(rnd(10))
  m[y][x]=5
  add(nests,{tx=x,ty=y,x=x*8+4,y=y*8+4,hp=60,q=0,cd=0})
 end
 hq={k=0,x=7,y=6,hp=25,mhp=25,fl=0}
 add(blds,hq)
 for i=0,3 do bmap[(6+i\2)*16+7+i%2]=hq end
 p={x=64,y=72,vx=0,vy=0,bank=0,inv=90,cd=0}
 res,cn,cap,day,ph,clock,burrow={3,6,0},3,4,1,"day",0,0
 cr,tax,lib,hold,war=20,5,0,12,0
 cg,pr,sold,boy={0,0,0},split"3,4,8",{0,0,0},{}
 cc,ab,abo,boss,menu=30,0,0,nil,nil
 assign()
 msg("build farms & mines. trade at aurum",10)
 st="play" sfx(8)
end

-- give workers to buildings in build order
function assign()
 local f=cn
 for b in all(blds) do
  local d=bd[b.k]
  if d and d.w then b.on=f>0 f-=1 end
 end
 idle=max(f,0)
end

function bc(b) local s=b.k==0 and 8 or 4 return b.x*8+s,b.y*8+s end

-- ===== update =====
function _update60()
 t+=1
 shake=max(0,shake-.4) flash=max(0,flash-1)
 if (mt and mt>0) mt-=1
 updvfx()
 if st=="play" then surface() sim()
 elseif st=="voy" then updvoy() sim()
 elseif st=="cargo" then updcargo()
 elseif st=="mkt" or st=="tax" then updmkt()
 elseif btnp(4) then
  if st=="intro" then newgame() else load("voidstorm.p8") end
 end
end

function stick()
 local dx,dy=0,0
 if (btn(0)) dx=-1
 if (btn(1)) dx=1
 if (btn(2)) dy=-1
 if (btn(3)) dy=1
 p.vx+=(dx*1.4-p.vx)*.25 p.vy+=(dy*1.4-p.vy)*.25
 p.bank+=(dx-p.bank)*.2
 if (p.inv>0) p.inv-=1
 p.cd-=1
end

function surface()
 if menu then updmenu() return end
 stick()
 p.x,p.y=mid(4,p.x+p.vx,123),mid(4,p.y+p.vy,107)
 if btn(4) and p.cd<=0 then
  local g=nearest(p.x,p.y,56)
  if g then
   local a=atan2(g.x-p.x,g.y-p.y)
   add(bul,{x=p.x,y=p.y-2,vx=cos(a)*4,vy=sin(a)*4,l=18})
   p.cd,p.mf=7,2 sfx(0)
  end
 end
 if (btnp(5)) openmenu()
end

-- colony simulation: runs on the surface and while the ship is away
function sim()
 clock+=1
 if ph=="day" then
  if (clock%240==0) produce()
  if (clock>=1500) nightfall()
 else
  for n in all(nests) do
   if n.q>0 and clock%30==0 then
    n.q-=1
    spawnc(n.x,n.y)
   end
  end
  if burrow>0 and clock%40==20 then
   burrow-=1
   local e=rnd()<.5
   spawnc(e and rnd{2,125} or rnd(124),e and rnd(108) or rnd{2,108})
  end
  if boss then updboss()
  elseif #al==0 and clock>60 then
   local w=burrow for n in all(nests) do w+=n.q end
   if (w==0) dawn()
  end
 end
 updal() updbul()
 for b in all(blds) do
  if (b.fl>0) b.fl-=1
  if b.k==5 then
   b.cd=(b.cd or 0)-1
   local x,y=bc(b)
   local g=nearest(x,y,34,true)
   if g and b.cd<=0 then
    local a=atan2(g.x-x,g.y-y)
    add(bul,{x=x,y=y,vx=cos(a)*3,vy=sin(a)*3,l=14})
    b.cd,b.mf=36,3 sfx(7)
   end
  end
 end
 for n in all(nests) do
  n.cd-=1
  if st=="play" and n.cd<=0 and hit(n.x,n.y,30,p.x,p.y,1) then
   eshoot(n.x,n.y,atan2(p.x-n.x,p.y-n.y),1.1) n.cd=50
  end
 end
end

-- nearest alien / nest / boss within r (turrets ignore nests)
function nearest(x,y,r,nn)
 local best,bd2=nil,r*r
 local function chk(o)
  local dx,dy=(o.x-x)/8,(o.y-y)/8
  local d=(dx*dx+dy*dy)*64
  if (d<bd2) best,bd2=o,d
 end
 foreach(al,chk)
 if (not nn) foreach(nests,chk)
 if (boss) chk(boss)
 return best
end

function produce()
 for b in all(blds) do
  local d=bd[b.k]
  if d and d.pr and b.on then
   if d.pr<4 then res[d.pr]+=1 else lib=min(100,lib+1) end
   local x,y=bc(b)
   if (st=="play") pop(x,y-4,"+1",rc[d.pr])
  end
 end
 if (lib==100 and war==0 and t%2==0) msg("liberty 100%! declare at hq",14)
end

function nightfall()
 ph,clock="night",0
 for n in all(nests) do n.q=2+day end
 burrow=#nests<2 and (3+day)*(2-#nests)\2 or 0
 if war>0 then
  for i=1,1+war*2 do add(al,{k="s",x=rnd(128),y=-8,hp=6,t=0,fl=0}) end
  if (war==3) boss={x=64,y=-30,hp=350,mhp=350,t=0,fl=0}
  msg(war==3 and "the flagship arrives!" or "war night "..war.."/3",8)
 else
  msg("night "..day..": aliens attack!",8)
 end
 sfx(9)
end

function dawn()
 day+=1 ph,clock="day",0
 res[1]-=cn
 if res[1]<0 then
  local k=min(cn,-res[1])
  cn-=k res[1]=0
  msg(k.." colonist(s) starved!",8) sfx(4)
 else
  local b=min(res[1]>=6 and 2 or res[1]>=3 and 1 or 0,cap-cn)
  if (b>0) cn+=b msg("dawn. +"..b.." colonist(s) born",11)
 end
 for i=1,3 do pr[i]=min(pr[i]+1,base[i]) end
 if (war>0) war+=1
 if (day==2 and cr==20) msg("tip: x on the hq to trade at aurum",10)
 assign()
end

function spawnc(x,y)
 add(al,{k="c",x=x,y=y,hp=2+day\3,t=rnd(30),fl=0,sp=.25+day*.01})
 ring(x,y,2,1,11,8) sparks(x,y,4,{11,3})
end

function hurtb(b,n)
 b.hp-=n b.fl=4
 local x,y=bc(b)
 sparks(x,y,3,{8,9})
 if (st=="voy" and t%60<2) msg("colony under attack!",8)
 if b.hp<=0 then
  explode(x,y,b.k==0 and 3 or 1)
  del(blds,b)
  for k,v in pairs(bmap) do if (v==b) bmap[k]=nil end
  if (b.k==0) gameover("the hq has fallen")
  if (b.on) cn-=1 msg("a worker died",8)
  if (b.k==4) cap-=3
  assign()
 end
end

function gameover(s)
 st,why,t="over",s,0
 music(-1)
end

function hitship()
 lives-=1 p.inv=120
 explode(p.x,p.y,2) sfx(4)
 if (lives<=0) gameover("your ship was destroyed")
end

function updal()
 for a in all(al) do
  a.t+=1
  if (a.fl>0) a.fl-=1
  do
   if (not a.tg or a.tg.hp<=0) a.tg=rnd(blds)
   local b=a.tg
   if b then
    local x,y=bc(b)
    local dx,dy=x-a.x,y-a.y
    local d=sqrt(dx*dx+dy*dy)+.01
    a.fx=dx<0
    if a.k=="s" then
     if d>26 then a.x+=dx/d*.6 a.y+=dy/d*.6
     elseif a.t%60==0 then eshoot(a.x,a.y,atan2(dx,dy),1.3,1) end
    elseif d>5 then a.x+=dx/d*a.sp a.y+=dy/d*a.sp
    elseif a.t%30==0 then hurtb(b,1) end
   end
  end
  if (st=="play" and p.inv==0 and hit(a.x,a.y,3,p.x,p.y,3)) hitship() kill(a)
 end
end

function kill(a)
 explode(a.x,a.y,1)
 score+=a.k=="c" and 10 or 40
 del(al,a)
end

function eshoot(x,y,a,s,hb)
 add(ebul,{x=x,y=y,vx=cos(a)*s,vy=sin(a)*s,hb=hb})
end

function updbul()
 for b in all(bul) do
  b.x+=b.vx b.y+=b.vy b.l-=1
  local gone=b.l<=0
  for a in all(al) do
   if not gone and hit(b.x,b.y,2,a.x,a.y,4) then
    a.hp-=1 a.fl=3 gone=true sparks(b.x,b.y,3,{7,11})
    if (a.hp<=0) kill(a)
   end
  end
  for n in all(nests) do
   if not gone and hit(b.x,b.y,2,n.x,n.y,4) then
    n.hp-=1 gone=true sparks(b.x,b.y,3,{14,11})
    if n.hp<=0 then
     explode(n.x,n.y,2) del(nests,n)
     m[n.ty][n.tx]=2 res[3]+=3 score+=150
     pop(n.x,n.y-6,"+3 crystal",12)
     if (#nests==0) msg("all nests destroyed!",11) score+=300
    end
   end
  end
  if boss and not gone and hit(b.x,b.y,2,boss.x,boss.y,12) then
   boss.hp-=1 boss.fl=3 gone=true sparks(b.x,b.y,3,{7,10})
  end
  if (gone) del(bul,b)
 end
 for b in all(ebul) do
  b.x+=b.vx b.y+=b.vy
  local g=b.hb and bmap[(b.y\8)*16+b.x\8]
  if b.x<0 or b.x>127 or b.y<0 or b.y>111 then del(ebul,b)
  elseif g then hurtb(g,2) del(ebul,b)
  elseif st=="play" and p.inv==0 and hit(b.x,b.y,1,p.x,p.y,3) then del(ebul,b) hitship() end
 end
end

function updboss()
 local b=boss
 b.t+=1
 if (b.fl>0) b.fl-=1
 b.y+=(28-b.y)*.02 b.x=64+sin(b.t/300)*40
 if (b.t%7==0) eshoot(b.x,b.y,b.t/60,.9)
 if b.t%80==0 and #blds>0 then
  local x,y=bc(rnd(blds))
  for i=-1,1 do eshoot(b.x,b.y+8,atan2(x-b.x,y-b.y)+i*.03,1.2,1) end
 end
 if b.hp<=0 then
  for i=1,8 do explode(b.x+rnd(24)-12,b.y+rnd(24)-12,2) end
  explode(b.x,b.y,4) flash=10
  boss=nil al={} score+=2000
  st,t="win",0
 end
end

-- ===== build / hq menu =====
function openmenu()
 local x,y=p.x\8,p.y\8
 local tl,o=m[y][x],bmap[y*16+x]
 opts={}
 if o==hq then
  if (war==0) add(opts,7)
  if (lib>=100 and war==0) add(opts,8)
  if (#opts==0) msg("hold the colony!",8) return
 elseif o then msg("tile occupied") return
 else
  for i,d in ipairs(bd) do
   for k in all(d.ok) do if (k==tl) add(opts,i) end
  end
 end
 if (#opts==0) msg("can't build on "..tname[tl]) return
 menu={x=x,y=y,i=1,h=true}
end

function updmenu()
 if menu.h then menu.h=btn(4) or btn(5) return end
 local n=#opts
 if (btnp(2)) menu.i=(menu.i-2)%n+1
 if (btnp(3)) menu.i=menu.i%n+1
 if (btnp(5)) menu=nil return
 if btnp(4) then
  local k=opts[menu.i]
  local d=bd[k]
  menu=nil
  if k==7 then
   st,ci,hold0="cargo",1,true return
  elseif k==8 then
   war=1 msg("independence declared! war begins",8)
   sfx(9) flash=6 nightfall() return
  end
  if res[2]>=d.o and res[3]>=d.c then
   res[2]-=d.o res[3]-=d.c
   local b={k=k,x=p.x\8,y=p.y\8,hp=6,fl=0}
   add(blds,b) bmap[b.y*16+b.x]=b
   if (d.cap) cap+=d.cap
   assign()
   local x,y=bc(b)
   sparks(x,y,12,{7,10,11}) ring(x,y,2,1.5,10,10)
   sfx(3)
   if (d.w and not b.on) msg("no free colonist: idle",9)
  else
   sfx(4) msg("need "..d.o.." ore "..d.c.." crystal",8)
  end
 end
end

-- ===== cargo, voyage, market =====
function updcargo()
 if hold0 then hold0=btn(4) or btn(5) return end
 if (btnp(2)) ci=(ci-2)%4+1
 if (btnp(3)) ci=ci%4+1
 if (btnp(5)) st="play" cg={0,0,0} return
 local used=cg[1]+cg[2]+cg[3]
 if ci<4 then
  if (btnp(1) and used<hold and res[ci]>cg[ci]) cg[ci]+=1 sfx(7)
  if (btnp(0) and cg[ci]>0) cg[ci]-=1 sfx(7)
 elseif btnp(4) then
  for i=1,3 do res[i]-=cg[i] end
  voyage(1)
 end
end

function voyage(d)
 st,vt,vdir,vo,vb="voy",0,d,{},{}
 p.x,p.y,p.inv=64,100,60
 for i=1,12 do part(64+rnd(8)-4,100,rnd(2)-1,2+rnd(2),20,{7,10,9,5},1,2) end
 sfx(6)
end

function updvoy()
 vt+=1
 stick()
 p.x,p.y=mid(6,p.x+p.vx,121),mid(20,p.y+p.vy,118)
 if btn(4) and p.cd<=0 then
  add(vb,{x=p.x-3,y=p.y-6}) add(vb,{x=p.x+3,y=p.y-6})
  p.cd,p.mf=7,2 sfx(0)
 end
 if vt%22==0 and vt<1100 then
  add(vo,{x=8+rnd(112),y=-8,k=rnd()<.35 and "div" or "ast",vy=.6+rnd(.9)+vt/1500,hp=2,f=rnd()<.5})
 end
 if (t%2==0) part(p.x+rnd(4)-2,p.y+8,0,1.5,8,{10,9,8},0,1)
 for o in all(vo) do
  o.y+=o.vy
  if (o.k=="div") o.x+=(p.x-o.x)*.012
  if o.y>136 then del(vo,o)
  elseif p.inv==0 and hit(o.x,o.y,6,p.x,p.y,4) then
   del(vo,o) explode(o.x,o.y,1) vhit()
  end
 end
 for b in all(vb) do
  b.y-=5
  for o in all(vo) do
   if b and hit(b.x,b.y,2,o.x,o.y,6) then
    o.hp-=1 sparks(b.x,b.y,3,{7,12}) del(vb,b) b=nil
    if (o.hp<=0) explode(o.x,o.y,1) del(vo,o) score+=5
   end
  end
  if (b and b.y<-4) del(vb,b)
 end
 if vt>=1250 then
  if vdir==1 then sell() else land() end
 end
end

function vhit()
 p.inv=60 shake=5 sfx(4)
 local k,n=1,0
 for i=1,3 do if (cg[i]>n) k,n=i,cg[i] end
 if vdir==1 and n>0 then
  cg[k]=max(0,n-2) msg("cargo lost: -2 "..gname[k],8)
  sparks(p.x,p.y,10,{9,10,4})
 elseif vdir<0 and ab>0 then
  ab-=1 msg("a colonist was lost!",8)
 else
  hitship()
 end
end

function sell()
 st,mi,hold0="mkt",1,true
 local inc=0
 for i=1,3 do
  if not boy[i] then
   for u=1,cg[i] do
    inc+=pr[i] sold[i]+=1
    if (sold[i]%5==0) pr[i]=max(1,pr[i]-1)
   end
   cg[i]=0
  end
 end
 local tx=flr(inc*tax/100)
 cr+=inc-tx score+=inc-tx
 mkm="sold "..inc.."cr, tax -"..tx.."cr"
 if inc>0 and tax<70 and rnd()<.55 then
  local g,n=1,0
  for i=1,3 do if (sold[i]>n and not boy[i]) g,n=i,sold[i] end
  st,ntax,tg,mi="tax",tax+5+flr(rnd(2))*5,g,1
 end
end

function land()
 cn+=ab res[2]+=abo
 for i=1,3 do res[i]+=cg[i] cg[i]=0 end
 if (ab>0) msg(ab.." new colonist(s) landed",11)
 ab,abo,st=0,0,"play"
 p.x,p.y,p.inv=64,60,60
 assign()
 ring(64,60,4,3,7,15) sfx(3)
end

function updmkt()
 if hold0 then hold0=btn(4) or btn(5) return end
 if st=="tax" then
  if (btnp(2) or btnp(3)) mi=3-mi
  if btnp(4) then
   if mi==1 then tax=ntax mkm="tax is now "..tax.."%"
   else boy[tg]=true lib=min(100,lib+15) mkm=gname[tg].." boycott! +15 liberty" end
   st,mi="mkt",1
  end
  return
 end
 if (btnp(2)) mi=(mi-2)%5+1
 if (btnp(3)) mi=mi%5+1
 if btnp(4) then
  local c=({cc,15,60,40,0})[mi]
  if mi==5 then voyage(-1) return end
  if mi==1 and ab>=4 then mkm="ship is full" return end
  if mi==3 and hold>=30 then mkm="hold is maxed" return end
  if cr<c then mkm="not enough credits" sfx(4) return end
  cr-=c sfx(3)
  if mi==1 then ab+=1 cc+=10
  elseif mi==2 then abo+=5
  elseif mi==3 then hold+=6
  else lives+=1 end
 end
end

-- ===== draw =====
nightpal={[6]=13,[7]=6,[9]=4,[10]=9,[11]=3,[12]=13,[15]=13,[14]=2}

function _draw()
 cls(0)
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
 if st=="intro" then drawintro()
 elseif st=="voy" then drawvoy()
 elseif st=="mkt" or st=="tax" then drawmkt()
 else
  drawplay()
  if (st=="cargo") drawcargo()
  if (st=="over") drawover()
  if (st=="win") drawwin()
 end
 camera()
 if flash>0 then
  fillp(0b0101101001011010)
  rectfill(0,0,127,127,flash>5 and 7 or 8)
  fillp()
 end
end

function drawplay()
 local nt=ph=="night"
 if (nt) pal(nightpal)
 for y=0,13 do for x=0,15 do
  local k=m[y][x]
  spr(sn(tn[k]),x*8,y*8)
  local h=(x*7+y*13)%11
  if (k==3 and (t\6+h)%23==0) pset(x*8+h%7,y*8+h%5+1,7)
  if (k==4 and (t\20+h)%4==0) line(x*8+h%4,y*8+h%6+1,x*8+h%4+2,y*8+h%6+1,12)
 end end
 if nt then
  fillp(0b0101101001011010.1)
  rectfill(0,0,127,111,1)
  fillp()
 end
 for b in all(blds) do
  if (b.fl>0) whiteout()
  local x,y=bc(b)
  dspr(b.k==0 and "b_hq" or bd[b.k].s,x,y)
  if (nt) pal(nightpal) else pal()
  if b.hp<(b.mhp or 6) then
   line(x-3,y-6,x-3+6*b.hp/(b.mhp or 6),y-6,8)
  end
  local d=bd[b.k]
  if (d and d.w and not b.on and t%40<20) print("z",x+2,y-8,6)
  if (b.mf and b.mf>0) b.mf-=1 circfill(x,y,2,10)
 end
 pal()
 for b in all(blds) do
  if nt and (b.k==4 or b.k==0) and (t+b.x*7)%60<45 then
   local x,y=bc(b) pset(x-1,y,10) pset(x+1,y-1,10)
  end
 end
 for n in all(nests) do
  circ(n.x,n.y,3+sin(t/40)*1.5,n.q>0 and 8 or 11)
  if (n.hp<60) line(n.x-3,n.y-7,n.x-3+6*n.hp/60,n.y-7,11)
 end
 if not menu and st=="play" then
  local cx,cy=p.x\8*8,p.y\8*8
  rect(cx,cy,cx+7,cy+7,t%20<10 and 7 or 13)
 end
 for a in all(al) do
  if (a.fl>0) whiteout()
  if a.k=="c" then dspr(t\8%2==0 and "crawl_a" or "crawl_b",a.x+sin(t/16)*.5,a.y,1,a.fx)
  else dspr(t\10%2==0 and "saa" or "sab",a.x,a.y,.7) end
  pal()
 end
 if boss then
  if (boss.fl>0) whiteout()
  dspr("flagship",boss.x,boss.y)
  pal()
  rect(13,1,114,4,5)
  rectfill(14,2,14+boss.hp/boss.mhp*99,3,8)
 end
 for b in all(ebul) do circfill(b.x,b.y,1.5,b.hb and 9 or 8) pset(b.x,b.y,7) end
 for b in all(bul) do line(b.x,b.y,b.x-b.vx,b.y-b.vy,12) pset(b.x,b.y,7) end
 if st=="play" and (p.inv==0 or t%6<3) then
  ovalfill(p.x-4,p.y+5,p.x+4,p.y+7,1)
  drawship(p.x,p.y,.7)
 end
 drawvfx()
 drawhud()
 if (menu) drawmenu()
end

function drawhud()
 rectfill(0,112,127,127,0)
 line(0,112,127,112,ph=="night" and 8 or 13)
 local ic=split"i_food,i_ore,pow"
 for i=1,3 do
  dspr(ic[i],4+(i-1)*21,117)
  print(res[i],9+(i-1)*21,115,7)
 end
 dspr("i_colonist",68,117)
 print(cn.."/"..cap,73,115,idle>0 and 11 or 7)
 if (cr!=lcr) crf,lcr=40,cr
 crf=max(0,(crf or 0)-1)
 dspr("i_coin",97,117) print(cr,102,115,crf%8>3 and 7 or 10)
 print((war>0 and "war " or "day ")..day,2,122,ph=="night" and 8 or 10)
 if ph=="night" then
  local n=#al+burrow for o in all(nests) do n+=o.q end
  print(n,28,122,8)
 else rectfill(28,123,28+clock/1500*12,125,10) end
 print("lib",44,122,14)
 rect(57,122,87,126,5)
 rectfill(58,123,58+lib*.28,125,lib>=100 and t%8<4 and 7 or 14)
 print("tax"..tax.."%",92,122,8)
 if mt and mt>0 then
  local w=#mtx*2
  rectfill(62-w,2,65+w,9,0)
  print(mtx,64-w,3,mt%20<15 and mc or 7)
 end
end

function drawmenu()
 local mx=menu.x>8 and 2 or 54
 local h=#opts*9+12
 rectfill(mx,14,mx+71,14+h,0)
 rect(mx,14,mx+71,14+h,12)
 print(opts[1]>6 and "colony hq" or "build on "..tname[m[menu.y][menu.x]],mx+3,17,6)
 rect(menu.x*8-1,menu.y*8-1,menu.x*8+8,menu.y*8+8,10)
 for i,k in ipairs(opts) do
  local d=bd[k]
  local y=17+i*9
  local ok=res[2]>=d.o and res[3]>=d.c
  if (i==menu.i) rectfill(mx+1,y-2,mx+70,y+6,1)
  dspr(d.s,mx+7,y+2)
  print(d.n,mx+13,y,ok and 7 or 5)
  if (k<7) print(d.o.."o"..(d.c>0 and d.c.."c" or ""),mx+54,y,ok and 9 or 5)
 end
end

function drawcargo()
 rectfill(14,20,113,96,0) rect(14,20,113,96,10)
 print("load cargo for aurum",24,24,10)
 local used=cg[1]+cg[2]+cg[3]
 local ic=split"i_food,i_ore,pow"
 for i=1,3 do
  local y=30+i*12
  if (ci==i) rectfill(16,y-3,111,y+7,1)
  dspr(ic[i],24,y+2)
  print(gname[i],31,y,boy[i] and 5 or 7)
  print("< "..cg[i].." >",64,y,7)
  print("/"..res[i],92,y,6)
  if (boy[i]) print("boycott",64,y+6,8)
 end
 if (ci==4) rectfill(16,79,111,87,1)
 print("launch",50,81,ci==4 and 11 or 6)
 print("hold "..used.."/"..hold,24,90,used==hold and 8 or 6)
 print("x cancel",76,90,5)
end

function drawvoy()
 for i=1,48 do
  local s=(i*53)%128
  local y=(i*37+t*(1+i%3)*1.2)%128
  line(s,y,s,y+i%3*2,i%3==0 and 7 or 1)
 end
 for o in all(vo) do dspr(o.k,o.x,o.y,o.k=="ast" and .8 or .7,o.f,o.k=="div") end
 for b in all(vb) do line(b.x,b.y,b.x,b.y+3,12) end
 if (p.inv==0 or t%6<3) drawship(p.x,p.y)
 drawvfx()
 local s=vdir==1 and "to aurum" or "home to verdant"
 oprint(s,64-#s*2,3,10)
 rect(20,10,107,13,5)
 rectfill(21,11,21+vt/1250*85,12,11)
 local c=vdir==1 and (cg[1]+cg[2]+cg[3]).." cargo" or ab.." colonists aboard"
 oprint(c,2,121,7)
 oprint((ph=="night" and "colony: night "..day or "colony: day "..day),62,121,ph=="night" and 8 or 6)
 if mt and mt>0 then oprint(mtx,64-#mtx*2,108,mc) end
end

function drawmkt()
 rectfill(0,0,127,127,1)
 dspr("pla",104,20,1.2)
 print("\^w\^taurum",4,4,10)
 print("hegemony market",4,16,6)
 oprint("credits "..cr.."  tax "..tax.."%",4,26,7)
 for i=1,3 do
  local x=4+(i-1)*42
  dspr(({"i_food","i_ore","pow"})[i],x+4,40)
  print(boy[i] and "x" or pr[i].."cr",x+10,38,boy[i] and 8 or 10)
 end
 if st=="tax" then
  rectfill(6,50,121,96,0) rect(6,50,121,96,8)
  print("the hegemony raises",26,54,7)
  print("tax to "..ntax.."%!",40,62,8)
  print((mi==1 and "> " or "  ").."accept",30,74,mi==1 and 10 or 6)
  print((mi==2 and "> " or "  ").."boycott "..gname[tg].." +15lib",30,84,mi==2 and 10 or 6)
  return
 end
 local rows={"colonist ("..ab.."/4)",cc,"ore crate x5",15,"cargo hold +6",60,"repair hull",40,"launch home",""}
 for i=1,5 do
  local y=48+i*9
  if (i==mi) rectfill(2,y-2,125,y+6,0)
  print(rows[i*2-1],8,y,i==mi and 10 or 7)
  print(rows[i*2],100,y,9)
 end
 print(mkm or "",4,110,11)
 print("aboard: "..abo.." ore  hold "..hold,4,119,6)
end

function drawintro()
 for i=1,40 do pset((i*37+t/(1+i%3))%128,(i*53)%128,i%3==0 and 7 or 13) end
 dspr("p_lush",64,40,3+sin(t/120)*.1)
 print("\^w\^tverdant",36,70,11)
 oprint("build a colony. ship goods to",6,84,7)
 oprint("aurum, buy settlers. the tax",8,91,7)
 oprint("rises: earn liberty and break free",0,98,9)
 if (t%40<28) oprint("z: land the colony ship",18,110,11)
 oprint("z fire  x build/hq  arrows fly",4,120,6)
end

function drawover()
 rectfill(10,40,117,82,0) rect(10,40,117,82,8)
 print("\^w\^tcolony lost",20,45,8)
 oprint(why,64-#why*2,60,7)
 oprint("score "..score,64-#("score "..score)*2,68,10)
 if (t>60 and t%40<28) oprint("z: back to title",32,76,6)
end

function drawwin()
 rectfill(4,36,123,84,0) rect(4,36,123,84,10)
 local s="independence!"
 for i=1,#s do
  print("\^w\^t"..sub(s,i,i),12+(i-1)*8,42+sin(t/50+i/10)*2,({10,9,12,7})[(t\5+i)%4+1])
 end
 oprint("verdant is free",34,60,7)
 oprint("score "..score,64-#("score "..score)*2,68,10)
 if (t%50==0) explode(20+rnd(88),10+rnd(40),1)
 if (t>90 and t%40<28) oprint("z: back to title",32,76,6)
end
__gfx__
000000011000000000000000000000000000d200000d000000000000000000000000000000000000000000041000000000000002400000000000000011100000
00000001c100000000000200002000000000011000110000000000000000000000000000000000000000000e4000000000000009400000000000001d6d500000
00000017c100000000000020001000000000001002100000000000dddd0000000000000dd10000000002004421002000000000291000000000001666ddd50000
0000001771000000666000011100006c00000011110000000000066666d00000000000666d10000000241422412e400000000049410000000001d66ddd510000
0000001111000000666c0052220006660000012d2210000000006676666d00000000067666d10000000424444442100000220249441010000001d56555511000
00000011110000006666c0b22b306666000001222231000000006666666d50000000d67666dd100000022ee44442000002994494441441000001555551151000
000011111101100000666d1222166660000001111110000000036666666d1000000066666ddd100000044e422144100000299499441441000001555511115500
00011111111110000006dd1111dd66000000ddd212dd00000036166666dd331000433555555334500e244497a9241100000124994411100000065555111d5500
01017d177d1710010006c122221c6000000166d22d66d00033a3333333333a3304f4f3333334322324444297a942121000110499444010000056d55551555500
01157d177d1711010066111111016600001666d11d666d003333aa33333a33313343e233433433350014429aa9421100006021194141d00001dd555555555100
11cc7d17dd17111100022112210110000d6666d111d666d00333393a933333300333333333333330001244299922100000402119114140000555115555511100
1ccc7d177d1711d1000011122210100016666d12211d666d00133333333331100005333333331100000244424422100004940419442094000555115551111100
1111711cc11711110000010111010000d666212d2211d66d00001131113110000000111111113000002412222224100004f904994219f9000015d55511111100
0101111dd11110010000110010110000d66d011222102d6d00030003330033000033001001105300002111111111100004990299420499000005555111111000
00015111111510000000010000010000ddd00011211002dd00000000000000000000000000000000000000221000000000940049420094000000111115510000
00001100000100000000000000000000000000011000000000000000000000000000000000000000000000021000000000000004100040000000011111100000
0000000900000000000002222000000000000005550000000009000000ddd0000000000000000000000000000000000000000000000000000000000000000000
00000009000000000000244442000000000000d6dd500000007790000d111c000000000000000000000000000000000000000000000000000000000000000000
0000000990000900000244944422000000000dd6ddd5000005799400717111d00000000000000000000000000000000000000000000000000000000001444000
0000009a94000000000249994444200000005dddddd5000005999400c11111d00000000000000000000000000000000000000000000000000000000149449400
000909aaa99090000002499994492000000555dddd55550005999900c11111d00000004410000000000000044100000000000000000000000000012999999940
00004aaaaa990000012449999944220000d6d55ddd5ddd00057a9900d1111cd0000004e41000000000000004e410000000000000000000000000244421499940
00049aa77aaa900004444999994444000dd6dddddddddd500099a0000dddcdd00000044100000000000000001410000000000000000001111112421111149940
0049aaa777fa9400249999fff99994400ddddddd5dddd5500009000000dddd00000001220000000000000001411000000000000000012ddd2221111111129940
009aa7777777a900249999fff99994200dddd5dd5dddd52000006600000000000000001220001111111000142100000000000000001eeeedd2d2211111149400
009a77777777a90024499ffffff99420055d5555555d5220000441000000000000000001220144e442210142000000000000000001eeeeedddd2211111299400
009aa777777fa90002499ffff994442000552211125522000444410000000000000000001214ee444422122100000000000000001eeeeedddd2dd221119f4100
0099a777777a9400024999ffff9442000001222110222000444442000000000000000000014e4444444421000000000000000001eeeeedddd2ddd22114f92000
00099a7777a990000449999ff9942000000000012200000047776240000000000000000124e4444444444111000000000000000deeeedddd2ddddd2219940000
00009aa7faa94000004444999994200000000001220000004477424000000000000001114444411111144221100000000000001eeeeddd2ddddd2d224f410000
0009099aaa940000000224444442000000000012200000002444240000000000000124414444112222114222111000000000001eeeddd2ddddd2ed24f9200000
0900009999000000000000222220000000000010000000000222400000000000001442244441127ee2211222221100000000001dddd22dddd2ded24f94000000
000000000000000000000000000000000000000000000000000000000000000000144444444112eeee211222222220000000001ddd2ddddd2ded24f941000000
000000000000000000000000000000000000000000000000000000000000000000011111124112eeee211210000000000000001dddddddddded24f9411000000
000000000000000000000000000000000000000000000000000000000000000000000000124411eee2112210000000000000011ddddddddeedd4f94111000000
00000000000000000000000000000000000000000000000000000000000000000000000001244112211221000000000000001212dddddded224f941110000000
00000000000000000000000000000000000000000000000000000000000000000000000100124411112210000000000000012211ddd22ed224f9411110000000
000000000000000000000000000000000000000000000000000000000000000000000015100022222221001110000000000241112d2dd2249994112110000000
0000000000000000000000000000000000000000000000000000000000000000000001650000000000000015510000000014211112dd22499941121100000000
000000000000000000000000000000000000000000000000000000000000000000001ddd500001111110000ddd50000000491111112249994211111000000000
000000000000000000000000000000000000000000000000000000000000000000005d11510000111100001d1151000001941111112499941122110000000000
00000000000000000000000000000000000000000000000000000000000000000000551111000000000000151111000004942111249994211111100000000000
00000000000000000000000000000000000000000000000000000000000000000000051110000000000000051110000004999424999441111110000000000000
00000000000000000000000000000000000000000000000000000000000000000000005500000000000000005500000004999999994200000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001499999420000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000144441000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000003cccc00000000000122220000000000011100000000002000000000000000000005500000000000000000040000001dd000000000000000000000000000
0005333c3ccc5000000029999420000000000111100000000222000000002000000000576000000000d611000009440001dd1100000000000000000000000000
001b35c31cc3350000019ff9999200000000117c111100000221000000022200000005666100000006666d10094944000d1f1100000000000000000000000000
03b33c3ccc3c53000019f999924920000000116611111000001112221202220000000d7115000000166665d500944400001ff000000000000000000000000000
03333316ccc33350009f99999224910000111166d1c1110000012dd222121000000005df945000003b6616550094400006d11100000000000000000000000000
033b3c66cc33551004f1429999999410011617dc777611000002dd62222110000000055941500000666d11d5000450000ddddd00000000000000000000000000
1335c66cccc331502914449999999910011d67777776d110002d3d21512210000000055551500000166005d10099400005515000000000000000000000000000
c35ccccccc3bb35049244499999999100111d7777777d110002dd21333121110000056d111550000000000000004400000101000000000000000000000000000
c533ccccc333333049924999992299100011666d7776dd100122221bbb1212100005fd5941545000000006d00099900000000000000000000000000000000000
dc5333cccc3333504999499992224410001177d67766d11001222213b3121100005f9d5991544000000066650999990000000000000000000000000000000000
0cc3333ccc5555502499999999244410001177677761d11002252221312211000df99d5991544400000666559997999000000000000000000000000000000000
01c33333ccc1555002491299994444100016677776dd611002132222222121000d999d5991544400006665519979999000000000000000000000000000000000
01155335ccc1155001442249994442100011166666dd1110022322222211100005ddd6d555555500076655109999994000000000000000000000000000000000
00115551c1111500001449499444410000011dddddd11100001222222111100000000d66661000006dd551009999999000000000000000000000000000000000
000d5511111d50000001444444421000000011111111100000011111111100000000005555000000ddd510000999992000000000000000000000000000000000
000015dddd110000000011111111000000000111111100000000111111000000000000544500000005d100000094420000000000000000000000000000000000
0000000000000000000000000000000033333333ddd5dddddddddddd11111111000dd00000002000000510000001000000666d00005d050000b00b0000b00000
000000000000000f900000000000000033333333ddd5ddd9d76ddddd1111111100dd21000772117000f550000011100000777600006561500003300000503000
00000000000000f7940000000000000033333333dd55ddd4565dddd5111111110d522210777414d77741157000111100077777600055d5000b0bb1b000333030
00000000000f009f94009000000000003333333355555555d5dddddd111111110dd2211077351577741d1557006611007777776d006ddd1000bb5b0003113300
000000000009f91941494000000000003333b333dd5dd555ddddddddccc11111022215117535337775111117016dd1006777767d05d55d10b1bb5b3bb1333330
0000000000004f96549200000000000033333333dddddddddddddd6dd1dccccc21121b317555557777545177111111106767766d06d5551003bb5b1313333310
00000000000000ff44000000000000003333333394d5dddddddddc651111ddd1122222117777777777111777111111106761166d00dddd500513330330333100
00000000000ff4565149400000000000333b33339445ddddddddd55d1111111101111111000000000000000011011010067116d0000551000300003003010000
0000000000000d766500000000000000000000010000000000000000000650000000000000000000000000000000000000000000000000000000000000000000
0000000000100065510010000000000000000066d000000000000500006615000000000000000000000000000000000000000000000000000000000000000000
000000000015046665201000000000000000067765000000961466d2005d15000000000000000000000000000000000000000000000000000000000000000000
00000005611516ff4450101d00000000000016766d5000001ddd1d12003a53000000000000000000000000000000000000000000000000000000000000000000
000000061611d77766d5116150000000000016651d50000004111d00003b33000000000000000000000000000000000000000000000000000000000000000000
0000000055d119111141165500000000000016d55150000044000000003b33000000000000000000000000000000000000000000000000000000000000000000
00000561115d1794145155111d100000000016641d50000021000000003b33000000000000000000000000000000000000000000000000000000000000000000
0000061d11f416776d51441161500000000016665d50000000000000005355000000000000000000000000000000000000000000000000000000000000000000
00000555df911d551111144d55000000000016666d50000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000001594167666665124510000000000016666d50000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ff999f46616616529444440000000001d666d10000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000920009f651151159400024000000006dd66dd01000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000001511069f6ddd559450111000000001610111101100000000000000000000000000000000000000000000000000000000000000000000000000000000000
000056d510669ff79944150156510000016d000000001d0000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005615d1066699f444155016115100001d0001d5000010000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006111510266d194115500151115000d6d000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000
00061115102466d94155200151115000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005d151002446665552200015150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001110000244665522000001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000024442220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000002442200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000112220000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012442242200000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011144444444420000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000122221112444420000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000122221112444420000000000000000000
0000000000000000000000000000000000000d000000000000000000000000000000000000070000000000111111111211111111244420000000000000000000
00000000000000000000000000001000000000000000000000000000000000000000000000000000070011111111111111111111144420000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000122222111111111111111242200000000000000000000
00000000000700000000000000000000000000000000000000000000000000000000000000000000011222222111111111111111442200000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000011222222111111111111111442200000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000122222221111111111111114d21100000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000122222211111111111111122d410000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000001222221111111111111111444200000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000012222211111111111111112dd2100000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000012222211111111111111112dd2100000000000000000000000
0000000000000000000000000000000000000001000000000000000000000000000000000000001222211111111111121112d441000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111121112d4220000000000000100000000000
00000000000000000000000000000000000000000000000000000000000000000000000000010011111111111111121122d42110000000000001000000000000
000000000000000001000000000000000000000000000000000000000000000000000000000000111111111111122112dd421110000000000000dddd00000000
000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111122112dd4211100000000000066666d0000000
00000000000000000000000000000000000000000000000000000000000000000000000000001111111111111221112d4421111000000000006676666d000000
0000000000000000000000000000000000000000000000000000000000000000000000000001111111111111211112d42211100000000000006666666d500000
000000000000000000000000000000700000000000000000000000000001000000000000001111111111112211122d421111100000000000036666666d100000
000000000000000000000000000000000000000000000000000000000000000000000000001211111111111112444421111110000000000036166666dd331000
000000000000000000000000000000000000000000000000000000000d000000000000000012111111111111124444211111100000000033a3333333333a3300
000000000000000000000000000000000000000000000000000000000d00000000000000012111111111111124444211111100000000003333aa33333a333100
000000000070000000000000000000000000000000000000000000000000000000000000024111111111124444211111111000000000000333393a9333333000
00000000000000000000000000000000000000000000000000000000000000000000000114211111111124444211111111000000000000001333333333311000
00007000000000000000000000000000000000000000000000000000000000000000000224211111122444221111111100000000000000000011311131100000
0000000000000000000000000000000000010000000000000000000000000000000000022421111112244422d111111100000000000000000300033300330000
00000000000000000000000000000000000000000000000000000000000000000000000224442212444422111111110000000000000000000000000000000000
00000000000000100000000000000000000001000000100000000000000000000000000224444444444210000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000112444444211000000000000000000000000000000000000000000000
00000000000020000200000000000000000000000000000000000000000000000000000001222221000000000000000000000000000000000000000000000000
00000000000002000100000000000000000000000000000000100000000000000000000001222221000000000000000000000000000000000000000000000000
0000000666000011100006c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000666c005222000666000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000006666c0b22b3066660000000000000000000000000000000000000000000000000000000000d0000000000000000000000000000000000000000000000
000000000666d1222166660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006dd1111dd6600000000000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006c122221c6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066111111016600000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000
00000000002211221011cccccc00007777000000000000000000000000000000000000000000000000000000000077777700cccccc0000000000000000000000
000000000001eeeeee01cccccc200077772000cccc000000000000000000000000000000000000000000cc00cc0077777720cccccc2000eeee00000000000000
000000000000eeeeee2002cc22207702222000cccc200000000000000000000000000000000000000000cc20cc2002772220cc22222000eeee20000000000000
000000000001ee22ee2000cc200077200000cc02cc2000000000000000000000000000000000eeeeee00cc20cc2000772000cc200000ee022220000000000000
000000000000ee20ee2000cc200077200000cc20cc20000000000000000000000000cc000000eeeeee20cc20cc2000772000cccc0000ee200000000000000000
000000000000eeeeee2000cc200077200000cc20cc200000000000cccc0077777700cc200000ee22ee2002cc022000772000cccc2000eeeeee00000000000000
000000000000eeeeee2000cc200077200000cc20cc200000000000cccc2077777720cc200000ee20ee2000cc200000772000cc222000eeeeee20000000000000
000000000000ee22222000cc200077200000cc20cc2000070000cc02222077227720cc200000eeeeee20cc02cc0000772000cc2000000222ee20000000000000
000000000000ee200000cccccc0002777700cc20cc2000000000cc20000077207720cc200000eeeeee20cc20cc2077777700cccccc000000ee20000000000000
000000000000ee200000cccccc2000777720cccc022000000000cc20000077777720cc200000ee22ee20cc20cc2077777720cccccc20eeee0220700000000000
000000000000ee2000000222222000022220cccc200000000000cc20000077777720cc200000ee20ee20cc20cc200222222002222220eeee2000000000000000
0000000000000220000000000000000000000222200000000007cc20cc0077227720cc200000ee20ee2002200220000000000000000002222000010000000000
0000000000000000000000000000000000000000000000000000cc20cc2077207720cccccc00ee20ee2000000000000000000000000000000000000000000000
0000000000010000000000000000000000000000000000000000cccccc2077207720cccccc200220022000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000cccccc2077207720022222200000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222222002200220000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000d0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000070000000000000000000000000000000001c100000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000017c1000000000000000000000000000000000000d0000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000177100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000111100007000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111101100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000111111111100000000000000000000000100000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000001017d177d17100100000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000001157d177d171101000000000000000000000000000d0000000000000000000000000000
0000000000000000000000000000000000000000000000000000000011cc7d17dd17111100000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000001ccc7d177d1711d100000000000000000000000000000000000000000000000000000000
00000000000000000000000000000700000000000000000d000000001111711cc117111100000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000101111dd111100100000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000151111115100000000000000000000000000000000000000000000000000000000000
00d00000000000001000000000000000000000000000000000000000000811a808a1a80000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000088a88088a880000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000888880888880000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000088800088800000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000111000001111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000001a1100001aaa1aaa11aa1aaa1aa11aaa1000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000011a110001a1a1a1a1a111a1a1a1a1a111000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000011a10001aaa1aa11a101aaa1a1a1aa10000000000000000000000000000000000000070000000000000000000000000000
0000000000000000000000000000011a110001a1a1a1a1a111a1a1a1a1a111000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000001a1100001a1a1a1a11aa1a1a1aaa1aaa1000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000111000001111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000010000000000000000111111111100111111111111000111111111111111111110111111110000000000000000000000000000000000
00000000000000000000000000000000000001166116616101166166116161000166116661666166616611166166610000000000000000000000000000000000
00000000000000000000000000000000000001611161616101616161616161000161616111611161116161611161110007000000000000000000000000000000
00000000000000000000000000000000000001610161616101616161616661000161616611661166116161666166100000000000000000000000000000000000
000000000d0000000000000000000000000001611161616111616161611161000161616111611161116161116161110000000000000000000000000000000000
00000000000000000000000000000000000001166166116661661161616661000166616661610166616161661166610000000000000000000000000000100000
00000000000000000000000000000000000000111111111111111111111111000111111111110111111111111111110000000000000000000000000000000000
00000000000000000000000000000000000000111111111100111111111111111111111111111111111110000000000000000000000000000000000000000000
00000000000000000000000000000000000001166116616101166166116661666166616661666116616611000000000000000000000000000000000000000000
0000000000000000000000000000000000000161116161610161616161161111616161161116116161616100000000d000000000000000000000000000000000
00000000000000000000000000000000000001610161616101616161611611161166611610161161616161000000000000000000010000000000000000000000
0000000000000000000000000000000000000161116161611161616161161161116161161116116161616100000000000000000000001000000000000000000d
00000000000000000000000000000000000001166166116661661161616661666161611611666166116161000000000000000000000000000000000000000000
00000000000000000000000000000000000000111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000
00000000000000000000000000000000000000111111111111111111111111111111111111000000000000000000000111111100000000000000000000000000
000000000000000000000000000000000000011661616166616161666161611661666116610000000000000000000001ddddd100000000000000000000000000
0000000000000000000000000000000000000161116161616161611611616161616161611100000000000000000000011ddd1100000000000000000000000000
00000000000000000000000000000000d00001666161616611616116116161616166116661000000000000000000000011d11000000000000000000000000000
0000000000000000000000000000000000000111616161616166611611666161616161116100000000000d000000000001110000000000000000000000000000
00000000000000000000000000000000000001661116616161161166611611661161616611000000000000000000000000000000000000000100000000000000
00000000000000000000000000000000000001111011111111111111111111111111111110000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000304502d4502a4402744024430214300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001e6701c6701a66018660166501465012640106400e6300c6300a620086200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001867017670166701567014660136601266011660106500f6500e6500d6500c6400b6400a6400964008630076300663005630046200362002620016200000000000000000000000000000000000000000
0003000024150281502b1503015034150371500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002827125271222711f2711c271192711627113271102710d27100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001e3301d3301c3301b33000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000a6720c6720e67210672126721466216662186621a6621c6621e65220652226522465226652286422a6422c6422e64230642326323463236632386323a6323c6223e6224062200000000000000000000
000100003763032620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000024450244502b4502b450304503045037450374503c4503c4503c4503c4500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060000242512425124251242511e2511e2511e2511e251242512425124251242511e2511e2511e2511e251242512425124251242511e2511e2511e2511e251242512425124251242511e2511e2511e2511e251
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e00001515015130151502113015150151301515021130151501513015150211301515015130151502113015150151301515021130151501513015150211301515015130151502113015150151301515021130
000e00001515015130151502113015150151301515021130151501513015150211301515015130151502113015150151301515021130151501513015150211301515015130151502113015150151301515021130
000e00001115011130111501d1301115011130111501d1301115011130111501d1301115011130111501d1301115011130111501d1301115011130111501d1301115011130111501d1301115011130111501d130
000e00001315013130131501f1301315013130131501f1301315013130131501f1301315013130131501f1301315013130131501f1301315013130131501f1301315013130131501f1301315013130131501f130
000e00002d4303042034420394202d4203042034420394202d4303042034420394202d4203042034420394202d4303042034420394202d4203042034420394202d4303042034420394202d420304203442039420
000e00002d4303042034420394202d4203042034420394202d4303042034420394202d4203042034420394202d4303042034420394202d4203042034420394202d4303042034420394202d420304203442039420
000e0000294302d4203042035420294202d4203042035420294302d4203042035420294202d4203042035420294302d4203042035420294202d4203042035420294302d4203042035420294202d4203042035420
000e00002b4302f42032420374202b4202f42032420374202b4302f42032420374202b4202f42032420374202b4302f42032420374202b4202f42032420374202b4302f42032420374202b4202f4203242037420
000e00000c660000003c6100000028630000003c610000000c660000003c6100000028630000003c610000000c660000003c6100000028630000003c610000000c660000003c6100000028630000003c61000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 10141841
00 11151841
00 12161841
02 13171841
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
