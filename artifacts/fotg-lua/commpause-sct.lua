
--Description: triggers the active pause when the comms menu is activated.

--Does not work in multiplayer

CommPause = {}

CommPause.button_info = {
	uibt_unique_key = "CommPause_Active",
	uibt_default_val = false,
	uibt_title_str = ba.XSTR("Communications Menu Pause", 11), --custom_ui_11
	uibt_tool_tip = ba.XSTR("When On, opening the comms menu will engage Active Pause.\nWhen Off, opening the comms menu will not affect game speed.\nSingleplayer only, as multiplayer does not allow Active Pauses.", 12), --custom_ui_12

	uibt_choices_list = {{choice_i = 1, choice_str = ba.XSTR("Off", 0)}, {choice_i = 2, choice_str = ba.XSTR("On", 1)}},
	uibt_ui_type = FotG.UI_BT_List.TYPE_BinaryButton,

	uibt_origin_x = 0.5,
	uibt_origin_y = 1.0,
	--old, back when joystick mouse was also shown
	--uibt_offset_x = 300,
	uibt_offset_y = -170,
	uibt_offset_x = 160,

	uibt_gamestate = "GS_STATE_CONTROL_CONFIG",

	uibt_multi_allowed = false,

	uibt_get_function = function()
		return CommPause.Active
	end,

	uibt_set_function = function(new_value)
		CommPause.Active = new_value
	end

}

--Code

	--Game-play Setup and Toggling

	function CommPause:Check_Run(comms_opened)

		if ba.MultiplayerMode then return end

        if not self.button_info.uibt_get_function() then return end

        --if active pause is already on do nothing
        local active_paues_status = ExtraControls.activepause_mode_on

        if (comms_opened and not active_paues_status) or (not comms_opened and active_paues_status) then
            --if comms menu opened
            --  if active pause off then turn on
            --  if active pause already on then do nothing
            --if comms menu closed
            --  if active pause on then turn off
            --  if active pause off then do nothing
            ExtraControls:ActivePause_Toggle()
        end

	end

--

--Create Button
	FotG:UI_BT_Add(CommPause.button_info)


--Hooks
if not IS_STANDALONE then 
	--actually toggling

	engine.addHook("On HUD Comm Menu Opened", function() 
			CommPause:Check_Run(true)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On HUD Comm Menu Closed", function() 
			CommPause:Check_Run(false)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)
end