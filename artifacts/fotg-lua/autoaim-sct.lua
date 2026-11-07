-- This file allows one to define separate autoaim FOV values for each primary bank.
-- Also sets gradual auto aim, targeting computer mode, and other features.

-- In Multiplayer, weapons and secondary locking start out both on at the same time, and can only be changed by sexps on the server..
-- .. but it seems that locally setting it on the client works for the client ship/prevents them from locally firing/sending fire packets..
-- .. so it kind of works out okay?


AutoAim = {

	occluder_color = {165, 103, 23, 50},  --half transparent dark tan color
	base_gauge_id_center = 9,
	base_gauge_id_lead = 0,
	default_fvec = 1500,
	lead_intensity = 127,
		--apparently user cannot change values of the lead indicator
		--base color on center reticle seems to always be > 127

	--lock_time_p_diff is percent difference from default lock time, and default lock time depends on difficulty
	--static_mode_boost_p_diff is value multiplied to default static mode boost value
	--recall difficulty cannot be changed during the mission

	weapon_override = {
		["Gyrhil 72"] = {bank_fov = {7.5}, lock_time_pdiff = {0.30}, static_mode_boost_pdiff = {0.8}, match_sclass="ASF-01 B-wing"},
		["T&B KT6#Olv"] = {bank_fov = {6.2}, lock_time_pdiff = {0.65}, static_mode_boost_pdiff = {1.05}},
		["T&B KT6#Yel"] = {bank_fov = {6.2}, lock_time_pdiff = {0.65}, static_mode_boost_pdiff = {1.05}},
		["T&B KT6#Orn"] = {bank_fov = {6.2}, lock_time_pdiff = {0.65}, static_mode_boost_pdiff = {1.05}}
	},

	ship_tbl = {
		["T-65c X-wing"] =                 {bank_fov={5.0},           lock_time_pdiff={1.0},             static_mode_boost_pdiff={1.05}}, --bank 0
		["ASF-01 B-wing"] =                {bank_fov={5.0, 4.0, 2.5}, lock_time_pdiff={1.0, 1.0, 0.85},  static_mode_boost_pdiff={0.93, 0.80, 1.2}}, --wing tips, chin, turbo
		["RZ-1 A-wing"] =                  {bank_fov={5.75},          lock_time_pdiff={0.80}},
		["BTL-LP Longprobe"] =             {bank_fov={5.0},           lock_time_pdiff={1.0}},
		["E-7 E-wing"] =                   {bank_fov={5.5, 3.0},      lock_time_pdiff={1.0, 0.25}},
		["T.I.E. Fighter"] =               {bank_fov={5.0},           lock_time_pdiff={1.0}},
		["TIE/ln Fighter"] =               {bank_fov={5.5},           lock_time_pdiff={0.85}},
		["TIE/rc Fighter"] =               {bank_fov={5.5},           lock_time_pdiff={1.0}},
		["TIE Advanced X1"] =              {bank_fov={5.0},           lock_time_pdiff={0.85}},
		["TIE/In Interceptor"] =           {bank_fov={5.0},           lock_time_pdiff={0.90}},
		["TIE/In Interceptor Mk.2"] =      {bank_fov={5.0, 5.5},      lock_time_pdiff={1.0, 0.85}}, --wingtips first, then cockpit
		["TIE/sa Bomber"] =                {bank_fov={4.5},           lock_time_pdiff={1.0}},
		["TIE/sh Shuttle"] =               {bank_fov={3.5},           lock_time_pdiff={1.0}},
		["V38 Assault Fighter"] =          {bank_fov={5.0},           lock_time_pdiff={1.0}},
		["Z-95 Headhunter"] =              {bank_fov={5.5},           lock_time_pdiff={0.85}},
		["BTL-A4 Y-wing"] =                {bank_fov={4.3, 5.5},      lock_time_pdiff={1.0, 0.85}}, --lasers, ions
		["Cloakshape Fighter"] =           {bank_fov={5.5},           lock_time_pdiff={0.85},             static_mode_boost_pdiff={1.2}},
		["N-1 Starfighter"] =              {bank_fov={5.0},           lock_time_pdiff={0.85}},
		["ZY-wing"] =                      {bank_fov={5.0},           lock_time_pdiff={0.80},             static_mode_boost_pdiff={1.2}}, --Pirate Interceptor
		["TYE-wing"] =                     {bank_fov={4.5},           lock_time_pdiff={1.00},             static_mode_boost_pdiff={1.1}}, --DIE Wing (Recon)
		["TYE-Vulture"] =                  {bank_fov={5.5},           lock_time_pdiff={0.80},             static_mode_boost_pdiff={1.1}}, --Pirate Heavy Fighter
		["ZTI-wing"] =                     {bank_fov={5.5},           lock_time_pdiff={1.0},              static_mode_boost_pdiff={1.1}}, --Pirate Interceptor/Fighter
		["T-Blade Bomber"] =               {bank_fov={5.3, 4.2, 2.5}, lock_time_pdiff={1.0, 1.0, 0.80},   static_mode_boost_pdiff={1.2, 0.9, 1.15}}, --wing tip, chin, turbo
		["A-3 V-wing Starfighter"] =       {bank_fov={5.6, 5.6},      lock_time_pdiff={0.85, 0.85},       static_mode_boost_pdiff={1.1, 1.1}},      --lasers then ions
		["ARC-170 Starfighter"] =          {bank_fov={5.0, 5.0},      lock_time_pdiff={1.0, 1.0},         static_mode_boost_pdiff={1.2, 1.1}}, --lasers, ions
		["Vulture Droid Starfighter "] =   {bank_fov={4.0},           lock_time_pdiff={1.0}},
		["UT-60D U-wing"] =                {bank_fov={5.0},           lock_time_pdiff={1.0}},
		["Modified YT-1300 Freighter"] =   {bank_fov={6.5},           lock_time_pdiff={0.75},             static_mode_boost_pdiff={1.2}},
		--no yt1300 b/c it only has turrets
		["XG-1 Star Wing"] =               {bank_fov={5.2, 5.6},      lock_time_pdiff={0.95, 0.75},       static_mode_boost_pdiff={1.1}},
		["Lambda T-4a Shuttle"] =          {bank_fov={5.5, 5.5},      lock_time_pdiff={0.75, 0.75}},
		["DX-9 Stormtrooper Transport"] =  {bank_fov={5.0},           lock_time_pdiff={1.0}},
		["Zeta Hvy Cargo Shuttle"] =       {bank_fov={5.5, 5.5},      lock_time_pdiff={0.75, 0.75}},
		["Modified Firespray Gunship"] =   {bank_fov={6.0, 6.0},      lock_time_pdiff={0.70, 0.70},       static_mode_boost_pdiff={1.15, 1.15}},
		["Firespray Gunship"] =            {bank_fov={6.0, 6.0},      lock_time_pdiff={0.70, 0.70}},
		["Skipray Blastboat"] =            {bank_fov={5.5, 5.5},      lock_time_pdiff={0.75, 0.75}},
		["Star Speeder 3000"] =            {bank_fov={4.0},           lock_time_pdiff={1.0}}
	},

	ships_tbl_min = 20, --from ships.tbl +Minimum Distance:

	default_aim = 5.0,
	default_static_mode_boost = 1.85, --if it exists, static_mode_boost_p_diff is also multiplied by this default number to increase or decrease it
	default_lock_time = {2.0, 2.2, 2.4, 2.6, 2.8},	

	ai_min_autoaim_fov_deg = 1.0, --degrees, AI needs it to be at least a little so autoconvergence occurs

	ply_min_fov_deg = 0.5,
	ply_loss_rate_multiplier = 0.50, --this value * lock rate is how fast lock is lost, 
		--idea is that once you get a lock it's there 
		--(harder to get lock then keep it, player should be rewarded for getting it)
	diff_multiplier = {1.2, 1.1, 1.0, 0.95, 0.90}, --for auto aim size
	ply_growable_fov_multi_base = 2.0, 
	--this value * "current player Autoaim" is how where the aim has to be within to increase the fov for gradual aim (or outside to decrease)
		--if auto aim fov is 5, then the auto aim circle will start growing if within 5 * this value degrees
		--this value is clamped within the range of the following values * weapon fov
	ply_growable_fov_multi_max = 3.5, --this value * weapon fov = the max growable area
	ply_growable_fov_multi_min = 1.1, --this value * weapon fov = the min growable area
	do_angle_factor = true, --only triggers if gradual auto aim is enabled
	angle_bleed_max = 0.86, --max bleed percent
	angle_bleed_ref = 0.42, --rad/s crossing where the penalty saturates (lower number reaches penalty faster)

	-- if using gradual lock on time then limit autoaim range if targeting a small ship (set by radius)
	--   more movie accurate for folks who want that option
	--   weapon range is X% of original range for locking onto a small ship (but also has hard minimum) 
	-- keep the longer range for cap ships, and with AI since AI needs to be able to do strafing runs on cap ships
	-- also AI can't hit fighters from far away well anyway
	ply_small_target_range_percent = 0.55,
	ply_small_target_min_add = 250,
	ply_small_target_radius = 40,

	ply_subsys_t_radius = 5,
	ply_subsy_t_dist_multi = 0.75,
	ply_subsy_t_fov_multi = 0.75,

	use_plock_time = false, --initialize value, but will be read from file as soon as game starts

	gauge_name_secondary = "Targeting_Comp",
	gauge_name_stationary = "Fire_Stationary"
}

AutoAim.button_info = {
	uibt_unique_key = "AutoAim_Gradual_Lock",
	uibt_default_val = false,
	uibt_title_str = ba.XSTR("Gradual Primary Aim Lock", 5), --custom_ui_5
	uibt_tool_tip = ba.XSTR("When On, primary aim assist gradually locks.\nWhen Off, primary aim assist locks instantly.\nSingleplayer only, value is always Off in multiplayer.", 6), --custom_ui_6

	uibt_choices_list = {{choice_i = 1, choice_str = ba.XSTR("Off", 0)}, {choice_i = 2, choice_str = ba.XSTR("On", 1)}},
	uibt_ui_type = FotG.UI_BT_List.TYPE_BinaryButton,

	uibt_origin_x = 0.5,
	uibt_origin_y = 1.0,
	uibt_offset_x = 70,
	uibt_offset_y = -170,

	uibt_gamestate = "GS_STATE_OPTIONS_MENU",

	uibt_multi_allowed = false,

	uibt_options_tab = FotG.OTab_ID_Main,

	uibt_get_function = function()
		return AutoAim.use_plock_time
	end,

	uibt_set_function = function(new_value)
		AutoAim.use_plock_time = new_value
	end

}

--Code

	function AutoAim:Set_FOV(ship, on_primary_wep_switch) --never multi, only for player ATM

		--doesn't work in multi, b/c ship.var = new_var doesn't work in multi, but some sexps do
		if self.is_multiplayer then return end

		if CapShipControl:IsEnabled() then return end

		if ship == nil then ship = FotG:GetPlayerShip() end

		--validity checks
		if ship == nil then return end
		if not ship:isValid() then return end
		if ship:getBreedName() ~= "Ship" then return end

		--only set if player
		if not ship:isPlayer() then return end

		--get previous auto aim before setting new value
		local prev_aa_max_rad = self.ply_primary_wep_fov_rad
		local prev_aa_current_rad = math.rad(ship.AutoaimFOV)

		local full_classname = ship.Class.Name

        local classname = string.filterInvisible(full_classname)

		--find auto aim values for ship class
		local ship_aa = self.ship_tbl[classname]

		--find which bank we are in
		local active_i = 1
		local fix_bank

		if ship_aa ~= nil then
			--get bank only if it is selected 
			local bank_info = ship_aa.bank_fov
			if bank_info ~= nil then
				for i_bank, _ in ipairs(bank_info) do
					--set bank 
					if ship.PrimaryBanks[i_bank].Armed then
						fix_bank = i_bank
					end
				end

				--if we are running when primary weapon switched
				--have to do some sneaky math to get actual next bank 
				local num_banks = #bank_info
				if on_primary_wep_switch and num_banks > 1 and fix_bank ~= nil then
					if num_banks == 2 then
						if fix_bank == 1 then
							active_i = 2
						elseif fix_bank == 2 then
							active_i = 1
						end
					elseif num_banks == 3 then
						if fix_bank == 1 then
							active_i = 2
						elseif fix_bank == 2 then
							active_i = 3
						elseif fix_bank == 3 then
							active_i = 1
						end
					end
				end

			end

		end

		local autoaim_meta

		--save this weapon class values for use in On Frame hook
		local weaponclass = ship.PrimaryBanks[active_i].WeaponClass

		--check if weapon has override for values
		local weapon_aa = self.weapon_override[weaponclass.Name]
		if weapon_aa ~= nil then
			if weapon_aa.match_sclass == nil or weapon_aa.match_sclass == classname then
				active_i = 1
				autoaim_meta = weapon_aa
			end
		end

		--if no weapon override just use ship values
		if autoaim_meta == nil then
			autoaim_meta = ship_aa
		end

		self.ply_current_weapon_speed = math.max(weaponclass.Speed, 1)
		self.ply_current_weapon_lifetime = weaponclass.LifeMax
		self.ply_current_weapon_range = weaponclass.Range

		--options for stationary target mode
			--primary on and secondary on -> og weapon regeneration
			--primary on and secondary off -> og weapon regeneration
			--primary off and secondary on -> og weapon regeneration
			--primary off and secondary off -> higher weapon regeneration

		if not self.PrimaryAutoAimOn and not self.SecondaryAutoAimOn then
			--see if class/bank gets a boost
			local multiplier = self.default_static_mode_boost
			if autoaim_meta ~= nil then
				local static_boost_pdif = autoaim_meta.static_mode_boost_pdiff
				if static_boost_pdif ~= nil and static_boost_pdif[active_i] ~= nil then
					multiplier = multiplier * static_boost_pdif[active_i]
				end
			end

			ship.WeaponRegenRate = self.player_og_weapon_recharge * multiplier
		else
			ship.WeaponRegenRate = self.player_og_weapon_recharge
		end

		--force to 0 if off
		if not self.PrimaryAutoAimOn then 
			ship.AutoaimFOV = 0.0
			self.last_fov_check = mn.getMissionTime()
			return
		end

		--only set if ship has no-secondary-lock-on flag
		--recall no-secondary-lock-on == true disables target acquisition for secondaries of all types (does not affect turrets)
		if not ship:getFlag("no-secondary-lock-on") then 
			return 
		end

		local newfov
		local lock_time

		--scale by difficulty
		local diff_i = MissionHelper:GetGameDifficulty()

		--set bank fov and lock time if specified in table
		if autoaim_meta ~= nil then
			--bank fov
			local bank_info = autoaim_meta.bank_fov
			if bank_info ~= nil then
				newfov = bank_info[active_i]
			end
			--lock info
			local lock_info = autoaim_meta.lock_time_pdiff
			if lock_info ~= nil then
				lock_time = lock_info[active_i] * self.default_lock_time[diff_i]
			end
		end

		--set lock time if we are just using default value
		if lock_time == nil then 
			lock_time = self.default_lock_time[diff_i]
		end
		self.ply_lock_time = lock_time

		--final check, set to default if nil
		if newfov == nil then 
			newfov = self.default_aim
		end

		local fov_scale = self.diff_multiplier[diff_i]

		--set auto aim 
		local scaled_fov = newfov * fov_scale
		self.ply_primary_wep_fov_rad = math.rad(scaled_fov)

		self.ply_lock_rate = math.rad(scaled_fov)/lock_time
		self.ply_loss_rate = self.ply_lock_rate * self.ply_loss_rate_multiplier * -1

		--to account for quick switches between modes we need to actually set the ship's auto aim to the min so it can lock back on
		--recall this whole function is only running if in single-player (see early multi return at top of function)
		local percent_gradual_helper = 1
		if self.use_plock_time and prev_aa_max_rad > 0 then
			percent_gradual_helper = prev_aa_current_rad / prev_aa_max_rad
		end

		ship.AutoaimFOV = scaled_fov * percent_gradual_helper

		self.last_fov_check = mn.getMissionTime() or 0

	end

	function AutoAim:Use_Primary_Mode(ship) --maybe multi

		--if self.is_multiplayer then return end

        if ship ~= nil and ship:isValid() and ship:getBreedName() == "Ship" then

			local sname = ship.Name
			if FotG:IsStandaloneName(sname) then return end

			--unlock primaries if in multi since they might have been locked 
			--when secondary weapons toggled
			if self.is_multiplayer then
				ship:setFlag(false, "primaries-locked")
			end

			self.PrimaryAutoAimOn = true
			self.SecondaryAutoAimOn = false
			ship:setFlag(true, "no-secondary-lock-on")
			self:Set_FOV(ship)

		end

	end

	function AutoAim:Use_Secondary_Mode(ship) --maybe multi

		--if self.is_multiplayer then return end

        if ship ~= nil and ship:isValid() and ship:getBreedName() == "Ship" then

			local sname = ship.Name
			if FotG:IsStandaloneName(sname) then return end

			--in theory we should lock primaries if in multi since we can't change auto aim in multi
			--this is because auto aim will still work with secondaries on so folks would just leave secondaries on
			--but locking primaries is only possible if client sexps can register on server, and they cannot
			--but this is just for the player, so it seems fine
				--old: for now multi players get auto aim and secondary locking at the same time
			if self.is_multiplayer then
				ship:setFlag(true, "primaries-locked")
			end

			self.PrimaryAutoAimOn = false
			self.SecondaryAutoAimOn = true
			ship:setFlag(false, "no-secondary-lock-on")
			self:Set_FOV(ship)
			--set effect if player using DrawSecondary()
		end

	end

	function AutoAim:SwitchMode(ship) ----maybe multi, only used for the player atm

		--if self.is_multiplayer then return end

		if ship ~= nil and ship:isValid() and ship:getBreedName() == "Ship" then

			if FotG:IsStandaloneName(ship.Name) then return end

			if ship:getFlag("no-secondary-lock-on") then
				--if targeting computer mode was off then turn it on
				self:Use_Secondary_Mode(ship)
			else
				--if targeting computer mode was on then turn it off
				self:Use_Primary_Mode(ship)
			end

			self:CheckUpdateGauges()

			--run bomber check
			BombHelper:ViewToggle()

		end

	end

	function AutoAim:SetRendering(bool_status)

		self.rendering_is_enabled = bool_status

	end

	function AutoAim:Reset(on_mission_start) --yes multi

		--if self.is_multiplayer then return end

		self.cached_screen_width = gr.getScreenWidth()
		self.cached_screen_height = gr.getScreenHeight()
		self.cached_forward_vec = ba.createVector(0, 0, self.default_fvec)

		self.is_during_mission = on_mission_start

		--Observer mode is different, so needs to be accounted for
		--ensure that nothing gets set for observers, which ensures On Frame checks do not trigger
		local player = FotG:GetPlayerShip()
		if player ~= nil and player:isValid() and player:getBreedName() == "Ship" then
			self.PrimaryAutoAimOn = true
		else
			self.PrimaryAutoAimOn = false
		end

		if ba.MultiplayerMode then
			self.is_multiplayer = true
		else
			self.is_multiplayer = false
		end

		self.SecondaryAutoAimOn = false
		self.last_fov_check = 0.0
		self.played_lock_sound = false
		self.played_unlock_sound = false
		self.player_og_weapon_recharge = nil
		self.previous_target_sig = nil

		--ply values change depending on ship and difficulty and other things
		--do changes in Set_FOV
		self.ply_lock_time = 0.0
		self.ply_lock_rate = 0.0
		self.ply_loss_rate = 0.0
		self.ply_primary_wep_fov_rad = math.rad(self.ply_min_fov_deg) --ensure not 0 since this is a denominator

		self.played_lock_sound = false
		self.played_unlock_sound = false
		self.ply_current_weapon_speed = 1500
		self.ply_current_weapon_lifetime = 2.0
		self.ply_current_weapon_range = 2000

		if not self.is_multiplayer then --causes standalone crash in multi if it tries to look up weapon regeneration rate
			if on_mission_start then
				local ply = FotG:GetPlayerShip()
				if ply ~= nil and ply:isValid() and ply:getBreedName() == "Ship" then
					self.player_og_weapon_recharge = ply.WeaponRegenRate or 0
				else
					self.player_og_weapon_recharge = 0
				end
			else
				self.player_og_weapon_recharge = 0
			end
		end
		--gr.setPostEffect("tint", 0)

		self:SetRendering(true)

		--using a drawn rectangle instead to save on memory and texture usage

	end

	function AutoAim:MissionSetup(run_ship_clear) --yes multi, for part 

		--if self.is_multiplayer then return end

		self:Reset(true)

		self:CheckUpdateGauges()

		local ply = FotG:GetPlayerShip()
		self:Use_Primary_Mode(ply)
		self:Set_FOV(ply)

		if run_ship_clear then
			if not self.is_multiplayer then
				for ship in mn.getShipList() do
					self:ClearAI(ship)
				end
			end
		end

	end

	function AutoAim:Helper_BomberViewOn()

		return BombHelper and BombHelper.bomb_camera_on

	end

	function AutoAim:TogglePrimaryAssist() --never multi

		if self.is_multiplayer then return end --FOV and extra primary juice won't actually change on server

		local player = FotG:GetPlayerShip()

		-- will not toggle if in bomber view
		if player ~= nil and player:isValid() and player:getBreedName() == "Ship" and not self:Helper_BomberViewOn() and not CapShipControl:IsEnabled() then

			local og_auto_aim_was_on = self.PrimaryAutoAimOn --need to save value since use primary function sets it 
			local new_auto_aim_is_on

			--if targeting computer mode on turn it off
			if self.SecondaryAutoAimOn then
				self:Use_Primary_Mode(player) --internally resets FoV, but fine to do it twice
				--primary auto aim is now on, but it needs to be off
				new_auto_aim_is_on = false
			else
				new_auto_aim_is_on = not og_auto_aim_was_on
			end

			--update ship autoaim and toggle the boolean
			self.PrimaryAutoAimOn = new_auto_aim_is_on
			self:Set_FOV(player)

			--play sound
			ad.playGameSound(8)

			self:CheckUpdateGauges()

		end

	end

	function AutoAim:Toggle_T_Computer() --maybe multi, is for the key press control for toggling targeting computer

		--if self.is_multiplayer then return end

		local player = FotG:GetPlayerShip()

		--recall "Observer" is also a breed type
		if player ~= nil and player:isValid() and player:getBreedName() == "Ship" and not CapShipControl:IsEnabled() then

			--only turn on targeting computer if ship has secondaries
			local p_secondaries = player.SecondaryBanks
			if p_secondaries ~= nil and p_secondaries:isValid() and #p_secondaries >= 1 then

				--switch mode
				self:SwitchMode(player)

				ad.playGameSound(29)

			--else --odd that sound would play since it's not really an error
				--ad.playGameSound(28) --fail sound
			end
		end	

	end

	function AutoAim:InCircle(set_FOV, tx, ty, cx, cy, player, d) --yes multi, fov in radians; returns distance (0-1), in_fov (bool), and radius in PIXELS

		--reference scale (half the smaller screen dimension) for the out-of-fov falloff range
		local c_z
		if cx < cy then
			c_z = cx
		else
			c_z = cy
		end

		--radius: project a point on the cone edge and measure it on screen.
		--exact regardless of zoom/aspect/TrackIR, unlike an angle->pixel formula.
		--NOTE: assumes (cx,cy) was projected from (0,0,default_fvec). If cached_forward_vec
		--      uses a different length, set d to that length so center and edge match.
		d = d or self.default_fvec
		local edge_pt = ba.createVector(0, math.sin(set_FOV) * d, math.cos(set_FOV) * d)
		local ex, ey = player:findWorldPoint(edge_pt):getScreenCoords()
		local radius
		if ex and ey then
			local rdx = ex - cx
			local rdy = ey - cy
			radius = math.sqrt(rdx*rdx + rdy*rdy)
		else
			--fallback if the cone edge is off-screen
			local camera_fov = gr.getCurrentCamera(true).FOV
			local half_fov = camera_fov * 1.39626348 * 0.5  -- engine zoom -> projected half-FOV
			radius = math.tan(set_FOV) / math.tan(half_fov) * c_z
		end

		--radius = radius * 0.86 --magic number to help ensure drawn circle is just smidge smaller? nah

		local dx = tx - cx
		local dy = ty - cy
		local d_linear = math.sqrt(dx*dx + dy*dy)
		local distance = 1 - math.min(math.max(d_linear - radius, 0), c_z / 2) / (c_z / 2)
		local infov

		if distance >= 1 then
			--in fov
			infov = true
			distance = 1
		else
			--out of fov
			infov = false
		end

		return {distance = distance, infov = infov, radius = radius}

	end

	function AutoAim:DrawPrimary(player, draw) --yes multi, recall observer check already ran in On Frame function

		--early outs
		--if self.is_multiplayer then return end
		if not self.PrimaryAutoAimOn then return end
		if self.SecondaryAutoAimOn then return end

		--variable setup
		local is_multiplayer = self.is_multiplayer

		local target = player.Target
		local target_valid = false
		if target ~= nil and target:isValid() then
			target_valid = true
		end
		local targetsubsys = player.TargetSubsystem
		local target_dist_multi = 1
		local target_fov_multi = 1

		--get target variables
		local targetpos, target_radius
		if targetsubsys ~= nil and targetsubsys:isValid() then
			targetpos = targetsubsys.WorldPosition 
			target_radius = targetsubsys.Radius
			if not is_multiplayer and targetsubsys.Radius <= self.ply_subsys_t_radius then
				target_dist_multi = self.ply_subsy_t_dist_multi
				target_fov_multi = self.ply_subsy_t_fov_multi
			end
			--it's okay to have gradual aim not account for subsystems on same ship that are right next to each other?
			--save distance to target or make radius size affect auto-aim circle (ie <=5 meter radius and circle is smaller)
			--the growable in FoV will check, and if the subsystems are very far apart then the gradual FoV changes will kick in
		else
			if target_valid then
				targetpos = target.Position
				target_radius = target.Radius
			end
		end

		local sound_type = 2
		local plock_active = (not is_multiplayer and self.use_plock_time)

		--actually calculate target and update/draw autoaim
		if target_valid and player.PrimaryBanks ~= nil and player.PrimaryBanks:isValid() then

			local ply_physics = player.Physics
			-- match engine hud_calculate_lead_pos: the projectile travels at the weapon's max speed.
			-- additive weapon velocity (100% inherit) is captured by the relative velocity (target_velocity - ply_velocity)
			-- used below, so do not add the ship's forward speed here (as that would double-count it)
			local weapon_speed = self.ply_current_weapon_speed
			local ply_pos = player.Position
			local dist_to_target = ply_pos:getDistance(targetpos)
			local time_to_target = dist_to_target / weapon_speed
			local target_physics = target.Physics
			local target_velocity = target_physics.Velocity
			-- engine scales by the target's total speed magnitude (phys_info.speed), not its forward component
			local target_moved_dist = target_velocity:getMagnitude() * time_to_target

			local ply_velocity = ply_physics.Velocity
			local target_moving_dir_og = target_velocity - ply_velocity
			local target_moving_dir_helper

			if target_moving_dir_og:getMagnitude() > 0.01 then
				target_moving_dir_helper = target_moving_dir_og:getNormalized()
			else
				target_moving_dir_helper = target_moving_dir_og
			end

			-- two-step intercept = engine's first-pass lead + one polish_predicted_target_pos step
			local leadpos = targetpos + (target_moving_dir_og) * (ply_pos:getDistance(targetpos + (target_moving_dir_helper * target_moved_dist)) / weapon_speed)

			local weapon_range = self.ply_current_weapon_range * target_dist_multi

			if plock_active then
				if target.Radius <= self.ply_small_target_radius then
					weapon_range = (weapon_range * self.ply_small_target_range_percent) + self.ply_small_target_min_add
				end
			end

			local inrange
			if dist_to_target < weapon_range and dist_to_target > self.ships_tbl_min then
				inrange = true 
			else 
				inrange = false
			end

			--get auto aim FoV to set depending on multi or single player
			local auto_aim_fov

			if is_multiplayer then 
				--multiplayer, cannot use lock time
				auto_aim_fov = math.rad(player.AutoaimFOV)
			else
				--single player, can use lock time
				local player_current_autoaim_fov_rad = math.rad(player.AutoaimFOV)

				local weapon_fov_rad = self.ply_primary_wep_fov_rad --in radians

				if plock_active then
					--gradual auto aim

					--if time elapsed then update again
					local mtime = mn.getMissionTime()
					local time_diff = mtime - self.last_fov_check
					local new_fov = player_current_autoaim_fov_rad
					if time_diff > 0 then

						--if ship within fov then up auto aim linearly according to lock time
						--recall this is within a check for ensuring it only happens when primary aim is on 
						
						--idea is that it is harder to get a lock then to keep it, b/c it's more movie-like
						--  and players should be rewarded for their hard work of getting locks,
						--if fov is bigger that means player has a lock and should be able to keep it for longer

						local growable_fov = player_current_autoaim_fov_rad * self.ply_growable_fov_multi_base --in radians

						local max_growable_fov = self.ply_growable_fov_multi_max * weapon_fov_rad
						local min_growable_fov = self.ply_growable_fov_multi_min * weapon_fov_rad

						if growable_fov > max_growable_fov then
							growable_fov = max_growable_fov
						end
						if growable_fov < min_growable_fov then
							growable_fov = min_growable_fov
						end

						--see if in larger growable FoV (uses same method as IsFacing_Point)
						local position_diff = leadpos - ply_pos
						local norm_diff = position_diff:getNormalized()
						local ship_fvec_norm = player:getfvec(true)
						local angle_1 = ship_fvec_norm:getDotProduct(norm_diff)

						-- widen the growable FoV by distance to target and target radius
						-- this helps targets that are close grow FoV at a reasonable rate
						local target_angular_radius = math.atan(target_radius / dist_to_target)
						local angle_2 = math.cos(growable_fov * target_fov_multi + target_angular_radius)

						local in_growable_fov = (angle_1 >= angle_2)
						local update_val
						if in_growable_fov and inrange then
							update_val = self.ply_lock_rate --rate of lock or unlock per time in radians/sec
						else
							update_val = self.ply_loss_rate
						end

						self.last_fov_check = mtime
						local target_sig = target:getSignature()
						if target_sig ~= self.previous_target_sig then
							--different target so reset FoV
							new_fov = 0
							self.previous_target_sig = target_sig
						else
							--same target so update FoV
							if self.do_angle_factor then
								-- bleed in proportion to the line-of-sight rate: how fast the target's
								-- bearing sweeps across our view (rad/s) = real tracking difficulty,
								-- independent of where either ship is pointed.
								local bleed = 0
								local to_tgt = targetpos - ply_pos
								local range  = to_tgt:getMagnitude()
								if range > 0.01 then
									local los    = to_tgt * (1 / range)
									local v_perp = (target_moving_dir_og - los * target_moving_dir_og:getDotProduct(los)):getMagnitude()
									local floor  = self.ply_current_weapon_range * 0.3
									local los_rate = v_perp / math.max(range, floor)
									-- ramp 0 -> bleed_max as the crossing rate climbs to the reference rate
									local max_bleed = self.angle_bleed_max --max penalty 
									local los_ref = self.angle_bleed_ref --rad/s crossing where the penalty saturates (lower number reaches penalty faster)
									bleed = max_bleed * math.min(los_rate / los_ref, 1)
								end
								--print(" bleed difference" ..math.deg(new_fov + (update_val * time_diff)) - (new_fov + ((update_val - new_fov * bleed) * time_diff)).."\n")
								new_fov = new_fov + ((update_val - new_fov * bleed) * time_diff)
							else
								new_fov = new_fov + (update_val * time_diff)
							end
						end
					end

					--get updated fov and clamp
					--we don't clamp at 0 because then locks take too long
					--recall this in radians so 1 degree = 0.1745
					local min_fov = math.rad(self.ply_min_fov_deg)
					if new_fov < min_fov then 
						new_fov = min_fov 
					end
					--ensure actual auto aim fov should not exceed that of weapon
					if new_fov > weapon_fov_rad then
						new_fov = weapon_fov_rad 
					end

					--set auto aim fov
					auto_aim_fov = new_fov

				else
					--instant auto aim

					--set auto aim fov
					auto_aim_fov = weapon_fov_rad

				end

				--double check to make sure we restore auto-aim values
				--but we do not have to do this every frame if same
				if auto_aim_fov ~= player_current_autoaim_fov_rad then
					player.AutoaimFOV = math.deg(auto_aim_fov)
				end

			end

			if inrange then

				local tx, ty = leadpos:getScreenCoords() --if offscreen tx is false and ty is nil
				if tx ~= nil and ty ~= nil then
					local fvec = self.cached_forward_vec or ba.createVector(0, 0, self.default_fvec)
					local player_fvec = player:findWorldPoint(fvec)
					local cx, cy = player_fvec:getScreenCoords() --if offscreen cx is false and cy is nil

					if cx ~= nil and cy ~= nil then
						local fov_info = self:InCircle(auto_aim_fov, tx, ty, cx, cy, player)
						local screen_width = self.cached_screen_width or gr.getScreenWidth()
						local r, g, b = target:getIFFColor()

						-- lock state uses the engine's exact autoaim test (in_autoaim_fov): the angle
						-- between the ship's forward vector and the to-lead vector must be <= auto_aim_fov,
						-- also uses ship orientation (not the camera), so it's correct under TrackIR/cockpit/padlock
						local to_lead = (leadpos - ply_pos):getNormalized()
						local infov = (player:getfvec(true):getDotProduct(to_lead) >= math.cos(auto_aim_fov))

						if infov then 
							--in fov

							--play lock sound and set
							sound_type = 1

							--draw
							if self.base_gauge_lead_on and draw then
								gr.setColor(r, g, b, self.lead_intensity)
								FotG:SetLineWidth(2, screen_width)

								local fix = 20 - math.min(50, math.max(10, fov_info.radius)) / 50 * 20

								gr.drawArc(fov_info.radius, tx, ty, 12 + fix, 78 - fix, false)
								gr.drawArc(fov_info.radius, tx, ty, 102 + fix, 168 - fix, false)
								gr.drawArc(fov_info.radius, tx, ty, 192 + fix, 258 - fix, false)
								gr.drawArc(fov_info.radius, tx, ty, 282 + fix, 348 - fix, false)

								gr.drawArc(30, tx + fov_info.radius - 15, ty, -12, 12, true)
								gr.drawArc(30, tx, ty + fov_info.radius - 15, 78, 102, true)
								gr.drawArc(30, tx - fov_info.radius + 15, ty, 168, 192, true)
								gr.drawArc(30, tx, ty - fov_info.radius + 15, 258, 282, true)

								--reset line width
								--draw lead sight
								--gr.drawCircle(fov_info.radius, dx, dy, false)
								--FotG:ResetLineWidth()
							end
						else
							--out of fov

							--draw
							if self.base_gauge_lead_on and draw then
								local line_alpha = 127 * fov_info.distance
								if line_alpha > 0.1 then
									if plock_active then
										--also draw circle to show auto aim grow if using gradual auto aim
										FotG:SetLineWidth(1, screen_width)
										gr.setColor(r, g, b, line_alpha*0.6)
										gr.drawCircle(fov_info.radius, tx, ty, false)
									end
									gr.setColor(r, g, b, line_alpha)
									FotG:SetLineWidth(2, screen_width)
									local fov_d = 180 * fov_info.distance
									local angle = math.deg(math.atan2(ty - cy, tx - cx))
									gr.drawArc(fov_info.radius, tx, ty, angle - fov_d, angle + fov_d, false)
									--FotG:ResetLineWidth()
								end
							end
						end
					end
				end
			end

		else
			--if no target reset auto-aim if single-player and using gradual lock
			if not is_multiplayer and plock_active then
				if player.AutoaimFOV ~= self.ply_min_fov_deg then
					player.AutoaimFOV = self.ply_min_fov_deg
				end
			end

		end

		--check/play lock or unlock sounds

		if sound_type == 1 then
			--lock
			if not self.played_lock_sound then
				ad.playGameSound(136)
				self.played_lock_sound = true
				self.played_unlock_sound = false
			end
		elseif sound_type == 2 then
			--unlock
			if not self.played_unlock_sound then
				ad.playGameSound(137)
				self.played_lock_sound = false
				self.played_unlock_sound = true
			end			
		end


	end

	function AutoAim:DrawSecondary(draw) --yes multi, recall observer check already ran in On Frame function

		--if self.is_multiplayer then return end

		--draw occluder, the gauge has already been toggled on
		if draw and self.SecondaryAutoAimOn then
			local occ = self.occluder_color
			gr.setColor(occ[1], occ[2], occ[3], occ[4])
			gr.drawRectangle(0, 0, gr.getScreenWidth(), gr.getScreenHeight(), true)
		end

	end

	function AutoAim:OnFrame() --yes multi, recall run observer check here

		if not MTIME_OVER_P1 then 
			return 
		end

		local player = FotG:GetPlayerShip()
		if player == nil then return end
		if not player:isValid() then return end

		--failsafe check for observer in multiplayer
		if self.is_multiplayer and player:getBreedName() ~= "Ship" then 
			return
		end

		local draw = false
		if self.rendering_is_enabled and hu.HUDDrawn and not hu.HUDDisabledExceptMessages then
			draw = true
		end

		if not HyperspaceExit.is_player_jumping_in and not HyperspaceEnter.is_player_jumping_out and not gr.hasViewmode(VM_OTHER_SHIP) then

			--secondary just draws rectangle so can draw in more cases
			if gr.hasViewmode(VM_INTERNAL) or self:Helper_BomberViewOn() then
				self:DrawSecondary(draw)
			end

			--only draw circle aimer if looking forward
			--recall track messes up the auto aim screen coordinates
			if (gr.hasViewmode(VM_INTERNAL) or gr.hasViewmode(VM_CHASE)) and gr.hasViewmode(VM_CAMERA_LOCKED) then
				self:DrawPrimary(player, draw)
			end

		end

	end


	function AutoAim:ClearAI(ship) --never multi

		--ensure AI doesn't use auto aim
		--also recall GCW already takes care of this since it allows survived wingmen to use auto aim
		if not self.is_multiplayer and ship ~= nil and ship:isValid() and not ship:isPlayer() then
			if GCW ~= nil and not GCW.isactive then
				ship.AutoaimFOV = self.ai_min_autoaim_fov_deg
			end
		end

	end

	function AutoAim:CheckBaseGauge()

		if self.is_during_mission then
			if hu.getHUDConfigShowStatus(self.base_gauge_id_center) then
				self.base_gauge_center_on = true
			else
				self.base_gauge_center_on = false
			end
			if hu.getHUDConfigShowStatus(self.base_gauge_id_lead) then
				self.base_gauge_lead_on = true
			else
				self.base_gauge_lead_on = false
			end
		end

	end

	function AutoAim:UpdateGaugeDrawStatus_Sec() --targeting computer mode for secondaries

		local required_bool

		if self.is_during_mission then
			if self.SecondaryAutoAimOn and not self.PrimaryAutoAimOn and self.base_gauge_center_on and not BombHelper.bomb_camera_on  then
				--gauge needs to be showing
				required_bool = true
			else
				--gauge needs to be off
				required_bool = false
			end
		end

		if required_bool ~= nil then
			mn.evaluateSEXP("( hud-set-custom-gauge-active ( "..tostring(required_bool).." ) !"..self.gauge_name_secondary.."! )")
			--make targeting computer gauge more distinct, even if center reticle color changed then it will stick
			if required_bool then
				--reminder, the sexp version sets a flag that means nothing else besides sexp can change color
				mn.evaluateSEXP("( hud-set-color !"..self.gauge_name_secondary.."! 255 0 0 )")
			end
		end

	end

	function AutoAim:UpdateGaugeDrawStatus_Stat() --stationary fire mode

		if self.is_multiplayer then return end --fov and extra primary juice won't change on server

		local required_bool

		if self.is_during_mission then
			if not self.PrimaryAutoAimOn and not self.SecondaryAutoAimOn and self.base_gauge_center_on then
				--gauge needs to be showing
				required_bool = true
			else
				--gauge needs to be off
				required_bool = false
			end
		end

		if required_bool ~= nil then
			mn.evaluateSEXP("( hud-set-custom-gauge-active ( "..tostring(required_bool).." ) !"..self.gauge_name_stationary.."! )")
		end

	end

	function AutoAim:CheckUpdateGauges()

		self:CheckBaseGauge()
		self:UpdateGaugeDrawStatus_Sec()
		self:UpdateGaugeDrawStatus_Stat()

	end

--


--Create Button
	FotG:UI_BT_Add(AutoAim.button_info)


--Hooks
if not IS_STANDALONE then 
	engine.addHook("On Gameplay Start", function() 
			AutoAim:MissionSetup(true) --runs reset internally
		end
	)

	engine.addHook("On Mission About To End", function() 
			AutoAim:Reset(false)
		end
	)

	engine.addHook("On State Start", function() 
			--On State Start runs before On Gameplay Start, 
			--  but On State Start runs every time we come back into the game, even from a paused menu
			--so we do not want to always run the setup scripts, 
			--  but we do want to check the draw HUD status and run a sexp if needed, but only after time has passed
			if MTIME_OVER_P1 then
				AutoAim:CheckUpdateGauges()
			end
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Ship Arrive", function() 
			if not AutoAim.is_multiplayer then
				AutoAim:ClearAI(hv.Ship)
			end
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Frame", function() 
			AutoAim:OnFrame()
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	io.Keybinding["CYCLE_NEXT_PRIMARY"]:registerHook(function()
		AutoAim:Set_FOV(FotG:GetPlayerShip(), true) --"Cycle Primary Weapon Forward"
		return false
	end, true, true)

	io.Keybinding["CUSTOM_CONTROL_1"]:registerHook(function()
		AutoAim:Toggle_T_Computer() --"Toggle Targeting Computer Mode"
		return false
	end, true, true)

	io.Keybinding["CUSTOM_CONTROL_5"]:registerHook(function()
		AutoAim:TogglePrimaryAssist() --"Toggle Stationary Target Mode"
		return false
	end, true, true)

end