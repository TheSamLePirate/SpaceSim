-- This file contains all the scripting related to s-foils

Sfoils = {
	meta_info = {},
	time_of_last_fail_sound = 0,
	--first value is animation time
	--second value is sound in sounds.tbl
	method_close = -1,
	method_moving = 0,
	method_open = 1,
	disable_sfoils_event_name = "Force Manual S-foils",
	sclass_extra_info_tbl = { --animation time, 3D sound entry, 2D sound entry, sound time length,
		["T-65c X-wing"]={
			anim_time = 1.0,
			sound_time = 1.93,
			sound_3d = 173,
			sound_2d = 169,
			rot_vel_factor = 1.5,
			close_faster_aburn = true, 
			close_for_hyperspace = true
		},
		["ARC-170 Starfighter"]={
			anim_time = 1.0,
			sound_time = 1.93,
			sound_3d = 173,
			sound_2d = 169,
			rot_vel_factor = 1.5,
			close_faster_aburn = true,
			close_for_hyperspace = true
		},
		["ASF-01 B-wing"]={
			anim_time = 2.5,
			sound_time = 3.12,
			sound_3d = 174,
			sound_2d = 170,
			rot_vel_factor = 1.5,
			close_faster_aburn = true,
			close_for_hyperspace = true
		},
		["UT-60D U-wing"]={
			anim_time = 2.75,
			sound_time = 3.87,
			sound_3d = 176,
			sound_2d = 172,
			rot_vel_factor = 1.5,
			close_faster_aburn = true,
			close_for_hyperspace = true
		},
		["Skipray Blastboat"]={
			anim_time = 2.75,
			sound_time = 3.87,
			sound_3d = 176,
			sound_2d = 172,
			rot_vel_factor = 1.5,
			close_faster_aburn = true,
			close_for_hyperspace = true
		},
		["A-3 V-wing Starfighter"]={
			anim_time = 1.0,
			sound_time = 1.93,
			sound_3d = 173,
			sound_2d = 169,
			rot_vel_factor = 4.0,
			close_faster_aburn = false, 
			close_for_hyperspace = false
		},
		["XG-1 Star Wing"]={
			anim_time = 2.75,
			sound_time = 3.87,
			sound_3d = 176,
			sound_2d = 172,
			rot_vel_factor = 4.0,
			close_faster_aburn = false, 
			close_for_hyperspace = false
		},
		["Lambda T-4a Shuttle"]={
			anim_time = 5.0,
			sound_time = 6.0,
			sound_3d = 175,
			sound_2d = 171,
			rot_vel_factor = 4.0,
			close_faster_aburn = false, 
			close_for_hyperspace = false
		},
		["Zeta Hvy Cargo Shuttle"]={
			anim_time = 5.0,
			sound_time = 6.0,
			sound_3d = 175,
			sound_2d = 171,
			rot_vel_factor = 4.0,
			close_faster_aburn = false,
			close_for_hyperspace = false
		}
	},
	deal_with_special_bwing_rot = false
}

--Code

	function Sfoils:Reset()

		self.meta_info = nil
		self.meta_info = {}
		self.time_of_last_fail_sound = 0

	end

	function Sfoils:CheckAddShip_MetaInfo(ship)

		if ship == nil then return end
		if not ship:isValid() then return end

		local signature = ship:getSignature()
		--add to list if it doesn't exist
		--use tabled rotational velocity b/c physics rot velocity may compound
        if self.meta_info[signature] == nil then
			local filtered_classname = string.filterInvisible(ship.Class.Name)
			local sclass_rot = ship.Class.RotationTime 
			local twopi_rad = math.pi * 2
			local tbl_rot_val_x = twopi_rad/sclass_rot.x
			local tbl_rot_val_y = twopi_rad/sclass_rot.y
			local tbl_rot_val_z = twopi_rad/sclass_rot.z

			local rot_scale = self.sclass_extra_info_tbl[filtered_classname].rot_vel_factor

			local shields = ship.Shields
			local shields_remaining_front = 0
			local shields_remaining_rear = 0
			if shields ~= nil then
				shields_remaining_front = shields[1] or 0
				shields_remaining_rear = shields[2] or 0
			end

			self.meta_info[signature] = {
				current_wings_method = self.method_open, --since ships start with s-foils opened as the base model
				og_rotmax_x = tbl_rot_val_x,
				og_rotmax_y = tbl_rot_val_y,
				og_rotmax_z = tbl_rot_val_z,
				sfoil_rotmax_x = tbl_rot_val_x/rot_scale,
				sfoil_rotmax_y = tbl_rot_val_y/rot_scale,
				sfoil_rotmax_z = tbl_rot_val_z/rot_scale,
				ets_e = math.round(ship.EtsEngineIndex or 0),
				ets_s = math.round(ship.EtsShieldIndex or 0),
				ets_w = math.round(ship.EtsWeaponIndex or 0),
				shields_remaining_front = shields_remaining_front,
				shields_remaining_rear = shields_remaining_rear
			}
		end

	end

	function Sfoils:ShipEquipped(shipclassname)
	
		-- helper to ID all current ships with wings
		-- assumes caller has checked for validity already!
		shipclassname = string.filterInvisible(shipclassname)
		if self.sclass_extra_info_tbl[shipclassname] ~= nil then
            return true
        else
            return false
        end

	end

	function Sfoils:Should_Close_on_Hyper(sclassname)

		if sclassname == nil then return false end

		local info = self.sclass_extra_info_tbl[sclassname]

		if info == nil then return false end

		return info.close_for_hyperspace

	end

	function Sfoils:Check_Run_BwingRotation(ship, method, isinstant, shipclass_filtered)

		--not running ATM since not rotating cockpit (see animation table)
		local not_running_rotation = not self.deal_with_special_bwing_rot
		if not_running_rotation then return end

		if shipclass_filtered ~= "ASF-01 B-wing" then return end

		if ship == nil then return end
		if not ship:isValid() then return end

		local bwing_rot
		if method == self.method_open then
			bwing_rot = -90
		elseif method == self.method_close then
			bwing_rot = 90
		end

		if bwing_rot ~= nil then

			local ort = ship.Orientation
			local new_pbh = {p=ort.p, b=(ort.b + bwing_rot), h=ort.h}

			if isinstant then
				ship.Orientation = ba.createOrientation(new_pbh.p, new_pbh.b, new_pbh.h)
			else
				local rot_time = self.sclass_extra_info_tbl["ASF-01 B-wing"].anim_time + 0.3
				local input_tbl = {
					SR_IN_time_delay = 0,
					SR_IN_rotation_time = rot_time,
					SR_IN_play_dead_PR = nil,
					SR_IN_final_pbh_target_name = nil,
					SR_IN_final_pbh_special_override = nil
				}
				Movements:Add_Rotation(ship.Name, new_pbh, input_tbl)
			end

		end

	end

	function Sfoils:Toggle_Pre(ship, shipsig, method, is_instant, disable_auto_afterburn, shipclassname)

		-- function for start of s-foil toggle, returns animation time and any attached sound

		-- few failsafe checks just in case
		if shipsig == nil or ship == nil then
			return nil, nil
		end

		local ship_metainfo = self.meta_info[shipsig]
		if ship_metainfo == nil then
			return nil, nil
		end

		--check method
		local is_forward
		if method == self.method_open then
			is_forward = false
		elseif method == self.method_close then
			is_forward = true
		else
			return nil, nil
		end

		if not ship:isValid() then
			return nil, nil
		end

		--check and run B-wing ship rotation if needed
		self:Check_Run_BwingRotation(ship, method, is_instant, shipclassname)

		--determine sound and animation time
		local animation_time
		local foil_info = self.sclass_extra_info_tbl[shipclassname]
		local sound_entry_index = foil_info.sound_3d
		if is_instant then
			animation_time = 0
		else
			animation_time = foil_info.anim_time
		end

		--set as animation running
		ship_metainfo.current_wings_method = self.method_moving

		--and actually run animation
		local reset_on_start = false

		ship:triggerSubmodelAnimation("scripted", "SFoils_Toggle", is_forward, reset_on_start, is_instant)
		local sound_entry, assigned_sound_index

		--set sound to play and attach to ship if not instant
		if not is_instant then
			--we can use OS_PLAY_ON_PLAYER to assign a sound for non-player ships..
			--..though playing a 2d sound is quicker and easier
			if ship:isPlayer() then
				--play 2d sound if player
				ad.playGameSound(foil_info.sound_2d)
			else
				--use assign sound if AI
				sound_entry = ad.getSoundentry(sound_entry_index) --these are valid 3D sounds
				if sound_entry ~= nil and sound_entry:isValid() then
					--ad.play3DSound(sound_entry, ship.Position)
					assigned_sound_index = ship:assignSound(sound_entry, FotG.VECTOR_ZERO, BitOps.EnumOR(OS_MAIN, OS_LOOPING_DISABLED))
					----save this as example of how to assign sound 
				end
			end
		end

		local deal_with_afterburner = foil_info.close_faster_aburn

		--if close
		if method == self.method_close then
			--save current ETS values and shields
			ship_metainfo.ets_e = math.round(ship.EtsEngineIndex)
			ship_metainfo.ets_s = math.round(ship.EtsShieldIndex)
			ship_metainfo.ets_w = math.round(ship.EtsWeaponIndex)
			local shields = ship.Shields
			if shields ~= nil then
				ship_metainfo.shields_remaining_front = shields[1] or 0
				ship_metainfo.shields_remaining_rear = shields[2] or 0
			end
			--disable ETS and set to all engine and shields
			ship:EtsSetIndexes(6, 6, 0) --engine, shield, weapon
			--lock weapons
			ship:setFlag(true, "primaries-locked", "no-ets")
			--set after burners and maneuverability if that type of ship
			if deal_with_afterburner and not disable_auto_afterburn then
				ship:setFlag(false, "afterburners-locked")
				ship.Physics.AfterburnerActive = true
			end
			ship.Physics.RotationalVelocityMax = ba.createVector(ship_metainfo.sfoil_rotmax_x, ship_metainfo.sfoil_rotmax_y, ship_metainfo.sfoil_rotmax_z)
		end

		--if open 
		if method == self.method_open then
			--turn off afterburners and restore default maneuverability
			if deal_with_afterburner then
				ship.Physics.AfterburnerActive = false
				ship:setFlag(true, "afterburners-locked")
			end
			ship.Physics.RotationalVelocityMax = ba.createVector(ship_metainfo.og_rotmax_x, ship_metainfo.og_rotmax_y, ship_metainfo.og_rotmax_z)
			--enable shields (not turning off, see comments in closing section above)
			--also doing unlock weapons and ets later once wings actually done opening
		end

		--shields will temporarily 'turn off' with any motion, unless instant
		--turn off shields, though do not use disable-shields sexp because that changes ETS values
		if not is_instant then
			local shields = ship.Shields
			if shields ~= nil then
				ship.Shields[1] = 0
				ship.Shields[2] = 0
			end
		end

		return animation_time, sound_entry

	end

	function Sfoils:Toggle_Post(ship, shipsig, method, sound_entry)

		-- function for end of s-foil toggle

		-- validity checks and variable setup
		if shipsig == nil or ship == nil then
			return 
		end

		local ship_metainfo = self.meta_info[shipsig]

		if ship_metainfo == nil then 
			return
		end

		ship_metainfo.current_wings_method = method

		if not ship:isValid() then
			return
		end

		--reset shields
		if method == self.method_open then
			--finally allow weapons and ets to be set
			--unlock primary weapons
			ship:setFlag(false, "primaries-locked", "no-ets")
			--enable ETS and restore saved values
			ship:EtsSetIndexes(ship_metainfo.ets_e, ship_metainfo.ets_s, ship_metainfo.ets_w)
			--EtsSetIndexes(number EngineIndex, number ShieldIndex, number WeaponIndex)
		end

		local shields = ship.Shields
		if shields ~= nil then
			ship.Shields[1] = ship_metainfo.shields_remaining_front
			ship.Shields[2] = ship_metainfo.shields_remaining_rear
		end
		--unassign sound
		if sound_entry ~= nil and sound_entry:isValid() then
			ship:removeSound(sound_entry)
		end

	end

	function Sfoils:Get_AnimTime_Full(s_classname_simple, assigned_snd, anim_time_override)

		local buffer_time = 0.1

		local info = self.sclass_extra_info_tbl[s_classname_simple]
		local ani_time = anim_time_override or info.anim_time

		if assigned_snd then
			--if using tracking/attached 3d sound
			return math.max(ani_time + buffer_time, info.sound_time)
		else
			--recall player does not have tracking 3d sound, so no need to wait long to cut off any sound
			return ani_time + buffer_time
		end

	end

	function Sfoils:Toggle(ship, method, is_instant, disable_auto_afterburn, delayed_start_time)

		--validity checks
		if ba.MultiplayerMode then return end
		if ship == nil then return end
		if not ship:isValid() then return end

		local shipclassname = string.filterInvisible(ship.Class.Name)

		--final failsafe check if this ship can do s-foils
		if not self:ShipEquipped(shipclassname) then return end

		--set default values
		delayed_start_time = delayed_start_time or 0

		if is_instant == nil then 
			is_instant = false
		end
		if disable_auto_afterburn == nil then
			--mainly used to keep afterburners off when closing s-foils before jumping to hyperspace
			disable_auto_afterburn = false
		end

		--set metatable if nil
		self:CheckAddShip_MetaInfo(ship)
		local shipsig = ship:getSignature()
		local ship_metainfo = self.meta_info[shipsig]

		--return early if wings moving
		if ship_metainfo.current_wings_method == self.method_moving then
			return 
		end

		--do not change if this is the same status as the wing already are
		if ship_metainfo.current_wings_method == method then 
			return
		end

		--set method status once time elapsed
		if is_instant then
			--set instant
			local anim_time, assigned_snd = self:Toggle_Pre(ship, shipsig, method, is_instant, disable_auto_afterburn, shipclassname)
			self:Toggle_Post(ship, shipsig, method, assigned_snd)

		else
			async.run(function()
				--wait delayed start time then run
				if delayed_start_time > 0 then
					async.await(mn.waitAsync(delayed_start_time))
				end

				--wait animation time + buffer time then set as closed or open
				local anim_time, assigned_snd = self:Toggle_Pre(ship, shipsig, method, is_instant, disable_auto_afterburn, shipclassname)

				local wait_time = self:Get_AnimTime_Full(shipclassname, assigned_snd, anim_time)
				async.await(mn.waitAsync(wait_time))

				self:Toggle_Post(ship, shipsig, method, assigned_snd)

			end)
		end

	end

	function Sfoils:OnKeyPress()

		local player = FotG:GetPlayerShip()

		if player ~= nil and player:isValid() and player:getBreedName() == "Ship" then
			local pclass = player.Class.Name
			if pclass ~= nil and self:ShipEquipped(pclass) then
				--determine status
				self:CheckAddShip_MetaInfo(player)
				local shipsig = player:getSignature()
				local current_method = self.meta_info[shipsig].current_wings_method
				--run accordingly
				if current_method ~= 0 and not HyperspaceExit.is_player_jumping_in and not HyperspaceEnter.is_player_jumping_out then
					local new_method = current_method * -1
					if new_method ~= 0 then
						self:Toggle(player, new_method)
					end
				else
					--play fail noise if cannot, but only if it's been at least bit a since it was played
					local mtime = mn.getMissionTime()
					if mtime > self.time_of_last_fail_sound + 0.5 then
						ad.playGameSound(28)
						self.time_of_last_fail_sound = mtime
						--sound 28 is 2d fail sound
					end
				end
			end
		end

	end

	function Sfoils:SetHyperOut(ship, delay_toggle) --toggles s-foils for jumping to hyperpsace

		--validity checks
		if ba.MultiplayerMode then return end
		if ship == nil then return end 
		if not ship:isValid() then return end

		local shipclass = string.filterInvisible(ship.Class.Name)
		if not self:ShipEquipped(shipclass) then
			return
		end

		--get current wing method status
		self:CheckAddShip_MetaInfo(ship)
		local shipsig = ship:getSignature()
		local current_wing_status = self.meta_info[shipsig].current_wings_method

		--turn off afterburners regardless
		ship.Physics.AfterburnerActive = false
		ship:setFlag(true, "afterburners-locked")

		--check ship class to determine wing status to exit into hyperpsace
		--if wings are opening or closing, there's a catch all in the hyper script that should set the wings again 

		--set wing status for jumping
		--recall Toggle function will not run if wings moving, 
		--  though AI does not move wings on their own and player already was not allowed to hit jump if wings were moving
		--function also does correctly does nothing if requested mode matches current mode
		if self:Should_Close_on_Hyper(shipclass) then
			--close wings if X-wing, B-wing, etc
			self:Toggle(ship, self.method_close, false, true, delay_toggle)
		else
			--open if Lambda, Star Wing, or Zeta
			self:Toggle(ship, self.method_open, false, false, delay_toggle)
		end

	end

	function Sfoils:ShouldPreventHyperOut_Time(ship, isplayer) --returns animation time needed for s-foils to be accounted for before jumping to hyperspace (0 if non-s-foil ship or s-foils already ready to jump)

		--validity checks
		if ba.MultiplayerMode then return 0, false end
		if ship == nil then return 0, false end 
		if not ship:isValid() then return 0, false end

		local shipclass = string.filterInvisible(ship.Class.Name)
		
		--out early if ship has no s-foils
		if not self:ShipEquipped(shipclass) then
			return 0, false
		end

		--get wing status
		self:CheckAddShip_MetaInfo(ship)
		local shipsig = ship:getSignature()
		local current_wing_status = self.meta_info[shipsig].current_wings_method

		local classinfo = self.sclass_extra_info_tbl[shipclass] or {0}
		local ani_time_full = self:Get_AnimTime_Full(shipclass, true)

		--if moving then no jumping
		if current_wing_status == self.method_moving then
			return ani_time_full * 2.5, true --give time to finish then run again
		end

		--special case for player (function PlayerCheck() in see hyperspace-sct.tbm)
		if isplayer then 
			return 0, false
		end

		--if closed or open check ship class
		--recall already covered moving case above
		if self:Should_Close_on_Hyper(shipclass) then
			if current_wing_status == self.method_open then
				-- X/B/U-wings/ARCs must close to enter hyperspace
				return ani_time_full, false
			end
		else
			if current_wing_status == self.method_close then
				-- Lambda/Star Wing must open to enter hyperspace
				return ani_time_full, false
			end
		end

		-- at this point we should have covered all cases
		-- so wings are ready to go
		return 0, false

	end

	function Sfoils:ShipArrive(ship, onstart)

		--validity checks
		if ba.MultiplayerMode then return end
		if ship == nil then return end
		if not ship:isValid() then return end

		--check ship name against dummy ships
		local s_name = ship.Name
		if FotG:IsStandaloneName(s_name) then return end
		local s_class_og = ship.Class.Name
		if FotG:IsDummyClass(s_class_og) then return end

		if onstart == nil then
			onstart = true
		end

		local s_class = string.filterInvisible(s_class_og)

		--stop early if not an s-foil equipped ship
		if not self:ShipEquipped(s_class) then
			--actually the following is not needed
			--b/c if it's used then FSO log is spammed with messages about ab not being preset on ships
				--lock afterburners to ensure that AI never thinks to use them
				--this is needed b/c the AI start afterburners only checks if they are locked, not if the ship has them or not
				--most AI afterburners are pre-checked by 'maybe_fire' (which has that check) but not all
				--ship.Physics.AfterburnerActive = false
				--ship:setFlag(true, "afterburners-locked")
			return
		end

		self:CheckAddShip_MetaInfo(ship)

		--all ships arrive in mission with s-foils open because that's how the model is
		--so instantly close them
		--lambda doesn't get speed boost for having closed s-foils
		--but do not instantly close if FREDer has no-warp_in effect set
		--since this means FREDer wanted the ship to be acting like it's been flying around this whole time
		--have to look it up on parsed object though
		local parsed_ship = ship:getParsedShip()
		if parsed_ship ~= nil then
			if parsed_ship:getFlag("no-arrival-warp") then
				ship:setFlag(true, "afterburners-locked")
				return
			end
		end


		--also save if FREDer has set this specific ship to have Force Manual S-foils
		-- if this is a wing ship, then this will check the parent ship 
		local fred_set_manual_foils_per_ship = false
		if ship:getFlag("afterburners-locked") then
			fred_set_manual_foils_per_ship = true
			-- do not set to true if this is a wing ship in a wave > 1
			local s_wing = ship:getWing()
			if s_wing ~= nil and s_wing:isValid() then
				local wave_count = s_wing.CurrentWave
				if wave_count ~= nil and wave_count > 1 then
					fred_set_manual_foils_per_ship = false
				end
			end
		end

		--lock afterburners regardless to ensure that ships will not think they can use them
		--if it's a ship that gets an afterburner boost then the afterburners will get unlocked and set to on as soon as s-foils close
		ship:setFlag(true, "afterburners-locked")

		local instant_close = self:Should_Close_on_Hyper(s_class)

		--ship arrive, select -->open wings either instantly or after hyperspace done if no override
		if instant_close then

			local disable_autoafterburn = false

			--instant close at mission start
			self:Toggle(ship, self.method_close, true, disable_autoafterburn, 0)

			--run toggling as long as it is enabled
			if not mn.Events[self.disable_sfoils_event_name]:isValid() and not fred_set_manual_foils_per_ship then

				--get how long until toggle effect is run
				local waittime
				if onstart and not HyperspaceExit.is_player_jumping_in then
					--if at mission start and not jumping in
					--yes this will trigger for non-player ships too, but might be fun to see your wingmen open s-foils once you arrive
					waittime = ba.rand32(40, 200)/100
				else
					--not at start or not player wing jumping in
					waittime = ba.rand32(425, 550)/100
				end

				self:Toggle(ship, self.method_open, false, disable_autoafterburn, waittime)

			end
		end

		--2. ship arrive Lambda -->open wings instantly regardless
			-- don't allow mission wide override for ships that normally arrive from hyperspace with s-foils open
			-- lambda already open by default
			-- however do allow the FREDDer to override with locked-afterburners
			-- local close_for_hyper = self:Should_Close_on_Hyper(s_class)
		--if not close_for_hyper and not fred_set_manual_foils_per_ship then
			--self:Open(s_name, true) --true for instant open
		--end

	end

	function Sfoils:SetStartingShips()

		if ba.MultiplayerMode then return end

		--set player fail sound to play for locked weapons regardless
		local ply_ship = FotG:GetPlayerShip()
		if ply_ship ~= nil and ply_ship:isValid() and ply_ship:getBreedName() == "Ship" and not ply_ship:isDying() then
			ply_ship:setFlag(true, "fail-sound-locked-primary", "fail-sound-locked-secondary")
		end

		for ship in mn.getShipList() do
			self:ShipArrive(ship, true)
		end

	end

	function Sfoils:GetSfoilsStatus(ship)
		if ba.MultiplayerMode then return -1 end
		
		if ship ~= nil and ship:isValid() then
			if self:ShipEquipped(ship.Class.Name) then
				self:CheckAddShip_MetaInfo(ship)
				local ship_metainfo = self.meta_info[ship:getSignature()]
				if ship_metainfo ~= nil then
					if ship_metainfo.current_wings_method == self.method_open then
						return 2
					elseif ship_metainfo.current_wings_method == self.method_close then
						return 1
					else
						return 0
					end
				else
					return -1
				end
			else
				return -1
			end
		else
			return -1
		end
	end

	mn.LuaSEXPs["open-s-foils"].Action = function(...)
		
		if ba.MultiplayerMode then return end

		if #arg <= 0 then return end
		
		for _, value in ipairs(arg) do
			local ship = value[1]
			if ship ~= nil and ship:isValid() then
				if Sfoils:ShipEquipped(ship.Class.Name) then
					Sfoils:Toggle(ship, Sfoils.method_open)
				end
			end
		end

	end

	mn.LuaSEXPs["close-s-foils"].Action = function(...)
		
		if ba.MultiplayerMode then return end

		if #arg <= 0 then return end
		
		for _, value in ipairs(arg) do
			local ship = value[1]
			if ship ~= nil and ship:isValid() then
				if Sfoils:ShipEquipped(ship.Class.Name) then
					Sfoils:Toggle(ship, Sfoils.method_close)
				end
			end
		end

	end

	mn.LuaSEXPs["get-s-foils-status"].Action = function(ship)

		return Sfoils:GetSfoilsStatus(ship)

	end

--

--Hooks
if not IS_STANDALONE then 
	engine.addHook("On Gameplay Start", function() 
			Sfoils:Reset()
			Sfoils:SetStartingShips()
		end
	)

	engine.addHook("On Mission About To End", function() 
			Sfoils:Reset()
		end
	)

	engine.addHook("On Ship Arrive", function() 
			Sfoils:ShipArrive(hv.Ship, false)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	io.Keybinding["CUSTOM_CONTROL_3"]:registerHook(function()
		Sfoils:OnKeyPress() --"Toggle S-foils"
		return false
	end, true, true)

end