-- This file contains functions needed for capital ship control.

--Code

	CapShipControl = {

		globally_enabled = false,

		controller_shipclass = "Command_Controller_Ship",
		min_radius_to_control = 13, --recall fighters/bombers never allowed,

		capship_default = {
			AfterburnerAccelerationTime = 0,
			AfterburnerVelocityMax = FotG.VECTOR_ZERO, --vector
			SlideAccelerationTime = 0, 
			SlideDecelerationTime = 0, 

			BankingConstant = 0,

			ForwardAccelerationTime = 0.0,
			ForwardDecelerationTime = 0,

			RotationalVelocity = FotG.VECTOR_ZERO, --vector
			RotationalVelocityDamping = 0.0,
			RotationalVelocityDesired = FotG.VECTOR_ZERO, --vector
			RotationalVelocityMax = ba.createVector(3, 3, 3), --vector, in radians per second

			Velocity = FotG.VECTOR_ZERO, --vector
			VelocityDamping = 0.0,  
			VelocityDesired = FotG.VECTOR_ZERO, --vector
			VelocityMax = ba.createVector(0, 0, 500) --vector
		} 

	}

	function CapShipControl:IsShipClassController(shipclassname)

		return (shipclassname == self.controller_shipclass)

	end

	function CapShipControl:ToggleBool(bool)

		self.capship_control_enabled = bool

	end

	function CapShipControl:IsEnabled()

		return self.capship_control_enabled

	end

	function CapShipControl:MissionEnd()

		self:ToggleBool(false)
		self.currently_linked_shipname = nil
		self.currently_linked_ship = nil
		self.player_controller_prepped = false
		self.moveable_offset = nil

	end

	function CapShipControl:SetPlayerStatus(status)

		--set flags if needed
		if self.player_controller_prepped == status then
			return 
		end

		self.player_controller_prepped = status

		local player = FotG:GetPlayerShip()
		if player == nil then return end
		if not player:isValid() then return end
		if player:getBreedName() ~= "Ship" then return end

		player.Stealthed = true
		player:setFlag(true, "invulnerable", "protect-ship", "laser-protect-ship", "missile-protect-ship", "beam-protect-ship")
		player:setFlag(false, "collides")
		player:addShipEffect("Instant Hide", 0)

	end

	function CapShipControl:SetPhysics(player, targetship)

		--just do nil checks since target ship might be lua table
		if player == nil then 
			player = FotG:GetPlayerShip()
		end

		if player == nil then return end

		local player_physics = player.Physics
		local targetship_physics

		--get which target ship values to use
		if targetship ~= nil then
			--actual ship
			targetship_physics = targetship.Physics 
		else
			--unlinked default controller values
			targetship_physics = self.capship_default
		end

		--failsafe
		if player_physics == nil or targetship_physics == nil then return end

		for k_pfield,_ in pairs(self.capship_default) do
			if k_pfield == "ForwardDecelerationTime" then
				--player needs to feel like big ships slow down slowly, but in reality AI has it low to stop on target
				player_physics[k_pfield] = targetship_physics.ForwardAccelerationTime * 3
			else
				player_physics[k_pfield] = targetship_physics[k_pfield]
			end
		end

	end

	function CapShipControl:MissionStart()

		self:MissionEnd()

		if ba.MultiplayerMode then 
			return 
		end

		mn.evaluateSEXP("(fade-in 500 3)")

		local ply = FotG:GetPlayerShip()
		if ply ~= nil and ply:isValid() and not ply:isDying() and not ply:isArrivingWarp() and not ply:isDepartingWarp() then
			if self:IsShipClassController(ply.Class.Name) then
				self:ToggleBool(true)
				self:SetPlayerStatus(true)
				self:SetPhysics()
			end
		end

	end

	function CapShipControl:LinkShip()

		if not self:IsEnabled() or not MTIME_OVER_P1 then return end

		--#TODO
		--unlink current ship (allow player to target)
		--link ship (stop player from targeting)

		--get player target 
		local player = FotG:GetPlayerShip()
		if player == nil then return end
		if not player:isValid() then return end
		if player:getBreedName() ~= "Ship" then return end

		local ptarget_ship = player.Target
		if ptarget_ship == nil then return end
		if not ptarget_ship:isValid() then return end
		if ptarget_ship:getBreedName() ~= "Ship" then return end

		local ptarget_name = ptarget_ship.Name
		if ptarget_name == nil then return end

		local ptarget_class = ptarget_ship.Class
		if ptarget_class == nil then return end

		local is_friendly = (ptarget_ship.Team.Name == "Friendly")

		local ptarget_radius = ptarget_ship.Radius

		--has to be big ship, if not play fail noise
		--if big ship then link when pressed
		local classtype = ptarget_class.Type.Name
		if (classtype == "fighter" or classtype == "bomber") or ptarget_radius < self.min_radius_to_control or not is_friendly then
			FotG:PlaySound_Interface(FotG.sound_index_fail)
			return 
		end

		--do nothing if already linked or do we want to unlink fully?
		if self.currently_linked_shipname == ptarget_name then
			--self:CheckUnlinkShip(self.currently_linked_ship, true)
			return
		end

		--unlink any current ship
		self:CheckUnlinkShip(self.currently_linked_ship, false)

		--actually save linked ship
		self.currently_linked_ship = ptarget_ship
		self.currently_linked_shipname = ptarget_name
		FotG:PlaySound_Interface(FotG.sound_index_success)

		--set player position to host eyepoint and player orientation to host orientation
		player.Orientation = ptarget_ship.Orientation
		player.Position = ptarget_ship.Position

		--ensure any special rotations stop
		local remove_any_rotation = true

		--add to custom paused list
		Movements:Update_Custom_Ship_PausedWaypoint(ptarget_name, true, 1, remove_any_rotation)

		--deal with waypoint caps
		local current_wp_cap = ptarget_ship.WaypointSpeedCap

		--set physics the same as target ship
		self:SetPhysics(player, ptarget_ship)

		--update eyepoint

		local offset = {0, 500, -1 * 500}
		self.moveable_offset = offset
		player:updateSubmodelMoveable('Eyepoint_View_Helper', offset)

		--link with target (add optional objective? or add to roles gauge?)
		--highlight external camera controls
		--allow full unlinking and just full observer mode
		--allow ordering to depart for big ships?
		--if using track waypoint then allow for pause
		--how to leave mission? when player gets permission to leave just allow warp? 
		--will also have to change end mission messages
		--set same physics stats as ship we are controlling

		--all big ships restore default orders control
		--or use actual restore default order and allow ships to have that order once linked

	end

	function CapShipControl:CheckUnlinkShip(ship, play_noise, restore_orders)

		if not self:IsEnabled() then return end

		if ship == nil then return end
		if not ship:isValid() then return end

		local player = FotG:GetPlayerShip()
		if player == nil then return end
		if not player:isValid() then return end
		if player:getBreedName() ~= "Ship" then return end

		self.currently_linked_ship = nil
		self.currently_linked_shipname = nil

		if play_noise then 
			FotG:PlaySound_Interface(FotG.sound_index_success)
		end

		self:SetPhysics()

		--reset eyepoint
		if self.moveable_offset ~= nil then
			local offset = {0, 0, 0}
			for i,v in ipairs(self.moveable_offset) do
				offset[i] = v * -1
			end
			self.moveable_offset = nil
			player:updateSubmodelMoveable('Eyepoint_View_Helper', offset)
		end

		--#TODO
		if restore_orders then
			Movements:Update_Custom_Ship_PausedWaypoint(ship.Name, false, 1)
		end

	end

	function CapShipControl:RunSimulation()

		if not self:IsEnabled() or not MTIME_OVER_P1 then return end

		--#TODO
		--update hitpoints every 0.1 seconds?

		--sync position and orientation
		local linked_ship = self.currently_linked_ship
		local player = FotG:GetPlayerShip()
		if player ~= nil then
			if linked_ship ~= nil and linked_ship:isValid() and linked_ship:getBreedName() == "Ship" then
				if not linked_ship:isDying() and not linked_ship:isArrivingWarp() and not linked_ship:isDepartingWarp() then
					linked_ship.Position = player.Position
					linked_ship.Orientation = player.Orientation
				end
			end
		end

	end

--

--Hooks
if CapShipControl.globally_enabled and not IS_STANDALONE then

	engine.addHook("On Simulation", function() 
			CapShipControl:RunSimulation()
		end
	)

	engine.addHook("On Gameplay Start", function() 
			CapShipControl:MissionStart()
		end
	)

	engine.addHook("On Mission About To End", function() 
			CapShipControl:MissionEnd()
		end
	)

	engine.addHook("On Departure Started", function() 
			CapShipControl:CheckUnlinkShip(hv.Ship)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Ship Death Started", function() 
			CapShipControl:CheckUnlinkShip(hv.Ship)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	io.Keybinding["MULTI_MESSAGE_FRIENDLY"]:registerHook(function()
		CapShipControl:LinkShip()
		return false
	end, true, true)

end