Custom_Message_Gauge = {
    DEF_Title = "Incoming transmission",
    DEF_hud_keyname_frame = "CustomMessage_Frame",
    DEF_hud_keyname_body = "CustomMessage_Body",
    DEF_hud_gauge_id = 27, --27 is message lines!

    DEF_match_voice_length = true,
    DEF_use_unicode_mode = true,
    DEF_character_speed = 0.04,
    DEF_length_per_character = 0.10,
    DEF_minimum_time = 3.5,
    DEF_maximum_line_width = 600, --2_custom_message.eff; also recall, FRED message can only hold 460 characters
    DEF_time_after_voice = 1.5,
    DEF_use_speed_variation = false,
    DEF_cue_voice_index = 64, --from sounds.tbl interface section
    DEF_cue_voice_always_play = false,
    DEF_font_message_name = "font_hud_message", --from hud table
    DEF_add_shipname_suffix = true, --escort gauge also uses suffix on by default

    DEF_disable_event_name = "UseOptimizedMessageGauge",
    DEF_disable_caching = "NoMessageCaching",
    DEF_min_duration_suffix = "MIN_MSG_TIME_"
}

--Code
	--toggles gauge
	function Custom_Message_Gauge:Gauge_Toggle(required_bool)

		if required_bool == true or required_bool == false then

            if (required_bool and hu.getHUDConfigShowStatus(self.DEF_hud_gauge_id)) or (not required_bool) then
                mn.evaluateSEXP("( hud-set-custom-gauge-active ( "..tostring(required_bool).." ) !"..self.DEF_hud_keyname_frame.."! )")
                mn.evaluateSEXP("( hud-set-custom-gauge-active ( "..tostring(required_bool).." ) !"..self.DEF_hud_keyname_body.."! )")
            end

		end

	end

	--reset all 
    function Custom_Message_Gauge:ClearDynamic()

        self.MSG_StringFull = nil
        self.MSG_CharacterCount = nil
        self.MSG_CharacterSpeed = nil
        self.MSG_Duration = nil

        self.DRAW_StringDisplay = nil
        self.DRAW_IsDrawing = false
        self.DRAW_Timestamp = nil
        self.DRAW_CheckTime = nil
        self.DRAW_CurrentCharacter = nil
        self.DRAW_FullyShown = nil

        local gauge_frame = hu.getHUDGaugeHandle(self.DEF_hud_keyname_frame)
        local gauge_body = hu.getHUDGaugeHandle(self.DEF_hud_keyname_body)

        if gauge_frame == nil then 
            ba.warning("Message gauge could not find gauge with name of "..tostring(self.DEF_hud_keyname_frame).."\n")
            return 
        end
        if gauge_body == nil then 
                ba.warning("Message gauge could not find gauge with name of "..tostring(self.DEF_hud_keyname_body).."\n")
            return 
        end

        gauge_frame.Text = self.DEF_Title
        gauge_body.Text = ""

    end

    --returns word wrapped string, breaks on spaces
    function Custom_Message_Gauge:GetWrappedString(str, set_font, max_line_width)

        max_line_width = max_line_width or self.DEF_maximum_line_width

        --set font to hud message font so measuring is accurate
        local current_font_name 
        if set_font then
            current_font_name = gr.CurrentFont.Name
            gr.CurrentFont = gr.Fonts[self.DEF_font_message_name]
        end

        --loop through and line breaks at spaces
        local lines = {}
        local line = ""

        for word in str:gmatch("%S+") do
            local candidate = (line == "") and word or (line .. " " .. word)
            if gr.getStringWidth(candidate) <= max_line_width then
                line = candidate
            else
                if line ~= "" then
                    lines[#lines + 1] = line
                end
                line = word
            end
        end

        if line ~= "" then
            lines[#lines + 1] = line
        end

        --restore font
        if set_font and current_font_name ~= nil then
            gr.CurrentFont = gr.Fonts[current_font_name]
        end

        --put back into string
        return table.concat(lines, "\n")

    end

    function Custom_Message_Gauge:GetMessageMeta(mn_message, msg_text, is_builtin)

        --failsafes
        if mn_message == nil then 
            return 
        end

        --get variables
        local message_name = mn_message.Name
        local message_text = msg_text or mn_message.Message

        --setup speed
        local speedFactor = 1
        if self.DEF_use_speed_variation then
            if string.find(message_name, "!!!", 1, true) == 1 then
                speedFactor = 0
            elseif string.find(message_name, "!!", 1, true) == 1 then
                speedFactor = 0.3
            elseif string.find(message_name, "!", 1, true) == 1 then
                speedFactor = 0.6
            elseif string.find(message_name, "...", 1, true) == 1 then
                speedFactor = 2.0
            elseif string.find(message_name, "..", 1, true) == 1 then
                speedFactor = 1.6
            elseif string.find(message_name, ".", 1, true) == 1 then
                speedFactor = 1.3
            end
        end

        local can_be_cached
        if not is_builtin and self.MN_use_message_caching and (string.find(message_text, "%$") == nil) then
            can_be_cached = true
        else
            can_be_cached = false
        end

        --saved updated string with newlines
        --note this consolidates trailing or leading whitespace though, 
        --so count characters with this updated string
        local str_full = self:GetWrappedString(message_text, true)

        --get length
        local len_raw
        if self.DEF_use_unicode_mode then
            len_raw = utf8.len(str_full)
        else
            len_raw = #str_full
        end

        --estimate duration
        local char_speed = self.DEF_character_speed * speedFactor

        local voice_duration = mn_message.VoiceFile.Duration or 0
        local has_voice_file = (voice_duration > 0)

        local message_duration = self.DEF_minimum_time
        --try voice file duration
        if has_voice_file then
            --"Got Voice" so set duration and speed
            message_duration = voice_duration + self.DEF_time_after_voice
            if self.DEF_match_voice_length then
                char_speed = (voice_duration / len_raw)*0.8
            end
        else
            --"No voice", so guess duration
            message_duration = math.max(self.DEF_length_per_character * len_raw, self.DEF_length_per_character * len_raw * speedFactor, self.DEF_minimum_time)
        end

        --special case to force mission to display for longer or shorter
        local msg_name = mn_message.Name
        if msg_name ~= nil then
            local min_d_start, min_d_end = string.find(msg_name, self.DEF_min_duration_suffix)
            if min_d_start ~= nil and min_d_end ~= nil then
                local duration_override = 0
                local du_over_txt = string.sub(msg_name, min_d_end+1, #msg_name)
                local du_over_num = tonumber(du_over_txt)
                if du_over_num ~= nil then
                    message_duration = du_over_num
                end
            end
        end

        --save to sepcial format
        return {
            msg_messagename = message_name,
            msg_stringfull = str_full,
            msg_charactercount = len_raw,
            msg_characterspeed = char_speed,
            msg_duration = message_duration,
            msg_cacheable = can_be_cached,
            msg_has_voice = has_voice_file
        }

    end


    --adds message to cache table
    function Custom_Message_Gauge:CacheMessage_AddMaybe(message_meta)

        if self.MN_use_message_caching and message_meta ~= nil and message_meta.msg_cacheable then

            --failsafe
            if self.MN_cached_messages == nil then 
                self.MN_cached_messages = {} 
            end

            --actually cache
            self.MN_cached_messages[message_meta.msg_messagename] = nil
            self.MN_cached_messages[message_meta.msg_messagename] = message_meta
        end
        
    end

    --gets message from cache table
    function Custom_Message_Gauge:CacheMessage_Get(message_name)

        if self.MN_use_message_caching and self.MN_cached_messages ~= nil then 
            return self.MN_cached_messages[message_name]
        else
            return nil
        end

    end

    function Custom_Message_Gauge:HideDefault()
        mn.evaluateSEXP("(hud-set-builtin-gauge-active (false) !Messages!)")
    end

	function Custom_Message_Gauge:Reset(on_mission_start)

        --recall StatusHelper (which sets visibility status) is run any time gameplay is being started again

        self.MN_custom_gauge_allowed = false
        self.MN_gauge_enabled_for_mission = false
        self.MN_use_message_caching = true
        self.MN_cached_messages = nil

        self:ClearDynamic()
        self:Gauge_Toggle(false)

        if not on_mission_start then return end

        if mn.Events[self.DEF_disable_caching]:isValid() then
            self.MN_use_message_caching = false
        end

        --on mission start, so set meta variables 
        if mn.Events[self.DEF_disable_event_name]:isValid() or ba.MultiplayerMode then
            self.MN_custom_gauge_allowed = false
        else
            if hu.getHUDConfigShowStatus(self.DEF_hud_gauge_id) then
                self:HideDefault()
                --this mission is using the custom gauge, so the default gauge is now hidden
                self.MN_gauge_enabled_for_mission = true
                self.MN_custom_gauge_allowed = true
                --cache messages
                if self.MN_use_message_caching then
                    local mn_messages = mn.Messages
                    local num_mn_messages = #mn_messages
                    if num_mn_messages >= 1 then
                        self.MN_cached_messages = {}
                        for i=1,num_mn_messages do
                            local mn_message = mn_messages[i]
                            if mn_message ~= nil then
                                --function internally will only cache if there are no variables in message text
                                local msg_meta = self:GetMessageMeta(mn_message)
                                self:CacheMessage_AddMaybe(msg_meta)
                            end
                        end
                    end
                end
            else
                self.MN_custom_gauge_allowed = false
            end
        end

	end

    function Custom_Message_Gauge:Stop()

        self:Gauge_Toggle(false)
        self:ClearDynamic()

    end

    --helps with toggling if actual message gauge disabled by player in HUD config
	function Custom_Message_Gauge:StatusHelper()

        --only the mission start can enable the custom gauge, since that is where the default gauge gets hidden
        --so here we can only ever turn it back off, never on
		if self.MN_gauge_enabled_for_mission and hu.getHUDConfigShowStatus(self.DEF_hud_gauge_id) then
            self.MN_custom_gauge_allowed = true
		else
			self.MN_custom_gauge_allowed = false
		end

        if self.DRAW_IsDrawing then 
		    self:Gauge_Toggle(self.MN_custom_gauge_allowed)
        else
            self:Stop()
        end

	end

    --setups message
    function Custom_Message_Gauge:SetupMessage(mn_message, message_name, message_text, sender_obj, sender_str, is_builtin)

        --early outs, --do not play empty messages check 1
        if not self.MN_custom_gauge_allowed or message_text == "" then return end

        sender_str = sender_str or ""

        --cleanup any overlapping messages
        self:Stop()

        --get actual mission message
        if mn_message == nil then
            return
        end

        --recall escort gauge and F4 messages log show display name
        --have sender name and display name both shown if specified

        --get sender names full
        local sender_name
        if self.DEF_add_shipname_suffix and sender_obj ~= nil and sender_obj:isValid() and sender_obj:getBreedName() == "Ship" then
            local actual_name = string.filterInvisible(sender_obj.Name)
            local display_name = sender_obj.DisplayName
            local suffix
            if display_name ~= nil and display_name ~= "" then
                --just use display name if FREDer is setting it
                sender_name = display_name
            elseif actual_name ~= sender_str then
                suffix = actual_name
            end

            if suffix ~= nil and suffix ~= "" and suffix ~= " " then
                sender_name = sender_str .." ("..suffix..")"
            end
        end

        local msg_sender_name = sender_name or sender_str or ""

        --get message information needed for script, and cache
        --recall, cache function has internal checks to only add if caching allowed
        local msg_info = self:CacheMessage_Get(message_name)
        if msg_info == nil then
            msg_info = self:GetMessageMeta(mn_message, message_text, is_builtin)
            self:CacheMessage_AddMaybe(msg_info)
        end

        --do not play empty messages, check 2
        if msg_info.msg_charactercount <= 0 then
            return
        end

        --update dynamic variables
        self.MSG_StringFull = msg_info.msg_stringfull
        self.MSG_CharacterCount = msg_info.msg_charactercount
        self.MSG_CharacterSpeed = msg_info.msg_characterspeed
        self.MSG_Duration = msg_info.msg_duration

        self.MSG_SenderName = msg_sender_name --this cannot be cached

        self.DRAW_Timestamp = mn.getMissionTime()
        self.DRAW_CheckTime = 0
        self.DRAW_CurrentCharacter = 0
        self.DRAW_FullyShown = false
        self.DRAW_StringDisplay = nil
        self.DRAW_IsDrawing = true

        if self.DEF_cue_voice_always_play or not msg_info.msg_has_voice then
            ad.playInterfaceSound(self.DEF_cue_voice_index)
        end

        --force gauge showing and update 
        --(otherwise might be a few frame flicker from old message that is still running on HUD frame)
        self:DrawUpdate(true)

        self:Gauge_Toggle(true)

    end

    --updates and shows message
    function Custom_Message_Gauge:DrawUpdate(force_draw_start)

        --early outs
        if not self.MN_custom_gauge_allowed then return end
        if not self.DRAW_IsDrawing then return end

        --setup
        local m_time = mn.getMissionTime()
        local dr_timestamp = self.DRAW_Timestamp or 0
        local mg_duration = self.MSG_Duration or 0
        local timer_done = (m_time > dr_timestamp + mg_duration)

        --done with duration so toggle off
        --make sure timer is up and full string shown
        --  timer can be up but need to finish the string
        --  string can be shown but need to finish the time 
		if timer_done and self.DRAW_FullyShown then
            self:Stop()
			return
		end

        --no need to update text if already at max, but we are not turning gauge off until timer done
        if self.DRAW_FullyShown then return end

        --only run 20 times a second for type writer effect update, more is not needed 
        if m_time > self.DRAW_CheckTime then
            self.DRAW_CheckTime = m_time + 0.05
        else
            return
        end

        local update_text = false

        --draw type writer effect
        if self.MSG_CharacterSpeed == 0 then
            self.DRAW_StringDisplay = self.MSG_StringFull
            self.DRAW_CurrentCharacter = self.MSG_CharacterCount
            update_text = true
        else
            local toDraw = ((m_time) - dr_timestamp) / self.MSG_CharacterSpeed

            --force drawing update if starting new message
            if force_draw_start then
                toDraw = 1
            end

            -- only update string if progressed since last update
            if toDraw > 0 and toDraw > self.DRAW_CurrentCharacter then

                self.DRAW_CurrentCharacter = toDraw

                --max current character to max characters
                if self.DRAW_CurrentCharacter > self.MSG_CharacterCount then
                    self.DRAW_CurrentCharacter = self.MSG_CharacterCount
                end

                if self.DEF_use_unicode_mode then
                    self.DRAW_StringDisplay = utf8.sub(self.MSG_StringFull, 1, toDraw)
                else
                    self.DRAW_StringDisplay = self.MSG_StringFull:sub(1, toDraw)
                end

                update_text = true

            end
        end

        --actually set text
        if update_text then

            if self.DRAW_CurrentCharacter >= self.MSG_CharacterCount then
                self.DRAW_FullyShown = true
            end

            local gauge_frame = hu.getHUDGaugeHandle(self.DEF_hud_keyname_frame)
            local gauge_body = hu.getHUDGaugeHandle(self.DEF_hud_keyname_body)

            if gauge_frame == nil then 
                ba.warning("Message gauge could not find gauge with name of "..tostring(self.DEF_hud_keyname_frame).."\n")
                return 
            end
            if gauge_body == nil then 
                 ba.warning("Message gauge could not find gauge with name of "..tostring(self.DEF_hud_keyname_body).."\n")
                return 
            end

            gauge_frame.Text = self.MSG_SenderName or ""
            gauge_body.Text = self.DRAW_StringDisplay or ""
        end

    end

--

--Hooks
if not IS_STANDALONE then 
	engine.addHook("On Gameplay Start", function() 
			Custom_Message_Gauge:Reset(true)
		end
	)

	engine.addHook("On Mission About To End", function() 
			Custom_Message_Gauge:Reset(false)
		end
	)

	engine.addHook("On State Start", function() 
            --On State Start runs before On Gameplay Start, 
            --  but On State Start runs every time we come back into the game, even from a paused menu
            --so we do not want to always run the setup scripts, 
            --  but we do want to check the draw HUD status and run a sexp if needed, but only after time has passed
            if MTIME_OVER_P1 then
                Custom_Message_Gauge:StatusHelper()
            end
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Message Received", function() 
            Custom_Message_Gauge:SetupMessage(hv.MessageHandle, hv.Name, hv.Message, hv.Sender, hv.SenderString, hv.Builtin)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On HUD Draw", function() 
			Custom_Message_Gauge:DrawUpdate()
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

end
