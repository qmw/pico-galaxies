-- bug_battle_1 (demake)
-- planet mandible: real-time squad
-- bug battles with pause.
-- see design.md

-- bugs: name,sprite,scale,hp,damage,speed,range,rate
ud={}
for s in all(split("ant,crawl_a,.9,6,1,.5,6,30|beetle,ast,.6,16,2,.3,7,40|spitter,mine,.5,5,1,.35,30,50|gnat,dra,.45,4,1,.9,6,25","|")) do add(ud,split(s)) end
tc={12,8} tc2={1,2}

function msg(s,c) mtx,mt,mc=s,100,c or 7 end
function dist(a,b) return abs(a.x-b.x)+abs(a.y-b.y) end

function _init()
 t,shake,flash=0,0,0
 parts,rings,fx,pops,shots,marks={},{},{},{},{},{}
 st="intro" music(0)
end

function newgame()
 lv=0 bugs={}
 for k in all(split"1,1,1,1,1,2,3,3,4") do addbug(1,k,14+rnd(16),40+rnd(40)) end
 nextlevel()
end

function addbug(sd,k,x,y)
 local b={sd=sd,k=k,x=x,y=y,hp=ud[k][4],cd=rnd(20),fl=0}
 add(bugs,b) return b
end

function nextlevel()
 lv+=1 paused,cx,cy=false,40,60
 for b in all(bugs) do
  b.x,b.y,b.tx,b.tg,b.sel=14+rnd(16),30+rnd(60),nil,nil,false
  b.hp=ud[b.k][4]
 end
 if (lv>1) for i=1,4 do addbug(1,1,20,25+i*16) end
 piles={}
 local n=lv+1
 for i=1,n do
  local x=n==1 and 64 or 24+(i-1)*80/(n-1)
  add(piles,{x=x,y=30+(i*37)%60,o=0,pr=0,sp=0})
 end
 piles[1].o,piles[1].pr=1,100
 piles[#piles].o,piles[#piles].pr=2,-100
 local red=({"1,1,1,1","1,1,1,1,2,2,3,3","1,1,1,1,2,2,3,3,3,4,4,4"})[lv]
 for k in all(split(red)) do addbug(2,k,98+rnd(20),25+rnd(70)) end
 st="play" msg("battle "..lv.."/3",10) sfx(8)
end

function side(s)
 local n=0
 for b in all(bugs) do if (b.sd==s) n+=1 end
 return n
end

-- ===== simulation =====
function _update60()
 t+=1
 shake=max(0,shake-.4) flash=max(0,flash-1)
 if (mt and mt>0) mt-=1
 updvfx()
 for s in all(shots) do s.t-=1 if (s.t<=0) del(shots,s) end
 for m_ in all(marks) do m_.t-=1 if (m_.t<=0) del(marks,m_) end
 if st=="play" then
  input()
  if (not paused) sim()
 elseif btnp(4) then
  if st=="intro" then newgame()
  elseif st=="next" then nextlevel()
  else load("voidstorm.p8") end
 end
end

function sim()
 if (t%60==0) ai()
 for b in all(bugs) do
  local d=ud[b.k]
  if (b.fl>0) b.fl-=1
  b.cd-=1
  if (b.tg and b.tg.hp<=0) b.tg=nil
  if b.tg then
   local e=b.tg
   if dist(b,e)>d[7] then mv(b,e.x,e.y,d[6])
   elseif b.cd<=0 then bite(b,e) end
  elseif b.tx then
   mv(b,b.tx,b.ty,d[6])
   if (abs(b.x-b.tx)+abs(b.y-b.ty)<2) b.tx=nil
  else
   -- idle: auto-engage nearby enemies
   local best,bd=nil,20
   for e in all(bugs) do
    if (e.sd!=b.sd and dist(b,e)<bd) best,bd=e,dist(b,e)
   end
   b.tg=best
  end
 end
 -- separation
 for i=1,#bugs do
  local a=bugs[i]
  for j=i+1,#bugs do
   local c=bugs[j]
   local dx,dy=a.x-c.x,a.y-c.y
   if abs(dx)<5 and abs(dy)<5 then
    local px,py=(dx==0 and rnd(.4)-.2 or sgn(dx))*.25,(dy==0 and rnd(.4)-.2 or sgn(dy))*.25
    a.x+=px a.y+=py c.x-=px c.y-=py
   end
  end
  a.x,a.y=mid(4,a.x,123),mid(14,a.y,106)
 end
 -- piles: capture + spawning
 for p in all(piles) do
  local n={0,0}
  for b in all(bugs) do if (abs(b.x-p.x)<10 and abs(b.y-p.y)<10) n[b.sd]+=1 end
  if (n[1]>0 and n[2]==0) p.pr=min(100,p.pr+.6)
  if (n[2]>0 and n[1]==0) p.pr=max(-100,p.pr-.6)
  local o=p.o
  if (p.pr>=100) p.o=1
  if (p.pr<=-100) p.o=2
  if (p.o==1 and p.pr<0 or p.o==2 and p.pr>0) p.o=0
  if p.o!=o then
   ring(p.x,p.y,4,2,p.o>0 and tc[p.o] or 7,16)
   if (p.o==1) msg("pile captured!",11) sfx(3)
   if (o==1) msg("we lost a pile!",8)
  end
  if p.o>0 then
   p.sp+=1
   if p.sp>=480 and side(p.o)<14 then
    p.sp=0 addbug(p.o,1,p.x+rnd(8)-4,p.y+6) ring(p.x,p.y,2,1,tc[p.o],10)
   end
  end
 end
 -- battle end
 local redpiles=0 for p in all(piles) do if (p.o==2) redpiles+=1 end
 if side(2)==0 and redpiles==0 then
  if lv==3 then st,t="win",0 flash=8 sfx(8) else st,t="next",0 sfx(8) end
 elseif side(1)==0 then
  local mine=0 for p in all(piles) do if (p.o==1) mine+=1 end
  if (mine==0) st,why,t="over","the colony was wiped out",0 music(-1)
 end
end

function mv(b,x,y,s)
 local a=atan2(x-b.x,y-b.y)
 b.x+=cos(a)*s b.y+=sin(a)*s
 b.fx=x<b.x
end

function bite(b,e)
 local d=ud[b.k]
 b.cd=d[8]
 local dmg=d[5]
 if (e.k==2 and b.k==1) dmg/=2
 e.hp-=dmg e.fl=5
 if d[7]>10 then add(shots,{x=b.x,y=b.y,tx=e.x,ty=e.y,t=8,c=tc[b.sd]}) sfx(5)
 else sparks(e.x,e.y,3,{7,tc[b.sd]}) sfx(7) end
 if (b.k==4) b.hp=min(ud[4][4],b.hp+1)
 if e.hp<=0 then
  for i=1,8 do local a=rnd() part(e.x,e.y,cos(a)*1.2,sin(a)*1.2,18,{tc[e.sd],tc2[e.sd],5},1,2) end
  explode(e.x,e.y,e.k==2 and 2 or 1) del(bugs,e)
 end
end

function ai()
 for b in all(bugs) do
  if b.sd==2 and not b.tg and not b.tx then
   local best,bd=nil,40
   for e in all(bugs) do
    local w=(b.k==4 and e.k==3) and 60 or 0
    if (e.sd==1 and dist(b,e)-w<bd) best,bd=e,dist(b,e)-w
   end
   if best then b.tg=best
   else
    local p,pd=nil,999
    for q in all(piles) do if (q.o!=2 and dist(b,q)<pd) p,pd=q,dist(b,q) end
    if (p) b.tx,b.ty=p.x+rnd(10)-5,p.y+rnd(10)-5
   end
  end
 end
end

-- ===== player orders =====
function input()
 if (btn(0)) cx-=1.6
 if (btn(1)) cx+=1.6
 if (btn(2)) cy-=1.6
 if (btn(3)) cy+=1.6
 cx,cy=mid(2,cx,125),mid(12,cy,108)
 local sel={}
 for b in all(bugs) do if (b.sel) add(sel,b) end
 if btnp(5) then
  if #sel>0 then for b in all(sel) do b.sel=false end
  else paused=not paused sfx(7) end
  return
 end
 if not btnp(4) then return end
 local u,ud_=nil,6
 for b in all(bugs) do
  local d=abs(b.x-cx)+abs(b.y-cy)
  if (d<ud_) u,ud_=b,d
 end
 if u and u.sd==1 then u.sel=not u.sel sfx(7) return end
 if #sel==0 then
  for b in all(bugs) do if (b.sd==1) b.sel=true end
  msg("whole army selected",12) return
 end
 local pile
 for p in all(piles) do if (abs(p.x-cx)<8 and abs(p.y-cy)<8) pile=p end
 add(marks,{x=cx,y=cy,t=20,c=u and 8 or 11})
 for i,b in ipairs(sel) do
  if u then b.tg,b.tx=u,nil
  else
   local a,r=i/#sel,#sel>1 and 3+#sel or 0
   local ox,oy=pile and pile.x or cx,pile and pile.y or cy
   b.tx,b.ty,b.tg=ox+cos(a)*r,oy+sin(a)*r,nil
  end
 end
 sfx(0)
end

-- ===== draw =====
function _draw()
 cls(3)
 if st=="intro" then drawintro() return end
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
 for y=1,13 do for x=0,15 do
  local h=(x*x*7+y*13+x*y)%17
  spr(h<14 and 132 or 133,x*8,y*8)
 end end
 for p in all(piles) do
  dspr("i_food",p.x,p.y,1.2)
  for i=0,23 do
   local a=i/24
   local c=i/24<abs(p.pr)/100 and (p.pr>0 and 12 or 8) or 5
   pset(p.x+cos(a)*9,p.y+sin(a)*9,c)
  end
 end
 for b in all(bugs) do
  local d=ud[b.k]
  ovalfill(b.x-4,b.y+2,b.x+4,b.y+5,tc2[b.sd])
  if (b.sel) circ(b.x,b.y,6,t%16<8 and 7 or 10)
  if (b.fl>0) whiteout()
  if (b.sd==2) pal(11,8) pal(3,2) pal(12,8)
  if (b.sd==1) pal(11,12) pal(3,1)
  dspr(d[2],b.x,b.y,d[3],b.fx)
  pal()
  if (b.hp<d[4]) line(b.x-3,b.y-6,b.x-3+6*b.hp/d[4],b.y-6,tc[b.sd])
 end
 for s in all(shots) do
  local f=1-s.t/8
  circfill(s.x+(s.tx-s.x)*f,s.y+(s.ty-s.y)*f,1,s.c)
 end
 for m_ in all(marks) do circ(m_.x,m_.y,m_.t/4,m_.c) end
 drawvfx()
 camera()
 if (st=="play") line(cx-3,cy,cx+3,cy,7) line(cx,cy-3,cx,cy+3,7) pset(cx,cy,0)
 if paused and st=="play" then
  fillp(0b1010010110100101.1) rectfill(0,8,127,111,1) fillp()
  oprint("paused",52,58,10)
 end
 rectfill(0,0,127,7,0)
 print("battle "..lv.."/3",2,1,10)
 print("blue "..side(1),56,1,12) print("red "..side(2),92,1,8)
 rectfill(0,112,127,127,0)
 local n=0 for b in all(bugs) do if (b.sel) n+=1 end
 print(n>0 and n.." selected: z order  x drop" or "z select (empty=all)  x pause",2,114,6)
 print("capture piles to spawn ants",2,121,5)
 if mt and mt>0 then
  local w=#mtx*2
  rectfill(62-w,9,65+w,15,0) print(mtx,64-w,10,mt%20<15 and mc or 7)
 end
 if (st=="next") drawbanner("battle won!","z: next battle",11)
 if (st=="win") drawbanner("victory!","z: back to title",10)
 if (st=="over") drawbanner("defeat","z: back to title",8)
 if flash>0 then fillp(0b0101101001011010.1) rectfill(0,0,127,127,7) fillp() end
end

function drawbanner(a,b,c)
 rectfill(8,44,119,80,0) rect(8,44,119,80,c)
 print("\^w\^t"..a,64-#a*4,50,c)
 if (t>40 and t%40<28) oprint(b,64-#b*2,68,7)
end

function drawintro()
 cls(0)
 for i=1,40 do pset((i*37+t/(1+i%3))%128,(i*53)%128,i%3==0 and 7 or 13) end
 dspr("p_lush",64,34,3)
 print("\^w\^tmandible",32,62,11)
 oprint("command your bug colony.",16,78,7)
 oprint("take the food, crush the red",8,86,7)
 oprint("hive in 3 battles.",28,94,9)
 if (t%40<28) oprint("z: begin",48,108,11)
end
