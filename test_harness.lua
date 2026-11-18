-- test harness (voidstorm_test.p8 only): bot input, scripted campaign, screenshots
-- -p arcade : bot plays arcade from wave 4
-- -p camp   : scripted campaign actions + bot-played missions incl. flagship
local d,u,ng,nc=_draw,_update60,newgame,newcamp
local mode=stat(6)
tf,step=0,0
btn=function(i)
 if (st!="play") return false
 if (i==4) return true
 if (i==0) return sin(tf/170)<-.3
 if (i==1) return sin(tf/170)>.3
 if (i==2) return tf%400<60
 return false
end
btnp=function(i)
 if (st=="title") return tf>120 and i==(mode=="camp" and 4 or 5)
 if (st=="play") return i==5 and tf%700==350
 return false
end
newgame=function() ng() wave=3 p.lives=99 end
newcamp=function() nc() p.lives=99 c.cr=500 c.pool=5 end
steps={
 function() c.sel=2 c.m,c.mi=acts(pl[2]),1 end,
 function() c.m=nil pl[2].known=true c.sel=2 c.m,c.mi=acts(pl[2]),1 end,
 function() local a=c.m c.m=nil a[1][2]() end,
 function() c.sel=1 c.m,c.mi=acts(pl[1]),1 end,
 function() c.m=nil c.g={9,6,3} mission{k="convoy",n=2,lv=1} end,
 function() mission{k="raid",n=1,lv=1,q=pl[1]} end,
 function()
  for h in all(pl) do
   if h.t==4 then h.known=true mission{k="assault",n=1,lv=1,q=h} return end
  end
 end,
 function() if (st=="map") endturn() end,
 function() c.aut=100 c.sel=1 c.m,c.mi=acts(pl[1]),1 end,
 function() c.m=nil mission{k="war",n=1,lv=5,boss=2} end,
}
_update60=function()
 tf+=1
 if mode=="camp" and st=="map" and tf%120==0 then
  step+=1
  if (steps[step]) steps[step]()
 end
 if (st=="map") c.hold=false
 u()
end
_draw=function()
 d()
 if tf%60==0 then
  extcmd("set_filename",mode.."_"..tf)
  extcmd("screen",0,1)
 end
end
