
TIE_Burst = {
	is_mission_usable = true,
	is_ply_burst_on = false,
	base_gauge_id = 9, --center reticle
	base_gauge_on = true,
	custom_gauge_key = "Fire_Burst",
	valid_classes = {"T.I.E. Fighter", "TIE/ln Fighter", "TIE/rc Fighter", "TIE Advanced X1", "TIE/sa Bomber", "TIE/sh Shuttle", "TYE-wing"},
	weapon_switches = {
		["SFS L-s1"]={"SFS L-s1 (Burst)", false},
		["SFS L-s7.2"]={"SFS L-s7.2 (Burst)", false},
		["SFS L-s9.3"]={"SFS L-s9.3 (Burst)", false},
		["SFS L-s8.1"]={"SFS L-s8.1 (Burst)", false},
		["SFS L-s1 (Burst)"]={"SFS L-s1", true},
		["SFS L-s7.2 (Burst)"]={"SFS L-s7.2", true},
		["SFS L-s9.3 (Burst)"]={"SFS L-s9.3", true},
		["SFS L-s8.1 (Burst)"]={"SFS L-s8.1", true}				
	}
}

--Code
	function TIE_Burst:ClassValid(classname)

		if classname ~= nil then
			return string.equalAny(classname, self.valid_classes)
		else
			return false
		end

	end

	function TIE_Burst:UpdateGaugeDrawStatus()

		local required_bool

		if self.is_mission_usable then
			if self.is_ply_burst_on and self.base_gauge_on then
				--gauge needs to be showing
				required_bool = true
			else
				--gauge needs to be off
				required_bool = false
			end
		end

		if required_bool ~= nil then
			mn.evaluateSEXP("( hud-set-custom-gauge-active ( "..tostring(required_bool).." ) !"..self.custom_gauge_key.."! )")
		end

	end

	function TIE_Burst:SetGaugeStart()

		local ply = FotG:GetPlayerShip()
		if self.is_mission_usable and ply ~= nil and ply:isValid() and ply:getBreedName() == "Ship" then

			--only do for specific TIE classes, so check shipclass 
			local shipclass = ply.Class
			if shipclass ~= nil then
				if self:ClassValid(shipclass.Name) then
					local current_weapon_name = ply.PrimaryBanks[1].WeaponClass.Name
					local current_weapon_info = self.weapon_switches[current_weapon_name]
					if current_weapon_info ~= nil then
						self.is_ply_burst_on = current_weapon_info[2]
						--default gauge status is off, so only turn on if weapon set to burst weapon
						self:UpdateGaugeDrawStatus()
					end 
				end
			end

		end

	end

	function TIE_Burst:ToggleMode(ship)

		if self.is_mission_usable and ship ~= nil and ship:isValid() and ship:getBreedName() == "Ship" then

			--only do for specific TIE classes, so check shipclass 
			local shipclass = ship.Class
			if shipclass ~= nil then
				if self:ClassValid(shipclass.Name) then
					--if on then switch weapons back and turn off
					--if off then switch weapon to burst mode and turn on
					local current_weapon_name = ship.PrimaryBanks[1].WeaponClass.Name
					local switch_weapon_info = self.weapon_switches[current_weapon_name]
					if switch_weapon_info ~= nil then
						ship.PrimaryBanks[1].WeaponClass = tb.WeaponClasses[switch_weapon_info[1]]
					else
						print("TIE_Burst Error: could not find weapon "..current_weapon_name.." in TIE_Burst.weapon switches table...\n")
					end

					--toggle bool for player
					if ship:isPlayer() then
						self.is_ply_burst_on = not self.is_ply_burst_on
						self:UpdateGaugeDrawStatus()
					end
				end
			end

		end

	end

	function TIE_Burst:CheckSet_BaseGauge()

		if hu.getHUDConfigShowStatus(self.base_gauge_id) then
			self.base_gauge_on = true
		else
			self.base_gauge_on = false
		end

		self:UpdateGaugeDrawStatus()

	end

	function TIE_Burst:StateStart()

		--On State Start runs before On Gameplay Start, 
		--  but On State Start runs every time we come back into the game, even from a paused menu
		--so we do not want to always run the setup scripts, 
		--  but we do want to check the draw HUD status and run a sexp if needed, 
		--  but only after time has passed

		if MTIME_OVER_P1 and not ba.MultiplayerMode then
			self:CheckSet_BaseGauge()
		end

	end

	function TIE_Burst:GameplayStart()

		--turn burst off and see if mission allows us to use burst mode
		self.is_ply_burst_on = false 
		if mn.Events["Disable-TIE-Burst-Fire"]:isValid() or ba.MultiplayerMode then --setting weapon only works if you are server
			self.is_mission_usable = false
		else
			self.is_mission_usable = true
			self:CheckSet_BaseGauge()

			--check if FREDer set the weapon to burst then toggle on the gauge
			self:SetGaugeStart()
		end

	end

	function TIE_Burst:OnAction()

		if self.is_mission_usable and MTIME_OVER_P1 then
			self:ToggleMode(FotG:GetPlayerShip())
		end

	end

	function TIE_Burst:OnEnd()

		self.is_ply_burst_on = false
		self.is_mission_usable = false

	end

--

--Hooks
if not IS_STANDALONE then
	engine.addHook("On Gameplay Start", function() 
			TIE_Burst:GameplayStart()
		end
	)

	engine.addHook("On Mission About To End", function() 
			TIE_Burst:OnEnd()
		end
	)

	engine.addHook("On State Start", function() 
			TIE_Burst:StateStart()
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	io.Keybinding["CYCLE_PRIMARY_WEAPON_SEQUENCE"]:registerHook(function()
		--Play noise to show player they clicked the cycle weapon button for all craft
		--And also run TIE burst fire is needed
		if MTIME_OVER_P1 then
			ad.playGameSound(43)
			TIE_Burst:OnAction()
		end
		return false
	end, true, true)

end