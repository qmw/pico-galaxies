-- hex_territory_1 (demake)
-- planet shardmere: hex provinces,
-- towers, knights, upkeep and trees.
-- see design.md

fcol=split"12,8,10,11"
fdark=split"1,2,9,3"
fname=split"you,red,yellow,green"
upk=split"2,6,18,54"
usp=split"i_colonist,i_colonist,dra,saa"
usc=split"1,1,.5,.55"

function hx(x,y) return 6+x*11+(y%2)*5.5 end
function hy(y) return 18+y*10 end
function msg(s,c) mtx,mt,mc=s,100,c or 7 end
function hex(x,y) return x>=0 and y>=0 and x<11 and y<9 and h[y][x] or nil end

function nbs(z)
 local l,o={},z.y%2==0 and -1 or 0
 for d in all({{-1,0},{1,0},{o,-1},{o+1,-1},{o,1},{o+1,1}}) do
  local n=hex(z.x+d[1],z.y+d[2])
  if (n and n.l) add(l,n)
 end
 return l
end

function _init()
 t,shake,flash=0,0,0
 parts,rings,fx,pops={},{},{},{}
 st="intro" music(0)
end

function newgame()
 h={}
 for y=0,8 do
  h[y]={}
  for x=0,10 do
   local l=((x-5)^2/34+(y-4)^2/22)<1+rnd(.35)
   h[y][x]={x=x,y=y,l=l,o=l and 1+flr(rnd(4)) or 0,u=0,tr=l and rnd()<.12,g=0}
  end
 end
 recalc()
 for f=1,4 do for p in all(provs[f]) do if (p.cap) p.cap.g=8 end end
 turn,cx,cy,hand=0,5,4,nil
 startturn(1)
end

-- ===== provinces =====
function recalc()
 provs={{},{},{},{}}
 local seen={}
 for y=0,8 do for x=0,10 do
  local z=h[y][x]
  if z.l and not seen[z] then
   local p={hx={},f=z.o}
   local q={z} seen[z]=true
   while #q>0 do
    local c=deli(q,1) add(p.hx,c) c.p=p
    for n in all(nbs(c)) do
     if (n.o==z.o and not seen[n]) seen[n]=true add(q,n)
    end
   end
   add(provs[z.o],p)
   -- exactly one capital per province of 2+ hexes
   local gold,cap=0,nil
   for c in all(p.hx) do
    if c.cap then gold+=c.g c.cap=false if (not cap) cap=c end
   end
   if #p.hx>=2 then
    if not cap then
     for c in all(p.hx) do if (c.u==0 and not c.tw and not cap) cap=c end
     cap=cap or p.hx[1]
     cap.u,cap.tr=0,false
    end
    cap.cap,cap.g=true,gold p.cap=cap
   end
  end
 end end
end

function income(p)
 local i,u=0,0
 for c in all(p.hx) do
  if (not c.tr and not c.gr) i+=1
  if (c.u>0) u+=upk[c.u]
 end
 return i,u
end

function defense(z)
 local function dv(c) return max(c.u,c.tw and 2 or c.cap and 1 or 0) end
 local d=dv(z)
 for n in all(nbs(z)) do if (n.o==z.o) d=max(d,dv(n)) end
 return d
end

function grave(c) c.u,c.gr=0,true end

-- economy at the start of faction f's turn
function startturn(f)
 cur=f recalc()
 if f==1 then
  turn+=1
  for y=0,8 do for x=0,10 do
   local c=h[y][x]
   if c.l then
    if (c.gr) c.gr,c.tr=false,true
    if c.tr and rnd()<.12 then
     local n=rnd(nbs(c))
     if (n and n.u==0 and not n.cap and not n.tw and not n.tr) n.tr=true sparks(hx(n.x,n.y),hy(n.y),3,{11,3})
    end
   end
  end end
 end
 for p in all(provs[f]) do
  for c in all(p.hx) do c.mv=false end
  if p.cap then
   local i,u=income(p)
   p.cap.g+=i-u
   if p.cap.g<0 then
    p.cap.g=0
    for c in all(p.hx) do if (c.u>0) grave(c) end
    if (f==1 and u>0) msg("a province went broke: units starved!",8) sfx(4)
   end
  else
   for c in all(p.hx) do if (c.u>0) grave(c) end
  end
 end
 if f==1 then st="play"
 else st,aq,at="ai",{},20 for p in all(provs[f]) do add(aq,p) end end
end

function land(f)
 local n=0
 for y=0,8 do for x=0,10 do if (h[y][x].o==f) n+=1 end end
 return n
end

function endturn()
 local f=cur%4+1
 while f!=1 and land(f)==0 do f=f%4+1 end
 local alive=false
 for g=2,4 do if (land(g)>0) alive=true end
 if (not alive) st,t="win",0 flash=8 sfx(8) return
 if (land(1)==0) st,t="over",0 music(-1) return
 startturn(f)
 if (f!=1) msg(fname[f].." is moving...",fcol[f])
end

-- ===== actions =====
function adjacent(p,z)
 for n in all(nbs(z)) do if (n.p==p) return true end
end

-- place a unit of strength u from province p onto z; returns true on success
function place(u,p,z,f)
 if z.o==f and z.p==p then
  if (z.cap or z.tw) return false
  if z.u>0 then
   if (z.u+u>4) return false
   z.u+=u
  else
   z.u=u
   if (z.tr or z.gr) z.tr,z.gr,z.mv=false,false,true
  end
  return true
 end
 if (not adjacent(p,z) or u<=defense(z)) return false
 local lost=z.o
 if (z.cap and lost==1) msg("our capital fell!",8)
 z.o,z.u,z.mv,z.tw,z.cap,z.tr,z.gr,z.g=f,u,true,false,false,false,false,0
 ring(hx(z.x,z.y),hy(z.y),2,2,fcol[f],12) sparks(hx(z.x,z.y),hy(z.y),6,{fcol[f],7})
 sfx(1) shake=2
 recalc()
 return true
end

-- ===== ai =====
function aistep()
 local p=deli(aq,1)
 if (not p) endturn() return
 -- provinces are rebuilt after every capture: use the hex's current one
 if (p.hx[1].o!=cur) return
 p=p.hx[1].p
 if (not p.cap) return
 local f,bought=cur,p.cap.lb==turn and 2 or 0
 -- buy peasants (once per province per turn) while it can afford their upkeep
 local i,u=income(p)
 while p.cap.g>=10 and i-u-2>=0 and bought<2 do
  local spot
  for c in all(p.hx) do if (c.u==0 and not c.cap and not c.tw) spot=c end
  if (not spot) break
  p.cap.g-=10 spot.u=1 spot.mv=false bought+=1 u+=2
 end
 p.cap.lb=turn
 if p.cap.g>=25 and rnd()<.3 and p.cap.lb!=turn then
  for c in all(p.hx) do
   if c.u==0 and not c.cap and not c.tw and not c.tr then c.tw=true p.cap.g-=15 break end
  end
 end
 -- attack with each ready unit
 for c in all(p.hx) do
  if c.u>0 and not c.mv and c.o==f then
   local best,bv=nil,0
   for z in all(p.hx) do
    for n in all(nbs(z)) do
     if n.o!=f and defense(n)<c.u then
      local v=(n.cap and 5 or n.u>0 and 3 or 2)+rnd()
      if (v>bv) best,bv=n,v
     end
    end
   end
   if best then
    local u_=c.u c.u=0
    if place(u_,p,best,f) then add(aq,best.p,1) else c.u=u_ end
    at=8 return
   end
  end
 end
 -- blocked: merge two ready units (up to knights) if the province can pay the extra upkeep
 for c in all(p.hx) do
  if c.u>0 and not c.mv then
   for d in all(p.hx) do
    if d!=c and d.u>0 and not d.mv and c.u+d.u<=3 then
     local i,u=income(p)
     if i-u-(upk[c.u+d.u]-upk[c.u]-upk[d.u])>=0 then
      d.u+=c.u c.u=0 add(aq,p,1) at=6
      ring(hx(d.x,d.y),hy(d.y),2,1,fcol[f],8) return
     end
    end
   end
  end
 end
 at=1
end

-- ===== update =====
function _update60()
 t+=1
 shake=max(0,shake-.4) flash=max(0,flash-1)
 if (mt and mt>0) mt-=1
 updvfx()
 if st=="play" then updplay()
 elseif st=="ai" then at-=1 if (at<=0) aistep()
 elseif btnp(4) then
  if st=="intro" then newgame() else load("voidstorm.p8") end
 end
end

function updplay()
 if menu then
  if (btnp(2) or btnp(3)) mi=3-mi
  if (btnp(5)) menu=nil return
  if btnp(4) then
   local z=h[cy][cx]
   local g=z.p.cap
   if mi==1 then
    if g.g>=10 then g.g-=10 hand={u=1,p=z.p,buy=10} msg("place the peasant")
    else msg("not enough gold",8) end
   elseif g.g>=15 then g.g-=15 z.tw=true sfx(3)
   else msg("not enough gold",8) end
   menu=nil
  end
  return
 end
 if (btnp(0)) cx=max(0,cx-1)
 if (btnp(1)) cx=min(10,cx+1)
 if (btnp(2)) cy=max(0,cy-1)
 if (btnp(3)) cy=min(8,cy+1)
 local z=h[cy][cx]
 if btnp(5) then
  if hand then
   if hand.src then hand.src.u=hand.u else hand.p.cap.g+=hand.buy end
   hand=nil
  else endturn() end
  return
 end
 if btnp(4) and z.l then
  if hand then
   if hand.src==z then z.u=hand.u hand=nil
   elseif place(hand.u,hand.p,z,1) then
    hand=nil sfx(7)
   else msg(z.o==1 and "can't place there" or "too strong: defense "..defense(z),8) sfx(4) end
  elseif z.o==1 and z.u>0 and not z.mv then
   if (not z.p.cap) msg("cut off from any capital") return
   hand={u=z.u,p=z.p,src=z} z.u=0
  elseif z.o==1 and z.p.cap and z.u==0 and not z.cap and not z.tw then
   menu,mi=true,1
  end
 end
end

-- ===== draw =====
function _draw()
 cls(1)
 if st=="intro" then drawintro() return end
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
 for y=0,8 do for x=0,10 do
  local z=h[y][x]
  if z.l then
   local px,py=hx(x,y),hy(y)
   local c=fcol[z.o]
   rectfill(px-5,py-3,px+5,py+3,c) rectfill(px-3,py-5,px+3,py+5,c)
   if z.p and z.p.f==1 and hand and hand.p==z.p then pset(px,py-4,7) end
   if z.tr then
    rectfill(px,py+1,px,py+3,4) circfill(px,py-1,2,3) pset(px,py-3,3)
   elseif z.gr then line(px,py-3,px,py+2,5) line(px-2,py-1,px+2,py-1,5) end
   if z.cap then
    dspr("dome",px,py,.9)
    if (z.o==1) print(z.g,px-5,py+3,7)
   end
   if (z.tw) dspr("b_turret",px,py,.9)
   if z.u>0 then
    if (z.u==2) pal(12,8) pal(1,2)
    dspr(usp[z.u],px,py,usc[z.u])
    pal()
    if (z.o==1 and not z.mv and t%40<30) pset(px+4,py-4,7)
   end
  end
 end end
 -- cursor + held unit
 local cxp,cyp=hx(cx,cy),hy(cy)
 if (st=="play") rect(cxp-6,cyp-6,cxp+6,cyp+6,t%20<10 and 7 or 0)
 if hand then
  if (hand.u==2) pal(12,8) pal(1,2)
  dspr(usp[hand.u],cxp,cyp-8+sin(t/30),usc[hand.u])
  pal()
 end
 drawvfx()
 camera()
 -- hud
 rectfill(0,0,127,9,0)
 print(st=="ai" and fname[cur].." moving" or "your turn",2,2,fcol[cur])
 for f=1,4 do rectfill(52+(f-1)*19,3,52+(f-1)*19+land(f)/3,6,fcol[f]) end
 rectfill(0,110,127,127,0)
 local z=h[cy][cx]
 if z.l and z.p and z.p.cap and z.o==1 then
  local i,u=income(z.p)
  print("gold "..z.p.cap.g.."  +"..i.." -"..u.." = "..(i-u),2,112,i-u>=0 and 11 or 8)
 elseif z.l then
  print(fname[z.o].." land  defense "..defense(z),2,112,fcol[z.o])
 end
 print(hand and "z place  x cancel" or "z pick unit / buy  x end turn",2,120,6)
 if (menu) drawmenu()
 if mt and mt>0 then
  local w=#mtx*2
  rectfill(62-w,10,65+w,16,0) print(mtx,64-w,11,mt%20<15 and mc or 7)
 end
 if (st=="over" or st=="win") drawend()
 if flash>0 then fillp(0b0101101001011010.1) rectfill(0,0,127,127,10) fillp() end
end

function drawmenu()
 rectfill(34,50,94,72,0) rect(34,50,94,72,12)
 print((mi==1 and ">" or " ").."peasant 10g",38,54,mi==1 and 10 or 7)
 print((mi==2 and ">" or " ").."tower 15g",38,63,mi==2 and 10 or 7)
end

function drawintro()
 cls(0)
 for i=1,40 do pset((i*37+t/(1+i%3))%128,(i*53)%128,i%3==0 and 7 or 13) end
 dspr("p_ice",64,34,3)
 print("\^w\^tshardmere",30,62,12)
 oprint("four kingdoms, one island.",14,78,7)
 oprint("pay your knights or they starve.",0,86,7)
 oprint("take every hex.",34,94,9)
 if (t%40<28) oprint("z: begin",48,108,11)
end

function drawend()
 rectfill(8,40,119,84,0) rect(8,40,119,84,st=="win" and 10 or 8)
 local s=st=="win" and "victory!" or "defeat"
 print("\^w\^t"..s,64-#s*4,46,st=="win" and 10 or 8)
 local w=st=="win" and "shardmere is yours" or "your kingdom has fallen"
 oprint(w,64-#w*2,62,7)
 oprint("turn "..turn,52,70,6)
 if (t>60 and t%40<28) oprint("z: back to title",32,77,6)
end
