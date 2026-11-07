--load up choices tbl for mission
--for each question/answer do 
--  load up message and display in message view and then display options in extra info gauge
--  once choice made update values and messages and display 
--eventually end mission and update mission variables

DialogueScript = {
    Default_DynamicMessageName = "DYNAMIC_MESSAGE", --set as a message in FRED
    Default_SenderName = "Communication Contact",
    Default_Respone_Gauge_Title = "Response Communication",
    Default_Respone_Gauge_Separator = " ",
    Default_Response_Delay = 3,

    Interface_Sound_Number = 62,

    --"Enter", "Esc", "Pad 1", "1"
    KeyString_to_Index = {
        ["Pad 1"] = 1,
        ["Pad 2"] = 2,
        ["Pad 3"] = 3,
        ["Pad 4"] = 4,
        ["Pad 5"] = 5,
        ["Pad 6"] = 6,
        ["Pad 7"] = 7,
        ["Pad 8"] = 8,
        ["Pad 9"] = 9,
        ["1"] = 1,
        ["2"] = 2,
        ["3"] = 3,
        ["4"] = 4,
        ["5"] = 5,
        ["6"] = 6,
        ["7"] = 7,
        ["8"] = 8,
        ["9"] = 9,
    }
}

--Code

    function DialogueScript:Error(error_message, full_error)

        local message = "Error Dialogue Script: "..tostring(error_message).."\n"
        if full_error then
            warning(message)
        else
            print(message)
        end

    end

    function DialogueScript:GetValue(str_or_tbl_or_func)

        if type(str_or_tbl_or_func) == "table" then
			local randomi = ba.rand32(1, #str_or_tbl_or_func)
			return str_or_tbl_or_func[randomi]
        elseif type(str_or_tbl_or_func) == "string" then
            return str_or_tbl_or_func
        elseif type(str_or_tbl_or_func) == "function" then
            return str_or_tbl_or_func()
        else
            self:Error("provided neither a string or table or function, returning nil!")
            return nil
        end

    end

    function DialogueScript:Get_VAR_LUA(var_name)

        local lua_var_val = self.Current_LUA_Vars[var_name]
        if lua_var_val == nil then
            self:Error("Get Var LUA function provided with variable name "..tostring(var_name).." is currently nil \n")
        end

        return lua_var_val

    end

    function DialogueScript:Set_VAR_LUA(var_name, val, override)

        --fine to initiate and set at the same time, unlike SEXP variable
        local lua_var_val = self.Current_LUA_Vars[var_name]

        if not override and type(val) == "number" and lua_var_val ~= nil then
            self.Current_LUA_Vars[var_name] = lua_var_val + val
        else
            self.Current_LUA_Vars[var_name] = val
        end

    end 

    function DialogueScript:Get_VAR_SEXP(var_name)

        local mn_var = mn.SEXPVariables[var_name]
        if mn_var == nil then
            self:Error("Get Var SEXP function provided with variable name "..tostring(var_name).." which is invalid \n")
            return nil
        end

        return mn_var.Value

    end

    function DialogueScript:Set_Var_SEXP(var_name, val, override, is_pa)

        local mn_var = mn.SEXPVariables[var_name]
        if mn_var == nil then
            self:Error("Set Var SEXP function provided with variable name "..tostring(var_name).." which is invalid \n")
            return
        end

        if is_pa and GCW ~= nil then
            GCW:UpdateVariable(var_name, val, override)
        else
            if not override and type(val) == "number" then
                mn_var.Value = mn_var.Value + val
            else
                mn_var.Value = val
            end
        end

    end   

    function DialogueScript:Reset()

        --only reset if it was already loaded
        if not self.Dialogue_active then 
            return
        end

        self.Dialogue_active = false
        self.Key_pressed_timestamp = 0

        self.Loaded_conversation_tbl = nil
        self.Current_choice_keyname = nil
        self.Mission_ending = nil

        self.Current_DynamicMessageName = nil
        self.Current_SenderName = nil
        self.Current_Respone_Gauge_Title = nil
        self.Current_Respone_Gauge_Separator = nil
        self.Current_Response_Delay = nil

        self.Current_LUA_Vars = {}

    end

    function DialogueScript:SetSenderName(opt_sender_name)

        self.Current_SenderName = opt_sender_name or self.Default_SenderName

    end

    function DialogueScript:SetSafetyTime(extra_amount)

        extra_amount = extra_amount or 0
        self.Key_pressed_timestamp = mn.getMissionTime() + extra_amount

    end

    function DialogueScript:GetSafetyTime()

        return self.Key_pressed_timestamp

    end

    function DialogueScript:SendDynamicMessage(message_text, opt_delay, opt_sendername, opt_priority, opt_from_command)

        --validity checks
        message_text = message_text or ""
        opt_delay = opt_delay or 0
        opt_sendername = opt_sendername or "Command"

        local sender
        if string.find(opt_sendername, "Command") ~= nil then
            opt_from_command = true
            sender = "Command"
        else
            sender = mn.Ships[opt_sendername]
            if sender == nil then return end
            if not sender:isValid() then return end
        end

        local message = mn.Messages[self.Current_DynamicMessageName]
		if message == nil then 
            self:Error("Dyanmic message does not exist and is nil with message name of <"..tostring(self.Current_DynamicMessageName)..">!")
            return 
        end
        if not message:isValid() then 
            self:Error("Dyanmic message does not exist and is invalid with message name of <"..tostring(self.Current_DynamicMessageName)..">!")
            return 
        end

        --set message text
        message.Message = message_text

        --send message
        if opt_priority == "Low" then
            mn.sendMessage(sender, message, opt_delay, MESSAGE_PRIORITY_LOW, opt_from_command)
        elseif opt_priority == "High" then
            mn.sendMessage(sender, message, opt_delay, MESSAGE_PRIORITY_HIGH, opt_from_command)
        else
            mn.sendMessage(sender, message, opt_delay, MESSAGE_PRIORITY_NORMAL, opt_from_command)
        end

    end

    function DialogueScript:EndMission(delay)

        self.Mission_ending = true

        delay = delay or 2

        async.run(function()
            async.await(mn.waitAsync(delay))
            mn.evaluateSEXP("( fade-out 1500 3 )")
            async.await(mn.waitAsync(1.75))
            mn.evaluateSEXP("( end-mission )")
        end)

    end

    function DialogueScript:LoadChoice(choice_keyname)

        if choice_keyname == nil then
            self:Error("Question and Answer keyname is nil!")
            return 
        end

        local convo_tbl = self.Loaded_conversation_tbl

        if convo_tbl == nil then
            self:Error("conversation table is nil!")
            return 
        end

        local choice_tbl = convo_tbl[choice_keyname]

        if choice_tbl == nil then
            self:Error("Choice table is nil using keyname of <"..tostring(choice_keyname).."> for this choice!")
            return 
        end

        self.Current_choice_keyname = choice_keyname

        --load question into message and show
        local question_info = choice_tbl.Question_Info

        if question_info == nil then
            self:Error("Question table is nil using keyname of <"..tostring(choice_keyname)..">!")
            return 
        end

        if Object_Info_Help == nil then
            self:Error("conversation cannot fild Extra Roles HUD Gauge!")
            return
        end

        Object_Info_Help:ClearAll()

        --end mission then show message and then end mission/disable input
        local question_duration = question_info.Question_Duration
        if question_info.Question_Ends_Mission then
            self:EndMission(question_duration + 2) --just some extra buffer time
            return
        end

        local message_text = self:GetValue(question_info.Question_Text)
        local opt_priority = nil
        local opt_from_command = nil
        local opt_delay = self.Current_Response_Delay
        self:SendDynamicMessage(message_text, opt_delay, self.Current_sender_name, opt_priority, opt_from_command)

        DialogueScript:SetSafetyTime(opt_delay)

        --load answers into answers gauge and show
        local answers_info = choice_tbl.Answers_Info

        if answers_info == nil then
            self:Error("Answers table is nil using keyname of <"..tostring(choice_keyname)..">!")
            return 
        end

        async.run(function()
            async.await(mn.waitAsync(opt_delay * 1.5))
            for i_answer, v_answer in ipairs(answers_info) do
                local choice_txt = self:GetValue(v_answer.Answer_Text)
                Object_Info_Help:InsertObjectRole(choice_txt, "(Press "..i_answer..")")
            end
        end)

    end

    function DialogueScript:RunAnswerOutcome(choice_keyname, selected_answer_index)

        local convo_tbl = self.Loaded_conversation_tbl

        if convo_tbl == nil then
            self:Error("conversation table is nil!")
            return 
        end

        local choice_tbl = convo_tbl[choice_keyname]

        if choice_tbl == nil then
            self:Error("Choice table is nil using keyname of <"..tostring(choice_keyname)..">!")
            return 
        end

        local answers_info = choice_tbl.Answers_Info

        if answers_info == nil then
            self:Error("Answers table is nil using keyname of <"..tostring(choice_keyname)..">!")
            return 
        end

        local selected_answer_tbl = choice_tbl.Answers_Info[selected_answer_index]

        if selected_answer_tbl == nil then
            return
        end

        --run answer function and answer message and get next question to load
        local outcome_func = selected_answer_tbl.Answer_Outcome_Func
        if outcome_func == nil then
            return
        end

        ad.playInterfaceSound(self.Interface_Sound_Number)

        local next_question_keyname = outcome_func()

        self:LoadChoice(next_question_keyname)

    end

    function DialogueScript:Hook_KeyPress(key_name)

        --validity, recall multi and is active already checked before function ran
        if self.Mission_ending then 
            return
        end

        --grab timestamp
        if mn.getMissionTime() < self:GetSafetyTime() + 0.25 then
            return 
        end

        --update timestamp
        self:SetSafetyTime()

        --validity checks
        local key_to_index = self.KeyString_to_Index[key_name]

        if key_to_index == nil then
            return
        end

        --run answer outcome
        self:RunAnswerOutcome(self.Current_choice_keyname, key_to_index)

    end

    function DialogueScript:Startup(conversation_keyname, var_opt_tbl)

        self:Reset()

        --check if dynamic message exists
        if ba.MultiplayerMode or conversation_keyname == nil then
            return 
        end

        --load up which script to use
        if DialogueConversations == nil then
            self:Error("Dialogue Conversations table is nil!")
            return
        end

        if Object_Info_Help == nil then
            self:Error("conversation cannot fild Extra Roles HUD Gauge!")
            return
        end

        self.Loaded_conversation_tbl = DialogueConversations[conversation_keyname]

        if self.Loaded_conversation_tbl == nil then
            self:Error("conversation is not valid with key name of <"..tostring(conversation_keyname)..">")
            return 
        end

        local convo_metainfo = self.Loaded_conversation_tbl.DMeta_Info

        if convo_metainfo == nil then
            self:Error("conversation metainfo is not valid with key name of <"..tostring(conversation_keyname)..">")
            return 
        end

        local dynamic_message_name = self.Default_DynamicMessageName
        if mn.Messages[dynamic_message_name] == nil then
            self:Error("conversation has no valid FRED message of message name <"..tostring(dynamic_message_name)..">")
            return 
        end

        --set defaults
        self.Current_DynamicMessageName = dynamic_message_name
        self.Current_SenderName = self.Default_SenderName
        self.Current_Respone_Gauge_Title = self.Default_Respone_Gauge_Title
        self.Current_Respone_Gauge_Separator = self.Default_Respone_Gauge_Separator
        self.Current_Response_Delay = self.Default_Response_Delay

        --validity has passed so load up first choice
        self.Dialogue_active = true

        self:SetSenderName(self.Current_SenderName)

        --setup internal lua variables
        local opt_start_func = convo_metainfo.START_FUNC
        if type(opt_start_func) == "function" then
            opt_start_func(var_opt_tbl)
        end

        --load first choice
        self:LoadChoice(convo_metainfo.START_KEY)

        --also load up answer panel
        Object_Info_Help:HelperToggleFull(true, false)
        Object_Info_Help:SetTitle(self.Current_Respone_Gauge_Title)
        Object_Info_Help:SetSeperator(self.Current_Respone_Gauge_Separator)

    end


	mn.LuaSEXPs["dialogue-load-script"].Action = function(dialogue_keyname) 

		DialogueScript:Startup(dialogue_keyname)

	end

	mn.LuaSEXPs["dialogue-set-sender-ship"].Action = function(sender_ship) 

        local sender_name
        if sender_ship ~= nil and sender_ship:isValid() then
            sender_name = sender_ship.Name
        end

        if sender_name == nil then
            sender_name = "Command"
        end

		DialogueScript:SetSenderName(sender_name)

	end

	mn.LuaSEXPs["dialogue-set-choice-title"].Action = function(choice_title) 

        if Object_Info_Help ~= nil then
            DialogueScript.Current_Respone_Gauge_Title = choice_title
            Object_Info_Help:SetTitle(choice_title)
        end

	end


--Hooks
if not IS_STANDALONE then
    --dialogue startup is run via FRED event

	engine.addHook("On Key Pressed", function() 
			if not ba.MultiplayerMode and DialogueScript.Dialogue_active then
				DialogueScript:Hook_KeyPress(hv.Key)
			end
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Mission About To End", function() 
			DialogueScript:Reset()
		end
	)
end