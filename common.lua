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

function whiteout()
 for c=1,15 do pal(c,7) end
end

-- ===== vfx =====
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

function pop(x,y,txt,c)
 add(pops,{x=x,y=y,s=txt,l=40,c=c or 7})
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
