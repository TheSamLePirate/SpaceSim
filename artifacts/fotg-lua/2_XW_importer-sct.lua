-- Mission Importer Script
-- Contains various functions to emulate behaviors from X-Wing
-- Created by Goober5000
--

MissionImporter = {
	add_hooks = true,
	hooks_added = false,

	EnableIdentification = false,

	Boarded = {},
	Captured = {},
	Identified = {},
	Docked = {},
	IdentificationFactor = nil,

	ShipAbbreviations = {
		["T-65c X-wing"] = "X-W",
		["BTL-A4 Y-wing"] = "Y-W",
		["RZ-1 A-wing"] = "A-W",
		["ASF-01 B-wing"] = "B-W",
		["TIE/ln Fighter"] = "T/F",
		["TIE/In Interceptor"] = "T/I",
		["TIE/sa Bomber"] = "T/B",
		["XG-1 Star Wing"] = "GUN",
		["DX-9 Stormtrooper Transport"] = "TRN",
		["Lambda T-4a Shuttle"] = "SHU",
		["DV-3 Freighter"] = "TUG",
		["BFF-1 Container"] = "CN/",
		["BFF-1 Freighter"] = "FRT",
		["Liberty Type Star Cruiser"] = "CRS",
		["Nebulon-B Frigate"] = "FRG",
		["CR90 Corvette#Reb"] = "CRV",
		["Imperial Star Destroyer"] = "ISD"	
	}
}

--Code
	function MissionImporter:ShipAttackedInit(shipname)
		WeaponHit:createCheck(shipname, nil, shipname)
	end
	mn.LuaSEXPs["fotg-ship-attacked-init"].Action = function(shipname)
		MissionImporter:ShipAttackedInit(shipname)
	end

	function MissionImporter:WingAttackedInit(wing)
		if not wing or not wing:isValid() then
			return
		end
		for i = 1, #wing do
			self:ShipAttackedInit(wing[i].Name)
		end
	end
	mn.LuaSEXPs["fotg-wing-attacked-init"].Action = function(wing)
		MissionImporter:WingAttackedInit(wing)
	end

	function MissionImporter:IsShipAttacked(ship)
		if not ship or not ship:isValid() then
			return false
		end
		local checks = WeaponHit.hitChecks
		if checks then
			local check = checks[ship.Name]
			if check and check.hitTime and check.hitTime > 0 then
				return true
			end
		end
		return false
	end
	mn.LuaSEXPs["fotg-is-ship-attacked"].Action = function(ship)
		return MissionImporter:IsShipAttacked(ship)
	end

	function MissionImporter:IsWingAttacked(wing)
		if not wing or not wing:isValid() then
			return false
		end
		for i = 1, #wing do
			if self:IsShipAttacked(wing[i]) then
				return true
			end
		end
		return false
	end
	mn.LuaSEXPs["fotg-is-wing-attacked"].Action = function(wing)
		return MissionImporter:IsWingAttacked(wing)
	end

	function MissionImporter:SetShipBoarded(flag, ship)
		if not ship or not ship:isValid() then
			return
		end
		self.Boarded[ship.Name] = flag
	end
	mn.LuaSEXPs["fotg-set-ship-boarded"].Action = function(flag, ship)
		MissionImporter:SetShipBoarded(flag, ship)
	end

	function MissionImporter:IsShipBoarded(ship)
		if not ship or not ship:isValid() then
			return false
		end
		return self.Boarded[ship.Name] or false
	end
	mn.LuaSEXPs["fotg-is-ship-boarded"].Action = function(ship)
		return MissionImporter:IsShipBoarded(ship)
	end

	function MissionImporter:IsWingBoarded(wing)
		if not wing or not wing:isValid() then
			return false
		end
		for i = 1, #wing do
			if self:IsShipBoarded(wing[i]) then
				return true
			end
		end
		return false
	end
	mn.LuaSEXPs["fotg-is-wing-boarded"].Action = function(wing)
		return MissionImporter:IsWingBoarded(wing)
	end

	function MissionImporter:SetShipCaptured(flag, ship, capturing_ship)
		if not ship or not ship:isValid() then
			return
		end
		if not capturing_ship or not capturing_ship:isValid() then
			return
		end
		self.Captured[ship.Name] = flag
		if flag then
			ship.Team = capturing_ship.Team
			AddShipInfo:SetText(ship.Name, "CAPTURED")
			self:SetShipBoarded(flag, ship)
			self:SetShipIdentified(flag, ship)
		else
			AddShipInfo:ClearText(ship.Name)
		end
	end
	mn.LuaSEXPs["fotg-set-ship-captured"].Action = function(flag, ship, capturing_ship)
		MissionImporter:SetShipCaptured(flag, ship, capturing_ship)
	end

	function MissionImporter:IsShipCaptured(ship)
		if not ship or not ship:isValid() then
			return false
		end
		return self.Captured[ship.Name] or false
	end
	mn.LuaSEXPs["fotg-is-ship-captured"].Action = function(ship)
		return MissionImporter:IsShipCaptured(ship)
	end

	function MissionImporter:IsWingCaptured(wing)
		if not wing or not wing:isValid() then
			return false
		end
		for i = 1, #wing do
			if self:IsShipCaptured(wing[i]) then
				return true
			end
		end
		return false
	end
	mn.LuaSEXPs["fotg-is-wing-captured"].Action = function(wing)
		return MissionImporter:IsWingCaptured(wing)
	end
	
	function MissionImporter:PercentWingCaptured(percent, wing)
		if not wing or not wing:isValid() then
			return false
		end
		if percent > 100 or percent < 0 then
			return false
		end
		local count = 0
		for i = 1, #wing do
			if self:IsShipCaptured(wing[i]) then
				count = count + 1
			end
		end
		if count >= #wing*percent/100 then
			return true
		end
		return false
	end
	mn.LuaSEXPs["fotg-percent-wing-captured"].Action = function(wing)
		return MissionImporter:PercentWingCaptured(wing)
	end

	function MissionImporter:IsShipDisabled(ship)
		-- TODO
		return false
	end
	mn.LuaSEXPs["fotg-is-ship-disabled"].Action = function(ship)
		return MissionImporter:IsShipDisabled(ship)
	end

	function MissionImporter:IsWingDisabled(wing)
		if not wing or not wing:isValid() then
			return false
		end
		for i = 1, #wing do
			if self:IsShipDisabled(wing[i]) then
				return true
			end
		end
		return false
	end
	mn.LuaSEXPs["fotg-is-wing-disabled"].Action = function(wing)
		return MissionImporter:IsWingDisabled(wing)
	end

	function MissionImporter:SetShipIdentified(flag, ship, skip_msg)
		if not ship or not ship:isValid() then
			return
		end

		self.Identified[ship.Name] = flag
		ship:setFlag(flag, "cargo-known")

		if flag then
			ship.DisplayName = ""
			if not skip_msg then
				self:SendStatusMessage(self:GetStatusShipName(ship) .. " has been identified")
			end
		else
			ship.DisplayName = "UNKNOWN"
		end
	end
	mn.LuaSEXPs["fotg-set-ship-identified"].Action = function(flag, ship)
		MissionImporter:SetShipIdentified(flag, ship)
	end

	function MissionImporter:IsShipIdentified(ship)
		if not ship or not ship:isValid() then
			return false
		end
		return self.Identified[ship.Name] or false
	end
	mn.LuaSEXPs["fotg-is-ship-identified"].Action = function(ship)
		return MissionImporter:IsShipIdentified(ship)
	end

	function MissionImporter:IsWingIdentified(wing)
		if not wing or not wing:isValid() then
			return false
		end
		for i = 1, #wing do
			if self:IsShipIdentified(wing[i]) then
				return true
			end
		end
		return false
	end
	mn.LuaSEXPs["fotg-is-wing-identified"].Action = function(wing)
		return MissionImporter:IsWingIdentified(wing)
	end

	function MissionImporter:PercentShipsIdentified(percent, ships)
		if percent > 100 or percent < 0 then
			return false
		end
		local count = 0
		for i = 1, #ships do
			if self:IsShipIdentified(ships[i]) then
				count = count + 1
			end
		end
		if count >= #ships*percent/100 then
			return true
		end
		return false
	end
	mn.LuaSEXPs["fotg-percent-ships-identified"].Action = function(percent, ...)
		local ships = {}
		for i,v in ipairs(arg) do
			ships[#ships+1] = v[1]
		end
		return MissionImporter:PercentShipsIdentified(percent, ships)
	end

	function MissionImporter:PercentWingIdentified(percent, wing)
		if not wing or not wing:isValid() then
			return false
		end
		return self:PercentShipsIdentified(percent, wing)
	end
	mn.LuaSEXPs["fotg-percent-wing-identified"].Action = function(percent, wing)
		return MissionImporter:PercentWingIdentified(percent, wing)
	end
	
	function MissionImporter:IsShipDocked(ship)
		if not ship or not ship:isValid() then
			return false
		end
		if self.Docked[ship.Name] then
			return true
		end
		if ship:isDocked() then
			self.Docked[ship.Name] = true
			return true
		end
		return false
	end
	mn.LuaSEXPs["fotg-is-ship-docked"].Action = function(ship)
		return MissionImporter:IsShipDocked(ship)
	end
	
	function MissionImporter:PercentWingDocked(percent, wing)
		if not wing or not wing:isValid() then
			return false
		end
		if percent > 100 or percent < 0 then
			return false
		end
		local count = 0
		for i = 1, #wing do
			if self:IsShipDocked(wing[i]) then
				count = count + 1
			end
		end
		if count >= #wing*percent/100 then
			return true
		end
		return false
	end
	mn.LuaSEXPs["fotg-percent-wing-docked"].Action = function(wing)
		return MissionImporter:PercentWingDocked(wing)
	end

	-- utility functions
	function MissionImporter:GetStatusShipName(ship)
		-- three-letter prefix
		local classname = string.filterInvisible(ship.Class.Name)
		local abbrev = self.ShipAbbreviations[classname]
		if abbrev then
			abbrev = abbrev .. " "
		else
			abbrev = ""
		end

		-- identified, or not
		local name = ship.Name
		if not self.Identified[name] then
			local wing = ship:getWing()
			if wing:isValid() then
				name = "????" .. name:sub(#wing.Name + 1)
			else
				name = "????"
			end
		end

		return abbrev .. name
	end

	function MissionImporter:SendStatusMessage(str)
		if not self.StatusMessage then
			self.StatusMessage = mn.Messages["XWIStatusMessage"]
			if not self.StatusMessage or not self.StatusMessage:isValid() then
				self.StatusMessage = mn.addMessage("XWIStatusMessage", " ")
			end
		end
		if self.StatusMessage:isValid() then
			self.StatusMessage.Message = str
			mn.sendMessage("Computer", self.StatusMessage)
		end
	end

	function MissionImporter:ShouldAutomaticallyIdentify(ship)
		-- always identify fighters and bombers
		local typename = ship.Class.Type.Name:lower()
		if typename == "fighter" or typename == "bomber" then
			return true
		end

		-- otherwise just identify ships on the same team
		local ply = FotG:GetPlayerShip()
		local pl
		if ply ~= nil and ply:isValid() and ply:getBreedName() == "Ship" then
			pl = ply.Team
		else
			pl = {}
		end
		return ship.Team == pl.Team
	end


    function MissionImporter:CheckRegisterHooks()

        if not self.hooks_added then 
            self.hooks_added = true

			engine.addHook("On Ship Arrive", function() 
					MissionImporter:OnShipArrive(hv.Ship)
				end,
				{State="GS_STATE_GAME_PLAY"}
			)

			engine.addHook("On Frame", function() 
					MissionImporter:OnFrame()
				end,
				{State="GS_STATE_GAME_PLAY"}
			)
        end

    end

	function MissionImporter:Reset()

		self.EnableIdentification = false

		self.Boarded = {}
		self.Captured = {}
		self.Identified = {}
		self.Docked = {}
		self.IdentificationFactor = nil

	end

	function MissionImporter:OnStart()

		self:Reset()

		if ba.MultiplayerMode or IS_STANDALONE then
			return 
		end

		if mn.Events["X-Wing Style Identification"]:isValid() then
			self.EnableIdentification = true
			self:CheckRegisterHooks()
		end

		local ply = FotG:GetPlayerShip()
		if ply == nil then return end
		if not ply:isValid() then return end
		if ply:getBreedName() ~= "Ship" then return end 

		-- these are legacy marker events and no longer added to imported missions
		if mn.Events["XWI Import"]:isValid() then
			self.EnableIdentification = true
			self:CheckRegisterHooks()
			ply:setFlag(true, "cannot-perform-scan")
		end
		if mn.Events["No FreeSpace Style Scanning"]:isValid() then
			ply:setFlag(true, "cannot-perform-scan")
		end

	end

	function MissionImporter:OnShipArrive(ship)

		if self.EnableIdentification and not FotG:IsDummyClass(ship.Class.Name) then
			self:SetShipIdentified(self:ShouldAutomaticallyIdentify(ship), ship, true)
		end

	end

	function MissionImporter:OnFrame()

		if self.EnableIdentification then
			local pl = FotG:GetPlayerShip()
			if pl == nil then return end
			if not pl:isValid() then return end
			if pl:getBreedName() ~= "Ship" then return end 

			local pl_pos = pl.Position

			-- do this once when the player launches into the game
			if not self.IdentificationFactor then
				for thisShip in mn.getShipList() do
					-- only do identification for ships that don't already have it set, just in case the mission designer added events for this
					if self.Identified[thisShip.Name] == nil then
						self:SetShipIdentified(self:ShouldAutomaticallyIdentify(thisShip), thisShip, true)
					end
				end
				if pl.Class.Name:starts("RZ-1 A-wing") then
					self.IdentificationFactor = 2
				else
					self.IdentificationFactor = 1
				end
			end

			-- every frame thereafter, check for ship identification
			local thisShip = pl.Target
			if thisShip and thisShip:getBreedName() == "Ship" and not self.Identified[thisShip.Name] then
				local classname = string.filterInvisible(thisShip.Class.Name)
				local abbrev = self.ShipAbbreviations[classname]
				local dist = thisShip.Radius * self.IdentificationFactor
				if dist < 75 or abbrev == "CRS" or abbrev == "ISD" then
					dist = dist * 2
				end
				if thisShip.Position:getDistanceSquared(pl_pos) < dist * dist then
					self:SetShipIdentified(true, thisShip)
				end
			end
		end

	end


--Hooks
if not IS_STANDALONE and MissionImporter.add_hooks then
	engine.addHook("On Mission Start", function() 
			MissionImporter:OnStart()
		end
	)

	engine.addHook("On Mission About To End", function() 
			MissionImporter:Reset()
		end
	)
end