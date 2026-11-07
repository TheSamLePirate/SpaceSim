if not IS_STANDALONE then 
    local fso_metatable = {
        __index=function(tbl, key)
            for k, v in pairs(tbl) do
                if k == key then
                    return v
                end
            end
        end,
        __newindex=function(tbl, key, value)
            for k, v in pairs(tbl) do
                if k == key then
                    rawset(tbl, k, value)
                    return
                end
            end
            rawset(tbl, key, value)
        end
    }
 
    AAC = {
        static = {
            team_switching = {
                [mn.Teams["Friendly"]] = mn.Teams["Hostile"],
                [mn.Teams["Hostile"]] = mn.Teams["Friendly"],
            },
            target_subsystems = {
                [tb.ShipClasses["Liberty Type Star Cruiser"]:getShipClassIndex()] = {
                    ["EngineMainCenterA"] = "Engines",
                    ["EngineMainLeftA"] = "Engines",
                    ["EngineMainRightA"] = "Engines",
                    ["EngineAuxLeft01A"] = "Engines",
                    ["EngineAuxLeft02A"] = "Engines",
                    ["EngineAuxLeft03A"] = "Engines",
                    ["EngineAuxLeft04A"] = "Engines",
                    ["EngineAuxRight01A"] = "Engines",
                    ["EngineAuxRight02A"] = "Engines",
                    ["EngineAuxRight03A"] = "Engines",
                    ["EngineAuxRight04A"] = "Engines",
                    ["Reactor"] = "Reactor",
                    ["Sensor01A"] = "Sensors",
                    ["Sensor02A"] = "Sensors",
                    ["Sensor03A"] = "Sensors",
                    ["Communications01A"] = "Comms",
                    ["Communications02A"] = "Comms",
                    ["BridgeA"] = "Bridge",
                },
                [tb.ShipClasses["Imperial Star Destroyer"]:getShipClassIndex()] = {
                    ["Bridge"] = "Bridge",
                    ["Reactor"] = "Reactor",
                    ["Communications"] = "Comms",
                    ["SensorsLeft"] = "Sensors",
                    ["SensorsRight"] = "Sensors",
                    ["EngineLeft"] = "Engines",
                    ["EngineMiddle"] = "Engines",
                    ["EngineRight"] = "Engines",
                    ["EngineAuxTL"] = "Engines",
                    ["EngineAuxBL"] = "Engines",
                    ["EngineAuxTR"] = "Engines",
                    ["EngineAuxBR"] = "Engines",
                },
                
            },
            target_ships = {
                [tb.ShipClasses["CR90 Corvette#Reb"]:getShipClassIndex()] = true,
                [tb.ShipClasses["Raider Corvette"]:getShipClassIndex()] = true,
            },
        },
        dynamic = {},
    }
    
    setmetatable(AAC.static.team_switching, fso_metatable)
    
    --Code
        function AAC:rebuild_extant_target_list()
            self.dynamic = {
                clusters = {},
                bomber_wings = {},
            }
            setmetatable(AAC.dynamic.clusters, fso_metatable)
            setmetatable(AAC.dynamic.bomber_wings, fso_metatable)
            for ship in mn.getShipList() do
                local class_index = ship.Class:getShipClassIndex()
                if self.static.target_subsystems[class_index] ~= nil then
                    if self.dynamic.clusters[ship.Team] == nil then
                        self.dynamic.clusters[ship.Team] = {}
                    end
                    local team_cluster_list = self.dynamic.clusters[ship.Team]
                    for i = 1, #ship do
                        local subsystem = ship[i]
                        local cluster_name = self.static.target_subsystems[class_index][subsystem.CanonicalName]
                        if cluster_name ~= nil then
                            local tagged_cluster_name = ship.Name..";"..cluster_name
                            if team_cluster_list[tagged_cluster_name] == nil then
                                team_cluster_list[tagged_cluster_name] = {}
                            end
                            local cluster = team_cluster_list[tagged_cluster_name]
                            table.insert(cluster, subsystem)
                        end
                    end
                elseif self.static.target_ships[class_index] ~= nil then
                    if self.dynamic.clusters[ship.Team] == nil then
                        self.dynamic.clusters[ship.Team] = {}
                    end
                    local team_cluster_list = self.dynamic.clusters[ship.Team]
                    team_cluster_list[ship.Name] = {ship}
                end
            end
        end
        function AAC:randomize_reset_time(is_for_wing)
            if is_for_wing then
                return 999
            else
                return 999
            end
        end
        function AAC:bomber_fallback(wing)
            ba.warning("Bomber out of tasks!")
        end
        function AAC:attach_bomber_code_routine(wing)
            async.run(function()
                local startTime = time.getCurrentMissionTime()
                local startTimeWing = time.getCurrentMissionTime()
                local wingTargetName = nil
                local wingTarget = nil
                local waitTime = AAC:randomize_reset_time(false)
                local waitTimeWing = AAC:randomize_reset_time(true)
                while wing:isValid() do
                    local is_timestamp_elapsed = (time.getCurrentMissionTime() - startTime):getSeconds() > waitTime
                    local is_timestamp_wing_elapsed = (time.getCurrentMissionTime() - startTimeWing):getSeconds() > waitTimeWing
                    for shipnum = 1, #wing do
                        local ship = wing[shipnum]
                        if ship:isValid() and ship.HitpointsLeft > 0 and not ship:isArrivingWarp() and not ship:isDepartingDockbay() then
                            local orders = ship.Orders
                            if #orders > 1 then
                                ba.warning("Ship "..ship.Name.." has additional orders, despite being controlled by the assault script!")
                            end
                            if is_timestamp_elapsed
                            or #orders == 0
                            or not orders[1]:isValid()
                            or not orders[1].TargetSubsystem:isValid()
                            or orders[1].TargetSubsystem.HitpointsLeft <= 0 then
                                if wingTarget == nil or is_timestamp_wing_elapsed then
                                    is_timestamp_wing_elapsed = false
                                    waitTimeWing = AAC:randomize_reset_time(true)
                                    startTimeWing = time.getCurrentMissionTime()
                                    is_timestamp_elapsed = true
                                    local possibleWingTargets = self.dynamic.clusters[self.static.team_switching[ship.Team]]
                                    local targetsArray = {}
                                    for k, _ in pairs(possibleWingTargets) do
                                        table.insert(targetsArray, k)
                                    end
                                    if #targetsArray == 0 then
                                        AAC:bomber_fallback(wing)
                                        return
                                    end
                                    local arrayEntry = ba.rand32(1, #targetsArray)
                                    wingTargetName = targetsArray[arrayEntry]
                                    wingTarget = possibleWingTargets[targetsArray[arrayEntry]]
                                end
                                local targetableSubsystems = {}
                                while #targetableSubsystems == 0 do
                                    for _, subsystem in ipairs(wingTarget) do
                                        if subsystem:isValid() and subsystem.HitpointsLeft > 0 then
                                            table.insert(targetableSubsystems, subsystem)
                                        end
                                    end
                                    if #targetableSubsystems == 0 then
                                        local possibleWingTargets = self.dynamic.clusters[self.static.team_switching[ship.Team]]
                                        possibleWingTargets[wingTargetName] = nil
                                        local targetsArray = {}
                                        for k, _ in pairs(possibleWingTargets) do
                                            table.insert(targetsArray, k)
                                        end
                                        if #targetsArray == 0 then
                                            AAC:bomber_fallback(wing)
                                            return
                                        end
                                        local arrayEntry = ba.rand32(1, #targetsArray)
                                        wingTargetName = targetsArray[arrayEntry]
                                        wingTarget = possibleWingTargets[targetsArray[arrayEntry]]
                                    end
                                end
                                local new_target = targetableSubsystems[ba.rand32(1, #targetableSubsystems)]
                                ship:clearOrders()
                                if string.find(wingTargetName, ";") then
                                    ship:giveOrder(ORDER_ATTACK, new_target:getParent(), new_target)
                                else
                                    ship:giveOrder(ORDER_ATTACK, new_target)
                                end
                            end
                        end
                    end
                    if is_timestamp_elapsed then
                        waitTime = AAC:randomize_reset_time(false)
                        startTime = time.getCurrentMissionTime()
                    end
                    async.await(async.yield())
                end
            end, async.OnFrameExecutor)
        end
    --
end
