
GRD = {
	globally_used = false,
    enabled = false,
    width_steps = 100,
    height_steps = 60,
}

--Code
    function GRD:OnGameplayStart()

        if ba.MultiplayerMode or IS_STANDALONE then 
			return 
		end

        self.width = gr.getScreenWidth()
        self.height = gr.getScreenHeight()

    end

    function GRD:Draw()

        if not self.enabled then
            return
        end

        gr.setLineWidth(1)

        for i = 0, self.width_steps do
            if i % 20 == 0 then
                gr.setColor(255, 60, 60, 255)
            elseif i % 10 == 0 then
                gr.setColor(60, 255, 60, 255)
            elseif i % 5 == 0 then
                gr.setColor(60, 60, 255, 255)
            else
                gr.setColor(255, 255, 255, 255)
            end
            local screen_index = i - (self.width_steps / 2)
            local screen_pos = (i / self.width_steps) * self.width
            gr.drawLine(screen_pos, 0, screen_pos, self.height)
        end

        for i = 0, self.height_steps do
            if i % 20 == 0 then
                gr.setColor(255, 60, 60, 255)
            elseif i % 10 == 0 then
                gr.setColor(60, 255, 60, 255)
            elseif i % 5 == 0 then
                gr.setColor(60, 60, 255, 255)
            else
                gr.setColor(255, 255, 255, 255)
            end
            local screen_index = (i - (self.height_steps / 2)) - 0.5
            local screen_pos = (i / self.height_steps) * self.height
            gr.drawLine(0, screen_pos, self.width, screen_pos)
        end

    end
--


--Hooks
if GRD.globally_used and not IS_STANDALONE then 
	engine.addHook("On Gameplay Start", function() 
			GRD:OnGameplayStart()
		end
	)

	engine.addHook("On HUD Draw", function() 
			GRD:Draw()
		end,
		{State="GS_STATE_GAME_PLAY"}
	)
end
--
