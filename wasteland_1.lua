-- wasteland_1 (demake)
-- planet cinder: post-apocalyptic rpg.
-- talk, quest, loot, ap combat.
-- see design.md

-- areas: 16x13 tiles. . ground # wall b hab f farm h hq s scrap c core < > exits
maps={
"################".."#..............#".."#.h....bb...ff.#".."#..............#".."#..............#".."#..............>".."#..b.......b...>".."#..............#".."#....s.........#".."#..bb......bb..#".."#..bb......bb..#".."#..............#".."################",
"################".."#....s.....#...#".."#.##.......#.s.#".."#.##....s......#".."#..........##..#".."<...........#..>".."<..s...........>".."#.......##.....#".."#..##...##..s..#".."#..##..........#".."#.......s...##.#".."#..............#".."################",
"################".."#...#......#...#".."#...#..##..#.c.#".."#...#..##..#...#".."#..............#".."<...######.....#".."<.......#......#".."#.......#..##..#".."#..##...#..##..#".."#..##..........#".."#......s..s....#".."#..............#".."################"}
aname=split"rustwell,ash dunes,vault ruins"
-- weapons: name,min,max,range
wd={}
for s in all(split("knife,2,4,1|pistol,3,6,6|rifle,5,9,9|shotgun,6,12,4","|")) do add(wd,split(s)) end
-- enemies: name,sprite,scale,hp,ap,min,max,range,xp,caps
ed={}
for s in all(split("raider,i_colonist,1,12,6,3,6,6,30,15|scorpion,crawl_a,1,10,8,2,5,1,25,0|turret,dra,.5,15,6,2,5,8,40,0|gristle,saa,.7,40,8,6,12,4,200,80","|")) do add(ed,split(s)) end
sn_=split"str,agi,per,cha"

function msg(s,c) mtx,mt,mc=s,90,c or 7 end
function tile(x,y) return sub(maps[area],y*16+x+1,y*16+x+1) end
function dist(a,b) return abs(a.x-b.x)+abs(a.y-b.y) end
function at(x,y)
 for e in all(ents) do if (e.alive and e.a==area and e.x==x and e.y==y) return e end
end
function free(x,y)
 local c=tile(x,y)
 return x>=0 and x<16 and y>=0 and y<13 and (c=="." or c=="s" or c=="c" or c=="<" or c==">") and not at(x,y) and not (p.x==x and p.y==y)
end

function _init()
 t,shake,flash=0,0,0
 parts,rings,fx,pops,trs={},{},{},{},{}
 st="intro" music(0)
end

function newgame()
 p={x=7,y=5,st={5,5,5,5},lv=1,xp=0,caps=40,stim=2,scrap=0,w=2,ws={true,true},arm=0,core=false}
 pts,si=5,1
 area,qmain,qdog,gtalk,taken=1,0,0,false,{}
 ents={}
 local function e(k,a,x,y) add(ents,{k=k,a=a,x=x,y=y,hp=ed[k][4],alive=true,host=true}) end
 for c in all({{1,2,6,3},{1,2,12,6},{1,2,9,10},{2,2,2,8},{2,2,9,2},{2,2,13,9},{3,3,2,1},{3,3,13,7},{1,3,6,9},{1,3,10,4},{4,3,13,3}}) do e(unpack(c)) end
 for n in all({{"orin",5,4},{"vela",9,7},{"pip",4,11}}) do add(ents,{k=0,n=n[1],a=1,x=n[2],y=n[3],alive=true}) end
 dog={k=0,n="dog",a=2,x=14,y=10,alive=true} add(ents,dog)
 st="create"
end

function mhp() return 20+p.st[1]*2+(p.lv-1)*3 end
function maxap() return 5+p.st[2]\2 end
function checkpoint() cp={x=p.x,y=p.y,a=area,hp=p.hp} end

-- ===== update =====
function _update60()
 t+=1
 shake=max(0,shake-.4) flash=max(0,flash-1)
 if (mt and mt>0) mt-=1
 updvfx()
 for r in all(trs) do r[5]-=1 if (r[5]<=0) del(trs,r) end
 if st=="create" then updcreate()
 elseif st=="explore" then updexplore()
 elseif st=="talk" then updtalk()
 elseif st=="inv" then updinv()
 elseif st=="combat" then updcombat()
 elseif st=="dead" then
  if btnp(4) then p.x,p.y,area,p.hp=cp.x,cp.y,cp.a,mhp() st="explore" msg("checkpoint loaded") end
 elseif btnp(4) then
  if st=="intro" then newgame() else load("voidstorm.p8") end
 end
end

function updcreate()
 if (btnp(2)) si=(si-2)%4+1
 if (btnp(3)) si=si%4+1
 if (btnp(1) and pts>0 and p.st[si]<9) p.st[si]+=1 pts-=1
 if (btnp(0) and p.st[si]>3) p.st[si]-=1 pts+=1
 if (btnp(4) and pts==0) p.hp=mhp() st="explore" checkpoint() msg("rustwell. talk to elder orin.",10)
end

-- ===== exploration =====
function updexplore()
 if (btnp(5)) st,ii="inv",1 return
 if btnp(4) then
  for e in all(ents) do
   if e.alive and e.a==area and e.k==0 and dist(e,p)==1 then talk(e) return end
  end
 end
 for b=0,3 do
  if btnp(b) then
   local x,y=p.x+({-1,1,0,0})[b+1],p.y+({0,0,-1,1})[b+1]
   if free(x,y) then
    p.x,p.y=x,y
    local c=tile(x,y)
    if c==">" or c=="<" then
     area+=c==">" and 1 or -1 p.x=c==">" and 1 or 14
     msg(aname[area],10) checkpoint() sfx(8)
    elseif c=="s" and not taken[area*256+y*16+x] then
     taken[area*256+y*16+x]=true p.scrap+=1 msg("found scrap") sfx(3)
    elseif c=="c" and not p.core then
     p.core=true msg("you have the purifier core!",11) sfx(8) flash=6
    end
   end
  end
 end
 -- dog follows once found
 if (qdog==2) dog.a,dog.x,dog.y=area,p.x-1,p.y
 -- enemies wander; spotting the player starts combat
 for e in all(ents) do
  if e.alive and e.a==area and e.host then
   if e.k==4 and not gtalk and dist(e,p)<=3 then gtalk=true talk(e) return end
   if dist(e,p)<=5 and (e.k!=4 or gfight) then startcombat() return end
   if t%40==0 and e.k!=3 then
    local d=rnd({{1,0},{-1,0},{0,1},{0,-1}})
    if (free(e.x+d[1],e.y+d[2])) e.x+=d[1] e.y+=d[2]
   end
  end
 end
end

-- ===== dialogue =====
function node(text,opts) dlg,di={text=text,o=opts},1 st="talk" end
function bye() st="explore" end
function check(i,n) return p.st[i]>=n end
function gain(n)
 p.xp+=n pop(64,40,"+"..n.." xp",10)
 while p.xp>=p.lv*100 do
  p.xp-=p.lv*100 p.lv+=1
  local i=flr(rnd(4))+1 p.st[i]=min(10,p.st[i]+1) p.hp=mhp()
  msg("level "..p.lv.."! +1 "..sn_[i],10) sfx(8)
 end
end

function talk(e)
 local n=e.n
 if n=="orin" then
  if p.core then
   node("the core! rustwell will drink clean water again. thank you.",{{"you're welcome.",function() st,t="win",0 flash=8 sfx(8) end}})
  elseif qmain==0 then
   node("our purifier is dying. its core lies in the vault ruins, east past the dunes. gristle's raiders squat there.",
    {{"i'll get it.",function() qmain=1 gain(20) bye() end},
     {"[cha 6] what's in it for me?",function()
      if check(4,6) then p.caps+=50 qmain=1 gain(40) node("...fine. 50 caps now, more later.",{{"deal.",bye}})
      else node("you'd haggle over water? go.",{{"...",function() qmain=1 bye() end}}) end end},
     {"not now.",bye}})
  else node("the vault ruins are east. bring back the core.",{{"on my way.",bye}}) end
 elseif n=="vela" then
  local k=1.2-p.st[4]*.03
  node("vela's goods. caps talk.",{
   {"stimpak "..flr(25*k).."c",function() buy(flr(25*k),function() p.stim+=1 end) end},
   {"rifle "..flr(120*k).."c",function() buy(flr(120*k),function() p.ws[3]=true end) end},
   {"leather armor "..flr(60*k).."c",function() buy(flr(60*k),function() p.arm=max(p.arm,1) end) end},
   {"sell "..p.scrap.." scrap",function() p.caps+=p.scrap*10 p.scrap=0 talk(e) end},
   {"bye.",bye}})
 elseif n=="pip" then
  if qdog==2 then
   node("rusty! you found him! take these.",{{"good boy.",function() qdog=3 p.stim+=2 p.caps+=30 gain(100) dog.alive=false bye() end}})
  elseif qdog==0 then node("my dog rusty ran into the dunes...",{{"i'll find him.",function() qdog=1 bye() end},{"sorry, kid.",bye}})
  else node("please find rusty!",{{"working on it.",bye}}) end
 elseif n=="dog" then
  if (qdog<2) qdog=2 msg("rusty follows you",11) sfx(3)
  bye()
 else
  node("gristle: you want the core? walk away, wanderer.",{
   {"[cha 7] the town pays you to go",function()
    if check(4,7) then e.alive=false gain(150) node("...fine. but if they don't pay, i'm back.",{{"(he leaves)",bye}})
    else gfight=true node("nice try. die.",{{"fight!",function() bye() startcombat() end}}) end end},
   {"100 caps and you leave.",function()
    if p.caps>=100 then p.caps-=100 e.alive=false gain(80) node("pleasure doing business.",{{"(he leaves)",bye}})
    else gfight=true node("you're broke. and dead.",{{"fight!",function() bye() startcombat() end}}) end end},
   {"then we fight.",function() gfight=true bye() startcombat() end}})
 end
end

function buy(c,f)
 if (p.caps<c) msg("not enough caps",8) return
 p.caps-=c f() sfx(3) msg("bought.")
end

function updtalk()
 if (btnp(2)) di=(di-2)%#dlg.o+1
 if (btnp(3)) di=di%#dlg.o+1
 if (btnp(4)) dlg.o[di][2]()
end

-- ===== inventory =====
function updinv()
 local l=invlist()
 if (btnp(5)) st="explore" return
 if (btnp(2)) ii=(ii-2)%#l+1
 if (btnp(3)) ii=ii%#l+1
 if (btnp(4)) l[ii][2]()
end

function invlist()
 local l={}
 for i=1,4 do
  if (p.ws[i]) add(l,{(p.w==i and "* " or "  ")..wd[i][1].." "..wd[i][2].."-"..wd[i][3].." r"..wd[i][4],function() p.w=i end})
 end
 add(l,{"  stimpak x"..p.stim,function() usestim() end})
 return l
end

function usestim()
 if (p.stim<1 or p.hp>=mhp()) return false
 p.stim-=1 p.hp=min(mhp(),p.hp+10) sparks(px(p.x),py(p.y),8,{11,7}) sfx(3)
 return true
end

-- ===== combat =====
function px(x) return x*8+4 end
function py(y) return y*8+4 end

function startcombat()
 foes={}
 for e in all(ents) do if (e.alive and e.a==area and e.host and dist(e,p)<=9) add(foes,e) end
 if (#foes==0) return
 st,ph,p.ap,tg=st=="combat" and st or "combat","p",maxap(),1
 msg("combat!",8) sfx(9)
end

function hitch(e)
 local w=wd[p.w]
 local d=dist(e,p)
 if (d>w[4]) return 0
 return w[4]==1 and 85 or mid(5,50+p.st[3]*5-d*4,95)
end

function shoot(a,b,mn,mx,ch,melee)
 add(trs,{px(a.x),py(a.y),px(b.x),py(b.y),8})
 if rnd(100)<ch then
  local d=mn+flr(rnd(mx-mn+1))
  if (melee and a==p) d+=p.st[1]\2
  if (b==p) d=max(1,d-p.arm)
  b.hp-=d pop(px(b.x),py(b.y)-6,""..d,b==p and 8 or 10)
  sparks(px(b.x),py(b.y),6,{8,9,7}) shake=3 sfx(1)
  return true
 end
 pop(px(b.x),py(b.y)-6,"miss",6) sfx(5)
end

function updcombat()
 for i=#foes,1,-1 do
  local e=foes[i]
  if e.hp<=0 and e.alive then
   e.alive=false explode(px(e.x),py(e.y),e.k==4 and 3 or 1)
   p.caps+=ed[e.k][10] gain(ed[e.k][9])
  end
  if (not e.alive) deli(foes,i)
 end
 if #foes==0 then st="explore" msg("combat over",11) return end
 if p.hp<=0 then st,t="dead",0 explode(px(p.x),py(p.y),3) return end
 tg=mid(1,tg,#foes)
 if ph=="p" then
  if menu then
   if (btnp(2) or btnp(3)) mi=mi%3+1
   if (btnp(5)) menu=nil
   if btnp(4) then
    if mi==1 then tg=tg%#foes+1
    elseif mi==2 then if (p.ap>=2 and usestim()) p.ap-=2
    else p.ap=0 end
    menu=nil
   end
   return
  end
  if (btnp(5)) menu,mi=true,1 return
  for b=0,3 do
   if btnp(b) and p.ap>=1 then
    local x,y=p.x+({-1,1,0,0})[b+1],p.y+({0,0,-1,1})[b+1]
    if (free(x,y) and tile(x,y)!="<" and tile(x,y)!=">") p.x,p.y=x,y p.ap-=1
   end
  end
  if btnp(4) then
   local e=foes[tg]
   if p.ap<3 then msg("need 3 ap",8)
   elseif hitch(e)==0 then msg("out of range",8)
   else p.ap-=3 shoot(p,e,wd[p.w][2],wd[p.w][3],hitch(e),wd[p.w][4]==1) end
  end
  if (p.ap<=0) ph,eq,et="e",1,20 for e in all(foes) do e.ap=ed[e.k][5] end
 else
  et-=1
  if (et>0) return
  et=12
  local e=foes[eq]
  if not e then ph,p.ap="p",maxap() return end
  local d=ed[e.k]
  if e.ap>=3 and dist(e,p)<=d[8] then
   e.ap-=3 shoot(e,p,d[6],d[7],d[8]==1 and 70 or mid(10,60-dist(e,p)*3,90),d[8]==1)
  elseif e.ap>=1 and e.k!=3 and dist(e,p)>1 then
   local dx,dy=sgn(p.x-e.x),sgn(p.y-e.y)
   if (p.x==e.x) dx=0
   if (p.y==e.y) dy=0
   if free(e.x+dx,e.y) and dx!=0 then e.x+=dx
   elseif free(e.x,e.y+dy) and dy!=0 then e.y+=dy end
   e.ap-=1
  else eq+=1 end
 end
end

-- ===== draw =====
tspr={b="b_hab",f="b_farm",h="b_hq"}
function _draw()
 cls(0)
 if st=="intro" then drawintro() return end
 if st=="create" then drawcreate() return end
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
 local g=({4,4,5})[area]
 rectfill(0,0,127,103,g)
 for y=0,12 do for x=0,15 do
  local c=tile(x,y)
  if ((x*7+y*13)%5==0) pset(x*8+(x*3)%7,y*8+(y*5)%7,area==3 and 6 or 9)
  if c=="#" then spr(133,x*8,y*8)
  elseif tspr[c] then dspr(tspr[c],x*8+4,y*8+4,c=="h" and .5 or 1)
  elseif c=="s" and not taken[area*256+y*16+x] then dspr("i_ore",x*8+4,y*8+4,.8)
  elseif c=="c" and not p.core then dspr("i_cells",x*8+4,y*8+4) circ(x*8+4,y*8+4,5+sin(t/30),11)
  elseif c==">" or c=="<" then print(c,x*8+2,y*8+1,t%30<15 and 10 or 9) end
 end end
 if area==2 then
  for i=1,12 do pset((i*29+t/2)%128,(i*41+sin(t/90+i)*4)%104,15) end
 end
 for e in all(ents) do
  if e.alive and e.a==area then
   local x,y=px(e.x),py(e.y)
   if e.k==0 then
    if e.n=="dog" then circfill(x,y+1,2,4) pset(x+2,y,4) pset(x-2,y-1,4)
    else pal(12,({orin=6,vela=14,pip=10})[e.n]) dspr("i_colonist",x,y) pal() end
   else
    local d=ed[e.k]
    if (e.k==1) pal(12,8) pal(1,2)
    dspr(d[2],x,y,d[3])
    pal()
    if (st=="combat" and e.hp<d[4]) line(x-3,y-6,x-3+6*e.hp/d[4],y-6,8)
   end
  end
 end
 dspr("i_colonist",px(p.x),py(p.y)+sin(t/40)*.5)
 if st=="combat" and ph=="p" and foes[tg] then
  local e=foes[tg]
  rect(px(e.x)-5,py(e.y)-5,px(e.x)+4,py(e.y)+4,t%16<8 and 8 or 10)
  print(hitch(e).."%",px(e.x)+5,py(e.y)-6,7)
 end
 for r in all(trs) do line(r[1],r[2],r[3],r[4],t%2==0 and 10 or 7) end
 drawvfx()
 camera()
 drawhud()
 if (st=="talk") drawtalk()
 if (st=="inv") drawinv()
 if st=="dead" then
  rectfill(10,44,117,76,0) rect(10,44,117,76,8)
  print("\^w\^tyou died",30,48,8)
  if (t%40<28) oprint("z: load checkpoint",28,66,7)
 end
 if st=="win" then
  rectfill(6,40,121,84,0) rect(6,40,121,84,10)
  print("\^w\^tvictory!",32,45,10)
  oprint("rustwell has clean water",16,62,7)
  oprint("level "..p.lv.."  caps "..p.caps,34,70,6)
  if (t>60 and t%40<28) oprint("z: back to title",32,77,6)
 end
 if mt and mt>0 then
  local w=#mtx*2
  rectfill(62-w,1,65+w,8,0) print(mtx,64-w,2,mt%20<15 and mc or 7)
 end
end

function drawhud()
 rectfill(0,104,127,127,0)
 print("hp "..max(p.hp,0).."/"..mhp(),2,106,p.hp<8 and 8 or 11)
 print("lv"..p.lv,46,106,10)
 dspr("i_coin",62,108) print(p.caps,67,106,10)
 print("stim "..p.stim,92,106,11)
 if st=="combat" then
  print(ph=="p" and "ap" or "enemy turn",2,114,ph=="p" and 12 or 8)
  if (ph=="p") for i=1,maxap() do rectfill(12+i*6,114,16+i*6,118,i<=p.ap and 12 or 1) end
  print(ph=="p" and "z fire "..wd[p.w][1].."(3ap) x menu" or "",2,121,6)
  if menu then
   rectfill(70,72,126,102,0) rect(70,72,126,102,12)
   for i,s in ipairs({"next target","stimpak (2ap)","end turn"}) do
    print((i==mi and ">" or " ")..s,72,66+i*9,i==mi and 10 or 7)
   end
  end
 else
  print(aname[area],2,114,6)
  print("z talk  x inventory",2,121,5)
 end
end

function wrap(s,w)
 local l,line_={},""
 for wd_ in all(split(s," ",false)) do
  if (#line_+#wd_+1>w) add(l,line_) line_=""
  line_..=(line_=="" and "" or " ")..wd_
 end
 add(l,line_) return l
end

function drawtalk()
 rectfill(2,40,125,103,0) rect(2,40,125,103,9)
 local y=43
 for l in all(wrap(dlg.text,30)) do print(l,5,y,7) y+=7 end
 y+=3
 for i,o in ipairs(dlg.o) do
  print((i==di and ">" or " ")..o[1],5,y,i==di and 10 or 6) y+=7
 end
end

function drawinv()
 rectfill(10,14,117,100,0) rect(10,14,117,100,9)
 print("inventory",14,18,10)
 for i=1,4 do print(sn_[i].." "..p.st[i],86,18+i*8,6) end
 print("armor -"..p.arm,86,62,6)
 print("scrap "..p.scrap,86,70,6)
 print("xp "..p.xp.."/"..p.lv*100,86,78,6)
 for i,o in ipairs(invlist()) do print((i==ii and ">" or "")..o[1],14,22+i*9,i==ii and 10 or 7) end
 print("z use/equip  x close",14,92,5)
end

function drawcreate()
 for i=1,30 do pset((i*37)%128,(i*53)%128,5) end
 print("\^w\^tcreate wanderer",4,8,9)
 for i=1,4 do
  local y=30+i*12
  if (i==si) rectfill(14,y-2,112,y+6,1)
  print(({"strength","agility","perception","charisma"})[i],20,y,7)
  print("< "..p.st[i].." >",80,y,i==si and 10 or 6)
 end
 print("points left: "..pts,30,96,pts>0 and 11 or 6)
 if (pts==0 and t%40<28) oprint("z: enter the wasteland",20,110,10)
end

function drawintro()
 for i=1,40 do pset((i*37+t/(1+i%3))%128,(i*53)%128,i%3==0 and 7 or 13) end
 dspr("p_rock",64,34,3)
 print("\^w\^tcinder",40,62,9)
 oprint("the colony is dying of thirst.",6,78,7)
 oprint("find the purifier core.",18,86,7)
 oprint("talk, trade, fight, survive.",8,94,9)
 if (t%40<28) oprint("z: begin",48,108,11)
end
