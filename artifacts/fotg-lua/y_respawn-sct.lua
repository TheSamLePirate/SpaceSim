--Description: allows the player to respawn in singleplayer mode to increase accessibility
--Plus, some particularly busy folks may just want to enjoy FotG 
--without having to worry about dying since time-to-kill is fast in FotG

--Is disabled in multiplayer since that already has respawning
Respawner = {

	Active = false,

	min_radius_for_pos_overlap = 50,
	respawn_location_step_tbl = {0, 1500, 0},
	respawn_text = ba.XSTR("Respawning...", 15), --custom_ui_15

}

Respawner.button_info = {
	uibt_unique_key = "Respawner_Active",
	uibt_default_val = true,
	uibt_title_str = ba.XSTR("Player Respawns", 16), --custom_ui_16
	uibt_tool_tip = ba.XSTR("When On, the player will respawn upon dying.\nWhen Off, the mission will end if the player dies.\nSingleplayer only, as multiplayer has respawning.", 17), --custom_ui_17

	uibt_choices_list = {{choice_i = 1, choice_str = ba.XSTR("Off", 0)}, {choice_i = 2, choice_str = ba.XSTR("On", 1)}},
	uibt_ui_type = FotG.UI_BT_List.TYPE_BinaryButton,

	uibt_origin_x = 0.5,
	uibt_origin_y = 1.0,
	uibt_offset_x = -300,
	uibt_offset_y = -170,

	uibt_gamestate = "GS_STATE_OPTIONS_MENU",

	uibt_multi_allowed = false,

	uibt_options_tab = FotG.OTab_ID_Main,

	uibt_get_function = function()
		return Respawner.Active
	end,

	uibt_set_function = function(new_value)
		Respawner.Active = new_value
	end

}

--Code

	--Gameplay Functions

	function Respawner:Reset()

		self.is_respawn_in_progress = false
		self.player_respawns = 0

		self.mission_specific_override = 0
		self.mission_specific_pos = nil
		self.mission_specific_ort = nil
		self.mission_specific_weprefresh = false
		self.mission_specific_obs_check = true
		self.mission_specific_speed_0 = false

    end

    function Respawner:SetMission_Override(new_value)

		self.mission_specific_override = new_value or 0

    end

	function Respawner:SetMission_Position(pos_tbl)

		self.mission_specific_pos = pos_tbl

    end

	function Respawner:SetMission_Orientation(pbh_tbl)

		self.mission_specific_ort = pbh_tbl

    end

	function Respawner:SetMission_WepRefresh(bool)

		self.mission_specific_weprefresh = bool

    end

	function Respawner:SetMission_ObstructionCheck(obs_check)

		self.mission_specific_obs_check = obs_check

	end

	function Respawner:SetMission_RespawnZeroSpeed(speed_at_0)

		self.mission_specific_speed_0 = speed_at_0

	end

	function Respawner:GetNewPosition(ship_pos, ship_radius, special_position_reset_tbl)

		local step_size_tbl = self.respawn_location_step_tbl

		local new_pos

		if type(special_position_reset_tbl) == "table" then
			if #special_position_reset_tbl == 3 then
				new_pos = {
					special_position_reset_tbl[1], 
					special_position_reset_tbl[2], 
					special_position_reset_tbl[3]
				}
			end
		end

		if new_pos == nil then
			new_pos = {
				ship_pos[1] + step_size_tbl[1], 
				ship_pos[2] + step_size_tbl[2], 
				ship_pos[3] + step_size_tbl[3]
			}
		end

		--get list of big ships that might hinder respawning location
		local big_ship_pos_list = {}
		local i_bigships = 0
		for ship in mn.getShipList() do
			if ship ~= nil and ship:isValid() then
				local radius = ship.Radius
				if radius > self.min_radius_for_pos_overlap then
					i_bigships = i_bigships + 1
					local pos = ship.Position
					big_ship_pos_list[i_bigships] = {{pos[1], pos[2], pos[3]}, radius}
				end
			end
		end

		--check overlap with any big ships
		local function OverlapDetected_and_Updated()

			local overlap_detected = false

			for _,v_biginfo in ipairs(big_ship_pos_list) do
				local big_pos = v_biginfo[1]
				local big_radius = v_biginfo[2]
				if Movements:Has_Overlap(new_pos, ship_radius, big_pos, big_radius, true) then
					for i=1,3 do
						new_pos[i] = new_pos[i] + step_size_tbl[i]
					end
					overlap_detected = true
					break
				end
			end

			return overlap_detected

		end

		local max_iteration_checks_needed = i_bigships

		if self.mission_specific_obs_check and max_iteration_checks_needed > 0 then
			for _=1,max_iteration_checks_needed do
				if not OverlapDetected_and_Updated() then
					break
				end
			end
		end

		return new_pos

	end

	function Respawner:RunShipRespawn(dying_ship, is_player, refresh_weapons, special_position_reset_tbl, special_orientation_reset_tbl)

		--restore hull health and subsystems
		--transport 1500 meters below where ship just died
		--if that spot is occupied add 1500 meters (do that # large ships there are)

		--failsafe check 
		if dying_ship == nil then return end
		if not dying_ship:isValid() then return end
		if dying_ship:getBreedName() ~= "Ship" then return end

		self.is_respawn_in_progress = true

		--reset time compression as failsafe
		ExtraControls:ActivePauseMode_Reset(true)

        --do stuff for player respawn
		if is_player then
			--reset flickering
			if GlowmapFlicker ~= nil and GlowmapFlicker.global_enabled then
				GlowmapFlicker:PlyReset()
			end

			mn.evaluateSEXP("( fade-in 2000 3 )")

			ad.playSound(ad.getSoundentry(49)) --fighter explosion

			mn.evaluateSEXP("( show-subtitle-text !"..self.respawn_text.."! 0 5 ( true ) ( false ) 5000 200 0 255 255 255 )") 
			-- may not need last optional arg of !"..FotG:GetFontName("large").."! since HUD scales subtitles?

			self.player_respawns = self.player_respawns + 1
		end

		--clear player target
		dying_ship.TargetSubsystem = nil
		dying_ship.Target = nil

		--restore health
		local max_hp = dying_ship.HitpointsMax
		dying_ship.HitpointsLeft = max_hp
		dying_ship.SimHitpointsLeft = max_hp

		--heal shields
		if dying_ship.Shields ~= nil then
			local shields_hp = dying_ship.Shields.CombinedMax
			if shields_hp > 1.0 then
				dying_ship.Shields.CombinedLeft = shields_hp
			end
		end

		--heal subsystems
		for subsys in dying_ship:getSubsystemList() do
			if subsys ~= nil and subsys:isValid() and subsys.HitpointsMax > 0 then
				subsys.HitpointsLeft = subsys.HitpointsMax
			end
		end

		local shipname = dying_ship.Name
		if refresh_weapons then
			mn.evaluateSEXP("( set-secondary-ammo !"..shipname.."! 0 100 ) ")
			mn.evaluateSEXP("( set-secondary-ammo !"..shipname.."! 1 100 ) ") 
		end

		--teleport ship
		local new_pos = self:GetNewPosition(dying_ship.Position, dying_ship.Radius, special_position_reset_tbl)

		--set position and orientation
		dying_ship.Position = ba.createVector(new_pos[1], new_pos[2], new_pos[3])

		if type(special_orientation_reset_tbl) == "table" then
			local p = special_orientation_reset_tbl.p or special_orientation_reset_tbl[1]
			local b = special_orientation_reset_tbl.b or special_orientation_reset_tbl[2]
			local h = special_orientation_reset_tbl.h or special_orientation_reset_tbl[3]
			dying_ship.Orientation = ba.createOrientation(p, b, h)
		end

		if self.mission_specific_speed_0 then
			local s_py = dying_ship.Physics
			local saved_decel = s_py.ForwardDecelerationTime
			local zer_vec = ba.createVector(0, 0, 0)

			s_py.ForwardDecelerationTime = 0
			s_py.RotationalVelocity = zer_vec
			s_py.RotationalVelocityDesired = zer_vec
			s_py.Velocity = zer_vec
			s_py.VelocityDesired = zer_vec
			dying_ship:setFlag(true, "immobile")

			async.run(function()
				async.await(async.yield())
				if dying_ship ~= nil and dying_ship:isValid() and s_py ~= nil then
					s_py.RotationalVelocity = zer_vec
					s_py.RotationalVelocityDesired = zer_vec
					s_py.Velocity = zer_vec
					s_py.VelocityDesired = zer_vec
					s_py.ForwardDecelerationTime = saved_decel
					dying_ship:setFlag(false, "immobile")
				end
			end, async.OnSimulationExecutor)
		end

		--set ship throttle if player
		if is_player then
			if self.mission_specific_speed_0 then
				mn.evaluateSEXP("( set-player-throttle-speed !"..shipname.."! 0 )")
			else
				mn.evaluateSEXP("( set-player-throttle-speed !"..shipname.."! 20 )")
			end
		end

		--if PA then do protect
		if GCW ~= nil and GCW.isactive then
			if is_player then
				dying_ship.Stealthed = true
				dying_ship:setFlag(true, "protect-ship", "laser-protect-ship", "missile-protect-ship", "beam-protect-ship")

				--finally clean up
				async.run(function()
					async.await(mn.waitAsync(3))
					--check can warp again here since ship may have been damaged in waiting
					--recall that any s-foil closing was done in the depart protocols
					--also checks for ship validity
					if dying_ship ~= nil and dying_ship:isValid() then
						dying_ship.Stealthed = false
						dying_ship:setFlag(false, "protect-ship", "laser-protect-ship", "missile-protect-ship", "beam-protect-ship")
					end
					self.is_respawn_in_progress = false
				end)
			else
				--finally clean up
				self.is_respawn_in_progress = false
			end
		else
			--finally clean up
			self.is_respawn_in_progress = false
		end


	end

	function Respawner:RespawnAllowed()

		if ba.MultiplayerMode then
			return false
		end

		--mission can force it to on or off 
		--if not using mission override (ie it's 0) just to use whatever play setting is
		if self.mission_specific_override == 1 then
			return true
		elseif self.mission_specific_override == -1 then
			return false
		else --self.mission_specific_override == 0 
			if self.Active then
				return true
			else
				return false
			end
		end

	end

	function Respawner:OnShipDeath(dying_ship) --only works on player ship ATM

		--have to use 'On Ship Death' instead of 'On Started' b/c On Started is not overridable
		--recall that returning 'true' overrides the On Ship Death, returning false allows normal death
		if self:RespawnAllowed() then
			if dying_ship ~= nil and dying_ship:isValid() and dying_ship:isPlayer() and dying_ship:getBreedName() == "Ship" then
				--just let player survive if they are jumping, 
				--don't bother with fancy respawn teleport b/c it will likely mess it up
				if HyperspaceExit.is_player_jumping_in or HyperspaceEnter.is_player_jumping_out or dying_ship:isDepartingWarp() or dying_ship:isArrivingWarp() then
					return true
				else
					self:RunShipRespawn(dying_ship, true, self.mission_specific_weprefresh, self.mission_specific_pos, self.mission_specific_ort)
					return true
				end
			else
				return false
			end
		else
			return false
		end

	end

	function Respawner:SetValues(toggle_val, weprefresh_bool, use_new_settings, pos_tbl_x, pos_tbl_y, pos_tbl_z, pbh_p, pbh_b, pbh_h, obstacle_check, set_to_zero)

		Respawner:Reset()
		Respawner:SetMission_Override(toggle_val)
		Respawner:SetMission_WepRefresh(weprefresh_bool)
		if use_new_settings then
			Respawner:SetMission_Position({pos_tbl_x or 0, pos_tbl_y or 0, pos_tbl_z or 0})
			Respawner:SetMission_Orientation({pbh_p or 0, pbh_b or 0, pbh_h or 0})
			Respawner:SetMission_ObstructionCheck(obstacle_check)
			Respawner:SetMission_RespawnZeroSpeed(set_to_zero)
		end

	end


	mn.LuaSEXPs["sp-respawner-set-values"].Action = function (toggle_val, weprefresh_bool, use_new_settings, pos_tbl_x, pos_tbl_y, pos_tbl_z, pbh_p, pbh_b, pbh_h, obstacle_check, set_to_zero)

		if obstacle_check == nil then obstacle_check = true end

		Respawner:SetValues(toggle_val, weprefresh_bool, use_new_settings, pos_tbl_x, pos_tbl_y, pos_tbl_z, pbh_p, pbh_b, pbh_h, obstacle_check, set_to_zero)

	end

	mn.LuaSEXPs["sp-respawner-is-active"].Action = function ()

		return Respawner:RespawnAllowed()

	end

	mn.LuaSEXPs["sp-respawner-ply-count"].Action = function ()

		return Respawner.player_respawns

	end

	mn.LuaSEXPs["sp-respawner-run"].Action = function ()

		Respawner:OnShipDeath(FotG:GetPlayerShip())

	end

--


--Create Button
	FotG:UI_BT_Add(Respawner.button_info)


--Hooks

if not IS_STANDALONE then
	engine.addHook("On Gameplay Start", function() 
			Respawner:Reset()
		end
	)

	engine.addHook("On Mission About To End", function() 
			Respawner:Reset()
		end
	)

	engine.addHook("On Ship Death", function() 
		end,
		{State="GS_STATE_GAME_PLAY"},
		function ()
			return Respawner:OnShipDeath(hv.Ship)
		end
	)
end