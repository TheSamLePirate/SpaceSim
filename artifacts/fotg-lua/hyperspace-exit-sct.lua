
	--global variable for effects related to exiting hyperspace
	--declare these names here as we might need to check them in other scripts that might run on mission start before this one
HyperspaceExit = {

	starstreaks_effect_2k = "PE_HyperStreaks_1_2k",
	starstreaks_effect_4k = "PE_HyperStreaks_1_4k",
	tunnel_lights_effect = "PE_HyperTunnel_Lights_1",
	star_streak_part_start_time = 0.075, 
	skybox_fadein_start_base = 2.75,
	skybox_fadein_duration_base = 1.0,
	tunnel_fadeout_start_time = 0.49,
	tunnel_fadeout_duration = 0.25,

	event_enbale_hyperspacename = "PlayerArrivesFromHyperspace",
	event_disable_p_bank = "HYP-NoPlanetBankRotation",
	event_pwing_orientation_override = "HYP-WingmenUseOwnOrientation",
	exitduration = 4,
	default_sun = {
		bitmap = "SunWhite", --first sun entry in stars.tbl
		pbh = {0, 0, math.rad(-60) }, --from SCP code base "Adding default sun"
		scale = 1.0
	},

	ship_hide_radius = 100,

	black_texture_name = "starfield_transparent",
	base_planet_texture_name = "S_PlanetBase",

	smallest_scale = 0.0001,
	hyp_start_relative_offset_z = -150000,
	hyp_zoom_relative_offset_z = -55000, --far enough back so things look small, but close enough zoom still looks fluid

	position_helper_ids = { --make sure to update in the hyperspace sexp file, too
		-- these are used in PA, too
		North = 0,
		South = 1,
		East = 2,
		West = 3,
	},

	skybox_helper_ids = { --make sure to update in the hyperspace sexp file, too
		skybox_starfield = 0,
		skybox_planet = 1,
		skybox_asteroids_debris_any = 2, --must be same as all other asteroids/debris
		skybox_asteroids_blue = 2, --must be same as all other asteroids/debris
		skybox_asteroids_brown = 2, --must be same as all other asteroids/debris
		skybox_asteroids_grey = 2, --must be same as all other asteroids/debris
		skybox_debris = 2 --must be same as all other asteroids/debris
	},

	skybox_animations = {
		hp_asteroid_or_debris_list = { --this has to match the position_helper_ids above
			"Hyperspace_Exit_AS_South", --1
			"Hyperspace_Exit_AS_East", --2
			"Hyperspace_Exit_AS_West" --3
		},
		hp_planet_any = {
			"Hyperspace_Exit_PL_Any"
		}
	},

	--NOTE_ON_CALCULATIONS:
		--both sides converge at 125 meters ahead of player
		--take length of star streaks model in meters and / by texture length of 512 meters
		--  for example, 1000 meters / 512 pixels = 1.9531 meters/pixel
		--also, if mesh extends behind player, account for any offset of where max texture length is in relation to player 
		--  in other words, how far back does the mesh extend past the player?
		--    for example, perhaps the mesh extends 500 meters behind the player, 
		--      which is 256 pixels behind player ((500 meters / 1) * (1 pixel / 1.9531 meters))
		--      to converge at 125 meters that is (125 meters / 1) * (1 pixel / 1.9531 meters) + 256 pixels ~= 320 pixels
		--  512 pixels - 320 pixels = 192 pixels (x1 value)
		--  512 - (1 * x ) = 192 => 512 - 192 => 320 pixels (x2 value)

		-- default case:
		--  both sides converge at 125 meters ahead of player
		--  500 meters / 512 pixels = 0.9765625 meters/pixel
		--  mesh does not extend behind player 
		--  x1 value uses 384 pixels
		--  x2 value uses 128 pixels

		-- note mesh extending behind player does not look as good since it results in larger streaks
		-- also anything but the default for forward facing seems to not work as well, 
		-- thus keep forward facing same as is, 
		-- and use a rear view model to catch up and merge with where front facing section ends
}

--Code

	function HyperspaceExit:Reset()

		if HP_Exit_Tunnel_Ship ~= nil then
			HP_Exit_Tunnel_Ship:vanish()
			HP_Exit_Tunnel_Ship = nil
		end

		Hyperspace_star_particles = nil
		Hyperspace_light_particles = nil

		--set dynamic defaults 
		self.is_player_jumping_in = false --initiate this here to use with the escort script

		self.player_jumpend_velocity = nil

		self.fred_set_skybox_id = 0
		self.fred_set_plypos_id = 0
		self.fred_set_skybox_tex = nil
		self.skybox_helper_anim_stage1 = nil
		self.skybox_helper_anim_stage2 = nil

		self.background_stages_suns = nil
		self.background_stages_planets = nil
		self.number_suns = 0
		self.number_planets = 0

		self.fade_in_started = nil
		self.disable_p_bank_rotation = nil
		self.player_orientation = nil
		self.screen_center_x = nil
		self.screen_center_y = nil
		self.ply_pos_zoom_start = nil
		self.ply_pos_zoom_end = nil
		self.last_mtime = nil
		self.jump_in_effect_start_time = nil
		self.tunnel_move_started = nil
		self.fix_max_target_range = nil

		self.star_streaks_started = nil
		self.skybox_fade_done = nil
		self.tunnel_fade_out_started = nil

		self.isexitsound_1 = nil
		self.iszoomdone = nil
		self.isexitsound_2 = nil
		self.fake_warp_started = nil
		self.is_sexp_reset_done = nil
		self.skybox_alpha_og = nil

		self.skybox_fadein_start_mn = self.skybox_fadein_start_base
		self.skybox_fadein_duration_mn = self.skybox_fadein_duration_base

	end

	function HyperspaceExit:Get_BackgroundElement_Stages(bg_element, player_pbh) --pbh in {p=, b=, h=} in radians, final scale in {x=,y=}

		local bg_stages

		if bg_element ~= nil and player_pbh ~= nil then 
			--set starting orientations based on player orientations
			--normalize initial and final
			local background_pbh = bg_element.Orientation
			local i_pbh = Movements:StandardizePBH({p = player_pbh.p, b = player_pbh.b, h = player_pbh.h})
			local f_pbh = Movements:StandardizePBH({p = background_pbh.p, b = background_pbh.b, h = background_pbh.h})

			local l_x, l_y = FotG:BackgroundXYScale(bg_element.ScaleX, true)

			bg_stages = {
				initial_pbh = i_pbh,
				initial_scale = {x = self.smallest_scale, y = self.smallest_scale},

				final_pbh = f_pbh,
				final_scale = {x = l_x, y = l_y},

				i_orientation = ba.createOrientation(i_pbh.p, i_pbh.b, i_pbh.h),
				v_orientation = ba.createOrientation(f_pbh.p, f_pbh.b, f_pbh.h),
			}
		end

		return bg_stages

	end

	function HyperspaceExit:SetBitmap(bg_element, bg_script_entry, percent_moved)

		if bg_element == nil or bg_script_entry == nil then return end

		--Orientation
		if self.disable_p_bank_rotation then
			--complex hacky way
			local new_ort = {}
			--find progress using pbh matrices

			local startpbh = bg_script_entry.initial_pbh
			local endpbh = bg_script_entry.final_pbh

			for _,v in ipairs({"p", "b", "h"}) do
				if percent_moved >= 1.0 then
					new_ort[v] = endpbh[v]

				elseif percent_moved <= 0.0 then
					new_ort[v] = startpbh[v]

				else
					if v == "b" then
						new_ort[v] = endpbh[v]
					else
						new_ort[v] = startpbh[v]*(1-percent_moved) + endpbh[v]*percent_moved
					end
				end
			end

			bg_element.Orientation = ba.createOrientation(new_ort.p, new_ort.b, new_ort.h)

		else
			--reasonable clean way
			bg_element.Orientation = bg_script_entry.i_orientation:rotationalInterpolate(bg_script_entry.v_orientation, percent_moved)
		end

		--Scale
			--scale size
			local finalscale = bg_script_entry.final_scale
			local startscale = bg_script_entry.initial_scale
			local new_scale_x, new_scale_y

			--get rate and progress of zoom
			--get scale axis values, use x as base
			local start_x = startscale.x
			local final_x = finalscale.x

			if percent_moved >= 1.0 then
				--final shortcut
				new_scale_x = final_x
				new_scale_y = finalscale.y

			elseif percent_moved <= 0.0 then
				--initial shortcut
				new_scale_x = start_x
				new_scale_y = startscale.y

			else
				--progress calculations
				--get size of bitmap to draw, needs to be >0 and <= final size
				local current_x = math.Lerp(start_x, final_x, percent_moved)
				if current_x <= 0 then 
					current_x = start_x
				end

				local s_x, s_y = FotG:BackgroundXYScale(current_x)
				--special case for y value to keep things circular instead of stretching
				new_scale_x = s_x
				new_scale_y = s_y
			end

			--actually set scale
			bg_element:setScale(new_scale_x, new_scale_y)

	end

	function HyperspaceExit:BackgroundZoomHelper(zoom_percentdone)

		local num_suns = self.number_suns
		if num_suns >= 1 then
			local mn_suns = mn.BackgroundSuns
			local meta_suns = self.background_stages_suns
			for i=1,num_suns do
				self:SetBitmap(mn_suns[i], meta_suns[i], zoom_percentdone)
			end
		end

		local num_planets = self.number_planets
		if num_planets >= 1 then
			local mn_planets = mn.BackgroundBitmaps
			local meta_planets = self.background_stages_planets
			for i=1,num_planets do
				self:SetBitmap(mn_planets[i], meta_planets[i], zoom_percentdone)
			end
		end

	end

	function HyperspaceExit:HideShip_for_X_Seconds(ship, duration)

		--validity checks
		if ship == nil then return end
		if not ship:isValid() then return end

		--hide thrusters since shader effect does not
		ship:setFlag(true, "no-thrusters")

		--run hide shader effect for given duration
		duration = duration or 0
		ship:addShipEffect("Show Once T Over", duration*1000)

		--unhide thrusters when duration over
		async.run(function()
			async.await(mn.waitAsync(duration))
			if ship ~= nil and ship:isValid() then
				ship:setFlag(false, "no-thrusters")
			end
		end)

	end

	function HyperspaceExit:Startup()

		self:Reset()

		if ba.MultiplayerMode then return end

		if CapShipControl:IsEnabled() then return end

		if not mn.Events[self.event_enbale_hyperspacename]:isValid() then return end

		-- Fade in to avoid jitter from 1st load of objects
		-- sneaky longer fade in if super wide screen
		self.fade_in_started = false
		mn.evaluateSEXP("(fade-out 0 0)")

		local screen_width = gr.getScreenWidth()

		self.screen_center_x = screen_width/2
		self.screen_center_y = gr.getScreenHeight()/2

		self.skybox_alpha_og = mn.SkyboxAlpha
		mn.SkyboxAlpha = 0.0

		local particle_items = tb.ParticleEffects

		local streak_res = self.starstreaks_effect_2k
		if screen_width > 3000 then
			streak_res = self.starstreaks_effect_4k
		end

		Hyperspace_star_particles = particle_items[streak_res]
		Hyperspace_light_particles = particle_items[self.tunnel_lights_effect]

		local pship = FotG:GetPlayerShip()
		if pship == nil then return end
		if not pship:isValid() then return end
		if pship:getBreedName() ~= "Ship" then return end

		if pship:isDying() then return end

		self.is_sexp_reset_done = false

		self.last_mtime = 0.0

		--reset time compression in-case it got set
		ExtraControls:ActivePauseMode_Reset(true)

		local mtime = mn.getMissionTime()
		self.last_mtime = mtime

		local pshhip_physics = pship.Physics

		-- For some reason the ship likes to get some rotational velocity from
		-- somewhere; this nullifies that
		pshhip_physics.RotationalVelocity = FotG.VECTOR_ZERO

		--if the player has an initial velocity then it will register once the ship is back to being mobile
		--setting Physics.Velocity is only good for one frame, so use immobile

		--protect player ship so AI won't fire at it until hyperspace effect ends
		--any wingmen do not need this protection since they will immediately change positions to begin their warp_in 

		local current_vel = pshhip_physics.Velocity
		self.player_jumpend_velocity = {
			current_vel[1], current_vel[2], current_vel[3], 
			pshhip_physics.ForwardAccelerationTime,
			pshhip_physics.AfterburnerAccelerationTime 
		}

		pship:setFlag(true, "don't-change-position", "don't-change-orientation", "protect-ship", "laser-protect-ship", "missile-protect-ship")

		self.is_player_jumping_in = true
		self.jump_in_effect_start_time = mtime

		-- Don't let the player nor AI do anything during the effect
		pship:setFlag(true, "primaries-locked", "secondaries-locked")
		--mn.evaluateSEXP("(player-use-ai)")
		pship:giveOrder(ORDER_PLAY_DEAD_PERSISTENT, nil, nil, 200/100)

		--get where FREDer put the player and save it before we change it
		--also update starting zoom position based off of this location
		local player_starting_position = pship.Position
		local player_starting_orientation = pship.Orientation 
		local offset_zoom_vec = ba.createVector(0, 0, self.hyp_zoom_relative_offset_z)
		local starting_zoom_pos = pship:findWorldPoint(offset_zoom_vec)
		self.ply_pos_zoom_end = ba.createVector(player_starting_position[1], player_starting_position[2], player_starting_position[3])
		self.ply_pos_zoom_start = ba.createVector(starting_zoom_pos[1], starting_zoom_pos[2], starting_zoom_pos[3])

		--set player ship very far away and update starting position and orientation
		--also save updated position for use in setting up hyperspace ships below
		local offset_starting_effect_vec = ba.createVector(0, 0, self.hyp_start_relative_offset_z)
		local offset_player_starting_pos = pship:findWorldPoint(offset_starting_effect_vec)
		pship.Position = offset_player_starting_pos

		--Disable built in messages 
		mn.evaluateSEXP("( disable-builtin-messages )")

		--player:warpIn() --now executed later on with physically moving player position

		--disable targeting HUD gauges
		mn.evaluateSEXP("( ignore-key -1 !C! )")
		mn.evaluateSEXP("( hud-set-max-targeting-range 1 )")
		mn.evaluateSEXP("( hud-set-builtin-gauge-active ( false ) !Escort list! !Directives! )")
		self.fix_max_target_range = true

		--disable throttle gauge and others temporarily
		MissionHelper:Set_ControlGauges_Status(false)

		-- lock to force to first person view (just in case some mission designer put start in 3rd person mode on)
		-- 3rd person bad b/c the ship sway view does not keep up with the forced effect
		-- note, free look still works even with lock-perspective enabled
		mn.evaluateSEXP("(lock-perspective !true! !0!)")

		--setup other variables
		self.tunnel_move_started = false
		self.star_streaks_started = false
		self.skybox_fade_done = false
		self.tunnel_fade_out_started = false

		-- Get the player's wing
		local player_wing = pship:getWing()

		-- and make all the non-player ships in the player's wing
		-- warp in and makes sure their orientation is the same as the player's,
		-- but first check if there is an override
		local pwing_uses_ply_ori = true
		if mn.Events[self.event_pwing_orientation_override]:isValid() then
			pwing_uses_ply_ori = false
		end

		if player_wing ~= nil and player_wing:isValid() then
			local num_of_ships_pwing = #player_wing
			if num_of_ships_pwing >= 1 then
				local po = player_starting_orientation
				for i=1, num_of_ships_pwing do
					local wship = player_wing[i]
					if not wship:isPlayer() then
						if pwing_uses_ply_ori then
							wship.Orientation = ba.createOrientation(po.p, po.b, po.h)
						end
						--recall this does not trigger a `On Ship Arrive` hook
						wship:warpIn()
					end
				end
			end
		end

		--hide any ships warping in
		--since they will look strange with fake player warp
		--if FREDer has ships arriving after mission start but before player done warping
		--then they should give those ships custom warps to make entry look good
		for ship in mn.getShipList() do
			if ship:isArrivingWarp() then
				--though also hide since warp ins will not quite match
				self:HideShip_for_X_Seconds(ship, self.exitduration * 0.98)
			elseif ship.Radius > self.ship_hide_radius then
				--hide super huge ships so they don't appear at start of fake warp in distance
				self:HideShip_for_X_Seconds(ship, self.exitduration * 0.75)
			end
		end

		--check if mission has disabled planet bank rotation with zoom effect
		if mn.Events[self.event_disable_p_bank]:isValid() then
			self.disable_p_bank_rotation = true
		else
			self.disable_p_bank_rotation = false
		end

		--set player pbh in preparation for bitmap zooming
		self.player_orientation = player_starting_orientation

		local mission_suns = mn.BackgroundSuns
		local mission_planets = mn.BackgroundBitmaps

		local num_suns = #mission_suns
		local num_planets = #mission_planets

		self.number_suns = num_suns
		self.number_planets = num_planets

		self.background_stages_suns = {}
		self.background_stages_planets = {}

		--setup initial values of backgrounds (small scale in front of player which will be hidden by hyper tunnel)
		if num_suns >= 1 then
			for i=1,num_suns do
				local sun = mission_suns[i]
				if sun ~= nil then
					local stages = self:Get_BackgroundElement_Stages(sun, player_starting_orientation)
					self.background_stages_suns[i] = stages
					self:SetBitmap(sun, stages, 0)
				end
			end
		end
		if num_planets >= 1 then
			for i=1,num_planets do
				local planet = mission_planets[i]
				if planet ~= nil then
					local stages = self:Get_BackgroundElement_Stages(planet, player_starting_orientation)
					self.background_stages_planets[i] = stages
					self:SetBitmap(planet, stages, 0)
				end
			end
		end

		--set sound and zoom bools
		self.isexitsound_1 = true
		self.iszoomdone = false

		self.isexitsound_2 = false
		self.fake_warp_started = false

		--play hyperspace tunnel sound
		ad.playGameSound(81)

		--add hyperspace tunnel 

		-- get where hyperspace effect ships should spawn that accounts for eye point
		local player_eye_position_local = HyperspaceEnter:Get_LocalEyepointPos(pship)
		local player_eye_position_global = pship:findWorldPoint(player_eye_position_local)

		HP_Exit_Tunnel_Ship = mn.createShip("Hyperspace Tunnel", tb.ShipClasses["Hyperspace_Tunnel"], player_starting_orientation, player_eye_position_global, pship.Team, false)

		if HP_Exit_Tunnel_Ship == nil or not HP_Exit_Tunnel_Ship:isValid() then
			ba.warning("Error creating hyperspace tunnel!")
		end

		HP_Exit_Tunnel_Ship:setFlag(true, "stealth", "friendly-stealth-invisible", "protect-ship", "laser-protect-ship", "missile-protect-ship")

		HP_Exit_Tunnel_Ship:addShipEffect("Hyperspace Tunnel End Glow", 4000)

		local lights_source = Hyperspace_light_particles:createSource()
		lights_source:createOnObject(pship, ba.createVector(0, 0, 0))

	end

	function HyperspaceExit:RunSkybox(skybox_type_id, skybox_ply_pos_id, forward, isinstant)

		--asteroid south, east, west
		--planet south, east, west

		skybox_type_id = skybox_type_id or 0

		--copied from sexp
		--skybox_ply_pos_id: (1=South, 2=East, 3=West)
		--skybox_type_id: (1=planet skybox, 2=any asteroid skybox5)

		local animation_name

		if skybox_type_id == 1 then
			--planet
			animation_name = self.skybox_animations.hp_planet_any[1]
			--just texture replace for planet
			if forward then
				--set texture to self.black_texture_name
				--  ie: self.base_planet_texture_name -> self.black_texture_name
				mn.evaluateSEXP("( replace-skybox-texture !"..self.base_planet_texture_name.."! !"..self.black_texture_name.."! )")
			else
				--set texture to self.fred_set_skybox_tex
				--  ie: self.base_planet_texture_name -> self.fred_set_skybox_tex
				if self.fred_set_skybox_tex ~= nil then 
					mn.evaluateSEXP("( replace-skybox-texture !"..self.base_planet_texture_name.."! !"..self.fred_set_skybox_tex.."! )")
				end
			end

			return

		elseif skybox_type_id == 2 then
			--asteroids (or debris)
			animation_name = self.skybox_animations.hp_asteroid_or_debris_list[skybox_ply_pos_id]
		else
			return
		end

		if animation_name == nil then 
			ba.print("Hyperspace error, Run Skybox function does not recognize this entry number "..tostring(skybox_type_id).." \n")
			return 
		end

		local anim = mn.getSpecialSubmodelAnimation("skybox", "scripted", animation_name)
		if anim == nil then 
			ba.print("Hyperspace error, Run Skybox function does not recognize this animation name "..tostring(animation_name).." \n")
			return 
		end

		anim:start(forward, false, isinstant, false)
		--start([boolean forwards = true, boolean resetOnStart = false, boolean completeInstant = false, boolean pause = false])

	end

	function HyperspaceExit:Draw()

		if not self.is_player_jumping_in then return end

		local pship = FotG:GetPlayerShip()

		if pship == nil then return end
		if not pship:isValid() then return end
		if pship:getBreedName() ~= "Ship" then return end

		if pship:isDying() then return end

		local mtime = mn.getMissionTime()
		local exitduration = self.exitduration 
		local time_elapsed_absolute = mtime - self.jump_in_effect_start_time
		local time_elapsed_relative = (time_elapsed_absolute) / exitduration

		if not self.fade_in_started and mtime > 0.1 then
			--fade in seems to work better here instead of On Start
			mn.evaluateSEXP("(fade-in 1000 0)")
			self.fade_in_started = true
		end

		--move tunnel
		if not self.tunnel_move_started then
			if HP_Exit_Tunnel_Ship ~= nil then
				HP_Exit_Tunnel_Ship:triggerSubmodelAnimation("scripted", "Hyperspace_In_Effect", true, true, false)
				self.tunnel_move_started = true
			end
		end

		--star streaks
		if not self.star_streaks_started and time_elapsed_relative > self.star_streak_part_start_time * exitduration then
			local source = Hyperspace_star_particles:createSource()
			source:createOnObject(pship, ba.createVector(0, 0, 0))
			self.star_streaks_started = true
		end

		if not self.skybox_fade_done and time_elapsed_relative > self.skybox_fadein_start_mn/exitduration then
			local percent_done = ( time_elapsed_absolute - self.skybox_fadein_start_mn ) / self.skybox_fadein_duration_mn
			if percent_done <= 1.0 then
				mn.SkyboxAlpha = percent_done
			else
				self.skybox_fade_done = true
				mn.SkyboxAlpha = self.skybox_alpha_og
			end
		end

		--tunnel, fadeout starting at 0.49 and ending at 0.74
		if time_elapsed_relative > self.tunnel_fadeout_start_time and not self.tunnel_fade_out_started then

			self.tunnel_fade_out_started = true
			if HP_Exit_Tunnel_Ship ~= nil then
				HP_Exit_Tunnel_Ship:addShipEffect("Hyperspace Tunnel Fade Out", (self.tunnel_fadeout_duration) * exitduration * 1000)
			end

		end

		--Zooms in any planets and ships
		--set what portion of time in the warp effect the bitmaps should zoom during
		local pzoom_starttime = 0.63
		local asteroid_zoom_starttime = 0.48 --recall, the duration for asteroid zoom set in anim table
		local pzoom_endtime = 0.90
		local skyboxplanet_zoom_endtime = 0.90 --looks best if this matches regular planet zoom time above

		--also when we start to see planets, that means any ships should be not far behind
		--so fake warp starts shortly after, though we also want to make sure it matches with sound
		--and sound has to be 0.7 to have sound match overall effect
		local pwarp_start_sound = 0.7 --when sounds starts
		local pwarp_start_zoom = 0.71 --when fake warp in starts

		local l_skybox_id = self.fred_set_skybox_id
		if l_skybox_id > 0 and mtime > 0.2 then
			local l_plypos_id = self.fred_set_plypos_id
			--hide first
			if not self.skybox_helper_anim_stage1 then
				self.skybox_helper_anim_stage1 = true
				self:RunSkybox(l_skybox_id, l_plypos_id, true, true) --forward, instant
			end
			--then run animation
			if not self.skybox_helper_anim_stage2 then
				if (l_skybox_id >= self.skybox_helper_ids.skybox_asteroids_debris_any and time_elapsed_relative > asteroid_zoom_starttime) then
					--asteroid (or debris)
					self.skybox_helper_anim_stage2 = true
					self:RunSkybox(l_skybox_id, l_plypos_id, false, false) --forward, instant
				elseif (l_skybox_id == self.skybox_helper_ids.skybox_planet and time_elapsed_relative > skyboxplanet_zoom_endtime) then
					--planet
					self.skybox_helper_anim_stage2 = true
					self:RunSkybox(l_skybox_id, l_plypos_id, false, true) --forward, instant
					--also remove large background bitmap 
					--(which should be the foremost/last in list)
					local big_planet = mn.BackgroundBitmaps[self.number_planets]
					if big_planet ~= nil and big_planet:isValid() then
						mn.removeBackgroundElement(big_planet)
						self.number_planets = self.number_planets - 1
					end
				end
			end
		end

		if not self.iszoomdone then
			local pzoom_starttime_x4 = pzoom_starttime*exitduration
			local pzoom_endtime_x4 = pzoom_endtime*exitduration
			local zoom_time = ( pzoom_endtime_x4  - pzoom_starttime_x4 ) 
			local zoom_percentdone = ( time_elapsed_absolute - pzoom_starttime_x4 ) / zoom_time	
			if zoom_percentdone >= 0 and zoom_percentdone < 1.0 then
				--zoom bitmaps
				self:BackgroundZoomHelper(zoom_percentdone)
			elseif zoom_percentdone >= 1.0 then
				--stop zoom and reset bitmaps to original location
				self.iszoomdone = true
				self:BackgroundZoomHelper(1.0)
			end
		end

		--this plays an extra sound to better match with the planet zoom effect
		if self.isexitsound_1 and time_elapsed_relative > 0.53 then 
			ad.playGameSound(83)
			self.isexitsound_1 = false 
		end

		--warp in player
		if time_elapsed_relative > pwarp_start_sound then
			if not self.isexitsound_2 then
				--play sound
				ad.playGameSound(84)
				self.isexitsound_2 = true
			end
		end
		if time_elapsed_relative > pwarp_start_zoom then
			if not self.fake_warp_started then
				--move player to starting zoom position 
				pship.Position = ba.createVector(self.ply_pos_zoom_start[1], self.ply_pos_zoom_start[2], self.ply_pos_zoom_start[3])
				self.fake_warp_started = true
				--turn off player collisions to optimize movement
				pship:setFlag(false, "collides")
			end
			--normalize to 0-1 for fake warp
			local z_time = ( 1.0*exitduration  - pwarp_start_zoom*exitduration ) 
			local hy_percentdone = ( time_elapsed_absolute - pwarp_start_zoom*exitduration ) / z_time	
			if hy_percentdone >= 0 and hy_percentdone <= 1.0 then
				--find and set updated position
				pship.Position = self.ply_pos_zoom_start:getInterpolated(self.ply_pos_zoom_end, hy_percentdone)
			end
			--OLD WAY:
				-- Doing script warp_in puts the player ship about 5k away, which is a bit too close
				-- since this is 0.7 the player ship should have a custom warp_in time of 1.20 (1-0.7=0.3 * 4 = 1.2)
				-- note: a custom warp_in declaration exponent will also make the effect look better. 
				-- 1.0 is linear speed decrease, 0.5 is faster at the end and 2.0 is faster at the beginning
				-- also a custom declaration of 0.66 looks very nice
				-- player:warpIn()
		end

		--enable targeting HUD gauges
		local unhide_ship_time = pzoom_endtime-0.05 --0.01
		if self.fix_max_target_range and time_elapsed_relative > unhide_ship_time then 
			self.fix_max_target_range = false
			mn.evaluateSEXP("( hud-set-max-targeting-range 0 )")
			mn.evaluateSEXP("( hud-set-builtin-gauge-active ( true ) !Escort list! !Directives! )")
			mn.evaluateSEXP("( ignore-key 0 !C! )")
		end

		if not self.is_sexp_reset_done and time_elapsed_relative > 1.0 then 

			--ensure asteroid/debris can go to using non transparent stars now that effect is over
			if self.fred_set_skybox_id >= self.skybox_helper_ids.skybox_asteroids_debris_any then
				if GRAPHICS_UI.use_bright_stars then
					mn.evaluateSEXP("( replace-skybox-texture !"..GRAPHICS_UI.starfield_whtA_default.."! !"..GRAPHICS_UI.starfield_wht_bright.."! )")
				else
					mn.evaluateSEXP("( replace-skybox-texture !"..GRAPHICS_UI.starfield_whtA_default.."! !"..GRAPHICS_UI.starfield_wht_default.."! )")
				end
			end

			Movements:RemoveGoal_Correctly(pship, 200, "ai-play-dead-persistent")
			pship:setFlag(false, "primaries-locked", "secondaries-locked")
			mn.evaluateSEXP("(player-not-use-ai)")

			--be sure to turn on player collisions!
			pship:setFlag(true, "collides")

			mn.evaluateSEXP("(lock-perspective !false!)")

			--Enable built in messages 
			mn.evaluateSEXP("( enable-builtin-messages )")

			--allow enemies to target player and player ship to move
			pship:setFlag(false, "don't-change-position", "don't-change-orientation", "protect-ship", "laser-protect-ship", "missile-protect-ship")

			--b/c fake zoom moved so fast we might have missed a frame or two
			--which results in being 100s of meters off of FRED placed location
			--so ensure we are at that location
			pship.Position = self.ply_pos_zoom_end

			local pshhip_physics = pship.Physics
			local c_vel = self.player_jumpend_velocity
			pshhip_physics.Velocity = ba.createVector(c_vel[1], c_vel[2], c_vel[3]*1.3)
			pshhip_physics.VelocityDesired = pshhip_physics.Velocity

			MissionHelper:Set_ControlGauges_Status(true)

			self.is_sexp_reset_done = true

		end

		if self.is_sexp_reset_done and time_elapsed_relative > 1.025 then --already a part of the <self.is_player_jumping_in> condition

			--finally reset/unload everything
			--ships have already been unloaded, but fine to double check
			self:Reset()
			--^also sets 'is player jumping in' variable to false
		end

	end

	mn.LuaSEXPs["run-hyperspace-skybox-helper"].Action = function (skybox_id_number, ply_general_pos_id, tex_replace_string)

		if ba.MultiplayerMode then return end

		--this global tracker will inject values into the helper animation function
		HyperspaceExit.fred_set_skybox_id = skybox_id_number or 0
		HyperspaceExit.fred_set_plypos_id = ply_general_pos_id or 0
		HyperspaceExit.fred_set_skybox_tex = tex_replace_string

		--recall skybox fading does not work if we also need to see the planet/asteroid field moving
		--b/c the overlapping alphas do not play nice and instead look bad
		HyperspaceExit.skybox_fadein_start_mn = 1.75
		HyperspaceExit.skybox_fadein_duration_mn = 0.25

	end

--

--Hooks
if not IS_STANDALONE then
	engine.addHook("On Gameplay Start", function() 
			HyperspaceExit:Startup()
		end
	)

	engine.addHook("On Mission About To End", function() 
			HyperspaceExit:Reset()
		end
	)

	engine.addHook("On Frame", function() 
			HyperspaceExit:Draw()
		end,
		{State="GS_STATE_GAME_PLAY"}
	)
end