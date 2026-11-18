-- headless logic test: pico8 -x voidstorm_logic.p8
function show(tag) printh(tag..": yr="..c.yr.." cr="..c.cr.." g="..c.g[1]..","..c.g[2]..","..c.g[3].." pr="..c.pr[1]..","..c.pr[2]..","..c.pr[3].." pool="..c.pool.." tax="..c.tax.." aut="..c.aut.." st="..st.." msg="..c.msg) end
srand(1)
_init()
newcamp() show("start")
local free for q in all(pl) do if q.t!=4 and not q.own then free=q break end end
free.known=true
local a=acts(free) printh("menu free: "..a[1][1]) a[1][2]() show("colonize") printh(" free pop="..free.pop.." own="..tostr(free.own))
c.g={10,6,3}
mission{k="convoy",n=2,lv=1} printh(" mission st="..st.." fr.hp="..fr.hp)
score+=400 fr.hp=7 missionend(true) show("convoy win hp7")
mission{k="convoy",n=2,lv=1} c.g={5,5,5} fr.hp=0 missionend() show("convoy lost")
mission{k="raid",n=2,lv=1,q=free} missionend(true) show("raid win") printh(" free pop="..free.pop)
mission{k="raid",n=2,lv=1,q=free} p.lives-=1 missionend(true) show("raid w/ death") printh(" free pop="..free.pop)
local hv for q in all(pl) do if q.t==4 then hv=q end end
if hv then mission{k="assault",n=3,lv=3,boss=1,q=hv} missionend(true) show("assault") printh(" hive now type="..hv.t) end
for i=1,6 do
 st="map" mis=nil
 endturn() show("endturn"..i)
end
c.aut=100 local h=acts(pl[1]) printh("haven menu last: "..h[#h][1])
mission{k="war",n=4,lv=5,boss=2}
wave=3 spawnwave() printh("war wave4 boss.f="..tostr(boss and boss.f).." hp="..(boss and boss.hp or -1))
missionend(true) printh("after war st="..st)
newgame() printh("arcade c="..tostr(c).." mis="..tostr(mis))

extcmd("shutdown")
