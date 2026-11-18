-- bot test: idle blue bugs attack nearest red within 70 or go capture the nearest non-blue pile;
-- also exercises the real select/order input once. screenshots every 60f; logs result.
local u0,d0=_update60,_draw
tf=0
local pz=nil
btn=function() return false end
btnp=function(i)
 if (st=="intro" or st=="next") return i==4 and tf%30==0
 return i==pz
end
_update60=function()
 tf+=1 pz=nil
 if st=="play" then
  if tf==120 then cx,cy=60,60 pz=4 end
  if tf==122 then cx,cy=70,60 pz=4 end
  if tf%45==0 then
   for b in all(bugs) do
    if b.sd==1 and not b.tg and not b.tx then
     local e,ed=nil,70
     for o in all(bugs) do if (o.sd==2 and dist(b,o)<ed) e,ed=o,dist(b,o) end
     if e then b.tg=e
     else
      local p,pd=nil,999
      for q in all(piles) do if (q.o!=1 and dist(b,q)<pd) p,pd=q,dist(b,q) end
      if (p) b.tx,b.ty=p.x,p.y
     end
    end
   end
  end
 end
 if (st=="over" or st=="win") and not lg then lg=true printh("seed "..(seed or 0)..": "..st.." battle "..lv.." blue "..side(1),"bb_log") end
 u0()
end
_draw=function()
 d0()
 if (tf%60==0 and shots_on) extcmd("set_filename","bb_"..tf) extcmd("screen",0,1)
end
