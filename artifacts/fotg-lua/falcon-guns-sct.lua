Falcon_Guns = {
	use_energy_drainer = false,

	energy_consumed = 0.325, --from weapons table for half of Manual Control (since turret shoots 2 shots at once)
	turret_name_top = "TurretTop",
	turrent_name_bottom = "TurretBottom",

	--^recall that the string index for the ss is this name, not the alt ss name
	enabled = false,
}

--Code
	function Falcon_Guns:CurrentArmed(ship)

		local num_pbanks = #ship.PrimaryBanks
		local current_armed_bank = 1
		for i=1,num_pbanks do 
			if ship.PrimaryBanks[i].Armed then 
				current_armed_bank = i 
			end
		end

		return current_armed_bank

	end

	function Falcon_Guns:Controller(ship, option)

		local sub_turret_top = ship[self.turret_name_top]
		local sub_turret_bottom = ship[self.turrent_name_bottom]

		--manual: turn off both turrets and enable primaries
		if option == "manual" or option == 1 then 
			--turn off turrets
			-- Make the AI lose the current target and not pick new ones
			sub_turret_top:targetingOverride(true)
			sub_turret_top.Target = ship
			sub_turret_bottom:targetingOverride(true)
			sub_turret_bottom.Target = ship
			--are not using turret locked atm because the turrets don't reset position properly
			--ship[i].TurretLocked = true
			-- Rotate the turret to the default orientation
			sub_turret_top:rotateTurret(FotG.VECTOR_Z1, true)
			sub_turret_bottom:rotateTurret(FotG.VECTOR_Z1, true)

			--make sure they are alive and rotated back then enable primaries
			local waittime = 3
			if sub_turret_top.HitpointsLeft > 0 and sub_turret_bottom.HitpointsLeft > 0 then 
				if sub_turret_top:getTurretHeading():getDistance(FotG.VECTOR_Z1) < 0.1 and sub_turret_bottom:getTurretHeading():getDistance(FotG.VECTOR_Z1) < 0.1 then 
					waittime = 0.1			
				end
				async.run(function() 
					async.await(mn.waitAsync(waittime))
					ship:setFlag(false, "primaries-locked")
					--play noise?
				end)
			end
		end
		
		--mixed: top turret is manual and bottom is auto 
		if option == "mixed" or option == 2 then 
			sub_turret_top:targetingOverride(true)
			sub_turret_top.Target = ship
			--ship[i].TurretLocked = true
			sub_turret_top:rotateTurret(FotG.VECTOR_Z1, true)
			--make sure TurretTop is alive and rotated back then enable primaries
			local waittime = 3
			if sub_turret_top.HitpointsLeft > 0 then 
				if sub_turret_top:getTurretHeading():getDistance(FotG.VECTOR_Z1) < 0.1 then 
					waittime = 0.1			
				end
				async.run(function()
					async.await(mn.waitAsync(waittime))
					ship:setFlag(false, "primaries-locked")
				end)
			end
			--reenable bottom turret
			--ship[i].TurretLocked = false
			sub_turret_bottom:targetingOverride(false)
		end
		
		--auto: gun selected only, enable both turrets 
		if option == "gunner" or option == 3 then 
			--ship[i].TurretLocked = false
			sub_turret_top:targetingOverride(false)
			sub_turret_bottom:targetingOverride(false)
			ship:setFlag(true, "primaries-locked")
		end 

	end

	function Falcon_Guns:ValidPly(check_ship)

		--checks if given ship is player ship, which must be the Falcon
		--if check ship is specified it makes sure that ship is the player ship
		--if check ship is nil, then assumes check ship is player ship

		--does not work in multi
		if ba.MultiplayerMode then return false end

		local answer = false
		local player = FotG:GetPlayerShip()
		if player ~= nil and player:isValid() and player:getBreedName() == "Ship" and player.Class ~= nil and player.Class.Name == "Modified YT-1300 Freighter" then
			if check_ship then
				--if we are checking a specific ship it might be on a death or depart hook, and might not be the player, so we need to check if it's the player
				if check_ship ~= nil and check_ship:isValid() and check_ship:getBreedName() == "Ship" and check_ship:isPlayer() then
					answer = true
				end
			else
				--if check ship was nil then we are just checking the player, and parent if check already did that
				answer = true
			end
		end
		
		return answer

	end

	function Falcon_Guns:End()

		Falcon_Guns.enabled = false
		Falcon_guns_MainWeapon = nil
		Falcon_guns_SilentWeapon = nil

	end

	function Falcon_Guns:Start()

		self:End()

		if self:ValidPly() then 
			--find which bank is armed and run function accordingly 
			local player = FotG:GetPlayerShip()
			if player == nil then return end
			if not player:isValid() then return end
			if player:getBreedName() ~= "Ship" then return end 

			self:Controller(player, self:CurrentArmed(player))
			self.enabled = true
			Falcon_guns_MainWeapon = player.PrimaryBanks[1].WeaponClass
			Falcon_guns_SilentWeapon = tb.WeaponClasses["Silent Turret"]
			self.active_gun_wep_name = Falcon_guns_MainWeapon.Name
			self.silent_gun_wep_name = "Silent Turret"
		else
			self.enabled = false
		end

	end

	function Falcon_Guns:Weapon_Select(ship)

		if self.enabled and self:ValidPly(ship) then
			--find which bank is armed and run function accordingly 
			self:Controller(ship, self:CurrentArmed(ship))
		end

	end

	function Falcon_Guns:Turret_Fired(ship, weapon)

		--this decreases the players weapon energy reserves whenever the AI fires the turret
		--whole thing works because the turret will keep firing (just won't see anything)
		--then when player energy is high enough it turns back on
		if self.enabled and self:ValidPly(ship) then

			local wep_class_name = weapon.Class.Name
			--if turret has already been 'turned off' then see if the energy left is high enough and turn it back on
			if wep_class_name == self.silent_gun_wep_name then
				if ship.WeaponEnergyLeft >= Falcon_Guns.energy_consumed then
					ship[self.turret_name_top].PrimaryBanks[1].WeaponClass = Falcon_guns_MainWeapon
					ship[self.turrent_name_bottom].PrimaryBanks[1].WeaponClass = Falcon_guns_MainWeapon
				end

			--if turret is firing decrease used energy from player's weapons pool
			--if it gets below 0 then switch the turret weapon to one that doesn't fire anything 
			elseif wep_class_name == self.active_gun_wep_name then
				local remaning_energy = ship.WeaponEnergyLeft - Falcon_Guns.energy_consumed
				ship.WeaponEnergyLeft = remaning_energy
				if remaning_energy < Falcon_Guns.energy_consumed then
					ship[self.turret_name_top].PrimaryBanks[1].WeaponClass = Falcon_guns_SilentWeapon
					ship[self.turrent_name_bottom].PrimaryBanks[1].WeaponClass = Falcon_guns_SilentWeapon
				end
			end
		end	

	end

	function Falcon_Guns:PlyGoneCheck(ship, isdying)

		if self.enabled and self:ValidPly(ship) then
			--if player is not truly dying do not reset (ie do not reset if only respawning)
			if isdying and Respawner:RespawnAllowed() and ship:isPlayer() then
				return
			else
				self.enabled = false
			end
		end

	end

--

--Hooks
if not IS_STANDALONE then 
	engine.addHook("On Gameplay Start", function() 
			Falcon_Guns:Start()
		end
	)

	engine.addHook("On Mission About To End", function() 
			Falcon_Guns:End()
		end
	)


	engine.addHook("On Weapon Selected", function() 
			Falcon_Guns:Weapon_Select(hv.User)
		end,
		{State="GS_STATE_GAME_PLAY", ["Ship class"]="Modified YT-1300 Freighter"}
	)

	engine.addHook("On Ship Death Started", function() 
			Falcon_Guns:PlyGoneCheck(hv.Ship, true)
		end,
		{State="GS_STATE_GAME_PLAY", ["Ship class"]="Modified YT-1300 Freighter"}
	)

	engine.addHook("On Ship Depart", function() 
			Falcon_Guns:PlyGoneCheck(hv.Ship)
		end,
		{State="GS_STATE_GAME_PLAY", ["Ship class"]="Modified YT-1300 Freighter"}
	)

	if Falcon_Guns.use_energy_drainer then

		engine.addHook("On Turret Fired", function() 
				Falcon_Guns:Turret_Fired(hv.Ship, hv.Weapon)
			end,
			{State="GS_STATE_GAME_PLAY", ["Ship class"]="Modified YT-1300 Freighter"}
		)

	end
end
