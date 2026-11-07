ExtraControls = {
	headlight_lookup_all = { --list all banks associated with headlights
		["T-65c X-wing"]={1, 2, 3, 4, 5},
		["Z-95 Headhunter"]={1, 2},
		["ARC-170 Starfighter"]={1, 2},
		["BTL-A4 Y-wing"]={1, 2},
		["BTL-LP Longprobe"]={1, 2},
		["ASF-01 B-wing"]={1, 2},
		["T-Blade Bomber"]={1, 2},
		["RZ-1 A-wing"]={1, 2},
		["E-7 E-wing"]={1, 2, 3},
		["T.I.E. Fighter"]={1, 2},
		["TIE/ln Fighter"]={1, 2},
		["TIE/rc Fighter"]={1, 2},
		["TIE Advanced X1"]={1, 2},
		["TIE/In Interceptor"]={1, 2},
		["TIE/In Interceptor Mk.2"]={1, 2},
		["TIE/sa Bomber"]={1, 2},
		["TIE/sh Shuttle"]={1, 2},
		["V38 Assault Fighter"]={1, 2},
		["N-1 Starfighter"]={1, 2},
		["Vulture Droid Starfighter "]={1, 2},
		["Cloakshape Fighter"]={1, 2},
		["ZY-wing"]={1, 2},
		["TYE-wing"]={1, 2},
		["TYE-Vulture"]={1, 2},
		["ZTI-wing"]={1, 2},
		["XG-1 Star Wing"]={1, 2},
		["UT-60D U-wing"]={1, 2},
		["Modified Firespray Gunship"]={1, 2},
		["Firespray Gunship"]={1, 2},
		["Skipray Blastboat"]={1, 2},
		["Modified YT-1300 Freighter"]={1, 2},
		["YT-1300 Freighter"]={1, 2},
		["Lambda T-4a Shuttle"] = {has_other_banks = true, 5, 6}, 
		["DX-9 Stormtrooper Transport"] = {1, 2}, 
		["Zeta Hvy Cargo Shuttle"] = {has_other_banks = true, 1, 2}, 
		["Star Speeder 3000"] = {1, 2} 
	},
	control_type_headlight = 1,

	headlight_ply_toggle = 1,
	headlight_change_sclass = 2
}

--Code
	function ExtraControls:TargetClosest_Specific(teamname, source_ship, list_types_to_match, starfighter_method, set_as_player_target, do_ply_sensor_checks, must_be_targeting_source_ship, target_method, allow_targeting_player)

		if ba.MultiplayerMode then 
			return nil
		end

		local player = FotG:GetPlayerShip()
		if player == nil then 
			return nil
		end
		if not player:isValid() then 
			return nil
		end
		if player:getBreedName() ~= "Ship" then 
			return nil
		end

		if HyperspaceExit.is_player_jumping_in or HyperspaceEnter.is_player_jumping_out then 
			return nil
		end

		if do_ply_sensor_checks == nil then
			do_ply_sensor_checks = false
		end
		if do_ply_sensor_checks and Movements:GenericSubsystem_HitsPercent(player, "sensor") < 30 then
			return nil
		end

		target_method = target_method or -1
		-- -1 for closest match, 0 for previous closest and 1 for next closest
		local method_previous_closest = 0
		local method_next_closest = 1

		starfighter_method = starfighter_method or -1
		--0 is exclude starfighter, 1 is only include starfighters, -1 is does not matter

		if teamname == nil then 
			teamname = "Hostile"
		end
		if source_ship == nil then
			source_ship = player
		end
		if set_as_player_target == nil then 
			set_as_player_target = false
		end
		if must_be_targeting_source_ship == nil then 
			must_be_targeting_source_ship = false
		end

		local source_position = source_ship.Position
		local source_signature = source_ship:getSignature()
		local source_current_target_obj = source_ship.Target
		local source_current_target_sig
		local current_distance = 0

		if source_current_target_obj ~= nil and source_current_target_obj:isValid() then
			source_current_target_sig = source_current_target_obj:getSignature()
			current_distance = source_position:getDistanceSquared(source_current_target_obj.Position)
		end 

		local minimum_distance = 10000000000000 
    	local maximum_distance = 0

		local nearest_distance
		local targeting_from_closest_to_farthest
		local use_special_method = (target_method == method_previous_closest or target_method == method_next_closest)
		if use_special_method then
			targeting_from_closest_to_farthest = (target_method == method_next_closest)
			if targeting_from_closest_to_farthest then
				nearest_distance = 10000000000000
			else
				nearest_distance = 0
			end
		end

		local play_sound = true
		local source_current_t_was_matched = false

		local minimum_object_ptr, maximum_object_ptr, nearest_object_ptr, prospective_victim_ptr
		local l_closest_distance

		--go through hostile ships in mission
		for ship in mn.getShipList() do

			local pass_ply_check = true
			if ship:isPlayer() then
				if not allow_targeting_player then
					pass_ply_check = false
				end
			end

			--only continue if:
			--  visible on radar
			--  checks if a ship can appear on the viewer's radar. If a viewer is not provided it assumes the viewer is the player.
			--  Returns: 0 - not visible, 1 - partially visible, 2 - fully visible
			local visible_on_sensors = (not ship.Stealthed and not ship.HiddenFromSensors and ship:checkVisibility() > 0)
			local present = (not ship:isArrivingWarp() and not ship:isDepartingWarp() and not ship:isDying())
			local l_ship_tname = string.filterInvisible(ship.Team.Name)
			if pass_ply_check and teamname == l_ship_tname and present and ((not do_ply_sensor_checks) or (do_ply_sensor_checks and visible_on_sensors)) then 

				local ship_type = ship.Class.Type.Name
				local is_starfighter = ship_type == "fighter" or ship_type == "bomber"
				local type_was_match
				if list_types_to_match == nil then
					type_was_match = true
				else
					type_was_match = string.equalAny(ship_type, list_types_to_match)
				end
				if is_starfighter and starfighter_method == 0 then
					--method: exclude starfighters
					type_was_match = false
				elseif starfighter_method == 1 and not is_starfighter then
					--method: only include starfighters
					type_was_match = false
				end
				if type_was_match then

					--if starfighter then just use ship distance
					--otherwise use more distance checks, including possibly turrets
					local l_ship_pos = ship.Position
					local l_ship_signature = ship:getSignature()

					--skip ourselves
					local is_l_self = (l_ship_signature == source_signature)

					local l_ship_target_signature
					local l_ship_target = ship.Target
					if not is_l_self and (l_ship_target ~= nil and l_ship_target:isValid() and l_ship_target:getBreedName() == "Ship") then
						l_ship_target_signature = l_ship_target:getSignature()
					end
					--if doing next or previous method do not target if this ship is already source's target
					local can_method_proceed = true
					if not is_l_self and (target_method == method_previous_closest or target_method == method_next_closest) then
						if source_current_target_sig == l_ship_signature then
							can_method_proceed = false
							source_current_t_was_matched = true
						end
					end
					if not is_l_self and (can_method_proceed and l_ship_pos ~= nil) then
						local dist_to_target
						if is_starfighter then
							if (not must_be_targeting_source_ship) or (must_be_targeting_source_ship and l_ship_target_signature == source_signature) then
								dist_to_target = source_position:getDistanceSquared(l_ship_pos)
							end
						else --not starfighter
							if must_be_targeting_source_ship then
								--first check all turret subsystems
								local turret_distance 
								local use_early_turret_out = true
								for ss in ship:getSubsystemList() do
									if ss ~= nil and ss:isValid() and ss:isTurret() and ss.Targetable and ss.HitpointsLeft > 0 then
										local ss_target = ss.Target
										if ss_target ~= nil and ss_target:isValid() and ss_target:getSignature() == source_signature then
											if use_early_turret_out then
												--once we have found one turret that is targeting consider that good enough
												dist_to_target = source_position:getDistanceSquared(l_ship_pos)
												break
											else
												turret_distance = ss.WorldPosition:getDistanceSquared(l_ship_pos)
												if dist_to_target == nil then
													dist_to_target = turret_distance 
												end
												if turret_distance < dist_to_target then
													dist_to_target = turret_distance
												end
											end
										end
									end
								end
								--if no turret is attacking, check if this ship is actually targeting the attacked object number
								if (dist_to_target == nil) and (l_ship_target_signature == source_signature) then
									dist_to_target = source_position:getDistanceSquared(l_ship_pos)
								end
							else --does not have to be targeting source ship
								dist_to_target = source_position:getDistanceSquared(l_ship_pos)
							end
						end

						if dist_to_target ~= nil then
							if l_closest_distance == nil then
								l_closest_distance = dist_to_target
							end
							if use_special_method then
								--copied from select_next_target_by_distance( function in FSO
								prospective_victim_ptr = ship

								if (dist_to_target <= minimum_distance) then
									minimum_distance = dist_to_target;
									minimum_object_ptr = prospective_victim_ptr;
								end

								if (dist_to_target >= maximum_distance) then
									maximum_distance = dist_to_target;
									maximum_object_ptr = prospective_victim_ptr;
								end

								local diff = 0
								if (targeting_from_closest_to_farthest) then
									diff = dist_to_target - current_distance;
									if (diff > 0) then
										if (diff < (nearest_distance - current_distance)) then
											nearest_distance = dist_to_target;
											nearest_object_ptr = prospective_victim_ptr;
										end
									end
								else
									diff = current_distance - dist_to_target;
									if (diff > 0) then
										if (diff < (current_distance - nearest_distance)) then
											nearest_distance = dist_to_target;
											nearest_object_ptr = prospective_victim_ptr;
										end
									end
								end

							else
								--use <= in case only 1 valid target!
								if dist_to_target <= l_closest_distance then
									l_closest_distance = dist_to_target
									nearest_object_ptr = ship
								end
							end
						end
					end

				end

			end

		end

		if set_as_player_target then
			--after loop set target if not nil and play success sound, otherwise play failure sound

			if use_special_method and nearest_object_ptr == nil then
				--copied from select_next_target_by_distance( function in FSO
				if (targeting_from_closest_to_farthest) then
					if (minimum_object_ptr ~= nil) then
						nearest_object_ptr = minimum_object_ptr
					end
				else
					if (maximum_object_ptr ~= nil) then
						nearest_object_ptr = maximum_object_ptr
					end
				end
			end

			if nearest_object_ptr ~= nil and nearest_object_ptr:isValid() then
				--if player already targeting that seems fine to play noise again
				player.Target = nearest_object_ptr
				ad.playGameSound(8) --target acquired sound
			else
				if not source_current_t_was_matched then
					ad.playGameSound(28) --failed sound
				end
			end

		end


		return nearest_object_ptr

	end

	function ExtraControls:Headlight_Setup()

		--when mission starts FSO code makes glows on, so it will never be off until we set it, hence only update this on mission start
		self.ply_on = false

	end

	function ExtraControls:Headlight_Toggle(ply_ship, method_id) --just for player

		-- only visual so having on in multi is fine

		--if ba.MultiplayerMode then return end
		if ply_ship == nil then return end
		if not ply_ship:isValid() then return end
		if ply_ship:getBreedName() ~= "Ship" then return end

		local shipname = ply_ship.Name
		if FotG:IsStandaloneName(shipname) then return end
		local sclass_full = ply_ship.Class.Name
		if sclass_full == nil then return end

		local sclass = string.filterInvisible(sclass_full)

		--if we ever add headlights to ships that have non-headlight glow points
		--then this will have to be expanded
		local sinfo = self.headlight_lookup_all[sclass]

		--leave if no headlight info (ie ship does not use scripted headlights)
		if sinfo == nil then return end

		--ship headlights default to off now, so toggling only works for player
		local run_toggle = false

		if method_id == self.headlight_ply_toggle then
			--player clicked the button to toggle headlights
			self.ply_on = not self.ply_on
			run_toggle = true
		elseif method_id == self.headlight_change_sclass then
			--case where player turned headlights on, but ship class changed, 
			--so ensure glowpoints stay on
			if self.ply_on then
				run_toggle = true
			end
		end

		if run_toggle then
			if sinfo.has_other_banks then
				for _,v in ipairs(sinfo) do
					ply_ship:setGlowPointBankActive(self.ply_on, v)
				end
			else
				ply_ship:setGlowPointBankActive(self.ply_on)
			end
		end

	end

	function ExtraControls:ActivePauseMode_Reset(also_use_sexp)

		self.activepause_mode_on = false
		--recall FSO itself resets time compression when starting or ending a mission

		if also_use_sexp then
			mn.evaluateSEXP("(reset-time-compression)")
		end

	end

	function ExtraControls:ActivePause_Toggle()

		if ba.MultiplayerMode then return end

		local current_status = self.activepause_mode_on
		local new_status = not self.activepause_mode_on

		if new_status then
			--if toggling on then we only toggle on if not warping
			local ply = FotG:GetPlayerShip()
			--recall player does fake warp when hyperspace exit is used
			if ply ~= nil and ply:isValid() and ply:getBreedName() == "Ship" and not ply:isArrivingWarp() and not ply:isDepartingWarp() then
				mn.evaluateSEXP("( set-time-compression !0.001!)")
				self.activepause_mode_on = new_status
			else	
				--do not change if those conditions are not met
			end
		else
			--if toggling off just reset time compression
			mn.evaluateSEXP("(reset-time-compression)")
			self.activepause_mode_on = new_status
		end

	end

	function ExtraControls:Set_IFF_Family_Targeting(bool)
	
		ExtraControls.Use_iff_family_targeting = bool

	end

	function ExtraControls:TargetRun(team, method)

		--if enabled, then IFF targeting works across families, 
		--IE 'Target Next Closest Hostile' targets 'Hostile' and 'Hostile#Tactical'
		if MTIME_OVER_P1 and self.Use_iff_family_targeting and not ba.MultiplayerMode then
			self:TargetClosest_Specific(team, nil, nil, -1, true, true, false, method)
			return true
		else
			return false
		end

	end

	function ExtraControls:TargetPursuer()

		if MTIME_OVER_P1 and not ba.MultiplayerMode then
			local ply = FotG:GetPlayerShip()
			if ply ~= nil and ply:isValid() and ply:getBreedName() == "Ship" then
				local p_target = ply.Target
				if p_target ~= nil and p_target:isValid() and p_target:getBreedName() == "Ship" then

					local team_to_target = "Hostile"
					if string.find(p_target.Team.Name, "Hostile") then
						team_to_target = "Friendly"
					end

					--since small will only ask for help if getting attacked by small
					--so, if target is small, then only return small pursuers 
					--(to avoid bug where it would target closest hostile big ship if one happened to be nearby)
					local starfighter_method = -1
					local ship_type = p_target.Class.Type.Name
					if ship_type == "fighter" or ship_type == "bomber" then
						starfighter_method = 1
					end

					self:TargetClosest_Specific(team_to_target, p_target, nil, starfighter_method, true, true, true, -1)

				end
			end
			
			return true
		else
			return false
		end

	end

--

--Hooks
if not IS_STANDALONE then 
	engine.addHook("On Gameplay Start", function() 
			ExtraControls:Headlight_Setup()
			ExtraControls:ActivePauseMode_Reset()
			ExtraControls:Set_IFF_Family_Targeting(false)
		end
	)

	engine.addHook("On Mission About To End", function() 
			ExtraControls:ActivePauseMode_Reset()
			ExtraControls:Set_IFF_Family_Targeting(false)
		end
	)

	io.Keybinding["TARGET_NEXT_CLOSEST_HOSTILE"]:registerHook(function()
		return ExtraControls:TargetRun("Hostile", 1)
	end, true, true)

	io.Keybinding["TARGET_PREV_CLOSEST_HOSTILE"]:registerHook(function()
		return ExtraControls:TargetRun("Hostile", 0)
	end, true, true)

	io.Keybinding["TARGET_NEXT_CLOSEST_FRIENDLY"]:registerHook(function()
		return ExtraControls:TargetRun("Friendly", 1)
	end, true, true)

	io.Keybinding["TARGET_PREV_CLOSEST_FRIENDLY"]:registerHook(function()
		return ExtraControls:TargetRun("Friendly", 0)
	end, true, true)

	io.Keybinding["TARGET_CLOSEST_SHIP_ATTACKING_TARGET"]:registerHook(function()
		return ExtraControls:TargetPursuer()
	end, true, true)

	io.Keybinding["TOGGLE_GLIDING"]:registerHook(function()
		ExtraControls:ActivePause_Toggle() --"Toggle Active Pause"
		return false
	end, true, true)

	io.Keybinding["TOGGLE_HUD_CONTRAST"]:registerHook(function()
		ExtraControls:Headlight_Toggle(FotG:GetPlayerShip(), ExtraControls.headlight_ply_toggle) --"Toggle Floodlight" 
		return false
	end, true, true)

	--io.Keybinding["CUSTOM_CONTROL_4"]:registerHook(function()
		--if MTIME_OVER_P1 then 
		--	ExtraControls:TargetClosest_Specific("Hostile", nil, nil, 1, true, true, false)
		--end
		--return false
	--end, true, true)

end