-- SpaceSim / Aurore : vol de type avion dans l'atmosphere (joueur local).
--
-- Commandes : ba.setControlMode(LUA_STEERING_CONTROLS). Le moteur nous rend les entrees brutes du joueur
-- (ci.Pitch / Heading / Bank) et applique celles que nous ecrivons a l'image suivante.
-- Translation : dans l'air, le script possede la vitesse (Physics.Velocity = PF_SCRIPTED_VELOCITY) :
-- poussee vers la consigne des gaz (temps d'acceleration de la table), amortissement lateral, gravite
-- radiale, portance, decrochage. Le tout est dose par la densite de l'air ; en orbite FSO reprend la main.
-- Tout est local au joueur : compatible multijoueur (chaque client pilote son propre vaisseau).
--
-- Modes (F10) : ARCADE    manche lateral = inclinaison commandee, virage coordonne automatique,
--                         mise a niveau automatique, un peu de lacet direct pour viser, pas de decrochage.
--               SIMULATION manche lateral = taux de roulis, touches/axe d'inclinaison = palonnier,
--                         gestion de l'energie, decrochage, facteur de charge limite.
-- Tests : data/spacesim-flightcal.flag (signes des commandes), data/spacesim-flighttest.flag (sequence).

local V=ba.createVector   -- own copy: scripts load alphabetically (flight before planet)
local C=V(0,-80000,0)
local R=80000
local G0=9.81
local function length(v) return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z) end
local function unit(v) local d=length(v);if not (d>1e-6) then return V(0,0,1) end;return V(v.x/d,v.y/d,v.z/d) end
local function dot(a,b) return a.x*b.x+a.y*b.y+a.z*b.z end
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
local function sstep(e0,e1,x) local t=clamp((x-e0)/(e1-e0),0,1);return t*t*(3-2*t) end
local function ok(o) return o and o:isValid() end
local function log(m) if SPACESIM then SPACESIM.record('FLIGHT_MODEL '..m) end end

-- Signes des commandes FSO (calibres par data/spacesim-flightcal.flag) :
-- ci.Pitch = SP * (cabrer), ci.Heading = SH * (lacet a droite), ci.Bank = SB * (roulis a droite)
local SP,SH,SB=-1,1,-1

FLIGHT={mode='arcade',active=false,warnT=0,noticeT=-99,stall=false,pull=false}
local F=FLIGHT
local CFG='spacesim-flight.cfg'

local function loadCfg()
    if cf.fileExists(CFG,'data',true) then
        local f=cf.openFile(CFG,'r','data');local m=f and f:read('*l');if f then f:close() end
        if m=='simulation' or m=='arcade' then F.mode=m end
    end
end
local function saveCfg()
    local f=cf.openFile(CFG,'w','data');if f then f:write(F.mode..'\n');f:close() end
end

local function playerShip()
    local p=hv.Player
    if not (p and p:isValid()) then return nil end
    local sh=mn.Ships[tostring(p)]
    if ok(sh) then return sh end
    return nil
end

-- the cinematic owns the player's ship until it hands over control
local function scriptedByCinematic()
    return CINE and CINE.active and CINE.c and not CINE.c.handover
end

-- air: 1 near the ground, 0 above 40 km (FSO space flight there)
local function airFactor(h) return 1-sstep(20000,40000,h) end
-- maximum speed envelope: table speed low down, very fast in the upper atmosphere (playable climb to orbit),
-- back to combat speed in orbit
local function speedEnvelope(h,vt)
    return vt+(4200-vt)*sstep(1000,16000,h)*(1-sstep(80000,91000,h))
end

-- ------------------------------------------------------------------ input shaping (gamepad + keyboard)
local IN={p=0,h=0,b=0}
local function shape(raw,old,dt)
    -- keyboard keys give 0/1: ramp them; gamepad axes: light expo, then the same filter
    local x=clamp(raw,-1,1)
    local digital=(x==0 or math.abs(x)==1)
    local target=digital and x or x*(0.35+0.65*math.abs(x))
    local rate=digital and 3.5 or 12
    return old+clamp(target-old,-rate*dt,rate*dt)
end

-- ------------------------------------------------------------------ HUD
local function hudText(txt,x,y,r,g,b,a)
    gr.setColor(r,g,b,a or 255);gr.drawString(txt,x,y)
end
engine.addHook('On HUD Draw',function()
    if not F.active then return end
    local w,h=gr.getScreenWidth(),gr.getScreenHeight()
    local now=mn.getMissionTime()
    if now-F.noticeT<3 then
        local t='VOL : '..(F.mode=='arcade' and 'ARCADE (assiste)' or 'SIMULATION')..'   [F10]'
        hudText(t,w*0.5-gr.getStringWidth(t)*0.5,h*0.30,120,220,255)
    end
    if F.pull and math.floor(now*4)%2==0 then
        local t='REMONTEZ !'
        hudText(t,w*0.5-gr.getStringWidth(t)*0.5,h*0.62,255,60,40)
    elseif F.stall then
        local t='DECROCHAGE'
        hudText(t,w*0.5-gr.getStringWidth(t)*0.5,h*0.62,255,190,40)
    end
end)

engine.addHook('On Key Pressed',function() end,{},function()
    if not (SPACESIM and SPACESIM.state and SPACESIM.state.active) then return false end
    if hv.RawKey=='F10' then
        F.mode=(F.mode=='arcade') and 'simulation' or 'arcade';saveCfg();F.noticeT=mn.getMissionTime()
        log('mode='..F.mode);return true
    end
    return false
end)

-- ------------------------------------------------------------------ automated tests
local TEST=nil
local function testInputs(T)
    -- returns raw pitch(+ = cabrer, model convention), heading(+ = droite), bank, throttle, mode
    local seq={
        {6,'level',0,0,0,1.0},
        {5,'stick right',0,1,0,1.0},
        {4,'release',0,0,0,1.0},
        {6,'pull up',1,0,0,1.0},
        {3,'release',0,0,0,1.0},
        {4,'dive',-0.8,0,0,1.0},
        {3,'level',0,0,0,1.0},
        {5,'sim: throttle 0, pull',0.8,0,0,0.0,'simulation'},
        {4,'sim: roll right',0,0.6,0,1.0,'simulation'},
    }
    local t0=0
    for _,s in ipairs(seq) do
        if T<t0+s[1] then return s[2],s[3],s[4],s[5],s[6],s[7] or 'arcade' end
        t0=t0+s[1]
    end
    return nil
end

-- ------------------------------------------------------------------ the model
local lastLog=0
local function step(sh,dt,now)
    local ci=ba.getControlInfo()
    local p=sh.Position
    local up=unit(p-C)
    local r_=length(p-C);local hAlt=r_-R
    local air=airFactor(hAlt)
    local o=sh.Orientation
    local f,u,rt=o:getFvec(),o:getUvec(),o:getRvec()
    local phys=sh.Physics
    local vel=phys.Velocity
    local v=length(vel)

    -- raw inputs (engine conventions) -> model conventions
    local rawP,rawH,rawB=SP*ci.Pitch,SH*ci.Heading,SB*ci.Bank
    local throttle=clamp(ci.Forward+ci.ForwardCruise/100,0,1)
    local mode=F.mode
    if TEST then
        local name,tp,th,tb,tt,tm=testInputs(now-TEST.t0)
        if not name then log('TEST done');TEST=nil;ba.setControlMode(FLIGHT_CONTROL_LUA_STEERING)
        else
            if name~=TEST.name then TEST.name=name;log(string.format('TEST step "%s"',name)) end
            rawP,rawH,rawB,throttle,mode=tp,th,tb,tt,tm
        end
    end
    IN.p=shape(rawP,IN.p,dt);IN.h=shape(rawH,IN.h,dt);IN.b=shape(rawB,IN.b,dt)

    -- attitude
    local fh=f-up*dot(f,up)
    local pitchAng=math.asin(clamp(dot(f,up),-1,1))
    local upPerp=unit(up-f*dot(up,f))                       -- local "up" seen around the nose
    local bank=math.atan2(-dot(rt,upPerp),dot(u,upPerp))     -- > 0 : right wing down
    local rotMax=phys.RotationalVelocityMax                 -- rad/s : x pitch, y yaw, z roll
    local qMax,rMax,pMax=math.max(0.2,rotMax.x),math.max(0.2,rotMax.y),math.max(0.2,rotMax.z)
    local vs=math.max(v,40)
    local g=G0*(R/r_)*(R/r_)

    -- body rates wanted (rad/s): q pitch up, rr yaw right, pr roll right
    local q,rr,pr=0,0,0
    local cb=clamp(bank,-math.rad(80),math.rad(80))
    local omega=g*math.tan(cb)/vs                            -- coordinated turn rate (world vertical)
    local stallSpeed=62
    local lift=1
    if mode=='arcade' then
        local cmd=IN.h*math.rad(72)
        local level=(math.abs(IN.h)<0.06 and math.abs(IN.b)<0.06 and math.abs(pitchAng)<math.rad(65))
        local target=level and 0 or cmd
        if math.abs(IN.b)>0.06 then target=bank end           -- bank keys: free roll
        pr=clamp(3.2*(target-bank),-pMax,pMax)+IN.b*pMax
        -- turn = rotation about the world vertical (coordinated + a little aiming), split into body pitch/yaw;
        -- banked with the stick, the assistant also pulls: tight, level arcade turns
        local pull=IN.h*0.55*qMax*math.abs(math.sin(cb))     -- signed like the turn: stays horizontal
        local w=omega+IN.h*0.22*rMax+pull
        q=IN.p*qMax+w*math.sin(cb)
        rr=w*math.cos(cb)
        -- pitch hold: without pitch input the assistant keeps the attitude (no sinking in the turns)
        if math.abs(IN.p)>0.05 or not F.pitchHold or math.abs(bank)>math.rad(100) then F.pitchHold=pitchAng
        else q=q+clamp(2.2*(F.pitchHold-pitchAng)/math.max(0.35,math.cos(cb)),-0.6*qMax,0.6*qMax) end
        F.stall=false
    else
        pr=IN.h*pMax
        rr=omega*math.cos(cb)+IN.b*0.45*rMax                 -- bank axis/keys = rudder
        lift=clamp((v/stallSpeed)^2,0,1)
        local nMax=7.5*math.max(0.15,lift)                    -- the wing limits the load factor
        q=clamp(IN.p*qMax,-nMax*g/vs,nMax*g/vs)
        F.stall=(air>0.5 and v<stallSpeed)
        local sw=1-lift
        if sw>0.01 then
            -- stalled: the pilot loses authority, the nose weathervanes into the airflow, then falls
            local k=math.min(1,v/20)
            local d=unit(unit(vel)*k+up*(-(1-k)))
            local e=d-f*dot(d,f)
            q=q*lift*lift+2.8*sw*dot(e,u)
            rr=rr*lift+2.8*sw*dot(e,rt)
        end
    end
    -- blend with the raw space controls when the air gets thin
    local outP=(q/qMax)*air+rawP*(1-air)
    local outH=(rr/rMax)*air+rawH*(1-air)
    local outB=(pr/pMax)*air+rawB*(1-air)
    -- cancel FSO's "bank when turning" (delta_bank = -heading*maxrot.y*banking_constant)
    local bankComp=(SH*outH*rMax*phys.BankingConstant)/pMax
    ci.Pitch=clamp(SP*outP,-1,1);ci.Heading=clamp(SH*outH,-1,1);ci.Bank=clamp(SB*outB+bankComp*SB*SB,-1,1)

    -- speed envelope (climb to orbit), also when FSO flies
    local vt=F.vTable
    local vmax=speedEnvelope(hAlt,vt)
    local vab=vmax*F.abRatio
    local envelopeOn=not (SPACESIM.state.speedIndex and SPACESIM.state.speedIndex>1)   -- F9 cruise (free flight) wins
    if envelopeOn and math.abs(vmax-(F.lastVmax or 0))>0.5 then
        local m=phys.VelocityMax;phys.VelocityMax=V(m.x,m.y,vmax)
        local a=phys.AfterburnerVelocityMax;phys.AfterburnerVelocityMax=V(a.x,a.y,vab)
        F.lastVmax=vmax
    end

    -- translation (only in the air)
    if air>0.01 then
        local ab=phys.AfterburnerActive
        local vGoal=(ab and vab or vmax*throttle)
        local vf=dot(vel,f)
        local tau=(vGoal>vf) and (ab and F.abAccel or F.accel) or F.decel
        local gv=up*(-g*air*(mode=='arcade' and 0.55 or 1.0))
        local gPar=dot(gv,f)
        local aMax=(mode=='arcade') and 60 or 35               -- thrust / drag limited acceleration
        vf=vf+(clamp((vGoal-vf)/math.max(0.3,tau),-aMax,aMax)+gPar)*dt
        if mode=='arcade' then vf=math.max(vf,55*air) end
        local lat=vel-f*dot(vel,f)
        local tauSide=0.28+0.25*(1-lift)
        lat=lat*math.exp(-dt/tauSide)
        local gPerp=gv-f*gPar
        lat=lat+gPerp*((1-lift)*dt)
        local nv=f*vf+lat
        phys.Velocity=nv*air+vel*(1-air)
        vel=phys.Velocity;v=length(vel)
    end

    -- ground proximity (height map, terrain ahead along the trajectory)
    local pull=false
    if SPACESIM.surface and air>0.2 then
        for k=1,3 do
            local q2=p+vel*(k*1.0)
            local gp=SPACESIM.surface(q2)
            if gp and length(q2-C)-length(gp-C)<25 then pull=true;break end
        end
    end
    if pull and not F.pull then F.warnT=0 end
    F.pull=pull
    if pull and now-F.warnT>0.9 then
        F.warnT=now
        ad.playGameSound(56)          -- FotG 'proximity warning' (alert-proximity.wav)
    end

    if (TEST or F.debug) and now-lastLog>0.5 then
        lastLog=now
        local gp=SPACESIM.surface and SPACESIM.surface(p)
        log(string.format('t=%.1f mode=%s alt=%.0f agl=%.0f v=%.1f pitch=%.1f bank=%.1f hdg=%.1f air=%.2f in=(%.2f,%.2f,%.2f) stall=%s pull=%s',
            now,mode,hAlt,gp and (length(p-C)-length(gp-C)) or -1,v,math.deg(pitchAng),math.deg(bank),
            math.deg(math.atan2(dot(fh,V(1,0,0)),dot(fh,V(0,0,1)))),air,IN.p,IN.h,IN.b,tostring(F.stall),tostring(pull)))
    end
end

-- ------------------------------------------------------------------ calibration of the command signs
local CAL=nil
local function calibrate(sh,now)
    local ci=ba.getControlInfo()
    local o=sh.Orientation
    if not CAL.ref then CAL.ref={f=o:getFvec(),u=o:getUvec(),r=o:getRvec()};CAL.t0=now end
    local t=now-CAL.t0
    local axis=({'Pitch','Heading','Bank','done'})[math.floor(t/1.5)+1]
    if not axis then CAL=nil;ba.setControlMode(FLIGHT_CONTROL_NORMAL);log('CAL done');return end
    if axis~=CAL.axis then
        if CAL.axis then
            local ref=CAL.ref;local f,u=o:getFvec(),o:getUvec()
            log(string.format('CAL %s=+0.6 : nose_up=%.3f yaw_right=%.3f roll_right=%.3f',CAL.axis,dot(f,ref.u),dot(f,ref.r),dot(u,ref.r)))
        end
        CAL.axis=axis;CAL.ref={f=o:getFvec(),u=o:getUvec(),r=o:getRvec()}
    end
    ci.Pitch=0;ci.Heading=0;ci.Bank=0;if axis~='done' then ci[axis]=0.6 end
end

-- ------------------------------------------------------------------ hooks
engine.addHook('On Gameplay Start',function()
    F.active=false;F.init=false;TEST=nil;CAL=nil;F.lastVmax=nil;FLIGHT_EXTERNAL=nil
end)
engine.addHook('On Simulation',function()
    if not (SPACESIM and SPACESIM.state and SPACESIM.state.active) then return end
    local sh=playerShip()
    local now=mn.getMissionTime()
    local dt=ba.getMissionFrametime()
    local can=ok(sh) and not sh:isDying() and not scriptedByCinematic() and not FLIGHT_EXTERNAL and dt>0
    if can and (SPACESIM.state.auto or SPACESIM.state.showcase) then can=false end   -- autopilot (F8), showcase
    if not can then
        if F.active then F.active=false;ba.setControlMode(FLIGHT_CONTROL_NORMAL) end
        return
    end
    if not F.init then
        F.init=true;loadCfg()
        F.vTable=sh.Physics.VelocityMax.z
        F.abRatio=math.max(1.05,sh.Physics.AfterburnerVelocityMax.z/math.max(1,sh.Physics.VelocityMax.z))
        F.accel=math.max(0.4,sh.Physics.ForwardAccelerationTime);F.decel=math.max(0.4,sh.Physics.ForwardDecelerationTime)
        F.abAccel=math.max(0.4,sh.Physics.AfterburnerAccelerationTime)
        F.debug=cf.fileExists('spacesim-flightdebug.flag','data',true)
        if cf.fileExists('spacesim-flightcal.flag','data',true) then CAL={} end
        if cf.fileExists('spacesim-flighttest.flag','data',true) then
            TEST={t0=now+2}
            sh.Position=sh.Position+unit(sh.Position-C)*1200        -- room for loops and dives
        end
        log(string.format('init mode=%s vmax=%.0f ab=%.2f accel=%.2f decel=%.2f rotmax=%s banking=%.2f',F.mode,F.vTable,F.abRatio,F.accel,F.decel,tostring(sh.Physics.RotationalVelocityMax),sh.Physics.BankingConstant))
        F.noticeT=now
    end
    if CAL then
        if not F.active then F.active=true;ba.setControlMode(FLIGHT_CONTROL_LUA_FULL) end
        calibrate(sh,now);return
    end
    if not F.active then
        F.active=true;ba.setControlMode(TEST and FLIGHT_CONTROL_LUA_FULL or FLIGHT_CONTROL_LUA_STEERING)
    end
    if TEST and now<TEST.t0 then return end
    if TEST and not TEST.fullSet then TEST.fullSet=true;ba.setControlMode(FLIGHT_CONTROL_LUA_FULL) end
    if TEST then
        local ci=ba.getControlInfo()
        local _,_,_,_,tt=testInputs(now-TEST.t0)
        if tt then ci.Forward=tt;ci.ForwardCruise=0 end
    end
    step(sh,dt,now)
end)
engine.addHook('On Mission About To End',function()
    if F.active then F.active=false;ba.setControlMode(FLIGHT_CONTROL_NORMAL) end
end)
