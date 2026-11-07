
HRP = {
    enable_eventname = "EnableHangarRepair",
    enabled = false,
    static = {
        subject_ships = {
            "Grey Aurek 1",
        },
        repair_ships = {
            ["Liberty Type Star Cruiser"] = {
                subsystem = "Fighterbay01",
                shield_repair_mult = 1.0,
                hull_repair_mult = 1.0,
                subsys_repair_mult = 1.0,
                rearm_mult = 1.0,
                proximity_mult = 1.0,
            },
            ["Imperial Star Destroyer"] = {
                subsystem = "HangarCrane",
                shield_repair_mult = 1.0,
                hull_repair_mult = 1.0,
                subsys_repair_mult = 1.0,
                rearm_mult = 1.0,
                proximity_mult = 1.0,
            },
        },
        shield_repair_per_sec = 0.5,
        hull_repair_per_sec = 0.1,
        subsys_repair_per_sec = 0.2,
        rearm_per_sec = 0.2,
        proximity = 75.0
    }
}

--Code
    function HRP:OnGamePlayStart()

        if ba.MultiplayerMode or IS_STANDALONE then 
            self.enabled = false
            self.dynamic = nil
            return
		end

        if mn.Events[self.enable_eventname]:isValid() then
            self.enabled = true
            self.dynamic = {}
        else
            self.enabled = false
            self.dynamic = nil
            return
        end

        self.dynamic.repair_ships = {}
        setmetatable(HRP.dynamic.repair_ships, ASL.fso_metatable)

        for ship in mn.getShipList() do
            for _, name in ipairs(self.static.subject_ships) do
                if ship.Name == name then
                    local ammo = {}
                    for i = 1, #ship.PrimaryBanks do
                        local bank = ship.PrimaryBanks[i]
                        table.insert(ammo, bank.AmmoLeft / bank.AmmoMax)
                    end
                    self.dynamic.subject_ships = {}
                    table.insert(self.dynamic.subject_ships, {ship = ship, ammo = ammo})
                end
            end
            for class, repair_data in pairs(self.static.repair_ships) do
                if ship.Class.Name == class then
                    local relevant_subsystem = nil
                    for i = 1, #ship do
                        local subsystem = ship[i]
                        if subsystem.CanonicalName == repair_data.subsystem then
                            relevant_subsystem = i
                        end
                    end
                    if relevant_subsystem == nil then
                        ba.error("Subsystem "..repair_data.subsystem.." not found for ship "..ship.Name.."!")
                    end
                    self.dynamic.repair_ships[ship] = {}
                    local repair_ship = self.dynamic.repair_ships[ship]
                    repair_ship.subsystem = relevant_subsystem
                    repair_ship.shield_repair_mult = repair_data.shield_repair_mult
                    repair_ship.hull_repair_mult = repair_data.hull_repair_mult
                    repair_ship.subsys_repair_mult = repair_data.subsys_repair_mult
                    repair_ship.rearm_mult = repair_data.rearm_mult
                    repair_ship.proximity_mult = repair_data.proximity_mult
                end
            end
        end

    end

    function HRP:OnSimulation()

        if not self.enabled then
            return
        end

        local frametime = ba.getMissionFrametime()

        for _, subject_pair in ipairs(self.dynamic.subject_ships) do
            local subject = subject_pair.ship
            local ammo = subject_pair.ammo
            if subject ~= nil and subject:isValid() then
                for repair_ship, repair_data in pairs(self.dynamic.repair_ships) do
                    if repair_ship ~= nil and repair_ship:isValid() then
                        if subject.Team == repair_ship.Team then
                            local subject_pos = subject.Position
                            local subsys_pos = repair_ship[repair_data.subsystem].WorldPosition
                            if subject_pos:getDistanceSquared(subsys_pos) <= (self.static.proximity * repair_data.proximity_mult)^2 then
                                local shield_repair_factor = self.static.shield_repair_per_sec * repair_data.shield_repair_mult * frametime
                                local hull_repair_factor = self.static.hull_repair_per_sec * repair_data.hull_repair_mult * frametime
                                local subsys_repair_factor = self.static.subsys_repair_per_sec * repair_data.subsys_repair_mult * frametime
                                local rearm_factor = self.static.rearm_per_sec * repair_data.rearm_mult * frametime

                                local shields = subject.Shields
                                for i = 1, #shields do
                                    local quadrant_max = shields.CombinedMax / #shields
                                    shields[i] = math.min(quadrant_max, shields[i] + (quadrant_max * shield_repair_factor))
                                end
                                subject.HitpointsLeft = math.min(subject.HitpointsMax, subject.HitpointsLeft + (subject.HitpointsMax * hull_repair_factor))
                                for i = 1, #subject do
                                    local subsystem = subject[i]
                                    subsystem.HitpointsLeft = math.min(subsystem.HitpointsMax, subsystem.HitpointsLeft + (subsystem.HitpointsMax * subsys_repair_factor))
                                end

                                for i = 1, #subject.SecondaryBanks do
                                    if ammo[i] ~= nil then
                                        local bank = subject.SecondaryBanks[i]
                                        if (ammo[i] * bank.AmmoMax) - 1 > bank.AmmoLeft then
                                            ammo[i] = (bank.AmmoLeft + math.fmod((ammo[i] * bank.AmmoMax), 1)) / bank.AmmoMax
                                        end
                                        ammo[i] = math.min(1, ammo[i] + rearm_factor)
                                        bank.AmmoLeft = ammo[i] * bank.AmmoMax
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

    end

--

--Hooks
if not IS_STANDALONE then 
	engine.addHook("On Gameplay Start", function() 
			HRP:OnGamePlayStart()
		end
	)

    engine.addHook("On Simulation", function()
        HRP:OnSimulation()
    end)
end