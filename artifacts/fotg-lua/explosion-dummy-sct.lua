ExplosionDummy = {
    dummy_class = tb.ShipClasses["Explosion_Dummy"],
    dummy_lifetime_small = 15,
    dummy_lifetime_big = 180,
    small_class_types = {
        ["fighter"]=true,
        ["bomber"]=true,
        ["cargo"]=true,
        ["navbuoy"]=true,
        ["sentry gun"]=true,
        ["escape pod"]=true,
        ["support"]=true,
    },
    exceptions = {
        [tb.ShipClasses["Defense Mine#Ion"]:getShipClassIndex()] = true,
        [tb.ShipClasses["Asteroid#Small01"]:getShipClassIndex()] = true,
        [tb.ShipClasses["Asteroid#Small02"]:getShipClassIndex()] = true,
        [tb.ShipClasses["Asteroid#Small03"]:getShipClassIndex()] = true,
        [tb.ShipClasses["Asteroid#Medium01"]:getShipClassIndex()] = true,
        [tb.ShipClasses["Asteroid#Medium02"]:getShipClassIndex()] = true,
        [tb.ShipClasses["Asteroid#Medium03"]:getShipClassIndex()] = true,
        [tb.ShipClasses["Asteroid#Big01"]:getShipClassIndex()] = true,
        [tb.ShipClasses["Asteroid#Big02"]:getShipClassIndex()] = true,
        [tb.ShipClasses["Asteroid#Big03"]:getShipClassIndex()] = true,
        [tb.ShipClasses["ISD Debris#Small01"]:getShipClassIndex()] = true,
        [tb.ShipClasses["ISD Debris#Small02"]:getShipClassIndex()] = true,
        [tb.ShipClasses["ISD Debris#Small03"]:getShipClassIndex()] = true,
        [tb.ShipClasses["ISD Debris#Small04"]:getShipClassIndex()] = true,
        [tb.ShipClasses["ISD Debris#Small05"]:getShipClassIndex()] = true,
        [tb.ShipClasses["ISD Debris#Small06"]:getShipClassIndex()] = true,
        [tb.ShipClasses["ISD Debris#Big01"]:getShipClassIndex()] = true,
        [tb.ShipClasses["ISD Debris#Big02"]:getShipClassIndex()] = true,
        [tb.ShipClasses["ISD Debris#Big03"]:getShipClassIndex()] = true,
    },
    big_if_true = {
        [tb.ShipClasses["Firespray Gunship"]:getShipClassIndex()] = true,
        [tb.ShipClasses["Modified Firespray Gunship"]:getShipClassIndex()] = true,
        [tb.ShipClasses["Modified YT-1300 Freighter"]:getShipClassIndex()] = true,
        [tb.ShipClasses["Sensor Satellite#Reb"]:getShipClassIndex()] = true,
        [tb.ShipClasses["Sensor Satellite#Imp"]:getShipClassIndex()] = true,
    },
    particle_effects = {
        ["Imperial"] = {
            small = tb.ParticleEffects["PE_Explosion_Ship_Small_Imperial_Supplementary"],
            big = tb.ParticleEffects["PE_Explosion_Ship_Big_Imperial_Supplementary"],
        },
        ["Rebel"] = {
            small = tb.ParticleEffects["PE_Explosion_Ship_Small_Rebel_Supplementary"],
            big = tb.ParticleEffects["PE_Explosion_Ship_Big_Rebel_Supplementary"],
        },
        ["Pirate"] = {
            small = tb.ParticleEffects["PE_Explosion_Ship_Small_Rebel_Supplementary"],
            big = tb.ParticleEffects["PE_Explosion_Ship_Big_Rebel_Supplementary"],
        },
        ["Republic"] = {
            small = tb.ParticleEffects["PE_Explosion_Ship_Small_Rebel_Supplementary"],
            big = tb.ParticleEffects["PE_Explosion_Ship_Big_Rebel_Supplementary"],
        },
    },
    radius_factors = {
        [tb.ShipClasses["ASF-01 B-wing"]:getShipClassIndex()] = 1.5,
        [tb.ShipClasses["ASF-01 B-wing#Red"]:getShipClassIndex()] = 1.5,
        [tb.ShipClasses["ASF-01 B-wing#Blue"]:getShipClassIndex()] = 1.5,
        [tb.ShipClasses["ASF-01 B-wing#Gold"]:getShipClassIndex()] = 1.5,
        [tb.ShipClasses["ASF-01 B-wing#Green"]:getShipClassIndex()] = 1.5,
        [tb.ShipClasses["ASF-01 B-wing#Grey"]:getShipClassIndex()] = 1.5,
        [tb.ShipClasses["Defense Mine#Explosive"]:getShipClassIndex()] = 2.0,
        [tb.ShipClasses["DX-9 Stormtrooper Transport"]:getShipClassIndex()] = 1.5,
        [tb.ShipClasses["Lambda T-4a Shuttle"]:getShipClassIndex()] = 1.5,
        [tb.ShipClasses["Zeta Hvy Cargo Shuttle"]:getShipClassIndex()] = 1.2,
        [tb.ShipClasses["Firespray Gunship"]:getShipClassIndex()] = 1.5,
        [tb.ShipClasses["Modified Firespray Gunship"]:getShipClassIndex()] = 1.5,
        [tb.ShipClasses["YT-1300 Freighter"]:getShipClassIndex()] = 1.5,
        [tb.ShipClasses["Modified YT-1300 Freighter"]:getShipClassIndex()] = 1.5,
        [tb.ShipClasses["Star Speeder 3000"]:getShipClassIndex()] = 1.5,
        [tb.ShipClasses["Corellian Star Shuttle"]:getShipClassIndex()] = 1.15,
        [tb.ShipClasses["Corellian Star Shuttle#Rep"]:getShipClassIndex()] = 1.15,
        [tb.ShipClasses["BFF-1 Freighter"]:getShipClassIndex()] = 1.25,
        [tb.ShipClasses["BFF-1 Freighter#NoCargo"]:getShipClassIndex()] = 1.25,
        [tb.ShipClasses["Gozanti Cruiser#Imp"]:getShipClassIndex()] = 1.35,
        [tb.ShipClasses["Gozanti Cruiser#Rep"]:getShipClassIndex()] = 1.35,
        [tb.ShipClasses["Gozanti Cruiser#Pirate"]:getShipClassIndex()] = 1.35,
        [tb.ShipClasses["CR90 Corvette#Reb"]:getShipClassIndex()] = 1.3,
        [tb.ShipClasses["CR90 Corvette#Imp"]:getShipClassIndex()] = 1.3,
        [tb.ShipClasses["Carrack Lgt Cruiser#I"]:getShipClassIndex()] = 1.25,
        [tb.ShipClasses["Carrack Lgt Cruiser#R"]:getShipClassIndex()] = 1.25,
        [tb.ShipClasses["Nebulon-B Frigate"]:getShipClassIndex()] = 1.25,
        [tb.ShipClasses["MC30 Type Frigate"]:getShipClassIndex()] = 1.1,
        [tb.ShipClasses["Dreadnaught Hvy Cruiser#P"]:getShipClassIndex()] = 1.1,
        [tb.ShipClasses["Dreadnaught Hvy Cruiser#Reb"]:getShipClassIndex()] = 1.1,
        [tb.ShipClasses["Dreadnaught Hvy Cruiser#I"]:getShipClassIndex()] = 1.1,
        [tb.ShipClasses["Dreadnaught Hvy Cruiser#Rep"]:getShipClassIndex()] = 1.1,
        [tb.ShipClasses["Liberty Type Star Cruiser"]:getShipClassIndex()] = 1.1,
        [tb.ShipClasses["Imperial Star Destroyer"]:getShipClassIndex()] = 0.8,
        [tb.ShipClasses["Home One Type Star Cruiser"]:getShipClassIndex()] = 0.85,
        [tb.ShipClasses["Asteroid Base"]:getShipClassIndex()] = 1.95,
    }
}

    function ExplosionDummy:Run(ship)
        if ship:isPlayer() and Respawner:RespawnAllowed() then
            return
        end
        if FotG.DummyClasses[ship.Class.Name] then
            return 
        end
        if ExplosionDummy.exceptions[ship.Class:getShipClassIndex()] then
            return
        end
        local ship_is_small = ExplosionDummy.small_class_types[ship.Class.Type.Name] and not ExplosionDummy.big_if_true[ship.Class:getShipClassIndex()]
        async.run(function()
            local time = mn.getMissionTime()
            while mn.getMissionTime() >= time and ship ~= nil and ship:isValid() and ship:hasShipExploded() ~= 2 do
                async.await(async.yield())
                time = mn.getMissionTime()
            end
            if ship == nil or mn.getMissionTime() < time or (not ship:isValid()) then
                return
            end
            local dummy_lifetime
            if ship_is_small then
                dummy_lifetime = ExplosionDummy.dummy_lifetime_small
            else
                dummy_lifetime = ExplosionDummy.dummy_lifetime_big
            end
            local dummy_name = tostring(ship:getSignature())..";"
            local dummy = mn.createShip(dummy_name, ExplosionDummy.dummy_class, ship.Orientation, ship.Position, ship.Team, false)
            local factor = ExplosionDummy.radius_factors[ship.Class:getShipClassIndex()]
            if factor ~= nil then
                dummy.Radius = ship.Radius * factor
            else
                dummy.Radius = ship.Radius
            end
            dummy.Physics = ship.Physics
            local zero_vector = ba.createVector(0, 0, 0)
            dummy.Physics.RotationalVelocity = zero_vector
            dummy.Physics.RotationalVelocityDesired = zero_vector
            dummy.Physics.ShockwaveShakeAmplitude = 0
            dummy:addShipEffect("Instant Hide", 0)
            dummy:setFlag(true, "friendly-stealth-invisible", "no-dynamic", "protect-ship", "laser-protect-ship", "missile-protect-ship")
            if ship == nil then
                return
            end
            local category = ExplosionDummy.particle_effects[ship.Class.Species.Name]
            local explosion_effect
            if ship_is_small then
                explosion_effect = category.small
            else
                explosion_effect = category.big
            end
            local source = explosion_effect:createSource()
		    if source ~= nil then
		    	source:createOnObject(dummy, zero_vector)
		    end
            time = mn.getMissionTime()
            async.await(mn.waitAsync(dummy_lifetime))
            if mn.getMissionTime() >= time then
                time = mn.getMissionTime()
            else
                return
            end
            if dummy ~= nil then
                dummy:vanish()
            end
        end, async.OnFrameExecutor, false)
    end

if not IS_STANDALONE then 
    engine.addHook("On Ship Death", function()
            if not ba.MultiplayerMode and ba.getCurrentGameState().Name ~= "GS_STATE_LAB" and FotG.NebulaSliderCurrent > FotG.NebulaLowSetting then
                ExplosionDummy:Run(hv.Ship)
            end
        end
    )  
end