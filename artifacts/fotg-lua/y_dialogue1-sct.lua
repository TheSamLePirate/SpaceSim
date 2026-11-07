--list out conversations for the Dialogue Script logic here

DialogueConversations = {

    CONVO_EXAMPLE = {

        DMeta_Info = {
            START_KEY ="CT_Choice_1"
        },

        CT_Choice_1 = {

            Question_Info = {
                Question_Text = {"How much do you want for this ship?"},
                Question_Duration = 10,
            },

            Answers_Info = {
                { --Answer 1, Press 1
                    Answer_Text = {"100"},
                    Answer_Outcome_Func = function()
                        return 'CT_Choice_2'
                    end
                },
                { --Answer 2, Press 2
                    Answer_Text = {"200"},
                    Answer_Outcome_Func = function()
                        return 'CT_Choice_2'
                    end
                },
            }
        },

        CT_Choice_2 = {
            Question_Info = {
                Question_Text = {"How much do you want for this weapon?"},
                Question_Duration = 10,
            },

            Answers_Info = {
                { --Answer 1, Press 1
                    Answer_Text = {"100"},
                    Answer_Outcome_Func = function()
                        return 'CT_Choice_END'
                    end
                },
                { --Answer 1, Press 2
                    Answer_Text = {"200"},
                    Answer_Outcome_Func = function()
                        return 'CT_Choice_END'
                    end
                },
            }
        },

        CT_Choice_END = {
            Question_Info = {
                Question_Text = {"Thank you for your business."},
                Question_Duration = 2,
                Question_Ends_Mission = true
            },
            Answers_Info = {}
        }
    },

    CON1_BuyIntel = {

        DMeta_Info = {
            START_KEY ="C_BuyIntel1_Choice_1",
            START_FUNC = function(var_opt_tbl)
                --setup variables
                if type(var_opt_tbl) ~= "table" then
                    var_opt_tbl = {}
                end

                local default_variables = {
                    ['DCVar_Cost_Win']=100
                }

                for k_varname, v_varval in pairs(default_variables) do
                    local l_val = var_opt_tbl[k_varname] or v_varval
                    DialogueScript:Set_VAR_LUA(k_varname, l_val, true)
                end
            end
        },

        C_BuyIntel1_Choice_1 = {

            Question_Info = {
                Question_Text = {"How much do you want for this intel?"},
                Question_Duration = 10,
            },

            Answers_Info = {
                { --Answer 1, Press 1
                    Answer_Text = {"100"},
                    Answer_Outcome_Func = function()
                        return 'C_BuyIntel1_Choice_2'
                    end
                },
                { --Answer 2, Press 2
                    Answer_Text = {"200"},
                    Answer_Outcome_Func = function()
                        return 'C_BuyIntel1_Choice_2'
                    end
                },
            }
        },

        C_BuyIntel1_Choice_2 = {
            Question_Info = {
                Question_Text = {"How much do you want for this weapon?"},
                Question_Duration = 10,
            },

            Answers_Info = {
                { --Answer 1, Press 1
                    Answer_Text = {"100"},
                    Answer_Outcome_Func = function()
                        return 'C_BuyIntel1_Choice_END'
                    end
                },
                { --Answer 1, Press 2
                    Answer_Text = {"200"},
                    Answer_Outcome_Func = function()
                        return 'C_BuyIntel1_Choice_END'
                    end
                },
            }
        },

        C_BuyIntel1_Choice_END = {
            Question_Info = {
                Question_Text = {"Thank you for your business."},
                Question_Duration = 2,
                Question_Ends_Mission = true
            },
            Answers_Info = {}
        }
    }

}
