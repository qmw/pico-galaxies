-- lane_duel_1 (demake)
-- planet ridgeback: one lane,
-- telegraphed enemy intents.
-- see design.md

-- cards: name,icon,damage,cooldown
cdef={}
for s in all(split("blade,i_guns,2,0|pike,pow,1,1|rifle,i_cells,1,2|dash,ship,1,2|shield,shd,0,3|charge,bmb,3,4","|")) do
 add(cdef,split(s))
end
-- enemies: name,sprite,scale,hp,windup,range,damage,move
edef={}
for s in all(split("crawler,crawl_a,1,2,1,1,1,1|spitter,mine,.55,2,2,3,1,1|diver,div,.55,2,1,1,1,2|brute,ast,.75,5,2,2,3,1|mothership,boss,.6,14,3,8,3,0","|")) do
 add(edef,split(s))
end
fights=split("1,1|1,2|1,1,3|4,1|2,2,3|4,2,1|4,4,3|5","|")

function cx(i) return 12+i*13 end
function msg(s,c) mtx,mt,mc=s,90,c or 7 end

function _init()
 t,shake,flash=0,0,0
 parts,rings,fx,pops,fxl={},{},{},{},{}
 st="intro" music(0)
end

function newgame()
 p={x=4,f=1,hp=6,mhp=6,sh=0}
 deck={}
 for k=1,3 do add(deck,{k=k,d=cdef[k][3],cd=0}) end
 fn,si=0,1
 nextfight()
end

function nextfight()
 fn+=1 en={} p.x,p.f,p.sh,q=4,1,0,{}
 for c in all(deck) do c.cd,c.q=0,false end
 local l=split(fights[fn])
 for i,k in ipairs(l) do
  local x=i%2==1 and 8-(i-1)\2 or (i-1)\2
  local d=edef[k]
  add(en,{k=k,x=x,f=x<4 and 1 or -1,hp=d[4],fl=0})
 end
 st="fight"
 msg(fn==8 and "the mothership!" or "fight "..fn.."/8",fn==8 and 8 or 10)
 sfx(fn==8 and 9 or 8)
end

function at(x)
 for e in all(en) do if (e.x==x) return e end
end
function free(x) return x>=0 and x<=8 and not at(x) and p.x!=x end

-- ===== update =====
function _update60()
 t+=1
 shake=max(0,shake-.4) flash=max(0,flash-1)
 if (mt and mt>0) mt-=1
 updvfx()
 for l in all(fxl) do l.t-=1 if (l.t<=0) del(fxl,l) end
 for e in all(en or {}) do if (e.fl>0) e.fl-=1 end
 if st=="fight" then updfight()
 elseif st=="reward" then updreward()
 elseif st=="slot" then updslot()
 elseif btnp(4) then
  if st=="intro" then newgame() else load("voidstorm.p8") end
 end
end

function updfight()
 local no=#deck+2
 if (btnp(2)) si=(si-2)%no+1
 if (btnp(3)) si=si%no+1
 local acted
 for b=0,1 do
  if btnp(b) then
   local d=b==0 and -1 or 1
   p.f=d
   if (free(p.x+d)) p.x+=d part(cx(p.x)-d*4,70,-d*.5,0,8,{6,5},0,1)
   acted=true
  end
 end
 if (btnp(5)) p.f=-p.f acted=true
 if btnp(4) then
  if si==#deck+2 then acted=true msg("wait",6)
  elseif si==#deck+1 then
   -- strike: fire the whole queue in order from the current spot/facing
   if #q==0 then msg("queue is empty",8) sfx(4)
   else
    for c in all(q) do usecard(c) c.cd=cdef[c.k][4]+1 c.q=false end
    q={} acted=true
   end
  else
   local c=deck[si]
   if c.cd>0 then msg("cooling down: "..c.cd,8) sfx(4)
   elseif c.q then msg("already queued",8) sfx(4)
   elseif #q>=3 then msg("queue is full: fire!",8) sfx(4)
   else add(q,c) c.q=true acted=true sfx(7) end
  end
 end
 if acted then
  enemyturn()
  for c in all(deck) do c.cd=max(0,c.cd-1) end
  if #en==0 then
   if fn==8 then st,t="win",0 flash=10 sfx(8)
   else st=pickoffers() oi=1 end
  end
 end
end

-- ===== player cards =====
function dmg(x,d)
 local e=at(x)
 if (not e) return
 -- backstab: enemy faces away from the player
 local back=e.f==sgn(e.x-p.x)
 if (back) d*=2 pop(cx(x),52,"backstab!",10)
 e.hp-=d e.fl=6
 pop(cx(x),58,""..d,back and 10 or 7)
 sparks(cx(x),66,6,{7,8,9}) shake=2 sfx(1)
 if e.hp<=0 then
  explode(cx(x),66,e.k==5 and 3 or 1) del(en,e)
 end
end

function slash(x1,x2,c) add(fxl,{x1,x2,c or 7,t=8}) end

function usecard(c)
 local k,d,f,x=c.k,c.d,p.f,p.x
 if k==1 then slash(x,x+f) dmg(x+f,d)
 elseif k==2 then slash(x,x+2*f,12) dmg(x+f,d) dmg(x+2*f,d)
 elseif k==3 then
  local tx=x+f
  while tx>=0 and tx<=8 and not at(tx) do tx+=f end
  if (tx<0 or tx>8) msg("rifle: no target",8) return false
  slash(x,tx,10) dmg(tx,d) sfx(0)
 elseif k==4 then
  if not at(x+f) or not free(x+2*f) then msg("dash fizzled",8) return false end
  for i=1,10 do part(cx(x)+f*i*2.6,66+rnd(4)-2,0,0,12,{12,7,1},0,1) end
  dmg(x+f,d) p.x=x+2*f
 elseif k==5 then p.sh=1 ring(cx(x),66,3,1,12,14) sfx(3)
 else
  ring(cx(x),66,4,2,9,12) slash(x-1,x+1,9) dmg(x-1,d) dmg(x+1,d)
 end
 return true
end

-- ===== enemy turn =====
function cells(e)
 local d=edef[e.k]
 local c={}
 for i=1,d[6] do
  local x=e.x+e.f*i
  if (x>=0 and x<=8) add(c,x)
 end
 return c
end

function enemyturn()
 for e in all(en) do
  local d=edef[e.k]
  if e.it then
   e.it-=1
   if e.it<=0 then
    e.it=nil
    for x in all(cells(e)) do
     slash(e.x,x,8)
     if x==p.x then
      if p.sh>0 then p.sh=0 msg("blocked!",12) ring(cx(p.x),66,2,2,12,10)
      else
       p.hp-=d[7] shake=5 flash=3 sfx(4)
       pop(cx(p.x),56,"-"..d[7],8) sparks(cx(p.x),66,10,{8,2})
       if (p.hp<=0) st,why,t="over","you fell on the ridge",0 music(-1)
      end
     end
    end
   end
  else
   e.f=sgn(p.x-e.x)
   local dist=abs(p.x-e.x)
   if e.k==5 and rnd()<.35 then
    local sx=e.x<4 and 8 or 0
    if (free(sx)) add(en,{k=1,x=sx,f=-sgn(sx-4),hp=2,fl=0}) msg("it spawns a crawler!",8)
   elseif dist<=d[6] then
    e.it=d[5]
   else
    for i=1,d[8] do
     if (free(e.x+e.f) and abs(p.x-e.x)>d[6]) e.x+=e.f
    end
   end
  end
 end
end

-- ===== rewards =====
function pickoffers()
 local c={{"heal 3 hp",0},{"+2 max hp",-1}}
 for i,s in ipairs(deck) do add(c,{"+1 dmg: "..cdef[s.k][1],-1-i}) end
 for k=4,6 do
  local own=false
  for s in all(deck) do if (s.k==k) own=true end
  if (not own) add(c,{"new card: "..cdef[k][1],k})
 end
 offers={}
 for i=1,3 do local o=rnd(c) del(c,o) add(offers,o) end
 return "reward"
end

function updreward()
 if (btnp(2)) oi=(oi-2)%3+1
 if (btnp(3)) oi=oi%3+1
 if btnp(4) then
  local v=offers[oi][2]
  sfx(3)
  if v==0 then p.hp=min(p.mhp,p.hp+3)
  elseif v==-1 then p.mhp+=2 p.hp+=2
  elseif v<-1 then deck[-1-v].d+=1
  else newk,st,si=v,"slot",1 return end
  nextfight()
 end
end

function updslot()
 if (btnp(2)) si=(si-2)%3+1
 if (btnp(3)) si=si%3+1
 if btnp(4) then
  deck[si]={k=newk,d=cdef[newk][3],cd=0} si=1
  nextfight()
 end
end

-- ===== draw =====
function _draw()
 cls(1)
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
 for i=1,30 do pset((i*41+t\8)%128,(i*29)%50,i%4==0 and 7 or 13) end
 dspr("p_rock",100,24,1.5)
 if st=="intro" then drawintro()
 else drawlane() end
 drawvfx()
 camera()
 if st=="reward" or st=="slot" then drawreward() end
 if (st=="over" or st=="win") drawend()
 if mt and mt>0 then
  local w=#mtx*2
  rectfill(62-w,13,65+w,20,0)
  print(mtx,64-w,14,mt%20<15 and mc or 7)
 end
 if flash>0 then fillp(0b0101101001011010.1) rectfill(0,0,127,127,8) fillp() end
end

function drawlane()
 -- ridge
 rectfill(0,74,127,127,0)
 for i=0,8 do
  local x=cx(i)
  sspr(40,64,8,8,x-6,74,13,8)
  rect(x-6,58,x+6,73,5)
 end
 -- telegraphs
 for e in all(en) do
  if e.it then
   for x in all(cells(e)) do
    rect(cx(x)-6,58,cx(x)+6,73,t%16<8 and 8 or 2)
   end
  end
 end
 for e in all(en) do
  local d=edef[e.k]
  if (e.fl>0) whiteout()
  dspr(d[2],cx(e.x),66,d[3],e.f<0)
  pal()
  for i=1,e.hp do pset(cx(e.x)-6+i*2 -(e.hp>6 and 6 or 0),78,8) end
  if e.it then
   circfill(cx(e.x),52,4,8) print(e.it,cx(e.x)-1,50,7)
  elseif e.k!=5 then print(e.f>0 and ">" or "<",cx(e.x)-1,51,5) end
 end
 -- player
 local px=cx(p.x)
 dspr("i_colonist",px,66,1.3,p.f<0)
 print(p.f>0 and ">" or "<",px-1,51,11)
 for i,c in ipairs(q) do pset(px-4+i*2,49,12) end
 if (p.sh>0) circ(px,66,7,12)
 for l in all(fxl) do
  local y=66+(l[3]==8 and -3 or 0)
  line(cx(l[1]),y,cx(l[2]),y,t%2==0 and l[3] or 7)
 end
 -- hud
 for i=1,p.mhp do
  print("\^:0a1f1f0e04000000",2+(i-1)*6,2,i<=p.hp and 8 or 2)
 end
 print("fight "..fn.."/8",90,2,6)
 -- cards
 for i=1,#deck+2 do
  local x,y=1+(i-1)*25,96
  local c=deck[i]
  rectfill(x,y,x+24,y+22,i==si and 2 or 0)
  rect(x,y,x+24,y+22,i==si and 10 or (c and c.q) and 12 or 5)
  if c then
   local d=cdef[c.k]
   dspr(d[2],x+7,y+7)
   print(sub(d[1],1,5),x+2,y+15,(c.cd>0 or c.q) and 5 or 7)
   if (c.d>0) print(c.d,x+20,y+2,9)
   if (c.cd>0) print(c.cd,x+20,y+9,8)
  else
   print(i==#deck+1 and "fire!" or "wait",x+3,y+8,i==#deck+1 and (#q>0 and 10 or 5) or 6)
  end
 end
 -- queue strip
 print("queue",2,86,6)
 for i=1,3 do
  local x=24+(i-1)*12
  rect(x,84,x+10,93,q[i] and 12 or 1)
  if (q[i]) dspr(cdef[q[i].k][2],x+5,89,.8)
 end
 print("fire! = run queue",62,86,5)
 print("<> move  x turn",34,121,5)
end

function drawreward()
 rectfill(10,24,117,92,0) rect(10,24,117,92,10)
 if st=="slot" then
  print("replace which card?",26,30,10)
  for i=1,3 do
   local y=34+i*12
   if (i==si) rectfill(12,y-2,115,y+6,1)
   print(cdef[deck[i].k][1].." -> "..cdef[newk][1],20,y,i==si and 10 or 7)
  end
  return
 end
 print("victory! choose a reward",18,30,10)
 for i,o in ipairs(offers) do
  local y=34+i*14
  if (i==oi) rectfill(12,y-3,115,y+7,1)
  print(o[1],20,y,i==oi and 10 or 7)
 end
end

function drawintro()
 dspr("p_rock",64,34,3)
 print("\^w\^tridgeback",28,62,9)
 oprint("one ridge. one lane. read their",2,78,7)
 oprint("intent, strike first, survive",6,86,7)
 oprint("8 fights.",46,94,9)
 if (t%40<28) oprint("z: begin",48,108,11)
end

function drawend()
 rectfill(8,40,119,84,0) rect(8,40,119,84,st=="win" and 10 or 8)
 local s=st=="win" and "victory!" or "defeat"
 print("\^w\^t"..s,64-#s*4,46,st=="win" and 10 or 8)
 local w=why or "the mothership is dead"
 oprint(w,64-#w*2,62,7)
 oprint("fight "..fn.."/8",44,70,6)
 if (t>60 and t%40<28) oprint("z: back to title",32,77,6)
end
