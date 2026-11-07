-- This file contains the script which flickers glowmaps of dying ships or damaged cockpit.

GlowmapFlicker = {
	global_enabled = true,

	type_ship = 1,
	type_cockpit = 2
}

--Code
	function GlowmapFlicker:FullReset()

		self.activemaps = {}
		self.num_active = 0
		self.min_flicker_interval = 0.03
		self.failsafe_last_check = 0
		self.failsafe_interval = 1

		if ba.MultiplayerMode then
			self.is_multiplayer = true
		else
			self.is_multiplayer = false
		end

		local enabled = (self.global_enabled and not self.is_multiplayer)

		self.is_enabled_large_ships = enabled
		self.is_enabled_cockpit = enabled

	end

	function GlowmapFlicker:CPValid()

		if self.is_multiplayer then return false end

		if not self.is_enabled_cockpit then return false end

		local answer = false 
		local player = FotG:GetPlayerShip()

		if player ~= nil and player:isValid() and player:getBreedName() == "Ship" then
			--in first person view
			if gr.hasViewmode(VM_INTERNAL) then
			--also not in bomb view
				if BombHelper ~= nil and not BombHelper.bomb_camera_on then
					local pcockpit = player.Class.CockpitModel 
					--in a valid cockpit
					if pcockpit ~= nil and pcockpit:isValid() then 
						answer = true
					end
				end
			end
		end

		return answer

	end

	function GlowmapFlicker:Remove(ship_signature)

		if self.activemaps ~= nil and self.activemaps[ship_signature] ~= nil then
			self.num_active = self.num_active - 1
			--failsafe 
			if self.num_active < 0 then
				self.num_active = 0
			end
			self.activemaps[ship_signature] = nil
		end

	end

	function GlowmapFlicker:Add(ship, objecttype, duration, final_glow_state, is_dying)

		if self.is_multiplayer then return end

		if ship == nil then return end
		if not ship:isValid() then return end

		--variable setup
		local starttime = mn.getMissionTime()
		local ship_signature = ship:getSignature()

		if ship_signature == nil then return end

		local ship_glows_disabled = false
		if ship:getFlag("glowmaps-disabled") then
			ship_glows_disabled = true
		end

		--ship method 
		if objecttype == self.type_ship and self.is_enabled_large_ships then
			--don't flicker glowmaps if it's a fighter or bomber since there are so many of them
			local shiptype = ship.Class.Type.Name
			if shiptype == "fighter" or shiptype == "bomber" then
				return
			end
			--also disable turrets since it looks odd to have turrets firing in wild directions 
			--and firing in general if power is flickering
			if duration == nil then
				mn.evaluateSEXP("( turret-lock-all !"..ship.Name.."! )")
				duration = ship:getTimeUntilExplosion()
			end
			duration = duration - (self.min_flicker_interval * 2)

			--only flicker lights if there are lights to flicker, otherwise just shut any remaining ones off
			--but only if we are using for large dying ships
			if is_dying then
				if ship_glows_disabled or ship:getFlag("no-thrusters") then
					ship:setFlag(true, "glowmaps-disabled", "no-thrusters")
					return
				end
			end
		end

		--cockpit method
		if objecttype == self.type_cockpit then
			duration = duration or 0.8 --seconds (maybe make it longer for how big the hit was?)
		end

		--even if this already exists we just overwrite it so as to keep the list short
		if self.activemaps[ship_signature] ~= nil then
			-- if already exists just overwrite
			local info = self.activemaps[ship_signature]
			info.flicker_starttime = starttime
			info.flicker_duration = duration
			info.flicker_objecttype = objecttype
			info.glows_disabled = ship_glows_disabled
			info.final_glow_state = final_glow_state
			info.ship_name = ship.Name
			info.flicker_current_time = 0 -- so flicker starts right away
		else
			--if nil then add
			self.activemaps[ship_signature] = { 
				flicker_starttime = starttime, 
				flicker_duration = duration, 
				flicker_objecttype = objecttype,
				glows_disabled = ship_glows_disabled,
				ship_name = ship.Name,
				final_glow_state = final_glow_state,
				flicker_current_time = 0 -- so flicker starts right away
			}
			self.num_active = self.num_active + 1
		end

	end

	function GlowmapFlicker:PlyReset(ply_sig)

		if self.is_multiplayer then return end

		local ply = FotG:GetPlayerShip()
		if ply ~= nil and ply:isValid() and ply:getBreedName() == "Ship" then
			if not ply:isDying() then
				ply:setFlag(false, "glowmaps-disabled")
				self:Remove(ply:getSignature())
				return
			end
		end

		--if still here then ply was not valid so check if we have manual sig to use with remove
		if ply_sig ~= nil then
			self:Remove(ply_sig)
		end

	end

	function GlowmapFlicker:Failsafe_Off(k_shipsig, v_flickerinfo)

		--failsafe to off if dying ship
		if not self.is_enabled_large_ships or v_flickerinfo == nil then 
			return 
		end

		local ship_name = v_flickerinfo.ship_name

		if v_flickerinfo.flicker_objecttype == self.type_ship and ship_name ~= nil then
			if v_flickerinfo.final_glow_state == true and v_flickerinfo.glows_disabled then
				--when done, set glow state to on if final is supposed to be on and they are not currently on
				mn.evaluateSEXP("( activate-glow-maps !".. ship_name .."! ) ")
				mn.evaluateSEXP("( set-thrusters-status !true! !" .. ship_name .. "! )")
				v_flickerinfo.glows_disabled = false
			elseif v_flickerinfo.final_glow_state == false and not v_flickerinfo.glows_disabled then 
				--when done, set glow state to off if final is supposed to be on and they are currently on
				mn.evaluateSEXP("( deactivate-glow-maps !".. ship_name .."! ) ")
				mn.evaluateSEXP("( set-thrusters-status !false! !" .. ship_name .. "! )")
				v_flickerinfo.glows_disabled = true
			end

			self:Remove(k_shipsig)

		end	

	end

	function GlowmapFlicker:Run()

		--no multi running
		if self.is_multiplayer then return end

		if not MTIME_OVER_P1 then return end

		if FotG.NebulaSliderCurrent <= FotG.NebulaLowSetting then return end

		--only run if needed
		if self.num_active > 0 and (self.is_enabled_large_ships or self.is_enabled_cockpit) then

			local mtime = mn.getMissionTime()
			local min_step = self.min_flicker_interval
			local mn_ships = mn.Ships

			for k_shipsig, v_flickerinfo in pairs(self.activemaps) do
				local flicker_time_elapsed = mtime - v_flickerinfo.flicker_starttime

				local turn_off = false

				--run checks if time valid
				if flicker_time_elapsed < v_flickerinfo.flicker_duration then

					--get ship
					local ship = mn_ships[v_flickerinfo.ship_name]

					--run if still valid
					if ship ~= nil and ship:isValid() then

						local glowdisabled = v_flickerinfo.glows_disabled 
						--run for ships 
						if v_flickerinfo.flicker_objecttype == self.type_ship and self.is_enabled_large_ships then
							-- only flicker if game time progressing (ie not paused)
							if mtime > v_flickerinfo.flicker_current_time + min_step then

								v_flickerinfo.flicker_current_time = mtime

								--flicker the lights
								if (ba.rand32f() * v_flickerinfo.flicker_duration) > flicker_time_elapsed then
									if glowdisabled then
										ship:setFlag(false, "glowmaps-disabled", "no-thrusters")
										v_flickerinfo.glows_disabled = false
									end
								else --note the final is to have the glow maps off since the ship is dead
									if not glowdisabled then
										ship:setFlag(true, "glowmaps-disabled", "no-thrusters")
										v_flickerinfo.glows_disabled = true
									end
								end

							end
						end

						--run for cockpit 
						if v_flickerinfo.flicker_objecttype == self.type_cockpit and self.is_enabled_cockpit then
							--if inside view and not bomb view then flicker
							if self:CPValid() then
								-- only flicker if game time progressing (ie not paused)
								if mtime > v_flickerinfo.flicker_current_time + min_step then

									v_flickerinfo.flicker_current_time = mtime

									--flicker the lights
									if (ba.rand32f() * v_flickerinfo.flicker_duration) > flicker_time_elapsed then
										if not glowdisabled then 
											ship:setFlag(true, "glowmaps-disabled")
											v_flickerinfo.glows_disabled = true
										end
									--note the final is to have the glow maps back on
									else
										if glowdisabled then 
											ship:setFlag(false, "glowmaps-disabled")
											v_flickerinfo.glows_disabled = false
										end
									end

								end
							--if outside view reset
							else
								if glowdisabled then
									ship:setFlag(false, "glowmaps-disabled")
									v_flickerinfo.glows_disabled = false
								end
							end						
						end

					else --remove if ship no longer valid

						turn_off = true

					end

				--time is up, so remove it and toggle glow map if needed
				else
					turn_off = true
				end

				if turn_off then
					if v_flickerinfo.flicker_objecttype == self.type_cockpit then
						--failsafe to turn back on if player cockpit
						self:PlyReset(k_shipsig) --includes :Remove(
					else
						--failsafe to off and remove if ship
						self:Failsafe_Off(k_shipsig, v_flickerinfo) --includes :Remove(
					end
				end

			end

		end

	end

	mn.LuaSEXPs["run-glowmap-flicker"].Action = function (ship, duration, final_glow_state)

		if final_glow_state == nil then final_glow_state = false end

		GlowmapFlicker:Add(ship, GlowmapFlicker.type_ship, duration or 5, final_glow_state, false)

	end

--

--Hooks
if not IS_STANDALONE and GlowmapFlicker.global_enabled then

	engine.addHook("On Gameplay Start", function() 
			GlowmapFlicker:FullReset()
		end
	)

	engine.addHook("On Mission About To End", function() 
			GlowmapFlicker:FullReset()
		end
	)

	engine.addHook("On Pain Flash", function() 
			if hv.Pain_Type == 1 then --1 is for hull, 0 is for shields
				if GlowmapFlicker:CPValid() then
					GlowmapFlicker:Add(FotG:GetPlayerShip(), GlowmapFlicker.type_cockpit, nil, true, false)
				end
			end
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	if FotG ~= nil and FotG.use_ship_collision_scripts then
		engine.addHook("On Ship Collision", function() 
				if hv.Self == hv.Player then
					if GlowmapFlicker:CPValid() then
						GlowmapFlicker:Add(FotG:GetPlayerShip(), GlowmapFlicker.type_cockpit, nil, true, false)
					end
				end
			end,
			{State="GS_STATE_GAME_PLAY"}
		)
	end

	engine.addHook("On Ship Death", function() 
			--do not use 'On Ship Death Started' since time until explosion is 0
			local ship = hv.Ship
			if not ba.MultiplayerMode and ship ~= nil and ship:isValid() then
				GlowmapFlicker:Add(ship, GlowmapFlicker.type_ship, nil, false, true)
			end
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Frame", function() 
			GlowmapFlicker:Run()
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	io.Keybinding["VIEW_CHASE"]:registerHook(function()
		if MTIME_OVER_P1 then
			GlowmapFlicker:PlyReset()
		end
		return false
	end, true, true)

	io.Keybinding["TOGGLE_HUD"]:registerHook(function()
		if MTIME_OVER_P1 then
			GlowmapFlicker:PlyReset()
		end
		return false
	end, true, true)

end