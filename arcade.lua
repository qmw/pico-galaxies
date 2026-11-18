-- pico galaxies: title screen + arcade shooter (voidstorm.p8)

et={
 drone={hp=3,s={"dra","drb"},pts=100,r=6,an=6},
 saucer={hp=7,s={"saa","sab"},pts=250,r=7,an=10},
 diver={hp=2,s={"div"},pts=150,r=6},
 mine={hp=5,s={"mine"},pts=200,r=6},
 ast={hp=9,s={"ast"},pts=50,r=7},
}

function _init()
 cartdata("voidstorm_krea2")
 hi=dget(0)
 stars={}
 for i=1,70 do
  add(stars,{x=rnd(128),y=rnd(128),z=1+flr(rnd(3))})
 end
 plx,ply=90,20
 t,spd,shake,flash,hs=0,1,0,0,0
 parts,rings,fx,pops={},{},{},{}
 st="title"
 music(0)
end

modes={{"arcade"},{"colony defense","original_colony_defense_1.p8"},
 {"colonization","colonization_1.p8"},{"survivors","survivors_1.p8"},{"heroes","heroes_1.p8"},{"lane duel","lane_duel_1.p8"},{"grid tactics","grid_tactics_1.p8"},{"conquest","conquest_1.p8"},{"bug battle","bug_battle_1.p8"},{"hex lords","hex_territory_1.p8"},{"wasteland","wasteland_1.p8"},{"mmo rpg","mmo_rpg_1.p8"}}

function newgame()
 p={x=64,y=110,vx=0,vy=0,pw=1,shield=0,inv=90,
  lives=3,bombs=2,cd=0,bank=0,dead=0}
 bul,ebul,en,items,q={},{},{},{},{}
 parts,rings,fx,pops={},{},{},{}
 score,combo,ctime,wave,wt=0,1,0,0,30
 boss,banner,bt=nil,"",0
 st="play"
 sfx(8)
end

-- ===== spawning =====
function spawnwave()
 wave+=1 dif=wave
 bt=90 spd=4
 if wave%5==0 then
  banner="warning!" sfx(9)
  boss={x=64,y=-40,hp=160+dif*30,t=0,fl=0,ph=0,dead=0}
  boss.mhp=boss.hp
  return
 end
 banner="wave "..wave
 sfx(8)
 local n=5+dif*2
 for i=1,n do
  local r,k=rnd(),"drone"
  if dif>1 and r<.22 then k="diver"
  elseif dif>2 and r<.40 then k="saucer"
  elseif dif>3 and r<.52 then k="mine"
  elseif r<.65 then k="ast" end
  add(q,{d=40+i*(28-min(dif,12)),k=k})
 end
 -- drone squadrons
 local sx=24+rnd(80)
 for i=0,3 do add(q,{d=20+i*10,k="drone",x=sx}) end
end

function spawn(k,x)
 local d=et[k]
 local e={k=k,x=x or 12+rnd(104),y=-12,hp=d.hp+flr(dif/4),t=flr(rnd(60)),fl=0}
 e.x0=e.x
 if k=="saucer" then e.ty=16+rnd(40) end
 if k=="ast" then e.vx=rnd(.6)-.3 e.vy=.5+rnd(.6) end
 if k=="diver" then e.y=-10 e.vy=0 e.vx=0 end
 add(en,e)
end

function eshoot(x,y,a,s)
 add(ebul,{x=x,y=y,vx=cos(a)*s,vy=sin(a)*s,t=0})
end

function aim(x,y)
 return atan2(p.x-x,p.y-y)
end

-- ===== update =====
function _update60()
 t+=1
 if hs>0 then hs-=1 return end
 shake=max(0,shake-.4) flash=max(0,flash-1)
 spd+=(1-spd)*.03
 for s in all(stars) do
  s.y+=s.z*.35*spd
  if s.y>128 then s.y=0 s.x=rnd(128) end
 end
 ply+=.04*spd
 if ply>170 then ply=-40 plx=20+rnd(88) end
 updvfx()
 if st=="title" then
  -- mode menu: each planet style is its own cart
  sel=sel or 1
  if (btnp(2)) sel=(sel-2)%#modes+1
  if (btnp(3)) sel=sel%#modes+1
  if btnp(4) or btnp(5) then
   if sel==1 then newgame() else load(modes[sel][2]) end
  end
 elseif st=="play" then
  updplay()
 else
  if t>60 and btnp(5) then st="title" t=0 music(0) end
 end
end

function updplay()
 if bt>0 then bt-=1 end
 if ctime>0 then ctime-=1 else combo=1 end
 updplayer()
 -- spawn queue
 for i=#q,1,-1 do
  local s=q[i] s.d-=1
  if s.d<=0 then spawn(s.k,s.x) deli(q,i) end
 end
 if #q==0 and #en==0 and not boss then
  wt-=1
  if wt<=0 then spawnwave() wt=120 end
 end
 upden()
 if boss then updboss() end
 updbullets()
 upditems()
end

function updplayer()
 if p.dead>0 then
  p.dead-=1
  if p.dead==0 then
   if p.lives<=0 then
    st="over" t=0
    if score>hi then hi=score dset(0,hi) end
    music(-1)
   else
    p.x,p.y,p.inv=64,110,150
   end
  end
  return
 end
 local dx,dy=0,0
 if btn(0) then dx=-1 end
 if btn(1) then dx=1 end
 if btn(2) then dy=-1 end
 if btn(3) then dy=1 end
 p.vx+=(dx*1.8-p.vx)*.3
 p.vy+=(dy*1.8-p.vy)*.3
 p.x=mid(6,p.x+p.vx,122)
 p.y=mid(10,p.y+p.vy,120)
 p.bank+=(dx-p.bank)*.2
 if p.inv>0 then p.inv-=1 end
 -- engine trail
 if t%2==0 then
  part(p.x-3+rnd(1),p.y+8,rnd(.4)-.2,1+rnd(1),6+rnd(4),{7,10,9,8,2},0,1)
  part(p.x+3+rnd(1),p.y+8,rnd(.4)-.2,1+rnd(1),6+rnd(4),{7,10,9,8,2},0,1)
 end
 -- fire
 p.cd-=1
 if btn(4) and p.cd<=0 then
  p.cd=6 p.mf=3 sfx(0)
  local w=p.pw
  shot(p.x-3,p.y-6,0) shot(p.x+3,p.y-6,0)
  if w>=2 then shot(p.x-5,p.y-4,-.4) shot(p.x+5,p.y-4,.4) end
  if w>=3 then shot(p.x-7,p.y-2,-.9) shot(p.x+7,p.y-2,.9) end
  if w>=4 then shot(p.x,p.y-8,0,1) end
 end
 -- bomb
 if btnp(5) and p.bombs>0 then
  p.bombs-=1 flash=8 shake=8 sfx(6)
  ring(p.x,p.y,4,8,7,30) ring(p.x,p.y,2,6,12,30)
  for b in all(ebul) do sparks(b.x,b.y,2,{12,7}) end
  ebul={}
  for e in all(en) do hurt(e,12) end
  if boss then boss.hp-=30 boss.fl=6 end
  p.inv=max(p.inv,60)
 end
end

function shot(x,y,vx,big)
 add(bul,{x=x,y=y,vx=vx,vy=-6,big=big})
end

function hurt(e,d)
 e.hp-=d e.fl=4
 if e.hp<=0 and not e.dead then
  e.dead=true
  kill(e)
 end
end

function kill(e)
 local d=et[e.k]
 explode(e.x,e.y,e.k=="ast" and 1 or 1+flr(rnd(2)))
 local pts=d.pts*combo
 score+=pts
 pop(e.x,e.y-6,pts..(combo>1 and " x"..combo or ""),combo>1 and 10 or 7)
 combo=min(combo+1,8) ctime=90
 if e.k=="mine" then
  for i=0,7 do eshoot(e.x,e.y,i/8+t/100,1) end
  ring(e.x,e.y,3,3,8,15)
 end
 if e.k=="ast" then
  for i=1,6 do
   local a=rnd()
   part(e.x,e.y,cos(a)*2,sin(a)*2,30,{4,4,5,2},1.5,3)
  end
 end
 if rnd()<.14 then
  local r=rnd()
  add(items,{x=e.x,y=e.y,k=r<.6 and "pow" or r<.85 and "shd" or "bmb",t=0})
 end
 del(en,e)
end

function upden()
 for e in all(en) do
  e.t+=1
  if e.fl>0 then e.fl-=1 end
  local k=e.k
  if k=="drone" then
   e.y+=.55+dif*.03
   e.x=e.x0+sin(e.t/100)*22
   if dif>2 and e.t%140==70 then eshoot(e.x,e.y+4,.75,1.1) sfx(5) end
  elseif k=="saucer" then
   if e.y<e.ty then e.y+=.8
   else
    e.x=e.x0+sin(e.t/180)*30
    if e.t%max(30,70-dif*3)==0 then
     local a=aim(e.x,e.y)
     for i=-1,1 do eshoot(e.x,e.y+5,a+i*.04,1.3) end
     sfx(5)
     ring(e.x,e.y+5,1,1,11,8)
    end
    if e.t>600 then e.y+=1.2 end
   end
  elseif k=="diver" then
   if e.t<50 then
    e.y+=(14-e.y)*.08
    e.x+=(p.x-e.x)*.02
   else
    if e.vy==0 then
     local a=aim(e.x,e.y)
     e.vx,e.vy=cos(a)*3.2,sin(a)*3.2
     sfx(5)
    end
    e.x+=e.vx e.y+=e.vy
    part(e.x,e.y-7,0,-.5,10,{10,9,8,2},1,2)
   end
  elseif k=="mine" then
   e.y+=.35 e.x=e.x0+sin(e.t/240)*8
  elseif k=="ast" then
   e.x+=e.vx e.y+=e.vy
  end
  if e.y>140 or e.x<-20 or e.x>148 then del(en,e) end
  -- ram player
  if p.dead==0 and hit(e.x,e.y,et[k].r,p.x,p.y,3) then
   phit() hurt(e,99)
  end
 end
end

function phit()
 if p.inv>0 or p.dead>0 then return end
 if p.shield>0 then
  p.shield=0 p.inv=60
  sparks(p.x,p.y,20,{12,7,1})
  ring(p.x,p.y,10,2,12,12)
  sfx(4) shake=4
  return
 end
 p.lives-=1
 explode(p.x,p.y,3)
 sparks(p.x,p.y,30,{7,12,6,13},4)
 p.pw=max(1,p.pw-1)
 p.dead=90 hs=8 flash=4
 sfx(4)
end

function updboss()
 local b=boss
 b.t+=1
 if b.fl>0 then b.fl-=1 end
 if b.dead>0 then
  b.dead+=1
  if b.dead%5==0 then
   explode(b.x+rnd(28)-14,b.y+rnd(28)-14,1+flr(rnd(2)))
  end
  shake=max(shake,2)
  if b.dead>100 then
   explode(b.x,b.y,4)
   for i=1,3 do ring(b.x,b.y,i*4,4+i,({7,10,8})[i],40) end
   flash=10 hs=20
   score+=5000*combo
   pop(b.x,b.y,"+"..(5000*combo),10)
   for i=0,2 do add(items,{x=b.x-12+i*12,y=b.y,k=({"pow","shd","bmb"})[i+1],t=0}) end
   boss=nil wt=150
  end
  return
 end
 if b.y<30 then b.y+=.5 return end
 local rage=b.hp<b.mhp/2
 b.x=64+sin(b.t/(rage and 160 or 260))*36
 b.y=30+sin(b.t/120)*4
 local ph=flr(b.t/240)%3
 local f=b.t%240
 if ph==0 then
  -- spiral
  if f%(rage and 3 or 5)==0 then
   eshoot(b.x,b.y+6,b.t/45,1)
   if rage then eshoot(b.x,b.y+6,b.t/45+.5,1) end
  end
 elseif ph==1 then
  -- aimed fans
  if f%40==0 then
   local a=aim(b.x,b.y)
   for i=-3,3 do eshoot(b.x,b.y+10,a+i*.035,1.5) end
   sfx(5)
  end
 else
  -- ring bursts + escort drones
  if f%60==0 then
   for i=0,15 do eshoot(b.x,b.y,i/16+f/600,.9) end
   ring(b.x,b.y,6,3,14,14)
   sfx(5)
  end
  if f==120 then spawn("drone",b.x-20) spawn("drone",b.x+20) end
 end
 if rage and t%6==0 then
  part(b.x+rnd(24)-12,b.y+rnd(16)-8,0,-.5,25,{5,5,1},2,2)
 end
 if p.dead==0 and hit(b.x,b.y,13,p.x,p.y,3) then phit() end
end

function updbullets()
 for b in all(bul) do
  b.x+=b.vx b.y+=b.vy
  if b.y<-8 then del(bul,b) else
   local dmg=b.big and 2 or 1
   for e in all(en) do
    if hit(b.x,b.y,2,e.x,e.y,et[e.k].r) then
     sparks(b.x,b.y,2,{7,12})
     sfx(7)
     hurt(e,dmg) del(bul,b) break
    end
   end
   if boss and boss.y>=20 and boss.dead==0 and hit(b.x,b.y,2,boss.x,boss.y,13) then
    boss.hp-=dmg boss.fl=3
    sparks(b.x,b.y,2,{7,8,14})
    del(bul,b)
    if boss.hp<=0 then
     boss.dead=1 ebul={} hs=10
     sfx(2)
    end
   end
  end
 end
 for b in all(ebul) do
  b.x+=b.vx b.y+=b.vy b.t+=1
  if b.x<-6 or b.x>134 or b.y<-6 or b.y>134 then del(ebul,b)
  elseif p.dead==0 and hit(b.x,b.y,1,p.x,p.y,2) then
   del(ebul,b) phit()
  end
 end
end

function upditems()
 for it in all(items) do
  it.t+=1
  it.y+=.5
  local dx,dy=p.x-it.x,p.y-it.y
  if p.dead==0 and abs(dx)<28 and abs(dy)<28 then
   it.x+=dx*.08 it.y+=dy*.08
  end
  if t%6==0 then part(it.x+rnd(8)-4,it.y+rnd(8)-4,0,-.3,12,{7,10},0,1) end
  if p.dead==0 and hit(it.x,it.y,4,p.x,p.y,6) then
   local k=it.k
   if k=="pow" then
    if p.pw<4 then p.pw+=1 pop(it.x,it.y,"power up!",10)
    else score+=1000 pop(it.x,it.y,"+1000",10) end
   elseif k=="shd" then p.shield=1 pop(it.x,it.y,"shield!",12)
   else p.bombs=min(p.bombs+1,5) pop(it.x,it.y,"bomb!",8) end
   ring(it.x,it.y,2,2,7,10)
   sfx(3) del(items,it)
  elseif it.y>136 then del(items,it) end
 end
end

-- ===== draw =====
function _draw()
 cls(0)
 local sx,sy=rnd(shake)-shake/2,rnd(shake)-shake/2
 camera(sx,sy)
 drawbg()
 if st=="title" then drawtitle()
 else
  drawplay()
  if st=="over" then drawover() end
 end
 camera()
 if flash>0 then
  -- full-screen flash: draw bright, then fade
  -- dithered flash (no full-white frames)
  fillp(flash>5 and 0b0101101001011010 or 0b0111111111011111)
  rectfill(0,0,127,127,flash>5 and 7 or 12)
  fillp()
 end
end

function drawbg()
 -- planet drawn with a dimmed palette so it reads as backdrop
 for c,d in pairs({[7]=13,[14]=2,[15]=13,[9]=4,[10]=9,[8]=2,[13]=1,[6]=13,[12]=1,[2]=1,[4]=2}) do pal(c,d) end
 dspr("pla",plx,ply,1.25)
 pal()
 for s in all(stars) do
  local c=({1,13,7})[s.z]
  if spd>1.5 then
   line(s.x,s.y,s.x,s.y-s.z*spd*1.5,c)
  else pset(s.x,s.y,c) end
 end
end

function drawplay()
 for it in all(items) do
  local bob=sin(it.t/40)*1.5
  circ(it.x,it.y+bob,6+sin(it.t/20),it.t%8<4 and 7 or 13)
  dspr(it.k,it.x,it.y+bob)
 end
 for e in all(en) do
  local d=et[e.k]
  local fr=d.s[1]
  if d.an then fr=d.s[flr(e.t/d.an)%#d.s+1] end
  local fx_,fy_=false,false
  if e.k=="ast" or e.k=="mine" then
   local f=flr(e.t/(e.k=="mine" and 6 or 12))%4
   fx_=f==1 or f==2 fy_=f>=2
  end
  -- generated diver faces up; flip so it dives nose-first
  if e.k=="diver" then fy_=true end
  if e.k=="diver" and e.t<50 and e.t%10<5 then
   line(e.x,e.y+8,e.x,127,2)
  end
  if e.fl>0 then whiteout() end
  local s=1
  if e.k=="mine" then s=1+sin(e.t/30)*.08 end
  dspr(fr,e.x,e.y,s,fx_,fy_)
  pal()
  if e.k=="mine" and e.t%30<15 then circfill(e.x,e.y,1,8) end
 end
 if boss then drawboss() end
 -- enemy bullets
 for b in all(ebul) do
  local c=b.t%8<4 and 8 or 14
  circfill(b.x,b.y,2,c)
  pset(b.x,b.y,7)
 end
 -- player bullets
 for b in all(bul) do
  if b.big then
   rectfill(b.x-1,b.y-3,b.x+1,b.y+3,12)
   line(b.x,b.y-3,b.x,b.y+3,7)
  else
   line(b.x,b.y-2,b.x,b.y+2,12)
   pset(b.x,b.y-2,7)
  end
 end
 -- player
 if p.dead==0 and (p.inv==0 or t%6<3) then
  drawship(p.x,p.y)
  if p.mf and p.mf>0 then
   p.mf-=1
   circfill(p.x-3,p.y-7,1.5,7) circfill(p.x+3,p.y-7,1.5,7)
  end
  if p.shield>0 then
   for i=0,15 do
    local a=i/16+t/120
    if (i+t\4)%3>0 then
     pset(p.x+cos(a)*11,p.y+sin(a)*11,i%2==0 and 12 or 7)
    end
   end
  end
 end
 drawvfx()
 drawhud()
end

function drawboss()
 local b=boss
 if b.fl>0 then whiteout() end
 dspr("boss",b.x,b.y)
 pal()
 -- pulsing eye glow
 local r=2+sin(t/30)
 circ(b.x,b.y-1,r+2,b.hp<b.mhp/2 and 8 or 14)
 -- charge telegraph before fans
 local f=b.t%240
 if flr(b.t/240)%3==1 and f%40>30 then
  circ(b.x,b.y+10,(40-f%40),8)
 end
end

function drawhud()
 oprint(score,2,2,7)
 oprint("hi "..max(hi,score),64-#("hi "..max(hi,score))*2,2,6)
 if combo>1 then oprint("x"..combo,2,9,10) end
 for i=1,min(p.lives,5) do sspr(0,0,16,16,128-i*9,1,8,8) end
 for i=1,p.bombs do sspr(48,24,8,8,128-i*7,10,6,6) end
 for i=1,4 do
  rectfill(2+(i-1)*5,124,5+(i-1)*5,125,i<=p.pw and 12 or 1)
 end
 if boss and boss.dead==0 then
  local w=boss.hp/boss.mhp*100
  rect(13,16,114,20,5)
  rectfill(14,17,14+max(0,w),19,t%10<5 and boss.hp<boss.mhp/2 and 8 or 14)
 end
 if bt>0 then
  local y=50+(bt>80 and (bt-80)*3 or 0)
  local s=banner
  local c=banner=="warning!" and (t%8<4 and 8 or 7) or 7
  print("\^w\^t"..s,64-#s*4+1,y+1,1)
  print("\^w\^t"..s,64-#s*4,y,c)
 end
end

function drawtitle()
 -- demo fly-by of krea sprites
 local dt=t%300
 dspr(flr(t/6)%2==0 and "dra" or "drb",dt*.6-20,40+sin(t/90)*6)
 dspr(flr(t/10)%2==0 and "saa" or "sab",148-dt*.5,26+sin(t/70)*4)
 local s="pico galaxies"
 for i=1,#s do
  local ch=sub(s,i,i)
  local x=64-#s*4+(i-1)*8
  local y=50+sin(t/60+i/9)*3
  local c=({14,12,7,12})[flr(t/4+i)%4+1]
  print("\^w\^t"..ch,x+1,y+1,2)
  print("\^w\^t"..ch,x,y,c)
 end
 local by=76+sin(t/80)*2
 p=nil
 drawship(64,by)
 -- scrolling mode list: 4 rows visible
 local top=mid(1,(sel or 1)-1,max(1,#modes-3))
 for r=0,3 do
  local i=top+r
  local m=modes[i]
  if m then
   local s=(i==sel and (t%30<20 and "> " or "  ") or "  ")..m[1]
   oprint(s,30,98+r*7,i==sel and 10 or 6,1)
  end
 end
 if (top>1) oprint("\^:040e1f0000000000",96,98,13,1)
 if (top+3<#modes) oprint("\^:1f0e040000000000",96,119,13,1)
 if hi>0 then oprint("hi "..hi,64-#("hi "..hi)*2,2,10) end
end

function drawover()
 rectfill(14,44,113,84,0)
 rect(14,44,113,84,8)
 print("\^w\^tgame over",28,49,t%10<5 and 8 or 7)
 oprint("score "..score,64-#("score "..score)*2,64,7)
 local s=score>=hi and "new high score!" or "hi "..hi
 oprint(s,64-#s*2,71,10)
 if t>60 and t%40<28 then oprint("press x",50,78,6) end
end

