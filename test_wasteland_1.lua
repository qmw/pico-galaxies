-- scripted playthrough: create char, quest, combat (bot), dog, gristle talk, core, win
local u0,d0=_update60,_draw
tf,step,press=0,0,nil
btn=function() return false end
btnp=function(i) return i==press end
function shot(n) extcmd("set_filename","wl_"..n) extcmd("screen",0,1) end
steps={
 function() newgame() p.st={4,5,5,9} pts=0 p.hp=mhp() st="explore" checkpoint() end,
 function() p.x,p.y=5,5 talk(ents[12]) end,
 function() shot("1orin") di=1 dlg.o[1][2]() end,
 function() area=2 p.x,p.y=7,5 checkpoint() end,
 function() if (st=="combat") shot("2combat") end,
 nil,nil,nil,nil,nil,nil,
 function()
  p.hp=mhp() area=2
  for e in all(ents) do
   if e.a==2 then e.alive=false end
  end
  dog.alive=true p.x,p.y=13,10 talk(dog)
 end,
 function() area=1 p.x,p.y=4,10 talk(ents[14]) end,
 function() shot("3pip") dlg.o[1][2]() end,
 function()
  area=3 p.x,p.y=12,5 checkpoint()
  for e in all(ents) do
   if e.a==3 and e.k!=4 then e.alive=false end
  end
 end,
 function() if (st=="talk") shot("4gristle") dlg.o[1][2]() end,
 function() p.x,p.y=13,3 press=nil end,
 function() p.x,p.y=12,2 st="explore" end,
 function() press=1 end,
 function() area=1 p.x,p.y=5,5 talk(ents[12]) end,
 function() shot("5core") dlg.o[1][2]() end,
 function() shot("6win") end,
}
_update60=function()
 tf+=1 press=nil
 if st=="combat" and ph=="p" and tf%8==0 then
  local e=foes[tg]
  if e and p.ap>=3 and hitch(e)>0 then press=4
  elseif e and p.ap>=1 and hitch(e)==0 then
   press=e.x<p.x and 0 or e.x>p.x and 1 or e.y<p.y and 2 or 3
  else p.ap=0 end
  p.hp=max(p.hp,10)
 end
 if tf%40==0 and step<#steps and st!="combat" then step+=1 if (steps[step]) steps[step]() end
 if (step==7 and st=="combat" and tf%40==0) shot("2combat_"..tf)
 if (st=="win" and not lg) lg=true printh("reached win: qdog="..qdog.." core="..tostr(p.core).." lv="..p.lv.." caps="..p.caps,"wl_log",true)
 u0()
end
