-- colony test harness: scripted steps every 120f + bot flying/firing; screenshots every 60f
local d,u=_draw,_update60
tf,step=0,0
btn=function(i)
 if (st~="play" and st~="voy") return false
 if (menu) return false
 if (i==4) return true
 if (i==0) return sin(tf/300)<-.3
 if (i==1) return sin(tf/300)>.3
 if (st=="play" and i==2) return cos(tf/220)<-.3
 if (st=="play" and i==3) return cos(tf/220)>.3
 return false
end
btnp=function(i) return st=="intro" and i==4 and tf>60 end
function build(k,x,y,tl)
 m[y][x]=tl res[2]+=6 res[3]+=3
 p.x,p.y=x*8+4,y*8+4 openmenu()
 for j,o in ipairs(opts) do if (o==k) menu.i=j end
 menu.h=false
 btnp=function(i) return i==4 end updmenu()
 btnp=function(i) return false end
end
steps={
 function() build(1,5,5,1) build(2,10,8,2) build(3,5,9,3) end,
 function() build(5,6,9,1) build(6,9,9,1) build(4,10,5,1) end,
 function() res={10,12,6} p.x,p.y=64,52 openmenu() menu.h=false end,
 function() menu=nil st,ci,hold0="cargo",1,false cg={4,5,3} end,
 function() voyage(1) end,
}
local mk={
 function() if (st=="tax") mi=2 updmkt_=updmkt btnp=function(i) return i==4 end updmkt() btnp=function() return false end end,
 function() mi=1 btnp=function(i) return i==4 end updmkt() btnp=function() return false end end,
 function() mi=5 btnp=function(i) return i==4 end updmkt() btnp=function() return false end end,
}
mstep=0
_update60=function()
 tf+=1
 if (st=="play") lives=9
 if (st=="play" or st=="cargo") and tf%120==0 and step<#steps then step+=1 steps[step]() end
 if (st=="voy" and vt<1200 and tf%400==0) vt=1200
 if (st=="mkt" or st=="tax") and tf%90==0 then mstep+=1 if (mk[mstep]) mk[mstep]() end
 if (st=="play" and mstep>=3 and tf%600==0 and war==0) lib=100 p.x,p.y=64,52 openmenu() menu.i=#opts menu.h=false btnp=function(i) return i==4 end updmenu() btnp=function() return false end
 u()
end
_draw=function()
 d()
 if tf%60==0 then extcmd("set_filename","col_"..tf) extcmd("screen",0,1) end
end
