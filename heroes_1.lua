-- heroes_1 (demake)
-- planet ironveil: one hero, one town,
-- one map. turn-based battles.
-- see design.md

mw,mh=24,20
tn=split"t_grass,t_rock,t_crystal,t_water"
mvc=split"1,2,1,99"
rn=split"gold,ore,crystal"
ri=split"i_coin,i_ore,pow"
-- units: name,sprite,scale,hp,atk,def,dmin,dmax,speed,ranged,cost  (1-5 ours, 6-10 hive)
ut={}
for s in all(split("militia,i_colonist,1,5,2,1,1,2,4,0,60|rifleman,i_colonist,1,8,4,2,2,3,4,1,130|drone,dra,.6,15,5,5,3,5,7,0,260|saucer,saa,.7,32,8,8,6,10,5,0,600|lander,ship,.7,90,14,12,16,24,6,0,2000|crawler,crawl_a,1,4,2,1,1,3,5,0,0|spitter,mine,.5,9,4,2,2,3,4,1,0|diver,div,.55,12,6,3,2,5,8,0,0|brute,ast,.7,35,9,9,5,9,4,0,0|mothership,boss,.8,400,15,15,20,35,4,0,0","|")) do
 local a=split(s)
 add(ut,{n=a[1],s=a[2],sc=a[3],hp=a[4],a=a[5],d=a[6],mn=a[7],mx=a[8],sp=a[9],r=a[10]==1,c=a[11]})
end
-- town buildings: name, gold, ore, crystal (1-4 dwellings tier 2-5, 5 council)
bld={}
for s in all(split("rifle range,1000,5,0|drone bay,1500,5,0|saucer pad,3500,10,4|lander dock,7000,10,10|council,2500,8,0","|")) do
 add(bld,split(s))
end
growth=split"12,8,5,3,1"

function sn(n) return sp[n][2]\8*16+sp[n][1]\8 end
function msg(s,c) mtx,mt,mc=s,120,c or 7 end
function tl(x,y) return x>=0 and y>=0 and x<mw and y<mh and m[y][x] or 4 end
function key(x,y) return y*mw+x end

function _init()
 t,shake,flash=0,0,0
 parts,rings,fx,pops={},{},{},{}
 st="intro" music(0)
end

-- ===== new game / map =====
function newgame()
 repeat genmap() until reachable()
 h={x=3,y=10,mp=14,lv=1,xp=0,at=0,df=0}
 army={{k=1,n=18},{k=2,n=6}}
 res={2500,10,4}
 built,avail={true,false,false,false,false,false},{12,0,0,0,0}
 day,bt=1,false
 st="map" reveal()
 msg("find and destroy the hive capital",10)
end

function genmap()
 m,seen,obj={},{},{}
 for y=0,mh-1 do
  m[y],seen[y]={},{}
  for x=0,mw-1 do m[y][x]=1 end
 end
 for k in all(split"2,2,2,2,2,3,3,3,4,4,4") do
  local cx,cy,r=rnd(mw),rnd(mh),1+rnd(k==4 and 1.6 or 2.4)
  for y=0,mh-1 do for x=0,mw-1 do
   if ((x-cx)^2+(y-cy)^2<r*r) m[y][x]=k
  end end
 end
 for y=8,12 do for x=1,5 do m[y][x]=1 end end
 for y=7,13 do for x=18,22 do m[y][x]=1 end end
 obj[key(3,10)]={k="T"}
 obj[key(20,10)]={k="H"}
 local function place(o,near)
  for i=1,200 do
   local x,y=flr(rnd(mw)),flr(rnd(mh))
   local d=abs(x-3)+abs(y-10)
   if m[y][x]<4 and not obj[key(x,y)] and d>3 and (not near or d<near) then
    obj[key(x,y)]=o return x,y
   end
  end
 end
 for i=1,12 do place({k="r",r=1+i%3,v=i%3==1 and 300+flr(rnd(4))*100 or 3+flr(rnd(4))}) end
 for i=1,3 do
  local x,y=place({k="m",r=i},i==1 and 9)
  if (x) gstack(x+1,y,6+flr(rnd(3)))
 end
 for i=1,4 do place({k="c"}) end
 for i=1,14 do
  local x,y=place({k="e"})
  if (x) gstack(x,y)
 end
end

-- hive stack at x,y; strength grows with distance from town
function gstack(x,y,k)
 if (tl(x,y)>3 or obj[key(x,y)] and obj[key(x,y)].k!="e") return
 local d=abs(x-3)+abs(y-10)
 k=k or (d<9 and 6 or d<14 and rnd{6,7,8} or rnd{7,8,9})
 local n=({14,8,7,4})[k-5]+flr(rnd(5))+d\3
 obj[key(x,y)]={k="e",u=k,n=n}
end

function reachable()
 local q,v={{3,10}},{[key(3,10)]=true}
 while #q>0 do
  local c=deli(q,1)
  if (c[1]==20 and c[2]==10) return true
  for d in all({{1,0},{-1,0},{0,1},{0,-1}}) do
   local x,y=c[1]+d[1],c[2]+d[2]
   if (tl(x,y)<4 and not v[key(x,y)]) v[key(x,y)]=true add(q,{x,y})
  end
 end
end

function reveal()
 for j=-3,3 do for i=-3,3 do
  if (seen[h.y+j] and h.x+i>=0 and h.x+i<mw) seen[h.y+j][h.x+i]=true
 end end
end

-- ===== update =====
function _update60()
 t+=1
 shake=max(0,shake-.4) flash=max(0,flash-1)
 if (mt and mt>0) mt-=1
 updvfx()
 if st=="map" then updmap()
 elseif st=="town" then updtown()
 elseif st=="cache" then
  if (btnp(4)) res[1]+=500 msg("+500 gold",10) st="map"
  if (btnp(5)) gainxp(400) st="map"
 elseif st=="battle" then updbattle()
 elseif btnp(4) then
  if st=="intro" then newgame() else load("voidstorm.p8") end
 end
end

function updmap()
 if btnp(5) then endday() return end
 if btnp(4) then
  if (obj[key(h.x,h.y)] and obj[key(h.x,h.y)].k=="T") opentown()
  return
 end
 for b=0,3 do
  if btnp(b) then
   local x,y=h.x+({-1,1,0,0})[b+1],h.y+({0,0,-1,1})[b+1]
   local c=mvc[tl(x,y)]
   if (c>14) return
   if (h.mp<c) msg("no movement left: x ends the day",8) return
   local o=obj[key(x,y)]
   if o and (o.k=="e" or o.k=="H") then
    bx,by=x,y startbattle(o) return
   end
   h.x,h.y,h.mp=x,y,h.mp-c
   reveal()
   if (o) visit(o,x,y)
   return
  end
 end
end

function visit(o,x,y)
 if o.k=="r" then
  res[o.r]+=o.v obj[key(x,y)]=nil
  pop(hx_,hy_-8,"+"..o.v.." "..rn[o.r],10) sparks(hx_,hy_,8,{10,9,7}) sfx(3)
 elseif o.k=="m" and not o.own then
  o.own=true msg(rn[o.r].." mine claimed!",11) sfx(3)
 elseif o.k=="c" then
  obj[key(x,y)]=nil st="cache" sfx(3)
 elseif o.k=="T" then opentown() end
end

function endday()
 day+=1 h.mp=14 bt=false
 local inc={built[6] and 1000 or 500,0,0}
 for k,o in pairs(obj) do
  if (o.k=="m" and o.own) inc[o.r]+=o.r==1 and 250 or 2
 end
 for i=1,3 do res[i]+=inc[i] end
 if day%7==1 then
  for i=1,5 do if (i==1 or built[i]) avail[i]+=growth[i] end
  msg("a new week: recruits are ready",11)
 else msg("day "..day..": +"..inc[1].." gold") end
 if (day>90) over("the hives outlasted you")
end

function gainxp(n)
 h.xp+=n
 while h.xp>=h.lv*1000 do
  h.xp-=h.lv*1000 h.lv+=1 h.at+=1 h.df+=1
  msg("hero reached level "..h.lv.."! +1 atk +1 def",10)
  sparks(hx_ or 64,hy_ or 60,20,{10,7,9}) sfx(8)
 end
end

function over(s) st,why,t="over",s,0 music(-1) end

-- ===== town =====
function opentown() st,ti="town",1 end

function updtown()
 if (btnp(5)) st="map" return
 if (btnp(2)) ti=(ti-2)%10+1
 if (btnp(3)) ti=ti%10+1
 if btnp(4) then
  if ti<=5 then
   local b=bld[ti]
   if built[ti+1] then msg("already built")
   elseif bt then msg("one building per day",8)
   elseif res[1]>=b[2] and res[2]>=b[3] and res[3]>=b[4] then
    for i=1,3 do res[i]-=b[i+1] end
    built[ti+1],bt=true,true
    msg(b[1].." built!",11) sfx(3) sparks(64,40,12,{10,7})
   else msg("not enough resources",8) sfx(4) end
  else
   local k=ti-5
   local u=ut[k]
   if (avail[k]<1) msg("none available",8) return
   if (res[1]<u.c or k==5 and res[3]<2) msg("not enough gold",8) sfx(4) return
   local s
   for a in all(army) do if (a.k==k) s=a end
   if (not s and #army>=5) msg("army is full",8) return
   if (not s) s={k=k,n=0} add(army,s)
   s.n+=1 avail[k]-=1 res[1]-=u.c
   if (k==5) res[3]-=2
   sfx(7)
  end
 end
end

-- ===== battle =====
function startbattle(o)
 bo,bs=o,{}
 local foes={}
 if o.k=="H" then
  foes={{10,1},{9,6},{8,10},{7,10},{6,30}}
 else
  local parts=min(3,1+o.n\8)
  for i=1,parts do add(foes,{o.u,ceil(o.n/parts)}) end
 end
 for i,a in ipairs(army) do add(bs,{sd=1,k=a.k,n=a.n,hp=ut[a.k].hp,x=0,y=i-1,fl=0}) end
 for i,f in ipairs(foes) do add(bs,{sd=2,k=f[1],n=f[2],hp=ut[f[1]].hp,x=7,y=(i-1)%6,fl=0}) end
 xp0=0
 for s in all(bs) do if (s.sd==2) xp0+=s.n*ut[s.k].hp end
 round,st,ai,shots=0,"battle",0,{}
 newround()
 msg(o.k=="H" and "the hive capital!" or "battle!",8) sfx(9)
end

function newround()
 round+=1 order={}
 for s in all(bs) do s.rt=false add(order,s) end
 -- speed order, player first on ties (insertion sort)
 for i=2,#order do
  local j=i
  while j>1 and (ut[order[j].k].sp>ut[order[j-1].k].sp or ut[order[j].k].sp==ut[order[j-1].k].sp and order[j].sd<order[j-1].sd) do
   order[j],order[j-1]=order[j-1],order[j] j-=1
  end
 end
 oi=0 nexts()
end

function nexts()
 repeat oi+=1 until oi>#order or count(bs,order[oi])>0
 if (oi>#order) newround() return
 cur=order[oi] cur.df=false
 cx,cy,ai=cur.x,cur.y,30
end

function bat(x,y)
 for s in all(bs) do if (s.x==x and s.y==y) return s end
end
function bdist(a,x,y) return abs(a.x-x)+abs(a.y-y) end
function canmove(s,x,y) return x>=0 and x<8 and y>=0 and y<6 and not bat(x,y) and bdist(s,x,y)<=ut[s.k].sp end
function adjfoe(s)
 for o in all(bs) do if (o.sd!=s.sd and bdist(s,o.x,o.y)==1) return true end
end

-- damage from a to b; returns true if b died
function strike(a,b,half)
 local ua,ub=ut[a.k],ut[b.k]
 local at=ua.a+(a.sd==1 and h.at or 0)
 local df=(ub.d+(b.sd==1 and h.df or 0))*(b.df and 1.3 or 1)
 local d=0
 for i=1,min(a.n,20) do d+=ua.mn+flr(rnd(ua.mx-ua.mn+1)) end
 d=flr(d*a.n/min(a.n,20)*mid(.3,1+.1*(at-df),3)*(half and .5 or 1))
 d=max(1,d)
 local tot=(b.n-1)*ub.hp+b.hp-d
 b.fl=6
 local px,py=b.x*16+8,b.y*14+24
 pop(px,py-8,""..d,a.sd==1 and 10 or 8)
 sparks(px,py,6,{7,8,9})
 if tot<=0 then
  explode(px,py,ua.hp>30 and 2 or 1) del(bs,b) return true
 end
 b.n=ceil(tot/ub.hp) b.hp=tot-(b.n-1)*ub.hp
 shake=2 sfx(1)
end

function attack(a,b)
 local ranged=ut[a.k].r and bdist(a,b.x,b.y)>1
 if ranged then
  add(shots,{a.x*16+8,a.y*14+24,b.x*16+8,b.y*14+24,8})
  strike(a,b,adjfoe(a))
 elseif not strike(a,b) and not b.rt then
  b.rt=true strike(b,a)
 end
end

-- melee approach: empty cell next to target reachable by s (or s's own cell)
function approach(s,b)
 local best,bd=nil,99
 for d in all({{1,0},{-1,0},{0,1},{0,-1}}) do
  local x,y=b.x+d[1],b.y+d[2]
  if (x==s.x and y==s.y or canmove(s,x,y)) and bdist(s,x,y)<bd then best,bd={x,y},bdist(s,x,y) end
 end
 return best
end

function act(s,x,y)
 local b=bat(x,y)
 if b and b.sd!=s.sd then
  if not (ut[s.k].r and not adjfoe(s)) then
   local c=approach(s,b)
   if (not c) return false
   s.x,s.y=c[1],c[2]
  end
  attack(s,b)
 elseif canmove(s,x,y) then s.x,s.y=x,y
 else return false end
 return true
end

-- ai: attack/shoot the nearest foe, else step toward it
function aimove(s)
 local tg,bd=nil,99
 for o in all(bs) do if (o.sd!=s.sd and bdist(s,o.x,o.y)<bd) tg,bd=o,bdist(s,o.x,o.y) end
 if tg and not act(s,tg.x,tg.y) then
  local bx_,by_,bb=s.x,s.y,bd
  for y=0,5 do for x=0,7 do
   if (canmove(s,x,y) and abs(x-tg.x)+abs(y-tg.y)<bb) bx_,by_,bb=x,y,abs(x-tg.x)+abs(y-tg.y)
  end end
  s.x,s.y=bx_,by_
 end
end

-- end of a stack's turn: check for victory/defeat, then next stack
function finish()
 local a,e=0,0
 for s in all(bs) do if s.sd==1 then a+=1 else e+=1 end end
 if (a==0) over("your army was destroyed") return
 if (e==0) endbattle() return
 nexts()
end

function updbattle()
 for s in all(shots) do s[5]-=1 if (s[5]<=0) del(shots,s) end
 for s in all(bs) do if (s.fl>0) s.fl-=1 end
 if cur.sd==2 then
  ai-=1
  if (ai<=0) aimove(cur) finish()
  return
 end
 if (btnp(0)) cx=max(0,cx-1)
 if (btnp(1)) cx=min(7,cx+1)
 if (btnp(2)) cy=max(0,cy-1)
 if (btnp(3)) cy=min(5,cy+1)
 if (btnp(5)) cur.df=true msg("defending",12) finish() return
 if btnp(4) then
  if act(cur,cx,cy) then finish() else msg("can't reach",8) sfx(4) end
 end
end

function endbattle()
 army={}
 for s in all(bs) do add(army,{k=s.k,n=s.n}) end
 gainxp(xp0)
 obj[key(bx,by)]=nil
 h.x,h.y=bx,by reveal()
 st="map" sfx(8)
 msg("victory! +"..xp0.." xp",11)
 if (bo.k=="H") st,t="win",0 flash=8
end

-- ===== draw =====
function _draw()
 cls(0)
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
 if st=="intro" then drawintro()
 elseif st=="town" then drawtown()
 elseif st=="battle" then drawbattle()
 else
  drawmap()
  if (st=="cache") drawcache()
  if (st=="over" or st=="win") drawend()
 end
 drawvfx()
 camera()
 if mt and mt>0 then
  local w,y=#mtx*2,st=="battle" and 95 or st=="town" and 68 or 2
  rectfill(62-w,y-1,65+w,y+6,0)
  print(mtx,64-w,y,mt%20<15 and mc or 7)
 end
end

function drawmap()
 local ox,oy=mid(0,h.x-8,mw-16),mid(0,h.y-7,mh-14)
 for y=0,13 do for x=0,15 do
  local mx,my=ox+x,oy+y
  if seen[my][mx] then
   spr(sn(tn[m[my][mx]]),x*8,y*8)
   local o=obj[key(mx,my)]
   if o then
    local px,py=x*8+4,y*8+4
    if o.k=="r" then dspr(ri[o.r],px,py+sin(t/60+mx/7))
    elseif o.k=="m" then
     dspr(({"b_hab","b_mine","b_harv"})[o.r],px,py)
     if (o.own) pset(px+3,py-4,12)
    elseif o.k=="c" then dspr("i_cells",px,py)
    elseif o.k=="e" then
     local u=ut[o.u]
     dspr(u.s,px,py,u.sc*.8,t%60<30)
    elseif o.k=="T" then dspr("b_hq",px,py,.7)
    elseif o.k=="H" then dspr("boss",px,py,.5) circ(px,py,6+sin(t/40),8) end
   end
  end
 end end
 local hx,hy=(h.x-ox)*8+4,(h.y-oy)*8+4+sin(t/40)
 hx_,hy_=hx,hy
 pal(12,8) pal(1,2) dspr("i_colonist",hx,hy) pal()
 line(hx+3,hy-6,hx+3,hy+1,7) rectfill(hx+4,hy-6,hx+7,hy-4,8)
 rectfill(0,112,127,127,0)
 for i=1,3 do
  dspr(ri[i],4+(i-1)*36,118)
  print(res[i],10+(i-1)*36,116,7)
 end
 print("day "..day.." w"..((day-1)\7+1),2,122,6)
 print("mp "..h.mp,44,122,h.mp>0 and 11 or 8)
 print("lv"..h.lv,72,122,10)
 print("x:end day",92,122,5)
end

function drawcache()
 rectfill(14,40,113,80,0) rect(14,40,113,80,10)
 print("you found a cache!",28,46,10)
 print("z: take 500 gold",30,58,7)
 print("x: study it: 400 xp",26,68,7)
end

function drawtown()
 rectfill(0,0,127,127,1)
 dspr("b_hq",112,12,1.2)
 print("\^w\^tcolony hq",4,3,10)
 print("gold "..res[1].." ore "..res[2].." cry "..res[3],4,16,7)
 print("build (one per day)"..(bt and " - done" or ""),4,26,6)
 for i=1,5 do
  local b,y=bld[i],26+i*8
  if (ti==i) rectfill(2,y-1,125,y+5,0)
  print(b[1],8,y,built[i+1] and 11 or 7)
  print(built[i+1] and "built" or b[2].."g "..b[3].."o"..(b[4]>0 and " "..b[4].."c" or ""),60,y,built[i+1] and 11 or 9)
 end
 print("recruit (z: buy one)",4,76,6)
 for k=1,5 do
  local u,y=ut[k],76+k*8
  local ok=k==1 or built[k]
  if (ti==k+5) rectfill(2,y-1,125,y+5,0)
  if (k==2) pal(12,8) pal(1,2)
  dspr(u.s,10,y+2,u.sc*.7)
  pal()
  print(u.n,18,y,ok and 7 or 5)
  print(ok and avail[k].." left" or "need bld",60,y,ok and 11 or 5)
  print(u.c.."g",100,y,9)
 end
 print("x: leave",96,121,5)
end

function drawstack(s)
 local u=ut[s.k]
 local x,y=s.x*16+8,s.y*14+24
 if (s.fl>0) whiteout()
 if (s.k==2) pal(12,8) pal(1,2)
 dspr(u.s,x,y,u.sc,s.sd==2)
 pal()
 local c=""..s.n
 rectfill(x+7-#c*4,y+3,x+7,y+8,s.sd==1 and 1 or 2)
 print(c,x+8-#c*4,y+4,7)
end

function drawbattle()
 for y=0,5 do for x=0,7 do
  rectfill(x*16,17+y*14,x*16+15,17+y*14+13,(x+y)%2==0 and 3 or 1)
  if (cur.sd==1 and canmove(cur,x,y)) pset(x*16+8,17+y*14+7,11)
 end end
 if cur then
  rect(cur.x*16,17+cur.y*14,cur.x*16+15,17+cur.y*14+13,t%20<10 and 10 or 7)
 end
 for s in all(bs) do drawstack(s) end
 for s in all(shots) do line(s[1],s[2],s[3],s[4],t%2==0 and 10 or 7) end
 if cur.sd==1 then rect(cx*16+1,18+cy*14,cx*16+14,17+cy*14+12,12) end
 rectfill(0,0,127,15,0)
 local u=ut[cur.k]
 print("round "..round.."  "..(cur.sd==1 and "your " or "hive ")..u.n.." x"..cur.n,2,2,cur.sd==1 and 11 or 8)
 print("hp"..cur.hp.."/"..u.hp.." atk"..u.a.." def"..u.d.." spd"..u.sp..(u.r and " ranged" or ""),2,9,6)
 rectfill(0,102,127,127,0)
 print("z: move / attack   x: defend",4,106,6)
 print("hero lv"..h.lv.." +"..h.at.." atk +"..h.df.." def",4,114,10)
end

function drawintro()
 for i=1,40 do pset((i*37+t/(1+i%3))%128,(i*53)%128,i%3==0 and 7 or 13) end
 dspr("p_rock",64,34,3)
 print("\^w\^tironveil",32,62,9)
 oprint("lead your hero, grow your town,",4,78,7)
 oprint("raise an army and crush the",10,86,7)
 oprint("hive capital in the east.",14,94,9)
 if (t%40<28) oprint("z: begin",48,108,11)
 oprint("arrows move  z town  x end day",4,120,6)
end

function drawend()
 rectfill(8,40,119,84,0) rect(8,40,119,84,st=="win" and 10 or 8)
 local s=st=="win" and "victory!" or "defeat"
 print("\^w\^t"..s,64-#s*4,46,st=="win" and 10 or 8)
 local w=why or "the hive capital has fallen"
 oprint(w,64-#w*2,62,7)
 oprint("day "..day.."  hero lv"..h.lv,40,70,6)
 if (t>60 and t%40<28) oprint("z: back to title",32,77,6)
end
