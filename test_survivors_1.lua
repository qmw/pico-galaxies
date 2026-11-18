-- bot test: circles, auto-picks upgrades, invulnerable via hp refill, time-skips to bosses; screenshots
local u0,d0=_update60,_draw
tf=0
btn=function(i)
 if (st=="lvup") return false
 local a=tf/300
 if (i==0) return cos(a)<-.3
 if (i==1) return cos(a)>.3
 if (i==2) return sin(a)<-.3
 if (i==3) return sin(a)>.3
 return false
end
btnp=function(i)
 if (st=="intro") return i==4 and tf>30
 if (st=="lvup") then hold=false return i==4 end
 return false
end
_update60=function()
 tf+=1
 if st=="play" or st=="lvup" then
  p.hp=mhp()
  if (tf==400) wl={3,2,2,2,2}
  if (tf==1500) clock=178*60
  if (tf==2700) clock=299*60
 end
 u0()
end
_draw=function()
 d0()
 if tf%150==0 then extcmd("set_filename","sv_"..tf) extcmd("screen",0,1) end
end
