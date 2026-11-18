-- scripted test: drives the real order/colony/market functions; screenshots every 60f
local d,u=_draw,_update60
tf,step=0,0
btn=function() return false end
btnp=function(i) return st=="intro" and i==4 and tf>30 end
function press(k) btnp=function(i) return i==k end _update60_() btnp=function() return false end end
function pick(label)
 for i,o in ipairs(opts) do
  if (sub(o[1],1,#label)==label) mi=i
 end
end
steps={
 function() -- sail ship west to the coast
  for i=1,6 do local s=ship if s.mv>0 and tl(s.x-1,s.y)==4 then move(s,s.x-1,s.y) end end
 end,
 function()
  for i,v in ipairs(units) do
   if v==ship then au=i end
  end
  openmenu(ship) pick("unload")
 end,
 function() press(4) end,
 function()
  for i,v in ipairs(units) do
   if v.k=="c" and not v.on then au=i end
  end
  ship.mv=0 openmenu(units[au]) pick("found")
 end,
 function() press(4) end,
 function() opencol(cols[1]) end,
 function() ci=9 press(4) ci=9 end,
 function() st="map" for i=1,4 do endturn() end end,
 function() ship.x,ship.y,ship.mv=mw-1,9,1 move(ship,mw,9) end,
 function() for i=1,2 do endturn() end end,
 function() mi=4 ship.g[4]=30 press(4) end,
 function() mi=7 cr+=200 press(4) end,
 function() mi=8 press(4) end,
 function() bells=9999 for i=1,3 do endturn() end openmenu(units[au] or ship) pick("declare") end,
 function() press(4) for i=1,3 do endturn() end end,
}
_update60_=u
_update60=function()
 tf+=1
 if st~="intro" and tf%120==0 and step<#steps then step+=1 steps[step]() end
 u()
end
_draw=function()
 d()
 if tf%60==0 then extcmd("set_filename","oc_"..tf) extcmd("screen",0,1) end
end
