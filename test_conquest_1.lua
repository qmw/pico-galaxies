-- bot test: the player faction uses the same decide() as the ai; screenshots every 60f; logs result
local u0,d0=_update60,_draw
tf=0
btn=function() return false end
btnp=function(i) return st=="intro" and i==4 and tf>20 end
_update60=function()
 tf+=1
 if st=="play" and tf%30==0 then
  for z in all(owned(1)) do if (not z.ac) decide(z,1) z.ac=true end
  endturn()
 end
 if (st=="over" or st=="win") and not lg then
  lg=true printh("seed "..(seed or 0)..": "..st.." turn "..turn.." "..why.." own="..#owned(1).."/"..#owned(2).."/"..#owned(3),"cq_log")
 end
 u0()
end
_draw=function()
 d0()
 if (tf%60==0 and shots_on) extcmd("set_filename","cq_"..tf) extcmd("screen",0,1)
end
