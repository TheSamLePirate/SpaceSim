Cockpit_Toggling = {
	CP_Full_Active = true,
	CP_Sway_Active = true
}

Cockpit_Toggling.cp_full_button_info = {
	uibt_unique_key = "Cockpit_Full_Active",
	uibt_default_val = true,
	uibt_title_str = ba.XSTR("Cockpits", 7), --custom_ui_7
	uibt_tool_tip = ba.XSTR("When On, cockpits will be shown.\nWhen Off, cockpits will not be shown.", 8), --custom_ui_8

	uibt_choices_list = {{choice_i = 1, choice_str = ba.XSTR("Off", 0)}, {choice_i = 2, choice_str = ba.XSTR("On", 1)}},
	uibt_ui_type = FotG.UI_BT_List.TYPE_BinaryButton,

	uibt_origin_x = 0.5,
	uibt_origin_y = 0.7,
	uibt_offset_x = 0,
	uibt_offset_y = 0,

	uibt_gamestate = "GS_STATE_HUD_CONFIG",

	uibt_multi_allowed = true,

	uibt_get_function = function()
		return Cockpit_Toggling.CP_Full_Active
	end,

	uibt_set_function = function(new_value)
		Cockpit_Toggling.CP_Full_Active = new_value

		if Cockpit_Toggling.CP_Full_Active then
			hu.toggleCockpits = true
		else
			hu.toggleCockpits = false
		end
	end

}

Cockpit_Toggling.cp_sway_button_info = {
	uibt_unique_key = "Cockpit_Sway_Active",
	uibt_default_val = true,
	uibt_title_str = ba.XSTR("Cockpit Sway", 9), --custom_ui_9
	uibt_tool_tip = ba.XSTR("When On, the camera will slightly\nsway within the cockpit during movement\n(requires Cockpits to be On).\nWhen Off, the camera will remain\nstill within the cockpit during movement.", 10), --custom_ui_10

	uibt_choices_list = {{choice_i = 1, choice_str = ba.XSTR("Off", -1)}, {choice_i = 2, choice_str = ba.XSTR("On", -1)}},
	uibt_ui_type = FotG.UI_BT_List.TYPE_BinaryButton,

	uibt_origin_x = 0.5,
	uibt_origin_y = 0.7,
	uibt_offset_x = 400,
	uibt_offset_y = 0,

	uibt_gamestate = "GS_STATE_HUD_CONFIG",

	uibt_multi_allowed = true,

	uibt_get_function = function()
		return Cockpit_Toggling.CP_Sway_Active
	end,

	uibt_set_function = function(new_value)
		Cockpit_Toggling.CP_Sway_Active = new_value

		if Cockpit_Toggling.CP_Sway_Active then
			hu.toggleCockpitSway = true
		else
			hu.toggleCockpitSway = false
		end
	end

}


--Create Buttons
	FotG:UI_BT_Add(Cockpit_Toggling.cp_full_button_info)

	FotG:UI_BT_Add(Cockpit_Toggling.cp_sway_button_info)

