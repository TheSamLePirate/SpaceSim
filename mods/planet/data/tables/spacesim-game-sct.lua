-- SpaceSim / Aurore : systemes de jeu.
--   1. Evitement du relief par l'IA (chasseurs, bombardiers, navettes) : FSO ne connait pas le terrain.
--      Prediction de la trajectoire sur 3 s avec la carte d'altitude, cabrage proportionnel au danger,
--      plancher dur a 25 m. En multijoueur : serveur uniquement (positions transmises par le moteur).
--   2. Reapparition du joueur au-dessus de l'Aurore (FotG Respawner, solo), protege 3 s.
-- Tests : data/spacesim-aitest.flag (4 TIE poursuivent un joueur appat dans le canyon),
--         data/spacesim-noaiavoid.flag (meme test sans evitement, pour comparer).

local V=ba.createVector
local C=V(0,-80000,0)
local function length(v) return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z) end
local function unit(v) local d=length(v);if not (d>1e-6) then return V(0,0,1) end;return V(v.x/d,v.y/d,v.z/d) end
local function dot(a,b) return a.x*b.x+a.y*b.y+a.z*b.z end
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
local function ok(o) return o and o:isValid() end
local function log(m) if SPACESIM then SPACESIM.record('GAME '..m) end end
local function isServer() return not ba.MultiplayerMode or multi.isServer() end

GAME={}
local GM=GAME

-- height above the ground (m), or nil outside the map
local function agl(p)
    local g=SPACESIM.surface(p)
    if not g then return nil end
    return length(p-C)-length(g-C)
end

-- ------------------------------------------------------------------ 1. AI terrain avoidance
local AV={list={},nextList=0,events=0,lastLog=0}
local AVOID_TYPES={fighter=true,bomber=true,transport=true,['stealth fighter']=true}
local MARGIN=130      -- wanted clearance on the predicted trajectory (m)
local FLOOR=25        -- hard floor (m)

local function scriptedByCinematic(sh)
    local c=CINE and CINE.active and CINE.c
    if not c or not c.xw then return false end
    if c.handover then return ok(c.cargo) and c.cargo:getSignature()==sh:getSignature() end
    -- compare signatures: two Lua handles to the same ship are different userdata
    local sig=sh:getSignature()
    for _,x in ipairs(c.xw) do if ok(x) and x:getSignature()==sig then return true end end
    return ok(c.cargo) and c.cargo:getSignature()==sig
end

local function refreshList(now)
    AV.list={};AV.nextList=now+1
    for i=1,#mn.Ships do
        local sh=mn.Ships[i]
        if ok(sh) and not sh:isPlayer() and not sh:isDying() then
            local t=sh.Class and sh.Class.Type and sh.Class.Type.Name or ''
            if AVOID_TYPES[t:lower()] and not scriptedByCinematic(sh) then AV.list[#AV.list+1]=sh end
        end
    end
    if cf.fileExists('spacesim-aidebug.flag','data',true) then local n={};for _,x in ipairs(AV.list) do n[#n+1]=x.Name..'('..(x.Class.Type.Name)..')' end;log('AI_LIST '..table.concat(n,', ')) end
end

local function avoid(sh,dt)
    local p=sh.Position
    local up=unit(p-C)
    local phys=sh.Physics
    local vel=phys.Velocity
    local v=length(vel)
    if v<5 then return end
    local h0=agl(p)
    if not h0 or h0>2500 then return end
    -- clearance along the predicted trajectory (0.6, 1.2, 2, 3 s), the near future weighs more
    local cmin=h0
    for _,t in ipairs({0.6,1.2,2.0,3.0}) do
        local c=agl(p+vel*t)
        if c then cmin=math.min(cmin,c+(t-0.6)*12) end
    end
    local danger=clamp((MARGIN-cmin)/MARGIN,0,1)
    if danger<=0 and h0>FLOOR then return end
    AV.events=AV.events+1
    AV.per=AV.per or {};AV.per[sh.Name]=(AV.per[sh.Name] or 0)+1
    local o=sh.Orientation
    local f,u=o:getFvec(),o:getUvec()
    local climb=dot(f,up)
    -- pull up: rotate the nose (and the velocity) towards the sky, up to 1.6 rad/s
    local rate=1.6*danger*danger+0.4*danger
    if climb<0.55 then
        local nf=unit(f+up*(rate*dt*2.0))
        local nu=unit(u-nf*dot(u,nf))
        sh.Orientation=ba.createOrientationFromVectors(nf,nu)
        local vd=unit(vel)
        local nvd=unit(vd+up*(rate*dt*2.0))
        vel=nvd*v
    end
    -- hard floor: never below FLOOR metres, never sinking there
    if h0<FLOOR then
        sh.Position=p+up*(FLOOR-h0)
        local vv=dot(vel,up);if vv<0 then vel=vel-up*vv end
    end
    phys.Velocity=vel
end

-- the AI gets the same speed envelope as the players (spacesim-flight-sct.lua): able to follow the climb
local BASEV={}
local function sstep(e0,e1,x) local t=clamp((x-e0)/(e1-e0),0,1);return t*t*(3-2*t) end
local function envelope(sh)
    local sig=sh:getSignature()
    local ph=sh.Physics
    local b=BASEV[sig]
    if not b then b={v=ph.VelocityMax.z,ab=ph.AfterburnerVelocityMax.z,last=-1};BASEV[sig]=b end
    local h=length(sh.Position-C)-80000
    local k=sstep(1000,16000,h)*(1-sstep(80000,91000,h))
    if math.abs(k-b.last)<0.01 then return end
    b.last=k
    local v=b.v+(4200-b.v)*k
    local m=ph.VelocityMax;ph.VelocityMax=V(m.x,m.y,v)
    local a=ph.AfterburnerVelocityMax;ph.AfterburnerVelocityMax=V(a.x,a.y,math.max(b.ab,v*b.ab/math.max(1,b.v)))
end
engine.addHook('On Simulation',function()
    if not (SPACESIM and SPACESIM.state and SPACESIM.state.active and SPACESIM.surface) then return end
    if not isServer() then return end
    if cf.fileExists('spacesim-noaiavoid.flag','data',true) then return end
    local now=mn.getMissionTime();local dt=ba.getMissionFrametime()
    if dt<=0 then return end
    if now>=AV.nextList then refreshList(now) end
    for _,sh in ipairs(AV.list) do
        if ok(sh) and not sh:isDying() then avoid(sh,dt);envelope(sh) end
    end
    if now-AV.lastLog>10 and AV.events>0 then
        local top={};for n,k in pairs(AV.per or {}) do top[#top+1]={n,k} end;table.sort(top,function(a,b) return a[2]>b[2] end)
        local t={};for i=1,math.min(3,#top) do t[#t+1]=top[i][1]..'='..top[i][2] end
        AV.lastLog=now;log(string.format('AI_AVOID ships=%d corrections=%d top: %s',#AV.list,AV.events,table.concat(t,' ')));AV.events=0;AV.per={}
    end
end)

-- ------------------------------------------------------------------ 2. respawn above the Aurore
-- FotG's Respawner (single player) respawns 1500 m above the place of death by default: inside or above
-- the canyon walls. Here: forced on, 260 m above and 350 m behind the cargo, same heading, 3 s protection.
local RS={next=0}
local function respawnPoint()
    local cargo=mn.Ships['Aurore']
    if not ok(cargo) then return nil end
    local cp=cargo.Position;local up=unit(cp-C)
    local cf_=cargo.Orientation:getFvec()
    local fh=unit(cf_-up*dot(cf_,up))
    local pos=cp+up*260-fh*350
    local h=agl(pos);if h and h<150 then pos=pos+up*(150-h) end
    return pos,ba.createOrientationFromVectors(fh,up)
end
engine.addHook('On Simulation',function()
    if not (SPACESIM and SPACESIM.state and SPACESIM.state.active) then return end
    if not (Respawner and Respawner.SetMission_Position) then return end
    local now=mn.getMissionTime()
    if now<RS.next then return end
    RS.next=now+0.5
    if not RS.hooked then
        RS.hooked=true
        Respawner:SetMission_Override(1)          -- the player chose respawning
        Respawner:SetMission_RespawnZeroSpeed(false)
        local orig=Respawner.RunShipRespawn
        Respawner.RunShipRespawn=function(self,ship,is_player,...)
            orig(self,ship,is_player,...)
            if is_player and ok(ship) then
                local _,ori=respawnPoint()
                local cargo=mn.Ships['Aurore']
                if ori then ship.Orientation=ori end
                if ok(cargo) then ship.Physics.Velocity=cargo.Physics.Velocity end
                ship:setFlag(true,'invulnerable');RS.unprotect=mn.getMissionTime()+3
                log(string.format('RESPAWN %s at %s',ship.Name,tostring(ship.Position)));GM.lastRespawn=mn.getMissionTime()
                if SPACESIM.state then SPACESIM.state.stopped=nil end
            end
        end
        log('RESPAWN hooked (FotG Respawner, override on)')
    end
    local pos,ori=respawnPoint()
    if pos then
        Respawner:SetMission_Position({pos.x,pos.y,pos.z})
        Respawner:SetMission_Orientation({p=ori.p,b=ori.b,h=ori.h})
    end
    if RS.unprotect and now>RS.unprotect then
        RS.unprotect=nil
        local p=hv.Player;local sh=p and p:isValid() and mn.Ships[tostring(p)]
        if ok(sh) then sh:setFlag(false,'invulnerable') end
    end
end)

-- multiplayer respawn (FSO): 2 km beside the respawn-priority ship (the Aurore), possibly inside the canyon walls.
-- Each client owns its ship's position: when my ship is a new object (respawned), I move it above the cargo.
local MR={}
engine.addHook('On Gameplay Start',function() MR.sig=nil end)
engine.addHook('On Simulation',function()
    if not (ba.MultiplayerMode and SPACESIM and SPACESIM.state and SPACESIM.state.active) then return end
    local p=hv.Player
    if not (p and p:isValid()) then return end
    local sig=p:getSignature()
    if MR.sig and sig~=MR.sig then
        local sh=mn.Ships[tostring(p)]
        local pos,ori=respawnPoint()
        if ok(sh) and pos then
            sh.Position=pos;sh.Orientation=ori
            local cargo=mn.Ships['Aurore'];if ok(cargo) then sh.Physics.Velocity=cargo.Physics.Velocity end
            log('MP_RESPAWN '..sh.Name..' moved above the Aurore')
        end
    end
    MR.sig=sig
end)

-- ------------------------------------------------------------------ AI test bench (data/spacesim-aitest.flag)
local AT=nil
local function valleyX(z) return 650*math.sin(z/2700)+180*math.sin(z/730) end
engine.addHook('On Gameplay Start',function() AT=nil;AV.list={};AV.nextList=0;RS.hooked=nil;RS.next=0 end)
engine.addHook('On Simulation',function()
    if not (SPACESIM and SPACESIM.state and SPACESIM.state.active and SPACESIM.surface) then return end
    local now=mn.getMissionTime()
    if AT==nil then
        AT=cf.fileExists('spacesim-aitest.flag','data',true) and {t0=now+1,z=-4800,crash=0} or false
        if AT then FLIGHT_EXTERNAL=true end
    end
    if not AT then return end
    local pl=mn.Ships['Red 1']
    if not ok(pl) then return end
    local dt=ba.getMissionFrametime()
    -- bait: the player flies the canyon at 80 m above the ground, 150 m/s, invulnerable
    -- zigzag towards the canyon walls, 35 m above the ground, 200 m/s
    AT.z=AT.z+200*dt
    local function path(z) return V(valleyX(z)+300*math.sin(z/420),2000,z) end
    local g=SPACESIM.surface(path(AT.z))
    if g then
        local up=unit(g-C);local pos=g+up*35
        local ga=SPACESIM.surface(path(AT.z+60)) or path(AT.z+60)
        local fwd=unit((ga+unit(ga-C)*35)-pos)
        pl.Position=pos;pl.Orientation=ba.createOrientationFromVectors(fwd,up);pl.Physics.Velocity=fwd*200
        pl:setFlag(true,'invulnerable')
    end
    if not AT.spawned and now>AT.t0 then
        AT.spawned=true;AT.ties={}
        local cls=tb.ShipClasses['TIE/ln Fighter']
        for k=1,4 do
            local zq=AT.z-900-k*120
            local qq=V(valleyX(zq)+(k%2==0 and 90 or -90),2000,zq)
            local gg=SPACESIM.surface(qq)
            if gg and cls then
                local up=unit(gg-C)
                local t=mn.createShip('TIE test '..k,cls,ba.createOrientationFromVectors(unit(pl.Position-gg),up),gg+up*(60+k*25),mn.Teams['Hostile'],false)
                if ok(t) then t:giveOrder(ORDER_ATTACK,pl);AT.ties[#AT.ties+1]=t end
            end
        end
        log(string.format('AITEST %d TIE launched, avoidance=%s',#AT.ties,tostring(not cf.fileExists('spacesim-noaiavoid.flag','data',true))))
    end
    if AT.spawned and not AT.done then
        local alive,minh=0,1e9
        for _,t in ipairs(AT.ties) do
            if ok(t) and not t:isDying() then alive=alive+1;local h=agl(t.Position);if h then minh=math.min(minh,h) end end
        end
        AT.minh=math.min(AT.minh or 1e9,minh)
        if now-(AT.lastLog or 0)>5 then AT.lastLog=now;log(string.format('AITEST t=%.0f alive=%d min_agl_now=%.0f',now-AT.t0,alive,minh)) end
        if now-AT.t0>60 then
            AT.done=true
            log(string.format('AITEST RESULT survivors=%d/%d min_agl=%.0f',alive,#AT.ties,AT.minh))
            SPACESIM.flush();SPACESIM.stop('mission_end')
        end
    end
end)

-- respawn test (data/spacesim-respawntest.flag): dive into the ground at t=3 s, the respawn must follow
local RT=nil
engine.addHook('On Gameplay Start',function() RT=nil end)
engine.addHook('On Simulation',function()
    if not (SPACESIM and SPACESIM.state and SPACESIM.state.active) then return end
    if RT==nil then RT=cf.fileExists('spacesim-respawntest.flag','data',true) and {} or false end
    if not RT then return end
    local now=mn.getMissionTime()
    local p=hv.Player;local sh=p and p:isValid() and mn.Ships[tostring(p)]
    if not ok(sh) then return end
    if now>3 and not RT.dived then
        if not RT.t then RT.t=now;FLIGHT_EXTERNAL=true end
        local up=unit(sh.Position-C)
        sh.Orientation=ba.createOrientationFromVectors(up*-1+V(0,0,0.3),V(0,0,1));sh.Physics.Velocity=up*-220
        if sh:isDying() or GM.lastRespawn then RT.dived=true;FLIGHT_EXTERNAL=nil;log('RESPAWNTEST crashed') end
    end
    if RT.dived and not sh:isDying() and not RT.back then
        RT.back=true;log(string.format('RESPAWNTEST alive again agl=%s hull=%.0f%%',tostring(agl(sh.Position)),100*sh.HitpointsLeft/sh.HitpointsMax))
    end
end)

