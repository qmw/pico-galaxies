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
