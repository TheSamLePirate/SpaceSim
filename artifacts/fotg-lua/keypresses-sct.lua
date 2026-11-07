
AbsoluteKeys = {}

--Code
	function AbsoluteKeys:KeyPressed(keyname)

        if not ba.MultiplayerMode and self.keypresses[keyname] then
			--print("key was pressed "..keyname.."\n")
            return true
        else
            return false
        end

    end

    function AbsoluteKeys:KeyReset(...)

		if ba.MultiplayerMode then return end

		if #arg <= 0 then return end 

		for _, key in ipairs(arg) do
			local keyname = key[1]
			self.keypresses[keyname] = nil
			--print("resetting key "..keyname.."...\n")
		end

    end

	function AbsoluteKeys:Reset()
		if not ba.MultiplayerMode then
			self.keypresses = {}
		end
	end

	function AbsoluteKeys:Add(keyname)
		if MTIME_OVER_P1 and not ba.MultiplayerMode and keyname ~= nil then
			--only set it if it is not set to true already
			if not self.keypresses[keyname] then
				self.keypresses[keyname] = true
			end
		end
	end

	mn.LuaSEXPs["absolute-key-pressed"].Action = function (keyname)
		return AbsoluteKeys:KeyPressed(keyname)
	end

	mn.LuaSEXPs["absolute-key-reset"].Action = function (...)
		AbsoluteKeys:KeyReset(...)
	end


--Hooks
if not IS_STANDALONE then

	engine.addHook("On Gameplay Start", function() 
			AbsoluteKeys:Reset()
		end
	)

	engine.addHook("On Mission About To End", function() 
			AbsoluteKeys:Reset()
		end
	)

	engine.addHook("On Key Pressed", function() 
			AbsoluteKeys:Add(hv.Key)
		end,
		{State="GS_STATE_GAME_PLAY"}
	)
end