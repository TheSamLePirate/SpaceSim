-- This file contains the code for switching between different astromechs and astromech chatter

Astromechs = {
	base_textures = {
		diffuse = "r2red", reflect = "r2red-reflect", normal = "r2red-normal"
	},

	droid_types = {
		{texture_replace = {diffuse = "r2red", reflect = "", normal = ""},                            sub_rotation = {0, 0, 0}}, --1. 
		{texture_replace = {diffuse = "r2blue", reflect = "", normal = ""},                           sub_rotation = {0, 0, 0}}, --2. 
		{texture_replace = {diffuse = "r2orange", reflect = "", normal = ""},                         sub_rotation = {0, 0, 0}}, --3. 

		{texture_replace = {diffuse = "r5red", reflect = "r5red-reflect", normal = "r5red-normal"},     sub_rotation = {math.rad(240), 0, 0}}, 	 --4. 
		{texture_replace = {diffuse = "r5blue", reflect = "r5red-reflect", normal = "r5red-normal"},    sub_rotation = {math.rad(240), 0, 0}}, 	 --5. 
		{texture_replace = {diffuse = "r5orange", reflect = "r5red-reflect", normal = "r5red-normal"},  sub_rotation = {math.rad(240), 0, 0}},    --6. 

		{texture_replace = {diffuse = "r6red", reflect = "r6red-reflect", normal = "r6red-normal"},     sub_rotation = {math.rad(120), 0, 0}}, 	 --7. 
		{texture_replace = {diffuse = "r6blue", reflect = "r6red-reflect", normal = "r6red-normal"},    sub_rotation = {math.rad(120), 0, 0}},	 --8. 
		{texture_replace = {diffuse = "r6orange", reflect = "r6red-reflect", normal = "r6red-normal"},  sub_rotation = {math.rad(120), 0, 0}},    --9.
	},

	droid_sound_option = 1,
	droid_sound_types = { --a (classic R2-D2) then b (generic astromech)
		yes = {122, 124},
		no = {123, 125},
		upset = {130, 132},
		idle = {131, 133}
	}

}

--Code

	function Astromechs:GetSoundIndex(sound_type)

		local sound_type = self.droid_sound_types[sound_type]
		local def_sound_index = 2
		if sound_type ~= nil then
			return sound_type[self.droid_sound_option] or def_sound_index
		else
			return def_sound_index
		end

	end

	function Astromechs:ClassHas(shipclass)

		local base_class_tbl = {"T-65c X-wing", "BTL-A4 Y-wing", "ZY-wing", "N-1 Starfighter", "Star Speeder 3000", "A-3 V-wing Starfighter"}
		return string.equalAny(string.filterInvisible(shipclass), base_class_tbl)

	end

	function Astromechs:ShipHas(ship)

		local answer = false
		if ship ~= nil and ship:isValid() and ship:getBreedName() == "Ship" then
			answer = self:ClassHas(ship.Class.Name)
		end
		return answer

	end

	function Astromechs:ResetScreams(on_mission_start)

		if ba.MultiplayerMode then return end

		local time_int = 10
		self.last_check_time = -1 * time_int --so we can scream at the start of the mission if needed
		self.time_interval_check = time_int
		self.hp_interval_check = 20

		-- set type of astromech noise
		self.droid_sound_option = 1

		local chatter_enabled = false	
		local starting_hp = 100
		local ply = FotG:GetPlayerShip() 
		if on_mission_start and ply ~= nil and ply:isValid() and ply:getBreedName() == "Ship" then
			starting_hp = (ply.HitpointsLeft / ply.HitpointsMax)*100 or 100
			if self:ShipHas(ply) then
				chatter_enabled = true
			end
		end

		self.last_check_hp = starting_hp

		self.chatter_enabled = chatter_enabled

	end

	function Astromechs:CheckScreams(forcescream)
	
		if ba.MultiplayerMode then return end
	
		--if in craft with R2
		if not self.chatter_enabled then return end
	
		if forcescream == nil then
			forcescream = false
		end

		local ply = FotG:GetPlayerShip()

		--if valid
		if ply ~= nil and ply:isValid() and ply:getBreedName() == "Ship" then
			--if enough time has elapsed
			local mtime = mn.getMissionTime()
			if mtime > (self.last_check_time + self.time_interval_check) then
				--if hitpoints are different enough
				local hp = (ply.HitpointsLeft / ply.HitpointsMax)*100 or 100
				if hp < (self.last_check_hp - self.hp_interval_check) or forcescream then
					self.last_check_time = mtime
					self.last_check_hp = hp
					--do a scream
					ad.playGameSound(self:GetSoundIndex("upset"))
				end
			end
		end		
	
	end

	function Astromechs:ShipSetup(ship, droidtype_num, update_textures)

		-- sets the astromech color and model
		-- depending on specified type

		if ba.MultiplayerMode then return end

		-- shipHas also checks for ship validity
		if self:ShipHas(ship) and type(droidtype_num) == "number" then

			--extra checks
			local astromech = ship["Astromech"]
			if astromech == nil then return end

			if droidtype_num <= 0 then return end
			local droid_info = self.droid_types[droidtype_num]
			if droid_info == nil then return end

			--set orientation and texture
			local angles = droid_info.sub_rotation
			astromech.Orientation = ba.createOrientation(angles[1], angles[2], angles[3])

			if not update_textures then return end

			local new_textures = droid_info.texture_replace
			local sname = ship.Name

			for k_textype, v_basetexname in pairs(self.base_textures) do
				local new_tex_name = new_textures[k_textype]
				if new_tex_name ~= nil and new_tex_name ~= "" then
					mn.evaluateSEXP("( replace-texture !"..v_basetexname.."! !"..new_tex_name.."! !"..sname.."! )")
				end
			end

		end

	end

	mn.LuaSEXPs["ship-has-astromech-unit"].Action = function (ship)

		if ba.MultiplayerMode then 
			return false
		else
			return Astromechs:ShipHas(ship)
		end

	end

	mn.LuaSEXPs["play-astromech-chatter"].Action = function (num)

		if ba.MultiplayerMode then return end

		if type(num) ~= "number" then return end
		--still want chatter to play even if not enabled
		--if not Astromechs.chatter_enabled then return end

		local num_to_keys = {"no", "yes", "idle", "upset"}
		local key = num_to_keys[num]
		if key == nil then return end
		ad.playGameSound(Astromechs:GetSoundIndex(key))

	end

	mn.LuaSEXPs["set-astromech-chatter"].Action = function (num_toggle, num_voice)

		if ba.MultiplayerMode then return end

		if type(num_toggle) == "number" then

			local lboolean = false

			--option 0 = all off
			if num_toggle == 0 then 
				lboolean = false
			end

			--option 1 = only on for R2 capable ships 
			if num_toggle == 1 then 
				if Astromechs:ShipHas(FotG:GetPlayerShip()) then
					lboolean = true
				end
			end

			--option 2 = on for any kind of ship
			if num_toggle == 2 then 
				lboolean = true
			end

			Astromechs.chatter_enabled = lboolean

			--set voice type
			if type(num_voice) ~= "number" then
				num_voice = 1
			end

			if num_voice == 1 or num_voice == 2 then
				Astromechs.droid_sound_option = num_voice
			end

		end	

	end

	mn.LuaSEXPs["change-astromech-type"].Action = function(droidtype_num, ...)

		if ba.MultiplayerMode or #arg <= 0 or droidtype_num == nil then return end

		for _, value in ipairs(arg) do
			local ship = value[1]
			if ship ~= nil and ship:isValid() then
				Astromechs:ShipSetup(ship, droidtype_num, true)
			end
		end

	end

--

--Hooks
if not IS_STANDALONE then 
	engine.addHook("On Gameplay Start", function() 
			if not ba.MultiplayerMode then
				Astromechs:ResetScreams(true)
			end
		end
	)

	engine.addHook("On Mission About To End", function() 
			if not ba.MultiplayerMode then
				Astromechs:ResetScreams(false)
			end
		end
	)

	engine.addHook("On Pain Flash", function() 
			if not ba.MultiplayerMode then
				if hv.Pain_Type == 1 then --1 is for hull, 0 is for shields
					Astromechs:CheckScreams()
				end
			end
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	if FotG.use_ship_collision_scripts then
		engine.addHook("On Ship Collision", function() 
				if not ba.MultiplayerMode then
					local ply = FotG:GetPlayerShip()
					if hv.Self ~= nil and ply ~= nil and hv.Self == hv.Player then
						Astromechs:CheckScreams(true)
					end
				end
			end,
			{State="GS_STATE_GAME_PLAY"}
		)
	end
end