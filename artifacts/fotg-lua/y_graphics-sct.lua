-- Links advanced graphic options to options screen detail sliders
--And provides custom UI for player to select joysticks and resolution

	--Advanced graphics options are based on ini and are independent of the active pilot. 
	--Thus, changing pilots in the Pilots screen could lead to instances where the advanced ini options override player specific graphic sliders.
	--But this is on purpose, since the sliders need to reflect what the INI is. 
	--For example, the player could start on Pilot A, set graphics settings as low then switch to Pilot B, 
	--and Pilot B would then have graphic settings set to Low because the script sets the graphics from the ini. 
	--We could save the linked advanced graphic options in a unique pilot specific file (like controls) 
	--or just leave it as is since these unique options require a game restart.
	--Just leave for now, as the script will update the pilot player file slider values to match the INI,
	--so the graphic options will always be the same across all players.


GRAPHICS_UI = {

	display_warnings = true,
	global_disable = false,

	converter_tbl = {

		--set slider values from advanced values
		--set advanced values from slider values

		{ --Deferred Full and Particles
			string_match = {ADV="Graphics.DeferredLighting", SLD="Graphics.Particles"},
			get_slider_from_adv = {
				ADV_1 = 1, -- advanced Off to slider 0
				ADV_2 = 3, -- advanced On to slider 2
			},
			get_adv_from_slider = {
				SLD_1 = 1, --slider 0 to advanced Off
				SLD_2 = 1, --slider 1 to advanced Off
				SLD_3 = 2, --slider 2 to advanced On
				SLD_4 = 2, --slider 3 to advanced On
				SLD_5 = 2  --slider 4 to advanced On
			}
		},

		{ --Deferred Cockpit and Particles (requires Deferred Full to be enabled, hence why is is after in i order)
			string_match = {ADV="Graphics.DeferredCockpitLighting", SLD="Graphics.Particles"},
			get_slider_from_adv = {
				ADV_1 = {key_name = "Graphics.DeferredLighting", key_value = 'ADV_2', key_self_value = 3, key_default_value = 1}, -- advanced Off to slider 0
				ADV_2 = {key_name = "Graphics.DeferredLighting", key_value = 'ADV_1', key_self_value = 1, key_default_value = 5}, -- advanced On to slider 4
			},
			get_adv_from_slider = {
				SLD_1 = 1, --slider 0 to advanced Off
				SLD_2 = 1, --slider 1 to advanced Off
				SLD_3 = 1, --slider 2 to advanced Off
				SLD_4 = 2, --slider 3 to advanced On
				SLD_5 = 2  --slider 4 to advanced On
			}
		},

		{ --AA and SmallDebris (Impact Effects) 
			string_match = {ADV="Graphics.AAMode", SLD="Graphics.SmallDebris"},
			get_slider_from_adv = {
				ADV_1 = 1, -- advanced Off to slider 0
				ADV_2 = 2, -- advanced FXAA-low to slider 1
				ADV_3 = 3, -- advanced FXAA-medium to slider 2
				ADV_4 = 4, -- advanced FXAA-high to slider 3
				ADV_5 = 2, -- advanced SMAA-low to slider 1
				ADV_6 = 3, -- advanced SMAA-medium to slider 2
				ADV_7 = 4, -- advanced SMAA-high to slider 3
				ADV_8 = 5  -- advanced SMAA-ultra to slider 4
			},
			get_adv_from_slider = function(current_value_key)
				if string.find(current_value_key, "FXAA") then
					return {
						SLD_1 = 1, --slider 0 to advanced Off
						SLD_2 = 2, --slider 1 to advanced FXAA-low
						SLD_3 = 3, --slider 2 to advanced FXAA-medium
						SLD_4 = 4, --slider 3 to advanced FXAA-high
						SLD_5 = 4  --slider 4 to advanced FXAA-high
					}
				else
					return {
						SLD_1 = 1, --slider 0 to advanced Off
						SLD_2 = 5, --slider 1 to advanced SMAA-low
						SLD_3 = 6, --slider 2 to advanced SMAA-medium
						SLD_4 = 7, --slider 3 to advanced SMAA-high
						SLD_5 = 8  --slider 4 to advanced SMAA-ultra
					}
				end
			end
		},

		{ --Shadows and Shield Effects 
			string_match = {ADV="Graphics.Shadows", SLD="Graphics.ShieldEffects"},
			get_slider_from_adv = {
				ADV_1 = 1, -- advanced Off to slider 0
				ADV_2 = 2, -- advanced Low to slider 1
				ADV_3 = 3, -- advanced Medium to slider 2
				ADV_4 = 4, -- advanced High to slider 3
				ADV_5 = 5  -- advanced Ultra to slider 4
			},
			get_adv_from_slider = {
				SLD_1 = 1, --slider 0 to advanced Off
				SLD_2 = 2, --slider 1 to advanced Low
				SLD_3 = 3, --slider 2 to advanced Medium
				SLD_4 = 4, --slider 3 to advanced High
				SLD_5 = 5  --slider 4 to advanced Ultra
			}
		},

		{ --MSAA and Stars 
			string_match = {ADV="Graphics.MSAASamples", SLD="Graphics.Stars"},
			get_slider_from_adv = {
				ADV_1 = 1, -- advanced Off to slider 0
				ADV_2 = 3, -- advanced 4x to slider 2
				ADV_3 = 5  -- advanced 8x to slider 4
			},
			get_adv_from_slider = {
				SLD_1 = 1, --slider 0 to advanced Off
				SLD_2 = 1, --slider 1 to advanced Off
				SLD_3 = 2, --slider 2 to advanced 4X
				SLD_4 = 2, --slider 3 to advanced 4X
				SLD_5 = 3  --slider 4 to advanced 8X
			}
		}

	},

	ui_align_helper_label = "MMMMMMMMMMMMM",
	ui_align_helper_box = "4000 x 4000  ",

	use_bright_stars = false,

	starfield_wht_default = "Skb_Str_01_Wht",
	starfield_wht_bright = "Skb_Str_01b_Wht",

	starfield_whtA_default = "Skb_Str_01_Wht-trs",
	starfield_whtA_bright = "Skb_Str_01b_Wht-trs"

}

GRAPHICS_UI.starstyle_button_info = {
	uibt_unique_key = "Starfield_Style_Option",
	uibt_default_val = 1, --dropdown values are choice_i: 1 = Standard, 2 = Bright
	uibt_title_str = ba.XSTR("Starfield Style", 18), --custom_ui_18
	uibt_tool_tip = ba.XSTR("With Standard, the starfield background shows smaller and less bright stars.\nWith Bright, the starfield background shows larger and brighter stars.\nRequires mission restart to take effect.", 19), --custom_ui_19

	uibt_choices_list = {{choice_i = 1, choice_str = ba.XSTR("Standard", 20)}, {choice_i = 2, choice_str = ba.XSTR("Bright", 21)}},
	uibt_ui_type = FotG.UI_BT_List.TYPE_DropdownList,

	uibt_origin_x = 0.0,
	uibt_origin_y = 1.0,
	uibt_offset_x = 710,
	uibt_offset_y = -190,

	uibt_list_expand_mode_x = 1,
	uibt_list_expand_mode_y = -1,

	uibt_label_minimum_string = "Starfield Style ",

	uibt_list_minimum_string = GRAPHICS_UI.ui_align_helper_box,
	--^keep it same as resolution to look good in UI

	uibt_gamestate = "GS_STATE_OPTIONS_MENU",

	uibt_multi_allowed = false,

	uibt_options_tab = FotG.OTab_ID_Detail,

	--map between the dropdown choice_i and the boolean used by the rest of the scripts
	uibt_get_function = function()
		if GRAPHICS_UI.use_bright_stars then
			return 2
		else
			return 1
		end
	end,

	uibt_set_function = function(new_value)
		GRAPHICS_UI.use_bright_stars = (new_value == 2)
	end

}

--Code

	--Code for using the slider UIs to set advanced graphic options 
	function GRAPHICS_UI:ValidChecks()

		if self.global_disable then return false end

		if opt == nil then 
			ba.warning("Error, for Graphics Helper function opt script library does not seem to exist! \n")
			return false
		end

		if ui == nil then 
			ba.warning("Error, for Graphics Helper function ui script library does not seem to exist! \n")
			return false
		end

		if ui.OptionsMenu == nil then 
			ba.warning("Error, for Graphics Helper function ui.OptionsMenu script library does not seem to exist! \n")
			return false
		end

		return true

	end

	function GRAPHICS_UI:Warning(str)

		str = "Warning: GRAPHICS_UI "..str.."\n"
		if self.display_warnings then
			ba.warning(str)
		else
			ba.print(str)
		end

	end

	function GRAPHICS_UI:SetSliders_fromAdvanced()

		if not self:ValidChecks() then return end

		--get all advanced values, then update slider values to those values via persist changes and saving file

		local fso_options = opt.Options
		local options_i_list = FotG.options_name_i_list

		local changes_were_made = false

		local temp = {}

		--since we are setting sliders we need to go in rigid i order
		for _, v_linkinfo in ipairs(self.converter_tbl) do
			--setup 
			local slider_key = v_linkinfo.string_match.SLD
			local advanced_key = v_linkinfo.string_match.ADV

			--get advanced value
			local adv_opt_i = options_i_list[advanced_key]
			local advanced_opt = fso_options[adv_opt_i]
			if advanced_opt == nil then
				self:Warning("advanced_opt == nil using advanced_key of "..tostring(advanced_key))
				break
			end

			local adv_opts = advanced_opt:getValidValues()
			local adv_current_value = advanced_opt.Value
			local adv_current_i
			for i=1,#adv_opts do
				if adv_opts[i] == adv_current_value then
					adv_current_i = i
					break
				end
			end

			if adv_current_i == nil then
				self:Warning("for slider_key of "..tostring(slider_key)..", adv_current_i == nil for advanced_key of "..tostring(advanced_key).."\n")
				break
			end

			--use advanced i key and convert to slider key
			local advanced_subkey = "ADV_"..adv_current_i
			local slider_index
			local slider_value = v_linkinfo.get_slider_from_adv[advanced_subkey]
			local slider_val_type = type(slider_value)
			if slider_val_type == "number" then
				slider_index = slider_value
			elseif slider_val_type == "table" then
				local lookup_val = temp[slider_value.key_name]
				if lookup_val == slider_value.key_value then
					slider_index = slider_value.key_self_value
				else
					slider_index = slider_value.key_default_value
				end
			else
				self:Warning("for advanced_key of "..tostring(advanced_key).." with subkey of "..tostring(advanced_subkey)..", slider_value == nil using adv_current_i of "..tostring(adv_current_i).." with slider type "..tostring(slider_val_type).."\n")
				break
			end

			if slider_index == nil then
				self:Warning("for slider_key of "..tostring(slider_key)..", slider_index == nil for advanced_key of "..tostring(advanced_key).."\n")
				break
			end

			--set value of slider
			local slider_opt_i = options_i_list[slider_key]
			local slider_opt = fso_options[slider_opt_i]
			local current_slider_value = slider_opt.Value
			local new_slider_value = slider_opt:getValidValues()[slider_index]
			if new_slider_value == nil then
				self:Warning("for slider_key of "..tostring(slider_key)..", new_slider_value == nil using slider_index of "..tostring(slider_index).." for advanced_key of "..tostring(advanced_key).."\n")
				break
			end

			temp[advanced_key] = advanced_subkey

			if current_slider_value ~= new_slider_value then
				slider_opt.Value = new_slider_value
				changes_were_made = true
			end

		end

		if changes_were_made and opt ~= nil then
			opt.persistChanges()
		end

		--save sliders to player and campaign file to ensure sync
		if ui ~= nil and ui.OptionsMenu ~= nil then
			ui.OptionsMenu.savePlayerData()
		end

	end

	function GRAPHICS_UI:SetAdvanced_fromSliders()

		if not self:ValidChecks() then return end

		--get all slider values and then update advanced values to those values via persist changes and saving file
		--only update values if they are different

		local fso_options = opt.Options
		local options_i_list = FotG.options_name_i_list

		local changes_were_made = false

		--since we are setting advanced fine to go in any i order, but use i order anyway
		for _, v_linkinfo in ipairs(self.converter_tbl) do
			--setup 
			local slider_key = v_linkinfo.string_match.SLD
			local advanced_key = v_linkinfo.string_match.ADV

			--get slider value
			local slider_opt_i = options_i_list[slider_key]
			local slider_opt = fso_options[slider_opt_i]
			if slider_opt == nil then
				self:Warning("slider_opt == nil using slider_key of "..tostring(slider_key))
				break
			end

			local slider_opts = slider_opt:getValidValues()
			local slider_current_value = slider_opt.Value
			local slider_current_i
			for i=1,#slider_opts do
				if slider_opts[i] == slider_current_value then
					slider_current_i = i
					break
				end
			end

			if slider_current_i == nil then
				self:Warning("for slider_key of "..tostring(slider_key)..", slider_current_i == nil for advanced_key of "..tostring(advanced_key).."\n")
				break
			end

			--print("ZZZ slider_current_i "..slider_current_i.."\n")

			--get current value of advanced
			local adv_opt_i = options_i_list[advanced_key]
			local adv_opt = fso_options[adv_opt_i]
			local current_adv_value = adv_opt.Value

			--use slider i key and convert to advanced key
			local adv_tbl
			local adv_lookup = v_linkinfo.get_adv_from_slider
			if type(adv_lookup) == "function" then
				adv_tbl = adv_lookup(current_adv_value.Display)
			else
				adv_tbl = adv_lookup
			end
			local adv_index = adv_tbl["SLD_"..slider_current_i]

			if adv_index == nil then
				self:Warning("for slider_key of "..tostring(slider_key)..", adv_index == nil using slider_current_i of "..tostring(slider_current_i))
				break
			end	

			--get new value of advanced
			local new_adv_value = adv_opt:getValidValues()[adv_index]
			if new_adv_value == nil then
				self:Warning("for advanced_key of "..tostring(advanced_key)..", new_adv_value == nil using adv_index of "..tostring(adv_index))
				break
			end

			--print("ZZZ current_adv_value "..tostring(current_adv_value)..", and new_adv_value "..tostring(new_adv_value).."\n")

			if current_adv_value ~= new_adv_value then
				adv_opt.Value = new_adv_value
				changes_were_made = true
			end

		end

		if changes_were_made and opt ~= nil then
			opt.persistChanges()
		end

		--recall advanced options not saved in player file or campaign file, 
		--so no need to save those files

	end


	--Code for custom UI elements to select Resolution and Joysticks

	GRAPHICS_UI.joystick_opt_keys = {"Input.Joystick", "Input.Joystick1", "Input.Joystick2", "Input.Joystick3"}

	--Reads the devices FSO currently knows about, in the dropdown format UI_BT expects.
	--This has to be asked for fresh every time: this script runs during game init and on
	--some platforms (macOS especially) SDL has not reported the attached gamepads yet at
	--that point, plus devices can be plugged in or unplugged while the game is running.
	function GRAPHICS_UI:GetJoystickChoices()

		local choices = {}

		if opt == nil then return choices end

		local joy_opt_index = FotG.options_name_i_list["Input.Joystick"]
		if joy_opt_index == nil then return choices end

		local joy_option = opt.Options[joy_opt_index]
		if joy_option == nil then return choices end

		for i_opt,v_opt in ipairs(joy_option:getValidValues()) do
			choices[i_opt] = {choice_i = i_opt, choice_str = v_opt.Display}
		end

		return choices

	end

	--Rebuilds the joystick dropdowns from the current device list.
	--Safe and cheap to call repeatedly: it only rebuilds when the device list changed.
	function GRAPHICS_UI:RefreshUI_Joysticks()

		local choices = self:GetJoystickChoices()
		if #choices < 1 then return end

		--signature of the current device list, so an unchanged list costs nothing
		local signature = ""
		for _,v_choice in ipairs(choices) do
			signature = signature.."\n"..v_choice.choice_str
		end

		if signature == self.joystick_choices_signature then return end
		self.joystick_choices_signature = signature

		for _,v_key in ipairs(self.joystick_opt_keys) do

			local button_info = FotG.UI_BT_List.Buttons_Data[v_key]

			if button_info ~= nil then
				button_info.uibt_choices_list = choices
				if button_info.Elements ~= nil then
					--rebuild the drawn list so the new entries are actually selectable
					FotG:UI_BT_CheckResolution(button_info)
				end
			end

		end

	end

	--Marker recording that the joystick slots have already been set up on this machine.
	--Without it there is no way to tell a slot the player deliberately cleared from one
	--that was never set, because the options system reports None for both, and the ini
	--reads the same whether the key is absent or explicitly null.
	--Deliberately not pilot prefixed: which devices are plugged in is a machine setting.
	GRAPHICS_UI.joystick_marker_file = "_FGD_joysticks"
	GRAPHICS_UI.joystick_marker_path = "data/players"

	function GRAPHICS_UI:JoysticksWereSetUp()

		--cached so the file is only read once per session
		if self.joystick_marker_cache == nil then
			local marker = JSON_FILE:Read(self.joystick_marker_file, self.joystick_marker_path)
			self.joystick_marker_cache = (marker ~= nil) and (marker.was_set_up == true)
		end

		return self.joystick_marker_cache

	end

	function GRAPHICS_UI:MarkJoysticksSetUp()

		self.joystick_marker_cache = true
		JSON_FILE:Write({was_set_up = true}, {indent = true}, self.joystick_marker_file, self.joystick_marker_path)

	end

	--Assigns detected devices to any joystick slot still set to None, restoring the old
	--behavior of defaulting to the devices that are plugged in. Runs at most once per
	--machine, so it never overrides a slot the player chose, including one set to None.
	--Returns true if anything was actually assigned, so the caller knows to persist.
	function GRAPHICS_UI:AutoAssign_Joysticks()

		if opt == nil then return false end
		if self:JoysticksWereSetUp() then return false end

		local options_i_list = FotG.options_name_i_list
		local joy_opt_index = options_i_list["Input.Joystick"]
		if joy_opt_index == nil then return false end

		local fso_options = opt.Options

		local choices = fso_options[joy_opt_index]:getValidValues()
		if #choices < 2 then
			--no devices reported yet, so this does not count as the setup pass.
			--leave the marker alone and try again on the next menu transition
			return false
		end

		--the device list is populated, so this is the one and only setup pass,
		--whether or not there turns out to be anything to fill in
		self:MarkJoysticksSetUp()

		local none_serialized = choices[1].Serialized

		--note which devices are already in use, and which slots still need one
		local in_use = {}
		local empty_keys = {}

		for _,v_key in ipairs(self.joystick_opt_keys) do

			local opt_index = options_i_list[v_key]

			if opt_index ~= nil then
				--compare on the serialized value, since the display name is not unique
				local serialized = fso_options[opt_index].Value.Serialized
				if serialized == none_serialized then
					table.insert(empty_keys, v_key)
				else
					in_use[serialized] = true
				end
			end

		end

		if #empty_keys < 1 then return false end

		--fill the empty slots in order, from the devices that are not spoken for
		local changed = false
		local i_choice = 2 --1 is None

		for _,v_key in ipairs(empty_keys) do

			while (choices[i_choice] ~= nil) and in_use[choices[i_choice].Serialized] do
				i_choice = i_choice + 1
			end

			local set_value = choices[i_choice]
			if set_value == nil then break end --ran out of devices

			fso_options[options_i_list[v_key]].Value = set_value
			in_use[set_value.Serialized] = true
			i_choice = i_choice + 1
			changed = true

		end

		return changed

	end

	function GRAPHICS_UI:CreateUI_Joysticks()

		local max_joysticks_active = 4
		local font_h = FotG.font_list_data[FotG.Font_Options.font_medium].f_line_h
		local line_h = font_h*1.65
		local start_origin_x = 1.0
		local start_origin_y = 1.0
		local start_offset_x = -140
		local start_offset_y = -380

		local scaled_coor = FotG:Scale_UI(start_origin_x, start_origin_y, start_offset_x, start_offset_y)

		local s_x = scaled_coor.x
		local s_y = scaled_coor.y

		--get list of joysticks
		--note this list is only a starting point, see RefreshUI_Joysticks below
		local control_options = self:GetJoystickChoices()

		local joystick_offsets = {
			{opt_keyname = "Input.Joystick",  display = ba.XSTR("Device 1", 1705, false), offset_x = s_x, offset_y = s_y             },  --1 (Joy-0)
			{opt_keyname = "Input.Joystick1", display = ba.XSTR("Device 2", 1707, false), offset_x = s_x, offset_y = s_y + line_h    },  --2 (Joy-1)
			{opt_keyname = "Input.Joystick2", display = ba.XSTR("Device 3", 1709, false), offset_x = s_x, offset_y = s_y + (line_h*2)},  --3 (Joy-2)
			{opt_keyname = "Input.Joystick3", display = ba.XSTR("Device 4", 1711, false), offset_x = s_x, offset_y = s_y + (line_h*3)}   --4 (Joy-3)
		}

		local dropdown_type = FotG.UI_BT_List.TYPE_DropdownList

		for i_id=1,max_joysticks_active do

			--setup button variables
			local info = joystick_offsets[i_id]

			--set button table
			local joy_dropdown = {
				uibt_ui_type = dropdown_type,

				uibt_unique_key = info.opt_keyname,
				--which device is plugged into this machine is not a per-pilot setting,
				--so always take the value from the ini and never from the pilot json
				uibt_default_val = -1,
				uibt_read_from_ini = true,
				uibt_title_str = info.display,
				uibt_choices_list = control_options,
				uibt_tool_tip = "",--"Selected input for "..info.display,

				uibt_origin_x = -1,
				uibt_origin_y = -1,
				uibt_offset_x = info.offset_x,
				uibt_offset_y = info.offset_y,
				uibt_offset_as_coor = true,

				uibt_list_expand_mode_x = -1,
				uibt_list_expand_mode_y = -1,
				uibt_list_minimum_string = "Minimum Joystick String Width",
				--^keep it as a bit long so UI does not change too much based on string length of input

				uibt_gamestate = "GS_STATE_OPTIONS_MENU",

				uibt_multi_allowed = true,

				uibt_options_tab = FotG.OTab_ID_Main,

				uibt_get_function = function(stringkey)

					local opt_index = FotG.options_name_i_list[stringkey]
					if opt_index == nil then 
						return -1
					end

					local option = opt.Options[opt_index]
					local current_value = option.Value
					local current_i

					local choices = option:getValidValues()
					for i,v in ipairs(choices) do
						if v == current_value then
							current_i = i
						end
					end

					return current_i or -1

				end,

				uibt_set_function = function(new_value, stringkey)

					local opt_index = FotG.options_name_i_list[stringkey]
					if opt_index == nil then 
						return
					end

					local option = opt.Options[opt_index]
					local choices = option:getValidValues()

					--only write a choice that actually exists right now.
					--falling back to choices[1] here would write None (null) over a
					--perfectly good ini entry whenever the device list is not yet
					--populated or the stored index is stale
					local set_value = choices[new_value]
					if set_value == nil then
						return
					end

					--never write a value that is already set.
					--the options system persists any assignment, even an identical one,
					--and a device that is not enumerated yet reads back as None, so
					--writing that back would null out a good ini entry
					if set_value ~= option.Value then
						option.Value = set_value
					end

				end
			}

			--add button
			FotG:UI_BT_Add(joy_dropdown)
		end

	end

	function GRAPHICS_UI:CreateUI_ResolutionUI()

		--get list of resolutions
		local resolution_options = {}
		local res_opt_keyname, res_title, tooltip

		if opt ~= nil and not opt:isInGameOptionsEnabled() then return end

		if gr.isVR() then
			res_opt_keyname = "Graphics.ResolutionVR"
			res_title = ba.XSTR("Game VR Resolution", 1878, false)
			tooltip = ba.XSTR("The game rendering resolution when in VR mode.  \nRequires restart to take effect.", 23) --custom_ui_23
		else
			res_opt_keyname = "Graphics.Resolution"
			res_title = ba.XSTR("Game Screen Resolution", 1748, false)
			tooltip = ba.XSTR("The game rendering resolution.  \nRequires restart to take effect.", 22) --custom_ui_22
		end

		local res_opt_index = FotG.options_name_i_list[res_opt_keyname]
		if res_opt_index == nil then return end

		local res_option = opt.Options[res_opt_index]
		if res_option == nil then return end

		local res_choices = res_option:getValidValues()

		for i_opt,v_opt in ipairs(res_choices) do
			resolution_options[i_opt] = {choice_i = i_opt, choice_str = v_opt.Display}
		end

		--set button table
		local res_dropdown = {
			uibt_ui_type = FotG.UI_BT_List.TYPE_DropdownList,

			uibt_unique_key = res_opt_keyname,
			uibt_default_val = -1, -- -1 calls the get function instead
			uibt_title_str = res_title,
			uibt_choices_list = resolution_options,
			uibt_tool_tip = tooltip,--"Selected input for "..info.display,
			uibt_read_from_ini = true,

			uibt_origin_x = 0.0,
			uibt_origin_y = 1.0,
			uibt_offset_x = 180,
			uibt_offset_y = -190,

			uibt_label_minimum_string = GRAPHICS_UI.ui_align_helper_label,

			uibt_list_expand_mode_x = 1,
			uibt_list_expand_mode_y = -1,
			uibt_list_minimum_string = GRAPHICS_UI.ui_align_helper_box,
			--^keep it as a bit long so UI does not change too much based on string length of input

			uibt_gamestate = "GS_STATE_OPTIONS_MENU",

			uibt_multi_allowed = true,

			uibt_options_tab = FotG.OTab_ID_Detail,

			uibt_get_function = function()

				local keyname
				if gr.isVR() then
					keyname = "Graphics.ResolutionVR"
				else
					keyname = "Graphics.Resolution"
				end

				local opt_index = FotG.options_name_i_list[keyname]
				if opt_index == nil then 
					return -1
				end

				local option = opt.Options[opt_index]
				local current_value = option.Value
				local current_i

				local choices = option:getValidValues()
				for i,v in ipairs(choices) do
					if v == current_value then
						current_i = i
					end
				end

				return current_i or -1

			end,

			uibt_set_function = function(new_value)

				local keyname
				if gr.isVR() then
					keyname = "Graphics.ResolutionVR"
				else
					keyname = "Graphics.Resolution"
				end

				local opt_index = FotG.options_name_i_list[keyname]
				if opt_index == nil then 
					return
				end

				local option = opt.Options[opt_index]
				local choices = option:getValidValues()

				local set_value = choices[new_value] or choices[1] --default to first choice
				if set_value ~= nil then
					option.Value = set_value
				end

			end
		}

		--add button
		FotG:UI_BT_Add(res_dropdown)

	end

	function GRAPHICS_UI:CreateUI_WindowUI()

		--force to always windowed? fullscreen more performant though on certain systems
		--Mac and Linux may appreciate fullscreen

		if gr.isVR() then return end

		if opt ~= nil and not opt:isInGameOptionsEnabled() then return end

		local window_options = {}
		local window_opt_keyname = "Graphics.WindowMode"

		local window_opt_index = FotG.options_name_i_list[window_opt_keyname]
		if window_opt_index == nil then return end

		local window_option = opt.Options[window_opt_index]
		if window_option == nil then return end

		local window_choices = window_option:getValidValues()

		local tbl_i = 0
		for i_opt,v_opt in ipairs(window_choices) do
			-- 1= fullscreen, 2 = border-less, 3 = window
			tbl_i = tbl_i + 1
			window_options[tbl_i] = {choice_i = i_opt, choice_str = v_opt.Display}
		end

		local window_button = {
			uibt_unique_key = window_opt_keyname,
			uibt_default_val =  -1, -- -1 calls the get function instead,
			uibt_title_str = ba.XSTR("Game Screen Mode", 1772, false),
			uibt_tool_tip = ba.XSTR("Windowed mode is reccomnded, especially on Windows.", 24), --custom_ui_24
			uibt_read_from_ini = true,

			uibt_choices_list = window_options,
			uibt_ui_type = FotG.UI_BT_List.TYPE_DropdownList,

			uibt_origin_x = 0.0,
			uibt_origin_y = 1.0,
			uibt_offset_x = 180,
			uibt_offset_y = -90,

			uibt_label_minimum_string = GRAPHICS_UI.ui_align_helper_label,

			uibt_list_expand_mode_x = 1,
			uibt_list_expand_mode_y = -1,
			uibt_list_minimum_string = GRAPHICS_UI.ui_align_helper_box,
			--^keep it same as resolution to look good in UI

			uibt_gamestate = "GS_STATE_OPTIONS_MENU",

			uibt_multi_allowed = true,

			uibt_options_tab = FotG.OTab_ID_Detail,

			uibt_get_function = function()

				local window_opt_index = FotG.options_name_i_list["Graphics.WindowMode"]
				local window_option = opt.Options[window_opt_index]

				if window_option.Value == window_option:getValidValues()[3] then
					return 3
				elseif window_option.Value == window_option:getValidValues()[2] then
					return 2
				else 
					return 1
				end

			end,

			uibt_set_function = function(new_value)

				local opt_index = FotG.options_name_i_list["Graphics.WindowMode"]
				if opt_index == nil then 
					return
				end

				local option = opt.Options[opt_index]
				local choices = option:getValidValues()

				local set_value = choices[new_value] or choices[1] --default to first choice
				if set_value ~= nil then
					option.Value = set_value
				end

			end
		}

		--add button
		FotG:UI_BT_Add(window_button)

	end


	--Code for star style
	function GRAPHICS_UI:RunStarStyling()

		if ba.MultiplayerMode then return end

        if not self.use_bright_stars then return end

		local mn_skyboxmodel = mn.Skybox

		if mn_skyboxmodel == nil then return end
		if not mn_skyboxmodel:isValid() then return end

		local sb_filename = mn_skyboxmodel.Filename
		if sb_filename == nil or sb_filename == "" then return end

		local valid_sbnames_def = {
			"skybox_debris.pof",
			"skybox_planet.pof",
			"skybox_starfield.pof"
		}
		local valid_sbnames_a = {
			"skybox_asteroids_blue.pof", 
			"skybox_asteroids_bluebrown.pof",
			"skybox_asteroids_bluegrey.pof",
			"skybox_asteroids_brown.pof",
			"skybox_asteroids_brownblue.pof",
			"skybox_asteroids_browngrey.pof",
			"skybox_asteroids_grey.pof",
			"skybox_asteroids_greyblue.pof",
			"skybox_asteroids_greybrown.pof",
		}

		if string.equalAny(sb_filename, valid_sbnames_def) then
			mn.evaluateSEXP("( replace-skybox-texture !"..self.starfield_wht_default.."! !"..self.starfield_wht_bright.."! )")
		elseif string.equalAny(sb_filename, valid_sbnames_a) then
			--if using hyperspace then switch asteroids to alpha version and rely on hyperspace script to switch to non alpha when effect done 
			--if not using hyperspace then switch to non-alpha version immediately and do it here
			if mn.Events[HyperspaceExit.event_enbale_hyperspacename]:isValid() then
				mn.evaluateSEXP("( replace-skybox-texture !"..self.starfield_whtA_default.."! !"..self.starfield_whtA_bright.."! )")
			else
				mn.evaluateSEXP("( replace-skybox-texture !"..self.starfield_whtA_default.."! !"..self.starfield_wht_bright.."! )")
			end
		end

	end

--


--Create the custom UIs
	GRAPHICS_UI:CreateUI_Joysticks()
	GRAPHICS_UI:CreateUI_ResolutionUI()
	GRAPHICS_UI:CreateUI_WindowUI()
	FotG:UI_BT_Add(GRAPHICS_UI.starstyle_button_info)


--Hooks
if not IS_STANDALONE then
	--Refresh the device list whenever we are about to show or touch the joystick options.
	--Do not rely on these running before or after the UI_BT hooks in z_fotg_button-sct.lua:
	--modular tables are loaded in reverse of directory enumeration order, so z_ is parsed
	--first, and hook order follows registration order. The get/set functions always ask
	--the options system for the live value list, so they are correct either way; this
	--refresh only exists to keep the drawn dropdown list in sync.
	engine.addHook("On State End", function()
			if tostring(hv.NewState) ~= "GS_STATE_QUIT_GAME" then
				GRAPHICS_UI:RefreshUI_Joysticks()
				--deliberately not done on entry to the options menu, so that an
				--auto-assignment cannot be thrown away by the player hitting cancel
				if GRAPHICS_UI:AutoAssign_Joysticks() then
					opt.persistChanges()
				end
			end
		end,
		{State="GS_STATE_INITIAL_PLAYER_SELECT"}
	)

	engine.addHook("On State End", function()
			if tostring(hv.NewState) ~= "GS_STATE_QUIT_GAME" then
				GRAPHICS_UI:RefreshUI_Joysticks()
				if GRAPHICS_UI:AutoAssign_Joysticks() then
					opt.persistChanges()
				end
			end
		end,
		{State="GS_STATE_BARRACKS_MENU"}
	)

	engine.addHook("On State Start", function()
			GRAPHICS_UI:RefreshUI_Joysticks()
		end,
		{State="GS_STATE_OPTIONS_MENU"}
	)

	engine.addHook("On State End", function()
			if tostring(hv.NewState) ~= "GS_STATE_QUIT_GAME" then
				GRAPHICS_UI:SetSliders_fromAdvanced()
			end
		end,
		{State="GS_STATE_INITIAL_PLAYER_SELECT"}
	)

	engine.addHook("On State End", function()
			if tostring(hv.NewState) ~= "GS_STATE_QUIT_GAME" then
				GRAPHICS_UI:SetSliders_fromAdvanced()
			end
		end,
		{State="GS_STATE_BARRACKS_MENU"}
	)

	engine.addHook("On State Start", function()
			if tostring(hv.OldState) == "GS_STATE_BARRACKS_MENU" then
				GRAPHICS_UI:SetSliders_fromAdvanced()
			end
		end,
		{State="GS_STATE_OPTIONS_MENU"}
	)

	engine.addHook("On State End", function() 
			if tostring(hv.NewState) ~= "GS_STATE_QUIT_GAME" then
				GRAPHICS_UI:SetSliders_fromAdvanced()
			end
		end,
		{State="GS_STATE_INGAME_OPTIONS"}
	)

	engine.addHook("On Options Menu Closed", function() 
			if hv.OptionsAccepted then
				GRAPHICS_UI:SetAdvanced_fromSliders()
			end
		end,
		{State="GS_STATE_OPTIONS_MENU"}
	)


	engine.addHook("On Gameplay Start", function() 
			GRAPHICS_UI:RunStarStyling()
		end

	)	

end