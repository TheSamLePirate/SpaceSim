Object_Info_Help = {
	default_title = "Squadron Roles",
	default_seperator = ": ",
	custom_hud_name_key_frame = "CustomRoleGauge_Frame",
	custom_hud_name_key_body = "CustomRoleGauge_Body",
	base_gauge_id = 18 --18 is "DIRECTIVES_VIEW"
}

--Code
	--reset all 
	function Object_Info_Help:Reset()

		self.object_role_list = nil
		self.object_role_list = {}
		self.gauge_title = self.default_title
		self.seperator = self.default_seperator
		self.sexp_toggled_on = false
		self.mission_allows_player_toggle = false

		self:Gauge_UpdateText()
		self:Gauge_Toggle(false)

	end

	function Object_Info_Help:StatusHelper()

		-- run when come back into mission after an option screen

		--if it is supposed to be on make sure it is on b/c it has mission critical info
		--otherwise do what parent gauge does

		if self.mission_allows_player_toggle then
			if hu.getHUDConfigShowStatus(self.base_gauge_id) and self.sexp_toggled_on then
				--should be on
				self:Gauge_Toggle(true)
			else
				--should be off
				--only force it to turn off if it's actually on in the first place
				--if already off then no need to turn off again
				if self.sexp_toggled_on then
					self:Gauge_Toggle(false)
				end
			end
		else
			--ensure that even if parent turned it off then this custom gauge still enabled
			--in other words, only way to turn off gauge is with SEXP call, not with this auto checking
			if self.sexp_toggled_on then
				self:Gauge_Toggle(true)
			end
		end

	end

	--toggles gauge
	function Object_Info_Help:Gauge_Toggle(required_bool)

		if IS_STANDALONE then 
			return 
		end

		--reminder, this gauge always has to be toggled on via SEXP, which will then trigger this function again

		--active status set by FREDDer so player should not be able to turn off?
		--set color
		--local color = hu.getHUDGaugeColor("Directives", true)

		if required_bool == true or required_bool == false then

			local can_set = false
			if required_bool then
				--script has been ordered to try and turn it on (whether by FREDer or auto check), only do this if:
				--  mission says player cannot toggle it off and this function call wants it on
				--  mission says player can toggle it off and the parent gauge is on
				if self.mission_allows_player_toggle then
					--if player can toggle it, then only turn it on if the player wants it on (ie parent gauge is on)
					--ie the parent gauge is on
					if hu.getHUDConfigShowStatus(self.base_gauge_id) then
						can_set = true
					end
				else
					--if player cannot toggle the gauge and 
					--the function call wants it on then make sure to set it to on
					can_set = true
				end
			else
				--script has been ordered to try and turn it off (whether by FREDer or auto check), only do this if:
				--  player can turn it off and either the parent gauge is off or sexp is forcing it off
				--  player cannot turn it off but script is turning it off itself
				if self.mission_allows_player_toggle then
					if (not hu.getHUDConfigShowStatus(self.base_gauge_id)) or (self.sexp_toggled_on == false) then
						can_set = true
					end
				else
					can_set = true
				end
			end

			if can_set then
				mn.evaluateSEXP("( hud-set-custom-gauge-active ( "..tostring(required_bool).." ) !"..self.custom_hud_name_key_frame.."! )")
				mn.evaluateSEXP("( hud-set-custom-gauge-active ( "..tostring(required_bool).." ) !"..self.custom_hud_name_key_body.."! )")
			end

			--if enabling then force readable color
			if required_bool then
				--reminder, the sexp version sets a flag that means nothing else besides sexp can change color
				--mn.evaluateSEXP("( hud-set-color !"..self.custom_hud_name_key_frame.."! 200 200 200 )") 
				--^^do not set frame color since users may configure (similar to how message box allows setting frame color)
				mn.evaluateSEXP("( hud-set-color !"..self.custom_hud_name_key_body.."! 200 200 200 )")
			end
		end

	end

	--updates display text
	function Object_Info_Help:Gauge_UpdateText()

		local gauge_frame = hu.getHUDGaugeHandle(self.custom_hud_name_key_frame)
		local gauge_body = hu.getHUDGaugeHandle(self.custom_hud_name_key_body)

		if gauge_frame == nil or gauge_body == nil then return end

		--local concatenate text into table
		local n = "\n"
		local txt = ""

		for _,v in ipairs(self.object_role_list) do
			local sep = self.seperator or ": "
			txt = txt .. v.name .. sep .. v.role_description .. n
		end

		--set updated text to gauge
		gauge_frame.Text = self.gauge_title
		gauge_body.Text = txt

	end

	--insert object to Object_Info_Help.object_role_list
	function Object_Info_Help:InsertObjectRole(object_name, role_description)

		if object_name == nil then return end

		--remove entry if it exists to replace it, since remove entry matches by name only once
		self:RemoveObjectRole(object_name)

		role_description = role_description or ""

		table.insert(self.object_role_list, {name = object_name, role_description = role_description})
		--table.sort(self.object_role_list)

		self:Gauge_UpdateText()

	end

	--update object
	function Object_Info_Help:UpdateObjectRole(object_name, role_description)

		if object_name == nil then return end

		role_description = role_description or ""

		--find location in list where this name is 
		for _,v in ipairs(self.object_role_list) do
			if object_name == v.name then 
				v.role_description = role_description
			end
		end

		self:Gauge_UpdateText()

	end

	--remove object from Object_Info_Help.object_role_list
	function Object_Info_Help:RemoveObjectRole(object_name)

		if object_name == nil then return end

		--find location in list where this name is 
		local found_item = false
		for i,v in ipairs(self.object_role_list) do
			if object_name == v.name then 
				table.remove(self.object_role_list, i)
				found_item = true
				break
			end
		end

		if found_item then
			self:Gauge_UpdateText()
		end

	end

	--clear items
	function Object_Info_Help:ClearAll()

		self.object_role_list = nil
		self.object_role_list = {}

		self:Gauge_UpdateText()

	end

	--update title
	function Object_Info_Help:SetTitle(title_string)

		if type(title_string) ~= "string" then return end
		
		self.gauge_title = title_string

		self:Gauge_UpdateText()

	end

	--update separator
	function Object_Info_Help:SetSeperator(seperator_str)

		if type(seperator_str) ~= "string" then return end
		
		self.seperator = seperator_str

		self:Gauge_UpdateText()

	end

	--helper function for toggling
	function Object_Info_Help:HelperToggleFull(toggle_status, mission_allows_player_toggle)

		-- make sure to set visibility status and sexp status first, since toggle call uses those
		if type(mission_allows_player_toggle) ~= "boolean" then
			mission_allows_player_toggle = false
		end
		Object_Info_Help.mission_allows_player_toggle = mission_allows_player_toggle

		if type(toggle_status) == "boolean" then
			Object_Info_Help.sexp_toggled_on = toggle_status
			Object_Info_Help:Gauge_Toggle(toggle_status)
		end

	end


	--sexp API for Object_Info_Help:InsertObjectRole(object_name)
	mn.LuaSEXPs["role-gauge-add-object"].Action = function(...) 
		
		if ba.MultiplayerMode then return end

		if #arg <= 0 then return end
		
		for _, value in ipairs(arg) do
		
			local objectname = value[1]
			local objectdescription = value[2]
			Object_Info_Help:InsertObjectRole(objectname, objectdescription)
		
		end		
		
	end

	--sexp API for Object_Info_Help:UpdateObjectRole(object_name)
	mn.LuaSEXPs["role-gauge-update-object"].Action = function(...) 
		
		if ba.MultiplayerMode then return end

		if #arg <= 0 then return end
		
		for _, value in ipairs(arg) do
		
			local objectname = value[1]
			local objectdescription = value[2]
			Object_Info_Help:UpdateObjectRole(objectname, objectdescription)
		
		end
		
	end

	mn.LuaSEXPs["role-gauge-update-object-num"].Action = function(...)

		if ba.MultiplayerMode then return end

		if #arg <= 0 then return end
		
		for _, value in ipairs(arg) do
		
			local objectname = value[1]
			local objectdescription = value[2]
			Object_Info_Help:UpdateObjectRole(objectname, objectdescription)
		
		end
		
	end

	--sexp API for Object_Info_Help:InsertObjectRole(object_name)
	mn.LuaSEXPs["role-gauge-remove-object"].Action = function(...) 
	
		if ba.MultiplayerMode then return end

		if #arg <= 0 then return end
		
		for _, value in ipairs(arg) do
		
			local objectname = value[1]
			Object_Info_Help:RemoveObjectRole(objectname)
		
		end

	end

	mn.LuaSEXPs["role-gauge-toggle"].Action = function(toggle_status, mission_allows_player_toggle)

		if ba.MultiplayerMode then return end

		Object_Info_Help:HelperToggleFull(toggle_status, mission_allows_player_toggle)
	
	end

	mn.LuaSEXPs["role-gauge-clear-all"].Action = function()

		if ba.MultiplayerMode then return end

		Object_Info_Help:ClearAll()

	end

	mn.LuaSEXPs["role-gauge-set-title"].Action = function(title_str)

		if ba.MultiplayerMode then return end
	
		Object_Info_Help:SetTitle(title_str)

	end

	mn.LuaSEXPs["role-gauge-set-separator"].Action = function(seperator_str)

		if ba.MultiplayerMode then return end

		Object_Info_Help:SetSeperator(seperator_str)

	end

--

--Hooks
if not IS_STANDALONE then 
	engine.addHook("On Gameplay Start", function() 
			Object_Info_Help:Reset()
		end
	)

	engine.addHook("On Mission About To End", function() 
			Object_Info_Help:Reset()
		end
	)

	engine.addHook("On State Start", function() 
			--On State Start runs before On Gameplay Start, but On State Start runs every time we come back into the game, even from a paused menu
			--so we do not want to always run the setup scripts, but we do want to check the draw HUD status and run a sexp if needed, but only after time has passed
			if MTIME_OVER_P1 then
				Object_Info_Help:StatusHelper()
			end
		end,
		{State="GS_STATE_GAME_PLAY"}
	)
end
