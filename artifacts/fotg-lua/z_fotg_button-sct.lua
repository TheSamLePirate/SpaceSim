--Common functions to make a UI Toggle Button 

FotG.UI_BT_List = {
	Buttons_Data = {}, --keys are string values of button names, and values are table of button data
	Buttons_Gamestates = {}, --keys are string values of game-state names, and values are i list of button names
	Font_Multiplier = 1.0,

	--do not actually save as a json  b/c then FSO gets confused and thinks all json files are pilot files
	Data_Save_Prefix = "_FGD_",
	Data_Save_Path = "data/players", --save to players to make agnostic to mod version

	scaled_p1 = FotG:ScaleR(1),
	scaled_p2 = FotG:ScaleR(2),
	scaled_p3 = FotG:ScaleR(3),
	scaled_p5 = FotG:ScaleR(5),
	scaled_p8 = FotG:ScaleR(8),
	scaled_p10 = FotG:ScaleR(10),
	scaled_p20 = FotG:ScaleR(20),

	ID_OFF = 1,
	ID_ON = 2,
	ID_NIL = 0,
	ID_SPECIAL = 1138,

	TYPE_BinaryButton = 1,
	TYPE_DropdownList = 2
}

--Code: Saving and Loading JSON
	function FotG:UI_BT_WriteJSON()

		local write_json = {}

		local filename = FotG:Get_PilotName_withPrefix(self.UI_BT_List.Data_Save_Prefix)
		local path = self.UI_BT_List.Data_Save_Path

		--get all keys from lua values and save to json file
		for k_buttonname, v_buttoninfo in pairs(self.UI_BT_List.Buttons_Data) do

			local get_function = v_buttoninfo.uibt_get_function
			if get_function ~= nil then
				write_json[k_buttonname] = get_function(k_buttonname)
			end

		end

		JSON_FILE:Write(write_json, {indent = true}, filename, path)

	end

	function FotG:UI_BT_ReadJSON()

		local filename = FotG:Get_PilotName_withPrefix(self.UI_BT_List.Data_Save_Prefix)
		local path = self.UI_BT_List.Data_Save_Path

		--read json of all keys and set
		local read_json = JSON_FILE:Read(filename, path)

		--if file does not exist create it with defaults
		local json_valid = false
		if read_json ~= nil then
			json_valid = true
		end

		--get all keys from file read json and set lua values
		local persist_needed = false
		for k_buttonname, v_buttoninfo in pairs(self.UI_BT_List.Buttons_Data) do

			local set_function = v_buttoninfo.uibt_set_function
			if set_function ~= nil then
				local value
				local get_function = v_buttoninfo.uibt_get_function

				if read_json and read_json[k_buttonname] ~= nil then
					if v_buttoninfo.uibt_read_from_ini and get_function ~= nil then
						--useful for things like graphics that would be jarring if switching pilots
						--so read from ini which is pilot independent
						value = get_function(k_buttonname)
					else
						value = read_json[k_buttonname]
					end
				else
					local default_val = v_buttoninfo.uibt_default_val or -1
					if default_val == -1 and get_function ~= nil then
						--method: set default value from the current value
						--useful for things like graphics that would be jarring if switching pilots
						value = get_function(k_buttonname)
					else
						--method: set default value from specified default value
						value = default_val
					end
				end

				set_function(value, k_buttonname)
				persist_needed = true
			end

		end

		--if json was invalid then write it with newly set default values
		if not json_valid then
			self:UI_BT_WriteJSON()
			persist_needed = true
		end

		if persist_needed and opt ~= nil then
			opt.persistChanges()
		end

	end

--Code: Individual Button

	function FotG:UI_BT_MultiPlayerStop(button_info)

		if button_info == nil or (not button_info.uibt_multi_allowed and ba.MultiplayerMode) then 
			return true
		else
			return false
		end

	end

	function FotG:UI_BT_TabInvalid(button_info)

		local none_id = self.OTab_ID_None
		local required_opt_tab = button_info.uibt_options_tab or none_id
		--if uses specific tab (ie > none) and the button tab is not current tab then the button is invalid
		if button_info == nil or (required_opt_tab > none_id and required_opt_tab ~= self.OTab_ID_Current) then 
			return true
		else
			return false
		end

	end

	function FotG:UI_BT_EarlyStop(button_info)

		if self:UI_BT_MultiPlayerStop(button_info) or self:UI_BT_TabInvalid(button_info) then
			return true
		else
			return false
		end

	end

	function FotG:UI_BT_CheckResolution(button_info)

		local sized_coord

		if button_info.uibt_offset_as_coor then
			sized_coord = {x = button_info.uibt_offset_x, y = button_info.uibt_offset_y}
		else
			local coordinates = {
				origin = {x = button_info.uibt_origin_x, y = button_info.uibt_origin_y}, 
				offset = {x = button_info.uibt_offset_x, y  = button_info.uibt_offset_y},
				screen = {x = gr.getScreenWidth(), y = gr.getScreenHeight()},
				get_values_for_ui = true
			}

			sized_coord = self:Get_Coordinates(coordinates)
		end

		local is_binary_button = (button_info.uibt_ui_type == self.UI_BT_List.TYPE_BinaryButton)
		local is_dropdown = (button_info.uibt_ui_type == self.UI_BT_List.TYPE_DropdownList)

		local box_size = self.UI_BT_List.scaled_p20
		if box_size < 10 then 
			box_size = 10 
		end

		local box_half = box_size/2

		local p_1 = self.UI_BT_List.scaled_p1
		local p_2 = self.UI_BT_List.scaled_p2
		local p_5 = self.UI_BT_List.scaled_p5
		local p_10 = self.UI_BT_List.scaled_p10
		local p_20 = self.UI_BT_List.scaled_p20

		local med_font = self:SetFont(self.Font_Options.font_medium, true)
		local font_h = med_font.f_line_h
		local font_buf = med_font.f_buf
		if font_buf < 1 then
			font_buf = 1 
		end
		local title_str = button_info.uibt_title_str
		local title_str_width = gr.getStringWidth(title_str)
		local center_x = sized_coord.x - (title_str_width/2)

		local label_x
		if is_dropdown then
			label_x = sized_coord.x
		else
			label_x = center_x - (title_str_width/2)
		end

		local label_y = sized_coord.y

		local b_off_x1 = center_x - (box_half*5)
		local b_on_x1 = center_x + (box_half*3)
		local b_y1 = sized_coord.y + (med_font.f_line_h * 1.1)

		local b_y2 = b_y1 + box_size

		local tooltip_x = b_off_x1
		local tooltip_y = b_y2 + p_20
		local tooltip_str = button_info.uibt_tool_tip
		local tooltip_w = gr.getStringWidth(tooltip_str)
		local tooltip_h = gr.getStringHeight(tooltip_str)

		button_info.Elements = nil

		button_info.Elements = { 
			title_info = {
				string_coor = {
					x1 = label_x, 
					y1 = label_y
				},
				string_value = title_str
			}
		}

		if is_binary_button then
			--binary button
			local choice_off_str = button_info.uibt_choices_list[1].choice_str
			local off_str_width = gr.getStringWidth(choice_off_str)
			local choice_on_str = button_info.uibt_choices_list[2].choice_str
			local on_str_width = gr.getStringWidth(choice_on_str)
			local use_red_for_off = (string.find(string.lower(choice_off_str), "off") ~= nil)

			button_info.Elements.choices_info = {
				
				{ --1 off
					box_coor = {
						x1 = b_off_x1,
						y1 = b_y1,
						x2 = b_off_x1 + box_size,
						y2 = b_y2
					},
					label_coor = {
						x1 = b_off_x1 + box_half - (off_str_width/2),
						y1 = b_y2 + self.UI_BT_List.scaled_p8
					},
					label_value = choice_off_str,
					choice_id_key = self.UI_BT_List.ID_OFF,
					use_red_for_off = use_red_for_off
				},
				
				{ --2 on
					box_coor = {
						x1 = b_on_x1,
						y1 = b_y1,
						x2 = b_on_x1 + box_size,
						y2 = b_y2
					},
					label_coor = {
						x1 = b_on_x1 + box_half - (on_str_width/2),
						y1 = b_y2 + self.UI_BT_List.scaled_p8
					},
					label_value = choice_on_str,
					choice_id_key = self.UI_BT_List.ID_ON,
				}
			}

		elseif is_dropdown then
			--dropdown list
			if font_buf < 1 then
				font_buf = 1
			end
			local x_buf = font_buf
			local y_buf = math.round(font_buf * 1.0)
			local line_h = font_h + math.round(font_buf * 1.2)

			local expand_list_mode_x = button_info.uibt_list_expand_mode_x
			local expand_list_mode_y = button_info.uibt_list_expand_mode_y

			local choices_list = button_info.uibt_choices_list
			local num_choices = #choices_list
			if num_choices < 1 then
				num_choices = 1
			end

			local max_str_width = gr.getStringWidth(button_info.uibt_list_minimum_string) 

			for _,v_choice in ipairs(choices_list) do
				local l_width = gr.getStringWidth(v_choice.choice_str) + (x_buf*2)
				if l_width > max_str_width then
					max_str_width = l_width
				end
			end

			max_str_width = max_str_width + x_buf

			local special_x
			local special_y = label_y
			local list_x

			if expand_list_mode_x < 0 then
				--expand left
				special_x = label_x - (x_buf + max_str_width)
				list_x = special_x - (p_2 + max_str_width)
			else --> 0
				--expand right
				--use a fixed label column width (if given) so boxes line up regardless of title length
				local label_col_width = title_str_width
				local label_min_str = button_info.uibt_label_minimum_string
				if label_min_str ~= nil then
					label_col_width = math.max(label_col_width, gr.getStringWidth(label_min_str))
				end
				special_x = label_x + (x_buf + label_col_width)
				list_x = special_x + (p_2 + max_str_width)
			end 

			local spec_box_y1 = special_y - y_buf
			local spec_box_y2 = spec_box_y1 + line_h

			--anchor tooltip under the left edge of the label + box group
			--(the default tooltip coords are based on binary button geometry and title width)
			tooltip_x = math.min(label_x, special_x)
			tooltip_y = spec_box_y2 + p_10

			local list_y_size = (num_choices * line_h)

			local list_y_start, list_y_end
			if expand_list_mode_y < 0 then
				--expand up
				list_y_end = spec_box_y2
				list_y_start = list_y_end - list_y_size
			else -- >0 
				--expand down
				list_y_start = spec_box_y1
				list_y_end = list_y_start + list_y_size
			end 

			local list_current_y = list_y_start

			local choices_tbl = {}

			for i_index,v_choice in ipairs(choices_list) do
				--set y
				local new_y = list_current_y + line_h
				--add entry
				choices_tbl[i_index] = {
					box_coor = {
						x1 = list_x,
						y1 = list_current_y,
						x2 = list_x + max_str_width,
						y2 = new_y
					},
					label_coor = {
						x1 = list_x + (x_buf*1.0),
						y1 = list_current_y + y_buf
					},
					label_value = v_choice.choice_str,
					choice_id_key = v_choice.choice_i
				}
				--update additive y
				list_current_y = new_y
			end

			button_info.Elements.choices_info = choices_tbl

			button_info.Elements.special_info = {
				box_coor = {
					x1 = special_x,
					y1 = spec_box_y1,
					x2 = special_x + max_str_width,
					y2 = spec_box_y2
				},
				label_coor = {
					x1 = special_x + (x_buf*1.0),
					y1 = special_y
				},
				choices_framer = {
					x1 = list_x,
					y1 = list_y_start,
					x2 = list_x + max_str_width,
					y2 = list_y_end
				},
				--placeholder shown until UI_BT_StateStart fills in the selected choice.
				--uses the same strings.tbl id the engine uses for its own None entries,
				--so it matches the list entry rather than showing English in a translation
				label_value = ba.XSTR("None", 1673, false),
				choice_id_key = self.UI_BT_List.ID_SPECIAL,
				list_is_minimized = true --must click to open
			}


		end

		button_info.Elements.tooltop_info = {
			background_coor = {
				x1 = tooltip_x,
				y1 = tooltip_y,
				x2 = tooltip_x + tooltip_w + p_10,
				y2 = tooltip_y + tooltip_h
			},
			frame_coor = {
				x1 = tooltip_x - p_1,
				y1 = tooltip_y - p_1,
				x2 = tooltip_x + tooltip_w + p_10,
				y2 = tooltip_y + tooltip_h + p_2
			},
			string_coor = {
				x1 = tooltip_x + p_5,
				y1 = tooltip_y + p_5
			},
			string_value = tooltip_str
		}

	end

	function FotG:UI_BT_HoverHelper(button_info)

		--set hover state
		button_info.hover_active_id = self.UI_BT_List.ID_NIL
		self:UI_BT_MouseMoved(button_info)

	end

	function FotG:UI_BT_StateStart(button_info)

		local get_function = button_info.uibt_get_function 
		if get_function == nil then return end

		--record the current value
		local current_value = get_function(button_info.uibt_unique_key)
		button_info.uibt_set_but_unsaved_value = current_value

		--for dropdown, show the current value's string and minimize drop down list
		if button_info.uibt_ui_type == self.UI_BT_List.TYPE_DropdownList then
			local choices_info = button_info.Elements.choices_info
			local current_val_info
			for _,v_choice in ipairs(choices_info) do
				if v_choice.choice_id_key == current_value then
					current_val_info = v_choice
					break
				end
			end
			if current_val_info ~= nil then
				button_info.Elements.special_info.label_value = current_val_info.label_value
			end

			button_info.Elements.special_info.list_is_minimized = true
		end

		self:UI_BT_HoverHelper(button_info)

	end

	function FotG:UI_BT_InBoxHelper(x, y, button_info) --returns ID of button over, or nil ID

		local elements = button_info.Elements

		local id_key

		--special out if dropdown list and list is minimized
		local isdropdown = (button_info.uibt_ui_type == self.UI_BT_List.TYPE_DropdownList)
		if isdropdown then
			local special_button = elements.special_info
			--return if special button was clicked
			if x > special_button.box_coor.x1 and x < special_button.box_coor.x2 and y > special_button.box_coor.y1 and y < special_button.box_coor.y2 then
				return special_button.choice_id_key
			end
		end

		if (isdropdown and not button_info.Elements.special_info.list_is_minimized) or (not isdropdown) then
			for _,v_choiceinfo in ipairs(elements.choices_info) do
				if x > v_choiceinfo.box_coor.x1 and x < v_choiceinfo.box_coor.x2 and y > v_choiceinfo.box_coor.y1 and y < v_choiceinfo.box_coor.y2 then
					id_key = v_choiceinfo.choice_id_key
					break
				end
			end
		end

		return id_key or self.UI_BT_List.ID_NIL

	end

	function FotG:UI_BT_MouseMoved(button_info)

		if self:UI_BT_EarlyStop(button_info) then return end

		local x = io.getMouseX()
		local y = io.getMouseY()

		local button_over_id = FotG:UI_BT_InBoxHelper(x, y, button_info)

		local nil_val = self.UI_BT_List.ID_NIL

		if button_over_id > nil_val then
			if button_info.hover_active_id <= nil_val then
				FotG:PlaySound_Interface(FotG.sound_index_hover)
			end
			button_info.hover_active_id = button_over_id
		else
			button_info.hover_active_id = nil_val
		end 	

	end

	function FotG:UI_BT_MousePressed(button_info, x, y) --returns if press was consumed

		if self:UI_BT_EarlyStop(button_info) then return end

		x = x or io.getMouseX()
		y = y or io.getMouseY()

		local button_over_id = FotG:UI_BT_InBoxHelper(x, y, button_info)

		local dropdown_type = self.UI_BT_List.TYPE_DropdownList
		local is_binary_button = (button_info.uibt_ui_type == self.UI_BT_List.TYPE_BinaryButton)
		local is_dropdown = (button_info.uibt_ui_type == dropdown_type)

		--only do something if button is not nil
		if button_over_id > self.UI_BT_List.ID_NIL then
			--update temp value
			if is_binary_button then
				--binary button (if here then button was not nil)
				if button_over_id == self.UI_BT_List.ID_OFF then
					button_info.uibt_set_but_unsaved_value = false
				elseif button_over_id == self.UI_BT_List.ID_ON then
					button_info.uibt_set_but_unsaved_value = true
				end

			elseif is_dropdown then
				--dropdown list (if here then button was not nil)
				local list_minimized = button_info.Elements.special_info.list_is_minimized

				if button_over_id == self.UI_BT_List.ID_SPECIAL then
					if list_minimized then
						--if pressed button and list minimized then open
						button_info.Elements.special_info.list_is_minimized = false
					else
						--if pressed button and list maximized then close
						button_info.Elements.special_info.list_is_minimized = true
					end
					--do not save the special button since it is not a valid ID for saving
				elseif button_over_id > self.UI_BT_List.ID_NIL and not list_minimized then
					--if pressed any valid option then set that option and close
					--  minimized list already checked when getting button over value, 
					--  but good to have failsafe checks
					button_info.uibt_set_but_unsaved_value = button_over_id 
					button_info.Elements.special_info.list_is_minimized = true
					--update selected text to show current value's string
					local choices_info = button_info.Elements.choices_info
					for _,v_choice in ipairs(choices_info) do
						if v_choice.choice_id_key == button_over_id then
							button_info.Elements.special_info.label_value = v_choice.label_value
							break
						end
					end
				end

			end

			FotG:PlaySound_Interface(FotG.sound_index_click)

			return true

		else

			return false

		end

	end

	function FotG:UI_BT_DrawHelper_Binary(button_info, is_selected, is_hovering, choice_key)

		local choice_info = button_info.Elements.choices_info[choice_key]

		--choices labels
		if is_selected or is_hovering then
			self:SetColor(self.Colors.ui_lightblue)
		else
			self:SetColor(self.Colors.ui_text_valid)
		end
		gr.drawString(choice_info.label_value, choice_info.label_coor.x1, choice_info.label_coor.y1)

		--rectangle
		local b_coor = choice_info.box_coor
		if is_selected then
			if choice_info.use_red_for_off then
				if is_hovering then
					self:SetColor(self.Colors.lightpink)
				else
					self:SetColor(self.Colors.pink)
				end
			else
				if is_hovering then
					self:SetColor(self.Colors.swy)
				else
					self:SetColor(self.Colors.ui_gold)
				end
			end
			gr.drawLine(b_coor.x1, b_coor.y1, b_coor.x2, b_coor.y2)
			gr.drawLine(b_coor.x1, b_coor.y2, b_coor.x2, b_coor.y1)
		elseif is_hovering then
			self:SetColor(self.Colors.ui_lightblue)
		else
			self:SetColor(self.Colors.ui_border)
		end

		gr.drawRectangle(b_coor.x1, b_coor.y1, b_coor.x2, b_coor.y2, false)
		--FotG:ResetLineWidth()

	end

	function FotG:UI_BT_DrawHelper_Dropdown(button_info)

		local special_tbl = button_info.Elements.special_info
		local choices_tbl = button_info.Elements.choices_info --[choice_key]

		--note special box always have something selected, 
		--so text in special box is always selected color

		local is_minimzed = (button_info.Elements.special_info.list_is_minimized)

		--1. draw special box 
		local spec_box = special_tbl.box_coor
		local hover_active_id = button_info.hover_active_id
		local selected_id = button_info.uibt_set_but_unsaved_value

		local hover_special = (hover_active_id == self.UI_BT_List.ID_SPECIAL)

		--special box core
		if hover_special then
			self:SetColor(self.Colors.ui_list_hover)
		elseif not is_minimzed then
			self:SetColor(self.Colors.ui_list_selected)
		else
			self:SetColor(self.Colors.black)
		end
		gr.drawRectangle(spec_box.x1, spec_box.y1, spec_box.x2, spec_box.y2, true)

		--special box frame
		if hover_special or (not is_minimzed) then
			self:SetColor(self.Colors.ui_lightblue)
		else
			self:SetColor(self.Colors.ui_border)
		end

		gr.drawRectangle(spec_box.x1, spec_box.y1, spec_box.x2, spec_box.y2, false)
		--FotG:ResetLineWidth()

		--special box text
		if hover_special or (not is_minimzed) then
			self:SetColor(self.Colors.ui_lightblue)
		else
			self:SetColor(self.Colors.ui_text_valid)
		end
		gr.drawString(special_tbl.label_value, special_tbl.label_coor.x1, special_tbl.label_coor.y1)


		--2. draw dropdown list

		--do not draw if minimized
		if is_minimzed then
			return 
		end

		--rectangle background
		local c_frame = special_tbl.choices_framer
		self:SetColor(self.Colors.black)
		gr.drawRectangle(c_frame.x1, c_frame.y1, c_frame.x2, c_frame.y2, true)

		--line items with hover if needed

		--draw hovered and selected items
		local hover_choice, current_choice
		for i_idx,v_choice in ipairs(choices_tbl) do
			if v_choice.choice_id_key == hover_active_id then
				hover_choice = v_choice
			end
			if v_choice.choice_id_key == selected_id then
				current_choice = v_choice
			end
		end

		if hover_choice ~= nil and hover_choice ~= current_choice then
			self:SetColor(self.Colors.ui_list_hover)
			local box = hover_choice.box_coor
			gr.drawRectangle(box.x1, box.y1, box.x2, box.y2, true)
		end

		if current_choice ~= nil then
			if hover_choice == current_choice then
				self:SetColor(self.Colors.ui_list_hover)
			else
				self:SetColor(self.Colors.ui_list_selected)
			end
			local box = current_choice.box_coor
			gr.drawRectangle(box.x1, box.y1, box.x2, box.y2, true)
			self:SetColor(self.Colors.ui_lightblue)
			gr.drawString(current_choice.label_value, current_choice.label_coor.x1, current_choice.label_coor.y1)
		end

		--draw all other items names
		self:SetColor(self.Colors.ui_text_valid)
		for i_choiceidx, v_choiceinfo in ipairs(choices_tbl) do
			if i_choiceidx ~= selected_id then
				gr.drawString(v_choiceinfo.label_value, v_choiceinfo.label_coor.x1, v_choiceinfo.label_coor.y1)
			end
		end

		--rectangle frame
		self:SetColor(self.Colors.ui_lightblue)
		gr.drawRectangle(c_frame.x1, c_frame.y1, c_frame.x2, c_frame.y2, false)

	end

	function FotG:UI_BT_DrawOptions(button_info)

		if self:UI_BT_EarlyStop(button_info) then return end

		local current_value = button_info.uibt_set_but_unsaved_value

		local hover_active_id = button_info.hover_active_id

		self:SetFont(self.Font_Options.font_medium)

		local elements = button_info.Elements

		local is_binary_button = (button_info.uibt_ui_type == self.UI_BT_List.TYPE_BinaryButton)
		local is_dropdown = (button_info.uibt_ui_type == self.UI_BT_List.TYPE_DropdownList)

		--main label text
		self:SetColor(self.Colors.ui_text_valid)
		local title = elements.title_info
		gr.drawString(title.string_value, title.string_coor.x1, title.string_coor.y1)

		if is_binary_button then
			--binary button
			--1 = off
			local b_off_selected = (not current_value)
			local b_off_hover = (hover_active_id == self.UI_BT_List.ID_OFF)
			self:UI_BT_DrawHelper_Binary(button_info, b_off_selected, b_off_hover, 1)

			--2 = on
			local b_on_selected = (current_value)
			local b_on_hover = (hover_active_id == self.UI_BT_List.ID_ON)
			self:UI_BT_DrawHelper_Binary(button_info, b_on_selected, b_on_hover, 2)

		elseif is_dropdown then
			self:UI_BT_DrawHelper_Dropdown(button_info)

		end

		--tooltip
		local tip = elements.tooltop_info
		if tip ~= nil then
			local tip_str = tip.string_value
			if hover_active_id > self.UI_BT_List.ID_NIL and tip_str ~= nil and tip_str ~= "" then
				self:SetColor(self.Colors.black)
				gr.drawRectangle(tip.background_coor.x1, tip.background_coor.y1, tip.background_coor.x2, tip.background_coor.y2)
				self:SetColor(self.Colors.ui_border)
				gr.drawRectangle(tip.frame_coor.x1, tip.frame_coor.y1, tip.frame_coor.x2, tip.frame_coor.y2, false)
				self:SetColor(self.Colors.ui_text_valid)
				gr.drawString(tip_str, tip.string_coor.x1, tip.string_coor.y1)
			end
		end

	end


--Code: Looping Hooks

	function FotG:UI_BT_OnStateStart()

		local game_state = ba.getCurrentGameState().Name
		local instate_button_names = self.UI_BT_List.Buttons_Gamestates[game_state]
		if instate_button_names == nil then return end

		local button_data = self.UI_BT_List.Buttons_Data
		for _, v_buttonname in ipairs(instate_button_names) do
			self:UI_BT_StateStart(button_data[v_buttonname])
		end

	end

	function FotG:UI_BT_OnTabHelper()

		local instate_button_names = self.UI_BT_List.Buttons_Gamestates["GS_STATE_OPTIONS_MENU"]
		if instate_button_names == nil then return end

		local dropdown_type = self.UI_BT_List.TYPE_DropdownList
		local button_data = self.UI_BT_List.Buttons_Data

		for _, v_buttonname in ipairs(instate_button_names) do

			local button_info = button_data[v_buttonname]

			--minimize all drop downs
			if (button_info.uibt_ui_type == dropdown_type) then
				button_info.Elements.special_info.list_is_minimized = true
			end

			--refresh hover state
			self:UI_BT_HoverHelper(button_info)

		end

	end

	function FotG:UI_BT_OnFrame()

		local game_state = ba.getCurrentGameState().Name
		local instate_button_names = self.UI_BT_List.Buttons_Gamestates[game_state]
		if instate_button_names == nil then return end

		local button_data = self.UI_BT_List.Buttons_Data
		for _, v_buttonname in ipairs(instate_button_names) do
			self:UI_BT_DrawOptions(button_data[v_buttonname])
		end

	end

	function FotG:UI_BT_OnMouseMoved()

		local game_state = ba.getCurrentGameState().Name
		local instate_button_names = self.UI_BT_List.Buttons_Gamestates[game_state]
		if instate_button_names == nil then return end

		local button_data = self.UI_BT_List.Buttons_Data
		for _, v_buttonname in ipairs(instate_button_names) do
			self:UI_BT_MouseMoved(button_data[v_buttonname])
		end

	end

	function FotG:UI_BT_OnMousePressed()

		local game_state = ba.getCurrentGameState().Name
		local instate_button_names = self.UI_BT_List.Buttons_Gamestates[game_state]
		if instate_button_names == nil then return end

		local button_data = self.UI_BT_List.Buttons_Data
		local x, y = io.getMouseX(), io.getMouseY()
		local consumed = false
		local consumed_btn_name
		for _, v_buttonname in ipairs(instate_button_names) do
			if not consumed then
				consumed = self:UI_BT_MousePressed(button_data[v_buttonname], x, y)
				if consumed then 
					consumed_btn_name = v_buttonname
					break
				end
			end
		end

		--force all dropdown lists to minimized except if one was clicked and consumed
		local dropdown_type = self.UI_BT_List.TYPE_DropdownList
		for _,v_btninfo in pairs(self.UI_BT_List.Buttons_Data) do
			if (v_btninfo.uibt_ui_type == dropdown_type) and (v_btninfo.uibt_unique_key ~= consumed_btn_name) then
				v_btninfo.Elements.special_info.list_is_minimized = true
			end
		end

	end

	function FotG:UI_BT_OnOptionsAccepted()

		local needs_saved = false
		local dropdown_type = self.UI_BT_List.TYPE_DropdownList

		for k_buttonname, v_buttoninfo in pairs(self.UI_BT_List.Buttons_Data) do
			--if a value was changed while in the options screen 
			--then set the value and save it
			local unsaved_val = v_buttoninfo.uibt_set_but_unsaved_value

			local saved_value
			local get_function = v_buttoninfo.uibt_get_function 
			if get_function ~= nil then 
				saved_value = get_function(k_buttonname)
			end

			if (unsaved_val ~= nil) and (unsaved_val ~= saved_value) then --could be true, false, etc so use: val ~= nil
				local set_function = v_buttoninfo.uibt_set_function
				if set_function ~= nil then 
					set_function(unsaved_val, k_buttonname) 
					needs_saved = true
					--we don't actually have to set the temp value to nil as it will get reset on state start
					--plus setting it to nil makes the UI look like the value reverts to default values 
				end
			end

			--also minimize all drop downs
			if (v_buttoninfo.uibt_ui_type == dropdown_type) then
				v_buttoninfo.Elements.special_info.list_is_minimized = true
			end
		end

		if needs_saved and opt ~= nil then
			opt.persistChanges()
			self:UI_BT_WriteJSON()
		end

	end

	function FotG:UI_BT_OnOptionsDiscarded()

		--ensure temp values get cleaned up
		local dropdown_type = self.UI_BT_List.TYPE_DropdownList

		for _, v_buttoninfo in pairs(self.UI_BT_List.Buttons_Data) do
			--clear all temp values
			if v_buttoninfo.uibt_set_but_unsaved_value ~= nil then
				--we don't actually have to set the temp value to nil as it will get reset on state start
				--plus setting it to nil makes the UI look like the value reverts to default values 
			end

			--also minimize all drop downs
			if (v_buttoninfo.uibt_ui_type == dropdown_type) then
				v_buttoninfo.Elements.special_info.list_is_minimized = true
			end
		end

	end


--Code: Create Button

	function FotG:UI_BT_Add(button_info_tbl)

		--add a button to the button list
		--should be run as early as possible, such as On Game Initialization

		local new_bt_info = {
			uibt_gamestate = button_info_tbl.uibt_gamestate,

			uibt_ui_type = button_info_tbl.uibt_ui_type,

			uibt_unique_key = button_info_tbl.uibt_unique_key,
			uibt_default_val = button_info_tbl.uibt_default_val or false,
			uibt_title_str = button_info_tbl.uibt_title_str,

			uibt_read_from_ini = button_info_tbl.uibt_read_from_ini ,

			uibt_choices_list = button_info_tbl.uibt_choices_list,

			uibt_tool_tip = button_info_tbl.uibt_tool_tip,

			uibt_list_minimum_string = button_info_tbl.uibt_list_minimum_string or "ZZZZZZZZZZZZ",
			uibt_label_minimum_string = button_info_tbl.uibt_label_minimum_string, --optional, sets label column width so dropdown boxes align
			uibt_list_expand_mode_x = button_info_tbl.uibt_list_expand_mode_x or 1,
			uibt_list_expand_mode_y = button_info_tbl.uibt_list_expand_mode_y or 1,

			uibt_set_but_unsaved_value = nil,

			uibt_origin_x = button_info_tbl.uibt_origin_x,
			uibt_origin_y = button_info_tbl.uibt_origin_y,
			uibt_offset_x = button_info_tbl.uibt_offset_x,
			uibt_offset_y = button_info_tbl.uibt_offset_y,
			uibt_offset_as_coor = button_info_tbl.uibt_offset_as_coor or false,

			uibt_multi_allowed = button_info_tbl.uibt_multi_allowed,

			uibt_options_tab = button_info_tbl.uibt_options_tab or FotG.OTab_ID_None,

			uibt_get_function = button_info_tbl.uibt_get_function,

			uibt_set_function = button_info_tbl.uibt_set_function,

			hover_active_id = FotG.UI_BT_List.ID_NIL

		}

		local game_state = button_info_tbl.uibt_gamestate
		local button_name = button_info_tbl.uibt_unique_key

		if self.UI_BT_List.Buttons_Gamestates[game_state] == nil then
			self.UI_BT_List.Buttons_Gamestates[game_state] = {}
		end

		--add button names to game state table tracker
		table.insert(self.UI_BT_List.Buttons_Gamestates[game_state], button_name)

		--add actual button data to buttons table
		self.UI_BT_List.Buttons_Data[button_name] = new_bt_info

	end


--Code: Create Hooks

	function FotG:UI_BT_RefreshResolution()

		--does not need to be done if game changes between window or fullscreen, 
		--since resolution did not actually change

		--should be run though if the font multiplier changes

		--update resolution of all buttons, regardless of other states
		for _, v_button in pairs(self.UI_BT_List.Buttons_Data) do
			self:UI_BT_CheckResolution(v_button)
		end

	end

	function FotG:CheckSave_FontMultiplier()

		--checks what current font multiplier is and saves the value if it is different

		local currently_saved_fm = self.UI_BT_List.Font_Multiplier

		local opt_index = FotG.options_name_i_list["Game.FontScaleFactor"]
		if opt_index == nil then 
			return false
		end
		local option = opt.Options[opt_index]

		if option == nil then
			return false
		end

		local val = tostring(option.Value)
		if val == nil then
			val = 1
		end
		local actual_current_fm = tonumber(val)
		if type(actual_current_fm) ~= "number" then
			actual_current_fm = 1
		end

		if currently_saved_fm ~= actual_current_fm then
			self.UI_BT_List.Font_Multiplier = actual_current_fm
			return true
		end

		return false

	end

	function FotG:UI_BT_Initialize()

		--this function should be run only after all buttons have been added 
		--in other words run all the button additions during Game Initialize and 
		--then run this function after that, such as On State Start of Player Select

		-- create hooks for all added buttons
		for k_gamestate, _ in pairs(FotG.UI_BT_List.Buttons_Gamestates) do

			engine.addHook("On State Start", function() 
					FotG:UI_BT_OnStateStart()
				end,
				{State = k_gamestate}
			)

			engine.addHook("On Frame", function() 
					FotG:UI_BT_OnFrame()
				end,
				{State = k_gamestate}
			)

			engine.addHook("On Mouse Moved", function() 
					FotG:UI_BT_OnMouseMoved()
				end,
				{State = k_gamestate}
			)

			engine.addHook("On Mouse Pressed", function() 
					FotG:UI_BT_OnMousePressed()
				end,
				{State = k_gamestate}
			)

		end

		self:CheckSave_FontMultiplier()

		self:FontInitialize()
		self:UI_BT_RefreshResolution()
	end


--Hooks
if not IS_STANDALONE then
	--setup hooks, do this hear so we have had time to register them in other scripts
	engine.addHook("On State Start", function() 
			FotG:UI_BT_Initialize()
		end,
		{State="GS_STATE_INITIAL_PLAYER_SELECT"}
	)


	--deal with switching players
	engine.addHook("On State End", function() 
			if tostring(hv.NewState) ~= "GS_STATE_QUIT_GAME" then
				FotG:UI_BT_ReadJSON()
			end
		end,
		{State="GS_STATE_INITIAL_PLAYER_SELECT"}
	)

	engine.addHook("On State End", function() 
			if tostring(hv.NewState) ~= "GS_STATE_QUIT_GAME" then
				FotG:UI_BT_ReadJSON()
			end
		end,
		{State="GS_STATE_BARRACKS_MENU"}
	)

	engine.addHook("On State Start", function() 
			if tostring(hv.NewState) ~= "GS_STATE_QUIT_GAME" and tostring(hv.OldState) == "GS_STATE_BARRACKS_MENU" then
				FotG:UI_BT_ReadJSON()
			end
		end,
		{State="GS_STATE_OPTIONS_MENU"}
	)


	--deal with refreshing tabs
	engine.addHook("On Options Menu Tab Changed", function() 
			FotG:UI_BT_OnTabHelper()
		end,
		{State="GS_STATE_OPTIONS_MENU"}
	)

	--deal with accepting or discarding options
	engine.addHook("On Options Menu Closed", function() 
			if hv.OptionsAccepted then
				FotG:UI_BT_OnOptionsAccepted()
			else 
				FotG:UI_BT_OnOptionsDiscarded()
			end
		end,
		{State="GS_STATE_OPTIONS_MENU"}
	)

	engine.addHook("On HUD Config Menu Closed", function() 
			if hv.OptionsAccepted then
				FotG:UI_BT_OnOptionsAccepted()
			else 
				FotG:UI_BT_OnOptionsDiscarded()
			end
		end,
		{State="GS_STATE_HUD_CONFIG"}
	)

	engine.addHook("On Controls Config Menu Closed", function() 
			if hv.OptionsAccepted then
				FotG:UI_BT_OnOptionsAccepted()
			else 
				FotG:UI_BT_OnOptionsDiscarded()
			end
		end,
		{State="GS_STATE_CONTROL_CONFIG"}
	)


	--deal with ensuring FotG json stays synced with setting via advanced in-game options menu
	engine.addHook("On State End", function() 
			if tostring(hv.NewState) ~= "GS_STATE_QUIT_GAME" then
				--Also do write at end of in-game options,
				--in case any ini options are also saved in FotG CFG.
				--Fine to do writes since it does not change the value,
				--and ensures the FotG CFG is equal to ini regarding any common variables.
				--Recall, ini values are already saved or discarded by the time we hit here,
				--so the ini value is correct and can be saved. 
				FotG:UI_BT_WriteJSON()

				if FotG:CheckSave_FontMultiplier() then
					FotG:FontInitialize()
					FotG:UI_BT_RefreshResolution()
				end
			end
		end,
		{State="GS_STATE_INGAME_OPTIONS"}
	)
end