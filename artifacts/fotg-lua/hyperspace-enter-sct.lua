HyperspaceEnter = {

	ship_thruster_off_time = 0.4,
	ship_fade_starttime = 0.55,
	ship_fade_duration = 0.5,
	start_starstreaks_time = 2.6, --amount of time that has passed since the above $On Warp Out hook was triggered that star streaks start
	starstreaks_efffect_2k = "PE_HyperStreaks_2_2k",
	starstreaks_efffect_4k = "PE_HyperStreaks_2_4k",
	thruster_effect_default = "PE_HyperThrust_1_Wht",
	skybox_fadeout_start = 0.6, --amount of time before skybox fadeout starts once star streak section begins
	skybox_fadeout_duration = 0.4, --amount of time skybox fadeout ends before start streak section ends

	thruster_effect_ships = {
		["T-65c X-wing"]="PE_HyperThrust_1_Red",
		["ASF-01 B-wing"]="PE_HyperThrust_1_Orn",
		["RZ-1 A-wing"]="PE_HyperThrust_1_Yel",
		["BTL-LP Longprobe"]="PE_HyperThrust_2_Red",
		["E-7 E-wing"]="PE_HyperThrust_1_Pur",
		["T.I.E. Fighter"]="PE_HyperThrust_1_Red",
		["TIE/ln Fighter"]="PE_HyperThrust_1_Red",
		["TIE/rc Fighter"]="PE_HyperThrust_1_Red",
		["TIE Advanced X1"]="PE_HyperThrust_1_Red",
		["TIE/In Interceptor"]="PE_HyperThrust_1_Red",
		["TIE/In Interceptor Mk.2"]="PE_HyperThrust_1_Red",
		["TIE/sa Bomber"]="PE_HyperThrust_1_Red",
		["TIE/sh Shuttle"]="PE_HyperThrust_1_Red",
		["V38 Assault Fighter"]="PE_HyperThrust_1_Red",
		["Z-95 Headhunter"]="PE_HyperThrust_1_Pnk",
		["BTL-A4 Y-wing"]="PE_HyperThrust_2_Red",
		["N-1 Starfighter"]="PE_HyperThrust_3_Blu",
		["Cloakshape Fighter"]="PE_HyperThrust_2_Wht",
		["A-3 V-wing Starfighter"]="PE_HyperThrust_1_Yel",
		["ARC-170 Starfighter"]="PE_HyperThrust_1_Pnk",
		["ZY-wing"]="PE_HyperThrust_3_Pur",
		["TYE-wing"]="PE_HyperThrust_3_Yel",
		["TYE-Vulture"]="PE_HyperThrust_2_Red",
		["ZTI-wing"]="PE_HyperThrust_1_Pnk",
		["T-Blade Bomber"]="PE_HyperThrust_1_Gld",
		["XG-1 Star Wing"]="PE_HyperThrust_3_Blu",
		["Skipray Blastboat"]="PE_HyperThrust_1_Yel",
		["Modified Firespray Gunship"]="PE_HyperThrust_1_Orn",
		["Firespray Gunship"]="PE_HyperThrust_1_Yel",
		["Modified YT-1300 Freighter"]="PE_HyperThrust_1_Tel",
		["YT-1300 Freighter"]="PE_HyperThrust_1_Tan",
		["Lambda T-4a Shuttle"]="PE_HyperThrust_1_Blu",
		["Zeta Hvy Cargo Shuttle"]="PE_HyperThrust_1_Blu",
		["DX-9 Stormtrooper Transport"]="PE_HyperThrust_1_Cyn",
		["UT-60D U-wing"]="PE_HyperThrust_1_Blu",
		["Star Speeder 3000"]="PE_HyperThrust_1_Gld",
		["Action VI Transport"]="PE_HyperThrust_2_Gld",
		["Corellian Star Shuttle"]="PE_HyperThrust_1_Yel",
		["DV-3 Freighter"]="PE_HyperThrust_1_Wht",
		["BFF-1 Freighter"]="PE_HyperThrust_1_Wht",
		["Rayter Transport"]="PE_HyperThrust_1_Yel",
		["GR-75 Transport"]="PE_HyperThrust_1_Cln",
		["Gozanti Cruiser#Imp"]="PE_HyperThrust_3_Blu",
		["Gozanti Cruiser#Rep"]="PE_HyperThrust_3_Blu",
		["Gozanti Cruiser#Pirate"]="PE_HyperThrust_2_Pur",
		["Charger c70 Frigate"]="PE_HyperThrust_2_Gld",
		["CR90 Corvette"]="PE_HyperThrust_1_Orn",
		["Raider Corvette"]="PE_HyperThrust_1_Cyn",
		["Braha'tok Gunship"]="PE_HyperThrust_1_Wht",
		["Marauder Corvette#Pir"]="PE_HyperThrust_1_Pur",
		["Marauder Corvette#Rep"]="PE_HyperThrust_1_Pur",
		["Marauder Corvette#Imp"]="PE_HyperThrust_1_Wht",
		["Carrack Lgt Cruiser"]="PE_HyperThrust_1_Blu",
		["Arquitens Lgt Cruiser"]="PE_HyperThrust_2_Blu",
		["Nebulon-B Frigate"]="PE_HyperThrust_4_Yel",
		["MC30 Type Frigate"]="PE_HyperThrust_2_Vlt",
		["Strike Med Cruiser"]="PE_HyperThrust_1_Orn",
		["Dreadnaught Hvy Cruiser#P"]="PE_HyperThrust_2_Yel",
		["Dreadnaught Hvy Cruiser#Reb"]="PE_HyperThrust_2_Yel",
		["Dreadnaught Hvy Cruiser#I"]="PE_HyperThrust_2_Wht",
		["Dreadnaught Hvy Cruiser#Rep"]="PE_HyperThrust_2_Wht",
		["MC40 Type Star Cruiser"]="PE_HyperThrust_2_Vlt",
		["Vindicator Hvy Cruiser"]="PE_HyperThrust_1_Cyn",
		["Interdictor Cruiser"]="PE_HyperThrust_1_Cyn",
		["Venator Cruiser"]="PE_HyperThrust_2_Trq",
		["Liberty Type Star Cruiser"]="PE_HyperThrust_1_Vlt",
		["Home One Type Star Cruiser"]="PE_HyperThrust_2_Vlt",
		["Imperial Star Destroyer"]="PE_HyperThrust_2_Cyn",
		["Super Star Destroyer"]="PE_HyperThrust_1_Orn",
	},

	waypoint_base_name = "JumpOutPoint",
	jump_point_label_info = {ba.XSTR("Hyperspace", 2), ba.XSTR("Jump", 3), ba.XSTR("Vector", 4)}, --custom_ui_2, custom_ui_3, custom_ui_4
	engine_health_cutoff = 30,
	degree_alignment_AI = 2,
	degree_alignment_player = {3,2,2,1,1},
	los_exit_check_distance = 10000,
	los_ignore_radius = 15,
	thruster_effect_name = "PE_HyperThrust_1",

	classes_with_no_hyperdrive = {
		["T.I.E. Fighter"] = true,
		["TIE/ln Fighter"] = true,
		["TIE/rc Fighter"] = true,
		["TIE/In Interceptor"] = true,
		["TIE/In Interceptor Mk.2"] = true,
		["TIE/sa Bomber"] = true,
		["TIE/sh Shuttle"] = true,
	},

	special_thrusters = {
		["T-65c X-wing"]={
			{ 1.556000,  -0.895000, -4.0},
			{-1.556000,  -0.895000, -4.0},
			{ 1.556000,   0.895000, -4.0},
			{-1.556000,   0.895000, -4.0}
		},
		["Skipray Blastboat"]={
			{0, 0, -12.3},
			{6.26, 0, -8.8},
			{-6.26, 0, -8.8}
		}
	},

	camera_offsets = { --{}, {} -- chase_view_offsets, extra eye_point_offsets from submodel that eyepoint is attached to
		["T-65c X-wing"]={{0, 6, -21}},
		["ASF-01 B-wing"]={{0, 8, -25}, {0, 3.8865, 0}},
		["RZ-1 A-wing"]={{0, 2, -8}},
		["BTL-LP Longprobe"]={{0, 5, -18}},
		["BTL-A4 Y-wing"]={{0, 5, -18}},
		["E-7 E-wing"]={{0, 5, -18}},
		["Z-95 Headhunter"]={{0, 5, -16}},
		["N-1 Starfighter"]={{0, 3, -13}},
		["Cloakshape Fighter"]={{0, 6, -22}},
		["ZY-wing"]={{0, 5, -18}},
		["TYE-wing"]={{0, 5, -16}},
		["TYE-Vulture"]={{0, 4, -15}},
		["ZTI-wing"]={{0, 5, -16}},
		["T-Blade Bomber"]={{0, 8, -25}, {0, 3.8865, 0}},
		["UT-60D U-wing"]={{0, 13, -50}},
		["A-3 V-wing Starfighter"]={{0, 2, -8}},
		["ARC-170 Starfighter"]={{0, 6, -23}},
		["XG-1 Star Wing"]={{0, 10, -36}},
		["Skipray Blastboat"]={{0, 13, -40}},
		["Modified Firespray Gunship"]={{0, 13, -46}},
		["Firespray Gunship"]={{0, 13, -46}},
		["Modified YT-1300 Freighter"]={{0, 13, -46}},
		["YT-1300 Freighter"]={{0, 13, -46}},
		["T.I.E. Fighter"]={{0, 5, -16}},
		["TIE/ln Fighter"]={{0, 5, -16}},
		["TIE/rc Fighter"]={{0, 5, -16}},
		["TIE Advanced X1"]={{0, 5, -16}},
		["TIE/In Interceptor"]={{0, 5, -14}},
		["TIE/In Interceptor Mk.2"]={{0, 5, -14}},
		["TIE/sa Bomber"]={{0, 6, -18}},
		["TIE/sh Shuttle"]={{0, 6, -18}},
		["V38 Assault Fighter"]={{0, 5, -13}},

		["Lambda T-4a Shuttle"] = {{0, 13, -50}}, 
		["Zeta Hvy Cargo Shuttle"] = {{0, 11, -58}}, 
		["DX-9 Stormtrooper Transport"] = {{0, 11, -38}}, 
		["Star Speeder 3000"] = {{0, 10, -40}} 
	}
}

--Code

	function HyperspaceEnter:GetFirstWP_from_Pathname(pathname)

		if pathname == nil then 
			return nil 
		end

		local wp_path = mn.WaypointLists[pathname]
		if wp_path ~= nil and wp_path:isValid() then
			return wp_path[1]
		else 
			return nil
		end

	end

	function HyperspaceEnter:IsFacing_ExitWP(ship, wp_path_name, angle_threshold)

		local wp = self:GetFirstWP_from_Pathname(wp_path_name)

		if wp ~= nil then
			return Movements:IsFacing_Object(ship, wp, math.rad(angle_threshold), true)
		else
			return false
		end

	end

    function HyperspaceEnter:ShowBlinker(blinkornot)
        self.show_blinker = blinkornot
    end

    function HyperspaceEnter:ShowExitPoint(showorhide)
        self.show_vector = showorhide
    end

	function HyperspaceEnter:Check_all_waypoints_for_vectors()

		local wplists_num = #mn.WaypointLists
        --just end the function here if there are no waypoints 
		if wplists_num <= 0 then return false end 

		local answer = false 
		local point_base = self.waypoint_base_name

		for i=1,wplists_num do

			local current_wp_path = mn.WaypointLists[i]

			if current_wp_path ~= nil and current_wp_path:isValid() then 
				if string.find(current_wp_path.Name, point_base) ~= nil then
					answer = true 
					break
				end
			end

		end

		return answer 

	end

    function HyperspaceEnter:Find_ExitWP_PathName(ship) --returns wp_exit_point_path_name corresponding to ship

		local wplists_num = #mn.WaypointLists
        --just end the function here if there are no waypoints 
		if wplists_num <= 0 then return nil end 

		if ship == nil then return nil end
		if not ship:isValid() then return nil end
		if ship:getBreedName() ~= "Ship" then return end

		local found_ship_vec = false
        local found_wing_vec = false
        local found_iff_vec = false
        local wp_path

		local point_base = self.waypoint_base_name
		local length_pointbase = #point_base + 2

		--save wing name, otherwise nil
		local ship_wingname
		local wing = ship:getWing()
		if wing ~= nil and wing:isValid() and wing.Name ~= nil then
			ship_wingname = wing.Name
		end

		local shipname = ship.Name
		local shipteam_name = string.filterInvisible(ship.Team.Name)

		--check override
		local override_pathname = self.jumppoint_override_list[shipname]
		if override_pathname ~= nil then
			wp_path = mn.WaypointLists[override_pathname]
		end

		--early out if valid, otherwise use default logic
		if wp_path ~= nil and wp_path:isValid() then
			return wp_path.Name
		end

        for i=1,wplists_num do

			local current_wp_path = mn.WaypointLists[i]

			if current_wp_path ~= nil and current_wp_path:isValid() then 

				local wpname = current_wp_path.Name

				if string.find(wpname, point_base) ~= nil then

					local waypoint_reference = string.sub(wpname, length_pointbase) --ie the string length of "JumpOutPoint"

					--check for specific ship name
					if not found_ship_vec and waypoint_reference == shipname then
						wp_path = current_wp_path

						found_ship_vec = true
					end

					--if ship in wing then check for wing name
					if ship_wingname ~= nil then
						if not found_ship_vec and not found_wing_vec and waypoint_reference == ship_wingname then
							wp_path = current_wp_path

							found_wing_vec = true
						end
					end

					--check for team
					if not found_ship_vec and not found_wing_vec and not found_iff_vec and waypoint_reference == shipteam_name then
						wp_path = current_wp_path

						found_iff_vec = true
					end

					--check for default point
					if not found_ship_vec and not found_wing_vec and not found_iff_vec and wpname == point_base then
						wp_path = current_wp_path
					end

				end

			end

        end

		if wp_path ~= nil and wp_path:isValid() then
			return wp_path.Name
		else
			return nil 
		end

    end

	function HyperspaceEnter:SetExtra_Checks(shipname, set_los_bool, set_min_speed)

		if type(shipname) ~= "string" then return end

		if set_los_bool == nil then
			set_los_bool = false
		end

		if type(set_min_speed) ~= "number" then
			set_min_speed = 0
		end

		self.helper_ship_table[shipname] = nil

		self.helper_ship_table[shipname] = {
			ship_needs_los = set_los_bool,
			ship_needs_min_speed = set_min_speed,
		}

	end

	function HyperspaceEnter:SetShip_to_JumpPoint_Override(shipname, waypoint_pathname) --to clear set <waypoint_pathname> to nil

		--failsafe
		if type(shipname) ~= "string" then 
			return 
		end

		if self.jumppoint_override_list == nil then 
			self.jumppoint_override_list = {} 
		end

		self.jumppoint_override_list[shipname] = waypoint_pathname

	end

	function HyperspaceEnter:Clear()

		if ba.MultiplayerMode then return end

		--print("Clearing Hyperspace Entry Values...\n")

		--clear all the stuff 
		Hyperspace_enter_effect = nil

		self.running_depart_list = nil	
		self.running_depart_list = {}

		self.jumppoint_override_list = nil	
		self.jumppoint_override_list = {}

		self.ply_jump_wp_name = nil		
		self.jumping_along_vec_list = nil
		self.vector_pulse_size = nil
		self.vector_box_size = nil			

		self.r_matrix_x = nil
		self.r_matrix_y = nil
		self.r_matrix_z = nil
		self.r_matrix = nil
		self.p_orientation = nil
		self.roll_orientation = nil
		self.alpha = nil 
		self.alpha_angle = nil
		self.effect_start = nil

		self.helper_ship_table = nil

		self.font_string_lines = nil

		--unload globals
		ROLLING_CAMERA = nil

		Hyperspace_enter_streaks_effect = nil

		self.skybox_alpha_og = nil

	end

	function HyperspaceEnter:Initiate()

		if ba.MultiplayerMode then return end

		self:Clear()

		local streak_res = self.starstreaks_efffect_2k
		if gr.getScreenWidth() > 3000 then
			streak_res = self.starstreaks_efffect_4k
		end
		Hyperspace_enter_effect = tb.ParticleEffects[streak_res]

		if gr.isVR() then
			self.is_in_VR = true
		else
			self.is_in_VR = false
		end

		self.is_player_jumping_out = false
		self.is_camera_rotating = false

		self.show_vector = true
		self.show_blinker = false
		self.using_vector_jumps = false
		self.previous_vector_check_time = 0.0
		self.fix_ply_drive = false
		self.show_blue_exit = true
		self.star_streaks_started = false

		self.jumping_along_vec_list = {}

		self.helper_ship_table = {}

		self:UpdateWP()

		self.ply_jump_wp_name = self:Find_ExitWP_PathName(FotG:GetPlayerShip())

		if self.ply_jump_wp_name ~= nil then 
			self.using_vector_jumps = true
		else
			--player not using vector jumps, but 
			--still might need to check for vector jumps, as it might be only with a specific ship that is not the player
			--for example, might only have 1 jump out point such as JumpOutPoint Beta 1
			self.using_vector_jumps = self:Check_all_waypoints_for_vectors()
		end

		-- lets scale the exit vector box based on screen res
		self.vector_box_size = FotG:ScaleR(15)

		-- ditto for the pulsing box
		self.vector_pulse_size = self.vector_box_size * 2

		local font_data = FotG:SetFont(FotG.Font_Options.font_medium, true)
		self.font_half_height = font_data.f_line_h*0.5
		self.font_index = font_data.f_index

		self.font_string_lines = {}
		for i,v_word in ipairs(self.jump_point_label_info) do
			self.font_string_lines[i] = {v_word, gr.getStringWidth(v_word) / 2}
		end

		--recall texture for flash was already loaded

	end

	function HyperspaceEnter:UpdateWP()

		--normalize waypoints if there are any
		--run manually to account for moving waypoints
		local wp_lists = mn.WaypointLists
		local wplists_num = #wp_lists

		for i=1,wplists_num do
			if string.find(wp_lists[i].Name, "JumpOutPoint") ~= nil then

				local waypoint = wp_lists[i][1]
				if waypoint ~= nil and waypoint:isValid() then
					waypoint.Position = waypoint.Position:getNormalized() * 2000000
				end

			end
		end	

	end

	function HyperspaceEnter:Visuals()

		if not hu.HUDDrawn or hu.HUDDisabledExceptMessages or ba.MultiplayerMode then
			return 
		end

		if self.show_vector and self.ply_jump_wp_name ~= nil and not self.is_player_jumping_out and not HyperspaceExit.is_player_jumping_in and MTIME_OVER_P1 then
			local mtime = mn.getMissionTime()
			gr.setColor(127, 191, 255)

			local waypoint = self:GetFirstWP_from_Pathname(self.ply_jump_wp_name)
			local x, y = waypoint.Position:getScreenCoords()
			local mtime_2 = mtime * 2
			local pulse = mtime_2 % math.floor(mtime_2)

			if x and y then
				gr.CurrentFont = gr.Fonts[self.font_index]
				--recall vector box size already set according to resolution
				local box_coor = {
					x = { x - self.vector_box_size, x + self.vector_box_size },
					y = { y - self.vector_box_size, y + self.vector_box_size }
				}
				local strs = self.font_string_lines
				gr.drawString(strs[1][1], x - strs[1][2], box_coor.y[2] + self.font_half_height)
				gr.drawString(strs[2][1], x - strs[2][2])
				gr.drawString(strs[3][1], x - strs[3][2])

				gr.setColor(127, 191, 255, 255 * (1.0 - pulse))

				gr.drawRectangle(box_coor.x[1], box_coor.y[1], box_coor.x[2], box_coor.y[2], false)
			end
			if self.show_blinker then
				local x_2, y_2 = gr.drawOffscreenIndicator(waypoint, false, true)
				if x_2 and y_2 then 
					gr.setColor(127, 191, 255, 255 * (1.0 - pulse))
					gr.drawCircle(2 + pulse * self.vector_pulse_size, x_2, y_2)
				end
			end

		end

	end

	function HyperspaceEnter:OnDepartureStarted(ship)

		--overall this function boils down to changing a warp flag before the rest of do_departure is ran
		-- and setting to run waypoints if using vector jumps

		--note that conditions or health of ship may prevent it from departing, 
		--so mission designers should retrigger departure orders as needed
		--for example:
			--PA does this whereas ships are added to a departure cue that is checked regularly, 
			--and if they are unable to leave they get re-added to cue

		if ba.MultiplayerMode then return end

		--validity checks
		if ship == nil then return end
		if not ship:isValid() then return end 

		--only run this for AI ships
		if ship:isPlayer() then return end

		--this ship was given an order to depart or departure cues became true
		--there are two departure options, hyperspace or ship bay
		--if the departure is to a ship bay we can disallow the ship warp without affecting bay departure 
		--if the departure is hyperspace then we can disallow the warp to stop it from jumping, then give it some better orders

		--check if this ship can warp
		--we have to check that here since the placement of the hook call is before the SCP code checks to see if it can warp
		--if it cannot warp then we stop and let do_departure figure out that it can't warp
		local can_bay_depart
		--note we have to use if block since the function returns a user data value and not a boolean
		if ship:canBayDepart() then
			can_bay_depart = true
		else
			can_bay_depart = false
		end

		--recall if the ai-goal-warpout was used then it will:
			--if can warp, it forces the ship to warpout even if the departure location is a bay
			--if cannot warp, it tells the ship to depart to a bay if possible and go back to just flying around if not possible 

		--if it can warp then might be useful to check to see if it can also bay, because if it can_bay then it probably should 
		--if we disable the warp here then ai-goal-warpout could possibly actually work more like order depart 
		--  since it will force it to check if it can bay, but...
		--edge case caveat: used ai-goal-warpout via sexp on ship that can warp but also can_bay:
			--in theory the ship should check if it can_bay first, then if it cannot it checks if it can jump, and if it can then it jumps
			--but we disallow the warp here, so even if it could have originally warped it cannot now
			--...so really we should break out if it can_bay as well and 
			--  just tell mission designers that using ai-goal-warpout will always force a warpout if the ship can_warp

		--Important! Good mission design suggests that if you have a departure to a bay instead of hyperspace 
		--  it is a good idea to break the warp if the ship should not be warping.
		--This is because if the ship can_warp and is given a warp-out order it will warpout even if the departure location is to a docking bay	
		--A new sexp has been made to help with this 'ai-order-depart'.
		--Options for using sexp orders to ensure ships depart via bays:
			--1. use ai-goal-warpout on a ship that cannot warp but can_bay (cannot really check this via FRED though)
			--2. use lua sexp 'ai-order-depart' which checks and does things according to if ship can_bay or not (this is preferred method)

		--if the ship cannot warp or can_bay we leave the function here without changing any warp flags
		--also if it can_bay then we just return here so we don't go telling it jump out 
		--if it accidentally faces it's waypoint while on it's bay departure path
		if not ship:canWarp() or can_bay_depart then 

			--close the s-foils if we are going to the bay but cannot warp since do_departure will figure out that it can't warp 
			--and tell it to bay if it can
			if can_bay_depart then
				Sfoils:SetHyperOut(ship)
				if ship ~= nil and ship:isValid() then
					--set ships departing to bays to stop nearly instantly
					--this helps departing the mission via bays look good and actually follow paths
					ship.Physics.ForwardDecelerationTime = Movements:Round(ship.Physics.ForwardDecelerationTime/1000, 4)
					--also add them collision group of same small team
					if string.find(ship.Team.Name, "Hostile") ~= nil then
						ship:addToCollisionGroup(MissionHelper.collide_cull_grp_small_hostile_AI) 
					else
						ship:addToCollisionGroup(MissionHelper.collide_cull_grp_small_friendly_AI) 
					end
				end
			end

			return

		end

		--set to never warp so we have some time to order it to do other things, this won't affect departure via bays
		--we can use any break or disable warp related choice here, canWarp() checks all of them
		--because we are at this point in the function we are only stopping the warp for ships that are about the depart via warp anyway
		--do not use break warp b/c PA uses that for interdictors
		ship:setFlag(true, "never-warp")

		--still here means it can warp and cannot bay so we should check if it needs a vector jump (if not just let it jump after any needed s-foils)
		--fun fact: in testing we can clear the ship's orders and break it's warp and give it an order to follow some waypoints and it will still depart via docking bay

		--wait a hot second so a few frames can pass and we can tell it to do it's waypoint thing
		--if we fix the warp right away then the function this hook is in just tells the ship to leave right away

		--FYI, even if we didn't exclude can_bay from here then:
			--we are only at this hook if the ship was given a departure order that is > then it's current order or it's departure cue became true
			--Recall that departure cues override all orders (see examples below)
				--in other words the top order is now a departure order or it doesn't matter because it was a departure cue 
				--example 1: ship departure is bay and Order_Guard (200) is overridden by departure cue and the ship departs via bay
				--example 2: ship departure is hyperspace and Order_Guard (200) is overridden by departure cue and the ship departs to hyperspace
				--example 3: ship departure is bay and player orders ship to depart and it does if no other higher orders are present
				--example 4: ship departure is hyperspace and player orders ship to depart and it does if no other higher orders are present

		--summary:
			--if bay then all of this doesn't affect it's departure
			--if hyperspace than this does affect it's departure since we broke the warp and the AI code goes back to doing whatever: 
			--But we know that this ship is destined to depart so give it a high order, 
			--and tell the FREDers to not clear it's goals or give another 200 order, and it should be fine.

		local sname = ship.Name
		local timelapse = 0.3

		async.run(function()

			--wait the needed time
			async.await(mn.waitAsync(timelapse))

			--at this point the ship cannot bay but can warp (which includes internal engines > 0 check)
			--(recall that vector check function below has extra >= engine_health_cutoff % for engines)

			--make sure the ship being used is still valid
			local check_ship = mn.Ships[sname]
			if check_ship ~= nil and check_ship:isValid() and not check_ship:isDying() then

				--do the waypoint option if present if someone is using it in this mission
				if self.using_vector_jumps then
					--check for specific jump path
					local exit_wp_name = self:Find_ExitWP_PathName(ship)	
					if exit_wp_name ~= nil then
						--use specific jump path

						--FYI clearing orders messes things up, so don't do it

						--if the ship is departing via bay this order can be given and it won't take affect, 
						--  even if the priority of the departure order that triggered this hook is low
						--at this point in function though means the ship cannot bay 
						ship:setFlag(true, "no-dynamic")
						ship:giveOrder(ORDER_WAYPOINTS_ONCE, self:GetFirstWP_from_Pathname(exit_wp_name), nil, 200/100)

						--add to jumping vector table 
						self.jumping_along_vec_list[sname] = exit_wp_name
					else
						--no jump path so just jump out
						--in other words, someone is using a vector jump (hence vector jumps is true) but it isn't this ship
						self:ForceWarpOut(ship, true, -1)
					end
				--just allow it to depart now that some time has passed
				--recall, we might still be running a departure via docking bay path
				--but the good part is that no orders can affect the ship now
				--so we can tell it to do a ai-goal-warp-out and it won't actually do anything if it's doing a bay departure
				else
					self:ForceWarpOut(ship, true, -1)	
				end

			end

		end)


	end

	function HyperspaceEnter:VectorRemoveShip(ship)

		if ba.MultiplayerMode then return end

		if ship ~= nil and ship:isValid() then
			local shipname = ship.Name
			if self.jumping_along_vec_list ~= nil then
				if self.jumping_along_vec_list[shipname] ~= nil then 
					self.jumping_along_vec_list[shipname] = nil
				end
			end
		end

	end

	function HyperspaceEnter:ForceWarpOut(ship, play_sound, time_delay)	

		--validity
		if ship == nil then return end
		if not ship:isValid() then return end

		local sname = ship.Name
		--once order starts it cannot be stopped, just like bay departures
		--this helps reduce async issues if given multiple depart orders
		--also needs to jump or die, b/c no way to retrigger
		if self.running_depart_list[sname] ~= nil then
			return
		else
			self.running_depart_list[sname] = true
		end

		--better protect to ensure it jumps by AI not targeting or destroying engines
		--better guardian engines too so player can't change it
		ship:setFlag(true, "protect-ship", "laser-protect-ship", "missile-protect-ship", "beam-protect-ship")
		MissionHelper:GuardianSubsystems(ship, nil, nil, MissionHelper.guardian_onlyengines)

		--recall that we don't want to check warp status here since it probably has a broken warp
		--also, doing s-foils here ensures that ships will close s-foils and then jump, 
		--  and not fly around with s-foils closed dodging shots but missing the jump window
		--could be case where ship engines broken down too far or out of vector alignment if s-foils closed though
		--but that's so minor that it's not really a concern 

		--deal with any s-foils
		local sfoil_time = 0
		local shipclassname = string.filterInvisible(ship.Class.Name)
		if Sfoils:ShipEquipped(shipclassname) then
			local sfoilwait, wings_were_moving = Sfoils:ShouldPreventHyperOut_Time(ship)

			--toggle s-foils, with delay if wings were moving
			local delay_before_can_toggle = 0
			if wings_were_moving then
				--in this case
				delay_before_can_toggle = sfoilwait
			end
			Sfoils:SetHyperOut(ship, delay_before_can_toggle) --recall function only runs delay async if time > 0

			--if wings have to wait to toggle add some extra time to the async
			--so it runs after the function delay above
			sfoil_time = delay_before_can_toggle + Sfoils:Get_AnimTime_Full(shipclassname, true) + 0.5
		end

		async.run(function()

			--wait the needed time
			local random_delay = 0
			if type(time_delay) == "number" then
				--if negative use default random delay, otherwise use specified delay
				if time_delay < 0 then
					random_delay = (ba.rand32(5, 105)/100) --helps so ships do not jump out exactly at the same time
				else
					random_delay = time_delay
				end
			end 
			local wait_time = sfoil_time + random_delay
			if wait_time > 0 then
				async.await(mn.waitAsync(wait_time))
			end

			--make sure the ship being used is still valid
			local check_ship = mn.Ships[sname]
			if check_ship ~= nil and check_ship:isValid() and not check_ship:isDying() then

				--allow the warp
				--does not really matter though since forcing warpout overrides any flags
				check_ship:setFlag(false, "never-warp")

				--recall collisions somewhat safeguarded within collision section of mission script

				--clear/toggle off afterburners
				--but extra failsafe here and for non s-foil ships
				check_ship.Physics.AfterburnerActive = false
				check_ship:setFlag(true, "afterburners-locked")

				--play warpout sound here since the location gets really far away really quickly if we wait until On Warp Out
				if play_sound == nil then 
					play_sound = true
				end
				if play_sound then
					local sound_entry = ad.getSoundentry(77) --these are valid 3D sounds
					if sound_entry ~= nil and sound_entry:isValid() then
						--play in 3D since ship is going fast
						--check_ship:assignSound(sound_entry, nil, BitOps.EnumOR(OS_MAIN, OS_LOOPING_DISABLED))
						ad.play3DSound(sound_entry, check_ship.Position)
					end
				end

				--actually warp out
				check_ship.Physics.RotationalVelocity = FotG.VECTOR_ZERO
				check_ship.Physics.RotationalVelocityDesired = FotG.VECTOR_ZERO

				check_ship:clearOrders()
				check_ship:warpOut()

			end

		end)


	end

	function HyperspaceEnter:ShipSpecificChecks_Pass(ship, assume_ship_valid)

		if not assume_ship_valid then
			if ship == nil then return true end
			if not ship:isValid() then return true end
		end

		--determine if this actually matters
		--recall it already is enabled in FSO for player
		local min_vel_passed, los_check_passed = true, true
		local use_min_vel, use_los_check = false, false

		local ship_specific_checks = self.helper_ship_table[ship.Name]
		if ship_specific_checks ~= nil then

			--if min speed check is needed, check it
			local specific_min_speed = ship_specific_checks.ship_needs_min_speed
			if specific_min_speed ~= nil and specific_min_speed > 0 then
				use_min_vel = true

				if ship.Physics:getForwardSpeed() >= specific_min_speed then
					min_vel_passed = true
				else
					min_vel_passed = false
				end
			end

			--if LoS check needed, check it
			if ship_specific_checks.ship_needs_los then --do not use '~= nil' b/c value might be false
				use_los_check = true

				local ship_pos = ship.Position
				--the end of the ray cast should extend quite a bit along the forward vector of the ship
				local ray_end_pos = ship:findWorldPoint(ba.createVector(0, 0, self.los_exit_check_distance))
		
				--boolean, number getLineOfSightFirstIntersect(vector from, vector to, [table excludedObjects (expects list of objects, empty by default), boolean testForShields = false, boolean testForHull = true, number threshold = 10.0])
				--Checks whether the to-position is in line of sight from the from-position and returns the distance to the first interruption of the line of sight, disregarding specific excluded objects and objects with a radius of less then threshold.
				--Returns: true and zero if there is line of sight, false and the distance otherwise and intersecting object otherwise.
				local has_line_of_sight, closest_obstacle_distance, intersecting_obj = mn.getLineOfSightFirstIntersect(ship_pos, ray_end_pos, {ship}, false, true, self.los_ignore_radius)

				los_check_passed = has_line_of_sight
			end

		end

		if not use_los_check and not use_min_vel then 
			return true 
		end

		if not use_los_check and use_min_vel then 
			return min_vel_passed 
		end

		if use_los_check and not use_min_vel then 
			return los_check_passed 
		end

		if use_los_check and use_min_vel then 
			return (los_check_passed and min_vel_passed)
		end

	end

	function HyperspaceEnter:VectorCheck_AI() --runs every X seconds for AI ships in jump vector queue

		--check for all ships told to point to a vector to see if they are ready to jump
		--if we have gotten this far that means we've passed the canWarp() check
		--we have toggled a warp flag to off though, so we cannot use the canWarp check here 
		if self.jumping_along_vec_list ~= nil then
			--local eng_cuttoff = self.engine_health_cutoff
			local degree_facing = self.degree_alignment_AI

			for k_sname,v_exitwp_name in pairs(self.jumping_along_vec_list) do

				local ship = mn.Ships[k_sname]
				if ship ~= nil and ship:isValid() and not ship:isPlayer() then

					--check engine, but default FSO way for AI where if it is > 0 then it an jump
					--not all ships might have nav!
					--and facing towards point
					--and we already know the ship is not the player, so that means we have to do the line of sight exit check

					if (Movements:GenericSubsystem_HitsPercent(ship, "engine") > 0) and ship.Physics.RotationalVelocity:getMagnitude() < 0.1 then

						if self:IsFacing_ExitWP(ship, v_exitwp_name, degree_facing) and self:ShipSpecificChecks_Pass(ship, true) then
							--now remove from table, then force warp so this does not trigger again
							self.jumping_along_vec_list[k_sname] = nil

							self:ForceWarpOut(ship, true, -1)	
							--don't use function here, it makes the sound weird
						end

					end
				end
			end
		end

	end

	function HyperspaceEnter:VectorCheck_Ply() --runs if the player presses the 'enter subspace' control, returns true if jump aborted

		--recall somehow FSO knows to not enable player warp if there is something in the path, 
		--so no need to check this for player b/c FSO does it already
		--not the case for AI ships though!

		if ba.MultiplayerMode then return false end

		local pship = FotG:GetPlayerShip()
		
		if pship == nil then return false end
		if not pship:isValid() then return false end
		if pship:getBreedName() ~= "Ship" then return false end

		if pship:isDying() then return false end

		if CapShipControl:IsEnabled() then return false end

		--if not using vector jumps we still have to make the player wings close
		--because OnDepartureStarted() only works with AI ships

		if not pship:canWarp() then return false end

		local player_can_fotg_jump = false
		--check for using jump vector and/or pointing towards exit
		local diff = MissionHelper:GetGameDifficulty()
		local alignment = self.degree_alignment_player[diff]
		if (self.ply_jump_wp_name == nil) or (self.ply_jump_wp_name ~= nil and self:IsFacing_ExitWP(pship, self.ply_jump_wp_name, alignment)) then
			--check for active moving s-foils and ai auto return
			local waitime, wings_moving = Sfoils:ShouldPreventHyperOut_Time(pship, true)
			if waitime <= 0 and not wings_moving then
				if GCW ~= nil and GCW:Player_Under_AI_Autoreturn() then
					player_can_fotg_jump = false
				else
					player_can_fotg_jump = true
				end
			end
		end

		local sound
		local jump_aborted

		--check if can do 'fate of the galaxy' style jump
		if player_can_fotg_jump then
			--yep, jumping!
			jump_aborted = false

			--set success sound
			if Astromechs:ShipHas(pship) then
				sound = Astromechs:GetSoundIndex("yes")
			else
				sound = 135 --2d beep1
			end

			Sfoils:SetHyperOut(pship)

			--also account for s-foil animation times
			--already accounted for in ships table with `$Warpout Engage Time:`

			--also force view back to front if bomb camera on?
			--fine to let it view from there I guess, 
			--as bomb script at least turns off custom hud drawing
			--and it's complex to toggle it off b/c running the toggle will turn it on if it is off

		else
			--nope, staying put
			jump_aborted = true
			--set fail sound
			if Astromechs:ShipHas(pship) then
				sound = Astromechs:GetSoundIndex("no")
			else
				sound = 28 --2d fail sound
			end
		end

		--play fun hyperspace or confirmed sound-from-table
		if sound ~= nil then
			ad.playGameSound(sound)
		end

		return jump_aborted

	end

	function HyperspaceEnter:Get_LocalEyepointPos(ship)

		local local_pos
		if ship ~= nil and ship:isValid() then
			local class = ship.Class
			if class ~= nil then
				local model = class.Model
				if model ~= nil then
					local eye_points = model.Eyepoints
					if eye_points ~= nil then
						local eyp = eye_points[1]
						if eyp ~= nil and eyp:isValid() then
							local_pos = eyp.Position
						end
					end	
				end
			end
		end

		if local_pos == nil then
			local_pos = FotG.VECTOR_ZERO
		end

		return local_pos

	end

	function HyperspaceEnter:Get_ExternalOffset(shipclassname, offset_type, shipname) --returns {x,y,z}

		if not (offset_type == 1 or offset_type == 2) then
			print("Error: offset type "..tostring(offset_type).." unrecognized for shipclass info...\n")
		end

		shipclassname = string.filterInvisible(shipclassname)

		local off_pos = {0,0,0}

		local coffs = self.camera_offsets[shipclassname]
		if coffs ~= nil then
			if offset_type == 1 then
				--if we have a non default offset than use it
				local co1 = coffs[1] or {0, 0, 0}
				off_pos.x = co1[1] or 0
				off_pos.y = co1[2] or 0
				off_pos.z = co1[3] or 0
			elseif offset_type == 2 then
				--get model eyepoint
				local eyp_pos = self:Get_LocalEyepointPos(mn.Ships[shipname])
				local extra_off = coffs[2] or {0, 0, 0}
				off_pos.x = eyp_pos.x + (extra_off[1] or 0)
				off_pos.y = eyp_pos.y + (extra_off[2] or 0)
				off_pos.z = eyp_pos.z + (extra_off[3] or 0)
				--print("offset_check "..off_pos.x..", "..off_pos.y..", "..off_pos.z.."\n")
			end
		else
			if offset_type == 1 then
				--recall default `chase_view_offset = vm_vec_new(0.0f, 0.625f * Viewer_obj->radius, -2.125f * Viewer_obj->radius);`
				local pradius = Movements:Get_Ship_Radius(shipname, true)
				off_pos.x = 0
				off_pos.y = math.round(0.625 * pradius)
				off_pos.z = math.round(-2.125 * pradius)
			elseif  offset_type == 2 then
				off_pos.x = 0
				off_pos.y = 0
				off_pos.z = 0
			end
		end

		return off_pos

	end

	function HyperspaceEnter:FireThruster(ship)

		if ship == nil then return end
		if not ship:isValid() then return end

		--do not shoot thrusters on TIEs
		local sclass = ship.Class
		local classname_safe = string.filterInvisible(sclass.Name)
		if self.classes_with_no_hyperdrive[classname_safe] ~= nil then
			return 
		end

		local thruster_off_time = self.ship_thruster_off_time
		if thruster_off_time > 0 then
			async.run(function()
				async.await(mn.waitAsync(thruster_off_time))
				--disable real-space ship thrusters
				if ship ~= nil then
					ship:setFlag(true, "no-thrusters")
				end
			end)
		end

		local thruster_effect_name = self.thruster_effect_ships[sclass.Name] or self.thruster_effect_ships[classname_safe] or self.thruster_effect_default
		local thruster_effect = tb.ParticleEffects[thruster_effect_name]
		if thruster_effect == nil then return end

		local start_time = self.ship_fade_starttime 
		local duration = self.ship_fade_duration
		if start_time > 0 then
			async.run(function()
				async.await(mn.waitAsync(start_time))
				if ship ~= nil then
					ship:addShipEffect("Custom Fade Out", duration*1000)
				end
			end)
		else
			ship:addShipEffect("Custom Fade Out", duration*1000)
		end

		local thruster_special = self.special_thrusters[classname_safe]
		local model = sclass.Model
		local thruster_banks_num = #model.Thrusters
		for i=1,thruster_banks_num do

			local thruster = model.Thrusters[i]
			local thruster_num_points = #thruster

			for j=1,thruster_num_points do
				local thruster_point = thruster[j]

				local thruster_point_pos
				--special case for engines that move
				if thruster_special ~= nil then
					local tbl_thruster = thruster_special[i]
					thruster_point_pos = ba.createVector(tbl_thruster[1], tbl_thruster[2], tbl_thruster[3])
				else
					thruster_point_pos = thruster_point.Position
				end

				--create particle with new scripting 
				local radius = thruster_point.Radius * 8
				if radius < 0.1 then
					radius = 0.1
				end
				local source = thruster_effect:createSource()
				if source ~= nil then
					source:setTriggerRadius(radius)
					source:createOnObject(ship, thruster_point_pos)
				end
			end

		end

	end

	function HyperspaceEnter:TriggerJumpEffect(ship)

		-- If it's the player's ship that's jumping, this hook initializes the variables
		-- needed for drawing the effect, attaches the camera in front of the ship and
		-- plays the hyperdrive sound. If it's another ship, then
		-- it just fires the thrusters.

		-- Note, b/c mission ends with player actually jumping out to hyperspace, FSO does some hard coded things
		--   Player speeds up and controls locked. 
		--     speed up means that we cannot set a ship equal to the player's position for the duration, 
		--     b/c floating point issues will come into play, so cannot have tunnel follow player

		if ba.MultiplayerMode then return end

		local player = FotG:GetPlayerShip()

		if ship ~= nil and ship:isValid() and player ~= nil and player:isValid() and player:getBreedName() == "Ship" then
			if ship:isPlayer() then
				self.is_player_jumping_out = true
				self.effect_start = mn.getMissionTime()

				--reset time compression in-case it got set
				ExtraControls:ActivePauseMode_Reset(true)

				--default camera following looks jumpy when the player ship speeds up quickly with jump out
				--so attach a camera to ensure it looks smooth when in chase view
				if gr.hasViewmode(VM_CHASE) then
					local pname = player.Name
					if pname ~= nil then
						local pclass = string.filterInvisible(player.Class.Name)
						local cam_pos = self:Get_ExternalOffset(pclass, 1, pname)
						--somehow sexps are the only way to make it attach right to player ship
						mn.evaluateSEXP("( set-camera-host !"..pname.."! )")
						mn.evaluateSEXP("( set-camera-position "..cam_pos.x.." "..cam_pos.y.." "..cam_pos.z.." ) ")
						--account for B-wing special case
						if Sfoils.deal_with_special_bwing_rot and pclass == "ASF-01 B-wing" then
							mn.evaluateSEXP("( set-camera-rotation 0 -90 0 ) ")
						end
					end
				end

				ad.playGameSound(93) --2d hyperspace sound

				--add fade out 
				async.run(function()
					async.await(mn.waitAsync(5.0))
					mn.evaluateSEXP("( fade-out 500 0 )")
				end)

			else
				--sound is played in ForceWarpOut() section
				self:FireThruster(ship)
			end
		end

	end

	function HyperspaceEnter:DrawEffect()

		if ba.MultiplayerMode then return end

		if not self.is_player_jumping_out then return end

		local player = FotG:GetPlayerShip()
		if player == nil then return end
		if not player:isValid() then return end
		if player:getBreedName() ~= "Ship" then return end

		local relative_startime = mn.getMissionTime() - self.effect_start

		--create star streaks/fade out skybox
		--then set camera 
		if relative_startime < self.start_starstreaks_time then

			--create star streaks
			if not self.star_streaks_started and Hyperspace_enter_effect ~= nil then
				local source = Hyperspace_enter_effect:createSource()
				source:createOnObject(player, ba.createVector(0, 0, 0))
				self.star_streaks_started = true
				self.skybox_alpha_og = mn.SkyboxAlpha 
			end

			--fade out skybox
			local percent_done = 1
			if self.skybox_fadeout_duration ~= 0 then
				percent_done = math.Clamp((relative_startime - self.skybox_fadeout_start) / (self.skybox_fadeout_duration), 0, 1)
			end
			mn.SkyboxAlpha = self.skybox_alpha_og - percent_done

		else

			--set and then rotate camera
			if not self.is_camera_rotating then
				-- This bit is run only once, to fix the camera right behind the ship
				-- and play the boom sound of entering hyperspace

				--reset skybox alpha since in external view
				mn.SkyboxAlpha = 1.0

				--have to use player info instead of using gr.Camera[1], because for some reason that camera's position values make no sense
				local ply_orient = player.Orientation
				local adjusted_or = {}

				local pclassname = string.filterInvisible(player.Class.Name)

				--get external or internal view offset
				local offset_typ
				if gr.hasViewmode(VM_CHASE) then
					offset_typ = 1
				else
					offset_typ = 2
				end
				local l_offsets = self:Get_ExternalOffset(pclassname, offset_typ, player.Name)
				local l_offsets_vec = ba.createVector(l_offsets.x, l_offsets.y, l_offsets.z)

				--get orientation
				if Sfoils.deal_with_special_bwing_rot and pclassname == "ASF-01 B-wing" then
					--deal with B-wing rotation
					adjusted_or = Movements:StandardizePBH({p=ply_orient.p, b=ply_orient.b-math.rad(90), h=ply_orient.h})
				else
					--all other ships
					adjusted_or = {p=ply_orient.p, b=ply_orient.b, h=ply_orient.h}
				end
				local anchor_or = ba.createOrientation(adjusted_or.p, adjusted_or.b, adjusted_or.h)

				--get camera position -- global position + relative position offsets
				local cam_pos = player:findWorldPoint(l_offsets_vec)

				--set camera position and prep for rotation
				ROLLING_CAMERA = gr.createCamera("Rolling Camera", ba.createVector(cam_pos.x, cam_pos.y, cam_pos.z), anchor_or)
				gr.setCamera(ROLLING_CAMERA)

				ad.playGameSound(77)

				self.r_matrix_x = ba.createOrientation(1,0,0,0,1,0,0,0,1)
				self.r_matrix_y = ba.createOrientation(1,0,0,0,1,0,0,0,1)
				self.r_matrix_z = ba.createOrientation(1,0,0,0,1,0,0,0,1)
				self.r_matrix =   ba.createOrientation(1,0,0,0,1,0,0,0,1)
				self.alpha = 0
				self.alpha_angle = 30 * math.pi / 180
				self.p_orientation = anchor_or

				self.is_camera_rotating = true

				--fire thrusters
				self:FireThruster(player)

			elseif not self.is_in_VR then
				-- only run rotating camera if not in VR, otherwise VR players might hurl
				-- This takes care of rotating the camera at the end of the effect
				self.alpha = (self.alpha_angle * ba.getMissionFrametime()) + self.alpha

				self.r_matrix_z[9] = 1
				self.r_matrix_z[1] = math.cos(self.alpha)
				self.r_matrix_z[2] = -math.sin(self.alpha)
				self.r_matrix_z[4] = math.sin(self.alpha)
				self.r_matrix_z[5] = math.cos(self.alpha)

				self.r_matrix = (self.r_matrix_x * self.r_matrix_y) * self.r_matrix_z 
				self.roll_orientation = self.p_orientation * self.r_matrix
				ROLLING_CAMERA.Orientation = self.roll_orientation

				--need to rotate ship too to make it look less odd
				if Sfoils.deal_with_special_bwing_rot and string.filterInvisible(player.Class.Name) == "ASF-01 B-wing" then
					--deal with B-wing rotation
					local n_or = Movements:StandardizePBH({p=self.roll_orientation.p, b=self.roll_orientation.b+math.rad(90), h=self.roll_orientation.h})
					player.Orientation = ba.createOrientation(n_or.p, n_or.b, n_or.h)
				else
					--all other ships
					player.Orientation = self.roll_orientation
				end

				--set the player's throttle to 0 so we don't here the engine sound anymore
				--this works since the engine sound only plays if the player's velocity is > 0.01
				local p_phys = player.Physics
				p_phys.VelocityDesired = p_phys.VelocityDesired * 0
				p_phys.Velocity = p_phys.Velocity * 0

			end
		end

	end

	function HyperspaceEnter:RunSimulation()

		if not ba.MultiplayerMode and MTIME_OVER_P1 then 

			if self.using_vector_jumps then
				local mtime = mn.getMissionTime()
				if mtime > self.previous_vector_check_time + 0.2 then
					self:VectorCheck_AI()
					self.previous_vector_check_time = mtime
				end
			end

		end

	end

	function HyperspaceEnter:OrderDepart(priority, ship)

		if ship ~= nil and ship:isValid() then

			if type(priority) ~= "number" then
				priority = 89
			end

			if ship:canBayDepart() then
				--my mother ship is here, so I'm going to go depart to my mother ship
				--so disallow my warp and do a departure 
				--since my warp is stopped and I can_bay then I will immediately start the bay departing and cannot be stopped (so it's fine that my warp is set to not work)
				ship:setFlag(true, "never-warp")
				ship:giveOrder(ORDER_DEPART, nil, nil, priority/100)
				--^running that order will trigger '$On Departure Started:'

			else
				--if I cannot bay then check if I can warp, if so just order me a warp
				if ship:canWarp() then
					ship:giveOrder(ORDER_DEPART, nil, nil, priority/100)
					--^running that order will trigger '$On Departure Started:'
				end
				--if I couldn't warp then I can't depart in anyway and am sad and my orders are thus not changed in anyway
			end

		end

	end

	mn.LuaSEXPs["player-hyperdrive-active"].Action = function ()

		if ba.MultiplayerMode then
			return false
		else
			return HyperspaceExit.is_player_jumping_in or HyperspaceEnter.is_player_jumping_out
		end

	end

	mn.LuaSEXPs["ship-has-hyperdrive"].Action = function (ship) --returns true if ship has a hyperdrive according to SW canon

		if ba.MultiplayerMode then return true end

		local has_hyperdrive = true

		if MTIME_OVER_P1 and ship ~= nil and ship:isValid() then
			local sclass = ship.Class.Name
			if sclass ~= nil then
				local class_safe = string.filterInvisible(sclass)
				if HyperspaceEnter.classes_with_no_hyperdrive[class_safe] ~= nil then
					has_hyperdrive = false
				end
			end
		end

		return has_hyperdrive

	end

	mn.LuaSEXPs["did-player-jumpout?"].Action = function ()	--simple check to see if HyperspaceEnter.is_player_jumping_out in hyperspace script is true

		if not ba.MultiplayerMode and HyperspaceEnter.is_player_jumping_out then
			return true
		else 
			return false
		end

	end

	mn.LuaSEXPs["set-player-warp-status"].Action = function (toggle_option)

		if ba.MultiplayerMode then return end

		if type(toggle_option) ~= "boolean" then return end
		local ply = FotG:GetPlayerShip()
		if ply == nil then return end
		if not ply:isValid() then return end
		if ply:getBreedName() ~= "Ship" then return end

		if ply:isDying() then return end

		local never_warp_bool = not toggle_option
		ply:setFlag(never_warp_bool, "never-warp")

		HyperspaceEnter:ShowBlinker(toggle_option)
		HyperspaceEnter:ShowExitPoint(toggle_option)

	end

	mn.LuaSEXPs["show-hyperspace-vector"].Action = function (lboolean)

		if ba.MultiplayerMode then return end

		if type(lboolean) == "boolean" then
			HyperspaceEnter:ShowExitPoint(lboolean)
		end

	end

	mn.LuaSEXPs["show-hyperspace-blinker"].Action = function (lboolean)

		if ba.MultiplayerMode then return end

		if type(lboolean) == "boolean" then
			HyperspaceEnter:ShowBlinker(lboolean)
		end

	end

	mn.LuaSEXPs["update-hyperspace-exit-vector"].Action = function ()

		if ba.MultiplayerMode then return end

		HyperspaceEnter:UpdateWP()

	end

	mn.LuaSEXPs["ai-order-depart"].Action = function (priority, ...)

		if ba.MultiplayerMode then return end

		for _, v_data in ipairs(arg) do
			local ship = v_data[1]	
			HyperspaceEnter:OrderDepart(priority, ship)
		end

	end

	mn.LuaSEXPs["ai-force-warpout"].Action = function (delay_time, ...)

		if ba.MultiplayerMode then return end

		for _, v_data in ipairs(arg) do
			local ship = v_data[1]	
			HyperspaceEnter:ForceWarpOut(ship, true, delay_time)
		end

	end

--

--Hooks
if not IS_STANDALONE then
	engine.addHook("On Simulation", function() 
			HyperspaceEnter:RunSimulation()
		end
	)

	engine.addHook("On Gameplay Start", function() 
			HyperspaceEnter:Initiate()
		end
	)

	engine.addHook("On Mission About To End", function() 
			HyperspaceEnter:Clear()
		end
	)

	engine.addHook("On HUD Draw", function() 
			HyperspaceEnter:Visuals()
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Departure Started", function() 
			HyperspaceEnter:OnDepartureStarted(hv.Ship)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Ship Depart", function() 
			--ships that depart via bays have an entry in the 'vector check' table so this just ensures it gets removed
			--safe to trigger multiple times b/c it will only be removed if it still exists in the table
			HyperspaceEnter:VectorRemoveShip(hv.Ship)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Warp Out", function() 
			HyperspaceEnter:TriggerJumpEffect(hv.Self)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Frame", function() 
			-- This hook handles the actual drawing of the effect
			HyperspaceEnter:DrawEffect()
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	io.Keybinding["END_MISSION"]:registerHook(function()
		return HyperspaceEnter:VectorCheck_Ply() --"Engage Hyperdrive (End Mission)", returns true if vector jump and jump aborted
	end, true, true)

end
