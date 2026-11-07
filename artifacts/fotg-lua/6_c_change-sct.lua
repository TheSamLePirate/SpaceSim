-- This file contains a safe, script approved way to run change-ship-class

ChangeClassSafe = {}

--Code
    function ChangeClassSafe:ResetQueue(on_mission_start)

        self.queue_list = nil
        if on_mission_start and not ba.MultiplayerMode and not IS_STANDALONE then
            self.queue_list = {}
        end

    end

	function ChangeClassSafe:RunChange(class_to_change_to, ship_to_change)

        if ba.MultiplayerMode then return end

        if ship_to_change == nil then return end
        if not ship_to_change:isValid() then return end
        if ship_to_change:isDying() then return end

        if class_to_change_to == nil then return end
        if not class_to_change_to:isValid() then return end
        local new_class_name = class_to_change_to.Name

        if new_class_name == nil then return end

        local is_ply = false
        if ship_to_change:isPlayer() then
            is_ply = true
        end

        local ship_name = ship_to_change.Name
        if ship_name == nil then return end

        local ship_sig = ship_to_change:getSignature()

        --early out if still waiting, otherwise proceed
        if self.queue_list ~= nil and self.queue_list[ship_sig] ~= nil then
            return 
        end

        --wait until s-foils done before allowing to change
        local delay_time = 0
        local s_foil_info = Sfoils.meta_info[ship_sig]
        local s_foils_need_opened = false
        local old_class_simple = string.filterInvisible(ship_to_change.Class.Name)
        if s_foil_info ~= nil then
            if s_foil_info.current_wings_method == Sfoils.method_moving then
                delay_time = Sfoils:Get_AnimTime_Full(old_class_simple) + 0.5
            end
            if s_foil_info.current_wings_method ~= Sfoils.method_open then
                s_foils_need_opened = true
            end
        end

        local function change_helper()

            if ship_to_change == nil then return end
            if not ship_to_change:isValid() then return end
            if ship_to_change:isDying() then return end

            --clear out any old s-foils
            if s_foils_need_opened then
                Sfoils:Toggle(ship_to_change, Sfoils.method_open, true)
            end
            Sfoils.meta_info[ship_sig] = nil

            --change the class
            mn.evaluateSEXP("( change-ship-class !"..new_class_name.."! !"..ship_name.."! )")

            --setup new s-foils, needs to run first to save og rotational speeds
            if Sfoils:ShipEquipped(new_class_name) then 
                Sfoils:CheckAddShip_MetaInfo(ship_to_change)
            end

            --deal with everything else 
            BombHelper:B_Ship_Setup(ship_to_change, true) --has internal logic for player vs AI ship

            if is_ply then
                Custom_Message_Gauge:Stop()
                AutoAim:MissionSetup(false)
                Custom_Message_Gauge:HideDefault()
                Custom_Message_Gauge:StatusHelper()
                Object_Info_Help:StatusHelper()
                ExtraControls:Headlight_Toggle(ship_to_change, ExtraControls.headlight_change_sclass)
                Falcon_Guns:Start()
                GlowmapFlicker:PlyReset()
                MissionHelper:EngineBonus_Enable()
                TIE_Burst:GameplayStart()
            end

            local has_shields = false
            local shields = ship_to_change.Shields
            if shields ~= nil then
                local max_shields = shields.CombinedMax or 0
                if max_shields > 0 then
                    has_shields = true
                end
            end
            --ETS is engine, shield, weapon
            if has_shields then
                ship_to_change:EtsSetIndexes(4, 4, 4)
            else
                ship_to_change:EtsSetIndexes(6, 0, 6)
            end

		end


        if delay_time > 0 then
            --wait delay time then run
			async.run(function()
                self.queue_list[ship_sig] = true
				async.await(mn.waitAsync(delay_time))
                change_helper()
                self.queue_list[ship_sig] = nil
			end)
        else
            --run immediately
            self.queue_list[ship_sig] = true
            change_helper()
            self.queue_list[ship_sig] = nil
        end

	end


	mn.LuaSEXPs["change-ship-class-safe"].Action = function(class_to_change_to, ship_to_change)
		
        ChangeClassSafe:RunChange(class_to_change_to, ship_to_change)

	end

--

--Hooks
if not IS_STANDALONE then 
	engine.addHook("On Gameplay Start", function() 
			ChangeClassSafe:ResetQueue(true)
		end
	)

	engine.addHook("On Mission About To End", function() 
			ChangeClassSafe:ResetQueue(false)
		end
	)
end