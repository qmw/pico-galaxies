-- colonization_1 (demake)
-- planet nova terra: turn-based
-- colonize / trade / independence.
-- see design.md

mw,mh=24,20
tn=split"t_grass,t_rock,t_crystal,t_water,nest"
gi=split"i_food,i_ore,pow,i_guns,i_cells"
gn=split"food,ore,crystal,guns,cells"
exn=split"farmer,miner,cutter"
-- tile yields: good, amount
yg,ya=split"1,2,3,1,0",split"3,3,2,2,0"
-- buildings: name, sprite, input good, output good (0 = militia: +1 colony defense per worker)
bn=split"armory,refinery,watch hall"
bs=split"b_mine,b_harv,dome"
bin,bout=split"2,3,0",split"4,5,0"
base=split"1,2,4,7,12"

function sn(n) return sp[n][2]\8*16+sp[n][1]\8 end
function msg(s,c) mtx,mt,mc=s,120,c or 7 end
function tl(x,y) return x>=0 and y>=0 and x<mw and y<mh and m[y][x] or 4 end

function _init()
 cartdata("colonization_1")
 t,shake,flash,cw,cpx,cpy=0,0,0,0,0,0
 parts,rings,fx,pops={},{},{},{}
 cam={x=0,y=0}
 st="intro" music(0)
end

function newgame()
 m,seen={},{}
 for y=0,mh-1 do
  m[y],seen[y]={},{}
  local cx=15+flr(rnd(3))
  for x=0,mw-1 do m[y][x]=x>=cx and 4 or 1 end
 end
 for k in all(split"2,2,2,2,3,3,4,2,3") do
  local cx,cy,r=rnd(15),rnd(mh),1+rnd(2)
  for y=0,mh-1 do for x=0,mw-1 do
   if ((x-cx)^2+(y-cy)^2<r*r and m[y][x]!=4 or k==4 and (x-cx)^2+(y-cy)^2<r*r) m[y][x]=k
  end end
 end
 vil={}
 for i=1,7 do
  local x,y repeat x,y=flr(rnd(13)),flr(rnd(mh)) until m[y][x]<4
  m[y][x]=5
  add(vil,{x=x,y=y,ex=1+i%3,ang=0,hp=3})
 end
 cols,units,hw={},{},{}
 ship=unit("ship",20,9)
 ship.g={20,0,0,10,0}
 for k in all(split"c,c,s") do add(units,arm({k=k,x=20,y=9,on=ship,mv=0})) end
 cr,tax,turn=150,0,1
 pr,sold,cc={},{0,0,0,0,0},80
 for i=1,5 do pr[i]=base[i] end
 au,cam,cw=1,{x=10,y=4},0
 reveal(20,9,2)
 st="map" newturn()
 cpx,cpy=cam.x*8,cam.y*8
 msg("sail west and found a colony",10)
end

function unit(k,x,y)
 local u={k=k,x=x,y=y,mv=0}
 add(units,u) return u
end

function reveal(x,y,r)
 for j=-r,r do for i=-r,r do
  if (seen[y+j] and x+i>=0 and x+i<mw) seen[y+j][x+i]=true
 end end
end

function colat(x,y)
 for c in all(cols) do if (c.x==x and c.y==y) return c end
end


-- ===== turns =====
function newturn()
 for u in all(units) do
  u.mv=u.k=="ship" and 6 or 1
  if (u.k=="s" and (u.fort or colat(u.x,u.y))) u.hp=min(u.hp+1,2+u.lv)
  if (u.on or u.fort or u.tr) u.mv=0
 end
 nextunit()
end

function nextunit()
 for i=1,#units do
  local j=(au+i-1)%#units+1
  if units[j].mv>0 then au=j focus() return end
 end
 endturn()
end

-- map effects live in world pixels and pause the camera briefly so they are seen
function boom(x,y,sz) explode(x*8+4,y*8+4,sz) cw=40 end
function zap(x,y,cols) sparks(x*8+4,y*8+4,10,cols) cw=25 end

function focus()
 local u=units[au]
 cam.x,cam.y=mid(0,u.x-8,mw-16),mid(0,u.y-7,mh-14)
end

function endturn()
 turn+=1
 for c in all(cols) do produce(c) end
 for u in all(units) do
  if u.tr then
   u.tr-=1
   if u.tr==0 then
    u.tr=nil
    voyage(u.dir)
   end
  end
 end
 hives()
 if (#cols==0 and turn>8) over("every colony has fallen")
 if (turn>150) over("the hives outlasted you")
 newturn()
end

-- per-turn net change of each good (+ liberty) for colony c.
-- used for both the colony-screen preview and end-of-turn production.
function yields(c)
 local d,g,lb,wa={2,1,0,0,0},c.g,1+#c.w\3,{0,0,0,0,0}
 for w in all(c.w) do
  if w.j<9 then
   local k=tl(c.x+dx8[w.j],c.y+dy8[w.j])
   local gd=yg[k]
   if (gd>0) d[gd]+=ya[k]*(w.ex==gd and 2 or 1)
  end
 end
 for w in all(c.w) do
  local b=w.j-8
  if b>0 then
   if bout[b]==0 then lb+=1
   else
    local n=min(g[bin[b]]+d[bin[b]],3)
    d[bin[b]]-=n d[bout[b]]+=n
    wa[bin[b]]-=3-n wa[bout[b]]+=3-n
   end
  end
 end
 d[1]-=#c.w*2
 for i=1,5 do wa[i]+=d[i] end
 return d,lb,wa
end

function produce(c)
 local g=c.g
 local d=yields(c)
 for i=1,5 do g[i]+=d[i] end
 if g[1]<0 then
  g[1]=0
  if (#c.w>1) deli(c.w,#c.w) msg(c.n..": a colonist starved",8)
 elseif g[1]>=20 then
  g[1]-=20 unit("c",c.x,c.y) msg(c.n..": a colonist is born",11)
 end
 for i=1,5 do g[i]=min(g[i],200) end
end

-- hive villages grow angry near colonies and send warriors that roam,
-- hunt your units and raid colonies. win = every village destroyed.
function hives()
 for v in all(vil) do
  local near=false
  for c in all(cols) do
   if (abs(c.x-v.x)<=4 and abs(c.y-v.y)<=4) near=true
  end
  v.ang=near and v.ang+1 or max(0,v.ang-1)
  local n=0 for w in all(hw) do if (w.v==v) n+=1 end
  if n<(v.ang>10 and 2 or 1) and rnd()<.04+min(v.ang,10)*.015 then
   for j=1,8 do
    local x,y=v.x+dx8[j],v.y+dy8[j]
    if tl(x,y)<4 and not at(x,y) then add(hw,{x=x,y=y,v=v}) break end
   end
  end
 end
 for w in all(hw) do
  -- chase the nearest colony or land unit within 7 tiles, else wander
  local tg,bd=nil,8
  for o in all(cols) do if (dist(o,w)<bd) tg,bd=o,dist(o,w) end
  for o in all(units) do if (o.k!="ship" and not o.on and dist(o,w)<bd) tg,bd=o,dist(o,w) end
  local dx,dy=rnd{-1,0,1},rnd{-1,0,1}
  if (tg) dx,dy=sgn(tg.x-w.x)*(tg.x!=w.x and 1 or 0),sgn(tg.y-w.y)*(tg.y!=w.y and 1 or 0)
  local x,y=w.x+dx,w.y+dy
  local c,u=colat(x,y),at(x,y)
  if c then raid(w,c)
  elseif u then
   if fight(wstr(),str(u)) then lose(u)
   else del(hw,w) boom(w.x,w.y,1) msg("hive warrior slain",11) gainxp(u) end
  elseif tl(x,y)<4 then w.x,w.y=x,y end
 end
end

function raid(w,c)
 del(hw,w)
 local d=defender(c)
 local _,mil=yields(c)
 if fight(wstr(),d and str(d) or mil) then
  if (d) lose(d) return
  zap(c.x,c.y,{8,9})
  local k=flr(rnd(3))+1 c.g[k]\=2
  msg("hives raided "..c.n..": "..gn[k].." stolen",8) shake=6
  if rnd()<.5 then
   deli(c.w,#c.w) msg("hives raided "..c.n..": a colonist died",8)
   if (#c.w==0) del(cols,c) msg(c.n.." was overrun!",8)
  end
 else boom(w.x,w.y,1) msg("hive raid on "..c.n.." repelled",11) if (d) gainxp(d) end
end

function wstr() return 1.5+turn/40 end

-- a beaten soldier loses its guns; a beaten colonist dies
function lose(u)
 boom(u.x,u.y,1)
 if u.k=="s" then
  u.hp-=1
  if u.hp>0 then msg("soldier wounded: hp "..u.hp.."/"..(2+u.lv),8) return end
  u.k,u.fort="c",nil msg("your soldier was beaten and disarmed",8)
 else del(units,u) msg("a colonist was killed",8) end
end
function dist(a,b) return abs(a.x-b.x)+abs(a.y-b.y) end
function at(x,y)
 for o in all(units) do if (o.k!="ship" and not o.on and o.x==x and o.y==y) return o end
end

function defender(c)
 for u in all(units) do if (u.k=="s" and u.x==c.x and u.y==c.y and not u.on) return u end
end

function str(u) return (u.k=="s" and 1.5+u.lv*.5 or 1)*((u.fort or colat(u.x,u.y)) and 1.5 or 1) end

-- soldiers: lv, hp (max 2+lv), xp. level up every lv*2 xp: +.5 str, +1 max hp, full heal
function arm(u)
 if (u.k=="s") u.lv,u.hp,u.xp=1,3,0
 return u
end
function gainxp(u)
 if (u.k!="s") return
 u.xp+=1
 if u.xp>=u.lv*2 then
  u.lv+=1 u.xp=0 u.hp=2+u.lv
  zap(u.x,u.y,{10,7,9}) msg("soldier reached level "..u.lv.."!",10) sfx(8)
 end
end
function fight(a,d) shake=4 sfx(2) return rnd(a+d)<a end

function over(s) st,why,t="over",s,0 music(-1) end

-- ===== map input =====
dx8=split"-1,0,1,-1,1,-1,0,1"
dy8=split"-1,-1,-1,0,0,1,1,1"

function _update60()
 t+=1
 shake=max(0,shake-.4) flash=max(0,flash-1)
 if (mt and mt>0) mt-=1
 updvfx()
 if cw>0 then cw-=1
 else
  cpx+=(cam.x*8-cpx)*.25 cpy+=(cam.y*8-cpy)*.25
 end
 if st=="map" then updmap()
 elseif st=="menu" then updmenu()
 elseif st=="colony" then updcol()
 elseif st=="aurum" then updaurum()
 elseif st=="voy" then updvoy()
 elseif btnp(4) then
  if st=="intro" then newgame() else load("voidstorm.p8") end
 end
end

function updmap()
 if (cw>0) return
 local u=units[au]
 if (not u or u.mv<=0) nextunit() return
 if btnp(5) then
  -- x: next unit; if no other unit can move, skip this one (may end the turn)
  local other=false
  for o in all(units) do if (o!=u and o.mv>0) other=true end
  if (not other) u.mv=0
  nextunit() sfx(7) return
 end
 if btnp(4) then openmenu(u) return end
 for b=0,3 do
  if btnp(b) then
   local dx,dy=({-1,1,0,0})[b+1],({0,0,-1,1})[b+1]
   move(u,u.x+dx,u.y+dy)
   return
  end
 end
end

function move(u,x,y)
 local k=tl(x,y)
 local c=colat(x,y)
 if u.k=="ship" then
  if x>u.x and x>=mw-2 and k==4 then
   u.tr,u.dir,u.mv=2,1,0 sfx(6)
   msg("sailing to aurum (2 turns)",12) nextunit() return
  end
  if (k!=4 and not c) return
 else
  if k==4 then
   if ship.x==x and ship.y==y and not ship.tr then u.on,u.x,u.y=ship,x,y u.mv=0 msg("boarded the ship") nextunit() end
   return
  end
  for w in all(hw) do
   if w.x==x and w.y==y then
    if fight(str(u),wstr()) then del(hw,w) msg("hive warrior slain!",11) boom(x,y,1) gainxp(u)
    else lose(u) end
    u.mv=0 nextunit() return
   end
  end
  if k==5 then
   local v for o in all(vil) do if (o.x==x and o.y==y) v=o end
   if (not v) return
   if u.k=="s" then
    if fight(str(u),wstr()) then
     v.hp-=1 zap(x,y,{11,3}) msg("hive hit! "..v.hp.." left",11) gainxp(u)
     if v.hp<=0 then
      del(vil,v) m[y][x]=1 cr+=100 boom(x,y,2)
      msg("hive destroyed! +100cr. "..#vil.." left",11)
      for o in all(vil) do o.ang+=3 end
      if (#vil==0) st,t="win",0 sfx(8)
     end
    else lose(u) end
   elseif v.ex>0 and not u.ex then
    u.ex,v.ex=v.ex,0 msg("trained as expert "..exn[u.ex],11) sfx(3)
   else msg("the hives have nothing to teach") end
   u.mv=0 nextunit() return
  end
 end
 u.x,u.y,u.fort=x,y,nil
 u.mv-=1
 for o in all(units) do if (o.on==u) o.x,o.y=x,y end
 if c and u.k=="ship" then
  for o in all(units) do if (o.on==u) o.on=nil o.mv=0 end
 end
 reveal(x,y,u.k=="ship" and 2 or 1)
 focus()
 if (u.mv<=0) nextunit()
end

-- ===== order menu =====
function openmenu(u)
 local c=colat(u.x,u.y)
 opts={}
 local function o(s,f) add(opts,{s,f}) end
 if u.k=="ship" then
  local has=false
  for v in all(units) do if (v.on==u) has=true end
  if has and not c then
   o("unload units",function()
    for j=1,8 do
     local x,y=u.x+dx8[j],u.y+dy8[j]
     if tl(x,y)<4 then
      for v in all(units) do if (v.on==u) v.on,v.x,v.y,v.mv=nil,x,y,0 end
      reveal(x,y,1) msg("units landed") return
     end
    end
    msg("no land next to the ship",8)
   end)
  end
  if (c) o("cargo & colony",function() opencol(c) end)
 else
  if not c and u.k=="c" then
   local ok=true
   for d in all(cols) do if (abs(d.x-u.x)<2 and abs(d.y-u.y)<2) ok=false end
   if (ok) o("found colony",function() found(u) end)
  end
  if c then
   o("join colony",function() add(c.w,{j=9,ex=u.ex}) autojob(c,c.w[#c.w]) del(units,u) msg("joined "..c.n) end)
   if (u.k=="c" and c.g[4]>=20) o("arm soldier (20 guns)",function() c.g[4]-=20 u.k="s" arm(u) msg("soldier armed",11) end)
   if (ship.x==u.x and ship.y==u.y and not ship.tr) o("board ship",function() u.on=ship end)
   o("open colony",function() opencol(c) end)
  end
  if (u.k=="s") o("fortify",function() u.fort=true end)
 end
 if (#cols>0) o("view colonies",function() opencol(cols[1]) end)
 o("skip unit",function() end)
 o("end turn",function() for v in all(units) do v.mv=0 end end)
 st,mi="menu",1
end

function updmenu()
 if (btnp(2)) mi=(mi-2)%#opts+1
 if (btnp(3)) mi=mi%#opts+1
 if (btnp(5)) st="map" return
 if btnp(4) then
  st="map"
  local u=units[au]
  opts[mi][2]()
  if (st=="map" and u) u.mv=0
  if (st=="map") nextunit()
 end
end

names=split"new hope,fairhaven,ironhill,starfall,greenreach,last light,dawnport,cobalt"
function found(u)
 local c={x=u.x,y=u.y,n=names[#cols+1] or "colony",g={0,0,0,0,0},w={}}
 add(cols,c) del(units,u)
 add(c.w,{j=9,ex=u.ex}) autojob(c,c.w[1])
 reveal(c.x,c.y,2)
 zap(c.x,c.y,{7,10,11}) sfx(3)
 msg(c.n.." founded!",11)
end

-- best free tile for a new worker (expert's trade first, then food)
function autojob(c,w)
 local best,bv=9,-1
 for j=1,8 do
  local k=tl(c.x+dx8[j],c.y+dy8[j])
  local v=ya[k]+(yg[k]==w.ex and 5 or 0)+(yg[k]==1 and 1 or 0)
  if (yg[k]>0 and not taken(c,j) and v>bv) best,bv=j,v
 end
 w.j=best
end
function taken(c,j)
 for w in all(c.w) do if (w.j==j) return true end
end

-- ===== colony screen =====
function opencol(c)
 cur,st,ci,held=c,"colony",1,nil
end

-- slots: 1-8 tiles, 9-11 buildings, 12 ship cargo row
-- screen position of colony-screen slot i
-- 1-8 tile ring, 9-11 buildings, 12 cargo, 13 next colony
function slotxy(i)
 if i<9 then
  local j=i<=4 and i-1 or i
  return 16+j%3*18,48+j\3*18
 end
 if (i<12) return 95,48+(i-9)*18
 if (i==12) return 48,100
 return 112,8
end

-- move the cursor to the nearest slot in direction dx,dy
function navcol(dx,dy)
 local x,y=slotxy(ci)
 local best,bd=ci,999
 for i=1,13 do
  local a,b=slotxy(i)
  a-=x b-=y
  local d=abs(a)+abs(b)+abs(a*dy+b*dx)*2
  if (a*dx+b*dy>0 and d<bd) best,bd=i,d
 end
 ci=best
end

function updcol()
 local c=cur
 if btnp(5) then
  if held then held=nil else st="map" end
  return
 end
 for b=0,3 do
  if (btnp(b)) navcol(({-1,1,0,0})[b+1],({0,0,-1,1})[b+1])
 end
 if btnp(4) then
  if ci==13 then
   local i=1 for k=1,#cols do if (cols[k]==c) i=k end
   cur,held=cols[i%#cols+1],nil sfx(7) return
  end
  if ci==12 then
   if (ship.x==c.x and ship.y==c.y and not ship.tr) swapcargo(c)
   return
  end
  if held then
   if ci>8 or not taken(c,ci) then held.j=ci held=nil sfx(7) end
  else
   for w in all(c.w) do if (w.j==ci) held=w sfx(7) end
  end
 end
end

-- move goods: unload everything, then load all manufactured goods + surplus raw
function swapcargo(c)
 for i=1,5 do c.g[i]+=ship.g[i] ship.g[i]=0 end
 local room=100
 for i=5,2,-1 do
  local n=min(c.g[i],room)
  ship.g[i]+=n c.g[i]-=n room-=n
 end
 msg("cargo loaded: "..(100-room).." units",11) sfx(3)
end

-- ===== aurum =====
function updaurum()
 if hold0 then hold0=btn(4) or btn(5) return end
 if (btnp(2)) mi=(mi-2)%8+1
 if (btnp(3)) mi=mi%8+1
 if btnp(4) then
  if mi<=5 then
   local n=ship.g[mi]
   if (n==0) mkm="nothing to sell" return
   local inc=0
   for u=1,n do
    inc+=pr[mi] sold[mi]+=1
    if (sold[mi]%10==0) pr[mi]=max(1,pr[mi]-1)
   end
   ship.g[mi]=0
   local tx=inc*tax\100
   cr+=inc-tx sfx(3)
   mkm="sold "..n.." "..gn[mi].." for "..(inc-tx).."cr"
   if (inc>30 and tax<60 and rnd()<.5) tax+=5 mkm..=" tax now "..tax.."%"
  elseif mi==6 then
   if (cr<40) mkm="not enough credits" return
   cr-=40 ship.g[4]+=20 mkm="bought 20 guns" sfx(3)
  elseif mi==7 then
   local n=0 for u in all(units) do if (u.on==ship) n+=1 end
   if (n>=2) mkm="the ship is full" return
   if (cr<cc) mkm="not enough credits" return
   cr-=cc cc+=20
   add(units,{k="c",x=ship.x,y=ship.y,on=ship,mv=0}) mkm="colonist recruited" sfx(3)
  else
   ship.tr,ship.dir=2,-1 st="map"
   for i=1,5 do pr[i]=min(pr[i]+1,base[i]) end
   msg("sailing home (2 turns)",12) nextunit()
  end
 end
end

-- ===== arcade flight between nova terra and aurum =====
function voyage(d)
 st,vt,vdir,vo,vb="voy",0,d,{},{}
 p={x=64,y=100,vx=0,vy=0,inv=60,cd=0,bank=0}
 sfx(6)
end

function updvoy()
 vt+=1
 local dx,dy=0,0
 if (btn(0)) dx=-1
 if (btn(1)) dx=1
 if (btn(2)) dy=-1
 if (btn(3)) dy=1
 p.vx+=(dx*1.6-p.vx)*.25 p.vy+=(dy*1.6-p.vy)*.25
 p.x,p.y=mid(6,p.x+p.vx,121),mid(20,p.y+p.vy,118)
 p.bank+=(dx-p.bank)*.2
 if (p.inv>0) p.inv-=1
 p.cd-=1
 if btn(4) and p.cd<=0 then
  add(vb,{x=p.x-3,y=p.y-6}) add(vb,{x=p.x+3,y=p.y-6})
  p.cd=7 sfx(0)
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
    if (o.hp<=0) explode(o.x,o.y,1) del(vo,o)
   end
  end
  if (b and b.y<-4) del(vb,b)
 end
 if vt>=1250 then
  if vdir==1 then st,mi,mkm,hold0="aurum",1,"welcome to aurum",true
  else
   -- land just west of the space lanes, on the sea tile nearest row 9
   local by,bd=9,99
   for y=0,mh-1 do
    if (tl(mw-3,y)==4 and abs(y-9)<bd) by,bd=y,abs(y-9)
   end
   st,ship.x,ship.y="map",mw-3,by
   reveal(ship.x,ship.y,2) focus()
   msg("your ship has returned",11)
  end
 end
end

-- a hit costs 10 of the biggest cargo, or a colonist aboard on the way home
function vhit()
 p.inv=60 shake=5 sfx(4)
 sparks(p.x,p.y,10,{9,10,4})
 local k,n=1,0
 for i=1,5 do if (ship.g[i]>n) k,n=i,ship.g[i] end
 for u in all(units) do
  if vdir<0 and u.on==ship and rnd()<.5 then del(units,u) msg("a colonist was lost!",8) return end
 end
 if n>0 then
  ship.g[k]-=min(10,n) msg("cargo lost: -10 "..gn[k],8)
 else msg("hull hit!",8) end
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
 local s=vdir==1 and "to aurum" or "home to nova terra"
 oprint(s,64-#s*2,3,10)
 rect(20,10,107,13,5)
 rectfill(21,11,21+vt/1250*85,12,11)
 local n=0 for i=1,5 do n+=ship.g[i] end
 oprint(n.." cargo",2,121,7)
end

-- ===== draw =====
function _draw()
 cls(0)
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
 if st=="intro" then drawintro()
 elseif st=="colony" then drawcol()
 elseif st=="aurum" then drawaurum()
 elseif st=="voy" then drawvoy()
 else
  drawmap()
  if (st=="menu") drawmenu()
  if (st=="over" or st=="win") drawend()
 end
 camera()
 if (st=="voy") drawvfx()
 if mt and mt>0 and st!="colony" then
  local w=#mtx*2
  rectfill(62-w,113,65+w,120,0)
  print(mtx,64-w,114,mt%20<15 and mc or 7)
 end
 if flash>0 then
  fillp(0b0101101001011010.1) rectfill(0,0,127,127,8) fillp()
 end
end

function drawmap()
 local ox,oy=cpx\8,cpy\8
 camera(cpx+rnd(shake)-shake/2,cpy+rnd(shake)-shake/2)
 for my=oy,oy+14 do for mx=ox,ox+16 do
  if seen[my] and seen[my][mx] then
   local k=m[my][mx]
   spr(sn(tn[k]),mx*8,my*8)
   if (k==4 and (t\20+mx*3+my)%5==0) pset(mx*8+(mx*5)%6+1,my*8+(my*3)%6+1,12)
  end
 end end
 -- space lanes to aurum: the 2 eastmost columns
 local bx=(mw-2)*8
 fillp(0b0111111111011111.1) rectfill(bx,cpy,bx+15,cpy+111,13) fillp()
 for y=0,111,8 do pset(bx,cpy+y+t\6%8,13) end
 for y=8,104,32 do print("\^:0103070301000000",bx+4+t\10%3,cpy+y,13) end
 for c in all(cols) do
  local x,y=c.x*8,c.y*8
  dspr("dome",x+4,y+4)
  if (#c.w>0) print(#c.w,x+5,y-1,7)
 end
 for v in all(vil) do
  if (v.ang>=6 and seen[v.y][v.x] and t%30<15) print("!",v.x*8+3,v.y*8-6,8)
 end
 for w in all(hw) do
  if seen[w.y][w.x] then
   -- red palette so warriors stand out on green plains
   pal(11,8) pal(3,2) pal(10,9)
   dspr(t\8%2==0 and "crawl_a" or "crawl_b",w.x*8+4,w.y*8+4)
   pal()
  end
 end
 for i,u in ipairs(units) do
  if not u.on and not u.tr then
   local x,y=u.x*8+4,u.y*8+4
   local a=i==au and st=="map"
   if (a) y+=sin(t/40)*1
   if u.k=="ship" then dspr("freighter",x,y,.5)
   else
    if (u.k=="s") pal(12,8) pal(1,2)
    dspr("i_colonist",x,y)
    pal()
    if (u.ex) pset(x+3,y-3,10)
    if u.k=="s" then
     print(u.lv,x-6,y-4,10)
     for i=1,2+u.lv do pset(x-4+i*2,y+5,i<=u.hp and 11 or 8) end
    end
    if (u.fort) rect(x-4,y-4,x+3,y+3,13)
   end
   if (a and cw<=0) rect(x-5,y-5,x+4,y+4,t%20<10 and 10 or 7)
  end
 end
 drawvfx()
 camera()
 -- hud
 rectfill(0,112,127,127,0)
 local u=units[au]
 local s=u and (u.k=="ship" and "ship" or u.k=="s" and "soldier" or u.ex and exn[u.ex] or "colonist")..(u and u.mv and " mv"..u.mv or "") or ""
 if (u and u.k=="ship") s..=" cargo "..(ship.g[1]+ship.g[2]+ship.g[3]+ship.g[4]+ship.g[5])
 if (u and u.k=="s") s..=" lv"..u.lv.." hp"..u.hp.."/"..(2+u.lv).." xp"..u.xp.."/"..u.lv*2
 if (not (mt and mt>0)) print(s,2,114,7)
 print("t"..turn,2,121,6)
 dspr("i_coin",22,123) print(cr,27,121,10)
 print("hives "..#vil,48,121,11)
 print("tax "..tax.."%",80,121,8)
 if (ship.tr) print(ship.dir==1 and ">aur" or "<home",108,114,12)
end

function drawmenu()
 local h=#opts*8+6
 rectfill(30,10,125,10+h,0) rect(30,10,125,10+h,12)
 for i,o in ipairs(opts) do
  if (i==mi) rectfill(31,10+i*8-5,124,10+i*8+1,1)
  print(o[1],34,10+i*8-4,i==mi and 10 or 7)
 end
end

function drawcol()
 local c=cur
 rectfill(0,0,127,127,1)
 print("\^w\^t"..c.n,3,3,10)
 local d,lb,wa=yields(c)
 print(#c.w.." colonists  defense "..lb,3,15,6)
 rectfill(100,4,124,12,ci==13 and 10 or 0)
 print("next>",103,6,ci==13 and 0 or 7)
 for i=1,5 do
  local x=6+(i-1)*25
  dspr(gi[i],x,28)
  print(c.g[i],x+5,24,7)
  -- yellow = a building wants this but lacks input (shows the intended amount)
  local v=wa[i]
  print((v>=0 and "+" or "")..v,x+5,31,v!=d[i] and 10 or v>0 and 11 or v<0 and 8 or 5)
 end
 -- tile ring
 for j=0,8 do
  local x,y=8+j%3*18,40+j\3*18
  local k=j==4 and 0 or (j<4 and j+1 or j)
  local tk=tl(c.x+j%3-1,c.y+j\3-1)
  sspr(sp[tn[tk]][1],sp[tn[tk]][2],8,8,x,y,16,16)
  if k==0 then dspr("dome",x+8,y+8,1.5)
  else
   local y_=ya[tk]
   for w in all(c.w) do
    if w.j==k then
     dspr("i_colonist",x+8,y+8)
     if (w.ex) pset(x+12,y+4,10)
     if (w.ex==yg[tk]) y_*=2
    end
   end
   if (yg[tk]>0) print(y_,x+1,y+1,taken(c,k) and 11 or 6)
   if (ci==k) rect(x-1,y-1,x+16,y+16,held and 11 or 10)
  end
 end
 -- buildings
 for b=1,3 do
  local y=40+(b-1)*18
  local s=b+8
  rectfill(66,y,124,y+15,0)
  dspr(bs[b],74,y+8)
  print(bn[b],82,y+2,7)
  local n=0 for w in all(c.w) do if (w.j==s) n+=1 end
  for i=1,n do dspr("i_colonist",80+i*9,y+11,.7) end
  if (ci==s) rect(65,y-1,125,y+16,held and 11 or 10)
 end
 local sh=ship.x==c.x and ship.y==c.y and not ship.tr
 print(sh and "swap cargo with ship" or "no ship docked",8,98,sh and 7 or 5)
 if (ci==12) rect(6,96,90,104,10)
 print(held and "z place worker  x cancel" or "z pick worker  x back",4,108,11)
 -- growth: 20 stored food = new colonist
 local f=d[1]
 if f<0 then
  print("starving! "..f.." food/turn",4,118,t%20<10 and 8 or 2)
 else
  print("growth",4,118,6)
  rect(30,118,71,122,5)
  rectfill(31,119,31+min(c.g[1],20)*2,121,11)
  print(f>0 and ceil((20-c.g[1])/f).." turns" or "never",76,118,f>0 and 11 or 5)
 end
end

function drawaurum()
 rectfill(0,0,127,127,1)
 dspr("pla",106,16,1.2)
 print("\^w\^taurum",4,4,10)
 print("credits "..cr.."  tax "..tax.."%",4,18,7)
 local rows={}
 for i=1,5 do add(rows,{"sell "..ship.g[i].." "..gn[i],pr[i].."/u",gi[i]}) end
 add(rows,{"buy 20 guns","40",gi[4]})
 add(rows,{"recruit colonist",""..cc,"i_colonist"})
 add(rows,{"sail home","","freighter"})
 for i,r in ipairs(rows) do
  local y=24+i*10
  if (i==mi) rectfill(2,y-2,125,y+7,0)
  dspr(r[3],8,y+2,r[3]=="freighter" and .5 or 1)
  print(r[1],16,y,i==mi and 10 or 7)
  print(r[2],104,y,9)
 end
 print(mkm or "",4,118,11)
end

function drawintro()
 for i=1,40 do pset((i*37+t/(1+i%3))%128,(i*53)%128,i%3==0 and 7 or 13) end
 dspr("p_lush",64,36,3)
 print("\^w\^tnova terra",24,64,11)
 oprint("found colonies, refine goods,",8,80,7)
 oprint("trade at aurum, arm soldiers",8,87,7)
 oprint("and wipe out the alien hives.",6,94,9)
 if (t%40<28) oprint("z: begin",48,108,11)
 oprint("arrows move  z orders  x next",4,120,6)
end

function drawend()
 rectfill(8,40,119,84,0) rect(8,40,119,84,st=="win" and 10 or 8)
 local s=st=="win" and "victory!" or "defeat"
 print("\^w\^t"..s,64-#s*4,46,st=="win" and 10 or 8)
 local w=why or "the hives are gone"
 oprint(w,64-#w*2,62,7)
 oprint("turn "..turn,52,70,6)
 if (t>60 and t%40<28) oprint("z: back to title",32,77,6)
end
