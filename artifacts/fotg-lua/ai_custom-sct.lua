
LUA_AI = {
    method_tighten = 1,
    method_loosen = -1,
    method_default = 0
}

--Code

    -- Recall default orders are not really AI and just run script code, so .ActionFrame is not needed other than to return true

	function LUA_AI:FormationSpacing_Update(ai_helper, method)

        -- sets wing spacing

        -- validity checks, including no multiplayer
        if ba.MultiplayerMode then return true end

        if ai_helper == nil then return true end
        local ship = ai_helper.Ship
        if ship == nil then return true end
        if not ship:isValid() then return true end

        local wing = ship:getWing()
        if wing == nil then return true end
        if not wing:isValid() then return true end

        local current_spacing = wing.FormationScale
        local desired_spacing

        -- change formation spacing accordingly
        if method == self.method_tighten then
            desired_spacing = 0.6
        elseif method == self.method_loosen then
            desired_spacing = 1.8
        elseif method == self.method_default then
            desired_spacing = 1.0
        end

        -- set wing spacing if different
        if desired_spacing ~= current_spacing then
            wing.FormationScale = desired_spacing
        end

		return true

	end


    function LUA_AI:Default_Helper(ai_helper)

        --by default run 'attack any'
        --but if in PA run order restore default orders for ship

        local ship = ai_helper.Ship

        if GCW ~= nil and GCW.isactive then
            GCW:Orders_RestoreDefault_Small(ship) --has internal validity checks
        else
            if ship ~= nil and ship:isValid() then
                Movements:Orders_Remove_EqualorUnder_PR(ship, 100)
                ship:giveOrder(ORDER_ATTACK_ANY, nil, nil, 88/100)
            end
        end

        return true

    end


    mn.LuaAISEXPs["ai-run-default"].ActionEnter = function(ai_helper)
		return LUA_AI:Default_Helper(ai_helper)
	end

	mn.LuaAISEXPs["ai-run-default"].ActionFrame = function(ai_helper)
        return true
	end


	mn.LuaAISEXPs["ai-formation-tighten"].ActionEnter = function(ai_helper)
		return LUA_AI:FormationSpacing_Update(ai_helper, LUA_AI.method_tighten)
	end

	mn.LuaAISEXPs["ai-formation-tighten"].ActionFrame = function(ai_helper)
        return true
	end


	mn.LuaAISEXPs["ai-formation-loosen"].ActionEnter = function(ai_helper)
		return LUA_AI:FormationSpacing_Update(ai_helper, LUA_AI.method_loosen)
	end

	mn.LuaAISEXPs["ai-formation-loosen"].ActionFrame = function(ai_helper)
        return true
	end


	mn.LuaAISEXPs["ai-formation-default"].ActionEnter = function(ai_helper)
		return LUA_AI:FormationSpacing_Update(ai_helper, LUA_AI.method_default)
	end

	mn.LuaAISEXPs["ai-formation-default"].ActionFrame = function(ai_helper)
        return true
	end


    function LUA_AI:CommPriority(sender, recipient, target, subsystem, order)

		if ba.MultiplayerMode then return false end

        --ensure player orders to wing and ships treated same
        --ie, avoid issuing ship an order then 
        --trying to issue it a wing order and not having it follow it

		recipient:forAllShips(function(ship) 
			if ship ~= nil and ship:isValid() then
                local so = ship.Orders
                if so ~= nil then
                    local num_ords = #so
                    if num_ords > 1 then
                        for i=1,num_ords do 
                            local ord = so[i]
                            if ord ~= nil and ord:isValid() then
                                if ord.Priority == 100 then --default pr to ship
                                    ord.Priority = 95 --default pr to wing
                                end
                            end
                        end
                    end
                end
            end
		end)

		return true

	end

--Hooks
if not IS_STANDALONE then

    engine.addHook("On HUD Comm Order Issued", function() 
			--ensure wing order PR always matches ship order PR
			LUA_AI:CommPriority(hv.Sender, hv.Recipient, hv.Target, hv.Subsystem, hv.Order)
		end, 
        {State="GS_STATE_GAME_PLAY"}
    )

end