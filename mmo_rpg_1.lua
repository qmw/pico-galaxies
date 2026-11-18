-- mmo_rpg_1 (demake)
-- planet eldmoor: pocket fantasy mmo.
-- tab-target, hotbar, quests, a boss.
-- see design.md

-- tiles: 0 grass 1 tree 2 rock 3 water 4 road 5 house 6 barrow door
mw,mh=32,24
-- abilities: name,icon,mana,cooldown,cast,range
ab={}
for s in all(split("strike,i_ore,0,30,0,16|firebolt,ex1,10,0,48,64|mend,i_cells,15,300,60,0|nova,bmb,20,480,0,26","|")) do add(ab,split(s)) end
-- mobs: name,sprite,scale,hp,dmg,level,xp,ranged
md={}
for s in all(split("gloomfang,crawl_a,1,18,3,1,25,0|spitter,mine,.55,22,4,3,40,1|brute,ast,.7,40,7,5,70,0|hollow king,boss,.9,400,9,8,0,0","|")) do add(md,split(s)) end
names=split"ravenx,lilbrew,tankmaster"
chatl=split"lfg barrow need heals,wts linen cloth,anyone seen the hollow king?,lol wiped again,gz on ding!,where is sage thom?,brb food"
rar={{"common",6},{"rare",12},{"epic",14}}

function msg(s,c) mtx,mt,mc=s,90,c or 7 end
function d2(a,b) return abs(a.x-b.x)+abs(a.y-b.y) end
function solid(x,y)
 if (dun) return x<10 or x>118 or y<10 or y>100
 local tx,ty=flr(x/8),flr(y/8)
 if (tx<0 or ty<0 or tx>=mw or ty>=mh) return true
 local k=m[ty][tx]
 return k==1 or k==2 or k==3 or k==5
end
function say(n,s) add(chat,{n,s}) if (#chat>3) deli(chat,1) end

function _init()
 t,shake,flash=0,0,0
 parts,rings,fx,pops,shots,tels={},{},{},{},{},{}
 st="intro" music(0)
end

function newgame()
 srand(3) m={}
 for y=0,mh-1 do
  m[y]={}
  for x=0,mw-1 do
   local k=0
   if (x==0 or y==0 or x==mw-1 or y==mh-1) k=2
   if (x>=8 and x<=15 and rnd()<.28) k=1
   if (x>=17 and x<=24 and y<=10 and rnd()<.25) k=3
   if (x>=17 and x<=28 and y>=14 and rnd()<.22) k=2
   if (y==11 and x>0 and x<mw-1) k=4
   m[y][x]=k
  end
 end
 for c in all({{2,9},{5,9},{2,14},{6,14}}) do m[c[2]][c[1]]=5 end
 m[11][30]=6
 srand(t)
 p={x=28,y=96,hp=48,mhp=48,mp=45,mmp=45,lv=1,xp=0,wi=1,ai=1,gcd=0,cd={0,0,0,0},aa=0,cmb=0,f=false}
 mobs={}
 local function sp(k,n,x0,x1,y0,y1)
  for i=1,n do
   for j=1,40 do
    local x,y=(x0+rnd(x1-x0))*8,(y0+rnd(y1-y0))*8
    if not solid(x,y) then add(mobs,{k=k,x=x,y=y,hx=x,hy=y,hp=md[k][4],fl=0,cd=0}) break end
   end
  end
 end
 sp(1,7,9,15,2,21) sp(2,5,17,24,1,10) sp(3,4,18,28,14,22)
 npcs={{n="warden elra",x=36,y=80,c=11},{n="sage thom",x=52,y=120,c=13}}
 pls={}
 for i=1,3 do add(pls,{n=names[i],x=40+i*8,y=88,tx=40,ty=88,c=({8,14,9})[i]}) end
 q1,q2,q3,kills,sacs=0,0,0,0,0
 chat={} dun=false tg=nil
 st="play" msg("talk to warden elra (z)",10)
end

function mhp_() return 40+p.lv*8 end
function mmp_() return 40+p.lv*5 end
function power() return (1+(p.lv-1)*.15) end

-- ===== combat =====
function hurt(e,d,crit)
 if (crit) d*=2
 d=flr(d)
 e.hp-=d e.fl=4
 pop(e.x,e.y-8,""..d,crit and 10 or 7)
 sparks(e.x,e.y,3,{7,8})
 if (e!=p) e.ag=true
 if e.hp<=0 then
  if e==p then
   msg("you died. respawning at the graveyard",8)
   p.x,p.y,p.hp,p.mp,tg=28,96,mhp_(),mmp_(),nil
   for o in all(mobs) do
    o.ag=false
    if dun then
     if o.hx==64 then del(mobs,o) else o.dead,o.rs=true,60 end
    end
   end
   dun,tels=false,{}
   return
  end
  kill(e)
 end
end

function kill(e)
 local d=md[e.k]
 explode(e.x,e.y,e.k==4 and 4 or 1)
 if tg==e then tg=nil end
 if e.k==4 then
  st,t="win",0 flash=10 sfx(8) return
 end
 e.dead,e.rs=true,900
 xp(d[7])
 if e.k==1 and q1==1 then
  kills+=1
  if (kills>=6) q1=2 msg("fangs in the wood: done! return to elra",11)
 end
 if e.k==2 and q2==1 and rnd()<.6 then
  sacs+=1 pop(e.x,e.y-14,"spore sac "..sacs.."/4",11)
  if (sacs>=4) q2=2 msg("spore samples: done! return to thom",11)
 end
 if (rnd()<.18) loot(d[6]+flr(rnd(3)))
end

function loot(il)
 local r=il>=6 and 3 or il>=4 and 2 or 1
 local w=rnd()<.5
 local cur=w and p.wi or p.ai
 local nm=rar[r][1].." "..(w and "blade" or "mail").." ilvl "..il
 say("loot",nm)
 if il>cur then
  if w then p.wi=il else p.ai=il end
  msg("equipped "..nm,rar[r][2]) sfx(3)
  ring(p.x,p.y,2,2,rar[r][2],20)
 end
end

function xp(n)
 if (p.lv>=8) return
 p.xp+=n pop(p.x,p.y-12,"+"..n.." xp",12)
 while p.xp>=p.lv*100 and p.lv<8 do
  p.xp-=p.lv*100 p.lv+=1 p.hp,p.mp=mhp_(),mmp_()
  msg("level "..p.lv.."!",10) sfx(8) ring(p.x,p.y,3,3,10,24) sparks(p.x,p.y,20,{10,7,9})
  say(rnd(names),"gz!")
 end
end

function useab(i)
 local a=ab[i]
 if (p.cast or p.gcd>0 and i!=1 or p.cd[i]>0) return
 if (p.mp<a[3]) msg("not enough mana",8) return
 if a[6]>0 and i!=4 and (not tg or d2(tg,p)>a[6]) then
  autotarget(a[6])
  if (not tg or d2(tg,p)>a[6]) msg("out of range",8) return
 end
 if a[5]>0 then p.cast={i=i,t=0}
 else fire(i) end
end

function fire(i)
 local a=ab[i]
 p.mp-=a[3] p.cd[i]=a[4] p.gcd=30
 local pw=power()+p.wi*.15
 if i==1 then hurt(tg,(4+p.wi)*pw,rnd()<.1) sfx(1)
 elseif i==2 then
  local an=atan2(tg.x-p.x,tg.y-p.y)
  add(shots,{x=p.x,y=p.y,vx=cos(an)*2.5,vy=sin(an)*2.5,d=(8+p.wi*1.5)*pw,tg=tg,l=60}) sfx(0)
 elseif i==3 then
  local h=15+p.lv*3
  p.hp=min(mhp_(),p.hp+h) pop(p.x,p.y-10,"+"..h,11) sparks(p.x,p.y,12,{11,7,3}) sfx(3)
 else
  ring(p.x,p.y,4,3,12,14) ring(p.x,p.y,2,2,7,10) sfx(6) shake=2
  for e in all(mobs) do if (not e.dead and d2(e,p)<a[6]) hurt(e,(6+p.wi)*pw) end
 end
end

function autotarget(r)
 local best,bd=nil,r or 90
 for e in all(mobs) do
  if (not e.dead and d2(e,p)<bd and e!=tg) best,bd=e,d2(e,p)
 end
 tg=best or tg
end

-- ===== update =====
function _update60()
 t+=1
 shake=max(0,shake-.4) flash=max(0,flash-1)
 if (mt and mt>0) mt-=1
 updvfx()
 if st=="play" then updplay()
 elseif st=="talk" then updtalk()
 elseif btnp(4) then
  if st=="intro" then newgame() else load("voidstorm.p8") end
 end
end

function updplay()
 for i=1,4 do p.cd[i]=max(0,p.cd[i]-1) end
 p.gcd=max(0,p.gcd-1) p.cmb=max(0,p.cmb-1)
 p.mp=min(mmp_(),p.mp+.06)
 if (p.cmb==0) p.hp=min(mhp_(),p.hp+.1)
 -- input
 if btn(5) then
  for b=0,3 do if (btnp(b)) useab(({1,2,3,4})[b+1]) end
 else
  local dx,dy=0,0
  if (btn(0)) dx=-1 p.f=true
  if (btn(1)) dx=1 p.f=false
  if (btn(2)) dy=-1
  if (btn(3)) dy=1
  if dx!=0 or dy!=0 then
   if (p.cast) p.cast=nil msg("interrupted",8)
   if (not solid(p.x+dx*3,p.y)) p.x+=dx*.9
   if (not solid(p.x,p.y+dy*3)) p.y+=dy*.9
  end
 end
 if btnp(4) then
  local near
  for n in all(npcs) do if (not dun and d2(n,p)<14) near=n end
  if near then talk(near) else autotarget() end
 end
 if p.cast then
  p.cast.t+=1
  if p.cast.t>=ab[p.cast.i][5] then
   local i=p.cast.i
   p.cast=nil
   if (i==3 or tg and not tg.dead) fire(i)
  end
 end
 -- auto-attack
 p.aa-=1
 if tg and not tg.dead and d2(tg,p)<14 and p.aa<=0 then p.aa=60 hurt(tg,(2+p.wi)*power()) end
 if (tg and tg.dead) tg=nil
 -- barrow door
 if not dun and abs(p.x-244)<6 and abs(p.y-92)<8 then
  if q3==1 then enterdun()
  elseif t%60==0 then msg("the barrow: needs the hollow king quest",8) end
 end
 updmobs() updshots()
 -- fake players wander and chat
 for o in all(pls) do
  if (abs(o.x-o.tx)<2 and abs(o.y-o.ty)<2) o.tx,o.ty=16+rnd(200),16+rnd(160)
  local a=atan2(o.tx-o.x,o.ty-o.y)
  if not solid(o.x+cos(a)*4,o.y+sin(a)*4) then o.x+=cos(a)*.5 o.y+=sin(a)*.5
  else o.tx,o.ty=o.x,o.y end
 end
 if (t%420==0) say(rnd(names),rnd(chatl))
end

function updmobs()
 for e in all(mobs) do
  if e.dead then
   e.rs-=1
   if (e.rs<=0 and not dun) e.dead,e.hp,e.x,e.y,e.ag=false,md[e.k][4],e.hx,e.hy,false
  else
   local d=md[e.k]
   if (e.fl>0) e.fl-=1
   e.cd-=1
   if (not e.ag and d2(e,p)<28) e.ag=true
   if e.ag then
    if not dun and abs(e.x-e.hx)+abs(e.y-e.hy)>90 then
     e.ag,e.hp,e.x,e.y=false,d[4],e.hx,e.hy
    else
     local dd,a=d2(e,p),atan2(p.x-e.x,p.y-e.y)
     local want=d[8]==1 and 36 or 9
     if dd>want then
      local s=e.k==4 and .35 or .5
      if (not solid(e.x+cos(a)*4,e.y+sin(a)*4)) e.x+=cos(a)*s e.y+=sin(a)*s
     end
     if e.cd<=0 and dd<(d[8]==1 and 50 or 12) then
      e.cd=60 p.cmb=180
      local dmg=max(1,d[5]-p.ai*.5)*((e.k==4 and t-bt>5400) and 2 or 1)
      if d[8]==1 then add(shots,{x=e.x,y=e.y,vx=cos(a)*1.6,vy=sin(a)*1.6,d=dmg,tg=p,l=60,m=true})
      else hurt(p,dmg) end
     end
     e.fx=p.x<e.x
    end
   end
  end
 end
 -- boss mechanics
 if dun and boss and not boss.dead then
  if t%150==0 then
   for i=1,3 do add(tels,{x=i==1 and p.x or 20+rnd(88),y=i==1 and p.y or 20+rnd(70),t=90}) end
  end
  if boss.hp<200 and not adds then
   adds=true msg("the hollow king calls his hounds!",8)
   for i=1,2 do add(mobs,{k=1,x=boss.x+i*10-15,y=boss.y+10,hx=64,hy=50,hp=18,fl=0,cd=30,ag=true}) end
  end
 end
 for tl in all(tels) do
  tl.t-=1
  if tl.t<=0 then
   del(tels,tl) explode(tl.x,tl.y,2)
   if (abs(p.x-tl.x)+abs(p.y-tl.y)<12) hurt(p,12)
  end
 end
end

function updshots()
 for s in all(shots) do
  s.l-=1
  if s.tg and not s.tg.dead then
   local a=atan2(s.tg.x-s.x,s.tg.y-s.y)
   local sp=s.m and 1.6 or 2.5
   s.vx,s.vy=cos(a)*sp,sin(a)*sp
  end
  s.x+=s.vx s.y+=s.vy
  if (t%2==0) part(s.x,s.y,0,0,8,s.m and {11,3} or {10,9,8},0,1)
  if s.tg and d2(s,s.tg)<5 then
   hurt(s.tg,s.d,not s.m and rnd()<.15) del(shots,s)
  elseif s.l<=0 then del(shots,s) end
 end
end

function enterdun()
 dun,boss,adds,bt=true,nil,false,t
 for e in all(mobs) do e.dead,e.rs=true,99999 end
 boss={k=4,x=64,y=40,hx=64,hy=40,hp=400,fl=0,cd=60,ag=true}
 add(mobs,boss)
 p.x,p.y=64,96 tg=boss
 msg("the barrow: the hollow king wakes!",8) sfx(9)
end

-- ===== quests / dialogue =====
function talk(n)
 dl,st=n,"talk"
 local e=n.n=="warden elra"
 if e then
  if q1==0 then dl.s,dl.f="gloomfangs prowl the wood east. slay 6 and i'll arm you.",function() q1=1 end
  elseif q1==2 then dl.s,dl.f="well fought! take this blade.",function() q1=3 p.wi=max(p.wi,3) xp(120) end
  elseif q1==3 and q3==0 then
   if p.lv>=4 then dl.s,dl.f="you're ready. the hollow king stirs in the barrow, far east. end him.",function() q3=1 end
   else dl.s,dl.f="grow stronger (level 4), then come back.",nil end
  else dl.s,dl.f="the barrow lies east along the road.",nil end
 else
  if q2==0 then dl.s,dl.f="bring me 4 spore sacs from the fen spitters, north-east.",function() q2=1 end
  elseif q2==2 then dl.s,dl.f="splendid samples! this mail will serve you.",function() q2=3 p.ai=max(p.ai,3) xp(150) end
  else dl.s,dl.f="mind the spores, friend.",nil end
 end
end

function updtalk()
 if btnp(4) or btnp(5) then
  if (btnp(4) and dl.f) dl.f() sfx(3)
  st="play"
 end
end

function mark(n)
 if n.n=="warden elra" then
  if (q1==0 or q1==3 and q3==0 and p.lv>=4) return "!",10
  if (q1==2) return "?",10
 else
  if (q2==0) return "!",10
  if (q2==2) return "?",10
 end
end

-- ===== draw =====
function _draw()
 cls(0)
 if st=="intro" then drawintro() return end
 local cx=dun and 0 or mid(0,p.x-64,mw*8-128)
 local cy=dun and -8 or mid(-8,p.y-56,mh*8-104)
 camera(cx+rnd(shake)-shake/2,cy+rnd(shake)-shake/2)
 if dun then
  rectfill(0,0,127,111,1)
  for i=0,15 do spr(133,i*8,0) spr(133,i*8,104) end
  for i=0,13 do spr(133,0,i*8) spr(133,120,i*8) end
 else
  for ty=flr(cy/8),flr(cy/8)+14 do for tx=flr(cx/8),flr(cx/8)+16 do
   local k=m[ty] and m[ty][tx]
   if k then
    local x,y=tx*8,ty*8
    if (k==4) rectfill(x,y,x+7,y+7,4) pset(x+(tx*3)%7,y+3,9)
    if (k!=4) spr(k==2 and 133 or k==3 and 135 or 132,x,y)
    if (k==1) rectfill(x+3,y+5,x+4,y+7,4) circfill(x+4,y+3,3,3) circfill(x+3,y+2,1,11)
    if (k==5) dspr("b_hab",x+4,y+4)
    if (k==6) dspr("nest",x+4,y+4,1.5) circ(x+4,y+4,7+sin(t/40),8)
   end
  end end
 end
 for tl in all(tels) do
  circ(tl.x,tl.y,12,tl.t%10<5 and 8 or 2)
  circfill(tl.x,tl.y,12*(1-tl.t/90),2)
 end
 if not dun then
  for n in all(npcs) do
   pal(12,n.c) dspr("i_colonist",n.x,n.y) pal()
   local s,c=mark(n)
   if (s) print(s,n.x-1,n.y-12+sin(t/30),c)
  end
  for o in all(pls) do
   pal(12,o.c) dspr("i_colonist",o.x,o.y) pal()
   print(o.n,o.x-#o.n*2,o.y-10,5)
  end
 end
 for e in all(mobs) do
  if not e.dead then
   local d=md[e.k]
   if (e==tg) ovalfill(e.x-6,e.y+3,e.x+6,e.y+6,8)
   if (e.fl>0) whiteout()
   dspr(d[2],e.x,e.y,d[3],e.fx)
   pal()
   if (e.hp<d[4]) line(e.x-4,e.y-7,e.x-4+8*e.hp/d[4],e.y-7,8)
  end
 end
 for s in all(shots) do circfill(s.x,s.y,1.5,s.m and 11 or 9) pset(s.x,s.y,7) end
 ovalfill(p.x-4,p.y+3,p.x+4,p.y+5,1)
 pal(12,9) dspr("i_colonist",p.x,p.y,1.1,p.f) pal()
 drawvfx()
 camera()
 drawhud()
 if (st=="talk") drawtalk()
 if st=="win" then
  rectfill(6,40,121,84,0) rect(6,40,121,84,10)
  print("\^w\^tvictory!",32,45,10)
  oprint("the hollow king has fallen",12,62,7)
  oprint("level "..p.lv,52,70,6)
  if (t>60 and t%40<28) oprint("z: back to title",32,77,6)
 end
 if mt and mt>0 then
  local w=#mtx*2
  rectfill(62-w,24,65+w,31,0) print(mtx,64-w,25,mt%20<15 and mc or 7)
 end
end

function bar(x,y,w,v,mx,c)
 rectfill(x,y,x+w,y+2,1) rectfill(x,y,x+w*max(0,v)/mx,y+2,c)
end

function drawhud()
 -- player frame
 rectfill(0,0,44,13,0)
 print("lv"..p.lv,2,1,10)
 bar(16,1,26,p.hp,mhp_(),8) bar(16,5,26,p.mp,mmp_(),12)
 bar(2,10,40,p.xp,p.lv*100,9)
 -- target frame
 if tg and not tg.dead then
  local d=md[tg.k]
  rectfill(74,0,127,9,0)
  print(d[1].." "..d[6],76,1,8)
  bar(76,6,48,tg.hp,d[4],8)
 end
 -- quest tracker
 local y=12
 if (q1==1) print("fangs "..kills.."/6",86,y,6) y+=7
 if (q2==1) print("sacs "..sacs.."/4",86,y,6) y+=7
 if (q3==1) print("slay the king",76,y,8)
 -- chat
 for i,c in ipairs(chat) do
  print("["..c[1].."] "..c[2],2,92+i*6-#chat*6,c[1]=="loot" and 11 or 5)
 end
 -- hotbar + cast bar
 rectfill(0,113,127,127,0)
 for i=1,4 do
  local x=34+(i-1)*15
  rect(x,114,x+13,126,btn(5) and 10 or 5)
  dspr(ab[i][2],x+7,120,.8)
  if (p.cd[i]>0) rectfill(x+1,115,x+12,115+11*p.cd[i]/ab[i][4],1)
  print(({"<","^",">","v"})[i],x+5,108,6)
 end
 if p.cast then
  bar(34,110,58,p.cast.t,ab[p.cast.i][5],10)
 end
 print("x+dir",2,116,5) print("z tab",104,116,5)
end

function drawtalk()
 rectfill(4,62,123,106,0) rect(4,62,123,106,10)
 print(dl.n,8,65,10)
 local l,y="",73
 for w in all(split(dl.s," ",false)) do
  if (#l+#w>28) print(l,8,y,7) y+=7 l=""
  l..=w.." "
 end
 print(l,8,y,7)
 print(dl.f and "z accept  x later" or "z ok",54,99,6)
end

function drawintro()
 for i=1,40 do pset((i*37+t/(1+i%3))%128,(i*53)%128,i%3==0 and 7 or 13) end
 dspr("p_lush",64,34,3)
 print("\^w\^teldmoor",36,62,11)
 oprint("quests, loot, a hollow king.",10,78,7)
 oprint("hold x + arrow: abilities",14,86,7)
 oprint("z: talk / tab-target",24,94,9)
 if (t%40<28) oprint("z: log in",46,108,11)
end
