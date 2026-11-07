-- Add-Ship-Info Script - Displays additional text above the ship target box
-- Created by Goober5000
--

AddShipInfo = {
    add_hooks = true,
    hooks_added = false,

    POS_X = nil,
    POS_Y = nil,

    COLOR_R = 255,
    COLOR_G = 255,
    COLOR_B = 0,
    COLOR_A = 255,

    Enabled = false,
    ShipTexts = {},
}

--Code
    function AddShipInfo:CheckRegisterHooks()

        if not self.hooks_added then 
            self.hooks_added = true
            engine.addHook("On HUD Draw", function() 
                    AddShipInfo:OnHUD()
                end,
                {State="GS_STATE_GAME_PLAY"}
            )
        end

    end

    function AddShipInfo:SetText(ship_name, text)
        if not text or text == "" then
            self:ClearText(ship_name)
        else
            self.Enabled = true
            self.ShipTexts[ship_name] = text
            self:CheckRegisterHooks()
        end
    end
    mn.LuaSEXPs["lua-AddShipInfo-set-text"].Action = function(text, ...)
        for i,v in ipairs(arg) do
            AddShipInfo:SetText(v[1], text)
        end
    end

    function AddShipInfo:HasText(ship_name)
        if self.ShipTexts[ship_name] then
            return true
        else
            return false
        end
    end
    mn.LuaSEXPs["lua-AddShipInfo-has-text"].Action = function(ship_name)
        return AddShipInfo:HasText(ship_name)
    end

    function AddShipInfo:ClearText(ship_name)
        self.ShipTexts[ship_name] = nil

        -- disable when all entries have been removed
        if next(self.ShipTexts) == nil then
            self.Enabled = false
        end
    end
    mn.LuaSEXPs["lua-AddShipInfo-clear-text"].Action = function(...)
        for i,v in ipairs(arg) do
            AddShipInfo:ClearText(v[1])
        end
    end

    function AddShipInfo:DrawTextForShip(ship_name)
        self:DrawText(self.ShipTexts[ship_name])
    end

    function AddShipInfo:DrawText(text)
        if text ~= nil and text ~= "" then
            gr.setColor(self.COLOR_R, self.COLOR_G, self.COLOR_B, self.COLOR_A)
            gr.CurrentFont = self.FONT

            gr.setScreenScale(self.BASE_WIDTH, self.BASE_HEIGHT)
            gr.drawStringResized(GR_RESIZE_FULL, text, self.POS_X, self.POS_Y)
            gr.resetScreenScale()
        end
    end

    function AddShipInfo:Reset()

        self.Enabled = false
        self.ShipTexts = {}

    end

    function AddShipInfo:OnStart()

        self:Reset()

        if ba.MultiplayerMode or IS_STANDALONE then 
            return 
        end

        if not self.POS_X or not self.POS_Y then
            local gauge = hu.getHUDGaugeHandle("Extra Target Data")     -- alternatively Target Monitor
            if gauge == nil then return end
            self.FONT = gauge:getFont()
            self.BASE_WIDTH, self.BASE_HEIGHT = gauge:getBaseResolution()

            -- calculate position relative to gauge
            local pos_x, pos_y = gauge:getPosition()
            if self.FONT == gr.Fonts[3] then
                pos_x = pos_x + 14
                pos_y = pos_y - 5   -- if Target Monitor, -5 still works
            else
                pos_x = pos_x + 8
                pos_y = pos_y - 0   -- if Target Monitor, -3
            end
            pos_y = pos_y - 2 * (self.FONT.Height + 1)
            self.POS_X, self.POS_Y = pos_x, pos_y
        end

    end

    function AddShipInfo:OnHUD()

        if self.Enabled and hu.HUDDrawn then
            local ply = FotG:GetPlayerShip()
            if ply ~= nil and ply:isValid() and ply:getBreedName() == "Ship" then
                local target = ply.Target
                if target ~= nil and target:getBreedName() == "Ship" then
                    self:DrawTextForShip(target.Name)
                end
            end
        end

    end


--Hooks
if not IS_STANDALONE and AddShipInfo.add_hooks then
	engine.addHook("On Mission Start", function() 
			AddShipInfo:OnStart()
		end
	)

	engine.addHook("On Mission About To End", function() 
			AddShipInfo:Reset()
		end
	)
end