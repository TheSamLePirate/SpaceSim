-- This file contains functions needed in general and/or specific missions.

--Code

    -- Used for various helper functions
	MissionHelper = {
		destroyed_ss_react_eventname = "DestroyedSubsystemsReact",

		playerarrives_docked_eventname = "PlayerArrivesDocked",
		playerarrives_bay_eventname = "PlayerArrivesFromDockingBay",

		impact_damage_high = "Collision_Damage_High", --used to make collisions harder for players on higher difficulties
		impact_damage_low = "Collision_Damage_Low",

		--50 is hardcoded min radius where guarding ships will orbit guard-ee instead of be stationary and align
		--making this number larger helps them not appear to circle too tightly 
		--if too big though optimizations with collision checking outside of actual radius are pointless
		min_guardee_orbit_radius = 60,

		-- make mass larger on non fighter ships to prevent small ship collisions throwing it off
		radius_for_extra_mass = 12,
		radius_for_no_collided_exit = 20,
		extra_mass_helper = 75000,
		
		-- used to add all large ships to the same collisional group
		collide_cull_on_eventname_def = "EnableCollisionCullsAll",
		collide_cull_on_eventname_friend = "EnableCollisionCullsFriendly",
		collide_cull_on_eventname_hostile = "EnableCollisionCullsHostile",
		collide_cull_also_on_small_F = false, 
		collide_cull_also_on_small_H = false, 
		--^want to allow close packing small ships to hit each other or not? 
		--useful if player is trying to shake two tails
		collide_tinybig_small_f_help = 60, --if big ship smaller then this non player small F can go through it 

		collide_cull_grp_big_all_AI = 2,

		collide_cull_grp_small_friendly_AI = 3,
		collide_cull_grp_small_hostile_AI = 4,

		collide_cull_grp_smallish_friendly_AI = 5,
		collide_cull_grp_smallish_hostile_AI = 6,

		collide_cull_grp_all_friendly_AI = 7,
		collide_cull_grp_all_hostile_AI = 8,

		highest_pr = 200,
		high_pr = 150,

		weapon_helper = {
			--if this filtered ship class matches, then put weapon as the compact green variant 
			--makes more movie accurate and doing it this way means 
			--we do not have 2 KX-5 weapons that look identical and are confusing in the loadout for players
			ship_classes = {
				["N-1 Starfighter"] = {["T&B IX4#Red"]="T&B IX4#Grn", ["T&B KX-5#Red"]="T&B KX-5#Grn"},
				["A-3 V-wing Starfighter"] = {["T&B IX4#Red"]="T&B IX4#Grn", ["T&B KX-5#Red"]="T&B KX-5#Grn"},
				["ARC-170 Starfighter"] = {["T&B IX4#Red"]="T&B IX4#Grn", ["T&B KX-5#Red"]="T&B KX-5#Grn", ["T&B KX-4#Red"]="T&B KX-4#Grn"},
			}
		},

		guardian_all = 1,
		guardian_onlycomms = 2,
		guardian_onlyengines = 3
	}


	-- Auto switch to singleplayer for Techroom
	function MissionHelper:AutoSinglePlayer()

		--set the modes and player flags to singleplayer
		ba.MultiplayerMode = false
		local ply = ba.getCurrentPlayer()
		if ply ~= nil and ply:isValid() then
			ply.WasMultiplayer = false
			ply.IsMultiplayer = false
		end

	end

	function MissionHelper:GuardianSubsystems(ship, min, max, method)

		if ship ~= nil and ship:isValid() and ship:getBreedName() == "Ship" then

			if type(min) ~= "number" then
				min = 36
			end
			if type(max) ~= "number" then
				max = 41
			end
			if max <= min then
				max = min + 1
			end
			local min_s = tostring(math.round(min))
			local max_s = tostring(math.round(max))

			--only run if on a fighter or bomber
			local shiptype = ship.Class.Type.Name
			if shiptype == "fighter" or shiptype == "bomber" then
				if method == self.guardian_onlycomms then
					mn.evaluateSEXP("( ship-subsys-guardian-threshold ( rand-multiple "..min_s.." "..max_s.." ) !"..ship.Name.."! !Communications!)")
				elseif method == self.guardian_onlyengines then
					mn.evaluateSEXP("( ship-subsys-guardian-threshold ( rand-multiple "..min_s.." "..max_s.." ) !"..ship.Name.."! !<all engines>! )")
				else
					mn.evaluateSEXP("( ship-subsys-guardian-threshold ( rand-multiple "..min_s.." "..max_s.." ) !"..ship.Name.."! !<all engines>! !Weapons! !Sensors! !Navigation! !Communications!)")
				end
				--ba.print("Setting_Threshold_for_subsystems: "..ship.Name.."\n...")
			end

		end

	end

	function MissionHelper:Get_Player_Target()

		local player = FotG:GetPlayerShip()
		if player == nil then return nil end
		if not player:isValid() then return nil end
		if player:getBreedName() ~= "Ship" then return nil end 

		local ptarget = player.Target
		if ptarget == nil then return nil end

		if ptarget:getBreedName() == "Ship" then 
			return ptarget
		else
			return nil
		end

	end

	function MissionHelper:Set_ControlGauges_Status(toogle_bool)

		mn.evaluateSEXP("( hud-set-builtin-gauge-active ( "..tostring(toogle_bool).." ) !Center reticle! !Throttle! )")

	end

	function MissionHelper:LockShip(ship, is_hud_disabled, is_cloaked) --locks a given ship, optional HUD_disabled and is_Cloaked argument

		--validity checks
		if ba.MultiplayerMode then return end
		if ship == nil then return end
		if not ship:isValid() then return end
		if ship:getBreedName() ~= "Ship" then return end

		--default args
		if is_hud_disabled == nil then 
			is_hud_disabled = false
		end
		if is_cloaked == nil then 
			is_cloaked = false
		end

		--locking specific aspects
		if is_cloaked then
			ship:addShipEffect("Instant Hide", 0)
		end

		ship:setFlag(true, "primaries-locked", "secondaries-locked", "never-warp")
		mn.evaluateSEXP("( turret-lock-all !"..ship.Name.."! )")

		--if player ship then have to set AI to control and also lock HUD if specified
		if ship:isPlayer() then
			mn.evaluateSEXP("( player-use-ai ) ")
			ship:clearOrders()
			if is_hud_disabled then
				mn.evaluateSEXP("( hud-disable 1 )") --1 to disable
			end
		end

		--add play dead persistent order to AI at max level
		ship:giveOrder(ORDER_PLAY_DEAD_PERSISTENT, nil, nil, self.highest_pr/100)

	end

	function MissionHelper:UnlockShip(ship, enable_hud, uncloak) --unlocks a given ship

		--validity checks
		if ba.MultiplayerMode then return end
		if ship == nil then return end
		if not ship:isValid() then return end

		--default args
		if enable_hud == nil then 
			enable_hud = true
		end
		if uncloak == nil then 
			uncloak = true
		end

		--locking specific aspects
		if uncloak then
			ship:addShipEffect("Instant Show", 0)
		end

		ship:setFlag(false, "primaries-locked", "secondaries-locked", "never-warp")
		mn.evaluateSEXP("( turret-free-all !"..ship.Name.."! )")

		--if player ship then have to set AI to not control and also unlock HUD if specified
		if ship:isPlayer() then
			mn.evaluateSEXP("( player-not-use-ai ) ")
			ship:clearOrders()
			if enable_hud then
				mn.evaluateSEXP("( hud-disable 0 )") --0 to enable
			end
		else
			--if not player and clearing orders, then remove play dead persistent order to AI at max level
			Movements:RemoveGoal_Correctly(ship, self.highest_pr, "ai-play-dead-persistent")
		end

	end

	function MissionHelper:GuardeesOrbit(ship, min_to_set)

		if ship ~= nil and ship:isValid() then
			local min_to_set = min_to_set or self.min_guardee_orbit_radius
			if ship.Radius < min_to_set then
				ship.Radius = min_to_set
			end
		end

	end


	function MissionHelper:EqualizeSmallShields(ship)

		if ship ~= nil and ship:isValid() then
			local shields = ship.Shields
			if shields ~= nil then
				local half = shields.CombinedLeft/2 
				if half > 0 then
					ship.Shields[1] = half
					ship.Shields[2] = half
				end
			end
		end

	end

	function MissionHelper:Dock_Ply_Hide_Helper(pship, mothership, bool_set)

		if pship == nil then return end

		--recall, protect flag can be unset by script/sexp/player orders 
		--so just make sure FREDer is not ordering hostile ships to attack player or mothership in first 30 seconds or so

		local player_wing = pship:getWing()
		if player_wing ~= nil and player_wing:isValid() then 
			--do all ships in player wing
			local num_of_ships_pwing = #player_wing
			for i=1, num_of_ships_pwing do
				local wship = player_wing[i]
				if wship ~= nil then
					wship:setFlag(bool_set, "no-dynamic", "protect-ship", "laser-protect-ship", "missile-protect-ship", "beam-protect-ship")
					wship.Stealthed = bool_set
				end
			end
		else
			--just do player ship since it is not in wing
			pship:setFlag(bool_set, "no-dynamic", "protect-ship", "laser-protect-ship", "missile-protect-ship", "beam-protect-ship")
			pship.Stealthed = bool_set
		end 

		if mothership ~= nil and mothership:isValid() then
			mothership:setFlag(bool_set, "protect-ship", "laser-protect-ship", "missile-protect-ship", "beam-protect-ship")
			mothership.Stealthed = bool_set
		end

	end

	--Used to get player un-docked or emerging from a fighter bay
	function MissionHelper:PlayerArrivesDocked()

		--recall that undocking automatically disables collisions..
		--..and will not enable them again until un-dock path is done

		local pship = FotG:GetPlayerShip() 

		if pship == nil then return end
		if not pship:isValid() then return end
		if pship:getBreedName() ~= "Ship" then return end

		if pship:isDying() then return end

		if pship:isDocked() then 
			-- lock to force to first person view (just in case some mission designer put start in 3rd person mode on)
			-- 3rd person bad b/c close up 3rd person we can see inside mothership, which is not professional
			-- note, free look still works even with lock-perspective enabled
			mn.evaluateSEXP("(lock-perspective !true! !0!)")

			pship:setFlag(true, "primaries-locked", "secondaries-locked")
			mn.evaluateSEXP("( player-use-ai ) ")

			local pname_ship = pship.Name
			if pname_ship ~= nil then
				mn.evaluateSEXP("( change-ai-class !AI_S_Captain_SlowShieldManger! !"..pname_ship.."! )")
			end

			local mothership = ExtraControls:TargetClosest_Specific("Friendly", pship, nil, 0, false, false, false)
			mn.evaluateSEXP("( ship-guardian !"..pname_ship.."! )")

			MissionHelper:Set_ControlGauges_Status(false)

			pship:clearOrders()
			pship:giveOrder(ORDER_PLAY_DEAD_PERSISTENT, nil, nil, self.high_pr/100)

			self:Dock_Ply_Hide_Helper(pship, mothership, true)
			
			Movements:UndockOrderSafe(pship, self.highest_pr)

			async.run(function()
				async.await(mn.waitAsync(1))
				MissionHelper:EqualizeSmallShields(pship)
				async.await(mn.waitAsync(12))
				if mothership ~= nil and mothership:isValid() then
					mothership:setUndocked(pship)
				end
				Movements:RemoveGoal_Correctly(pship, self.high_pr, "ai-play-dead-persistent")
				mn.evaluateSEXP("( set-player-throttle-speed !"..pname_ship.."! 100 )")

				self:Dock_Ply_Hide_Helper(pship, mothership, false)

				mn.evaluateSEXP("( ship-no-guardian !"..pname_ship.."! )")
				mn.evaluateSEXP("( player-not-use-ai )")
				pship:setFlag(false, "primaries-locked", "secondaries-locked")
				mn.evaluateSEXP("(lock-perspective !false! !0!)")
				MissionHelper:Set_ControlGauges_Status(true)
			end)
		end
		
	end

	function MissionHelper:Get_Mothership_Classname(ship) --arg is small ship potentially emerging from a bay

		--get arrival anchor name, will be nil if no arrival anchor
		local anchor_name
		local s_wing = ship:getWing()
		if s_wing ~= nil and s_wing:isValid() then 
			--is in wing
			anchor_name = s_wing.ArrivalAnchor
		else --not a wing
			anchor_name = ship.ArrivalAnchor
		end

		--if this ship has an arrival anchor then check if that anchor is an Arquitens
		if anchor_name ~= nil then
			local anchor_ship = mn.Ships[anchor_name]
			if anchor_ship ~= nil and anchor_ship:isValid() then
				return anchor_ship
			end
		end

		return nil

	end

	function MissionHelper:PlayerArrivefromDockingBay()

		local pship = FotG:GetPlayerShip()

		if pship == nil then return end
		if not pship:isValid() then return end
		if pship:getBreedName() ~= "Ship" then return end

		if pship:isDying() then return end

		local mothership = self:Get_Mothership_Classname(pship)
		if mothership == nil then return end
		if not mothership:isValid() then return end

		-- lock to force to first person view (just in case some mission designer put start in 3rd person mode on)
		-- 3rd person bad b/c close up 3rd person we can see inside mothership, which is not professional
		-- note, free look still works even with lock-perspective enabled
		mn.evaluateSEXP("(lock-perspective !true! !0!)")

		--setup and run AI for player
		--note that if player is set to AI then bay doors will immediately close, so only use this if more then 1 ship in player wing
		pship:setFlag(true, "primaries-locked", "secondaries-locked")
		mn.evaluateSEXP("( player-use-ai ) ")

		MissionHelper:Set_ControlGauges_Status(false)

		local pname_ship = pship.Name
		if pname_ship ~= nil then
			mn.evaluateSEXP("( set-player-throttle-speed !"..pname_ship.."! 0 )")
			mn.evaluateSEXP("( change-ai-class !AI_S_Captain_SlowShieldManger! !"..pname_ship.."! )")
		end
		pship:giveOrder(ORDER_PLAY_DEAD_PERSISTENT, nil, nil, self.high_pr/100)

		self:Dock_Ply_Hide_Helper(pship, nil, true)

		pship:setFlag(false, "collides")

		local zero_vec = FotG.VECTOR_ZERO
		pship.Physics.RotationalVelocity = zero_vec
		pship.Physics.Velocity = zero_vec

		local duration = 1.9
		local pitch = 0.2
		local forward = 0.7
		local unlock_time = 1.7

		--if player arriving from Arquitens bay then place right outside hangar bay, recall this function is not called in multi!
		local mothership_class_name = mothership.Class.Name
		local manual_offset 
		if string.find(mothership_class_name, "Arquitens") then
			--all automatic AI paths go up or down, so manual can go straight and fast
			manual_offset = {0, 0, 125}
			pitch = 0.0 
		elseif string.find(mothership_class_name, "Strike") then
			--strike has four quadrant AI paths, so this is in center in front
			manual_offset = {0, -5, 65} 
			pitch = 0.35
		elseif string.find(mothership_class_name, "Dreadnaught") then
			--dreadnaught has four quadrant AI paths, so this is in center in front
			manual_offset = {0, -37, 100} 
			pitch = 0.2
		elseif string.find(mothership_class_name, "Asteroid") then
			--asteroid base has 6 AI paths that start far back in hangar, so this is in center in front of all of them
			--also, asteroid base starts player back in hangar at angled orientation, so we need to fix that
			pship.Orientation = mothership.Orientation
			manual_offset = {0, 25, 580} 
			pitch = -0.05
		elseif string.find(mothership_class_name, "XQ") then
			--XQ1 base has AI paths that start far back in hangar, so this is in center in front of all of them
			--also, asteroid base starts player back in hangar at angled orientation, so we need to fix that
			manual_offset = {0, 22, 400} 
			pitch = -0.05
			pship.Orientation = mothership.Orientation
		elseif string.find(mothership_class_name, "Golan") then
			--for Golan we want to have the player just go out of the center and climb to avoid any other AI paths
			manual_offset = {0, 105, -150} 
			pitch = -0.3
			pship.Orientation = mothership.Orientation
		elseif string.find(mothership_class_name, "Shield Gate") then
			--for shield gate we want to keep the actual position since TIEs exit individual windows
			pitch = -0.3
		elseif string.find(mothership_class_name, "Imperial Star") then
			--for ISD we want to keep the actual position since TIEs exit individual windows
			pitch = 0.2
		elseif string.find(mothership_class_name, "Venator") then
			--for venator we want to keep the actual position and just go forward and then up
			pitch = -0.15
			forward = 0.15
			unlock_time = 5.5
		end
		if manual_offset ~= nil then
			pship.Position = mothership:findWorldPoint(ba.createVector(manual_offset[1], manual_offset[2], manual_offset[3]))
		end

		async.run(function()
			async.await(mn.waitAsync(0.5)) --need time for doors to open/screen to fade in
			--weird hardcoded FSO thing with it time >= 2.0
			pship:doManeuver(duration, 0, pitch, 0, true, 0, 0, forward, true)
			--doManeuver(number Duration, number Heading, number Pitch, number Bank, boolean ApplyAllRotation, number Vertical, number Sideways, number Forward, boolean ApplyAllMovement, number ManeuverBitfield)
			async.await(mn.waitAsync(0.5))
			mn.evaluateSEXP("( set-player-throttle-speed !"..pname_ship.."! 100 )")
			MissionHelper:EqualizeSmallShields(pship)
			async.await(mn.waitAsync(unlock_time))
			pship:setFlag(true, "collides")

			self:Dock_Ply_Hide_Helper(pship, nil, false)

			Movements:RemoveGoal_Correctly(pship, self.high_pr, "ai-play-dead-persistent")
			pship:setFlag(false, "primaries-locked", "secondaries-locked")
			mn.evaluateSEXP("( player-not-use-ai )")
			mn.evaluateSEXP("(lock-perspective !false! !0!)")
			MissionHelper:Set_ControlGauges_Status(true)
		end)


	end


	function MissionHelper:CheckSet_PlyDead()

		-- fix for quick restarts and isDying check
		-- overall this entire check is the quick way to check if player has died and the state has changed
		-- as opposed to always checking when a ship dies, b/c that itself does not always work

		self.player_maybe_invalid = false

		if not MTIME_OVER_P1 then return end

		local ply = FotG:GetPlayerShip()
		if ply == nil then
			self.player_maybe_invalid = true
			return 
		end
		if not ply:isValid() then
			self.player_maybe_invalid = true
			return
		end

		if ply:getBreedName() ~= "Ship" then 
			self.player_maybe_invalid = true
			return 
		end

		if ply:isDying() then
			self.player_maybe_invalid = true
			return 
		end

		if ply.HitpointsLeft <= 0 then
			self.player_maybe_invalid = true
			return 
		end

	end


	-- Used to give player better maneuverability at higher ETS engine values
	-- Also decrease maneuverability if speed near 0
	function MissionHelper:EngineBonus_Reset()

		self.enginebonus_enabled = false
		self.player_maybe_invalid = false
		self.enginebonus_OG_values = nil
		self.enginebonus_engine_subsystems = nil
	
	end

	function MissionHelper:EngineBonus_Enable() --calls Reset

		self:EngineBonus_Reset()

		if ba.MultiplayerMode then return end

		if GCW ~= nil and GCW.isactive and GCW.responses_table ~= nil and GCW.responses_table.choices_are_on then return end

		self.enginebonus_enabled = true

		self:CheckSet_PlyDead()
		if self.player_maybe_invalid then return end

		local ply = FotG:GetPlayerShip()
		if ply == nil then return end
		if not ply:isValid() then return end
		if ply:getBreedName() ~= "Ship" then return end

		local sip = ply.Physics

		--update with OG values from s-foils table values if needed..
		--..because closed s-foils make rot vel different
		local actual_rot_vel
		local signature = self.single_player_signature
		if signature ~= nil and Sfoils.meta_info ~= nil then
			local foilinfo = Sfoils.meta_info[signature]
			if foilinfo ~= nil then
				actual_rot_vel = ba.createVector(foilinfo.og_rotmax_x, foilinfo.og_rotmax_y, foilinfo.og_rotmax_z)
			end
		end

		--if not an s-foils ship just use rot vel
		if actual_rot_vel == nil then 
			local sip_mv = sip.RotationalVelocityMax
			actual_rot_vel = ba.createVector(sip_mv.x, sip_mv.y, sip_mv.z)
		end

		--cache engine subsystem names instead of using "hits-left-subsystem-generic" sexp
		local engine_subsystems = {}

		for subsystem in ply:getSubsystemList() do
			if subsystem ~= nil then
				local actual_sub_name = tostring(subsystem.CanonicalName)
				if string.findAny(actual_sub_name, {"engine", "Engine"}) then
					table.insert(engine_subsystems, actual_sub_name)
				end
			end
		end

		--set values
		self.enginebonus_engine_subsystems = engine_subsystems

		self.enginebonus_OG_values = {
			--RotMax must be first entry!
			{"RotationalVelocityMax", actual_rot_vel, -0.02}, --this one is backwards, since bigger values are faster
			{"ForwardAccelerationTime", sip.ForwardAccelerationTime, 0.03},
			{"ForwardDecelerationTime", sip.ForwardDecelerationTime, 0.02},
			{"RotationalVelocityDamping", sip.RotationalVelocityDamping, 0.005},
			{"VelocityDamping", sip.VelocityDamping, 0.01}
		}

		local sfoils_rotval
		local sfoils_ship = Sfoils.sclass_extra_info_tbl[string.filterInvisible(ply.Class.Name)]
		if sfoils_ship ~= nil then
			sfoils_rotval = sfoils_ship.rot_vel_factor
		else
			sfoils_rotval = 1.0
		end
		self.sfoils_rot_factor_inverse = 1/sfoils_rotval

		self.check_previous_mtime = 0
		self.check_interval = 0.15


	end

	function MissionHelper:Engine_Health_Ratio(ship, engine_ss_list)

		local total_engine_hitpoints_max = 0
		local total_engine_hitpoints_left = 0

		-- go through all engine subsystems and sum max and remaining hitpoints
		for _,v_engine_ss_name in ipairs(engine_ss_list) do
			local engine_ss = ship[v_engine_ss_name]
			if engine_ss ~= nil and engine_ss:isValid() then
				total_engine_hitpoints_max = total_engine_hitpoints_max + engine_ss.HitpointsMax
				total_engine_hitpoints_left = total_engine_hitpoints_left + engine_ss.HitpointsLeft
			end
		end

		--safety check
		if total_engine_hitpoints_max <= 0 then 
			total_engine_hitpoints_max = 1 
		end

		return total_engine_hitpoints_left/total_engine_hitpoints_max

	end

	function MissionHelper:EngineBonus_HealthCheck(ship, engine_ss_list, engine_threshold) --assumes ship and engine_ss list are valid

		engine_threshold = engine_threshold or 0.3

		--calculate overall health from 0 to 1
		if self:Engine_Health_Ratio(ship, engine_ss_list) > engine_threshold then
			return true
		else
			return false
		end

	end

	function MissionHelper:EngineBonus_Update()

		--runs every On Simulation frame to update
		--must not run if exiting or entering hyperspace or s-foils doing anything

		if not self.enginebonus_enabled then return end

		if self.player_maybe_invalid then return end

		--hyperspace check
		if HyperspaceExit.is_player_jumping_in or HyperspaceEnter.is_player_jumping_out or CapShipControl:IsEnabled() then
			return
		end

		--player validity
		local ply = FotG:GetPlayerShip()
		if ply == nil then return end
		if not ply:isValid() then return end
		if ply:getBreedName() ~= "Ship" then return end

		--PONDER adding timer interval check?
		--  values do not *need* to be set every frame since it remembers the values
		--  also 5-10 times a second is probably indistinguishable from 60 times a second?
		--  especially with damped physics
		local mtime = mn.getMissionTime()
		if mtime < self.check_previous_mtime + self.check_interval then
			return
		else
			self.check_previous_mtime = mtime
		end

		--s-foils check b/c bonus if closed, but we have to account for the 1.5 longer rot vel
		local s_foilsclosed = false
		local signature = self.single_player_signature
		if signature ~= nil and Sfoils ~= nil and Sfoils.meta_info ~= nil then
			local foilinfo = Sfoils.meta_info[signature]
			if foilinfo ~= nil then
				--no bonus if opening or closing
				if foilinfo.current_wings_method == Sfoils.method_moving then 
					return
				end
				if foilinfo.current_wings_method == Sfoils.method_close then
					s_foilsclosed = true
				end
			end
		end

		--get engines ETS (ranges from 0 - 12)
		local engine_power = ply.EtsEngineIndex

		--turn into step value
		local step_amount = 4-engine_power --4 is base-> ie 4-4 = 0, 4-6 = -2, 4-2 = 2 
		local engine_damaged_multi

		--recall, reduced benefit if going slow
		--players will use 1/3 throttle a lot for turning, 
		--so make sure this speed at which slow turning starts is much lower
		local slowdown_speed_initial = 25
		local slowdown_multi_final = 0.15

		--check eng health and scale improvement accordingly
		local eng_health = self:Engine_Health_Ratio(ply, self.enginebonus_engine_subsystems)

		--recall FSO is hard coded to make engines pop back to full speed capabilities at 50%
		--but the following code helps damaged engines to be slightly not as good, even if repaired to max

		--how high do engines self repair to? 45 to 65-ish
		--local self_repair_max = 0.4 -->under this engines should be slow while they repair?
		--recall speed will also be lower in FSO and going no near zero speed has slower effect, too
		local eng_hp_check = 0.85
		local eng_min_repaired = eng_hp_check -- or eng_hp_check - 0.5? nah
		local eng_min_abs = 0.1

		--eng repairs still take a while though, and this only affects player
		--so help speed up slow maneuvering at ranges from 20-40% especially 
		local eng_helper_multi = 2.0

		if eng_health > eng_hp_check then
			--engines are strong, so good improvement
			engine_damaged_multi = 1.0
		else
			--engines are weak, so poor improvement (recall lower values slower)
			if eng_health < eng_min_repaired then
				engine_damaged_multi = math.Clamp(eng_health * eng_helper_multi, eng_min_abs, eng_min_repaired)
			else
				engine_damaged_multi = eng_min_repaired --tiny optimization
			end
		end

		--account for stopped ship
		local p_phys = ply.Physics
		local speed = p_phys:getForwardSpeed()

		--for list, calculate and set new values
		--local updated_val = original_value * step_percent

		for i, v_ogval in ipairs(self.enginebonus_OG_values) do

			--get values and step
			local k_physicsvalue = v_ogval[1]
			local ogvalue = v_ogval[2]
			local step = v_ogval[3]
			local step_percent = 1.0 + (step_amount * step)
			local extra_multi = 1

			if i == 1 then --bit of optimization hack, first entry is RotationalVelocityMax
				--account for closed s-foils
				if s_foilsclosed then
					extra_multi = self.sfoils_rot_factor_inverse
				end
				--account for low speed, do it in a smooth way going from 1 to min multiplier
				--  though do not punish the player with low turning speeds if at lower difficulties
				--  so only run this slowdown if at higher difficulties
				if speed <= slowdown_speed_initial and self.current_game_diff >= 4 then

					local d = 1 - (speed/slowdown_speed_initial) 
					--if going initial slowdown speed then d is 0
					--if going 0 speed then d is 1
					extra_multi = extra_multi * math.Lerp(1.0, slowdown_multi_final, d)

				end
			end

			p_phys[k_physicsvalue] = ogvalue * step_percent * extra_multi * engine_damaged_multi
		end

	end

	function MissionHelper:SetTurretPriorities(shipname)

		if shipname ~= nil and shipname ~= "" then
			mn.evaluateSEXP("( ship-turret-target-order !"..shipname.."! !Ships! !Asteroids! !Bombs! )")
		end

	end

	function MissionHelper:On_Ship_Arrive(ship, is_multi)

		--validity
		if ship == nil then return end
		if not ship:isValid() then return end
		if ship:getBreedName() ~= "Ship" then return end

		local sname = ship.Name
		if FotG:IsStandaloneName(sname) then return end
		if FotG:IsDummyClass(ship.Class.Name) then return end

		--cache multi status if not specified
		if is_multi == nil then 
			if ba.MultiplayerMode then
				is_multi = true
			else
				is_multi = false
			end
		end

		--cache class type
		local sclass = ship.Class
		local stype = sclass.Type.Name
		local is_fighter_or_bomber = (stype == "fighter" or stype == "bomber")

		local ship_is_ply
		if ship:isPlayer() then
			ship_is_ply = true
		else
			ship_is_ply = false
		end

		--set compact green variant of weapons such as for N-1
		--makes more movie accurate and doing it this way means 
		--we do not have 2 KX-5 weapons that look identical and are confusing in the loadout for players
		if not is_multi then
			local filtered_classname = string.filterInvisible(sclass.Name)
			local wep_helper_info = self.weapon_helper.ship_classes[filtered_classname]
			if wep_helper_info ~= nil then
				local tbl_weapons = tb.WeaponClasses
				local ship_p_banks = ship.PrimaryBanks
				local num_banks = #ship.PrimaryBanks
				for i=1,num_banks do
					for k_ogwepname, v_updatewepname in pairs(wep_helper_info) do
						local bankwep = ship_p_banks[i]
						if bankwep.WeaponClass.Name == k_ogwepname then
							bankwep.WeaponClass = tbl_weapons[v_updatewepname]
						end
					end
				end
			end
		end

		local s_radius = ship.Radius

		--run functions, such as ETS balancing for no shields or slowing emerging ships from Arquitens
		--only for fighters or bombers though
		if is_fighter_or_bomber then

			local can_set_value

			--only set value if 
			--ship is not player ship in multiplayer and ship is on server
			--ship is not player ship in singleplayer

			if is_multi then
				--multiplayer
				if not ship_is_ply and multi:isServer() then
					can_set_value = true
				end
			else
				--singleplayer
				if not ship_is_ply then
					can_set_value = true
				end

			end

			if can_set_value then

				--if emerging from Arquitens bay then cap waypoint speed to 3 for 17 seconds
				local mothership = self:Get_Mothership_Classname(ship)
				if not ship_is_ply and mothership ~= nil and mothership:isValid() then
					local ship_phy = ship.Physics
					local og_veldamp = ship_phy.VelocityDamping
					local og_accl = ship_phy.ForwardAccelerationTime
					if string.find(mothership.Class.Name, "Arquitens") then
						ship_phy.VelocityDamping = 0
						ship_phy.ForwardAccelerationTime = 5
						ship.WaypointSpeedCap = 140
						async.run(function()
							async.await(mn.waitAsync(5))
							if ship ~= nil and ship:isValid() then
								ship.Physics.VelocityDamping = og_veldamp
								ship.Physics.ForwardAccelerationTime = og_accl
								ship.WaypointSpeedCap = -1
							end
						end)
					end
				end

			end

		else
			-- set turrets to prioritize ships over bombs (recall huge only weapons never target bombs)
			self:SetTurretPriorities(ship.Name)
			-- if big ship than make mass larger to prevent small ship collisions throwing it off
			if s_radius > self.radius_for_extra_mass then
				local mass = ship.Physics.Mass
				ship.Physics.Mass = mass + self.extra_mass_helper
			end
		end

		if is_multi then
			return 
		end

		local is_hostile = (string.find(ship.Team.Name, "Hostile") ~= nil)	
		
		--if hostile small and difficulty at medium or lower then remove countermeasures
		if is_fighter_or_bomber and is_hostile and self:GetGameDifficulty() <= 3 then
			ship.CountermeasuresLeft = 0
		end

		--add to collisional group according to type, but do not do for Player
		--also do not do if collision cull not enabled or if in multi (recall multi return above)
		if not ship_is_ply and ((self.collide_cull_enabled_h and is_hostile) or (self.collide_cull_enabled_f and not is_hostile)) then 

			local collisional_group_id

			--find right type
			if is_fighter_or_bomber then
				--not using ATM
				if (self.collide_cull_also_on_small_F and not is_hostile) or (self.collide_cull_also_on_small_H and is_hostile) then
					if is_hostile then
						collisional_group_id = self.collide_cull_grp_small_hostile_AI
					else
						collisional_group_id = self.collide_cull_grp_small_friendly_AI
					end
				end
			else
				collisional_group_id = self.collide_cull_grp_big_all_AI
			end

			--add it
			if collisional_group_id ~= nil then
				ship:addToCollisionGroup(collisional_group_id)
			end

			if s_radius < self.collide_tinybig_small_f_help then
				--only for friendly team, as player needs to be able to shake tails of hostile fighters so they need to collide
				--also it will not be as noticeable if hostile ships collide with ships they are guarding
				if not is_hostile then
					ship:addToCollisionGroup(self.collide_cull_grp_smallish_friendly_AI)
				end
			end

		end

	end

	function MissionHelper:On_Ship_Jump(ship)

		if ship == nil then return end
		if not ship:isValid() then return end
		if ship:getBreedName() ~= "Ship" then return end

		--if it's a big ship make it not collide with anything
		--b/c friendly pilots might be in the way and we do not want
		--a big friendly taking out friendly pilots this way

		--in the hyperspace script we have ways of checking exit vector alignment
		--and line-of-sight to see if anyone is in the way
		--but overall if we have reached the point of jumping out
		--then ships should just be able to leave without causing a scene
		local stype = ship.Class.Type.Name
		if (stype == "fighter") or (stype == "bomber") then
			--add small ships to big ship collisional group so if they jump they can 
			--  go smoothly and not crash into a big ship on the way out
			--do not use collides though b/c that may affect wings/waves
			--note, this will only actually be useful if collision culls were enabled in the mission
			ship:addToCollisionGroup(self.collide_cull_grp_big_all_AI)
		elseif ship.Radius >= self.radius_for_no_collided_exit then
			ship:setFlag(false, "collides")
		end

	end

	function MissionHelper:SetGameDifficulty()

		self.current_game_diff = ba.getGameDifficulty()

	end

	function MissionHelper:GetGameDifficulty()

		if self.current_game_diff ~= nil then
			return self.current_game_diff
		else
			return ba.getGameDifficulty() or 3
		end

	end

	function MissionHelper:On_Mission_Start()

		--cache multiplayer status
		local is_multi
		if ba.MultiplayerMode then
			is_multi = true
		else
			is_multi = false
		end

		--cache player signature
		self.single_player_signature = nil
		if not is_multi then
			local ply = FotG:GetPlayerShip()
			if ply ~= nil and ply:isValid() then
				self.single_player_signature = ply:getSignature()
			end
		end

		self:SetGameDifficulty()

		--disable motion debris
		mn.evaluateSEXP("( set-motion-debris-override ( true ) )")

		--check and set engine bonus
		self:EngineBonus_Enable() --returns early if in multiplayer

		--set destroyed subsystems react
		if not is_multi and mn.Events[self.destroyed_ss_react_eventname]:isValid() then
			self.destroyed_ss_react = true
			--actual changes and code runs in GCW script
		else
			self.destroyed_ss_react = false
		end

		-- special arrives for player and set collision cull status if not in multi
		if not is_multi then

			--enable HUD
			mn.evaluateSEXP("( hud-disable 0 )") --0 to enable

			--do special player arrivals for player ship
			if mn.Events[self.playerarrives_docked_eventname]:isValid() then
				self:PlayerArrivesDocked()
			end
			if mn.Events[self.playerarrives_bay_eventname]:isValid() then
				self:PlayerArrivefromDockingBay()
			end

			--protect player subsystems depending on situation
			local ply_ship = FotG:GetPlayerShip()
			if self:GetGameDifficulty() <= 3 then
				--protect all subsystems on lower difficulties
				self:GuardianSubsystems(ply_ship)
			else --elseif difficulty >= 4 then
				--always protect comms so players does not miss important messages
				--idea can be that there are some backup comms buried in center of ship
				self:GuardianSubsystems(ply_ship, 36, 41, self.guardian_onlycomms)
				--also make collisions more deadly 
				if ply_ship ~= nil and ply_ship:isValid() and ply_ship:getBreedName() == "Ship" then
					ply_ship.ImpactDamageClass = self.impact_damage_high
				end
			end

			self.collide_cull_enabled_f = false
			self.collide_cull_enabled_h = false

			--setup collisions
			if mn.Events[self.collide_cull_on_eventname_def]:isValid() then
				ba.print("EnableCollisionCulls All function has been enabled. All large ships will be added to the no collide collisional group, meaning they will not collide with each other...\n")
				self.collide_cull_enabled_f = true
				self.collide_cull_enabled_h = true
			elseif mn.Events[self.collide_cull_on_eventname_friend]:isValid() then
				ba.print("EnableCollisionCulls Friendly function has been enabled. All large friendly ships will be added to the no collide collisional group, meaning they will not collide with each other...\n")
				self.collide_cull_enabled_f = true
			elseif mn.Events[self.collide_cull_on_eventname_hostile]:isValid() then
				ba.print("EnableCollisionCulls Hostile function has been enabled. All large hostile ships will be added to the no collide collisional group, meaning they will not collide with each other...\n")
				self.collide_cull_enabled_h = true
			end

		else

			--run multiplayer sexps, but only on server
			--bomber turret setting is done in bomber turret script
			--what's left to do is lock afterburners of all ships
			if multi:isServer() then
				mn.evaluateSEXP("( alter-ship-flag !afterburners-locked! ( true ) ( true ) )")
			end

		end

		--run any needed aspects for current ships
		for ship in mn.getShipList() do
			self:On_Ship_Arrive(ship)
		end

	end

	function MissionHelper:On_Mission_End()

		self:EngineBonus_Reset()
		self.destroyed_ss_react = false
		self.single_player_signature = nil

	end


	--Custom SEXPs to link with functions of MissionHelper

	mn.LuaSEXPs["difficulty-number"].Action = function() --returns game difficult as number
		return MissionHelper:GetGameDifficulty()
	end

	mn.LuaSEXPs["is-campaign?"].Action = function()
		local answer = false
		if mn.isInCampaign() then
			answer = true
		end
		return answer
	end

	mn.LuaSEXPs["variable-divide"].Action = function (var_num, var_denom)

		--variable handles must both exist and be valid
		if var_num == nil or var_denom == nil then return 0 end
		if not var_num:isValid() or not var_denom:isValid() then return 0 end

		local numerator = var_num.Value
		local denominator = var_denom.Value

		--string variables cannot be divided
		if type(numerator) ~= "number" or type(denominator) ~= "number" then return 0 end

		--cannot divide by zero, and a negative denominator has no meaningful percent
		if denominator <= 0 then return 0 end

		--clamp so that a negative result reads as 0 and a ratio over 1 reads as 100,
		--rather than either one falling outside the documented range
		return math.Clamp(math.round((numerator/denominator)*100), 0, 100)

	end

	mn.LuaSEXPs["number-to-time"].Action = function(seconds, variable)
		if seconds == nil then return end
		if variable == nil then return end
		local minutes = math.floor(seconds / 60)
		local remainingSeconds = seconds % 60
		variable.Value = string.format("%d:%02d", minutes, remainingSeconds)
	end

	-- Used to change ship stats like shields or bank constant 
	-- Weapon and maneuverability settings should not be changed since they are tied to changing with other scripts..
	-- ..such as the engine bonus, s-foils, auto-aim with stationary mode, etc 

	--mn.LuaSEXPs["set-cockpit-moveable"].Action = function(moveable_name, ...)

		--if #arg <= 0 or moveable_name == nil then return end

		--local tbl = {}
		--for _, value in ipairs(arg) do
			--table.insert(tbl, value[1])
		--end

		--mn.updateSpecialSubmodelMoveable("cockpit", moveable_name, tbl)

	--end

	mn.LuaSEXPs["set-player-target-sub"].Action = function (ship_to_target, sub_to_target)

		if ba.MultiplayerMode then return end

		local ply = FotG:GetPlayerShip()
		if ply == nil then return end
		if not ply:isValid() then return end
		if ply:getBreedName() ~= "Ship" then return end

		if ship_to_target ~= nil and ship_to_target:isValid() then
			ply.Target = ship_to_target
			if sub_to_target ~= nil and sub_to_target:isValid() then
				ply.TargetSubsystem = sub_to_target
			else
				ply.TargetSubsystem = nil
			end
		else
			ply.Target = nil
			ply.TargetSubsystem = nil
		end
		

	end

	mn.LuaSEXPs["set-impact-armor-type"].Action = function(impact_armor_id, ...)

		if ba.MultiplayerMode then return end
		if #arg <= 0 then return end
		if type(impact_armor_id) ~= "number" then 
			impact_armor_id = 0 
		end

		for _, value in ipairs(arg) do
			local ship = value[1]
			if ship ~= nil and ship:isValid() then
				if impact_armor_id == 1 then 
					ship.ImpactDamageClass = MissionHelper.impact_damage_high
				else
					ship.ImpactDamageClass = MissionHelper.impact_damage_low
				end
			end
		end

	end

	mn.LuaSEXPs["set-guarders-to-orbit"].Action = function(...)

		if ba.MultiplayerMode then return end
		if #arg <= 0 then return end

		for _, value in ipairs(arg) do
			local ship = value[1]
			if ship ~= nil and ship:isValid() then
				MissionHelper:GuardeesOrbit(ship)
			end
		end

	end

	mn.LuaSEXPs["set-shield-recharge-percent"].Action = function(recharge_percent, ...)

		if ba.MultiplayerMode then return end
		if #arg <= 0 then return end
		if recharge_percent < 0 then 
			recharge_percent = 0 
		end

		for _, value in ipairs(arg) do
			local ship = value[1]
			if ship ~= nil and ship:isValid() then
				ship.ShieldRegenRate = math.round(recharge_percent/100, 3)
			end
		end

	end

	mn.LuaSEXPs["set-shield-special-hitpoints"].Action = function(special_hitpoints_as_percent, ...)

		if ba.MultiplayerMode then return end
		if #arg <= 0 then return end
		if special_hitpoints_as_percent <= 0 then 
			return
		end

		for _, value in ipairs(arg) do
			local ship = value[1]
			if ship ~= nil and ship:isValid() then
				local ship_shields = ship.Shields
				if ship_shields ~= nil then 
					local og_hitpoints = ship_shields.CombinedMax 
					local current_hitpoints = ship_shields.CombinedLeft 
					local new_hitpoints_max = math.round(og_hitpoints * (special_hitpoints_as_percent/100))
					local new_hitpoints_current = math.min(math.round(current_hitpoints * (special_hitpoints_as_percent/100)), new_hitpoints_max)
					if new_hitpoints_max >= 0 then
						ship_shields.CombinedMax = new_hitpoints_max
						ship_shields.CombinedLeft = new_hitpoints_current
					end
				end
			end
		end

	end

	mn.LuaSEXPs["set-hull-special-hitpoints"].Action = function(special_hitpoints_as_percent, ...)

		if ba.MultiplayerMode then return end
		if #arg <= 0 then return end
		if special_hitpoints_as_percent <= 0 then 
			return
		end

		for _, value in ipairs(arg) do
			local ship = value[1]
			if ship ~= nil and ship:isValid() then
				local og_hitpoints = ship.HitpointsMax 
				local current_hitpoints = ship.HitpointsLeft 
				local new_hitpoints_max = math.round(og_hitpoints * (special_hitpoints_as_percent/100))
				local new_hitpoints_current = math.min(math.round(current_hitpoints * (special_hitpoints_as_percent/100)), new_hitpoints_max)
				if new_hitpoints_max >= 0 then
					ship.HitpointsMax = new_hitpoints_max
					ship.HitpointsLeft = new_hitpoints_current
				end
			end
		end

	end

	mn.LuaSEXPs["set-subsystem-special-hitpoints"].Action = function(special_hitpoints_as_percent, ...)

		if ba.MultiplayerMode then return end
		if #arg <= 0 then return end
		if special_hitpoints_as_percent <= 0 then 
			return
		end

		for _, value in ipairs(arg) do
			local ship = value[1]
			local subsystem = value[2]
			if ship ~= nil and ship:isValid() and subsystem ~= nil and subsystem:isValid() then
				local og_hitpoints = subsystem.HitpointsMax 
				local current_hitpoints = subsystem.HitpointsLeft 
				local new_hitpoints_max = math.round(og_hitpoints * (special_hitpoints_as_percent/100))
				local new_hitpoints_current = math.min(math.round(current_hitpoints * (special_hitpoints_as_percent/100)), new_hitpoints_max)
				if new_hitpoints_max >= 0 then
					subsystem.HitpointsMax = new_hitpoints_max
					subsystem.HitpointsLeft = new_hitpoints_current
				end
			end
		end

	end


	-- Used to spawn ship for practice mission
	PracticeMode = {
		ship_spawned_varname = 'Max_Ships_Spawned'
	}

	function PracticeMode:Spawn(team_number) --1 is friendly 2 is hostile

		if team_number == 1 or team_number == 2 then
			--get team name
			local teams = {"Friendly", "Hostile"}
			local team = teams[team_number]

			--get player target class and size
			local player = FotG:GetPlayerShip()
			if player == nil then return end
			if not player:isValid() then return end
			if player:getBreedName() ~= "Ship" then return end

			local ptarget = player.Target
			if ptarget == nil then return end

			local ptargetname = tostring(ptarget)
			if ptargetname == nil then return end

			local ptargetship = mn.Ships[ptargetname]
			if ptargetship == nil then return end

			if not ptargetship:isValid() then return end

			local tclass = ptargetship.Class
			if tclass == nil then return end

			local classtype = tclass.Type.Name
			if classtype ~= "fighter" and classtype ~= "bomber" then
				FotG:PlaySound_Interface(FotG.sound_index_fail)
				return 
			end

			local tclassname = tclass.Name
			local t_radius = ptargetship.Radius + 100

			--set spawn location
				--local spawn_range = 4*t_radius
				--local spawn_positions = {
					--{-1735, 0, 2088},
					--{1340, 0, 1835}
				--}
				--local spawn_pos = spawn_positions[team_number]
				--for i=1,3 do
					--spawn_pos[i] = player.Position[i] + ba.rand32(-spawn_range, spawn_range)
				--end
			local pos_mag_x = (t_radius * 3) + 200
			local pos_mag_y = (t_radius * 3) + 200
			local pos_mag_z = (t_radius * 4) + 2000
			local spawn_pos = {
				math.Random_Magnitude(pos_mag_x, pos_mag_x*1.3),
				math.Random_Magnitude(pos_mag_y, pos_mag_y*1.3),
				math.Random_Magnitude(pos_mag_z, pos_mag_z*1.3)
			}

			--do pre spawn ship checks 
			local ship_number_var = mn.SEXPVariables[self.ship_spawned_varname]
			if ship_number_var == nil then
				FotG:PlaySound_Interface(FotG.sound_index_fail)
				return
			end

			local ship_number = ship_number_var.Value or 0

			--if too many spawns then sad message via mission events
			if ship_number >= 9999 then
				FotG:PlaySound_Interface(FotG.sound_index_fail)
				return
			end

			--set name and and spawn and update variable
			ship_number = ship_number + 1
			local sname = "Ship" .." "..tostring(ship_number)
			mn.SEXPVariables[self.ship_spawned_varname] = ship_number

			FotG:PlaySound_Interface(FotG.sound_index_success)

			local newship_pos = player:findWorldPoint(ba.createVector(spawn_pos[1], spawn_pos[2], spawn_pos[3]))
			local newship = mn.createShip(sname, tb.ShipClasses[tclassname], player.Orientation, newship_pos, mn.Teams[team])

			--change AI class per difficulty
			local ai_tbl = {"AI_07_Captain", "AI_08_Major", "AI_09_Commander", "AI_10_Colonel", "AI_11_General", "AI_12_Jedi"}
			local diff = MissionHelper:GetGameDifficulty()
			local ai_class = ai_tbl[diff] 
			mn.evaluateSEXP("( change-ai-class !"..ai_class.."! !"..sname.."! )")

			--set orders
			if newship == nil then return end
			if not newship:isValid() then return end
			local stype = newship.Class.Type.Name
			if stype == "fighter" or stype == "bomber" then
				--player cannot order hostile ships
				if team_number == 1 then
					local ord_str = "!Destroy my target! !Disable my target! !Disarm my target! !Protect my target! !Ignore my target! !Form on my wing! !Cover me! !Engage enemy!"
					--TIEs cannot jump
					if not string.findAny(tclassname, {"T.I.E", "TIE"}) then
						ord_str = ord_str .. " !Depart!"
					end
					mn.evaluateSEXP("( set-player-orders !"..sname.."! ( true ) "..ord_str.." )")
				end
				--attack any order
				newship:giveOrder(ORDER_ATTACK_ANY, nil, nil, 89/100)
			end

		end

	end

	function PracticeMode:Kill()

		--get player target name
		local ptarget = MissionHelper:Get_Player_Target()
		if ptarget ~= nil and ptarget:isValid() then 
			--kill ship, don't kill civilians
			local tteam = ptarget.Team.Name
			if tteam == "Friendly" or tteam == "Hostile" then
				FotG:PlaySound_Interface(FotG.sound_index_success)
				mn.evaluateSEXP("( self-destruct !"..ptarget.Name.."! )")
				return true
			end
		end

		return false

	end

--

--Hooks
if not IS_STANDALONE then
	engine.addHook("On Simulation", function() 
			MissionHelper:EngineBonus_Update()
		end
	)

	engine.addHook("On Gameplay Start", function() 
			MissionHelper:On_Mission_Start()
		end
	)

	engine.addHook("On Mission About To End", function() 
			MissionHelper:On_Mission_End()
		end
	)


	-- Auto switch to single-player so Techroom missions are easy to get to
	-- Seems like a lot of redundancies, but they are all needed!
	engine.addHook("On State Start", function() 
			MissionHelper:AutoSinglePlayer()
		end,
		{State="GS_STATE_MAIN_MENU"}
	)

	engine.addHook("On State Start", function() 
			MissionHelper:AutoSinglePlayer()
		end,
		{State="GS_STATE_TECH_MENU"}
	)

	engine.addHook("On State Start", function() 
			MissionHelper:AutoSinglePlayer()
		end,
		{State="GS_STATE_SIMULATOR_ROOM"}
	)

	engine.addHook("On State Start", function() 
			MissionHelper:CheckSet_PlyDead()
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Ship Arrive", function() 
			MissionHelper:On_Ship_Arrive(hv.Ship)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)	

	engine.addHook("On Warp Out", function() 
			--recall this hook triggers at start of warpout function in code
			MissionHelper:On_Ship_Jump(hv.Self)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On State End", function() 
			if tostring(hv.NewState) ~= "GS_STATE_QUIT_GAME" then
				MissionHelper:CheckSet_PlyDead()
			end
		end,
		{State="GS_STATE_GAME_PLAY"}
	)
end
