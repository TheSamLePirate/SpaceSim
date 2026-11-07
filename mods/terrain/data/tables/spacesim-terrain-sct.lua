-- SpaceSim terrain proof. Observation hooks never override native collisions.
-- The automatic demonstration changes velocity/orientation, never player position.
local state = { active=false }
local V = ba.createVector
local function valid(obj) return obj and obj:isValid() end
local function distance(a,b)
    return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)
end
local function record(text)
    local line=string.format("TERRAIN_PROOF t=%.3f %s",mn.getMissionTime(),text)
    state.lines[#state.lines+1]=line
    ba.print(line.."\n")
end
local function save()
    local file=cf.openFile("spacesim-terrain-telemetry.txt","w","data")
    if file then
        file:write(table.concat(state.lines,"\n").."\n")
        file:close()
    end
end
local function surface_at(x,z,top)
    if not valid(state.terrain) then return nil end
    return state.terrain:checkRayCollision(V(x,top or 12000,z),V(x,-600,z))
end
local function point_string(p) return string.format("x=%.3f y=%.3f z=%.3f",p.x,p.y,p.z) end

engine.addHook("On Gameplay Start",function()
    local filename=mn.getMissionFilename():lower()
    if not filename:find("_spt_terrain_") then state.active=false;return end
    state={active=true,automatic=filename:find("_auto")~=nil,lines={},collisions=0,probeContacts=0,phase="vallee",lastSave=-1,lastRay=-1,raySamples=0,maxStep=0,frames=0,time=0,agl=nil,finished=false,probePost=false}
    state.player=mn.Ships["Red 1"]
    state.probe=mn.Ships["Sonde collision"]
    state.capital=mn.Ships["Vigilance"]
    state.terrain=mn.Props["Terrain Aurore"]
    record("START mission="..filename.." auto="..tostring(state.automatic))
    record("TERRAIN present="..tostring(valid(state.terrain)))
    if valid(state.player) and valid(state.capital) then state.player.Target=state.capital end
    for _,xz in ipairs({{0,-2400},{0,0},{1000,-1000},{1800,900},{-2500,1500}}) do
        local p=surface_at(xz[1],xz[2])
        if p then
            state.raySamples=state.raySamples+1
            record("RAY_HIT "..point_string(p))
        else record(string.format("RAY_MISS x=%d z=%d",xz[1],xz[2])) end
    end
    save()
end)

local function observe_collision()
    if not state.active then return false end
    local ship,prop=hv.Ship,hv.Prop
    if valid(prop) and valid(ship) and prop:getSignature()==state.terrain:getSignature() then
        if ship:getSignature()==state.probe:getSignature() and state.probeContacts==0 then
            state.probeContacts=1
            state.probeContactTime=mn.getMissionTime()
            state.probeContactPosition=ship.Position
            record("NATIVE_COLLISION probe=1 hit="..point_string(hv.Hitpos).." incoming_vy="..string.format("%.3f",ship.Physics.Velocity.y))
            save()
        elseif ship:getSignature()==state.player:getSignature() then
            state.collisions=state.collisions+1
            if state.collisions<6 then record("PLAYER_CONTACT "..point_string(hv.Hitpos));save() end
        end
    end
    return false -- Native FSO collision physics always runs.
end
-- FSO 26.2's ship/prop handler queries the override callback but does not run the
-- normal notification callback. Observe there and always return false.
engine.addHook("On Prop Collision",function() end,{},observe_collision)

engine.addHook("On Simulation",function()
    if not state.active or not valid(state.player) then return end
    local t=mn.getMissionTime()
    local dt=ba.getMissionFrametime()
    state.frames=state.frames+1
    state.time=state.time+dt
    local pos=state.player.Position
    if state.previous then state.maxStep=math.max(state.maxStep,distance(pos,state.previous)) end
    state.previous=V(pos.x,pos.y,pos.z)
    -- The independent test craft descends into the actual terrain mesh.
    if valid(state.probe) and state.probeContacts==0 then
        state.probe.Physics.Velocity=V(0,-25,0)
    elseif valid(state.probe) and not state.probePost and t>(state.probeContactTime or t)+0.15 then
        state.probePost=true
        local p=state.probe.Position
        local hit=surface_at(p.x,p.z)
        state.probeClearance=hit and p.y-hit.y or -9999
        state.probeResponseY=state.probe.Physics.Velocity.y
        record(string.format("NATIVE_RESPONSE probe_y=%.3f clearance=%.3f vy=%.3f",p.y,state.probeClearance,state.probeResponseY))
        save()
    end
    if state.automatic and not state.finished then
        local vel
        if t<6 then
            vel=V(0,0,180)
            state.phase="vallee"
        elseif pos.y<5600 then
            vel=V(0,290,25)
            state.phase="ascension"
        else
            vel=V(0,0,0)
            state.phase="vaisseau"
            state.finished=true
        end
        state.player.Physics.Velocity=vel
        if not state.finished then
            state.player.Orientation=ba.createOrientationFromVectors(vel,V(0,1,0))
        else
            state.player.Orientation=ba.createOrientationFromVectors(state.capital.Position-pos,V(0,1,0))
        end
    end
    if t-state.lastRay>.15 then
        state.lastRay=t
        local hit=surface_at(pos.x,pos.z)
        state.agl=hit and pos.y-hit.y or nil
    end
    if t-state.lastSave>=1 then
        state.lastSave=t
        local dist=valid(state.capital) and distance(pos,state.capital.Position) or -1
        record(string.format("FLIGHT %s agl=%.3f target_m=%.3f phase=%s frames=%d",point_string(pos),state.agl or -1,dist,state.phase,state.frames))
        if pos.y>5000 and dist<3600 and not state.reached then
            state.reached=true
            record("ALTITUDE_GOAL reached=true same_mission=true")
        end
        if state.finished and not state.result then
            state.result=true
            local probePos=valid(state.probe) and state.probe.Position or V(0,-9999,0)
            local probeGround=surface_at(probePos.x,probePos.z)
            local finalClearance=probeGround and probePos.y-probeGround.y or -9999
            record(string.format("PROBE_FINAL clearance=%.3f %s",finalClearance,point_string(probePos)))
            local passed=state.raySamples==5 and state.probeContacts>0 and state.probePost and state.probeClearance>0 and finalClearance>0 and state.probeResponseY>-20 and state.reached and state.maxStep<100
            record(string.format("RESULT status=%s ray_hits=%d native_contacts=%d probe_clearance=%.3f reached=%s max_step_m=%.3f mission=%s",passed and "PASS" or "FAIL",state.raySamples,state.probeContacts,state.probeClearance or -9999,tostring(state.reached),state.maxStep,mn.getMissionFilename()))
            record("AUTO_DONE controls_released=true")
        end
        save()
    end
end)

engine.addHook("On HUD Draw",function()
    if not state.active then return end
    gr.setColor(130,225,255,255)
    gr.drawString("SPACESIM / TERRAIN 01",24,84)
    local agl=state.agl and string.format("%.0f m",state.agl) or "hors terrain"
    local pos=valid(state.player) and state.player.Position or V(0,0,0)
    gr.drawString(string.format("Sol: %s | Hauteur: %.0f m | Contacts sol: %d",agl,pos.y,state.collisions),24,107)
    gr.drawString(string.format("Sonde: %s | Geometrie: %d/5 | Mission unique",state.probeContacts>0 and "contact physique confirme" or "descente de test",state.raySamples),24,130)
    gr.drawString(state.automatic and ("Demonstration: "..state.phase..(state.finished and " / commandes libres" or "")) or "Vol libre: prenez la vallee, puis montez vers Vigilance (6 km).",24,153)
    if state.reached then gr.drawString("OBJECTIF ATTEINT : surface -> vaisseau, sans chargement",24,176) end
end)

engine.addHook("On Mission About To End",function()
    if state.active then record("END mission="..mn.getMissionFilename());save();state.active=false end
end)
