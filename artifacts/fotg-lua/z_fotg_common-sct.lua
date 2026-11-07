--common functions for FotG scripting

--Code

	-- Global Helper Variables
	IS_STANDALONE = false
	if ba.inStandalone() then
		IS_STANDALONE = true
		ba.print("FotG Standalone Status: Standlone is enabled \n")
	end

	MTIME_OVER_P1 = false


	-- FotG Common Functions 
	FotG = {
		--Font options are from fonts.tbl
		Font_Options = {
			font_small="font_small", 
			font_medium="font_medium", 
			font_bold_medium="font_bold_medium", 
			font_large="font_large", 
			font_bold_large="font_bold_large"
		},

		Colors = {
			yellow = {255, 255, 122},
			swy = {255, 207, 71},
			gold = {255, 148, 18},
			gray = {130, 130, 130},
			darkgray = {35, 35, 35},
			lightgray = {85, 85, 85},
			black = {0, 0, 0},
			lightblue = {31, 190, 214},
			red = {126, 6, 6},
			lightred = {185, 35, 35},
			brightred = {225, 6, 6},
			pink = {175, 90, 82},
			lightpink = {225, 100, 90},
			green = {0, 120, 0},
			orange = {212, 91, 18},
			white = {255, 255, 255},
			dimwhite = {200, 200, 200},
			ui_base = {0, 22, 45},
			ui_border = {130, 130, 130},
			ui_grid = {11, 30, 49},
			ui_text_valid = {210, 210, 210},
			ui_text_invalid = {255, 135, 135},
			ui_gold = {200, 170, 90, 1.0},
			ui_lightblue = {190, 215, 255, 1.0},
			--special ones that use alpha
			ui_list_selected = {35, 35, 35, 1.0},
			ui_list_hover = {85, 85, 85, 0.75},
		},

		Textures_Can_Load = true,

		NebulaSliderCurrent = 5, --particles effect really
		NebulaLowSetting = 2,

		--IDs from FSO: 0 = Options Tab, 1 = Multi Tab, and 2 = Details Tab
		OTab_ID_Current = -1,
		OTab_ID_None = -1,
		OTab_ID_Main = 0,
		OTab_ID_Multi = 1,
		OTab_ID_Detail = 2,

		use_ship_collision_scripts = false,

		texname_galaxybg = "Skb_Str_01_Wht",
	
		texname_galaxymap = "GCW_T_Galaxy",
		texname_galaxyplanets = "GCW_T_PS",
		texhelp_nframes_gplts = 87, --get from number of frames in GCW_T_PS.eff,

		--from #Interface Sounds Start in sounds.tbl
		sound_index_click = 0,
		sound_index_fail = 10,
		sound_index_success = 4,
		sound_index_confirm = 62,
		sound_index_toggle = 6,
		sound_index_hover = 17,
		sound_index_keyboard = 16
	}

	FotG.DummyClasses = {["Hyperspace_Tunnel"]=true, ["Explosion_Dummy"]=true, ["Command_Controller_Ship"]=true}

	FotG.VECTOR_ZERO = ba.createVector(0, 0, 0)
	FotG.VECTOR_Z1 = ba.createVector(0, 0, 1)

	--Audio
	function FotG:PlaySound_Interface(snd_num)

		if snd_num ~= nil then
			ad.playInterfaceSound(snd_num)
		end

	end

	--Color Setting
	function FotG:SetColor(color, alpha)

		if color ~= nil then
			alpha = alpha or color[4] or 1.0
			if alpha < 0 then
				alpha = 0
			end
			if alpha > 1.0 then
				alpha = 1.0
			end
			gr.setColor(color[1], color[2], color[3], alpha*255)
		end

	end

	--Get Planet X and Y Scale
	function FotG:BackgroundXYScale(xscale, print_error)

		--recall scales need to be < 18 and within this function > 9.5 is undefined
		--so limit to 9.45 -> 16.89
		if xscale > 9.45 then
			if print_error then
				ba.print("Warning: Background X scale set to "..xscale..", which is above 9.45 limit! \n")
			end
			xscale = 9.45
		end

		local yscale = (17.3 * math.asin((1/9.5) * xscale)) - (0.9 * xscale)
		if yscale > 17.9 then
			if print_error then
				ba.print("Warning: Background Y scale calculated to "..yscale.." (using X scale of "..xscale.."). Resulting Y Scale is above 17.9 limit! \n")
			end
			yscale = 17.9
		end

		return xscale, yscale

	end

	--Dynamic Scaling
	function FotG:ScaleR(value, screen_width)

		screen_width = screen_width or gr.getScreenWidth() or 1600
		return math.ceil(value * (screen_width/1600))  --same as HUD gauges table

	end

	function FotG:Scale_UI(origin_x, origin_y, offset_x, offset_y, screen_width, screen_height)

		-- Calculate the current screen's aspect ratio
		screen_width = screen_width or gr.getScreenWidth() or 1600
		screen_height = screen_height or gr.getScreenHeight() or 900
		local current_ratio = screen_width / screen_height

		-- Calculate the target 4:3 aspect ratio or screen if stretched
		local target_ratio
		if gr.isMenuStretched() then
			target_ratio = current_ratio
		else
			target_ratio = 4/3
		end

		-- Initialize variables for the drawable area dimensions
		local drawable_width, drawable_height
		local x_helper, y_helper = 0, 0

		-- Determine the drawable area based on the aspect ratio comparison
		if current_ratio > target_ratio then
			-- Screen is wider than 4:3 (e.g., 16:9), so black bars on sides
			drawable_height = screen_height
			drawable_width = drawable_height * target_ratio
			x_helper = (screen_width - drawable_width) / 2
		else
			-- Screen is taller than 4:3 (e.g., 3:2), so black bars on top/bottom
			drawable_width = screen_width
			drawable_height = drawable_width / target_ratio
			y_helper = (screen_height - drawable_height) / 2
		end

		-- Calculate the final position based on the origin and offset
		-- origin_x and origin_y are normalized values (0.0 to 1.0) within the 4:3 area
		-- offset_x and offset_y are pixel offsets from that calculated position
		local final_x = x_helper + (origin_x * drawable_width) + self:ScaleR(offset_x, drawable_width)
		local final_y = y_helper + (origin_y * drawable_height) + self:ScaleR(offset_y, drawable_width)

		return {
			x = final_x,
			y = final_y
		}

	end

	function FotG:SetLineWidth(value, screen_width)

		local line_width = self:ScaleR(value or 1, screen_width)
		if line_width < 1 then
			line_width = 1 
		end

		gr.setLineWidth(line_width)

	end

	function FotG:ResetLineWidth()

		gr.setLineWidth(1)

	end

	function FotG:Get_Coordinates(pos_oo)

		local pos_x, pos_y
		if pos_oo.screen ~= nil then
			pos_x = pos_oo.screen.x
			pos_y = pos_oo.screen.y
		else
			pos_x = gr.getScreenWidth()
			pos_y = gr.getScreenHeight()
		end
		local standard = pos_x

		local off_x, off_y 
		if pos_oo.get_values_for_ui then
			return self:Scale_UI(pos_oo.origin.x, pos_oo.origin.y, pos_oo.offset.x, pos_oo.offset.y, pos_x, pos_y)
		elseif pos_oo.do_not_scale_offset then
			off_x = pos_oo.offset.x
			off_y = pos_oo.offset.y
		else
			off_x = self:ScaleR(pos_oo.offset.x, standard)
			off_y = self:ScaleR(pos_oo.offset.y, standard)
		end

		return { 
			x = (pos_oo.origin.x * pos_x) + off_x, 
			y = (pos_oo.origin.y * pos_y) + off_y,
		}

	end

	function FotG:GetValidShip(shipname) --returns Ship object or nil 

		if shipname == nil then return nil end
		local mn_ships = mn.Ships
		if mn_ships == nil then return nil end

		local ship = mn_ships[shipname]
		if ship ~= nil and ship:isValid() and (shipname == ship.Name) then 
			return ship
		else
			return nil
		end

	end

	function FotG:GetPlayerShip() --returns Ship object or nil 

		local ply = hv.Player
		if ply ~= nil and ply:isValid() then
			return self:GetValidShip(tostring(ply))
		else
			return nil
		end

	end


	--FONT Setting 
	function FotG:FontScaler(current_size, screen_width, screen_height, base_width, no_lower)

		--copied from FSO's function <calculate_auto_font_size(>

		screen_width = screen_width or gr.getScreenWidth()
		screen_height = screen_height or gr.getScreenHeight()

		local vmin = math.min(screen_width, screen_height)
		base_width = base_width or 1080
		local baseSize = vmin * (current_size / base_width)

		local final = math.round(baseSize)

		if no_lower and math.abs(current_size) > final then
			final = current_size
		end

		return final

	end

	function FotG:FontInitialize()

		--reset font table since resolution may have changed with game restart
		self.font_list_data = nil
		self.font_list_data = {}

		if gr == nil then return end

		--save current font
		local current_font = gr.CurrentFont
		if current_font == nil then return end

		local screen_width = gr.getScreenWidth()
		local screen_height = gr.getScreenHeight()
		if screen_width == nil or screen_height == nil then return end

		local base_width = 1080

		--cache font values 
		for k_fname, _ in pairs(self.Font_Options) do

			gr.CurrentFont = gr.Fonts[k_fname]

			local font_height = gr.CurrentFont.Height

			--recall bottom offset is positive
			local offset_bottom = FotG:FontScaler(gr.CurrentFont.BottomOffset, screen_width, screen_height, base_width, true)
			--gr.CurrentFont.BottomOffset = offset_bottom

			--local offset_top = FotG:FontScaler(gr.CurrentFont.TopOffset, screen_width, screen_height, base_width, true)
			--gr.CurrentFont.TopOffset = offset_top

			self.font_list_data[k_fname] = {
				f_buf = math.round(offset_bottom * 0.75),
				f_line_h = font_height, 
				f_index = k_fname
			}
		end

		--set back to saved current font
		gr.CurrentFont = current_font

	end

	function FotG:SetFont(font_sizename, return_values) --takes "font_small", "font_medium", or "font_large", sets the font and returns the f_buf, f_line_h, f_index, and f_res

		--get font data for that resolution and size and set the font
		gr.CurrentFont = gr.Fonts[font_sizename]

		if return_values then
			return self.font_list_data[font_sizename]
		else
			return
		end

	end


	--Image Loading
	function FotG:LoadTextures()

		if IS_STANDALONE then return end

		GCW_GALAXY_BGR = nil
		GCW_GALAXY_MAP = nil
		GCW_GALAXY_PLT = nil

		if not FotG.Textures_Can_Load then return end

		GCW_GALAXY_BGR = gr.loadTexture(self.texname_galaxybg)
		--print("FotG: Texture Update-loading texture "..self.texname_galaxybg.." \n")

		GCW_GALAXY_MAP = gr.loadTexture(self.texname_galaxymap)
		--print("FotG: Texture Update-loading texture "..self.texname_galaxymap.." \n")

		GCW_GALAXY_PLT = gr.loadTexture(self.texname_galaxyplanets, true)
		--print("FotG: Texture Update-loading texture "..self.texname_galaxyplanets.." \n")

	end


	--Options Helper Table
	function FotG:Setup_OPTs_Name_i_List()

		--create handy lookup table that records which i index each specific option string key is at

		local i_names = {}

		if opt ~= nil then
			local opts = opt.Options or {}
			for i, v in ipairs(opts) do
				i_names[v.Key] = i
			end
		end

		self.options_name_i_list = i_names

	end

	function FotG:StartSecretOptions()

		if opt ~= nil then
			opt.persistChanges()
			ba.postGameEvent(ba.GameEvents["GS_EVENT_INGAME_OPTIONS"])
		end

	end

	function FotG:Get_PilotName_withPrefix(optional_prefix)

		local ba_ply = ba.getCurrentPlayer()
		local player_pilot_name = ba_ply:getName()
		optional_prefix = optional_prefix or ""
		local num_chars_base = string.len(optional_prefix) + string.len(".txt") + 1
		local stringlength_max = 31-num_chars_base --keep files shorter then 32 characters plus extension

		if string.find(player_pilot_name, " ") ~= nil then
			player_pilot_name = string.gsub(player_pilot_name, " ", "_")
		end
		if string.len(player_pilot_name) > stringlength_max then
			player_pilot_name = string.sub(player_pilot_name, 1, stringlength_max)
		end
		print("Current correct player name is: "..player_pilot_name.."...\n")
		return optional_prefix..player_pilot_name

	end

	function FotG:IsStandaloneName(ship_name)
		if ship_name ~= nil and string.find(ship_name, "Standalone Ship") ~= nil then
			return true
		else
			return false
		end
	end

	function FotG:IsDummyClass(class_name)
		if self.DummyClasses[class_name] then
			return true
		else
			return false
		end
	end


	--JSON Loading
	JSON_FILE = {}

	--path is optional and defaults to 'data', extension is optional and adds it if not present
	--returns nil if json does not exist
	function JSON_FILE:Read(filename, path, delete_file_option) 

		ba.print("JSON: Reading JSON file -> "..filename.."...\n")

		local json = require ("dkjson")

		local tbl

		if delete_file_option == nil then
			delete_file_option = false
		end

		path = path or "data"

		--set file type if we forgot to specify the file type in the file path
		--do not actually save as a json  b/c then FSO gets confused and thinks all json files are pilot files
		if string.find(filename, ".txt", 1, true) == nil then
			filename = filename ..".txt"
		end

		if cf.fileExists(filename, path, false) then

			local currentFile = cf.openFile(filename, "rb", path)

			tbl = json.decode(currentFile:read("*a"))

			currentFile:close()

			--finally delete file if the option was set
			if delete_file_option then
				cf.deleteFile(filename, path)
			end

			ba.print("JSON: Successfully read JSON file -> "..filename.."...\n")
		else
			ba.print("JSON: file does not exist with name -> "..filename..", returning empty table...\n")
			--keep tbl as nil
		end

		return tbl

	end

	--path is optional and defaults to 'data', extension is optional and adds it if not present	
	function JSON_FILE:Write(tbl, options, filename, path)

		ba.print("JSON: Writing JSON file -> "..filename.."...\n")

		local json = require ("dkjson")

		path = path or "data"

		--set file type if we forgot to specify the file type in the file path
		--do not actually save as a json  b/c then FSO gets confused and thinks all json files are pilot files
		if string.find(filename, ".txt", 1, true) == nil then
			filename = filename ..".txt"
		end

		local file = cf.openFile(filename, "w+", path)
		if file ~= nil then
			file:write(json.encode(tbl, options))
			file:close()

			ba.print("JSON: Successfully wrote JSON file -> "..filename.."...\n")
		else
			ba.print("JSON: Could not write JSON file -> "..filename.."...\n")
		end

	end

--

--Setup Code
FotG:Setup_OPTs_Name_i_List()

FotG:FontInitialize()

FotG:LoadTextures()


--hooks
if engine and not IS_STANDALONE then

	--track options tab
	engine.addHook("On State Start", function() 
			FotG.OTab_ID_Current = FotG.OTab_ID_Main
		end,
		{State="GS_STATE_OPTIONS_MENU"}
	)
	engine.addHook("On Options Menu Tab Changed", function() 
			FotG.OTab_ID_Current = hv.TabNumber or FotG.OTab_ID_None
		end,
		{State="GS_STATE_OPTIONS_MENU"}
	)
	--do not actually need to reset tab here since it causes custom UI to disappear as the state transition happens
	--and the state gets set On Start anyway
	--engine.addHook("On Options Menu Closed", function() 
			--FotG.OTab_ID_Current = FotG.OTab_ID_None
		--end,
		--{State="GS_STATE_OPTIONS_MENU"}
	--)

	--stop F3 in Options Menu, instead use F4 in Main Menu
	engine.addHook("On Key Pressed", function() 
		end,
		{State="GS_STATE_OPTIONS_MENU"},
		function ()
			return hv.Key == "F3"
		end
	)
	engine.addHook("On Key Pressed", function() 
			if hv.Key == "F4" then
				FotG:StartSecretOptions()
			end
		end,
		{State="GS_STATE_MAIN_MENU"}
	)

	--track nebula/particle settings 
    engine.addHook("On State Start", function()
			FotG.NebulaSliderCurrent = 5 --restore to default
            if not ba.MultiplayerMode then
                --get current level of quality for the particles slider (recall, it is sneakily the nebula slider)
                --check each time gameplay state is entered incase player paused game and changed settings
                --full path is: opt.Options[FotG.options_name_i_list["Graphics.NebulaDetail"]].Value
                local opts = opt.Options
                local lookup_helper = FotG.options_name_i_list
                if opts ~= nil and lookup_helper ~= nil then
                    local particle_key = lookup_helper["Graphics.NebulaDetail"]
                    if particle_key ~= nil then
                        local part_opt = opts[particle_key]
                        if part_opt ~= nil then
                            local part_opt_vals = part_opt:getValidValues()
                            local part_opt_current = part_opt.Value
                            for i=1,#part_opt_vals do
                                if part_opt_vals[i] == part_opt_current then
                                    FotG.NebulaSliderCurrent = i
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end,
        {State="GS_STATE_GAME_PLAY"}
    )  

	--track mtime > 0.1
	engine.addHook("On Frame", function() 
			if not MTIME_OVER_P1 then
				if mn.getMissionTime() > 0.1 then
					MTIME_OVER_P1 = true
				end
			end
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Mission About To End", function() 
			MTIME_OVER_P1 = false
		end
	)

end