--background: 
	--AI cannot aim the proton bombs and just wastes them and it looks odd
	--Making the bombs shoot from an perpendicular normal works, but the AI never takes advantage of that because they just point their noise at their target and sit there
	--To fix this, the AI gets to fire bombs from a turret. This is more accurate then dumbfire bombs, and it allows the AI to fire bombs down and straight forward. 
	--The turret fire point points forward and the FOV is 100 degrees. The firepoint is below the ship though, so the bomb cannot fire up.
	--To convert the turret bombs to whatever is in the first bank just make an event titled `ProtonBombConversion`.
	--To turn off turret setting and/or bomb conversion for each ship just set the proton bomb bank to 0.
	--also by default the any bomb dropping bombers have the turret bombs full and the secondary bomb bank (perpendicular normal bank)
	--so this script assumes the FREDer wants to use the number of proton bombs in the secondary bank, and sets that number to the turret number, then sets the secondary bank to 0
	--in multiplayer we do this via sexp to account for various players, and this script also allows turret weapon changing, which doesn't work in multi
	--overall this script could be used in multiplayer, but is off for now in favor of the Bomber Setup sexp in each MP mission

BombHelper = {
	ply_class_filtered = "",
	bomber_turret_name = "BombTurret",
	bomber_camera_name = "Bombing Camera",
	bomb_weapons = {
		["ArmaTek VL-61/79#Pnk"] = "ArmaTek VL-61/79#Pnk",
		["ArmaTek VL-61/79#Cyn"] = "ArmaTek VL-61/79#Cyn",
		["S-1 Seismic Charge"] = "S-1 Seismic Charge",
		["XX-23 Homing Beacon"] = "XX-23 Homing Beacon"
	},
	bomb_cam = {
		["TIE/sa Bomber"] = {
			sec_bank_bomb = 2,
			vec_view_type = 1,
			vector_bombstart = {0.635, -1.98, -1.585},
			xfactor = function(anglediff)
				return -0.635 -- 0
			end,
			yfactor = function(anglediff)
				return -1.98 -- 3 + anglediff * 4
			end,
			zfactor = function(anglediff)
				return -1.585 --2 - anglediff * 8
			end
		},
		["BTL-A4 Y-wing"] = {
			sec_bank_bomb = 2, 
			vec_view_type = 1,
			vector_bombstart = {0.0, -0.7, 1.0},
			xfactor = function(anglediff)
				return 0.0 -- 0
			end,			
			yfactor = function(anglediff)
				return -0.7 -- -2 + anglediff * 4
			end,
			zfactor = function(anglediff)
				return 1.0 -- 2 - anglediff * 3
			end,
			fix_dual_linking = true
		},
		["BTL-LP Longprobe"] = { --does not have a turret but that's fine since AI does not need to fire
			sec_bank_bomb = 1, 
			vec_view_type = 1,
			vector_bombstart = {0.0, -0.7, 1.0},
			xfactor = function(anglediff)
				return 0.0 -- 0
			end,			
			yfactor = function(anglediff)
				return -0.7 -- -2 + anglediff * 4
			end,
			zfactor = function(anglediff)
				return 1.0 -- 2 - anglediff * 3
			end
		},
		["TIE/rc Fighter"] = { --does not have a turret but that's fine since AI does not need to fire
			sec_bank_bomb = 1, 
			vec_view_type = 1,
			vector_bombstart = {-0.95, -1.3, -0.01},
			xfactor = function(anglediff)
				return 0.0 -- 0
			end,			
			yfactor = function(anglediff)
				return -0.7 -- -2 + anglediff * 4
			end,
			zfactor = function(anglediff)
				return 1.0 -- 2 - anglediff * 3
			end
		},
		["TYE-wing"] = { --does not have a turret but that's fine since AI does not need to fire
			sec_bank_bomb = 1, 
			vec_view_type = 1,
			vector_bombstart = {-0.95, -1.3, -0.01},
			xfactor = function(anglediff)
				return 0.0 -- 0
			end,			
			yfactor = function(anglediff)
				return -0.7 -- -2 + anglediff * 4
			end,
			zfactor = function(anglediff)
				return 1.0 -- 2 - anglediff * 3
			end
		},
		["ARC-170 Starfighter"] = {
			sec_bank_bomb = 2, 
			vec_view_type = 1,
			vector_bombstart = {0.0, -1.47, -0.71},
			xfactor = function(anglediff)
				return 0.0 -- 0
			end,			
			yfactor = function(anglediff)
				return -1.47 -- -2 + anglediff * 4
			end,
			zfactor = function(anglediff)
				return -0.71 -- 2 - anglediff * 3
			end,
			fix_dual_linking = true
		},
		["Modified Firespray Gunship"] = {
			sec_bank_bomb = 2, 
			vec_view_type = 2,
			vector_bombstart = {0.0, 2.45, -2.67},
			xfactor = function(anglediff)
				return 0.0 -- 0
			end,			
			yfactor = function(anglediff)
				return 2.45 -- -2 + anglediff * 4
			end,
			zfactor = function(anglediff)
				return -2.67 -- 2 - anglediff * 3
			end,
			fix_dual_linking = true
		}
	}
}

--Code

	function BombHelper:Reset(run_dual_reset)

		self.bomb_camera_on = false
		self.bomb_camera_pos_set = false
		self.check_fire = false
		self.fire_secondary_held = false
		self.ply_class_filtered = ""

		if ba.MultiplayerMode then
			self.is_multiplayer = true
		else
			self.is_multiplayer = false
			if run_dual_reset then
				local ply = FotG:GetPlayerShip()
				if ply ~= nil and ply:isValid() and ply:getBreedName() == "Ship" then
					if ply.SecondaryBanks ~= nil and ply.SecondaryBanks:isValid() then
						ply.SecondaryBanks.DualFire = false
					end
				end
			end
		end

	end

	function BombHelper:CanDropBombs(sclass_str_full)

		local sclass_str = string.filterInvisible(sclass_str_full)
		if self.bomb_cam[sclass_str] ~= nil then 
			return true
		else
			return false
		end

	end

	function BombHelper:GetBombBank(sclass_str_full)

		local sclass_str = string.filterInvisible(sclass_str_full)
		if self.bomb_cam[sclass_str] ~= nil then
			return self.bomb_cam[sclass_str].sec_bank_bomb
		else
			return nil
		end

	end

	function BombHelper:B_Ship_Setup(ship, run_reset)

		--for player: lock and empty player bomb turret 
		--for AI: lock and empty secondary bomb bank and set those OG values to bomb turret

		--sets the bomb turret ammo equal to secondary ammo and then 0s the secondary ammo
		--does not get/check or set secondary lock or turret lock status
		--in FRED: if you want to lock secondaries then you also should lock turrets
		--using this script method so all ships can be easily setup, 
		--  even those ships the player might change to bomber in loadout
		--also recall player bomb turret is locked and emptied in other part of script

		--ba.print("Setting_bombs for "..ship.Name.." ...\n")

		if ship ~= nil and ship:isValid() then

			local sname = ship.Name
			if FotG:IsStandaloneName(sname) then return end

			local sclass_full = ship.Class.Name

			if ship:isPlayer() then 
				--player ship

				--reset, be sure to do this before checking class, 
				--so that change ship class and changing missions clears it 
				if run_reset then
					self:Reset(true)
				end

				--prepare and check player ship class
				self.ply_class_filtered = string.filterInvisible(sclass_full)

				--lock player turret, but only if bomber that drops bombs
				if not self:CanDropBombs(sclass_full) then return end

				if self.is_multiplayer then
					mn.evaluateSEXP("( turret-set-secondary-ammo !"..sname.."! !"..self.bomber_turret_name.."! 0 0 )")
				else
					local bomb_turret = ship[self.bomber_turret_name]
					if bomb_turret ~= nil and bomb_turret:isValid() then
						bomb_turret.SecondaryBanks[1].AmmoLeft = 0
						bomb_turret.TurretLocked = true
					end
				end

			else
				--if AI ship
				if not self:CanDropBombs(sclass_full) then return end

				local bomb_bank_index = self:GetBombBank(sclass_full)
				if bomb_bank_index == nil then return end

				local s_secondaries = ship.SecondaryBanks
				if s_secondaries == nil then return end
				if not s_secondaries:isValid() then return end

				local bomb_bank = s_secondaries[bomb_bank_index]
				
				if bomb_bank == nil then return end
				if not bomb_bank:isValid() then return end
				if bomb_bank.WeaponClass == nil then return end

				local num_bombs = bomb_bank.AmmoLeft

				--get turret ammo version of weapon
				local turret_weapon_name = self.bomb_weapons[bomb_bank.WeaponClass.Name]

				--if bomb_bank.WeaponClass.Name is nil that means either invalid or 0 ammo

				--if the secondary weapon got set to something not supported then ensure that the turret does not have any ammo
				--do not lock it because that would confuse FREDer

				if turret_weapon_name == nil or turret_weapon_name == "" then
					num_bombs = 0
				end

				--convert the weapon if it is supported
				if not self.is_multiplayer then
					--recall changing turret weapon does not register on multiplayer
					local bomb_turret = ship[self.bomber_turret_name]
					--if turret nil or locked though do not bother
					if bomb_turret ~= nil and bomb_turret:isValid() and not bomb_turret.TurretLocked then
						local bomb_turret_bank = bomb_turret.SecondaryBanks[1]
						if bomb_turret_bank	~= nil and bomb_turret_bank:isValid() then
							if turret_weapon_name ~= nil then
								bomb_turret_bank.WeaponClass = tb.WeaponClasses[turret_weapon_name]
							end
							bomb_turret_bank.AmmoLeft = num_bombs
						end
					end

					--in either case 0 out secondary ammo of bomb bank
					--if secondary weapon was supported and bomber turret was setup
					--  then set to 0 since we want to bomb turret to fire
					--or
					--if set to secondary weapon that is not supported, IE by error or FSO bug
					--  then still set it to 0 ammo so it does not fire buggy weapons out
					bomb_bank.AmmoLeft = 0

				elseif multi:isServer() then --add that this only runs in server
					--use sexps in multi since they might work
						--remember: almost all sexps use 0-based bank index, lua are 1
					--set ammo of turret to ammo of bomber secondary bank, then set secondary bank to 0
						--IE move secondary weapons to turret
					mn.evaluateSEXP("( turret-set-secondary-ammo !"..sname.."! !"..self.bomber_turret_name.."! 0 "..num_bombs.." )")
					--make AI have good aim. It still misses though its more accurate then default captain AI
						--mn_run_SEXP_("( change-ai-class !AI_12_Jedi! !"..sname.."! !"..self.bomber_turret_name.."! )")
					--remove all proton bombs
					--bomb_bank_index for anything with proton bombs is 2
					if bomb_bank_index == 2 then
						mn.evaluateSEXP("( set-secondary-ammo !"..sname.."! 1 0 )") --bank to check, number for ammo
					elseif bomb_bank_index == 1 then
						mn.evaluateSEXP("( set-secondary-ammo !"..sname.."! 0 0 )") --bank to check, number for ammo
					end
				end

			end

		end

	end

	function BombHelper:GameStart()

		self:Reset(true)

		for ship in mn.getShipList() do
			self:B_Ship_Setup(ship, false)
		end

	end

	function BombHelper:ViewToggle(reverse)

		if self.is_multiplayer then return end --camera doesn't look good in MP

		local player = FotG:GetPlayerShip()
		if player == nil then return end
		if not player:isValid() then return end
		if player:getBreedName() ~= "Ship" then return end

		-- secret way for players to get rid of flicker
		if GlowmapFlicker.global_enabled then
			GlowmapFlicker:PlyReset()
		end

		--account for ship change sexp
		local pclass = string.filterInvisible(player.Class.Name)
		self.ply_class_filtered = pclass

		local bc = self.bomb_cam[pclass]

		if bc ~= nil then

			-- early out if jumping
			if HyperspaceEnter.is_player_jumping_out or HyperspaceExit.is_player_jumping_in or player:isDying() then
				return
			end

			local bomb_bank_armed = false
			local ply_sec_banks = player.SecondaryBanks
			local bomb_bank_index = bc.sec_bank_bomb
			local bomb_bank = ply_sec_banks[bomb_bank_index]

			if reverse then
				--reverse is always true if we used the control
				if bomb_bank_index == 1 then
					bomb_bank_armed = true --can never un arm if we only have 1 bank
				elseif bomb_bank_index == 2 then --more then 1 secondary banks
					if bomb_bank.Armed then
						--if bomb bank is armed and moving to next bank with key press
						if ply_sec_banks[1].AmmoLeft <= 0 then
							--FSO will not move to other bank b/c it's zero so stay on bomb bank
							bomb_bank_armed = true
						else
							--FSO will switch to other bank since it has ammo left
							bomb_bank_armed = false
						end
					else
						--if bomb bank is not armed, that means FSO will try switching to it if it has ammo
						if bomb_bank.AmmoLeft > 0 then
							bomb_bank_armed = true
						else
							bomb_bank_armed = false
						end
					--someday if ever have ship with 3rd bank as bomb bank we can add that here
					end
				end
			else
				--reverse is nil though if we are just running this function in AutoAim
				if bomb_bank.Armed then
					bomb_bank_armed = true
				else
					bomb_bank_armed = false
				end		
			end

			--check bank and targeting computer status
				--print("zzz-Secondary Auto Aim is: "..tostring(AutoAim.SecondaryAutoAimOn).." \n")
				--print("zzz-Armed Bomb Bank is: "..tostring(bomb_bank_armed).." \n")
			local view_valid = (gr.hasViewmode(VM_INTERNAL) or self.bomb_camera_on)
			if AutoAim.SecondaryAutoAimOn and view_valid and bomb_bank_armed then

				--if bomb bank is selected
				--then make sure bomber camera is turned on
				if not self.bomb_camera_on then 

					mn.evaluateSEXP("( fade-in 300 3 )")

					--lock it to external so hud has chance to show up
					mn.evaluateSEXP("(lock-perspective !true! !1!)")

					--recall using camera sexps works as opposed to things not working with scripted ways
					mn.evaluateSEXP("( set-camera-host !"..player.Name.."! )")

					self.bomb_camera_pos_set = false
					local camera = gr.getCurrentCamera(true)
					if camera ~= nil then
						camera.Position = ba.createVector(bc.xfactor(0), bc.yfactor(0), bc.zfactor(0))
						self.bomb_camera_pos_set = true
					end

					self.bomb_camera_on = true

					--allow hud to show
					mn.evaluateSEXP(" (hud-disable 0) ")

					--update other gauges too, have to do this after setting bools since these internally check those bools
					mn.evaluateSEXP("( hud-set-builtin-gauge-active ( false ) !Center reticle! )")
					--mn.evaluateSEXP("( hud-set-builtin-gauge-active ( false ) !Center reticle! !Wingman status! !Auto speed! !Auto target! !Mini shield! !Player shield! !Target shield! !Escort list! !Mission time! !Kills! !Radar! !Weapon Energy! )")
					AutoAim:UpdateGaugeDrawStatus_Sec()

				end

			else
				--if bomb not selected
				--then make sure bomber camera is turned off
				if self.bomb_camera_on then
					--reset camera and status
					mn.evaluateSEXP("( fade-in 300 3 )")

					--recall using camera sexps works as opposed to things not working with scripted ways
					mn.evaluateSEXP(" (reset-camera !true!) ")

					--lock it back to internal
					mn.evaluateSEXP("(lock-perspective !true! !0!)")
					mn.evaluateSEXP("(lock-perspective !false!)")

					self.bomb_camera_on = false
					self.bomb_camera_pos_set = false

					--ensure hud gets re-enabled!
					mn.evaluateSEXP(" (hud-disable 0) ")

					--update other gauges too, have to do this after setting bools since these internally check those bools
					mn.evaluateSEXP("( hud-set-builtin-gauge-active ( true ) !Center reticle! )")
					--mn.evaluateSEXP("( hud-set-builtin-gauge-active ( true ) !Center reticle! !Wingman status! !Auto speed! !Auto target! !Mini shield! !Player shield! !Target shield! !Escort list! !Mission time! !Kills! !Radar! !Weapon Energy! )")
					AutoAim:UpdateGaugeDrawStatus_Sec()

					--do not delete and then keep making cameras 
					--b/c there is no way to delete so they just keep piling up
					--game restart seems to properly delete them of course
				end

			end
		end

	end

	function BombHelper:Frame()

		if self.is_multiplayer then return end  --camera doesn't look good in MP

		local player = FotG:GetPlayerShip()
		if player == nil then return end
		if not player:isValid() then return end
		if player:getBreedName() ~= "Ship" then return end

		if not MTIME_OVER_P1 then return end

		if self.bomb_camera_on then

			local pclass = self.ply_class_filtered
			if pclass == nil or pclass == "" then return end

			local bc = self.bomb_cam[pclass]
			local bomb_bank = player.SecondaryBanks[bc.sec_bank_bomb]

			--only continue if there is ammo left
			--we can check this with ammo counts, or also check if this bank is armed, since FSO switches to default bank if ammo drained
			if not bomb_bank.Armed then
				--only toggle bomber view off if weapon armed actually switches
				self:ViewToggle()
				return
			end

			local vb = bc.vector_bombstart
			local p_orient = player.Orientation
			local bomb_start_pos = player:findWorldPoint(ba.createVector(vb[1], vb[2], vb[3]))

			local weaponclass = bomb_bank.WeaponClass
			local wep_lifetime = weaponclass.LifeMax
			local wep_speed = weaponclass.Speed
			local get_vec
			local bomb_end_pos
			if bc.vec_view_type == 2 then
				--Slave I style rear launch bombs
				get_vec = p_orient:getFvec(true) * -1
			else
				--TIE Bomber style bottom launch bombs
				get_vec = p_orient:getUvec(true) * -1
			end
			bomb_end_pos = bomb_start_pos + (player.Physics.Velocity * wep_lifetime + (get_vec * wep_speed * wep_lifetime))

			local bomb_range = bomb_start_pos:getDistance(bomb_end_pos)

			local camera = gr.getCurrentCamera(true)
			if camera ~= nil and camera:isValid() then
				local anglediff = (1.0 - (get_vec):getDotProduct((bomb_end_pos - bomb_start_pos):getNormalized()))

				if anglediff == nil then anglediff = 0 end

				local camera_pitch
				if bc.vec_view_type == 2 then
					camera_pitch = 180 - anglediff * 180
				else
					camera_pitch = 90 - anglediff * 90
				end
				if camera_pitch ~= nil then
					camera.Orientation = ba.createOrientation(math.rad(camera_pitch), 0, 0)
				end

				if not self.bomb_camera_pos_set then
					--used to use `anglediff` instead of 0, but it didn't make much sense to change where camera was positioned
					--also this let's us optimize better
					camera.Position = ba.createVector(bc.xfactor(0), bc.yfactor(0), bc.zfactor(0))
					self.bomb_camera_pos_set = true
				end

				--gr.drawString(tostring(anglediff), 50, 50)
				--for i=1,3 do 
					--gr.drawString(tostring(camera.Position[i]), 15, 15+(i*15))
				--end
			end

			--don't drawn if jumping
			if HyperspaceEnter.is_player_jumping_out or HyperspaceExit.is_player_jumping_in then
				return
			end

			local tx, ty = bomb_end_pos:getScreenCoords()

			local found_collide_pos = false
			local collide_distance

			--boolean, number getLineOfSightFirstIntersect(vector from, vector to, [table excludedObjects (expects list of objects, empty by default), boolean testForShields = false, boolean testForHull = true, number threshold = 10.0])
			--Checks whether the to-position is in line of sight from the from-position and returns the distance to the first interruption of the line of sight, disregarding specific excluded objects and objects with a radius of less then threshold.
			--Returns: true and zero if there is line of sight, false and the distance otherwise and intersecting object otherwise.
			local ignore_ships_with_this_radius = 5
			local has_line_of_sight, closest_obstacle_distance, collide_obj = mn.getLineOfSightFirstIntersect(bomb_start_pos, bomb_end_pos, {player}, false, true, ignore_ships_with_this_radius)

			if not has_line_of_sight and collide_obj ~= nil and collide_obj:isValid() then
				-- need to get that actual position on the colliding object
				--checkRayCollision returns vector, collision_info
				local collide_pos, collideinfo = collide_obj:checkRayCollision(bomb_start_pos, bomb_end_pos, false)

				--failsafe check
				if collide_pos ~= nil then
					found_collide_pos = true
					collide_distance = bomb_start_pos:getDistance(collide_pos)
					tx, ty = collide_pos:getScreenCoords()
				end
			end

			--note occulder is drawn in the auto aim script
			--which checks to see if the bomb camera is active
			--AutoAim:DrawSecondary()

			if tx and ty then

				local screen_width = gr.getScreenWidth()
				FotG:SetLineWidth(2, screen_width)
				if found_collide_pos and collide_obj ~= nil and collide_distance ~= nil then
					local r, g, b = collide_obj:getIFFColor(false)
					local radius = FotG:ScaleR(30, screen_width)
					local radius_buf = FotG:ScaleR(15, screen_width)

					local distance_str = tostring(math.floor(collide_distance))

					gr.setColor(r, g, b)
					local y_offset = math.ceil(screen_width * 0.0244) --should be 50 for 2048
					gr.drawString(distance_str, tx - gr.getStringWidth(distance_str) / 2, ty + y_offset)

					if bomb_range > collide_distance then
						gr.setColor(r, g, b, 127)

						local fix_angle = 20 - 30 / 50 * 20

						--gr.drawCircle(radius, tx, ty)
						gr.drawArc(radius, tx, ty, 12 + fix_angle, 78 - fix_angle, false)
						gr.drawArc(radius, tx, ty, 102 + fix_angle, 168 - fix_angle, false)
						gr.drawArc(radius, tx, ty, 192 + fix_angle, 258 - fix_angle, false)
						gr.drawArc(radius, tx, ty, 282 + fix_angle, 348 - fix_angle, false)

						gr.drawArc(radius, tx + radius - radius_buf, ty, -12, 12, true)
						gr.drawArc(radius, tx, ty + radius - radius_buf, 78, 102, true)
						gr.drawArc(radius, tx - radius + radius_buf, ty, 168, 192, true)
						gr.drawArc(radius, tx, ty - radius + radius_buf, 258, 282, true)
					else
						gr.setColor(r, g, b, 127)
						gr.drawCircle(radius, tx, ty, false)
					end
				else
					gr.setColor(255, 255, 255, 127)
					gr.drawCircle(15, tx, ty, false)
				end

				--gr.drawLine(gr.getScreenWidth() / 2, gr.getScreenHeight(), tx, ty)
				--FotG:ResetLineWidth()
			end

		elseif self.check_fire then
			self.check_fire = false
			self:ViewToggle()
		end

	end

--

--Hooks
if not IS_STANDALONE then
	engine.addHook("On Gameplay Start", function() 
			BombHelper:GameStart()
		end
	)

	engine.addHook("On Mission About To End", function() 
			BombHelper:Reset()
		end
	)

	engine.addHook("On Frame", function() 
			BombHelper:Frame()
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Ship Arrive", function() 
			BombHelper:B_Ship_Setup(hv.Ship)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	io.Keybinding["CYCLE_SECONDARY"]:registerHook(function()
		BombHelper:ViewToggle(true) --"Cycle Secondary Weapon Forward"
		--^also called in auto aim script with toggle targeting computer mode
		return false
	end, true, true)

	io.Keybinding["FIRE_SECONDARY"]:registerHook(function()
		--this is a continuous control, so FSO runs hook every frame with hv.Pressed set...
		--so only flag on the initial press otherwise ViewToggle runs every frame
		local pressed = (hv.Pressed == true)
		if pressed and not BombHelper.fire_secondary_held then
			BombHelper.check_fire = true
		end
		BombHelper.fire_secondary_held = pressed
		return false
	end, true, true)

end
