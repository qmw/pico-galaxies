-- grid_tactics_1 (demake)
-- planet bastion: 3 mechs defend the
-- colony grid. attacks are telegraphed.
-- see design.md

-- tiles: 0 ground 1 mountain 2 water 3 building 4 rubble
-- mechs: name,sprite,scale,weapon
md={}
for s in all(split("brawler,ship,.7,1|gunner,saa,.65,2|artillery,freighter,.7,3","|")) do add(md,split(s)) end
wdesc=split"punch: 2 dmg + push,shot: first hit 1 dmg + push,lob 2+ away: 1 dmg + push around"
-- bugs: name,sprite,scale,hp,damage,ranged
bd={}
for s in all(split("crawler,crawl_a,1,2,1,0|spitter,mine,.6,2,1,1|brute,ast,.75,4,3,0","|")) do add(bd,split(s)) end
dirs={{1,0},{-1,0},{0,1},{0,-1}}

function px(x) return 16+x*12 end
function py(y) return 16+y*12 end
function inb(x,y) return x>=0 and y>=0 and x<8 and y<8 end
function msg(s,c) mtx,mt,mc=s,90,c or 7 end
function uat(x,y)
 for u in all(us) do if (u.x==x and u.y==y) return u end
end

function _init()
 t,shake,flash=0,0,0
 parts,rings,fx,pops,lines={},{},{},{},{}
 st="intro" music(0)
end

function newgame()
 power,mission=7,0
 newmission()
end

function newmission()
 mission+=1 round=0 us,sps={},{}
 m={}
 for y=0,7 do m[y]={} for x=0,7 do m[y][x]=0 end end
 local function put(k,n,x0,x1)
  for i=1,n do
   for j=1,30 do
    local x,y=x0+flr(rnd(x1-x0+1)),flr(rnd(8))
    if (m[y][x]==0) m[y][x]=k break
   end
  end
 end
 put(3,6,0,3) put(1,4,1,6) put(2,3,2,6)
 for i=1,3 do
  for j=1,30 do
   local x,y=1+flr(rnd(3)),flr(rnd(8))
   if m[y][x]==0 and not uat(x,y) then add(us,{sd=1,k=i,x=x,y=y,hp=4,fl=0}) break end
  end
 end
 for i=1,1+mission do spawnbug() end
 st="play" msg("mission "..mission.."/3: protect the grid",10) sfx(8)
 startround()
end

function spawnbug(x,y)
 if not x then
  for j=1,30 do
   x,y=5+flr(rnd(3)),flr(rnd(8))
   if (m[y][x]==0 or m[y][x]==4) and not uat(x,y) then break end
   x=nil
  end
 end
 if (not x) return
 local k=rnd()<.2+mission*.08 and 3 or rnd()<.4 and 2 or 1
 local b={sd=2,k=k,x=x,y=y,hp=bd[k][4],fl=0}
 add(us,b) return b
end

-- ===== board rules =====
function walk(x,y) return inb(x,y) and (m[y][x]==0 or m[y][x]==4) and not uat(x,y) end

function reach(u,n)
 local r,q={},{{u.x,u.y,0}}
 r[u.y*8+u.x]=true
 while #q>0 do
  local c=deli(q,1)
  if c[3]<n then
   for d in all(dirs) do
    local x,y=c[1]+d[1],c[2]+d[2]
    if (walk(x,y) and not r[y*8+x]) r[y*8+x]=true add(q,{x,y,c[3]+1})
   end
  end
 end
 return r
end

function hurt(u,n)
 u.hp-=n u.fl=8
 pop(px(u.x)+6,py(u.y)-2,"-"..n,u.sd==1 and 8 or 10)
 sparks(px(u.x)+6,py(u.y)+6,5,{7,8,9})
 if u.hp<=0 then
  explode(px(u.x)+6,py(u.y)+6,u.sd==1 and 2 or 1) del(us,u)
  if (u.sd==1) msg(md[u.k][1].." destroyed!",8)
 end
end

function hitb(x,y)
 m[y][x]=4 power-=1 flash=4 shake=5
 explode(px(x)+6,py(y)+6,2) msg("building hit! power "..power,8)
 if (power<=0) over("the grid went dark")
end

-- damage whatever stands on x,y; optional push direction
function strike(x,y,n,dx,dy)
 if (not inb(x,y)) return
 local u=uat(x,y)
 if u then
  hurt(u,n)
  if (dx and u.hp>0) push(u,dx,dy)
 elseif m[y][x]==3 then hitb(x,y) end
end

function push(u,dx,dy)
 local x,y=u.x+dx,u.y+dy
 local o=inb(x,y) and uat(x,y)
 if not inb(x,y) or m[y][x]==1 or m[y][x]==3 or o or m[y][x]==2 and u.sd==1 then
  -- bump
  ring(px(u.x)+6+dx*6,py(u.y)+6+dy*6,1,1,9,8)
  hurt(u,1)
  if o then hurt(o,1) elseif inb(x,y) and m[y][x]==3 then hitb(x,y) end
  return
 end
 add(lines,{px(u.x)+6,py(u.y)+6,px(x)+6,py(y)+6,6,10})
 u.x,u.y=x,y
 if m[y][x]==2 then
  sparks(px(x)+6,py(y)+6,10,{12,7,1}) del(us,u) msg(bd[u.k][1].." drowned!",12)
 end
end

-- first blocker from x,y going d (exclusive); returns x,y of hit cell or nil
function trace(x,y,dx,dy)
 repeat
  x+=dx y+=dy
  if (not inb(x,y)) return
 until uat(x,y) or m[y][x]==1 or m[y][x]==3
 return x,y
end

-- ===== mech weapons =====
function canfire(u,x,y)
 local dx,dy=x-u.x,y-u.y
 if (dx!=0 and dy!=0 or dx==0 and dy==0) return false
 local d=abs(dx)+abs(dy)
 if (u.k==1) return d==1
 if (u.k==3) return d>=2
 return true
end

function fire(u,x,y)
 local dx,dy=sgn(x-u.x),sgn(y-u.y)
 if (x==u.x) dx=0
 if (y==u.y) dy=0
 if u.k==1 then
  add(lines,{px(u.x)+6,py(u.y)+6,px(x)+6,py(y)+6,7,6})
  strike(x,y,2,dx,dy) sfx(1)
 elseif u.k==2 then
  local hx,hy=trace(u.x,u.y,dx,dy)
  local ex,ey=hx or u.x+dx*8,hy or u.y+dy*8
  add(lines,{px(u.x)+6,py(u.y)+6,px(ex)+6,py(ey)+6,12,8})
  if (hx) strike(hx,hy,1,dx,dy)
  sfx(0)
 else
  add(lines,{px(u.x)+6,py(u.y)+6,px(x)+6,py(y)+6,9,10})
  ring(px(x)+6,py(y)+6,2,2,9,12)
  strike(x,y,1)
  for d in all(dirs) do
   local o=uat(x+d[1],y+d[2])
   if (o) push(o,d[1],d[2])
  end
  sfx(2)
 end
end

-- ===== enemy planning & resolution =====
-- what a bug at x,y hits facing d: returns cell x,y and a value (building 3, mech 2, bug -1)
function aim(b,x,y,d)
 local tx,ty
 if bd[b.k][6]==1 then tx,ty=trace(x,y,d[1],d[2])
 else tx,ty=x+d[1],y+d[2] end
 if (not tx or not inb(tx,ty)) return
 local o=uat(tx,ty)
 if (o==b) o=nil
 local v=m[ty][tx]==3 and 3 or o and (o.sd==1 and 2 or -1) or 0
 return tx,ty,v
end

function plan(b)
 local r=reach(b,b.k==1 and 3 or 2)
 local best,bv,bx,by=nil,-9,b.x,b.y
 for k,_ in pairs(r) do
  local x,y=k%8,k\8
  for d in all(dirs) do
   local tx,ty,v=aim(b,x,y,d)
   v=(v or 0)+rnd(.5)
   if (v>bv) best,bv,bx,by=d,v,x,y
  end
 end
 b.x,b.y,b.d=bx,by,best or dirs[2]
end

-- round start: bugs move one by one (animated), each revealing its attack as it arrives
function startround()
 round+=1 ph,sel,cx,cy,mq,mv_="emove",nil,2,3,{},nil
 sps={}
 for u in all(us) do
  u.done=false
  if (u.sd==2) u.d=nil add(mq,u)
 end
end

function emovestep()
 if mv_ then
  mv_.a+=1
  if (mv_.a<14) return
  mv_.b.d,mv_=mv_.d,nil
  sfx(7)
  return
 end
 local b=deli(mq,1)
 if not b then
  ph="player" spawnmarks() return
 end
 if (count(us,b)==0) return
 local fx,fy=b.x,b.y
 plan(b)
 mv_={b=b,fx=fx,fy=fy,a=fx==b.x and fy==b.y and 13 or 0,d=b.d}
 b.d=nil
end

function spawnmarks()
 for i=1,mission do
  for j=1,30 do
   local x,y=4+flr(rnd(4)),flr(rnd(8))
   if (m[y][x]==0 or m[y][x]==4) then add(sps,{x,y}) break end
  end
 end
end

function endturn()
 ph,eq,et="enemy",{},0
 for u in all(us) do if (u.sd==2) add(eq,u) end
 add(eq,"spawn")
end

function enemystep()
 local b=deli(eq,1)
 if b=="spawn" then
  for s in all(sps) do
   local o=uat(s[1],s[2])
   if o then hurt(o,1) msg("emergence blocked!",11)
   else
    local n=spawnbug(s[1],s[2])
    if (n) ring(px(s[1])+6,py(s[2])+6,2,1.5,11,10)
   end
  end
  if st!="play" then return end
  local mechs=0 for u in all(us) do if (u.sd==1) mechs+=1 end
  if (mechs==0) over("all mechs were destroyed") return
  if round>=5 then
   if mission==3 then st,t="win",0 flash=8 sfx(8)
   else newmission() end
  else startround() end
  return
 end
 if count(us,b)==0 then return end
 local tx,ty=aim(b,b.x,b.y,b.d)
 add(lines,{px(b.x)+6,py(b.y)+6,px(tx or b.x)+6,py(ty or b.y)+6,8,8})
 if (tx) strike(tx,ty,bd[b.k][5])
 sfx(5)
end

function over(s) st,why,t="over",s,0 music(-1) end

-- ===== update =====
function _update60()
 t+=1
 shake=max(0,shake-.4) flash=max(0,flash-1)
 if (mt and mt>0) mt-=1
 updvfx()
 for l in all(lines) do l[6]-=1 if (l[6]<=0) del(lines,l) end
 for u in all(us or {}) do if (u.fl>0) u.fl-=1 end
 if st=="play" then
  if ph=="enemy" then
   et-=1
   if (et<=0) et=24 enemystep()
  elseif ph=="emove" then emovestep()
  else updplayer() end
 elseif btnp(4) then
  if st=="intro" then newgame() else load("voidstorm.p8") end
 end
end

function updplayer()
 if (btnp(0)) cx=max(0,cx-1)
 if (btnp(1)) cx=min(7,cx+1)
 if (btnp(2)) cy=max(0,cy-1)
 if (btnp(3)) cy=min(7,cy+1)
 if btnp(5) then
  if mode=="aim" then sel.done=true sel,mode=nil
  elseif sel then sel,mode=nil
  else endturn() end
  return
 end
 if btnp(4) then
  if not sel then
   local u=uat(cx,cy)
   if u and u.sd==1 and not u.done then sel,mode,rch=u,"move",reach(u,3) sfx(7) end
  elseif mode=="move" then
   if rch[cy*8+cx] then sel.x,sel.y,mode=cx,cy,"aim" sfx(7)
   else msg("can't move there",8) end
  elseif mode=="aim" then
   if canfire(sel,cx,cy) then fire(sel,cx,cy) sel.done=true sel,mode=nil
   else msg("not a valid target",8) sfx(4) end
  end
 end
end

-- ===== draw =====
tsp={[0]="t_grass","t_rock","t_water","t_grass","t_grass"}
function _draw()
 cls(0)
 if st=="intro" then drawintro() return end
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
 for y=0,7 do for x=0,7 do
  local k=m[y][x]
  local s=sp[tsp[k]]
  if (k==4) pal(3,5) pal(11,5)
  sspr(s[1],s[2],8,8,px(x),py(y),12,12)
  pal()
  if (k==3) dspr((x+y)%2==0 and "b_hab" or "b_farm",px(x)+6,py(y)+6,1.2)
  if (k==2 and (t\12+x+y)%4==0) line(px(x)+2,py(y)+5,px(x)+6,py(y)+5,12)
 end end
 -- spawn cracks
 for s in all(sps) do
  local x,y=px(s[1])+6,py(s[2])+6
  line(x-3,y-3,x+3,y+3,t%20<10 and 8 or 2) line(x-3,y+3,x+3,y-3,t%20<10 and 8 or 2)
 end
 -- move range / aim targets
 if sel then
  for y=0,7 do for x=0,7 do
   if (mode=="move" and rch[y*8+x]) rect(px(x)+1,py(y)+1,px(x)+10,py(y)+10,12)
   if (mode=="aim" and canfire(sel,x,y)) rect(px(x)+1,py(y)+1,px(x)+10,py(y)+10,t%16<8 and 10 or 9)
  end end
 end
 -- telegraphs
 for b in all(us) do
  if b.sd==2 and b.d and st=="play" then
   local tx,ty=aim(b,b.x,b.y,b.d)
   if tx then
    line(px(b.x)+6,py(b.y)+6,px(tx)+6,py(ty)+6,2)
    rect(px(tx),py(ty),px(tx)+11,py(ty)+11,t%16<8 and 8 or 2)
   end
  end
 end
 for u in all(us) do
  local x,y=px(u.x)+6,py(u.y)+6
  if mv_ and mv_.b==u then
   local f=mv_.a/14
   x,y=px(mv_.fx)+6+(px(u.x)-px(mv_.fx))*f,py(mv_.fy)+6+(py(u.y)-py(mv_.fy))*f
  end
  if (u.fl>0) whiteout()
  if (u.sd==1 and u.done) pal(7,5) pal(6,5) pal(12,13)
  if u.sd==1 then dspr(md[u.k][2],x,y,md[u.k][3])
  else dspr(bd[u.k][2],x,y,bd[u.k][3],u.d and u.d[1]<0) end
  pal()
  for i=1,u.hp do pset(px(u.x)+i*2,py(u.y)+11,u.sd==1 and 11 or 8) end
 end
 for l in all(lines) do line(l[1],l[2],l[3],l[4],t%2==0 and l[5] or 7) end
 if (st=="play" and ph=="player") rect(px(cx)-1,py(cy)-1,px(cx)+12,py(cy)+12,t%20<10 and 7 or 10)
 drawvfx()
 camera()
 -- hud
 print("power",2,3,10)
 for i=1,7 do rectfill(24+i*6,2,28+i*6,7,i<=power and 10 or 1) end
 print("m"..mission.."/3 r"..round.."/5",86,3,6)
 rectfill(0,113,127,127,0)
 local u=sel or (uat(cx,cy))
 if u and u.sd==1 then
  print(md[u.k][1].." hp"..u.hp.."  "..wdesc[u.k],2,115,11)
 elseif u then
  print(bd[u.k][1].." hp"..u.hp.." dmg"..bd[u.k][5]..(bd[u.k][6]==1 and " ranged" or ""),2,115,8)
 end
 local h=ph=="emove" and "hive moving..." or ph=="enemy" and "hive attacks..." or mode=="move" and "z move  x cancel" or mode=="aim" and "z fire  x skip" or "z select mech  x end turn"
 print(h,2,121,ph=="enemy" and 8 or 6)
 if mt and mt>0 then
  local w=#mtx*2
  rectfill(62-w,9,65+w,15,0) print(mtx,64-w,10,mt%20<15 and mc or 7)
 end
 if (st=="over" or st=="win") drawend()
 if flash>0 then fillp(0b0101101001011010.1) rectfill(0,0,127,127,flash>3 and 7 or 8) fillp() end
end

function drawintro()
 for i=1,40 do pset((i*37+t/(1+i%3))%128,(i*53)%128,i%3==0 and 7 or 13) end
 dspr("p_ice",64,34,3)
 print("\^w\^tbastion",36,62,12)
 oprint("three mechs. one power grid.",8,78,7)
 oprint("read the red lines, push the",8,86,7)
 oprint("bugs into each other.",22,94,9)
 if (t%40<28) oprint("z: deploy",46,108,11)
end

function drawend()
 rectfill(8,40,119,84,0) rect(8,40,119,84,st=="win" and 10 or 8)
 local s=st=="win" and "victory!" or "defeat"
 print("\^w\^t"..s,64-#s*4,46,st=="win" and 10 or 8)
 local w=why or "bastion holds"
 oprint(w,64-#w*2,62,7)
 oprint("mission "..mission.."/3  power "..max(power,0),28,70,6)
 if (t>60 and t%40<28) oprint("z: back to title",32,77,6)
end
