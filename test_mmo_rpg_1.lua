-- scripted playthrough with a combat bot using the real ability code
local u0,d0=_update60,_draw
tf,step,botting=0,0,false
btn=function() return false end
btnp=function(i) return st=="intro" and i==4 and tf>20 end
function shot(n) extcmd("set_filename","mm_"..n) extcmd("screen",0,1) end
function bot()
 p.hp=max(p.hp,mhp_()*.5)
 if (not tg or tg.dead) autotarget(200)
 if not tg then return end
 local d=d2(tg,p)
 if d>14 then
  local a=atan2(tg.x-p.x,tg.y-p.y)
  if (d<60 and p.mp>=10 and not p.cast) useab(2) return
  if (not p.cast) p.x+=cos(a)*.9 p.y+=sin(a)*.9
 else
  useab(1)
  if (p.cd[4]==0 and p.mp>=20) useab(4)
 end
end
steps={
 function() p.x,p.y=44,84 talk(npcs[1]) end,
 function() shot("1quest") dl.f() st="play" end,
 function() p.x,p.y=96,40 botting=true end,
 false,false,false,false,false,false,false,false,
 function() shot("2fight") end,
 false,false,false,false,
 function() botting=false kills=6 q1=2 p.x,p.y=44,84 talk(npcs[1]) end,
 function() shot("3turnin") dl.f() st="play" p.xp=0 for i=1,3 do xp(p.lv*100) end end,
 function() talk(npcs[1]) end,
 function() shot("4king") dl.f() st="play" p.x,p.y=244,92 end,
 function() botting=true end,
 false,false,false,
 function() shot("5boss") end,
}
_update60=function()
 tf+=1
 if st=="play" and botting and tf%4==0 then bot() end
 if tf%45==0 and step<#steps and st!="intro" then step+=1 if (steps[step]) steps[step]() end
 if (st=="win" and not lg) lg=true shot("6win") printh("win: lv "..p.lv.." wi "..p.wi.." ai "..p.ai.." t "..tf,"mm_log",true)
 if (tf==5400 and not lg) printh("no win by frame 5400: dun="..tostr(dun).." boss hp "..(boss and boss.hp or -1),"mm_log",true)
 u0()
end
