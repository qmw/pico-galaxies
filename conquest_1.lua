-- conquest_1 (demake)
-- planet tessar: three powers race
-- to own the planet. see design.md

-- factions: name, colour, army icon
fn_=split"colony,hive,hegemony"
fc=split"12,11,8"
fi=split"i_colonist,crawl_a,saa"
tsp=split"t_grass,t_rock,t_crystal,t_water"
tname=split"plains,hills,crystal,sea"
bname=split"farm,mine,bank,fort"
bspr=split"b_farm,b_mine,b_hab,b_turret"
nb={{1,0},{-1,0},{0,1},{0,-1}}

function msg(s,c) mtx,mt,mc=s,100,c or 7 end
function tr(x,y) return x>=0 and y>=0 and x<8 and y<6 and m[y][x] or nil end

function _init()
 t,shake,flash=0,0,0
 parts,rings,fx,pops,arrows={},{},{},{},{}
 st="intro" music(0)
end

function newgame()
 m={}
 for y=0,5 do
  m[y]={}
  for x=0,7 do
   local r=rnd()
   m[y][x]={x=x,y=y,t=r<.45 and 1 or r<.7 and 2 or r<.88 and 3 or 4,o=0,pop=0,army=0,b=0}
  end
 end
 for f,c in ipairs({{1,2},{6,1},{5,4}}) do
  local z=m[c[2]][c[1]]
  z.t,z.o,z.pop,z.army,z.b=f==1 and 1 or 2,f,3,4,4
 end
 res={{food=4,ore=10,cr=20},{food=4,ore=10,cr=20},{food=4,ore=10,cr=20}}
 turn,cx,cy=1,1,2
 newturn()
 msg("expand, arm, conquer 60% of tessar",10)
end

function newturn()
 st,mode="play",nil
 for y=0,5 do for x=0,7 do m[y][x].ac=false end end
end

function owned(f)
 local l={}
 for y=0,5 do for x=0,7 do if (m[y][x].o==f) add(l,m[y][x]) end end
 return l
end
function land()
 local n=0
 for y=0,5 do for x=0,7 do if (m[y][x].t<4) n+=1 end end
 return n
end

-- ===== actions =====
function train(z)
 local r=res[z.o]
 if (r.ore<10 or r.cr<5) return false
 r.ore-=10 r.cr-=5 z.army+=2
 if (z.o==1) sparks(z.x*16+8,z.y*16+16,8,{12,7}) sfx(3)
 return true
end

function settle(z,d)
 if (z.pop<2 or not d or d.t==4 or d.o!=0) return false
 z.pop-=1 d.o,d.pop,d.army=z.o,1,0
 add(arrows,{z,d,fc[z.o],20}) sfx(7)
 return true
end

function build(z,b)
 local r=res[z.o]
 if (z.b>0 or r.cr<30) return false
 r.cr-=30 z.b=b sfx(3)
 return true
end

-- dice battle; returns attacker survivors (0 = defeat)
function battle(a,d,fort)
 while a>0 and d>0 do
  local ha,hd=0,0
  for i=1,min(a,6) do if (flr(rnd(6))>=4) ha+=1 end
  for i=1,min(d,6) do if (flr(rnd(6))>=(fort and 3 or 4)) hd+=1 end
  a-=hd d-=ha
 end
 return max(a,0)
end

function attack(z,d)
 if (not d or d.t==4 or d.o==z.o or z.army<2) return false
 local go=z.army-1
 z.army=1
 add(arrows,{z,d,fc[z.o],24})
 local px,py=d.x*16+8,d.y*16+16
 local left=battle(go,d.army,d.b==4)
 explode(px,py,2) shake=4
 if left>0 then
  local lost=d.o
  d.o,d.army,d.pop=z.o,left,max(1,d.pop\2)
  if (d.b==4) d.b=0
  ring(px,py,3,2,fc[z.o],16)
  if (z.o==1 or lost==1) msg(fn_[z.o].." took "..tname[d.t].."!",z.o==1 and 11 or 8)
 else
  d.army=max(1,d.army)
  if (z.o==1) msg("the attack failed",8)
 end
 return true
end

-- ===== turn end: ai + economy =====
function endturn()
 st,af,aq,at="ai",2,owned(2),0
 msg("hive is moving...",11)
end

function aistep()
 if #aq==0 then
  if af==2 then af,aq=3,owned(3) msg("hegemony is moving...",8) return end
  economy() return
 end
 local z=deli(aq,1)
 if (z.o==af) at=decide(z,af) or at
end

-- one territory's turn for faction f; returns a pause length when it acted visibly
function decide(z,f)
 local hive,af=f==2,f
 local r=res[f]
 -- attack a weaker neighbour
 for d in all(nb) do
  local o=tr(z.x+d[1],z.y+d[2])
  if o and o.t<4 and o.o!=af and o.o!=0 then
   local df=o.army+(o.b==4 and 2 or 0)
   if (z.army-1>=df*(hive and 1.2 or 1.6)+1 and z.army>=3) attack(z,o) return 26
  end
 end
 for d in all(nb) do
  local o=tr(z.x+d[1],z.y+d[2])
  if (o and settle(z,o)) return 16
 end
 if (z.army<5 or hive) and train(z) then return end
 if (z.b==0 and r.cr>=30) build(z,z.t==1 and 1 or z.t==2 and 2 or 3)
end

function economy()
 for f=1,3 do
  local r=res[f]
  for z in all(owned(f)) do
   local k=z.b==z.t and 1.5 or 1
   if (z.t==1) r.food+=z.pop*2*k
   if (z.t==2) r.ore+=z.pop*2*k
   if (z.t==3) r.cr+=z.pop*2*k
   r.cr+=1 r.food-=z.pop/2
  end
  r.food,r.ore,r.cr=flr(r.food),flr(r.ore),flr(r.cr)
  if turn%4==0 then
   for z in all(owned(f)) do
    z.pop=r.food>0 and min(6,z.pop+1) or max(1,z.pop-1)
   end
  end
  r.food=max(r.food,0)
 end
 turn+=1
 local tot=land()
 local best,bf=0,1
 for f=1,3 do
  local n=#owned(f)
  if (n>best) best,bf=n,f
  if n>=tot*.6 or n>0 and #owned(1)+#owned(2)+#owned(3)==n then
   if f==1 then win("tessar is yours") else over(fn_[f].." conquered tessar") end
   return
  end
 end
 if (#owned(1)==0) over("your colony was wiped out") return
 if turn>60 then
  if bf==1 then win("most territories at turn 60") else over(fn_[bf].." held the most land") end
  return
 end
 newturn()
end

function win(s) st,why,t="win",s,0 flash=8 sfx(8) end
function over(s) st,why,t="over",s,0 music(-1) end

-- ===== update =====
function _update60()
 t+=1
 shake=max(0,shake-.4) flash=max(0,flash-1)
 if (mt and mt>0) mt-=1
 updvfx()
 for a in all(arrows) do a[4]-=1 if (a[4]<=0) del(arrows,a) end
 if st=="play" then updplay()
 elseif st=="ai" then
  at-=1
  if (at<=0) at=4 aistep()
 elseif btnp(4) then
  if st=="intro" then newgame() else load("voidstorm.p8") end
 end
end

function updplay()
 if mode=="menu" then
  if (btnp(2)) mi=(mi-2)%#opts+1
  if (btnp(3)) mi=mi%#opts+1
  if (btnp(5)) mode=nil return
  if btnp(4) then
   local z,o=m[cy][cx],opts[mi]
   if o[2]=="settle" or o[2]=="attack" then mode,act=o[2],o[2] msg("choose a neighbour",12)
   elseif o[2]() then z.ac=true mode=nil
   else msg("not enough resources",8) sfx(4) end
  end
  return
 end
 local ox,oy=cx,cy
 if (btnp(0)) cx=max(0,cx-1)
 if (btnp(1)) cx=min(7,cx+1)
 if (btnp(2)) cy=max(0,cy-1)
 if (btnp(3)) cy=min(5,cy+1)
 if mode=="settle" or mode=="attack" then
  if (abs(cx-sx)+abs(cy-sy)>1) cx,cy=ox,oy
  if (btnp(5)) mode=nil cx,cy=sx,sy return
  if btnp(4) then
   local z,d=m[sy][sx],m[cy][cx]
   local ok=abs(cx-sx)+abs(cy-sy)==1 and (mode=="settle" and settle(z,d) or mode=="attack" and attack(z,d))
   if ok then z.ac=true mode=nil else msg("can't "..mode.." there",8) sfx(4) end
  end
  return
 end
 if (btnp(5)) endturn() return
 if btnp(4) then
  local z=m[cy][cx]
  if (z.o!=1) msg("not your territory") return
  if (z.ac) msg("already acted this turn") return
  sx,sy,mi=cx,cy,1
  opts={{"train army (10o 5c)",function() return train(z) end},{"settle a neighbour","settle"},{"attack a neighbour","attack"}}
  if z.b==0 then
   for b=1,4 do add(opts,{"build "..bname[b].." (30c)",function() return build(z,b) end}) end
  end
  mode="menu"
 end
end

-- ===== draw =====
function _draw()
 cls(0)
 if st=="intro" then drawintro() return end
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
 for y=0,5 do for x=0,7 do
  local z=m[y][x]
  local px,py=x*16,8+y*16
  local s=sp[tsp[z.t]]
  sspr(s[1],s[2],8,8,px,py,16,16)
  if z.o>0 then
   rect(px,py,px+15,py+15,fc[z.o]) rect(px+1,py+1,px+14,py+14,fc[z.o])
   if z.army>0 then
    dspr(fi[z.o],px+5,py+6,z.o==3 and .4 or .7)
    print(z.army,px+10,py+3,7)
   end
   for i=1,z.pop do pset(px+1+i*2,py+13,10) end
   if (z.b>0) dspr(bspr[z.b],px+12,py+12,.5)
   if (z.ac and z.o==1) line(px+11,py+3,px+12,py+4,5) line(px+12,py+4,px+14,py+2,5)
  end
 end end
 for a in all(arrows) do
  line(a[1].x*16+8,a[1].y*16+16,a[2].x*16+8,a[2].y*16+16,t%4<2 and a[3] or 7)
  circfill(a[2].x*16+8,a[2].y*16+16,2,a[3])
 end
 if mode=="settle" or mode=="attack" then
  for d in all(nb) do
   local o=tr(sx+d[1],sy+d[2])
   if (o and o.t<4) rect(o.x*16+1,8+o.y*16+1,o.x*16+14,8+o.y*16+14,mode=="attack" and 8 or 11)
  end
 end
 if (st=="play") rect(cx*16,8+cy*16,cx*16+15,8+cy*16+15,t%20<10 and 7 or 10)
 drawvfx()
 camera()
 -- hud
 rectfill(0,0,127,7,0)
 local r=res[1]
 dspr("i_food",3,3,.8) print(r.food,8,1,7)
 dspr("i_ore",31,3,.8) print(r.ore,36,1,7)
 dspr("i_coin",59,3,.8) print(r.cr,64,1,10)
 print("t"..turn.."/60",100,1,6)
 rectfill(0,104,127,127,0)
 local tot=land()
 for f=1,3 do
  local n=#owned(f)
  rectfill(2+(f-1)*42,105,2+(f-1)*42+n*40/tot,107,fc[f])
  rect(2+(f-1)*42+tot*.6*40/tot,104,2+(f-1)*42+tot*.6*40/tot,108,7)
 end
 local z=m[cy][cx]
 local s=tname[z.t]..(z.o>0 and " - "..fn_[z.o].." pop "..z.pop.." army "..z.army or z.t<4 and " - free" or "")
 print(s,2,111,z.o>0 and fc[z.o] or 6)
 local h=st=="ai" and "rivals are moving..." or mode=="menu" and "z choose  x back" or mode and "pick a highlighted neighbour" or "z orders  x end turn"
 print(h,2,120,st=="ai" and 8 or 5)
 if (mode=="menu") drawmenu()
 if mt and mt>0 then
  local w=#mtx*2
  rectfill(62-w,9,65+w,15,0) print(mtx,64-w,10,mt%20<15 and mc or 7)
 end
 if (st=="over" or st=="win") drawend()
 if flash>0 then fillp(0b0101101001011010.1) rectfill(0,0,127,127,10) fillp() end
end

function drawmenu()
 local h=#opts*8+4
 local my=cy<3 and 60 or 18
 rectfill(20,my,108,my+h,0) rect(20,my,108,my+h,12)
 for i,o in ipairs(opts) do
  if (i==mi) rectfill(21,my+i*8-6,107,my+i*8,1)
  print(o[1],24,my+i*8-5,i==mi and 10 or 7)
 end
end

function drawintro()
 for i=1,40 do pset((i*37+t/(1+i%3))%128,(i*53)%128,i%3==0 and 7 or 13) end
 dspr("p_lush",64,34,3)
 print("\^w\^ttessar",40,62,11)
 oprint("three powers. one planet.",14,78,7)
 oprint("settle, arm and conquer 60%",10,86,7)
 oprint("before the hive or hegemony.",8,94,9)
 if (t%40<28) oprint("z: begin",48,108,11)
end

function drawend()
 rectfill(8,40,119,84,0) rect(8,40,119,84,st=="win" and 10 or 8)
 local s=st=="win" and "victory!" or "defeat"
 print("\^w\^t"..s,64-#s*4,46,st=="win" and 10 or 8)
 oprint(why,64-#why*2,62,7)
 oprint("turn "..turn,52,70,6)
 if (t>60 and t%40<28) oprint("z: back to title",32,77,6)
end
