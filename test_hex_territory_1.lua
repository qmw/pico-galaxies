-- bot test: on the player's turn, run the ai routine for blue's provinces; screenshots; logs result
local u0,d0=_update60,_draw
tf=0
btn=function() return false end
btnp=function(i) return st=="intro" and i==4 and tf>20 end
_update60=function()
 tf+=1
 if st=="play" and tf%20==0 then
  st,aq,at="ai",{},1
  for p in all(provs[1]) do add(aq,p) end
 end
 if (st=="over" or st=="win") and not lg then
  lg=true printh("seed "..(seed or 0)..": "..st.." turn "..turn.." land "..land(1).."/"..land(2).."/"..land(3).."/"..land(4),"hx_log")
 end
 if (st=="ai" and turn>60 and not lg) lg=true printh("seed "..(seed or 0)..": still going at turn 60, land "..land(1).."/"..land(2).."/"..land(3).."/"..land(4),"hx_log")
 u0()
end
_draw=function()
 d0()
 if (tf%60==0 and shots_on) extcmd("set_filename","hx_"..tf) extcmd("screen",0,1)
end
