
if not IS_STANDALONE then 
    engine.addHook("On Weapon Created", function()
            if not ba.MultiplayerMode then
                local child = hv.Weapon
                async.run(function()
                    while child ~= nil and child:isValid() do
                        local fraction = child.LifeLeft / child.Class.LifeMax
                        local hp_half = 1000
                        child.HitpointsLeft = (hp_half * fraction) + hp_half
                        async.await(async.yield())
                    end
                end, async.OnFrameExecutor)
            end
        end, {State="GS_STATE_GAME_PLAY", ["Weapon class"]="Seismic_Shockwave"}
    )  
end