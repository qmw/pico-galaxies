-- survivors_1 (demake)
-- planet swarmfall: horde survival.
-- move only; weapons fire themselves.
-- see design.md

wn=split"pulse blaster,orbiters,nova,arc,mine layer"
wd=split"bolts at the nearest foe,orbs circle and strike,shockwave hits all near,lightning chains foes,mines blast crowds"
wi=split"i_guns,shd,bmb,i_cells,mine"
pn=split"speed,magnet,armor,overclock,power"
pd=split"+15% move speed,+pickup range,+2 max hp -damage,-10% weapon cooldown,+25% damage"
pi=split"ship,pow,i_food,i_coin,ex1"
-- enemies: sprite a, sprite b, scale, hp, speed, radius, xp
et={
 c={"crawl_a","crawl_b",1,2,.42,3,1},
 d={"dra","drb",.55,4,.55,4,1},
 v={"div","div",.55,3,1.05,4,3},
 s={"saa","sab",.75,22,.32,6,10},
 b={"boss","boss",1,300,.25,13,30},
 f={"flagship","flagship",1,800,.22,13,0},
}

function _init()
 t,shake,flash=0,0,0
 parts,rings,fx,pops={},{},{},{}
 st="intro" music(0)
end

function newgame()
 p={x=0,y=0,hp=10,inv=0,lv=1,xp=0,f=false}
 wl,pl,cd={1,0,0,0,0},{0,0,0,0,0},{0,0,0,0,0}
 en,gems,bul,mines,arcs={},{},{},{},{}
 parts,rings,fx,pops={},{},{},{}
 clock,kills,ev=0,0,0
 st="play" sfx(8)
end

function mhp() return 10+pl[3]*2 end
function pow() return 1+pl[5]*.25 end
function cdm() return 1-pl[4]*.1 end
function nx() return 5+p.lv*4 end

-- ===== update =====
function _update60()
 t+=1
 shake=max(0,shake-.4) flash=max(0,flash-1)
 updvfx()
 if st=="play" then updplay()
 elseif st=="lvup" then updlvup()
 elseif btnp(4) then
  if st=="intro" then newgame() else load("voidstorm.p8") end
 end
end

function updplay()
 clock+=1
 local dx,dy=0,0
 if (btn(0)) dx=-1 p.f=true
 if (btn(1)) dx=1 p.f=false
 if (btn(2)) dy=-1
 if (btn(3)) dy=1
 local s=(dx!=0 and dy!=0) and .71 or 1
 s*=.9+pl[1]*.135
 p.x+=dx*s p.y+=dy*s
 if (p.inv>0) p.inv-=1
 spawner()
 weapons()
 for e in all(en) do
  local d=et[e.k]
  local a=atan2(p.x-e.x,p.y-e.y)
  e.x+=cos(a)*d[5] e.y+=sin(a)*d[5]
  e.fx=p.x<e.x
  if (e.fl>0) e.fl-=1
  if (e.hc>0) e.hc-=1
  if p.inv==0 and hit(e.x,e.y,d[6],p.x,p.y,3) then
   p.hp-=max(.5,1-pl[3]*.15) p.inv=40 shake=4 sfx(4)
   sparks(p.x,p.y,8,{8,2,7})
   if (p.hp<=0) st,t="over",0 music(-1) explode(p.x,p.y,3)
  end
  -- far-away stragglers respawn near the player
  if (abs(e.x-p.x)>100 or abs(e.y-p.y)>100) and e.k!="f" and e.k!="b" then spawnat(e) end
 end
 for g in all(gems) do
  local dx,dy=p.x-g.x,p.y-g.y
  local d=abs(dx)+abs(dy)
  if (d<16+pl[2]*12) g.m=true
  if g.m then
   g.v_=(g.v_ or 1)+.15
   local a=atan2(dx,dy)
   g.x+=cos(a)*g.v_ g.y+=sin(a)*g.v_
  end
  if d<5 then
   del(gems,g)
   if g.h then p.hp=min(p.hp+3,mhp()) pop(p.x,p.y-8,"+3hp",11) sfx(3)
   else
    p.xp+=g.v sfx(7)
    if (p.xp>=nx()) lvup()
   end
  end
 end
end

-- ===== spawning =====
function spawnat(e)
 local a=rnd()
 e.x,e.y=p.x+cos(a)*80,p.y+sin(a)*80
end

function spawn(k)
 if (#en>=110 and k!="f" and k!="b") return
 local d=et[k]
 local e={k=k,hp=d[4]*(1+clock/4000),fl=0,hc=0}
 spawnat(e) add(en,e)
 return e
end

function spawner()
 local sec=clock/60
 local rate=max(4,30-sec\8)
 if clock%rate==0 then
  local k="c"
  local r=rnd()
  if (sec>60 and r<.3) k="d"
  if (sec>90 and r<.15) k="v"
  for i=1,1+sec\60 do spawn(k) end
 end
 -- timed events
 if sec>=120 and ev==0 then
  ev=1 msg("saucer ambush!")
  for i=0,7 do local e=spawn("s") if (e) e.x,e.y=p.x+cos(i/8)*70,p.y+sin(i/8)*70 end
 elseif sec>=180 and ev==1 then
  ev=2 spawn("b") msg("the hive mothership!") sfx(9)
 elseif sec>=300 and ev==2 then
  ev=3 spawn("f") msg("the hegemony flagship!") sfx(9) flash=6
 end
end

function msg(s) mtx,mt=s,150 end

-- ===== weapons =====
function nearest(r)
 local b,bd=nil,r
 for e in all(en) do
  local d=abs(e.x-p.x)+abs(e.y-p.y)
  if (d<bd) b,bd=e,d
 end
 return b
end

function hurt(e,d)
 e.hp-=d e.fl=3
 if (d>=3) pop(e.x,e.y-6,""..flr(d),10)
 if e.hp<=0 and not e.dead then
  e.dead=true del(en,e) kills+=1
  local k=et[e.k]
  explode(e.x,e.y,(e.k=="b" or e.k=="f") and 4 or 1)
  if e.k=="f" then st,t="win",0 sfx(8) flash=10 return end
  if (e.k=="b") for i=1,12 do add(gems,{x=e.x+rnd(20)-10,y=e.y+rnd(20)-10,v=10}) end
  add(gems,{x=e.x,y=e.y,v=k[7]})
  if (rnd()<.015) add(gems,{x=e.x+4,y=e.y,h=1})
  if #gems>140 then gems[2].v+=gems[1].v deli(gems,1) end
 end
end

function weapons()
 for i=1,5 do cd[i]-=1 end
 local pw=pow()
 -- 1 pulse blaster
 local l=wl[1]
 if l>0 and cd[1]<=0 then
  local e=nearest(90)
  if e then
   local a=atan2(e.x-p.x,e.y-p.y)
   for j=1,l\2+1 do
    local o=(j-(l\2+2)/2)*.03
    add(bul,{x=p.x,y=p.y,vx=cos(a+o)*3,vy=sin(a+o)*3,l=40,pr=l>=4 and 3 or 1})
   end
   cd[1]=(42-l*4)*cdm() sfx(0)
  end
 end
 for b in all(bul) do
  b.x+=b.vx b.y+=b.vy b.l-=1
  for e in all(en) do
   if b.l>0 and hit(b.x,b.y,2,e.x,e.y,et[e.k][6]) then
    hurt(e,1.2*pw) b.pr-=1 sparks(b.x,b.y,2,{7,12})
    if (b.pr<=0) b.l=0
   end
  end
  if (b.l<=0) del(bul,b)
 end
 -- 2 orbiters
 l=wl[2]
 if l>0 then
  for j=1,l do
   local a=t/90+j/l
   local x,y=p.x+cos(a)*(16+l*2),p.y+sin(a)*(16+l*2)
   for e in all(en) do
    if e.hc==0 and hit(x,y,4,e.x,e.y,et[e.k][6]) then hurt(e,.8*pw) e.hc=20 end
   end
  end
 end
 -- 3 nova
 l=wl[3]
 if l>0 and cd[3]<=0 then
  local r=22+l*8
  ring(p.x,p.y,4,r/8,12,16) ring(p.x,p.y,2,r/10,7,12)
  for e in all(en) do
   if (abs(e.x-p.x)+abs(e.y-p.y)<r) hurt(e,2*pw)
  end
  cd[3]=(200-l*18)*cdm() sfx(6) shake=2
 end
 -- 4 arc
 l=wl[4]
 if l>0 and cd[4]<=0 then
  local x,y,hitc=p.x,p.y,{}
  for j=1,l+1 do
   local b,bd=nil,50
   for e in all(en) do
    local d=abs(e.x-x)+abs(e.y-y)
    if (d<bd and not hitc[e]) b,bd=e,d
   end
   if (not b) break
   add(arcs,{x,y,b.x,b.y,8}) hitc[b]=true
   x,y=b.x,b.y hurt(b,2.5*pw)
  end
  cd[4]=(100-l*8)*cdm() sfx(5)
 end
 for a in all(arcs) do a[5]-=1 if (a[5]<=0) del(arcs,a) end
 -- 5 mine layer
 l=wl[5]
 if l>0 and cd[5]<=0 then
  add(mines,{x=p.x,y=p.y,l=600}) cd[5]=(90-l*8)*cdm()
 end
 for m in all(mines) do
  m.l-=1
  local boom=m.l<=0
  for e in all(en) do if (not boom and hit(m.x,m.y,4,e.x,e.y,et[e.k][6])) boom=true end
  if boom then
   del(mines,m) ring(m.x,m.y,2,2,10,12) explode(m.x,m.y,1)
   for e in all(en) do
    if (abs(e.x-m.x)+abs(e.y-m.y)<16+l*3) hurt(e,4*pw)
   end
  end
 end
end

-- ===== level up =====
function lvup()
 p.xp-=nx() p.lv+=1
 local c,own={},0
 for i=1,5 do if (wl[i]>0) own+=1 end
 for i=1,5 do
  if (wl[i]>0 and wl[i]<6 or wl[i]==0 and own<4) add(c,{1,i})
  if (pl[i]<5) add(c,{2,i})
 end
 offers={}
 for j=1,3 do
  if (#c>0) local o=rnd(c) del(c,o) add(offers,o)
 end
 if (#offers==0) p.hp=mhp() return
 st,oi,hold="lvup",1,true
 ring(p.x,p.y,2,3,10,20) sparks(p.x,p.y,20,{10,7,9}) sfx(8)
end

function updlvup()
 if hold then hold=btn(4) or btn(5) return end
 if (btnp(2)) oi=(oi-2)%#offers+1
 if (btnp(3)) oi=oi%#offers+1
 if btnp(4) then
  local o=offers[oi]
  if o[1]==1 then wl[o[2]]+=1 else pl[o[2]]+=1 end
  if (o[1]==2 and o[2]==3) p.hp+=2
  st="play"
  if (p.xp>=nx()) lvup()
 end
end

-- ===== draw =====
function _draw()
 cls(0)
 if st=="intro" then drawintro() return end
 local cx,cy=p.x-64+rnd(shake)-shake/2,p.y-64+rnd(shake)-shake/2
 camera(cx,cy)
 -- ground tiles (hashed pattern)
 for ty=flr(cy/8),flr(cy/8)+16 do for tx=flr(cx/8),flr(cx/8)+16 do
  local h=(tx*tx*13+ty*ty*7+tx*ty*3+tx*5)%23
  spr(h<19 and 132 or h<22 and 133 or 134,tx*8,ty*8)
 end end
 for g in all(gems) do
  if g.h then dspr("i_food",g.x,g.y,.8)
  else
   local c=g.v>=10 and 8 or g.v>=3 and 11 or 12
   line(g.x,g.y-2,g.x+1,g.y,c) line(g.x,g.y+1,g.x-1,g.y,c) pset(g.x,g.y,7)
  end
 end
 for m in all(mines) do circfill(m.x,m.y,1.5,m.l%20<10 and 8 or 9) end
 for e in all(en) do
  local d=et[e.k]
  if (e.fl>0) whiteout()
  dspr(t\8%2==0 and d[1] or d[2],e.x,e.y,d[3],e.fx)
  pal()
 end
 local l=wl[2]
 for j=1,l do
  local a=t/90+j/l
  local x,y=p.x+cos(a)*(16+l*2),p.y+sin(a)*(16+l*2)
  circfill(x,y,2,12) pset(x,y,7)
 end
 for b in all(bul) do line(b.x,b.y,b.x-b.vx,b.y-b.vy,12) pset(b.x,b.y,7) end
 for a in all(arcs) do
  local mx,my=(a[1]+a[3])/2+rnd(6)-3,(a[2]+a[4])/2+rnd(6)-3
  line(a[1],a[2],mx,my,12) line(mx,my,a[3],a[4],7)
 end
 if p.inv==0 or t%6<3 then
  ovalfill(p.x-3,p.y+3,p.x+3,p.y+5,1)
  dspr("i_colonist",p.x,p.y,1,p.f)
 end
 drawvfx()
 camera()
 drawhud()
 if (st=="lvup") drawlvup()
 if (st=="over" or st=="win") drawend()
 if flash>0 then fillp(0b0101101001011010.1) rectfill(0,0,127,127,7) fillp() end
end

function drawhud()
 rectfill(0,0,127,3,1)
 rectfill(0,0,127*min(p.xp/nx(),1),3,12)
 local s=(clock\3600)..":"..sub("0"..(clock\60%60),-2)
 oprint(s,64-#s*2,6,7)
 oprint("lv"..p.lv,2,6,10)
 oprint(kills,126-#tostr(kills)*4,6,6)
 rect(54,120,74,123,5)
 rectfill(55,121,55+max(0,p.hp)/mhp()*18,122,8)
 if mt and mt>0 then
  mt-=1 oprint(mtx,64-#mtx*2,20,t%20<10 and 8 or 10)
 end
end

function drawlvup()
 rectfill(8,24,119,104,0) rect(8,24,119,104,10)
 print("level up! choose one",24,28,10)
 for j,o in ipairs(offers) do
  local y=12+j*24
  local i,w=o[2],o[1]==1
  local lv=w and wl[i] or pl[i]
  if (j==oi) rectfill(10,y,117,y+21,1)
  dspr(w and wi[i] or pi[i],20,y+10,w and 1 or .8)
  print((w and wn[i] or pn[i]),30,y+3,j==oi and 10 or 7)
  print(lv==0 and "new!" or "lv"..lv.."->"..(lv+1),88,y+3,lv==0 and 11 or 9)
  print(w and wd[i] or pd[i],30,y+12,6)
 end
end

function drawintro()
 for i=1,40 do pset((i*37+t/(1+i%3))%128,(i*53)%128,i%3==0 and 7 or 13) end
 dspr("p_hive",64,34,3)
 print("\^w\^tswarmfall",28,62,8)
 oprint("the swarm never ends.",22,78,7)
 oprint("survive 5:00, then kill the",10,86,7)
 oprint("hegemony flagship.",28,94,9)
 if (t%40<28) oprint("z: drop in",44,108,11)
 oprint("arrows move  weapons auto-fire",4,120,6)
end

function drawend()
 rectfill(10,40,117,86,0) rect(10,40,117,86,st=="win" and 10 or 8)
 local s=st=="win" and "victory!" or "overrun"
 print("\^w\^t"..s,64-#s*4,45,st=="win" and 10 or 8)
 local s2="time "..(clock\3600)..":"..sub("0"..(clock\60%60),-2).."  kills "..kills.."  lv"..p.lv
 oprint(s2,64-#s2*2,62,7)
 if (t>60 and t%40<28) oprint("z: back to title",32,74,6)
end
