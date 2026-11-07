
--Description: allows the mouse to act like a joystick, and can be toggled on the fly
--Usage: Press the Toggle control key during game-play, or set the value in the controls interface screen
	--To allow different pilots to have different settings, this script saves value as part of custom FotG options, 
	--instead of solely relying on the pilot independent ini options.

--Script, unrelated to mouse movement mode, forces Mouse to be split from Joy-0
--Because it's very confusing to players in the controls menu if the Mouse and Joy-0 link is On
--Even if we did have a default mouse setting, we still want to force the value for any players coming from other mods.

--Tested and works in multiplayer

JoyMouse = {
	Use_as_UI_button = false --NO UI Button for now, just in-game toggle for safety 
}

JoyMouse.button_info = {
	uibt_unique_key = "JoyMouse_is_Active",
	uibt_default_val = false,
	uibt_title_str = ba.XSTR("Mouse Movement Mode", 13), --custom_ui_13
	uibt_tool_tip = ba.XSTR("With Maneuver, the mouse moves like a joystick, allowing for evasive turns.\nWith Precise, the mouse moves conventionally, allowing for precision aiming.\nThis can also be toggled in-game using the 'Toggle Mouse Movement Mode' key.", 14), --custom_ui_14

	uibt_read_from_ini = true, 
	--^^this is saved in the ini options so do not read from json, 
	--  also means we do not have to worry about saving json file every time value toggled in-mission 
	--  since it is already saving and reading from ini

	uibt_choices_list = {{choice_i = 1, choice_str = ba.XSTR("Precise", 1844, false)}, {choice_i = 2, choice_str = ba.XSTR("Maneuver", 1845, false)}},
	uibt_ui_type = FotG.UI_BT_List.TYPE_BinaryButton,

	uibt_origin_x = 0.5,
	uibt_origin_y = 1.0,
	uibt_offset_x = 20,
	uibt_offset_y = -175,

	uibt_gamestate = "GS_STATE_CONTROL_CONFIG",

	uibt_multi_allowed = true,

	uibt_get_function = function()

		local flightmode_index = FotG.options_name_i_list["Game.FlightMode"]
		local flightmodeion = opt.Options[flightmode_index]

		--PRT--print("YYY Joymouse running getter \n")

		local helper_bool = JoyMouse.is_active_helper --hack helper

		local converted_bool 
		if flightmodeion ~= nil and flightmodeion.Value == flightmodeion:getValidValues()[1] then
			--PRT--print("  YYY Joymouse getter function shows current value is PRECISE (aka FALSE) \n")
			converted_bool = false
		else
			--PRT--print("  YYY Joymouse getter function shows current value is MANUVER (aka TRUE) \n")
			converted_bool = true
		end

		if helper_bool ~= converted_bool then
			print("YYY YYY Joymouse helper_bool was "..tostring(helper_bool).." but converted_bool was "..tostring(converted_bool).."\n")
			converted_bool = helper_bool
		end

		return converted_bool

	end,

	uibt_set_function = function(new_value)
		JoyMouse.NeedsCentered = true

		local flightmode_index = FotG.options_name_i_list["Game.FlightMode"]
		local flightmodeion = opt.Options[flightmode_index]

		--PRT--print("YYY Joymouse running setter, setting value to "..tostring(new_value).." \n")

		JoyMouse.is_active_helper = new_value --hack helper

		if flightmodeion ~= nil then
			if new_value then
				flightmodeion.Value = flightmodeion:getValidValues()[2]
				--PRT--print("  YYY Joymouse setting value to MANUVER (aka TRUE) \n")
			else
				flightmodeion.Value = flightmodeion:getValidValues()[1]
				--PRT--print("  YYY Joymouse setting value to PRECISE (aka FALSE) \n")
			end
		end

	end
}

--Code

	--Game-play Setup and Toggling

	function JoyMouse:Check_Can_Run()

		local answer

		if MTIME_OVER_P1 and not gr.hasViewmode(VM_FREECAMERA) and not gr.hasViewmode(VM_EXTERNAL) and (gr.hasViewmode(VM_INTERNAL) or gr.hasViewmode(VM_CHASE)) then 

			--check if multi observer ship
			if ba.MultiplayerMode then
				local ply = FotG:GetPlayerShip()
				if ply ~= nil and ply:isValid() and ply:getBreedName() == "Ship" then
					answer = true
				else
					answer = false
				end
			else
				answer = true
			end

		else
			answer = false
		end

		return answer

	end

	function JoyMouse:SetValueHelper(value_to_set, play_sound, center_flight_cursor)

		--set the value 
		self.button_info.uibt_set_function(value_to_set)

		--persist change so that is takes effect in-mission
		local mouse_opt_index = FotG.options_name_i_list["Game.FlightMode"]
		local mouse_option = opt.Options[mouse_opt_index]

		if mouse_option ~= nil then
			--persist changes
			mouse_option:persistChanges()

			--play a fun 2d noise if warranted
			if play_sound then
				ad.playGameSound(43)
			end

			--center flight cursor if warranted
			if center_flight_cursor then
				io.resetFlightCursor()
			end
		end

	end

	function JoyMouse:TogglePressed(final_value_match)

		if self:Check_Can_Run() then

			--toggle it
			local current_val = self.button_info.uibt_get_function()
			local final_val = not current_val

			--only proceed with toggle if
			--  we are not using final match (which is the default)
			--  or if we are using final match and the final match is what the resulting toggle will give
			--    IE if we want to ensure it is off, then only proceed with toggle if the final value will actually be off 
			if final_value_match ~= nil and final_value_match ~= final_val then
				return 
			end

			self:SetValueHelper(final_val, true, true)

		end

	end

	function JoyMouse:KeyCheck(hvkey)

		--recall, Esc does not trigger a different game state, check F keys just for redundancy
		if hvkey == "Esc" or hvkey == "F1" or hvkey == "F2" or hvkey == "F3" or hvkey == "F4" then
			io.resetFlightCursor()
		end

	end


	--Forcing Mouse to be Split and not linked to Joy-0.
	--Not related to Mouse Movement Mode.
	--See justification in comment at top of document.

	function JoyMouse:ForceMouseSplit()

		local i_opt_key = FotG.options_name_i_list["Input.UseMouse"] or -1
		if i_opt_key > 0 then
			local option = opt.Options[i_opt_key]
			if option ~= nil then
				option.Value = option:getValidValues()[1]
				option:persistChanges()
				ui.OptionsMenu.savePlayerData()
			end
		end

	end

	mn.LuaSEXPs["force-mouse-toggle-status"].Action = function(bool_status)  

		if ba.MultiplayerMode then return end

		JoyMouse:TogglePressed(bool_status)

	end

--

--Create Button
if not IS_STANDALONE and JoyMouse.Use_as_UI_button then
	FotG:UI_BT_Add(JoyMouse.button_info)
end


--Hooks
if not IS_STANDALONE then
	--forcing mouse to not be linked to Joy-0
	--NOT related to mouse movement mode!

	engine.addHook("On State End", function() 
			if tostring(hv.NewState) ~= "GS_STATE_QUIT_GAME" then
				JoyMouse:ForceMouseSplit()
			end
		end,
		{State="GS_STATE_INITIAL_PLAYER_SELECT"}
	)

	engine.addHook("On State End", function() 
			if tostring(hv.NewState) ~= "GS_STATE_QUIT_GAME" then
				JoyMouse:ForceMouseSplit()
			end
		end,
		{State="GS_STATE_BARRACKS_MENU"}
	)

	engine.addHook("On State Start", function() 
			if tostring(hv.OldState) == "GS_STATE_BARRACKS_MENU" then
				JoyMouse:ForceMouseSplit()
			end
		end,
		{State="GS_STATE_OPTIONS_MENU"}
	)


	--actually toggling of mouse mode

	engine.addHook("On State Start", function() 
			io.resetFlightCursor()
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Gameplay Start", function() 
		--if not using as UI button, then always force the joystick mode off at mission start
			if not JoyMouse.Use_as_UI_button then
				JoyMouse:SetValueHelper(false, false, false)
			end
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Mission About To End", function() 
			io.resetFlightCursor()
		end
	)

	engine.addHook("On Key Pressed", function() 
			JoyMouse:KeyCheck(hv.Key) --runs recenter
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	io.Keybinding["CUSTOM_CONTROL_2"]:registerHook(function()
		JoyMouse:TogglePressed() --runs re-center
		return false
	end, true, true)

end