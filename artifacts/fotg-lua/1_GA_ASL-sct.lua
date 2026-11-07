if not IS_STANDALONE then
    ASL = {
        UNSHIELDED_FIGHTER_POINTS = 1,
        UNSHIELDED_BOMBER_POINTS = 3,
        SHIELDED_FIGHTER_POINTS = 3,
        SHIELDED_BOMBER_POINTS = 6,
        BOARDING_CRAFT_POINTS = 10,
        CORVETTE_POINTS = 32,

        fso_metatable = {__index=function(tbl, key)
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
        },
        godmode = false,
        enable_eventname = "EnableAssaultMode",
        enabled = false,
        types = {
            fighter = "fighter",
            bomber = "bomber",
            transport = "transport",
            cruiser = "cruiser",
            capital = "capital",
        },
        rebels = {
            subsys_point_value = {
                ["EngineMainCenterA"] = 8,
                ["EngineMainLeftA"] = 7,
                ["EngineMainRightA"] = 7,
                ["EngineAuxLeft01A"] = 4,
                ["EngineAuxLeft02A"] = 4,
                ["EngineAuxLeft03A"] = 4,
                ["EngineAuxLeft04A"] = 1,
                ["EngineAuxRight01A"] = 4,
                ["EngineAuxRight02A"] = 4,
                ["EngineAuxRight03A"] = 4,
                ["EngineAuxRight04A"] = 1,
                ["Reactor"] = 48,
                ["Sensor01A"] = 8,
                ["Sensor02A"] = 8,
                ["Sensor03A"] = 8,
                ["Communications01A"] = 12,
                ["Communications02A"] = 12,
                ["BridgeA"] = 24,
            },
            boarding = {
                subsys_name = "Fighterbay01",
                proximity = 75,
            },
        },
        empire = {
            subsys_point_value = {
                ["Bridge"] = 25,
                ["Reactor"] = 48,
                ["Communications"] = 24,
                ["SensorsLeft"] = 12,
                ["SensorsRight"] = 12,
                ["EngineLeft"] = 12,
                ["EngineMiddle"] = 12,
                ["EngineRight"] = 12,
                ["EngineAuxTL"] = 3,
                ["EngineAuxBL"] = 3,
                ["EngineAuxTR"] = 3,
                ["EngineAuxBR"] = 3,
            },
            boarding = {
                subsys_name = "Fighterbay01",
                proximity = 75,
            },
        },
        boarding_tasks = {
            autoturrets = 1,
            shields = 2,
            engines = 3,
            reactor = 4,
            none = 5,
        },
        boarding_status = {
            in_transit = 1,
            destroyed = 2,
            boarding = 3,
            successful = 4,
            none = 5,
        },
        boarding_craft_classes = {
            tb.ShipClasses["UT-60D U-wing"]:getShipClassIndex(),
            tb.ShipClasses["UT-60D U-wing#Red"]:getShipClassIndex(),
            tb.ShipClasses["UT-60D U-wing#Blue"]:getShipClassIndex(),
            tb.ShipClasses["UT-60D U-wing#Gold"]:getShipClassIndex(),
            tb.ShipClasses["UT-60D U-wing#Green"]:getShipClassIndex(),
            tb.ShipClasses["UT-60D U-wing#Grey"]:getShipClassIndex(),
            tb.ShipClasses["DX-9 Stormtrooper Transport"]:getShipClassIndex(),
        },
        fighter_swap_equivalents = {
            space_superiority = {
                rebel = tb.ShipClasses["T-65c X-wing#Grey"]:getShipClassIndex(),
                imperial = tb.ShipClasses["TIE/ln Fighter"]:getShipClassIndex(),
            },
            interceptor = {
                rebel = tb.ShipClasses["RZ-1 A-wing#Grey"]:getShipClassIndex(),
                imperial = tb.ShipClasses["TIE/In Interceptor Mk.2"]:getShipClassIndex(),
            },
            auxiliary_fighter = {
                rebel = tb.ShipClasses["Z-95 Headhunter#Grey"]:getShipClassIndex(),
                imperial = tb.ShipClasses["V38 Assault Fighter"]:getShipClassIndex(),
            },
            elite_fighter = {
                rebel = tb.ShipClasses["E-7 E-wing#Grey"]:getShipClassIndex(),
                imperial = tb.ShipClasses["TIE Advanced X1"]:getShipClassIndex(),
            },
            bomber = {
                rebel = tb.ShipClasses["BTL-A4 Y-wing#Grey"]:getShipClassIndex(),
                imperial = tb.ShipClasses["TIE/sa Bomber"]:getShipClassIndex(),
            },
            elite_bomber = {
                rebel = tb.ShipClasses["ASF-01 B-wing#Grey"]:getShipClassIndex(),
                imperial = tb.ShipClasses["XG-1 Star Wing"]:getShipClassIndex(),
            },
        },
        base_wing_respawn_intervals = {
            fighter_min = 30,
            fighter_max = 45,
            boarding_craft_min = 90,
            boarding_craft_max = 180,
        },
        messages = {
            isd_autoturrets_disabled_rebel = "Their auto-turret defenses have been disabled!",
            isd_autoturrets_disabled_imperial = "Our auto-turret defenses have been disabled!", -- *twirls moustache*
            isd_shields_down_rebel = "Their shields have been penetrated!",
            isd_shields_down_imperial = "Our shields have been penetrated!", -- *twirls moustache*
            isd_shields_disabled_rebel = "Their shield generator has been destroyed!",
            isd_shields_disabled_imperial = "Our shield generator has been destroyed!", -- *twirls moustache*
            isd_sensors_destroyed_rebel = "Their sensors array has been destroyed!",
            isd_sensors_destroyed_imperial = "Our sensors array has been destroyed!", -- *twirls moustache*
            isd_comms_destroyed_rebel = "Their communications relay has been destroyed!",
            isd_comms_destroyed_imperial = "Our communications relay has been destroyed!", -- *twirls moustache*
            isd_engines_destroyed_rebel = "Their engines have been destroyed!",
            isd_engines_destroyed_imperial = "Our engines have been destroyed!", -- *twirls moustache*
            isd_bridge_destroyed_rebel = "Their bridge has been destroyed!",
            isd_bridge_destroyed_imperial = "Our bridge has been destroyed!", -- *twirls moustache*
            isd_reactor_destroyed_rebel = "Their reactor has been destroyed!",
            isd_reactor_destroyed_imperial = "Our reactor has been destroyed!", -- *twirls moustache*
            isd_corvettes_destroyed_rebel = "Their corvettes have been destroyed!",
            isd_corvettes_destroyed_imperial = "Our corvettes have been destroyed!", -- *twirls moustache*
            isd_boarding_started_rebel = "Our boarding party has reached their hangar!",
            isd_boarding_started_imperial = "Their boarding party has reached our hangar!", -- *twirls moustache*
            isd_boarding_finished_rebel = "Our boarding party has planted charges!",
            isd_boarding_finished_imperial = "Their boarding party has planted charges!", -- *twirls moustache*

            mcc_autoturrets_disabled_rebel = "Our auto-turret defenses have been disabled!",
            mcc_autoturrets_disabled_imperial = "Their auto-turret defenses have been disabled!", -- *twirls moustache*
            mcc_shields_down_rebel = "Our shields have been penetrated!",
            mcc_shields_down_imperial = "Their shields have been penetrated!", -- *twirls moustache*
            mcc_shields_disabled_rebel = "Our shield generator has been destroyed!",
            mcc_shields_disabled_imperial = "Their shield generator has been destroyed!", -- *twirls moustache*
            mcc_sensors_destroyed_rebel = "Our sensors array has been destroyed!",
            mcc_sensors_destroyed_imperial = "Their sensors array has been destroyed!", -- *twirls moustache*
            mcc_comms_destroyed_rebel = "Our communications relay has been destroyed!",
            mcc_comms_destroyed_imperial = "Their communications relay has been destroyed!", -- *twirls moustache*
            mcc_engines_destroyed_rebel = "Our engines have been destroyed!",
            mcc_engines_destroyed_imperial = "Their engines have been destroyed!", -- *twirls moustache*
            mcc_bridge_destroyed_rebel = "Our bridge has been destroyed!",
            mcc_bridge_destroyed_imperial = "Their bridge has been destroyed!", -- *twirls moustache*
            mcc_reactor_destroyed_rebel = "Our reactor has been destroyed!",
            mcc_reactor_destroyed_imperial = "Their reactor has been destroyed!", -- *twirls moustache*
            mcc_corvettes_destroyed_rebel = "Our corvettes have been destroyed!",
            mcc_corvettes_destroyed_imperial = "Their corvettes have been destroyed!", -- *twirls moustache*
            mcc_boarding_started_rebel = "Their boarding party has reached our hangar!",
            mcc_boarding_started_imperial = "Our boarding party has reached their hangar!", -- *twirls moustache*
            mcc_boarding_finished_rebel = "Their boarding party has planted charges!",
            mcc_boarding_finished_imperial = "Our boarding party has planted charges!", -- *twirls moustache*
            
            rebel_victory = "We won! Yeah-hah!",
            imperial_defeat = "We have been defeated. Lord Vader will not be pleased.",
            rebel_defeat = "They may have won this battle, but the Rebellion's day will come.",
            imperial_victory = "The day is ours. Well done, gentlemen.",
        },
        keybinds = {
            swap_teams = io.Keybinding["MULTI_MESSAGE_ALL"],
            cycle_boarding_task = io.Keybinding["MULTI_MESSAGE_TARGET"],
        },

        cr90_class_index = tb.ShipClasses["CR90 Corvette#Reb"]:getShipClassIndex(),
        gr75_class_index = tb.ShipClasses["GR-75 Transport"]:getShipClassIndex(),
        raider_class_index = tb.ShipClasses["Raider Corvette"]:getShipClassIndex()
    }

    ASL.ship_score_data = {
        [tb.ShipClasses["T-65c X-wing"]:getShipClassIndex()] = {index = tb.ShipClasses["T-65c X-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["T-65c X-wing#Red"]:getShipClassIndex()] = {index = tb.ShipClasses["T-65c X-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["T-65c X-wing#Blue"]:getShipClassIndex()] = {index = tb.ShipClasses["T-65c X-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["T-65c X-wing#Gold"]:getShipClassIndex()] = {index = tb.ShipClasses["T-65c X-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["T-65c X-wing#Green"]:getShipClassIndex()] = {index = tb.ShipClasses["T-65c X-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["T-65c X-wing#Grey"]:getShipClassIndex()] = {index = tb.ShipClasses["T-65c X-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["RZ-1 A-wing"]:getShipClassIndex()] = {index = tb.ShipClasses["RZ-1 A-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["RZ-1 A-wing#Red"]:getShipClassIndex()] = {index = tb.ShipClasses["RZ-1 A-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["RZ-1 A-wing#Blue"]:getShipClassIndex()] = {index = tb.ShipClasses["RZ-1 A-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["RZ-1 A-wing#Gold"]:getShipClassIndex()] = {index = tb.ShipClasses["RZ-1 A-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["RZ-1 A-wing#Green"]:getShipClassIndex()] = {index = tb.ShipClasses["RZ-1 A-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["RZ-1 A-wing#Grey"]:getShipClassIndex()] = {index = tb.ShipClasses["RZ-1 A-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["Z-95 Headhunter"]:getShipClassIndex()] = {index = tb.ShipClasses["Z-95 Headhunter"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["Z-95 Headhunter#Red"]:getShipClassIndex()] = {index = tb.ShipClasses["Z-95 Headhunter"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["Z-95 Headhunter#Blue"]:getShipClassIndex()] = {index = tb.ShipClasses["Z-95 Headhunter"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["Z-95 Headhunter#Gold"]:getShipClassIndex()] = {index = tb.ShipClasses["Z-95 Headhunter"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["Z-95 Headhunter#Green"]:getShipClassIndex()] = {index = tb.ShipClasses["Z-95 Headhunter"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["Z-95 Headhunter#Grey"]:getShipClassIndex()] = {index = tb.ShipClasses["Z-95 Headhunter"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["E-7 E-wing"]:getShipClassIndex()] = {index = tb.ShipClasses["E-7 E-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["E-7 E-wing#Red"]:getShipClassIndex()] = {index = tb.ShipClasses["E-7 E-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["E-7 E-wing#Blue"]:getShipClassIndex()] = {index = tb.ShipClasses["E-7 E-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["E-7 E-wing#Gold"]:getShipClassIndex()] = {index = tb.ShipClasses["E-7 E-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["E-7 E-wing#Green"]:getShipClassIndex()] = {index = tb.ShipClasses["E-7 E-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["E-7 E-wing#Grey"]:getShipClassIndex()] = {index = tb.ShipClasses["E-7 E-wing"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["BTL-A4 Y-wing"]:getShipClassIndex()] = {index = tb.ShipClasses["BTL-A4 Y-wing"]:getShipClassIndex(), points = ASL.SHIELDED_BOMBER_POINTS,},
        [tb.ShipClasses["BTL-A4 Y-wing#Red"]:getShipClassIndex()] = {index = tb.ShipClasses["BTL-A4 Y-wing"]:getShipClassIndex(), points = ASL.SHIELDED_BOMBER_POINTS,},
        [tb.ShipClasses["BTL-A4 Y-wing#Blue"]:getShipClassIndex()] = {index = tb.ShipClasses["BTL-A4 Y-wing"]:getShipClassIndex(), points = ASL.SHIELDED_BOMBER_POINTS,},
        [tb.ShipClasses["BTL-A4 Y-wing#Gold"]:getShipClassIndex()] = {index = tb.ShipClasses["BTL-A4 Y-wing"]:getShipClassIndex(), points = ASL.SHIELDED_BOMBER_POINTS,},
        [tb.ShipClasses["BTL-A4 Y-wing#Green"]:getShipClassIndex()] = {index = tb.ShipClasses["BTL-A4 Y-wing"]:getShipClassIndex(), points = ASL.SHIELDED_BOMBER_POINTS,},
        [tb.ShipClasses["BTL-A4 Y-wing#Grey"]:getShipClassIndex()] = {index = tb.ShipClasses["BTL-A4 Y-wing"]:getShipClassIndex(), points = ASL.SHIELDED_BOMBER_POINTS,},
        [tb.ShipClasses["ASF-01 B-wing"]:getShipClassIndex()] = {index = tb.ShipClasses["ASF-01 B-wing"]:getShipClassIndex(), points = ASL.SHIELDED_BOMBER_POINTS,},
        [tb.ShipClasses["ASF-01 B-wing#Red"]:getShipClassIndex()] = {index = tb.ShipClasses["ASF-01 B-wing"]:getShipClassIndex(), points = ASL.SHIELDED_BOMBER_POINTS,},
        [tb.ShipClasses["ASF-01 B-wing#Blue"]:getShipClassIndex()] = {index = tb.ShipClasses["ASF-01 B-wing"]:getShipClassIndex(), points = ASL.SHIELDED_BOMBER_POINTS,},
        [tb.ShipClasses["ASF-01 B-wing#Gold"]:getShipClassIndex()] = {index = tb.ShipClasses["ASF-01 B-wing"]:getShipClassIndex(), points = ASL.SHIELDED_BOMBER_POINTS,},
        [tb.ShipClasses["ASF-01 B-wing#Green"]:getShipClassIndex()] = {index = tb.ShipClasses["ASF-01 B-wing"]:getShipClassIndex(), points = ASL.SHIELDED_BOMBER_POINTS,},
        [tb.ShipClasses["ASF-01 B-wing#Grey"]:getShipClassIndex()] = {index = tb.ShipClasses["ASF-01 B-wing"]:getShipClassIndex(), points = ASL.SHIELDED_BOMBER_POINTS,},
        [tb.ShipClasses["UT-60D U-wing"]:getShipClassIndex()] = {index = tb.ShipClasses["UT-60D U-wing"]:getShipClassIndex(), points = ASL.BOARDING_CRAFT_POINTS,},
        [tb.ShipClasses["UT-60D U-wing#Red"]:getShipClassIndex()] = {index = tb.ShipClasses["UT-60D U-wing"]:getShipClassIndex(), points = ASL.BOARDING_CRAFT_POINTS,},
        [tb.ShipClasses["UT-60D U-wing#Blue"]:getShipClassIndex()] = {index = tb.ShipClasses["UT-60D U-wing"]:getShipClassIndex(), points = ASL.BOARDING_CRAFT_POINTS,},
        [tb.ShipClasses["UT-60D U-wing#Gold"]:getShipClassIndex()] = {index = tb.ShipClasses["UT-60D U-wing"]:getShipClassIndex(), points = ASL.BOARDING_CRAFT_POINTS,},
        [tb.ShipClasses["UT-60D U-wing#Green"]:getShipClassIndex()] = {index = tb.ShipClasses["UT-60D U-wing"]:getShipClassIndex(), points = ASL.BOARDING_CRAFT_POINTS,},
        [tb.ShipClasses["UT-60D U-wing#Grey"]:getShipClassIndex()] = {index = tb.ShipClasses["UT-60D U-wing"]:getShipClassIndex(), points = ASL.BOARDING_CRAFT_POINTS,},
        [tb.ShipClasses["TIE/ln Fighter"]:getShipClassIndex()] = {index = tb.ShipClasses["TIE/ln Fighter"]:getShipClassIndex(), points = ASL.UNSHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["TIE/In Interceptor"]:getShipClassIndex()] = {index = tb.ShipClasses["TIE/In Interceptor"]:getShipClassIndex(), points = ASL.UNSHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["TIE/In Interceptor Mk.2"]:getShipClassIndex()] = {index = tb.ShipClasses["TIE/In Interceptor Mk.2"]:getShipClassIndex(), points = ASL.UNSHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["V38 Assault Fighter"]:getShipClassIndex()] = {index = tb.ShipClasses["V38 Assault Fighter"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["TIE Advanced X1"]:getShipClassIndex()] = {index = tb.ShipClasses["TIE Advanced X1"]:getShipClassIndex(), points = ASL.SHIELDED_FIGHTER_POINTS,},
        [tb.ShipClasses["TIE/sa Bomber"]:getShipClassIndex()] = {index = tb.ShipClasses["TIE/sa Bomber"]:getShipClassIndex(), points = ASL.UNSHIELDED_BOMBER_POINTS,},
        [tb.ShipClasses["XG-1 Star Wing"]:getShipClassIndex()] = {index = tb.ShipClasses["XG-1 Star Wing"]:getShipClassIndex(), points = ASL.SHIELDED_BOMBER_POINTS,},
        [tb.ShipClasses["DX-9 Stormtrooper Transport"]:getShipClassIndex()] = {index = tb.ShipClasses["DX-9 Stormtrooper Transport"]:getShipClassIndex(), points = ASL.BOARDING_CRAFT_POINTS,},
        [tb.ShipClasses["CR90 Corvette#Reb"]:getShipClassIndex()] = {index = tb.ShipClasses["CR90 Corvette#Reb"]:getShipClassIndex(), points = ASL.CORVETTE_POINTS,},
        [tb.ShipClasses["GR-75 Transport"]:getShipClassIndex()] = {index = tb.ShipClasses["GR-75 Transport"]:getShipClassIndex(), points = ASL.CORVETTE_POINTS,},
        [tb.ShipClasses["Raider Corvette"]:getShipClassIndex()] = {index = tb.ShipClasses["Raider Corvette"]:getShipClassIndex(), points = ASL.CORVETTE_POINTS,},
    }

    --Code

    function ASL:rebuildClusterList()
         ASL.dynamic.clusters = {}
        
        setmetatable(ASL.dynamic.clusters, ASL.fso_metatable)
        for ship in mn.getShipList() do
            local class_index = ship.Class:getShipClassIndex()
            if AAC.static.target_subsystems[class_index] ~= nil then
                local ship_index = nil
                if ship == ASL.rebels.capital.ship then
                    ship_index = ASL.rebels.capital.sig
                elseif ship == ASL.empire.capital.ship then
                    ship_index = ASL.empire.capital.sig
                end
                if ship_index == nil then
                    ba.warning("Valid ship index not found while building cluster list!")
                end
                local ship_list = ASL.dynamic.clusters
                for i = 1, #ship do
                    local subsystem = ship[i]
                    local cluster_name = AAC.static.target_subsystems[class_index][subsystem.CanonicalName]
                    if cluster_name ~= nil then
                        if ship_list[ship_index] == nil then
                            ship_list[ship_index] = {}
                            setmetatable(ship_list[ship_index], ASL.fso_metatable)
                        end
                        local cluster_list = ship_list[ship_index]
                        if cluster_list[cluster_name] == nil then
                            cluster_list[cluster_name] = {}
                        end
                        local cluster = cluster_list[cluster_name]
                        local subsys_data = {
                            system = subsystem,
                            name = subsystem.CanonicalName
                        }
                        table.insert(cluster, subsys_data)
                    end
                end
            end
        end
    end

    function ASL:sendMessage(message_text, sender)
        if ASL.dynamic.messages_done then
            return
        end
        local message = mn.Messages[1]
        message.Message = message_text
        if sender == nil then
            sender = "Command"
        end
        mn.sendMessage(sender, message)
    end

    function ASL:victoryLogic(victor)
        ASL.dynamic.finished = true
        async.run(function()
                local victory_start = time.getCurrentTime()

                async.await(mn.waitAsync(1))

                local player_is_victor = victor == ASL.dynamic.friendly
                local player_is_rebel = ASL.rebels.capital.team == ASL.dynamic.friendly
                local outcome_message
                if player_is_victor then
                    if player_is_rebel then
                        outcome_message = ASL.messages.rebel_victory
                    else
                        outcome_message = ASL.messages.imperial_victory
                    end
                else
                    if player_is_rebel then
                        outcome_message = ASL.messages.rebel_defeat
                    else
                        outcome_message = ASL.messages.imperial_defeat
                    end
                end

                ASL:sendMessage(outcome_message)

                ASL.dynamic.messages_done = true

                
                async.await(mn.waitAsync(1))
                
                local ship_to_destroy
                local destroyed_ship_data
                if ASL.empire.capital.ship.Team ~= victor then
                    ship_to_destroy = ASL.empire.capital.ship
                    destroyed_ship_data = ASL.empire.capital
                elseif ASL.rebels.capital.ship.Team ~= victor then
                    ship_to_destroy = ASL.rebels.capital.ship
                    destroyed_ship_data = ASL.rebels.capital
                end

                if ship_to_destroy ~= nil then
                    mn.evaluateSEXP("( set-subsystem-strength !"..ship_to_destroy.Name.."! !Hull! !0!)")
                end

                ASL.empire.capital.ship = nil
                ASL.rebels.capital.ship = nil

                async.await(mn.waitAsync(6))

                ASL:composeDebriefing(destroyed_ship_data, player_is_rebel)
                mn.evaluateSEXP("( lock-perspective ( true ) -1 ( true ) )")
                mn.evaluateSEXP("( set-time-compression !0.0001!)")
                mn.evaluateSEXP("( hud-set-builtin-gauge-active ( false ) !Messages! !Training messages! !Support! !Damage! !Wingman status! !Auto speed! !Auto target! !Countermeasures! !Talking head! !Directives! !Weapons! !Objective notifier! !Comm menu! !Lag indicator! !Mini shield! !Player shield! !Target shield! !Escort list! !Mission time! !Ets weapons! !Ets shields! !Ets engines! !Target monitor! !Extra target data! !Radar! !Radar orb! !Radar BSG! !Afterburner energy! !Weapon energy! !Text warnings! !Center reticle! !Throttle! !Threat indicator! !Lead indicator! !Lead sight! !Lock indicator! !Weapon linking! !Multiplayer messages! !Voice status! !Ping! !Supernova! !Offscreen indicator! !Targeting brackets! !Orientation! !Hostile direction! !Target direction! !Missile indicator! !Kills! !Fixed messages! !Ets retail! !Flight path! !Warhead count! !Hardpoints! !Primary weapons! !Secondary weapons! )")
                mn.evaluateSEXP("( hud-set-custom-gauge-active ( false ) !Targeting_Comp! !Fire_Stationary! !Fire_Burst! !CustomMessage_Frame! !CustomMessage_Body! !ExtraInfo_Frame! !ExtraInfo_Body! !CustomRoleGauge_Frame! !CustomRoleGauge_Body! !AssaultScoreFriendly! !AssaultScoreHostile! !AssaultStatusFriendly! !AssaultStatusHostile! !BoardingMonitorFrame! !BoardingMonitorBody! )")
                
                AutoAim:SetRendering(false)

                mn.evaluateSEXP("( hud-set-custom-gauge-active ( true ) !AssaultOutcome! )")
                local outcome_banner = hu.getHUDGaugeHandle("AssaultOutcome")
                if player_is_victor then
                    outcome_banner.Text = "VICTORY"
                    outcome_banner:setColor(75, 106, 255, 255)
                    outcome_banner:setPosition(724, 429)
                else
                    outcome_banner.Text = "DEFEAT"
                    outcome_banner:setColor(255, 60, 60, 255)
                    outcome_banner:setPosition(731, 429)
                end
                mn.evaluateSEXP("( set-immobile !Grey Aurek 1! )")
                mn.evaluateSEXP("( lock-primary-weapon !Grey Aurek 1! )")
                mn.evaluateSEXP("( lock-secondary-weapon !Grey Aurek 1! )")

                local screen_width = gr.getScreenWidth()
                local screen_height = gr.getScreenHeight()
                local startTime = time.getCurrentTime()
                local fade_start = 6.75
                local end_time = 8
                while (time.getCurrentTime() - startTime):getSeconds() < end_time do
                    local current_time = (time.getCurrentTime() - startTime):getSeconds()
                    local alpha_mult_pre_exponent = math.max(current_time - fade_start, 0) / (end_time - fade_start)
                    local alpha_mult = alpha_mult_pre_exponent^1.5
                    gr.setColor(0, 0, 0, alpha_mult * 255)
                    gr.drawRectangle(0, 0, screen_width, screen_height)
                    async.await(async.yield())
                end
                gr.setColor(0, 0, 0, 255)
                gr.drawRectangle(0, 0, screen_width, screen_height)
                mn.evaluateSEXP("( end-mission )")
            end, async.OnFrameExecutor
        )

    end

    function ASL:victoryCheck()
        if ASL.dynamic.finished then
            return
        end
        if ASL.dynamic.score[ASL.dynamic.friendly] >= ASL.dynamic.max_score[ASL.dynamic.friendly] then
            ASL:victoryLogic(ASL.dynamic.friendly)
        elseif ASL.dynamic.score[ASL.dynamic.hostile] >= ASL.dynamic.max_score[ASL.dynamic.hostile] then
            ASL:victoryLogic(ASL.dynamic.hostile)
        end
    end

    function ASL:updateScoreGauge()
        local padding_friendly = ""
        local padding_hostile = ""
        if ASL.dynamic.score[ASL.dynamic.friendly] < 10 then
            padding_friendly = "  "
        elseif ASL.dynamic.score[ASL.dynamic.friendly] < 100 then
            padding_friendly = " "
        end
        if ASL.dynamic.score[ASL.dynamic.hostile] < 10 then
            padding_hostile = "  "
        elseif ASL.dynamic.score[ASL.dynamic.hostile] < 100 then
            padding_hostile = " "
        end
        hu.getHUDGaugeHandle("AssaultScoreFriendly").Text = padding_friendly..ASL.dynamic.score[ASL.dynamic.friendly].." / "..ASL.dynamic.max_score[ASL.dynamic.friendly]
        hu.getHUDGaugeHandle("AssaultScoreHostile").Text = padding_hostile..ASL.dynamic.score[ASL.dynamic.hostile].." / "..ASL.dynamic.max_score[ASL.dynamic.hostile]
        ASL:victoryCheck()
    end

    function ASL:swapShipClass(new_class)
        local player_ship = FotG:GetPlayerShip()
        if player_ship == nil then return end
        if not player_ship:isValid() then return end
        if player_ship:getBreedName() ~= "Ship" then return end 

        ASL.dynamic.loadout_tracking[player_ship.Class:getShipClassIndex()] = {}
        ASL.dynamic.loadout_tracking[player_ship.Class:getShipClassIndex()].primary = {}
        ASL.dynamic.loadout_tracking[player_ship.Class:getShipClassIndex()].secondary = {}
        local new_loadout_entry = ASL.dynamic.loadout_tracking[player_ship.Class:getShipClassIndex()]
        for i = 1, #player_ship.PrimaryBanks do
            local bank = player_ship.PrimaryBanks[i]
            new_loadout_entry.primary[i] = {}
            new_loadout_entry.primary[i].class = bank.WeaponClass:getWeaponClassIndex()
        end
        for i = 1, #player_ship.SecondaryBanks do
            local bank = player_ship.SecondaryBanks[i]
            new_loadout_entry.secondary[i] = {}
            new_loadout_entry.secondary[i].class = bank.WeaponClass:getWeaponClassIndex()
            new_loadout_entry.secondary[i].left = bank.AmmoLeft
        end
        
        ChangeClassSafe:RunChange(new_class, player_ship)

        local changed_player = FotG:GetPlayerShip()
        if changed_player == nil then return end
        if not changed_player:isValid() then return end
        if changed_player:getBreedName() ~= "Ship" then return end 

        local old_loadout_entry = ASL.dynamic.loadout_tracking[changed_player.Class:getShipClassIndex()]
        if old_loadout_entry ~= nil then
            for i = 1, #changed_player.PrimaryBanks do
                local bank = changed_player.PrimaryBanks[i]
                local old_bank = old_loadout_entry.primary[i]
                if old_bank ~= nil then
                    bank.WeaponClass = tb.WeaponClasses[old_bank.class]
                end
            end
            for i = 1, #changed_player.SecondaryBanks do
                local bank = changed_player.SecondaryBanks[i]
                local old_bank = old_loadout_entry.secondary[i]
                if old_bank ~= nil then
                    bank.WeaponClass = tb.WeaponClasses[old_bank.class]
                    bank.AmmoLeft = old_bank.left
                end
            end
        end

        mn.evaluateSEXP("( hud-set-custom-gauge-active ( true ) !BoardingMonitorFrame! )")
        mn.evaluateSEXP("( hud-set-custom-gauge-active ( true ) !BoardingMonitorBody! )")

        mn.evaluateSEXP("( hud-set-custom-gauge-active ( true ) !AssaultStatusFriendly! )")
        mn.evaluateSEXP("( hud-set-custom-gauge-active ( true ) !AssaultStatusHostile! )")

        mn.evaluateSEXP("( hud-set-custom-gauge-active ( true ) !AssaultScoreFriendly! )")
        mn.evaluateSEXP("( hud-set-custom-gauge-active ( true ) !AssaultScoreHostile! )")
    end

    function ASL:swapAssaultScore(team1, team2)
        local team1_score = ASL.dynamic.score[team1]
        local team2_score = ASL.dynamic.score[team2]
        ASL.dynamic.score[team1] = team2_score
        ASL.dynamic.score[team2] = team1_score
    end

    function ASL:swapTeams(team_from, team_to, swap_player_ship)
        local swapping_to_imperial = ASL.empire.capital.team == team_to
        local swapping_to_rebel = ASL.rebels.capital.team == team_to
        if swapping_to_imperial == swapping_to_rebel then
            return
        end
        ASL:swapAssaultScore(team_from, team_to)
        local team_from_boarding_status = ASL.dynamic.boarding_status[team_from]
        local team_to_boarding_status = ASL.dynamic.boarding_status[team_to]
        if team_from_boarding_status ~= nil and team_to_boarding_status ~= nil then
            ASL.dynamic.boarding_status[team_from] = team_to_boarding_status
            ASL.dynamic.boarding_status[team_to] = team_from_boarding_status
        end

        local sexp_start = "( change-iff !"
        local rebel_entities = "!Mon Calamari Cruiser! !Corellian Corvette 1! !Corellian Corvette 2! !Rebel Transport 1! !Rebel Transport 2! !Red Aurek! !Red Besh! !Red Cresh! !Blue Aurek! !Blue Besh! !Blue Cresh! !Green Aurek! !Green Besh! !Green Cresh! !Gold Aurek! !Gold Besh! !Gold Cresh! !Rebel Boarding Craft! )"
        local imperial_entities = "!Star Destroyer! !Raider Corvette 1! !Raider Corvette 2! !Xi Aurek! !Xi Besh! !Xi Cresh! !Beta Aurek! !Beta Besh! !Beta Cresh! !Gamma Aurek! !Gamma Besh! !Gamma Cresh! !Delta Aurek! !Delta Besh! !Delta Cresh! !Imperial Boarding Craft! )"
        
        local respawn_object
        if swapping_to_imperial then
            local sexp_string_a = sexp_start..team_from.Name.."! "..imperial_entities
            local sexp_string_b = sexp_start..team_to.Name.."! "..rebel_entities
            mn.evaluateSEXP(sexp_string_a)
            mn.evaluateSEXP(sexp_string_b)
            ASL.empire.capital.team = team_from
            ASL.rebels.capital.team = team_to
            respawn_object = mn.Ships["ISD Spawn Exterior"]
            mn.evaluateSEXP("( set-squadron-wings !Xi Aurek! !Xi Besh! !Xi Cresh! )")
        else
            local sexp_string_a = sexp_start..team_from.Name.."! "..rebel_entities
            local sexp_string_b = sexp_start..team_to.Name.."! "..imperial_entities
            mn.evaluateSEXP(sexp_string_a)
            mn.evaluateSEXP(sexp_string_b)
            ASL.rebels.capital.team = team_from
            ASL.empire.capital.team = team_to
            local player = FotG:GetPlayerShip()
            if player == nil then return end
            if not player:isValid() then return end
            if player:getBreedName() ~= "Ship" then return end 
            if tb.ShipClasses[ASL.dynamic.fighter_swap_lookup[player.Class:getShipClassIndex()]].Name == "ASF-01 B-wing#Grey" then
                respawn_object = mn.Ships["MCC Spawn Exterior"]
            else
                respawn_object = mn.Ships["MCC Spawn Exterior"]
            end
            mn.evaluateSEXP("( set-squadron-wings !Red Aurek! !Red Besh! !Red Cresh! )")
        end

        Respawner:SetValues(1, true, true, respawn_object.Position.x, respawn_object.Position.y, respawn_object.Position.z, respawn_object.Orientation.p, respawn_object.Orientation.b, respawn_object.Orientation.h, false, true)

        if swap_player_ship then
            local player = FotG:GetPlayerShip()
            if player == nil then return end
            if not player:isValid() then return end
            if player:getBreedName() ~= "Ship" then return end 
            local new_class = tb.ShipClasses[ASL.dynamic.fighter_swap_lookup[player.Class:getShipClassIndex()]]
            ASL:swapShipClass(new_class)
        end
        ASL:updateScoreGauge()
        ASL:setWingIntervals()
    end

    function ASL:getBoardingTasks(capital)
        local tasks = {}
        local task_status = ASL.dynamic.objectives[capital.sig]

        if not task_status.autoturrets then
            table.insert(tasks, ASL.boarding_tasks.autoturrets)
        end
        if not task_status.shields_disabled then
            table.insert(tasks, ASL.boarding_tasks.shields)
        end
        if not task_status.engines then
            table.insert(tasks, ASL.boarding_tasks.engines)
        end
        if not task_status.reactor then
            table.insert(tasks, ASL.boarding_tasks.reactor)
        end

        return tasks
    end

    function ASL:cycleBoardingTask(capital)
        local tasks = ASL:getBoardingTasks(capital)

        if #tasks == 0 then
            ASL.dynamic.boarding_task = ASL.boarding_tasks.none
            return
        end
        
        local new_task_found = false
        for i = 1, 3 do
            for tasks_i = 1, #tasks do
                local candidate = ASL.dynamic.boarding_task + i
                if candidate > 4 then
                    candidate = candidate - 4
                end
                if tasks[tasks_i] == candidate then
                    ASL.dynamic.boarding_task = candidate
                    new_task_found = true
                    break
                end
            end
            if new_task_found then
                break
            end
        end
    end

    function ASL:selectBoardingTask(boarding_craft_team, capital)
        if boarding_craft_team == ASL.dynamic.friendly then
            local selection = ASL.dynamic.boarding_task
            ASL:cycleBoardingTask(capital)
            return selection
        else
            local tasks = ASL:getBoardingTasks(capital)

            if #tasks > 0 then
                return tasks[ba.rand32(1, #tasks)]
            else
                return ASL.boarding_tasks.none
            end
        end
    end

    function ASL:disableAutoturrets(capital)
        local turbo_lgt_red = tb.WeaponClasses["Turbo_Laser_Lgt#Red"]
        local turbo_lgt_grn = tb.WeaponClasses["Turbo_Laser_Lgt#Grn"]
        local turbo_med_red = tb.WeaponClasses["Turbo_Laser_Med#Red"]
        local turbo_med_grn = tb.WeaponClasses["Turbo_Laser_Med#Grn"]
        local turbo_hvy_red = tb.WeaponClasses["Turbo_Laser_Hvy#Red"]
        local turbo_hvy_grn = tb.WeaponClasses["Turbo_Laser_Hvy#Grn"]
        for i = 1, #capital.ship do
            local subsystem = capital.ship[i]
            local weaponclass = subsystem.PrimaryBanks[1].WeaponClass
            if weaponclass == turbo_lgt_red or
            weaponclass == turbo_lgt_grn or
            weaponclass == turbo_med_red or
            weaponclass == turbo_med_grn or
            weaponclass == turbo_hvy_red or
            weaponclass == turbo_hvy_grn then
                subsystem.TurretLocked = true
            end
        end

        local message_text
        if capital.sig == ASL.rebels.capital.sig then
            ASL.dynamic.objectives[ASL.rebels.capital.sig].autoturrets = true
            if capital.team == ASL.dynamic.friendly then
                message_text = ASL.messages.mcc_autoturrets_disabled_rebel
            else
                message_text = ASL.messages.mcc_autoturrets_disabled_imperial
            end
        elseif capital.sig == ASL.empire.capital.sig then
            ASL.dynamic.objectives[ASL.empire.capital.sig].autoturrets = true
            if capital.team == ASL.dynamic.friendly then
                message_text = ASL.messages.isd_autoturrets_disabled_imperial
            else
                message_text = ASL.messages.isd_autoturrets_disabled_rebel
            end
        end
        ASL:sendMessage(message_text)
        ASL:boardingCraftStopCheck(capital)
    end

    function ASL:boardingCraftLand(boarding_craft, capital)
        async.run(function()
                local boarding_craft_team = boarding_craft.Team

                local start_message_text
                if capital.sig == ASL.rebels.capital.sig then
                    if capital.team == ASL.dynamic.friendly then
                        start_message_text = ASL.messages.mcc_boarding_started_rebel
                    else
                        start_message_text = ASL.messages.mcc_boarding_started_imperial
                    end
                elseif capital.sig == ASL.empire.capital.sig then
                    if capital.team == ASL.dynamic.friendly then
                        start_message_text = ASL.messages.isd_boarding_started_imperial
                    else
                        start_message_text = ASL.messages.isd_boarding_started_rebel
                    end
                end
                ASL:sendMessage(start_message_text)

                if ASL.dynamic.boarding_status[boarding_craft_team] == ASL.boarding_status.in_transit then
                    ASL.dynamic.boarding_status[boarding_craft_team] = ASL.boarding_status.boarding
                end

                mn.evaluateSEXP("( destroy-instantly !"..boarding_craft.Name.."! )")

                if ASL.dynamic.finished then
                    return
                end

                async.await(mn.waitAsync(30))
                
                local end_message_text
                if capital.sig == ASL.rebels.capital.sig then
                    if capital.team == ASL.dynamic.friendly then
                        end_message_text = ASL.messages.mcc_boarding_finished_rebel
                    else
                        end_message_text = ASL.messages.mcc_boarding_finished_imperial
                    end
                elseif capital.sig == ASL.empire.capital.sig then
                    if capital.team == ASL.dynamic.friendly then
                        end_message_text = ASL.messages.isd_boarding_finished_imperial
                    else
                        end_message_text = ASL.messages.isd_boarding_finished_rebel
                    end
                end
                ASL:sendMessage(end_message_text)
                
                async.await(mn.waitAsync(5))

                if ASL.dynamic.finished then
                    return
                end

                local task = ASL:selectBoardingTask(boarding_craft_team, capital)
                if task == ASL.boarding_tasks.autoturrets then
                    ASL:disableAutoturrets(capital)
                    if ASL.dynamic.boarding_status[boarding_craft_team] == ASL.boarding_status.boarding then
                        ASL.dynamic.boarding_status[boarding_craft_team] = ASL.boarding_status.successful
                    end
                elseif task == ASL.boarding_tasks.shields then
                    mn.evaluateSEXP("( shields-off !"..capital.ship.Name.."! )")
                    ASL.dynamic.objectives[capital.sig].shields_disabled = true
                    local message_text
                    if capital.sig == ASL.rebels.capital.sig then
                        if capital.team == ASL.dynamic.friendly then
                            message_text = ASL.messages.mcc_shields_disabled_rebel
                        else
                            message_text = ASL.messages.mcc_shields_disabled_imperial
                        end
                    elseif capital.sig == ASL.empire.capital.sig then
                        if capital.team == ASL.dynamic.friendly then
                            message_text = ASL.messages.isd_shields_disabled_imperial
                        else
                            message_text = ASL.messages.isd_shields_disabled_rebel
                        end
                    end
                    ASL:sendMessage(message_text)
                    if ASL.dynamic.boarding_status[boarding_craft_team] == ASL.boarding_status.boarding then
                        ASL.dynamic.boarding_status[boarding_craft_team] = ASL.boarding_status.successful
                    end
                    ASL:boardingCraftStopCheck(capital)
                elseif task == ASL.boarding_tasks.engines then
                    mn.evaluateSEXP("( set-subsystem-strength !"..capital.ship.Name.."! !<all engines>! 0 )")
                    if ASL.dynamic.boarding_status[boarding_craft_team] == ASL.boarding_status.boarding then
                        ASL.dynamic.boarding_status[boarding_craft_team] = ASL.boarding_status.successful
                    end
                elseif task == ASL.boarding_tasks.reactor then
                    mn.evaluateSEXP("( set-subsystem-strength !"..capital.ship.Name.."! !Reactor! 0 )")
                    if ASL.dynamic.boarding_status[boarding_craft_team] == ASL.boarding_status.boarding then
                        ASL.dynamic.boarding_status[boarding_craft_team] = ASL.boarding_status.successful
                    end
                end
            end, async.OnFrameExecutor
        )
    end

    function ASL:boardingCraftLandCheck()
        if ASL.dynamic.finished then
            return
        end
        for boarding_craft in mn.getShipList() do
            if boarding_craft.HitpointsLeft > 0 then
                local is_boarding_craft = false
                for _, boarding_craft_class in ipairs(ASL.boarding_craft_classes) do
                    if boarding_craft.Class:getShipClassIndex() == boarding_craft_class then
                        is_boarding_craft = true
                    end
                end
                if is_boarding_craft then
                    if boarding_craft.Team ~= ASL.rebels.capital.team then
                        if ASL.rebels.capital.ship == nil then
                            return
                        elseif boarding_craft.Position:getDistanceSquared(ASL.rebels.capital.ship[ASL.dynamic.mcc_boarding.subsys_index].WorldPosition) <= ASL.rebels.boarding.proximity^2 then
                            ASL:boardingCraftLand(boarding_craft, ASL.rebels.capital)
                        end
                    elseif boarding_craft.Team ~= ASL.empire.capital.team then
                        if ASL.empire.capital.ship == nil then
                            return
                        elseif boarding_craft.Position:getDistanceSquared(ASL.empire.capital.ship[ASL.dynamic.isd_boarding.subsys_index].WorldPosition) <= ASL.empire.boarding.proximity^2 then
                            ASL:boardingCraftLand(boarding_craft, ASL.empire.capital)
                        end
                    end
                end
            end
        end
    end

    function ASL:boardingCraftStopCheck(capital)
        if #ASL:getBoardingTasks(capital) == 0 then
            local boarding_craft_team
            if capital.team == ASL.dynamic.friendly then
                boarding_craft_team = ASL.dynamic.hostile
            elseif capital.team == ASL.dynamic.hostile then
                boarding_craft_team = ASL.dynamic.friendly
            end
            if capital.sig == ASL.rebels.capital.sig and mn.SEXPVariables["imperial-boarding-stop"].Value == 0 then
                mn.SEXPVariables["imperial-boarding-stop"].Value = 1
                ASL.dynamic.boarding_status[boarding_craft_team] = ASL.boarding_status.none
                for boarding_craft in mn.getShipList() do
                    if boarding_craft.Team == boarding_craft_team then
                        for _, boarding_craft_class in ipairs(ASL.boarding_craft_classes) do
                            if boarding_craft.Class:getShipClassIndex() == boarding_craft_class then
                                boarding_craft:clearOrders()
                                boarding_craft:giveOrder(ORDER_ATTACK_ANY)
                            end
                        end
                    end
                end
            elseif capital.sig == ASL.empire.capital.sig and mn.SEXPVariables["rebel-boarding-stop"].Value == 0 then
                mn.SEXPVariables["rebel-boarding-stop"].Value = 1
                ASL.dynamic.boarding_status[boarding_craft_team] = ASL.boarding_status.none
                for boarding_craft in mn.getShipList() do
                    if boarding_craft.Team == boarding_craft_team then
                        for _, boarding_craft_class in ipairs(ASL.boarding_craft_classes) do
                            if boarding_craft.Class:getShipClassIndex() == boarding_craft_class then
                                boarding_craft:clearOrders()
                                boarding_craft:giveOrder(ORDER_ATTACK_ANY)
                            end
                        end
                    end
                end
            end
        end
    end

    function ASL:setWingInterval(wing)
        local difficulty = ba.getGameDifficulty()
        local min = 0
        local max = 0
        if wing[1].Class.Type.Name == ASL.types.transport then
            min = ASL.base_wing_respawn_intervals.boarding_craft_min
            max = ASL.base_wing_respawn_intervals.boarding_craft_max
        else
            min = ASL.base_wing_respawn_intervals.fighter_min
            max = ASL.base_wing_respawn_intervals.fighter_max
        end
        if wing[1].Team == ASL.dynamic.friendly then
            wing.WaveDelayMinimum = min
            wing.WaveDelayMaximum = max
        elseif wing[1].Team == ASL.dynamic.hostile then
            wing.WaveDelayMinimum = min - (((min - (min / 5)) / 5) * difficulty)
            wing.WaveDelayMaximum = max - (((max - (max / 5)) / 5) * difficulty)
        end
    end

    function ASL:setWingIntervals()
        for i = 1, #mn.Wings do
            ASL:setWingInterval(mn.Wings[i])
        end
    end

    function ASL:missionStart()

        if ba.MultiplayerMode or IS_STANDALONE then 
            ASL.enabled = false
            ASL.dynamic = nil
            ASL.rebels.capital = nil
            ASL.empire.capital = nil
			return 
		end

        if mn.Events[ASL.enable_eventname]:isValid() then
            ASL.enabled = true
            ASL.dynamic = {}
            ASL.rebels.capital = {}
            ASL.empire.capital = {}
        else
            ASL.enabled = false
            ASL.dynamic = nil
            ASL.rebels.capital = nil
            ASL.empire.capital = nil
            return
        end

        ASL.dynamic.friendly = mn.Teams["Friendly"]
        ASL.dynamic.hostile = mn.Teams["Hostile"]
        ASL.rebels.capital.ship = mn.Ships["Mon Calamari Cruiser"]
        ASL.rebels.capital.class = ASL.rebels.capital.ship.Class:getShipClassIndex()
        ASL.rebels.capital.sig = ASL.rebels.capital.ship:getSignature()
        ASL.rebels.capital.team = ASL.rebels.capital.ship.Team
        ASL.empire.capital.ship = mn.Ships["Star Destroyer"]
        ASL.empire.capital.class = ASL.empire.capital.ship.Class:getShipClassIndex()
        ASL.empire.capital.sig = ASL.empire.capital.ship:getSignature()
        ASL.empire.capital.team = ASL.empire.capital.ship.Team

        ASL.dynamic.fighter_swap_lookup = {}
        for _, entry in pairs(ASL.fighter_swap_equivalents) do
            ASL.dynamic.fighter_swap_lookup[entry.rebel] = entry.imperial
            ASL.dynamic.fighter_swap_lookup[entry.imperial] = entry.rebel
        end

        ASL.dynamic.victory_time = -1
        ASL.dynamic.finished = false
        ASL.dynamic.messages_done = false
        ASL.dynamic.score = {
            [ASL.dynamic.friendly] = 0,
            [ASL.dynamic.hostile] = 0,
        }

        ASL.dynamic.max_score = {
            [ASL.dynamic.friendly] = 400,
            [ASL.dynamic.hostile] = 400,
        }

        setmetatable(ASL.dynamic.score, ASL.fso_metatable)
        setmetatable(ASL.dynamic.max_score, ASL.fso_metatable)

        ASL:rebuildClusterList()

        ASL.dynamic.mcc_boarding = {}
        for i = 1, #ASL.rebels.capital.ship do
            local subsys = ASL.rebels.capital.ship[i]
            if subsys.CanonicalName == ASL.rebels.boarding.subsys_name then
                ASL.dynamic.mcc_boarding.subsys_index = i
            end
        end
        ASL.dynamic.isd_boarding = {}
        for i = 1, #ASL.empire.capital.ship do
            local subsys = ASL.empire.capital.ship[i]
            if subsys.CanonicalName == ASL.empire.boarding.subsys_name then
                ASL.dynamic.isd_boarding.subsys_index = i
            end
        end

        ASL.dynamic.objectives = {}
        ASL.dynamic.objectives[ASL.rebels.capital.sig] = {}
        ASL.dynamic.objectives[ASL.empire.capital.sig] = {}
        ASL.dynamic.objectives[ASL.rebels.capital.sig].autoturrets = false
        ASL.dynamic.objectives[ASL.rebels.capital.sig].shields_penetrated = false
        ASL.dynamic.objectives[ASL.rebels.capital.sig].shields_disabled = false
        ASL.dynamic.objectives[ASL.rebels.capital.sig].sensors = false
        ASL.dynamic.objectives[ASL.rebels.capital.sig].comms = false
        ASL.dynamic.objectives[ASL.rebels.capital.sig].engines = false
        ASL.dynamic.objectives[ASL.rebels.capital.sig].bridge = false
        ASL.dynamic.objectives[ASL.rebels.capital.sig].reactor = false
        ASL.dynamic.objectives[ASL.rebels.capital.sig].corvettes = false
        ASL.dynamic.objectives[ASL.empire.capital.sig].autoturrets = false
        ASL.dynamic.objectives[ASL.empire.capital.sig].shields_penetrated = false
        ASL.dynamic.objectives[ASL.empire.capital.sig].shields_disabled = false
        ASL.dynamic.objectives[ASL.empire.capital.sig].sensors = false
        ASL.dynamic.objectives[ASL.empire.capital.sig].comms = false
        ASL.dynamic.objectives[ASL.empire.capital.sig].engines = false
        ASL.dynamic.objectives[ASL.empire.capital.sig].bridge = false
        ASL.dynamic.objectives[ASL.empire.capital.sig].reactor = false
        ASL.dynamic.objectives[ASL.empire.capital.sig].corvettes = false
        setmetatable(ASL.dynamic.objectives, ASL.fso_metatable)

        ASL.dynamic.boarding_task = ASL.boarding_tasks.autoturrets
        ASL.dynamic.boarding_status = {}
        ASL.dynamic.boarding_status[ASL.dynamic.friendly] = ASL.boarding_status.none
        ASL.dynamic.boarding_status[ASL.dynamic.hostile] = ASL.boarding_status.none
        setmetatable(ASL.dynamic.boarding_status, ASL.fso_metatable)

        ASL.dynamic.kills = {}
        ASL.dynamic.kills[ASL.rebels.capital.sig] = {}
        ASL.dynamic.kills[ASL.empire.capital.sig] = {}
        setmetatable(ASL.dynamic.kills, ASL.fso_metatable)

        mn.evaluateSEXP("( hud-set-custom-gauge-active ( false ) !AssaultOutcome! )")
        
        mn.evaluateSEXP("( hud-set-custom-gauge-active ( true ) !BoardingMonitorFrame! )")
        mn.evaluateSEXP("( hud-set-custom-gauge-active ( true ) !BoardingMonitorBody! )")

        mn.evaluateSEXP("( hud-set-custom-gauge-active ( true ) !AssaultStatusFriendly! )")
        mn.evaluateSEXP("( hud-set-custom-gauge-active ( true ) !AssaultStatusHostile! )")

        mn.evaluateSEXP("( hud-set-custom-gauge-active ( true ) !AssaultScoreFriendly! )")
        mn.evaluateSEXP("( hud-set-custom-gauge-active ( true ) !AssaultScoreHostile! )")

        hu.getHUDGaugeHandle("BoardingMonitorFrame").Text = "Boarding Party (press "..ASL.keybinds.cycle_boarding_task:getInputName()..")"

        ASL:updateScoreGauge()

        local player = FotG:GetPlayerShip()
        if player == nil then return end
        if not player:isValid() then return end
        if player:getBreedName() ~= "Ship" then return end 

        player:setFlag(true, "no-subspace-drive")

        ASL.dynamic.loadout_tracking = {}

        local respawn_object
        local spawn_object
        if player.Class.Species.Name == "Imperial" then
            spawn_object = mn.Ships["ISD Spawn Interior"]
            ASL:swapTeams(ASL.dynamic.friendly, ASL.dynamic.hostile, false)
        else
            if player.Class.Name == "ASF-01 B-wing#Grey" then
                spawn_object = mn.Ships["MCC Spawn Exterior"]
                respawn_object = mn.Ships["MCC Spawn Exterior"]
            else
                spawn_object = mn.Ships["MCC Spawn Interior"]
                respawn_object = mn.Ships["MCC Spawn Exterior"]
            end
            Respawner:SetValues(1, true, true, respawn_object.Position.x, respawn_object.Position.y, respawn_object.Position.z, respawn_object.Orientation.p, respawn_object.Orientation.b, respawn_object.Orientation.h, false, true)
        end
        local player_ship = mn.Ships["Grey Aurek 1"]
        player_ship.Position = spawn_object.Position
        player_ship.Orientation = spawn_object.Orientation

        ChangeClassSafe:ResetQueue(true)
        ASL:swapShipClass(player_ship.Class)
        if Sfoils:GetSfoilsStatus(player) >= 0 and Sfoils:Should_Close_on_Hyper(string.filterInvisible(player.Class.Name)) then
            Sfoils:Toggle(player, Sfoils.method_close, true, false, 0)
            player:setFlag(true, "primaries-locked", "no-ets")
        end

        ASL.empire.capital.ship:triggerSubmodelAnimation("scripted", "HangarMain_ISD_Toggle", true, false, true, false)
        
        mn.evaluateSEXP("( ship-guardian-threshold 100 !Star Destroyer! !Mon Calamari Cruiser! )")

        async.run(function()
                async.await(async.yield())
                if ASL.godmode then
                    mn.evaluateSEXP("( ship-invulnerable !Grey Aurek 1! )")
                    mn.evaluateSEXP("( protect-ship !Grey Aurek 1! )")
                end
                mn.evaluateSEXP("( set-subsystem-special-hitpoints 33 !Star Destroyer! !EngineLeft! !Star Destroyer! !EngineMiddle! !Star Destroyer! !EngineRight! !Star Destroyer! !EngineAuxTL! !Star Destroyer! !EngineAuxBL! !Star Destroyer! !EngineAuxTR! !Star Destroyer! !EngineAuxBR! )")
                mn.evaluateSEXP("( set-subsystem-special-hitpoints 33 !Mon Calamari Cruiser! !EngineMainCenterA! !Mon Calamari Cruiser! !EngineMainLeftA! !Mon Calamari Cruiser! !EngineMainRightA! !Mon Calamari Cruiser! !EngineAuxLeft01A! !Mon Calamari Cruiser! !EngineAuxLeft02A! !Mon Calamari Cruiser! !EngineAuxLeft03A! !Mon Calamari Cruiser! !EngineAuxLeft04A! !Mon Calamari Cruiser! !EngineAuxRight01A! !Mon Calamari Cruiser! !EngineAuxRight02A! !Mon Calamari Cruiser! !EngineAuxRight03A! !Mon Calamari Cruiser! !EngineAuxRight04A! )")
                mn.evaluateSEXP("( set-shield-special-hitpoints 1500 !Star Destroyer! )")
                mn.evaluateSEXP("( set-shield-special-hitpoints 500 !Mon Calamari Cruiser! )")
            end, async.OnFrameExecutor
        )

        ASL:setWingIntervals()
    end

    function ASL:corvettesCheck()
        local any_cr90s = false
        local any_raiders = false
        for ship in mn.getShipList() do
            if (ship.Class:getShipClassIndex() == ASL.cr90_class_index or ship.Class:getShipClassIndex() == ASL.gr75_class_index) and not ship:isDying() then
                any_cr90s = true
            elseif ship.Class:getShipClassIndex() == ASL.raider_class_index and not ship:isDying() then
                any_raiders = true
            end
        end
        if (not any_cr90s) and (not ASL.dynamic.objectives[ASL.rebels.capital.sig].corvettes) then
            if ASL.rebels.capital.team == ASL.dynamic.friendly then
                ASL:sendMessage(ASL.messages.mcc_corvettes_destroyed_rebel)
            else
                ASL:sendMessage(ASL.messages.mcc_corvettes_destroyed_imperial)
            end
            ASL.dynamic.objectives[ASL.rebels.capital.sig].corvettes = true
        end
        if (not any_raiders) and (not ASL.dynamic.objectives[ASL.empire.capital.sig].corvettes) then
            if ASL.empire.capital.team == ASL.dynamic.friendly then
                ASL:sendMessage(ASL.messages.isd_corvettes_destroyed_imperial)
            else
                ASL:sendMessage(ASL.messages.isd_corvettes_destroyed_rebel)
            end
            ASL.dynamic.objectives[ASL.empire.capital.sig].corvettes = true
        end
    end

    function ASL:shieldCheck(capital)
        local actual_capital = capital.ship
        if actual_capital == nil then
            return
        end
        local objectives = ASL.dynamic.objectives[capital.sig]
        if objectives.shields_penetrated or objectives.shields_disabled then
            return
        end
        local capital_is_hostile = capital.team ~= ASL.dynamic.friendly
        local capital_is_isd = capital.sig == ASL.empire.capital.sig
        local shields = actual_capital.Shields
        local quadrant_max = shields.CombinedMax / #shields
        for i = 1, #shields do
            if shields[i] <= quadrant_max * 0.05 then
                objectives.shields_penetrated = true
                if capital_is_isd then
                    if capital_is_hostile then
                        ASL:sendMessage(ASL.messages.isd_shields_down_rebel)
                    else
                        ASL:sendMessage(ASL.messages.isd_shields_down_imperial)
                    end
                else
                    if capital_is_hostile then
                        ASL:sendMessage(ASL.messages.mcc_shields_down_imperial)
                    else
                        ASL:sendMessage(ASL.messages.mcc_shields_down_rebel)
                    end
                end
            end
        end
    end

    function ASL:getClusterHealth(cluster)
        local current_hits = 0
        local max_hits = 0
        for _, subsys_data in ipairs(cluster) do
            current_hits = current_hits + subsys_data.system.HitpointsLeft
            max_hits = max_hits + subsys_data.system.HitpointsMax
        end
        return current_hits / max_hits
    end

    function ASL:clusterCheck(capital)
        if capital.ship == nil then
            return
        end
        local cluster_list = ASL.dynamic.clusters[capital.sig]
        local objective_status = ASL.dynamic.objectives[capital.sig]
        local capital_is_hostile = capital.team ~= ASL.dynamic.friendly
        local capital_is_isd = capital.sig == ASL.empire.capital.sig
        if (not objective_status.sensors) and ASL:getClusterHealth(cluster_list["Sensors"]) <= 0 then
            objective_status.sensors = true
            if capital_is_isd then
                if capital_is_hostile then
                    ASL:sendMessage(ASL.messages.isd_sensors_destroyed_rebel)
                else
                    ASL:sendMessage(ASL.messages.isd_sensors_destroyed_imperial)
                end
            else
                if capital_is_hostile then
                    ASL:sendMessage(ASL.messages.mcc_sensors_destroyed_imperial)
                else
                    ASL:sendMessage(ASL.messages.mcc_sensors_destroyed_rebel)
                end
            end
        end
        if (not objective_status.comms) and ASL:getClusterHealth(cluster_list["Comms"]) <= 0 then
            objective_status.comms = true
            if capital_is_isd then
                if capital_is_hostile then
                    ASL:sendMessage(ASL.messages.isd_comms_destroyed_rebel)
                else
                    ASL:sendMessage(ASL.messages.isd_comms_destroyed_imperial)
                end
            else
                if capital_is_hostile then
                    ASL:sendMessage(ASL.messages.mcc_comms_destroyed_imperial)
                else
                    ASL:sendMessage(ASL.messages.mcc_comms_destroyed_rebel)
                end
            end
        end
        if (not objective_status.engines) and ASL:getClusterHealth(cluster_list["Engines"]) <= 0 then
            objective_status.engines = true
            if capital_is_isd then
                if capital_is_hostile then
                    ASL:sendMessage(ASL.messages.isd_engines_destroyed_rebel)
                else
                    ASL:sendMessage(ASL.messages.isd_engines_destroyed_imperial)
                end
            else
                if capital_is_hostile then
                    ASL:sendMessage(ASL.messages.mcc_engines_destroyed_imperial)
                else
                    ASL:sendMessage(ASL.messages.mcc_engines_destroyed_rebel)
                end
            end
            if ASL.dynamic.boarding_task == ASL.boarding_tasks.engines then
                ASL:cycleBoardingTask(capital)
            end
            ASL:boardingCraftStopCheck(capital)
        end
        if (not objective_status.bridge) and ASL:getClusterHealth(cluster_list["Bridge"]) <= 0 then
            objective_status.bridge = true
            if capital_is_isd then
                if capital_is_hostile then
                    ASL:sendMessage(ASL.messages.isd_bridge_destroyed_rebel)
                else
                    ASL:sendMessage(ASL.messages.isd_bridge_destroyed_imperial)
                end
            else
                if capital_is_hostile then
                    ASL:sendMessage(ASL.messages.mcc_bridge_destroyed_imperial)
                else
                    ASL:sendMessage(ASL.messages.mcc_bridge_destroyed_rebel)
                end
            end
        end
        if (not objective_status.reactor) and ASL:getClusterHealth(cluster_list["Reactor"]) <= 0 then
            objective_status.reactor = true
            if capital_is_isd then
                if capital_is_hostile then
                    ASL:sendMessage(ASL.messages.isd_reactor_destroyed_rebel)
                else
                    ASL:sendMessage(ASL.messages.isd_reactor_destroyed_imperial)
                end
            else
                if capital_is_hostile then
                    ASL:sendMessage(ASL.messages.mcc_reactor_destroyed_imperial)
                else
                    ASL:sendMessage(ASL.messages.mcc_reactor_destroyed_rebel)
                end
            end
            if ASL.dynamic.boarding_task == ASL.boarding_tasks.reactor then
                ASL:cycleBoardingTask(capital)
            end
            ASL:boardingCraftStopCheck(capital)
        end
    end

    function ASL:updateStatusGauges()
        local mcc_text = "MON CALAMARI CRUISER\n"
        local isd_text = "IMPERIAL STAR DESTROYER\n"

        local friendly_text = ""
        local friendly_cluster_list
        if ASL.rebels.capital.team == ASL.dynamic.friendly then
            friendly_cluster_list = ASL.dynamic.clusters[ASL.rebels.capital.sig]
            friendly_text = mcc_text
        elseif ASL.empire.capital.team == ASL.dynamic.friendly then
            friendly_cluster_list = ASL.dynamic.clusters[ASL.empire.capital.sig]
            friendly_text = isd_text
        end
        if friendly_cluster_list ~= nil then
            for cluster_name, cluster in pairs(friendly_cluster_list) do
                local cluster_health = ASL:getClusterHealth(cluster)
                local cluster_health_print
                if  (cluster_health > 0) then
                    cluster_health_print = string.format("%.0f", cluster_health * 100)
                else
                    cluster_health_print = "DESTROYED"
                end
                local spaces = ""
                for i = 0, 10 - string.len(cluster_name) do
                    spaces = spaces.." "
                end
                friendly_text = friendly_text..cluster_name..": "..spaces..cluster_health_print.."\n"
            end
            hu.getHUDGaugeHandle("AssaultStatusFriendly").Text = friendly_text
        end

        local hostile_text = ""
        local hostile_cluster_list
        if ASL.rebels.capital.team == ASL.dynamic.hostile then
            hostile_cluster_list = ASL.dynamic.clusters[ASL.rebels.capital.sig]
            hostile_text = mcc_text
        elseif ASL.empire.capital.team == ASL.dynamic.hostile then
            hostile_cluster_list = ASL.dynamic.clusters[ASL.empire.capital.sig]
            hostile_text = isd_text
        end
        if hostile_cluster_list ~= nil then
            for cluster_name, cluster in pairs(hostile_cluster_list) do
                local cluster_health = ASL:getClusterHealth(cluster)
                local cluster_health_print
                if  (cluster_health > 0) then
                    cluster_health_print = string.format("%.0f", cluster_health * 100)
                else
                    cluster_health_print = "DESTROYED"
                end
                local spaces = ""
                for i = 0, 10 - string.len(cluster_name) do
                    spaces = spaces.." "
                end
                hostile_text = hostile_text..cluster_name..": "..spaces..cluster_health_print.."\n"
            end
            hu.getHUDGaugeHandle("AssaultStatusHostile").Text = hostile_text
        end
    end

    function ASL:updateBoardingGauge()
        local status = "None"
        if ASL.dynamic.boarding_status[ASL.dynamic.friendly] == ASL.boarding_status.in_transit then
            status = "In Transit"
        elseif ASL.dynamic.boarding_status[ASL.dynamic.friendly] == ASL.boarding_status.destroyed then
            status = "Destroyed"
        elseif ASL.dynamic.boarding_status[ASL.dynamic.friendly] == ASL.boarding_status.boarding then
            status = "Boarding Action In Progress"
        elseif ASL.dynamic.boarding_status[ASL.dynamic.friendly] == ASL.boarding_status.successful then
            status = "Boarding Action Successful"
        end
        local task = "None"
        if ASL.dynamic.boarding_task == ASL.boarding_tasks.autoturrets then
            task = "Auto-Defense Mainframe"
        elseif ASL.dynamic.boarding_task == ASL.boarding_tasks.shields then
            task = "Shield Generator"
        elseif ASL.dynamic.boarding_task == ASL.boarding_tasks.engines then
            task = "Engine Coolant Pipes"
        elseif ASL.dynamic.boarding_task == ASL.boarding_tasks.reactor then
            task = "Reactor Control Console"
        end
        hu.getHUDGaugeHandle("BoardingMonitorBody").Text = "Status: "..status.."\n".."Objective: "..task
    end

    function ASL:composeDebriefing(destroyed_capital, player_is_rebel)
        local newline = "\n"
        local victor_string
        local judgment
        if destroyed_capital.sig == ASL.empire.capital.sig then
            victor_string = "Rebels"
            if player_is_rebel then
                judgment = "Excellent job!"
            else
                judgment = "Better luck next time!"
            end
        else
            victor_string = "Empire"
            if player_is_rebel then
                judgment = "Better luck next time!"
            else
                judgment = "Excellent job!"
            end
        end
        local intro = victor_string.." won! "..judgment..newline

        local rebel_header = "REBEL ACHIEVEMENTS"..newline
        local rebel_obj_destroyed = "Objectives destroyed:"..newline
        if ASL.dynamic.objectives[ASL.empire.capital.sig].sensors then
            local point_value = 0
            for i = 1, #ASL.dynamic.clusters[ASL.empire.capital.sig]["Sensors"] do
                local subsys_name = ASL.dynamic.clusters[ASL.empire.capital.sig]["Sensors"][i].name
                point_value = point_value + ASL.empire.subsys_point_value[subsys_name]
            end
            rebel_obj_destroyed = rebel_obj_destroyed.."Star Destroyer Sensors Array ("..point_value.." pts)"..newline
        end
        if ASL.dynamic.objectives[ASL.empire.capital.sig].comms then
            local point_value = 0
            for i = 1, #ASL.dynamic.clusters[ASL.empire.capital.sig]["Comms"] do
                local subsys_name = ASL.dynamic.clusters[ASL.empire.capital.sig]["Comms"][i].name
                point_value = point_value + ASL.empire.subsys_point_value[subsys_name]
            end
            rebel_obj_destroyed = rebel_obj_destroyed.."Star Destroyer Communications Relay ("..point_value.." pts)"..newline
        end
        if ASL.dynamic.objectives[ASL.empire.capital.sig].engines then
            local point_value = 0
            for i = 1, #ASL.dynamic.clusters[ASL.empire.capital.sig]["Engines"] do
                local subsys_name = ASL.dynamic.clusters[ASL.empire.capital.sig]["Engines"][i].name
                point_value = point_value + ASL.empire.subsys_point_value[subsys_name]
            end
            rebel_obj_destroyed = rebel_obj_destroyed.."Star Destroyer Engines ("..point_value.." pts)"..newline
        end
        if ASL.dynamic.objectives[ASL.empire.capital.sig].bridge then
            local point_value = 0
            for i = 1, #ASL.dynamic.clusters[ASL.empire.capital.sig]["Bridge"] do
                local subsys_name = ASL.dynamic.clusters[ASL.empire.capital.sig]["Bridge"][i].name
                point_value = point_value + ASL.empire.subsys_point_value[subsys_name]
            end
            rebel_obj_destroyed = rebel_obj_destroyed.."Star Destroyer Bridge ("..point_value.." pts)"..newline
        end
        if ASL.dynamic.objectives[ASL.empire.capital.sig].reactor then
            local point_value = 0
            for i = 1, #ASL.dynamic.clusters[ASL.empire.capital.sig]["Reactor"] do
                local subsys_name = ASL.dynamic.clusters[ASL.empire.capital.sig]["Reactor"][i].name
                point_value = point_value + ASL.empire.subsys_point_value[subsys_name]
            end
            rebel_obj_destroyed = rebel_obj_destroyed.."Star Destroyer Reactor ("..point_value.." pts)"..newline
        end
        local rebel_kills = "Kills:"..newline
        local rebel_kills_data = ASL.dynamic.kills[ASL.rebels.capital.sig]
        --awful magic number stuff; the indices aren't contiguous, so we have to iterate over the maximum number of kill entries we could conceivably have
        for i = 1, #tb.ShipClasses do
            local entry = rebel_kills_data[i]
            if entry ~= nil then
                local class_name = tb.ShipClasses[ASL.ship_score_data[i].index].AltName
                local point_value = ASL.ship_score_data[i].points
                if point_value == nil then
                    point_value = 0
                end
                rebel_kills = rebel_kills..class_name..": "..entry.." ("..point_value.." pts ea)"..newline
            end
        end

        local imperial_header = "IMPERIAL ACHIEVEMENTS"..newline
        local imperial_obj_destroyed = "Objectives destroyed:"..newline
        if ASL.dynamic.objectives[ASL.rebels.capital.sig].sensors then
            local point_value = 0
            for i = 1, #ASL.dynamic.clusters[ASL.rebels.capital.sig]["Sensors"] do
                local subsys_name = ASL.dynamic.clusters[ASL.rebels.capital.sig]["Sensors"][i].name
                point_value = point_value + ASL.rebels.subsys_point_value[subsys_name]
            end
            imperial_obj_destroyed = imperial_obj_destroyed.."Mon Calamari Cruiser Sensors Array ("..point_value.." pts)"..newline
        end
        if ASL.dynamic.objectives[ASL.rebels.capital.sig].comms then
            local point_value = 0
            for i = 1, #ASL.dynamic.clusters[ASL.rebels.capital.sig]["Comms"] do
                local subsys_name = ASL.dynamic.clusters[ASL.rebels.capital.sig]["Comms"][i].name
                point_value = point_value + ASL.rebels.subsys_point_value[subsys_name]
            end
            imperial_obj_destroyed = imperial_obj_destroyed.."Mon Calamari Cruiser Communications Relay ("..point_value.." pts)"..newline
        end
        if ASL.dynamic.objectives[ASL.rebels.capital.sig].engines then
            local point_value = 0
            for i = 1, #ASL.dynamic.clusters[ASL.rebels.capital.sig]["Engines"] do
                local subsys_name = ASL.dynamic.clusters[ASL.rebels.capital.sig]["Engines"][i].name
                point_value = point_value + ASL.rebels.subsys_point_value[subsys_name]
            end
            imperial_obj_destroyed = imperial_obj_destroyed.."Mon Calamari Cruiser Engines ("..point_value.." pts)"..newline
        end
        if ASL.dynamic.objectives[ASL.rebels.capital.sig].bridge then
            local point_value = 0
            for i = 1, #ASL.dynamic.clusters[ASL.rebels.capital.sig]["Bridge"] do
                local subsys_name = ASL.dynamic.clusters[ASL.rebels.capital.sig]["Bridge"][i].name
                point_value = point_value + ASL.rebels.subsys_point_value[subsys_name]
            end
            imperial_obj_destroyed = imperial_obj_destroyed.."Mon Calamari Cruiser Bridge ("..point_value.." pts)"..newline
        end
        if ASL.dynamic.objectives[ASL.rebels.capital.sig].reactor then
            local point_value = 0
            for i = 1, #ASL.dynamic.clusters[ASL.rebels.capital.sig]["Reactor"] do
                local subsys_name = ASL.dynamic.clusters[ASL.rebels.capital.sig]["Reactor"][i].name
                point_value = point_value + ASL.rebels.subsys_point_value[subsys_name]
            end
            imperial_obj_destroyed = imperial_obj_destroyed.."Mon Calamari Cruiser Reactor ("..point_value.." pts)"..newline
        end
        local imperial_kills = "Kills:"..newline
        local empire_kills_data = ASL.dynamic.kills[ASL.empire.capital.sig]
        --awful magic number stuff; the indices aren't contiguous, so we have to iterate over the maximum number of kill entries we could conceivably have
        for i = 1, #tb.ShipClasses do
            local entry = empire_kills_data[i]
            if entry ~= nil then
                local class_name = tb.ShipClasses[ASL.ship_score_data[i].index].AltName
                local point_value = ASL.ship_score_data[i].points
                if point_value == nil then
                    point_value = 0
                end
                imperial_kills = imperial_kills..class_name..": "..entry.." ("..point_value.." pts ea)"..newline
            end
        end

        local debriefing = intro..newline..rebel_header..newline..rebel_obj_destroyed..newline..rebel_kills..newline..imperial_header..newline..imperial_obj_destroyed..newline..imperial_kills

        if string.len(debriefing) / 31 > 240 then
            return
        end

        --turboscuffed string-chunking solution due to the system's general inability to do anything elegantly
        local start = 1
        local finish = 31
        for i = 1, 240 do
            local chunk = string.sub(debriefing, start, finish)
            mn.SEXPVariables["debrief-"..i].Value = chunk
            start = finish + 1
            finish = finish + 31
        end
        for i = 1, #mn.SEXPVariables do
            local var = mn.SEXPVariables[i]
        end
    end


    function ASL:OnSimulation()

        if not self.enabled then
            return
        end

        self:shieldCheck(self.rebels.capital)
        self:shieldCheck(self.empire.capital)

        self:updateStatusGauges()

        self:updateBoardingGauge()

        self:boardingCraftLandCheck()

    end

    function ASL:OnShipArrive(hv_ship)

        if not self.enabled or hv_ship == nil then
            return
        end
        if not hv_ship:isValid() then return end

        if FotG:IsDummyClass(hv_ship.Class.Name) then return end

        local wing = hv_ship:getWing()
        if wing:isValid() then
            self:setWingInterval(wing)
        end

        if hv_ship.Class.Type.Name == "transport" then
            self.dynamic.boarding_status[hv_ship.Team] = self.boarding_status.in_transit

            local priority
            if hv_ship.Team == self.dynamic.friendly then
                priority = 200
            else
                priority = 100
            end

            mn.evaluateSEXP("( add-remove-escort !"..hv_ship.Name.."! "..priority.." )")
        end

    end

    function ASL:OnShipDeath(hv_ship)

        if not self.enabled or hv_ship == nil then
            return
        end
        if not hv_ship:isValid() then return end

        if FotG:IsDummyClass(hv_ship.Class.Name) then return end

        if self.dynamic.finished then
            return
        end

        local target_team = hv_ship.Team
        local attacker_team

        if target_team == self.dynamic.friendly then
            attacker_team = self.dynamic.hostile
        elseif target_team == self.dynamic.hostile then
            attacker_team = self.dynamic.friendly
        else
            return
        end

        local side
        if attacker_team == self.rebels.capital.team then
            side = self.rebels.capital.sig
        else
            side = self.empire.capital.sig
        end

        local points
        local shipclass_index = hv_ship.Class:getShipClassIndex()

        if hv.Ship ~= self.rebels.capital.ship and hv.Ship ~= self.empire.capital.ship then
            local kills_index
            if self.ship_score_data[shipclass_index] ~= nil then
                kills_index = self.ship_score_data[shipclass_index].index
                if self.dynamic.kills[side][kills_index] == nil then
                    self.dynamic.kills[side][kills_index] = 0
                end
                self.dynamic.kills[side][kills_index] = self.dynamic.kills[side][kills_index] + 1
                points = self.ship_score_data[shipclass_index].points
            end
        end

        if points == nil then
            return
        end

        if self.dynamic.score[attacker_team] == nil then
            return
        end

        if hv_ship:isPlayer() then
            points = points * ba.getGameDifficulty()
        end
        
        self.dynamic.score[attacker_team] = self.dynamic.score[attacker_team] + points
        self:updateScoreGauge()

        local ship_type = hv_ship.Class.Type.Name
        if ship_type == "transport" then
            if self.dynamic.boarding_status[target_team] == self.boarding_status.in_transit then
                self.dynamic.boarding_status[target_team] = self.boarding_status.destroyed
            end
        elseif ship_type == "cruiser" then
            self:corvettesCheck()
        end

    end

    function ASL:OnSubsystemDestroyed(hv_ship, hv_subsystem)

        if not self.enabled or hv_ship == nil or hv_subsystem == nil then
            return
        end
        if self.dynamic.finished then
            return
        end
        if not hv_ship:isValid() then return end

        local target_team = hv_ship.Team
        local attacker_team

        if target_team == self.dynamic.friendly then
            attacker_team = self.dynamic.hostile
        elseif target_team == self.dynamic.hostile then
            attacker_team = self.dynamic.friendly
        else
            return
        end

        local points

        local ship_data
        if hv_ship.Class:getShipClassIndex() == self.rebels.capital.class then
            points = self.rebels.subsys_point_value[hv_subsystem.CanonicalName]
            ship_data = self.rebels.capital
        elseif hv_ship.Class:getShipClassIndex() == self.empire.capital.class then
            points = self.empire.subsys_point_value[hv_subsystem.CanonicalName]
            ship_data = self.empire.capital
        end

        if points ~= nil then
            self:clusterCheck(ship_data)
        else
            points = 1
        end

        if self.dynamic.score[attacker_team] == nil then
            return
        end

        self.dynamic.score[attacker_team] = self.dynamic.score[attacker_team] + points
        self:updateScoreGauge()

    end

end
--

--Hooks
if not IS_STANDALONE then 
	engine.addHook("On Gameplay Start", function() 
			ASL:missionStart()
		end
	)

	engine.addHook("On Simulation", function() 
			ASL:OnSimulation()
		end
	)

	engine.addHook("On Ship Arrive", function() 
			ASL:OnShipArrive(hv.Ship)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Ship Death", function() 
			ASL:OnShipDeath(hv.Ship)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Subsystem Destroyed", function() 
			ASL:OnSubsystemDestroyed(hv.Ship, hv.Subsystem)
		end,
		{State="GS_STATE_GAME_PLAY", ["Ship type"]="capital"}
	)

    ASL.keybinds.swap_teams:registerHook(function()
        if ASL.enabled and mn.getMissionTime() > 5 and not ASL.dynamic.finished then
            ASL:swapTeams(ASL.dynamic.friendly, ASL.dynamic.hostile, true)
        end
    end, true)

    ASL.keybinds.cycle_boarding_task:registerHook(function()
        if ASL.enabled and not ASL.dynamic.finished then
            local capital
            if ASL.rebels.capital.team == ASL.dynamic.friendly then
                capital = ASL.empire.capital
            elseif ASL.empire.capital.team == ASL.dynamic.friendly then
                capital = ASL.rebels.capital
            end
            if capital ~= nil then
                ASL:cycleBoardingTask(capital)
            end
        end
    end, true)

end
--