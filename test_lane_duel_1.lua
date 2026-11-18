-- bot test: simple policy, hp kept topped up, picks first reward; screenshots every 30f
local u0,d0=_update60,_draw
tf,press=0,nil
btn=function() return false end
btnp=function(i) return i==press end
function danger(x)
 for e in all(en) do
  if e.it then
   for c in all(cells(e)) do
    if c==x then return true end
   end
  end
 end
end
function decide()
 if (st=="intro" or st=="reward" or st=="slot") return 4
 if (st!="fight") return nil
 local f=p.f
 if danger(p.x) then
  for d in all({-1,1}) do if (free(p.x+d) and not danger(p.x+d)) return d<0 and 0 or 1 end
 end
 local near,nd=nil,99
 for e in all(en) do if (abs(e.x-p.x)<nd) near,nd=e,abs(e.x-p.x) end
 if (near and sgn(near.x-p.x)!=f) return 5
 for i,c in ipairs(deck) do
  if c.cd==0 and (c.k==1 and at(p.x+f) or c.k==2 and (at(p.x+f) or at(p.x+2*f)) or c.k==3 and nd>1 or c.k==6 and (at(p.x-1) or at(p.x+1))) then si=i return 4 end
 end
 if (near and nd>1 and free(p.x+f)) return f<0 and 0 or 1
 si=#deck+1 return 4
end
_update60=function()
 tf+=1 press=nil
 if (st=="fight") p.hp=p.mhp
 if (tf%20==0) press=decide()
 u0()
end
_draw=function()
 d0()
 if tf%30==0 then extcmd("set_filename","ld_"..tf) extcmd("screen",0,1) end
end
