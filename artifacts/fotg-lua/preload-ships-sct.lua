
--Preload ship script by wookieejedi
--To use enable just add a ship to your mission and give that ship the name <Hyperspace Preload_Ship> (no <>)
--Code

	PreLoad = {
		globally_enabled = true,
		shipname = "Hyperspace Preload_Ship",
	}

	function PreLoad:LoadShips()

		--create ship, need Hyperspace in name so it isn't cloaked by hyperspace script
		--mn.createShip("Hyperspace Preload_Ship_2", tb.ShipClasses["Nav Buoy"], ba.createOrientation(0,0,0), ba.createVector(0,50000,50000))
		--sexps and whatnot don't work with creating ship the same frame

		local sname = self.shipname
		local preload_ship = mn.Ships[sname]

		if preload_ship == nil then return end
		if not preload_ship:isValid() then return end

		-- reminder that time compression does nothing in this usage
		--mn.evaluateSEXP("( set-time-compression !0.001!)")

		--change location
		preload_ship.Position = ba.createVector(0, -50000, 0)

		--set flags
		preload_ship:setFlag(true, "invulnerable", "no-dynamic", "stealth", "friendly-stealth-invisible", "no-shields")
		preload_ship:setFlag(true, "protect-ship", "laser-protect-ship", "missile-protect-ship", "beam-protect-ship")
		preload_ship:setFlag(false, "collides")

		--save OG class
		local og_class= preload_ship.Class

		--go through all parsed objects and get classes
		local classes = {}
		local num_classes = 0

		local function class_getter(class)

			if class ~= nil then
				local classname = class.Name
				--do not add class to list if it's already been added
				if classes[classname] == nil then
					classes[classname] = class
					num_classes = num_classes + 1
					--print("the_ship_class_of ship "..parse_ship.Name.." is "..classname.."...\n")
				end
			end

		end

		for parse_ship in mn.getArrivalList() do
			if parse_ship ~= nil then
				class_getter(parse_ship.ShipClass)
			end
		end

		--load current ships too since they will have been shader turned off
		if mn.Events[HyperspaceExit.event_enbale_hyperspacename]:isValid() then
			for ship in mn.getShipList() do
				if ship ~= nil and ship:isValid() then 
					class_getter(ship.Class)
				end
			end
		end

		--if needed run changing ship class
		if num_classes > 0 then
			--then run change ship class
			for _,v_class in pairs(classes) do
				preload_ship.Class = v_class
				--ba.print("PreLoad: pre-loading class: " .. v_class.Name .. "...\n")
			end

			--change back to nav buoy
			preload_ship.Class = og_class
		end

		-- reminder that time compression does nothing in this usage
		--mn.evaluateSEXP("(reset-time-compression)")

		--remove ship afterwards so player doesn't have chance of finding it
		preload_ship:vanish()


	end

	function PreLoad:LoadFireBalls() --not using ATM

		if ba.MultiplayerMode then return end

		--run through number of fireball entries
		local nfb = #tb.FireballClasses
		if nfb > 0 then
			for i=1,nfb do
				--mn_run_SEXP_("( explosion-effect 0 50000 -50000 0 0 5 1 1 0 !"..tostring(i-1).."! !<none>! ))")
			end
		end

	end

	function PreLoad:Run()

		--don't run if in multi
		if ba.MultiplayerMode then return end

		self:LoadShips()

		--self:LoadFireBalls()

	end

--

--Hooks
if PreLoad.globally_enabled and not IS_STANDALONE then
	engine.addHook("On Gameplay Start", function() 
			PreLoad:LoadShips()
		end
	)
end
--