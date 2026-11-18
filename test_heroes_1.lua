-- bot test: fights map stacks with ai on both sides, visits town, then the capital; screenshots every 45f
local u0,d0=_update60,_draw
tf,nb=0,0
btnp=function(i) return st=="intro" and i==4 and tf>20 end
btn=function() return false end
function nearest_e()
 local b,bd,bk
 for k,o in pairs(obj) do
  if o.k=="e" then
   local x,y=k%mw,k\mw
   local d=abs(x-h.x)+abs(y-h.y)
   if (not b or d<bd) b,bd,bk=o,d,k
  end
 end
 return b,bk
end
_update60=function()
 tf+=1
 if st=="map" and tf%90==0 then
  if nb==2 then
   opentown()
  elseif nb>=4 then
   army={{k=1,n=200},{k=2,n=80},{k=3,n=40},{k=4,n=20},{k=5,n=6}}
   h.x,h.y=19,10 reveal() bx,by=20,10 startbattle(obj[key(20,10)])
  else
   local o,k=nearest_e()
   if o then
    h.x,h.y=k%mw-1,k\mw reveal() bx,by=k%mw,k\mw
    for a in all(army) do a.n+=10 end
    startbattle(o)
   end
  end
 elseif st=="town" and tf%30==0 then
  ti=6 btnp=function(i) return i==4 end updtown() updtown() btnp=function() return false end
  if (tf%180==0) st="map" nb+=1
 elseif st=="battle" and cur.sd==1 and tf%15==0 then
  local was=round
  aimove(cur) finish()
  if (st=="map") nb+=1
 elseif st=="cache" then st="map" end
 u0()
end
_draw=function()
 d0()
 if tf%45==0 then extcmd("set_filename","hr_"..tf) extcmd("screen",0,1) end
end
