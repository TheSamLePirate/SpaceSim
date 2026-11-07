-- This file contains the script which randomly destroys subsystems as a big ship dies. It is specifically for Fate of the Galaxy.

SubDying = {
	global_allowed = true,
	is_enabled = true,
	min_radius = 40,
	min_subsystems = 6
}

--Code
	function SubDying:Check_and_Start_Destroying(ship)

		if not self.is_enabled then return end
		if not MTIME_OVER_P1 then return end
		if ship == nil then return end
		if not ship:isValid() or ship:isPlayer() then return end

		local num_ss = #ship
		if num_ss < self.min_subsystems then return end
		local ship_radius = ship.Radius or 0
		if ship_radius < self.min_radius then return end

		--only run if not in potato mode
		if FotG.NebulaSliderCurrent <= FotG.NebulaLowSetting then 
			mn.evaluateSEXP("( turret-lock-all !"..ship.Name.."! )")
			return 
		end

		local death_time = ship:getTimeUntilExplosion()
		if death_time < 1.0 then
			ba.print("SubDying death time is < 1.0, so exiting early...\n")
			return
		end

		-- Curve: (180, 0.15) linear to (1200, 1.0) constant
		local x1, x2, y1, y2 = 180, 1200, 0.15, 1.0
		local t = math.min(math.max(ship_radius - x1, 0) / (x2 - x1), 1)  -- clamp to [0,1]
		local intensity = y1 + t * (y2 - y1)

		-- Build kill list and lock turrets in one pass
		local kill_list = {}
		local num_ss_to_kill = 0
		local radius_threshold = ship_radius * 0.1  -- subsys.Radius * 10 <= ship_radius
		for i = 1, num_ss do
			local subsys = ship[i]
			if subsys ~= nil and subsys.HitpointsMax > 0 and subsys.HitpointsLeft > 0 then
				subsys.TurretLocked = true
				if subsys.Radius <= radius_threshold then
					num_ss_to_kill = num_ss_to_kill + 1
					kill_list[num_ss_to_kill] = i
				end
			end
		end
		if num_ss_to_kill == 0 then return end

		-- Fisher–Yates shuffle
		for i = 1, num_ss_to_kill - 1 do
			local j = ba.rand32(i, num_ss_to_kill)
			kill_list[i], kill_list[j] = kill_list[j], kill_list[i]
		end

		-- One kill per round; intensity scales how many of the eligible subs we touch
		local num_rounds = math.floor(num_ss_to_kill * intensity)
		if num_rounds <= 0 then return end
		local add_time = (death_time / num_rounds) * 3
		local add_time_min = add_time * 0.5
		local add_time_max = add_time * 1.5

		async.run(function()
			for idx = 1, num_rounds do
				async.await(mn.waitAsync(ba.rand32f(add_time_min, add_time_max)))
				if ship ~= nil then
					local ss = ship[kill_list[idx]]
					if ss ~= nil and ss:isValid() then
						ss.HitpointsLeft = -1
					end
				end
			end
		end)

	end

	function SubDying:OnGamePlayStart()
		if ba.MultiplayerMode then
			self.is_enabled = false
		else
			self.is_enabled = true
		end
	end

--

--Hooks
if not IS_STANDALONE and SubDying.global_allowed then
	engine.addHook("On Gameplay Start", function() 
			SubDying:OnGamePlayStart()
		end
	)

	engine.addHook("On Mission End", function() 
			SubDying.is_enabled = false
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Ship Death", function() 
			--do not use 'On Ship Death Started' since time until explosion is 0
			--could also add hook for 'Ship Death Started' and protect the ship if we really wanted to
			SubDying:Check_and_Start_Destroying(hv.Ship, false)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)
end