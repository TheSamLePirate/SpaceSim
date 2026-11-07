-- Syncs settings between all campaigns like a normal modern game

-- Rundown
-- 1. At main menu, click on Campaign Select
-- 2. On State End for Main Menu is triggered 
--     **^^ This is where we get and record values to use later with a temporary table
-- 3. FSO parses campaign file with CSG => Loading 
-- 4. On State Start for Campaign Select is triggered 
-- 5. When clicking Select Campaign, player file is saved with PLR => Saving
-- 6. On State End for Campaign Select is triggered 
--     **^^ This is where we set and save values from original values in temporary table and resave player and campaign file
-- 7. Campaign file is parsed again with CSG => Loading 
-- 8. On State Start for Main Menu is triggered

SYNCER = {}

--Code

	function SYNCER:GetCurrentValues()

		-- reset values and then save to temporary table

		-- error checking
		if opt == nil or ui == nil then 
			ba.warning("Error, for SUNCER Get function, opt or ui script library does not seem to exist! \n")
			return
		end

		--these are the keys we want to sync, along with controls but that's a special case done below
		local opts_to_track = {
			"Audio.BriefingVoice",

			"Audio.Effects",
			"Audio.Music",
			"Audio.Voice",

			"Game.SkillLevel",

			"Input.JoystickSensitivity",
			"Input.JoystickDeadZone",

			"Input.MouseSensitivity",

			--Note, graphics related options actually seem to sync across campaigns, though not players.
			--Also note, settings like Planet Backgrounds and Object Update have no way of syncing since they are not part of in-game options.
			--So follow expected protocols and allow different players to have different settings. 
			--Recall restart related graphic options are saved in the mod ini, not player or campaign file, so they are pilot independent.
			--Also, graphic sliders and advanced settings are linked in the y_graphics-sct script file,
			--which describes the edge cases of using graphic sliders to show/set player independent advanced graphic options.
		}

		-- get and save values to temporary table
		-- also recall multiplayer options are not saved to campaign file 
		-- so they already properly are campaign independent
		local lvals = {}

		local fso_options = opt.Options
		local options_i_list = FotG.options_name_i_list

		for _, v_optkey in ipairs(opts_to_track) do

			local i_opt_key = options_i_list[v_optkey] or -1
			local option = fso_options[i_opt_key]

			if option ~= nil then
				lvals[v_optkey] = option.Value
			end

		end

		--do special case for controls, b/c they do not have an options key
		lvals.L_ControlPreset = ui.ControlConfig.getCurrentPreset() or "default"

		-- setup/reset temporary table
		self.CurrentVals_TempTbl = nil
		self.CurrentVals_TempTbl = lvals

	end

	function SYNCER:SetCurrentValues()

		-- save values from table to campaign/pilot file
		-- then delete temporary save table

		-- error checking
		if opt == nil or ui == nil then 
			ba.warning("Error, for SUNCER Set function, opt or ui script library does not seem to exist! \n")
			return
		end

		local ui_options_menu = ui.OptionsMenu

		if ui_options_menu == nil then 
			ba.warning("Error, for SYNCER Set function ui.OptionsMenu script library does not seem to exist! \n")
			return
		end

		--set values from table
		local lvals = self.CurrentVals_TempTbl

		if lvals == nil then return end

		ui.ControlConfig.usePreset(lvals.L_ControlPreset)

		--remove control preset from list before running options since it is not a real key
		lvals.L_ControlPreset = nil

		local fso_options = opt.Options
		local options_i_list = FotG.options_name_i_list

		for k_optkey, v_optval in pairs(lvals) do

			local i_opt_key = options_i_list[k_optkey] or -1
			local option = fso_options[i_opt_key]

			if option ~= nil then
				option.Value = v_optval
			end

		end

		-- save values to actual files and reset/delete temporary table
		if opt ~= nil then
			opt.persistChanges()
			ui_options_menu.savePlayerData()

			self.CurrentVals_TempTbl = nil
		end

	end

--

--Hooks
if not IS_STANDALONE then
	engine.addHook("On State Start", function() 
			SYNCER:GetCurrentValues()
		end,
		{State="GS_STATE_CAMPAIGN_ROOM"}
	)

	engine.addHook("On State End", function() 
			if tostring(hv.NewState) ~= "GS_STATE_QUIT_GAME" then
				SYNCER:SetCurrentValues()
			end
		end,
		{State="GS_STATE_CAMPAIGN_ROOM"}
	)
end