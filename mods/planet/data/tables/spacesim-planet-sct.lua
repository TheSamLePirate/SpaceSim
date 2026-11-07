-- Aurore 02: one scene, native POF terrain, continuous velocity-driven ascent.
-- All terrain, cloud and atmosphere models are mission props, loaded before flight.
local V=ba.createVector
local s={active=false}
local C=V(0,-80000,0)
local function valid(o) return o and o:isValid() end
local function length(v) return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z) end
local function distance(a,b) return length(a-b) end
local function unit(v) local d=length(v);if not (d>1e-6) then return V(0,0,1) end;return V(v.x/d,v.y/d,v.z/d) end
local function altitude(p) return distance(p,C)-80000 end
local function record(str)
    local line=string.format('PLANET_PROOF t=%.3f %s',mn.getMissionTime(),str)
    s.lines[#s.lines+1]=line;ba.print(line..'\n')
end
local function flush()
    s.lastSave=mn.getMissionTime()
    local f=cf.openFile('spacesim-planet-telemetry.txt','w','data')
    if f then f:write(table.concat(s.lines,'\n')..'\n');f:close() end
end
-- Periodic writes are throttled (every 10 s): writing every second caused a visible hitch.
local stopSignal   -- defined below (test harness), used by the collision hook
-- explosion effect without mn.createExplosion: under Vulkan, fireball_create's LOD computation called from Lua
-- (g3_get_bitmap_dims) crashes (seen from a collision hook and from On Simulation). Animated particle with the
-- same fireball texture + FotG explosion sound. The engine's own fireballs (ship deaths) are unaffected.
local BOOM={}
local function boom(pos,radius,silent)
    if not BOOM.tex then BOOM.tex=gr.loadTexture('Exp_Det_Shp_01_Gld',true) end
    if BOOM.tex and BOOM.tex:isValid() then gr.createParticle(pos,ba.createVector(0,0,0),1.8,radius,PARTICLE_BITMAP,-1,false,BOOM.tex) end
    if not silent then pcall(function() ad.playGameSound(49) end) end
end
local function save() if mn.getMissionTime()-(s.lastSave or -99)>10 then flush() end end
-- Time of day: the shader reads the mission sun light, so moving the sun moves the sky.
local SUN_AZ=0.8
local PRESETS={{'Midi',1.05},{'Apres-midi',0.62},{'Heure doree',0.20},{'Coucher',0.05},{'Crepuscule',-0.035},{'Nuit',-0.35},{'Aube',0.0}}
local function setSun(elev,az)
    s.sunElev=elev;s.sunAz=az or SUN_AZ
    if #mn.BackgroundSuns>0 then mn.BackgroundSuns[1].Orientation=ba.createOrientation(-elev,0,s.sunAz) end
end
local function sunVector(elev,az)
    az=az or SUN_AZ;return V(math.sin(az)*math.cos(elev),math.sin(elev),math.cos(az)*math.cos(elev))
end
local function capture(name)
    local f=cf.openFile('shot_'..name..'.b64','w','data')
    if f then f:write(gr.screenToBlob());f:close() end
    record('CAPTURE '..name..string.format(' altitude=%.0f sun=%.3f',s.alt or -1,s.sunElev or -9))
end
SHOWCASE={}
local function addShot(name,pos,sun,lookFn,az,hold) SHOWCASE[#SHOWCASE+1]={name=name,pos=pos,sun=sun,look=lookFn,az=az,hold=hold} end
do
    local valley=V(0,1060,-5000);local high=V(0,8200,-4000);local orbit=V(9000,96000,26000)
    local fwd=function() return V(0,-0.02,1) end
    local toSunLow=function() return V(math.sin(SUN_AZ),0.05,math.cos(SUN_AZ)) end
    local awaySun=function() return V(-math.sin(SUN_AZ),0.08,-math.cos(SUN_AZ)) end
    local down=function() return V(-0.09,-1,-0.27) end
    addShot('s01_midi_vallee',valley,1.05,fwd)
    addShot('s02_apresmidi_vallee',valley,0.62,fwd)
    local VAZ=0.12   -- sunset straight down the valley
    local toValleySun=function() return V(math.sin(VAZ),0.06,math.cos(VAZ)) end
    local awayValley=function() return V(-math.sin(VAZ),0.10,-math.cos(VAZ)) end
    addShot('s03_heure_doree_vers_soleil',valley,0.20,toValleySun,VAZ)
    addShot('s04_coucher_vers_soleil',valley,0.05,toValleySun,VAZ)
    addShot('s05_coucher_dos_au_soleil',valley,0.05,awayValley,VAZ)
    addShot('s06_crepuscule',valley,-0.035,toValleySun,VAZ)
    addShot('s07_8km_coucher',high,-0.30,function() return V(math.sin(VAZ),-0.25,math.cos(VAZ)) end,VAZ)
    addShot('s08_8km_apresmidi',high,0.62,fwd)
    addShot('s09_orbite_jour',orbit,0.62,down)
    addShot('s10_orbite_terminateur',orbit,0.02,down)
    addShot('s11_nuit_vallee',valley,-0.35,fwd)
    -- Ground content: positions resolved at run time from the mission objects.
    local function objPos(kind,name) local o=kind=='ship' and mn.Ships[name] or mn.Props[name];return o and o:isValid() and o.Position or V(0,800,0) end
    local function near(kind,name,off,clear)
        return function()
            local p=objPos(kind,name)+off
            local q=SURFACE and SURFACE(p)
            if q then local up=q-V(0,-80000,0);local l=math.sqrt(up.x*up.x+up.y*up.y+up.z*up.z);up=V(up.x/l,up.y/l,up.z/l)
                local need=q+up*(clear or 60);if (p-V(0,-80000,0)):getMagnitude()<(need-V(0,-80000,0)):getMagnitude() then p=need end end
            return p
        end
    end
    local function at(kind,name,off) return function() local d=objPos(kind,name)+(off or V(0,0,0))-SHOWCASE.current;return d end end
    addShot('g01_avantposte_jour',near('prop','Base hangar 0',V(190,55,-240)),0.62,at('prop','Base hangar 0',V(70,5,20)))
    addShot('g02_avantposte_coucher',near('prop','Base hangar 0',V(190,55,-240)),0.06,at('prop','Base hangar 0',V(70,5,20)),0.12)
    addShot('g03_avantposte_nuit',near('prop','Base hangar 0',V(190,55,-240)),-0.30,at('prop','Base hangar 0',V(70,5,20)))
    addShot('g04_tourelle_tir',near('ship','Batterie 5',V(230,10,-230),40),0.45,at('ship','Batterie 5',V(0,-25,0)),nil,7.0)
    addShot('g05_atat',near('ship','AT-AT 1',V(45,8,-60),12),0.45,at('ship','AT-AT 1',V(0,-2,0)))
    addShot('g06_foret',near('prop','Foret 2022',V(-300,70,-500),60),0.5,at('prop','Foret 2022',V(0,-30,0)))
    addShot('f01_foret_rase_jour',near('prop','Foret 2022',V(-120,18,-260),18),0.55,at('prop','Foret 2022',V(80,-20,200)))
    addShot('f02_foret_rase_couchant',near('prop','Foret 2022',V(-120,18,-260),18),0.06,at('prop','Foret 2022',V(80,-20,200)),0.12)
    addShot('f03_sous_bois',near('prop','Foret 2023',V(30,6,-120),6),0.45,at('prop','Foret 2023',V(30,0,200)))
    addShot('f04_foret_haut_jour',near('prop','Foret 2020',V(-600,350,-900),300),0.45,at('prop','Foret 2020'))
end
function SURFACE(p) return SURFACE_IMPL(p) end
-- ===================== ground height map (scripts/build_planet_heightmap.py) =====================
-- Gnomonic grids on the north face: a=R*d.x/d.y, b=R*d.z/d.y with d=unit(p-C). 2 chars/sample (base 94).
-- Decoded on demand: O(1) ground height instead of ray casts against the terrain props.
local HM=nil
local function hmLoad()
    HM={}
    if not cf.fileExists('spacesim-height.txt','data',true) then record('HEIGHTMAP missing');return end
    local f=cf.openFile('spacesim-height.txt','r','data');local all=f:read('*a');f:close()
    local pos,lines=1,{}
    while #lines<3 do
        local e=all:find('\n',pos,true);if not e then break end
        lines[#lines+1]=all:sub(pos,e-1);pos=e+1
    end
    for k=2,3 do
        local n,a0,b0,step,na,nb,u=lines[k]:match('^(%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+)')
        local g={name=n,a0=tonumber(a0),b0=tonumber(b0),step=tonumber(step),na=tonumber(na),nb=tonumber(nb),unit=tonumber(u)}
        g.off=pos;pos=pos+g.na*g.nb*2+1;HM[#HM+1]=g
    end
    HM.s=all
    record(string.format('HEIGHTMAP grids=%d bytes=%d',#HM,#all))
end
local sbyte=string.byte
local function hmSample(g,i,j)
    local k=g.off+(j*g.na+i)*2
    local c1,c2=sbyte(HM.s,k,k+1)
    return ((c1-33)*94+(c2-33))*g.unit
end
-- ground height (m above the 80 km sphere) under p, or nil outside the maps
local function hmHeight(p)
    if not HM or not HM.s then return nil end
    local dx,dy,dz=p.x-C.x,p.y-C.y,p.z-C.z
    if dy<=0 then return nil end
    local a,b=80000*dx/dy,80000*dz/dy
    for _,g in ipairs(HM) do
        local fx,fy=(a-g.a0)/g.step,(b-g.b0)/g.step
        if fx>=0 and fy>=0 and fx<g.na-1 and fy<g.nb-1 then
            local i,j=math.floor(fx),math.floor(fy);local tx,ty=fx-i,fy-j
            local h00,h10=hmSample(g,i,j),hmSample(g,i+1,j)
            local h01,h11=hmSample(g,i,j+1),hmSample(g,i+1,j+1)
            return (h00+(h10-h00)*tx)*(1-ty)+(h01+(h11-h01)*tx)*ty
        end
    end
    return nil
end
local function surfaceRay(p)
    local n=unit(p-C)
    local top=C+n*90000
    local q0=C+n*80000
    local hit
    for _,prop in ipairs(s.terrain) do
        local q=nil
        if distance(prop.Position,q0)<prop.Radius+9000 then q=prop:checkRayCollision(top,C) end
        if q and (not hit or distance(q,C)>distance(hit,C)) then hit=q end
    end
    return hit
end
-- surface point under p (along the planet radius): height map first, ray cast outside it
local function surface(p)
    local h=hmHeight(p)
    if h then return C+unit(p-C)*(80000+h) end
    return surfaceRay(p)
end
local function cruise()
    local speeds={250,1500,5000};s.cruise=speeds[s.speedIndex]
    s.player.Physics.VelocityMax=V(40,40,s.cruise)
    s.player.Physics.AfterburnerVelocityMax=V(60,60,s.cruise*1.7)
    s.player.Physics.ForwardAccelerationTime=1.5
    s.player.Physics.ForwardDecelerationTime=1.0
end
engine.addHook('On Gameplay Start',function()
    local filename=mn.getMissionFilename():lower()
    if not (filename:find('_spt_planet_') or filename:find('_spt_aurore_')) then s.active=false;return end
    s={active=true,lines={},terrain={},auto=filename:find('_auto')~=nil,autoStart=0,stage='surface',speedIndex=1,frames=0,realTime=0,frameTimes={},bins={},lastLog=-1,lastRay=-1,contacts=0,probeContact=false,maxStep=0,maxError=0}
    s.player=mn.Ships['Red 1'];s.probe=mn.Ships['Sonde collision'];s.capital=mn.Ships['Vigilance']
    if not HM then hmLoad() end
    if SPACESIM then SPACESIM.state=s end
    for i=1,#mn.Props do
        local prop=mn.Props[i]
        if valid(prop) and prop.Name:sub(1,7)=='Planet ' then s.terrain[#s.terrain+1]=prop end
    end
    -- Atmosphere belongs to the planet props; the starfield always remains behind it.
    -- Diagnostic switches for visual captures (absent in normal play).
    if cf.fileExists('spacesim-noair.flag','data',true) and valid(mn.Props['Air 0']) then mn.Props['Air 0'].Position=V(0,9e6,0) end
    -- diagnostic: no vegetation (forest sectors moved far away)
    if cf.fileExists('spacesim-noveg.flag','data',true) then
        for i=1,#mn.Props do local pr=mn.Props[i];if valid(pr) and pr.Name:sub(1,6)=='Foret ' then pr.Position=V(0,9e6,0) end end
    end
    mn.SkyboxAlpha=1
    if valid(s.capital) then s.player.Target=s.capital end;cruise()
    s.presetIndex=2;setSun(PRESETS[2][2])
    s.showcase=cf.fileExists('spacesim-showcase.flag','data',true)
    SURFACE_IMPL=surface
    if s.showcase then s.auto=false;s.shotIndex=1;s.shotStart=0
        local only=cf.fileExists('spacesim-only.flag','data',true) and cf.openFile('spacesim-only.flag','r','data')
        if only then
            local pre=only:read('*l') or '';only:close()
            local keep={};for _,sh in ipairs(SHOWCASE) do if sh.name:sub(1,#pre)==pre then keep[#keep+1]=sh end end;SHOWCASE=keep
        end
        if cf.fileExists('spacesim-showg.flag','data',true) then
            local keep={};for _,sh in ipairs(SHOWCASE) do if sh.name:sub(1,1)=='g' or sh.name:sub(1,1)=='f' then keep[#keep+1]=sh end end;SHOWCASE=keep
        end
    end
    -- No engine fog: haze, sky and halo all come from the shader's atmosphere.
    mn.runSEXP('(mission-set-nebula 0)')
    if #mn.BackgroundSuns>0 then local f=mn.BackgroundSuns[1].Orientation:getFvec();record(string.format('SUN x=%.4f y=%.4f z=%.4f',f.x,f.y,f.z)) end
    record(string.format('START mission=%s terrain_faces=%d radius_m=80000 auto=%s',filename,#s.terrain,tostring(s.auto)))
    for _,xz in ipairs({{0,-5000},{0,0},{1000,-1000},{5000,5000},{-6500,3500}}) do
        local q=surface(V(xz[1],3000,xz[2]))
        if q then record(string.format('RAY_HIT x=%.3f y=%.3f z=%.3f',q.x,q.y,q.z)) else record('RAY_MISS') end
    end
    if cf.fileExists('spacesim-hmtest.flag','data',true) then
        -- height map vs terrain ray casts over the canyon area
        math.randomseed(7);local n,sum,mx,worst=0,0,0,nil
        for _=1,600 do
            local q=V(-6000+math.random()*12000,4000,-11000+math.random()*20000)
            local h=hmHeight(q);local r=surfaceRay(q)
            if h and r then local e=math.abs((80000+h)-distance(r,C));n=n+1;sum=sum+e;if e>mx then mx=e;worst=q end end
        end
        record(string.format('HMTEST samples=%d mean_err=%.2f max_err=%.2f at=%s',n,sum/math.max(1,n),mx,tostring(worst)))
    end
    save()
end)
local function handle_key()
    if not s.active then return false end
    if hv.RawKey=='F8' then
        s.auto=not s.auto;s.finished=false;s.autoStart=mn.getMissionTime();s.autoSurfaceEnd=s.autoStart+ (altitude(s.player.Position)<3000 and 18 or 0)
        record('CONTROL auto='..tostring(s.auto));save()
    elseif hv.RawKey=='F9' then s.speedIndex=s.speedIndex%3+1;cruise();record('CRUISE speed='..s.cruise);save()
    elseif hv.RawKey=='F7' then s.dayCycle=false;s.presetIndex=s.presetIndex%#PRESETS+1;setSun(PRESETS[s.presetIndex][2]);record('SUN preset='..PRESETS[s.presetIndex][1])
    elseif hv.RawKey=='F6' then s.dayCycle=not s.dayCycle;record('SUN cycle='..tostring(s.dayCycle)) end
    return hv.RawKey=='F8' or hv.RawKey=='F9' or hv.RawKey=='F7' or hv.RawKey=='F6'
end
engine.addHook('On Key Pressed',function() end,{},handle_key)
-- FSO 26.2 bug workaround (collideshipweapon.cpp, prop_weapon_check_collision): for a constant-velocity
-- weapon (every laser / turbolaser) inside a prop larger than 500 m (our terrain tiles), the engine predicts
-- the impact over the laser's whole lifetime and, when that impact is still in the FUTURE, processes it
-- immediately anyway: the bolt is destroyed on its first frame, a few metres from the gun, and never reaches
-- the target in front of it. Real impacts lie on the segment travelled this frame (behind the current
-- position); predicted ones lie ahead of it -> those are ignored, the engine re-checks the pair later and
-- detonates the bolt for real when it actually reaches the ground.
engine.addHook('On Weapon Collision',function() end,{},function()
    local p,w=hv.Prop,hv.Weapon
    if not (p and p:isValid() and w and w:isValid()) or p.Radius<=500 then return false end
    local v=w.Physics.Velocity;local sp=math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)
    if sp<1 then return false end
    local d=hv.Hitpos-w.Position
    return (d.x*v.x+d.y*v.y+d.z*v.z)/sp>1.0
end)

engine.addHook('On Prop Collision',function() end,{},function()
    if not s.active or not valid(hv.Prop) or not valid(hv.Ship) then return false end
    local terrain=false
    for _,p in ipairs(s.terrain) do if p:getSignature()==hv.Prop:getSignature() then terrain=true;break end end
    if not terrain then return false end
    local isProbe=valid(s.probe) and hv.Ship:getSignature()==s.probe:getSignature()
    if isProbe and not s.probeContact then
        s.probeContact=true;s.probeTime=mn.getMissionTime()
        record(string.format('NATIVE_COLLISION incoming_vy=%.3f hit_y=%.3f',hv.Ship.Physics.Velocity.y,hv.Hitpos.y));save()
    elseif hv.Ship:getSignature()==s.player:getSignature() then s.contacts=s.contacts+1 end
    -- hitting the ground at speed destroys a fighter (player included)
    local sh=hv.Ship
    local tn=sh.Class and sh.Class.Type and sh.Class.Type.Name or ''
    if (tn=='fighter' or tn=='bomber') and not sh:isDying() and not isProbe then
        local v=sh.Physics.Velocity;local sp=math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)
        if sp>35 then
            record(string.format('CRASH %s speed=%.0f',sh.Name,sp))
            if valid(s.player) and sh:getSignature()==s.player:getSignature() then stopSignal('player_crash') end
            boom(hv.Hitpos or sh.Position,70);boom(sh.Position+unit(sh.Position-C)*12,40,true)
            sh.Physics.Velocity=V(0,0,0)
            sh.Target=nil
            -- FSO places the player's death camera 100 m from the wreck, on the side opposite the killer:
            -- a crash "kills itself" (camera 50 m in front of the nose = underground in a dive), so an
            -- invisible witness placed on the other side of the chosen camera point is credited instead
            -- scripted sequences (cinematic) stage the player's crash themselves
            if sh==s.player and SPACESIM_PLAYER_CRASH and SPACESIM_PLAYER_CRASH(sh,hv.Hitpos or sh.Position) then return true end
            if sh==s.player and SPACESIM_REAL_DEATH and SPACESIM_WRECK_CAM then
                SPACESIM_REAL_DEATH(sh,sh.Position,SPACESIM_WRECK_CAM(sh.Position,v,sh.Orientation:getFvec()))
            else
                sh:kill(sh)
            end
            return true      -- no collision response: the wreck must not bounce off the ground
        end
    end
    return false
end)
engine.addHook('On Simulation',function()
    if not s.active or not valid(s.player) then return end
    local t=mn.getMissionTime();local dt=ba.getRealFrametime();local p=s.player.Position;local alt=altitude(p)
    s.alt=alt;s.frames=s.frames+1;s.realTime=s.realTime+dt
    if dt>0 then s.frameTimes[#s.frameTimes+1]=dt end
    if s.previous then
        local step=distance(p,s.previous);s.maxStep=math.max(s.maxStep,step)
        local predicted=length(s.previousVelocity)*ba.getMissionFrametime()
        s.maxError=math.max(s.maxError,math.abs(step-predicted))
    end
    s.previous=V(p.x,p.y,p.z);s.previousVelocity=s.player.Physics.Velocity
    local bin=alt<3000 and 'surface' or (alt<25000 and 'atmosphere' or 'orbit')
    s.bins[bin]=s.bins[bin] or {frames=0,time=0};s.bins[bin].frames=s.bins[bin].frames+1;s.bins[bin].time=s.bins[bin].time+dt
    if not valid(s.probe) then
    elseif not s.probeContact then s.probe.Physics.Velocity=unit(C-s.probe.Position)*25
    elseif not s.probeResponse and t>s.probeTime+.2 then
        s.probeResponse=true;local q=surface(s.probe.Position)
        s.probeClearance=q and distance(s.probe.Position,C)-distance(q,C) or -9999
        record(string.format('NATIVE_RESPONSE clearance=%.3f vy=%.3f',s.probeClearance,s.probe.Physics.Velocity.y));save()
    end
    mn.SkyboxAlpha=1
    if s.dayCycle then
        local e=s.sunElev-ba.getMissionFrametime()*0.012
        if e<-0.45 then e=1.1 end
        setSun(e)
    end
    if s.showcase then
        local start=V(0,1060,-5000)
        local shots=SHOWCASE
        local shot=shots[s.shotIndex]
        if shot then
            if s.shotStart==0 then s.shotStart=t;setSun(shot.sun,shot.az);record('SHOWCASE '..shot.name) end
            local pos=type(shot.pos)=='function' and shot.pos() or shot.pos;SHOWCASE.current=pos
            local look=shot.look and shot.look() or sunVector(0.06,(shot.az or SUN_AZ))
            s.player.Position=pos;s.player.Physics.Velocity=V(0,0,0)
            s.player.Orientation=ba.createOrientationFromVectors(look,shot.up or V(0,1,0))
            if not s.cam then s.cam=gr.createCamera('ss_showcase',pos,s.player.Orientation);gr.setCamera(s.cam) end
            s.cam:setPosition(pos);s.cam:setOrientation(s.player.Orientation)
            if t-s.shotStart>(shot.hold or 2.5) and not s.pendingShot then s.pendingShot=shot.name end
        end
    end
    if s.auto and not s.finished then
        local vel;local view;local up=V(0,1,0)
        if t<(s.autoSurfaceEnd or 18) then
            s.stage='vallee';vel=V(0,0,240);view=V(0,-.045,1)
        elseif p.y<99500 then
            s.stage='ascension';local climb=math.min(2200,350+(t-(s.autoSurfaceEnd or 18))*160)
            vel=V(350,climb,160)
            local a=math.min(1,math.max(0,(alt-8000)/40000))
            view=V(.12,-.12-a*1.4,1-a*.8)
        else
            s.stage='orbite';vel=V(0,0,0);view=C-p;up=V(0,0,1);s.finished=true
        end
        s.player.Physics.Velocity=vel;s.player.Orientation=ba.createOrientationFromVectors(view,up)
    end
    if t-s.lastRay>.35 then
        s.lastRay=t;local q=surface(p);s.agl=q and distance(p,C)-distance(q,C) or nil
    end
    if t-s.lastLog>=1 then
        s.lastLog=t
        local b=s.bins[bin];s.fps=b.frames/math.max(.001,b.time)
        record(string.format('FLIGHT x=%.3f y=%.3f z=%.3f altitude=%.3f agl=%.3f phase=%s fps=%.2f sky=%.4f weapons=%d mission=%s',p.x,p.y,p.z,alt,s.agl or -1,bin,s.fps,mn.SkyboxAlpha,#mn.Weapons,mn.getMissionFilename()))
        if s.finished and not s.result then
            s.result=true;table.sort(s.frameTimes)
            for name,b in pairs(s.bins) do record(string.format('PERFORMANCE phase=%s frames=%d seconds=%.3f fps_mean=%.2f',name,b.frames,b.time,b.frames/b.time)) end
            local p95=s.frameTimes[math.max(1,math.floor(#s.frameTimes*.95))]
            local pass=#s.terrain>0 and s.probeContact and s.probeResponse and s.probeClearance>0 and alt>95000 and (s.maxError<200 or p95>0.05)
            record(string.format('RESULT status=%s native_contact=%s probe_clearance=%.3f altitude=%.3f max_step=%.3f integration_error=%.3f p95_ms=%.3f mission=%s',pass and 'PASS' or 'FAIL',tostring(s.probeContact),s.probeClearance or -9999,alt,s.maxStep,s.maxError,p95*1000,mn.getMissionFilename()))
            record('AUTO_DONE controls_released=true');s.auto=false
        end
        save()
    end
end)
local function flushShot()
    if s.pendingShot then
        capture(s.pendingShot);save()
        s.pendingShot=nil;s.shotIndex=s.shotIndex+1;s.shotStart=0
        if not SHOWCASE[s.shotIndex] then record('SHOWCASE_DONE');save() end
    end
end
engine.addHook('On Frame',function() if s.active and s.showcase then flushShot() end end)
local PERF={dts={},n=0,smooth=nil}
local function perfFrame()
    local dt=ba.getRealFrametime();if dt<=0 then return end
    PERF.n=PERF.n+1;PERF.dts[(PERF.n-1)%180+1]=dt
    PERF.smooth=PERF.smooth and PERF.smooth+(dt-PERF.smooth)*0.1 or dt
end
local function drawPerf()
    if PERF.off==nil then PERF.off=cf.fileExists('spacesim-nofps.flag','data',true) end
    if PERF.off or not PERF.smooth then return end
    local now=mn.getMissionTime()
    if not PERF.statT or now-PERF.statT>0.5 then
        -- stats refreshed twice a second only (Lua draw calls and sorting are not free)
        PERF.statT=now
        local n=math.min(PERF.n,180);local mx,sorted=0,{}
        for i=1,n do local d=PERF.dts[i];mx=math.max(mx,d);sorted[#sorted+1]=d end
        table.sort(sorted)
        PERF.p99=sorted[math.max(1,math.floor(#sorted*0.99))];PERF.mx=mx
        PERF.bars={}
        for k=1,30 do                       -- 30 bars, each the worst of 6 frames
            local w=0
            for j=1,6 do local idx=(PERF.n-180+(k-1)*6+j-1)%180+1;w=math.max(w,PERF.dts[idx] or 0) end
            PERF.bars[k]=w*1000
        end
        PERF.text1=string.format('%3.0f FPS   %5.1f ms',1/PERF.smooth,PERF.smooth*1000)
        PERF.text2=string.format('1%% bas %3.0f   pic %3.0f ms',1/PERF.p99,mx*1000)
    end
    local x,y=gr.getScreenWidth()-250,22
    local fps=1/PERF.smooth
    if fps>=45 then gr.setColor(120,255,140,255) elseif fps>=25 then gr.setColor(255,220,90,255) else gr.setColor(255,110,90,255) end
    gr.drawString(PERF.text1,x,y)
    gr.setColor(200,210,220,255);gr.drawString(PERF.text2,x,y+15)
    for k,ms in ipairs(PERF.bars) do
        if ms>33 then gr.setColor(255,90,70,255) elseif ms>17 then gr.setColor(255,210,80,255) else gr.setColor(110,230,130,255) end
        gr.drawRectangle(x+(k-1)*7,y+70-math.min(38,ms*0.6),x+(k-1)*7+5,y+70,true)
    end
end
-- stop signal for the test harness: mission end (stop now), player death / crash (stop after a hold)
stopSignal=function(reason)
    if s.stopped then return end
    s.stopped=reason
    record('STOP reason='..reason);flush()
    local f=cf.openFile('spacesim-stop.txt','w','data');if f then f:write(string.format('%s %.1f\n',reason,mn.getMissionTime()));f:close() end
end
engine.addHook('On Ship Death Started',function()
    if s.active and valid(hv.Ship) and valid(s.player) and hv.Ship:getSignature()==s.player:getSignature() then stopSignal('player_death') end
end)
engine.addHook('On Mission About To End',function() if s.active then stopSignal('mission_end') end end)
-- heartbeat for the test harness (scripts/capture_planet.sh): a blocking error dialog stops it
local HB={t=0}
local function heartbeat()
    local now=time.getCurrentTime():getSeconds()
    if now-HB.t<1 then return end
    HB.t=now
    local f=cf.openFile('spacesim-heartbeat.txt','w','data');if f then f:write(string.format('%.1f\n',mn.getMissionTime()));f:close() end
end
engine.addHook('On Frame',function() heartbeat();perfFrame();if not hu.HUDDrawn then drawPerf() end end)
engine.addHook('On HUD Draw',function()
    drawPerf()
    if not s.active then return end
    if s.showcase then flushShot();return end
    -- Optional visual proof: only when data/spacesim-capture.flag exists.
    if s.raidFlag then return end
    if s.auto and s.captureOn==nil then s.captureOn=cf.fileExists('spacesim-capture.flag','data',true);s.shots={} end
    if s.auto and s.captureOn and s.alt and s.shots then
        for _,mark in ipairs({{'01_vallee',1300,7},{'02_vallee_haut',1300,15},{'03_2km',2000},{'04_3km5',3500},{'05_5km',5000},{'06_7km',7000},{'07_10km',10000},{'08_15km',15000},{'09_25km',25000},{'10_40km',40000},{'11_60km',60000},{'12_orbite',99000}}) do
            local ready=(mark[3] and mn.getMissionTime()>mark[3]) or (not mark[3] and s.alt>mark[2])
            if ready and not s.shots[mark[1]] then
                s.shots[mark[1]]=true
                local f=cf.openFile('shot_'..mark[1]..'.b64','w','data')
                if f then f:write(gr.screenToBlob());f:close() end
                record('CAPTURE '..mark[1]..string.format(' altitude=%.0f',s.alt))
            end
        end
    end
    if s.cine then return end
    gr.setColor(180,230,245,255)
    gr.drawString('AURORE 02 / SURFACE > ORBITE',24,65)
    gr.drawString(string.format('Altitude %.2f km | Sol %s | %.0f FPS', (s.alt or 0)/1000,s.agl and string.format('%.0f m',s.agl) or '--',s.fps or 0),24,86)
    gr.drawString(string.format('F8 : %s | F9 : croisiere %d m/s',s.auto and 'reprendre les commandes' or 'trajet automatique',s.cruise or 250),24,107)
    gr.drawString('Planete 160 km | Terrain physique | Mission unique',24,128)
end)
engine.addHook('On Mission About To End',function()
    if s.raidState and s.raidState.warp then record('END_REQUESTED during hyperspace');flush();return end
    if s.cineJump then record('END_REQUESTED during cinematic hyperspace');flush();return end
    if s.active then record('END');flush();s.active=false end
end)

-- ===================== Raid : un seul plan continu, canyon au couchant -> orbite -> destroyer =====================
-- Active with data/spacesim-raid.flag. One centripetal Catmull-Rom spline, arc-length speed profile,
-- filtered orientation and one damped camera: no cut, no teleport. FPS measured per phase.
local RAID={}
local function valleyX(z) return 650*math.sin(z/2700)+180*math.sin(z/730) end
local function vlerp(a,b,t) return V(a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t,a.z+(b.z-a.z)*t) end
local function sstep(e0,e1,x) local t=math.max(0,math.min(1,(x-e0)/(e1-e0)));return t*t*(3-2*t) end
local function catmull(p0,p1,p2,p3,u)
    -- centripetal Catmull-Rom (Barry-Goldman), u in [0,1] across p1->p2
    local function knot(ti,a,b) return ti+math.sqrt(math.max(length(b-a),1e-3)) end
    local t0=0;local t1=knot(t0,p0,p1);local t2=knot(t1,p1,p2);local t3=knot(t2,p2,p3)
    local t=t1+(t2-t1)*u
    local A1=p0*((t1-t)/(t1-t0))+p1*((t-t0)/(t1-t0))
    local A2=p1*((t2-t)/(t2-t1))+p2*((t-t1)/(t2-t1))
    local A3=p2*((t3-t)/(t3-t2))+p3*((t-t2)/(t3-t2))
    local B1=A1*((t2-t)/(t2-t0))+A2*((t-t0)/(t2-t0))
    local B2=A2*((t3-t)/(t3-t1))+A3*((t-t1)/(t3-t1))
    return B1*((t2-t)/(t2-t1))+B2*((t-t1)/(t2-t1))
end
function RAID.start(t)
    if not valid(s.capital) then s.raidState=nil;return end
    local r={t0=t,phase='canyon',stats={},nextShot=t+2.0,shotIndex=0,lastFire=0,torps=0,s=0,
             short=cf.fileExists('spacesim-raidshort.flag','data',true)}
    s.raidState=r;s.auto=false
    -- 1. canyon control points: valley centre line, 140 m above the highest ground nearby
    local ground={}
    for z=-5400,4200,150 do local x=valleyX(z);ground[#ground+1]=surface(V(x,3000,z)) or V(x,700,z) end
    local P={}
    for i=1,#ground do
        local hi=-1e9
        for j=math.max(1,i-4),math.min(#ground,i+4) do hi=math.max(hi,ground[j].y) end
        P[i]=V(ground[i].x,hi+140,ground[i].z)
    end
    for pass=1,3 do for i=2,#P-1 do P[i]=vlerp(P[i],(P[i-1]+P[i+1])*0.5,0.5) end end
    local nCanyon=#P
    -- 2. climb, 3. destroyer run: continue the same curve
    local vig=s.capital.Position
    local last=P[#P];local d=unit(P[#P]-P[#P-1]);local up=unit(last-C)
    local add={last+d*1500+up*350,last+d*4500+up*2600,last+d*9000+up*9000,
               V(4000,30000,6000),V(9000,62000,2000),vig+V(-3000,9000,-9000),vig+V(-1800,2600,-5200),
               vig+V(-500,900,-2300),vig+V(120,420,-600),vig+V(200,360,900),vig+V(240,330,2400),vig+V(300,450,4200),vig+V(700,200,6500),vig+V(1100,-3500,9000),vig+V(1500,-11000,12500),vig+V(1900,-20000,16000),vig+V(2300,-30000,19500)}
    for _,q in ipairs(add) do P[#P+1]=q end
    -- arc-length table
    local tab={};local acc=0;local prev=P[1]
    local function pt(i) return P[math.max(1,math.min(#P,i))] end
    for i=1,#P-1 do
        local steps=math.max(8,math.floor(length(P[i+1]-P[i])/25))
        for k=0,steps-1 do
            local q=catmull(pt(i-1)+(i==1 and (P[1]-P[2]) or V(0,0,0)),P[i],P[i+1],pt(i+2)+(i+2>#P and (P[#P]-P[#P-1]) or V(0,0,0)),k/steps)
            acc=acc+length(q-prev);prev=q;tab[#tab+1]={s=acc,p=q,seg=i}
        end
    end
    tab[#tab+1]={s=acc+length(P[#P]-prev),p=P[#P],seg=#P-1}
    r.tab=tab;r.L=tab[#tab].s
    for _,e in ipairs(tab) do if e.seg<nCanyon then r.Lc=e.s end end
    for _,e in ipairs(tab) do if e.seg<#P-8 then r.La=e.s end end        -- end of the climb
    for _,e in ipairs(tab) do if e.seg<#P-2 then r.Lj=e.s end end        -- hyperspace jump point
    if cf.fileExists('spacesim-raidjump.flag','data',true) then r.s=r.Lj-4000 end
    r.climbOnly=cf.fileExists('spacesim-raidclimb.flag','data',true)
    if cf.fileExists('spacesim-raidattack.flag','data',true) then r.s=r.La-4000 end
    if r.climbOnly then r.s=r.Lc+300 end
    setSun(0.07,0.12)
    s.capital.Team=mn.Teams['Hostile'];s.capital:clearOrders()
    s.player.Target=s.capital
    hu.HUDDrawn=false
    r.cam=gr.createCamera('raid',s.player.Position,s.player.Orientation);gr.setCamera(r.cam)
    record(string.format('RAID_START length_km=%.1f canyon_km=%.1f climb_end_km=%.1f',r.L/1000,r.Lc/1000,r.La/1000));save()
end
local function sample(r,sv)
    local tab=r.tab;local lo,hi=1,#tab
    if sv<=0 then return tab[1].p end
    if sv>=r.L then return tab[#tab].p+(tab[#tab].p-tab[#tab-1].p)*((sv-r.L)/math.max(1,tab[#tab].s-tab[#tab-1].s)) end
    while hi-lo>1 do local m=math.floor((lo+hi)/2);if tab[m].s<sv then lo=m else hi=m end end
    local a=(sv-tab[lo].s)/math.max(1e-3,tab[hi].s-tab[lo].s)
    return vlerp(tab[lo].p,tab[hi].p,a)
end
local function speedAt(r,sv)
    local climb=r.La-r.Lc
    local v=270
    v=v+(3300-270)*sstep(r.Lc,r.Lc+climb*0.18,sv)
    v=v-(3300-210)*sstep(r.La-climb*0.30,r.La,sv)
    return v
end
local function smoothVec(old,new,k) if not old then return new end;return vlerp(old,new,k) end
function RAID.startWarp(r,t)
    -- lightspeed from the cockpit: FotG's own player hyperspace sequence (On Warp Out hook):
    -- S-foils close, star streaks, rolling camera, hyperspace sound, fade.
    r.warp=true;r.warpT=t
    if not r.inCockpit then r.inCockpit=true;gr.setCamera();hu.HUDDrawn=true end
    -- same path as the in-game 'engage subspace drive' key: FSO player warp-out sequence + FotG effects
    s.player:setFlag(false,'no-departure-warp')
    s.player:setFlag(false,'never-warp')
    local ok=ba.postGameEvent(ba.GameEvents['GS_EVENT_PLAYER_WARPOUT_START'])
    record('RAID_HYPERSPACE cockpit=true event='..tostring(ok)..' canWarp='..tostring(s.player:canWarp()));flush()
end
function RAID.warpUpdate(r,t)
    if s.captureOn and t>=r.nextShot and not r.pendingShot and t-r.warpT<7.6 then
        r.shotIndex=r.shotIndex+1;r.nextShot=t+0.33;r.pendingShot=string.format('raid_%03d_hyperespace',r.shotIndex)
    end
    if t-r.warpT>7.8 and not r.endShot then r.endShot=true;r.pendingShot='raid_end' end
end
function RAID.update(t,dt)
    local r=s.raidState
    if r.reported and not r.warp then return end
    local fdt=math.min(ba.getMissionFrametime(),0.35)
    if r.warp then RAID.warpUpdate(r,t);return end
    local v=speedAt(r,r.s);r.s=r.s+v*fdt
    if (r.short and r.s>=r.Lc) or (r.climbOnly and r.s>=r.La) or r.s>=r.Lj then
        r.reported=true;record('RAID_DONE')
        for name,st in pairs(r.stats) do
            table.sort(st.dts)
            local n=#st.dts;local sum=0 for _,x in ipairs(st.dts) do sum=sum+x end
            local p95=st.dts[math.max(1,math.floor(n*0.95))];local p99=st.dts[math.max(1,math.floor(n*0.99))]
            record(string.format('RAID_FPS phase=%s frames=%d seconds=%.1f fps_mean=%.2f fps_1pct_low=%.2f frame_p95_ms=%.1f frame_max_ms=%.1f',name,n,sum,n/sum,1/p99,p95*1000,st.dts[n]*1000))
        end
        record('RAID_SPIKES '..table.concat(r.spikes or {},' '))
        flush()
        if r.short or r.climbOnly then r.pendingShot='raid_end' else RAID.startWarp(r,t) end
        return
    end
    r.phase=r.s<r.Lc and 'canyon' or (r.s<r.La and 'ascension' or 'attaque')
    local pos=sample(r,r.s)
    local look=math.max(30,v*0.35)
    local fwd=unit(sample(r,r.s+look)-pos)
    local fwd2=unit(sample(r,r.s+look*2.5)-sample(r,r.s+look))
    local radial=unit(pos-C)
    local alt=length(pos-C)-80000
    local bankTarget=unit(radial+(fwd2-fwd)*(alt<6000 and 2.6 or 0.8))
    -- strafing run: the nose tracks the destroyer while the path follows the hull
    local vigP=s.capital.Position
    local toVig=vigP+V(0,-40,0)-pos;local dv=length(toVig)
    local aimW=0
    if r.s>r.La-2500 and r.s<r.Lj-2500 then
        local d0=unit(toVig);local ahead=d0.x*fwd.x+d0.y*fwd.y+d0.z*fwd.z
        aimW=sstep(7000,3500,dv)*sstep(-0.2,0.35,ahead)*0.75
    end
    if aimW>0 then fwd=unit(vlerp(fwd,unit(toVig),aimW)) end
    r.aimW=aimW
    r.fwd=unit(smoothVec(r.fwd,fwd,1-math.exp(-fdt*6)))
    r.up=unit(smoothVec(r.up,bankTarget,1-math.exp(-fdt*3)))
    local orient=ba.createOrientationFromVectors(r.fwd,r.up)
    s.player.Position=pos;s.player.Physics.Velocity=r.fwd*v;s.player.Orientation=orient
    -- weapons: lasers in the canyon, lasers + torpedoes on the destroyer when it is in front
    local vig=s.capital.Position
    if r.phase=='canyon' and t-r.lastFire>0.16 then s.player:firePrimary();r.lastFire=t end
    if r.phase=='attaque' then
        local tv=unit(vig-pos);local dot=tv.x*r.fwd.x+tv.y*r.fwd.y+tv.z*r.fwd.z
        local dist=length(vig-pos)
        if dot>0.55 and dist<4500 and t-r.lastFire>0.11 then s.player:firePrimary();r.lastFire=t end
        if dot>0.7 and dist<3800 and r.torps<2 and t-(r.lastTorp or 0)>2.5 then s.player:fireSecondary();r.torps=r.torps+1;r.lastTorp=t end
    end
    -- one camera, offset in the ship frame, blended continuously along the path
    local u=r.s
    local climb=r.La-r.Lc
    local chase={x=7,y=10,z=-46,la=140}
    local side={x=40,y=4,z=-14,la=70}
    local front={x=24,y=12,z=75,la=-60}
    local high={x=-12,y=16,z=-60,la=400}
    local function mixOff(a,b,w) return {x=a.x+(b.x-a.x)*w,y=a.y+(b.y-a.y)*w,z=a.z+(b.z-a.z)*w,la=a.la+(b.la-a.la)*w} end
    local off=chase
    off=mixOff(off,side,sstep(r.Lc*0.32,r.Lc*0.45,u)-sstep(r.Lc*0.62,r.Lc*0.75,u))
    off=mixOff(off,front,sstep(r.Lc+climb*0.10,r.Lc+climb*0.25,u)-sstep(r.La-climb*0.30,r.La-climb*0.12,u))
    off=mixOff(off,high,sstep(r.La-climb*0.12,r.La,u)-sstep(r.La+400,r.La+1800,u))
    -- after the pass over the destroyer: reverse shot, the destroyer stays in frame behind the X-wing
    local reverse={x=-26,y=14,z=90,la=-200}
    off=mixOff(off,reverse,sstep(r.La+900,r.La+1900,u)-sstep(r.Lj-4200,r.Lj-2600,u))
    local wide={x=150,y=24,z=60,la=120}
    off=mixOff(off,wide,sstep(r.Lj-1400,r.Lj-150,u))
    -- cockpit shots (jump cuts): canyon run past the batteries, destroyer attack
    local inCockpit=(u>r.Lc*0.15 and u<r.Lc*0.33) or (u>r.La-2600 and u<r.La-700) or (u>r.Lj-700)
    local ox,oy,oz=orient:getRvec(),orient:getUvec(),orient:getFvec()
    local want=ox*off.x+oy*off.y+oz*off.z
    r.camOff=smoothVec(r.camOff,want,1-math.exp(-fdt*2.5))
    local camPos=pos+r.camOff
    local target=vlerp(pos+oz*off.la,vigP,(r.aimW or 0)*0.55)
    local camUp=unit(vlerp(radial,oy,sstep(8000,30000,alt)))
    r.camLook=unit(smoothVec(r.camLook,unit(target-camPos),1-math.exp(-fdt*5)))
    if inCockpit then
        if not r.inCockpit then r.inCockpit=true;gr.setCamera();hu.HUDDrawn=true;record('RAID_COCKPIT on') end
        r.camLook=r.fwd
    else
        if r.inCockpit then r.inCockpit=false;hu.HUDDrawn=false;gr.setCamera(r.cam);record('RAID_COCKPIT off') end
        r.cam:setPosition(camPos);r.cam:setOrientation(ba.createOrientationFromVectors(r.camLook,camUp))
    end
    r.lastCam=camPos
    local st=r.stats[r.phase] or {dts={}};r.stats[r.phase]=st;st.dts[#st.dts+1]=dt
    if dt>0.08 then r.spikes=r.spikes or {};if #r.spikes<60 then r.spikes[#r.spikes+1]=string.format('%.2f:%.0f',t-r.t0,dt*1000) end end
    if s.captureOn and t>=r.nextShot and not r.pendingShot then
        r.shotIndex=r.shotIndex+1;r.nextShot=t+1.0
        r.pendingShot=string.format('raid_%03d_%s',r.shotIndex,r.phase)
    end
end
engine.addHook('On Simulation',function()
    if not s.active or not valid(s.player) then return end
    local t=mn.getMissionTime()
    if s.raidFlag==nil then s.raidFlag=cf.fileExists('spacesim-raid.flag','data',true);s.captureOn=cf.fileExists('spacesim-capture.flag','data',true) end
    if not s.raidFlag then return end
    if not s.raidState and t>1.0 then RAID.start(t) end
    if s.raidState then RAID.update(t,ba.getRealFrametime()) end
end)
engine.addHook('On Frame',function()
    local r=s.raidState
    if r and r.pendingShot then capture(r.pendingShot);r.pendingShot=nil end
    if r and r.warp and not r.endShot then RAID.warpUpdate(r,mn.getMissionTime()) end
end)

-- ===================== Streaming des entites au sol =====================
-- FotG ground ships (batteries, walkers, shuttle, cargo, beacons) keep AI and turrets running even
-- when invisible. They are vanished beyond 9 km from the camera/player and recreated identically
-- under 7 km (hysteresis). Props (buildings, forests, rocks) use empty LODs instead.
local STREAM={list=nil,nextCheck=0,FAR=9000,NEAR=7000}
local function streamInit()
    STREAM.list={}
    for i=1,#mn.Ships do
        local sh=mn.Ships[i]
        if sh and sh:isValid() then
            local n=sh.Name
            if n:find('^Batterie') or n:find('^AT%-AT') or n:find('^Balise') or n=='Lambda Ombre' or n=='Cargo 1'
               or n:find('^Bunker') or n:find('^Hangar') or n:find('^Caserne') or n:find('^Tour de') or n:find('^Reservoirs') then
                STREAM.list[#STREAM.list+1]={name=n,cls=sh.Class,team=sh.Team,pos=sh.Position,ori=sh.Orientation,live=true}
            end
        end
    end
    record(string.format('STREAM entities=%d far=%d near=%d',#STREAM.list,STREAM.FAR,STREAM.NEAR))
end
engine.addHook('On Simulation',function()
    if not s.active or not valid(s.player) then return end
    local t=mn.getMissionTime()
    if not STREAM.list then if t>0.5 then streamInit() end;return end
    if t<STREAM.nextCheck then return end
    STREAM.nextCheck=t+0.5
    local eye=s.player.Position
    if s.raidState and s.raidState.lastCam then eye=s.raidState.lastCam end
    local live,changed=0,0
    for _,e in ipairs(STREAM.list) do
        local d=distance(e.pos,eye)
        if e.live and not e.dead then
            -- destroyed by weapons: never bring it back
            local sh=mn.Ships[e.name]
            if not (sh and sh:isValid()) or sh:isDying() then e.dead=true;e.live=false end
        end
        if not e.dead then
            if e.live and d>STREAM.FAR then
                local sh=mn.Ships[e.name]
                if sh and sh:isValid() then e.ori=sh.Orientation;e.hull=sh.HitpointsLeft;sh:vanish() end
                e.live=false;changed=changed+1
            elseif not e.live and d<STREAM.NEAR then
                local sh=mn.createShip(e.name,e.cls,e.ori,e.pos,e.team,false)
                e.live=sh and sh:isValid()
                if e.live and e.hull then sh.HitpointsLeft=e.hull end    -- keep the damage already done
                changed=changed+1
            end
            if e.live then live=live+1 end
        end
    end
    if changed>0 then record(string.format('STREAM live=%d/%d changed=%d',live,#STREAM.list,changed)) end
end)

-- Shared helpers for other scripts of the mod (cinematic director).
SPACESIM={state=s,surface=surface,setSun=setSun,record=record,flush=flush,capture=capture,
          stream=STREAM,valid=valid,stop=function(r) stopSignal(r) end,boom=boom}
