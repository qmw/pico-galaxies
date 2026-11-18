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
