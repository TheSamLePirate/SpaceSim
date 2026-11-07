-- Weapon Hit Detection Script
-- Created by Goober5000
--

WeaponHit = {add_hooks = true, hooks_added = false}

--Code
	function WeaponHit:CheckRegisterHook()

		if ba.MultiplayerMode or IS_STANDALONE then 
			return 
		end

        if not self.hooks_added then 
            self.hooks_added = true

			if self.add_hooks then
				engine.addHook("On Ship Collision", function() 
						WeaponHit:OnShipCollision(hv.Weapon, hv.Ship, hv.ShipSubmodel)
					end,
					{State="GS_STATE_GAME_PLAY"}
				)
			end
        end

	end

	function WeaponHit:createCheck(check_name, weapon_class_name, ship_name, subsys_name)

		self:CheckRegisterHook()

		if self.hitChecks[check_name] then
			ba.warning("WeaponHit: Weapon check " .. check_name .. " already exists!")
			return
		end

		local check = {
			weapon_class_name = weapon_class_name,
			ship_name = ship_name,
			subsys_name = subsys_name,
		}
		self.hitChecks[check_name] = check
		self.Enabled = true
	end
	mn.LuaSEXPs["lua-WeaponHit-createCheck"].Action = function(check_name, weapon_class_name, ship_name, subsys_name)
		if not ba.MultiplayerMode and not IS_STANDALONE then
			WeaponHit:createCheck(check_name, weapon_class_name, ship_name, subsys_name)
		end
	end

	function WeaponHit:removeCheck(check_name)
		self.hitChecks[check_name] = nil

		-- disable when all entries have been removed
		if next(self.hitChecks) == nil then
			self.Enabled = false
		end
	end
	mn.LuaSEXPs["lua-WeaponHit-removeCheck"].Action = function(check_name)
		if not ba.MultiplayerMode and not IS_STANDALONE then
			WeaponHit:removeCheck(check_name)
		end
	end

	function WeaponHit:determineSubsystem(ship, impactPos, submodel)
		local submodel_name = (submodel and submodel:isValid() and submodel.Name)
		local minDist, minSubsys

		-- iterate through subsystems
		for subsys in ship:getSubsystemList() do
			-- direct submodel hit is processed immediately
			if submodel_name and subsys:getModelName() == submodel_name then
				return subsys
			end

			-- find the closest subsystem impact
			local dist = impactPos:getDistance(subsys.WorldPosition)
			if (dist <= subsys.Radius) then
				if minDist == nil or dist < minDist then
					minDist = dist
					minSubsys = subsys
				end
			end
		end
		return minSubsys
	end

	function WeaponHit:processHit(weapon, ship, submodel)
		local colInfo

		-- there is a subtle distinction here: a nil weapon class means "any weapon class" and a nil ship means "any ship", but a nil subsystem means "the hull", not "any subsystem"

		for _, check in pairs(self.hitChecks) do
			-- lazily get collision
			if not colInfo then
				colInfo = weapon:getCollisionInformation()
				if not colInfo:isValid() then
					return
				end
			end

			-- resolve weapon class, if one is specified and exists
			if check.weapon_class_name and not check.weapon_class then
				local temp_weapon_class = tb.WeaponClasses[check.weapon_class_name]
				if temp_weapon_class:isValid() then
					check.weapon_class = temp_weapon_class
				else
					if check.weapon_class_name:lower() ~= "all" then
						ba.warning("WeaponHit: Invalid weapon class name!")
					end
					check.weapon_class_name = nil
				end
			end

			-- resolve ship, if one is specified and ship is present
			if check.ship_name and not check.ship then
				local temp_ship = mn.Ships[check.ship_name]
				if temp_ship:isValid() then
					check.ship = temp_ship
				elseif check.ship_name == "all" then
					check.ship_name = nil
				end
			end

			-- check for a hit
			if (not check.weapon_class_name or check.weapon_class == weapon.Class) and (not check.ship_name or check.ship == ship) then
				local impactPos = colInfo:getCollisionPoint()
				local valid_hit = false

				if not check.subsys_name then
					valid_hit = true
				else
					-- resolve subsystem, if it exists
					if not check.subsys then
						local temp_subsys = ship[check.subsys_name]
						if temp_subsys:isValid() then
							check.subsys = temp_subsys
						else
							if check.subsys_name:lower() ~= "none" and check.subsys_name:lower() ~= "hull" then
								ba.warning("WeaponHit: Invalid subsystem name!")
							end
							check.subsys_name = nil
							valid_hit = true
						end
					end

					-- check whether the hit was actually on the subsystem
					if check.subsys then
						local subsysPos = check.subsys.WorldPosition
						local dist = impactPos:getDistance(subsysPos)

						if (dist <= check.subsys.Radius) then
							valid_hit = true
						end
					end
				end

				if valid_hit then
					check.hitTime = mn.getMissionTime()
					check.hitX = impactPos.x
					check.hitY = impactPos.y
					check.hitZ = impactPos.z
					check.hitWeaponClass = weapon.Class
					check.hitShip = ship
					check.hitSubsystem = self:determineSubsystem(ship, impactPos, submodel)
				end
			end
		end
	end

	function WeaponHit:checkVarType(var, enum, id)
		if var.Type == enum then
			return true
		else
			local text
			if enum == SEXPVAR_TYPE_NUMBER then
				text = 'numeric'
			elseif enum == SEXPVAR_TYPE_STRING then
				text = 'string'
			else
				text = '[unknown]'
			end
			ba.warning("WeaponHit: " .. id .. " variable '" .. var.Name .. "' must have a " .. text .. " type!")
			return false
		end
	end

	function WeaponHit:evalCheck(check_name, variable_pairs)
		local check = self.hitChecks[check_name]
		if not check then
			ba.warning("WeaponHit: Weapon check " .. check_name .. " not found!")
			return -1
		end

		local hit_age = check.hitTime
		if not hit_age or hit_age < 0 then
			hit_age = -1
		else
			hit_age = math.floor(mn.getMissionTime() - hit_age)
		end

		for _, v in ipairs(variable_pairs) do
			local name = v.name:lower()
			local variable = v.variable
			if name == 'age' then
				if self:checkVarType(variable, SEXPVAR_TYPE_NUMBER, name) then
					variable.Value = hit_age or -1
				end
			elseif name == 'x' then
				if self:checkVarType(variable, SEXPVAR_TYPE_NUMBER, name) then
					variable.Value = check.hitX or 0
				end
			elseif name == 'y' then
				if self:checkVarType(variable, SEXPVAR_TYPE_NUMBER, name) then
					variable.Value = check.hitY or 0
				end
			elseif name == 'z' then
				if self:checkVarType(variable, SEXPVAR_TYPE_NUMBER, name) then
					variable.Value = check.hitZ or 0
				end
			elseif name == 'weaponclass' then
				if self:checkVarType(variable, SEXPVAR_TYPE_STRING, name) then
					variable.Value = check.hitWeaponClass and check.hitWeaponClass.Name or ""
				end
			elseif name == 'ship' then
				if self:checkVarType(variable, SEXPVAR_TYPE_STRING, name) then
					variable.Value = check.hitShip and check.hitShip.Name or ""
				end
			elseif name == 'subsystem' then
				if self:checkVarType(variable, SEXPVAR_TYPE_STRING, name) then
					local subsys = check.hitSubsystem
					if subsys then
						variable.Value = subsys.CanonicalName
					else
						variable.Value = "Hull"
					end
				end
			end
		end

		return hit_age
	end
	mn.LuaSEXPs["lua-WeaponHit-evalCheck"].Action = function(check_name, ...)
		if ba.MultiplayerMode or IS_STANDALONE then 
			return 
		end
		local variable_pairs = {}
		for _, v in ipairs(arg) do
			variable_pairs[#variable_pairs + 1] = { name = v[1], variable = v[2] }
		end
		WeaponHit:evalCheck(check_name, variable_pairs)
	end
	mn.LuaSEXPs["lua-WeaponHit-isRecent"].Action = function(threshold, check_name, ...)
		if ba.MultiplayerMode or IS_STANDALONE then 
			return 
		end
		local variable_pairs = {}
		for _, v in ipairs(arg) do
			variable_pairs[#variable_pairs + 1] = { name = v[1], variable = v[2] }
		end
		local hit_age = WeaponHit:evalCheck(check_name, variable_pairs)
		return (hit_age >= 0) and (hit_age <= threshold)
	end

	function WeaponHit:OnStart()

		self.hitChecks = {}
		self.Enabled = false

	end

	function WeaponHit:OnShipCollision(weapon, ship, submodel)

		if weapon and self.Enabled then
			self:processHit(weapon, ship, submodel)
		end

	end


--Hooks
if not IS_STANDALONE and WeaponHit.add_hooks then
	engine.addHook("On Mission Start", function() 
			WeaponHit:OnStart()
		end
	)
end

