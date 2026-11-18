-- bot test: each mech moves to a reachable cell that can hit a bug, fires; then ends turn. power kept up.
local u0,d0=_update60,_draw
tf=0
btn=function() return false end
btnp=function(i) return st=="intro" and i==4 and tf>20 end
function botmove(u)
 local r=reach(u,3)
 local best,bx,by,tx,ty=-1,u.x,u.y
 for k,_ in pairs(r) do
  local x,y=k%8,k\8
  local ox,oy=u.x,u.y u.x,u.y=x,y
  for b in all(us) do
   if b.sd==2 and canfire(u,b.x,b.y) and rnd()>best then best,bx,by,tx,ty=rnd(),x,y,b.x,b.y end
  end
  u.x,u.y=ox,oy
 end
 u.x,u.y=bx,by
 if (tx) fire(u,tx,ty)
 u.done=true
end
_update60=function()
 tf+=1
 if st=="play" then power=max(power,3) end
 if st=="play" and ph=="player" and tf%25==0 then
  local m_=nil
  for u in all(us) do if (u.sd==1 and not u.done) m_=u end
  if m_ then botmove(m_) else endturn() end
 end
 u0()
end
_draw=function()
 d0()
 if tf%40==0 then extcmd("set_filename","gt_"..tf) extcmd("screen",0,1) end
end
