DynamicDecals = {}

--Code
    function DynamicDecals:Add(ship, decal_name, size, lifetime, rotation, pos_offset) --rotation in radians!, set rotation to -1 or nil for default 

        --validity checks
            if ba.MultiplayerMode then return end
            if not tb.isDecalSystemActive() then return end
            if ship == nil then return end
            if not ship:isValid() then return end
            if type(decal_name) ~= "string" then return end

        --default args

            if type(lifetime) ~= "number" then
                lifetime = -1
            end
            if lifetime < 0 then
                lifetime = -1
            end

            if type(size) ~= "number" then
                size = -1
            end

            local ship_radius = ship.Radius

            if size < 0 then 
                size = ship_radius * (ba.rand32(800, 1600)/1000)
            end

            local two_pi = math.pi*2

            if type(rotation) ~= "number" then
                rotation = -1 --triggers random rotation
            else
                if rotation < 0 then
                    rotation = -1 --triggers random rotation
                elseif rotation > two_pi then
                    rotation = two_pi
                end
            end

            local static_ray_pos
            if type(pos_offset) == "table" then
                if #pos_offset == 3 then
                    if type(pos_offset[1]) == "number" and type(pos_offset[2]) == "number" and type(pos_offset[3]) == "number" then
                        static_ray_pos = ship:findWorldPoint(ba.createVector(pos_offset[1], pos_offset[2], pos_offset[3]))
                    end
                end
            end


        --get a decal 
        local decal = tb.DecalDefinitions[decal_name]
        if decal == nil then return end
        if not decal:isValid() then return end

        --choose position and add it to ship
        local ray_pos = static_ray_pos or ship_pos:randomInSphere(ship_radius, true, false)
        --randomInSphere(number radius, boolean on_surface, [boolean bias_towards_center = true])

        local hull_point, collision_data = ship:checkRayCollision(ray_pos, ship_pos, true)
        --vector, collision_info checkRayCollision(vector StartPoint, vector EndPoint, [boolean Local = false])
        --Checks the collisions between the polygons of the current object and a ray. Start and end vectors are in world coordinates
        --Returns: World collision point (local if boolean is set to true) and the specific collision info, nil if no collisions

        --expected to get a hit, so make decal there
        if hull_point ~= nil and collision_data ~= nil and collision_data:isValid() then

            --from decal code in weapon hit, search:// Add impact decal
            --hit_normal = hit_dir = fvec
            local fvec = collision_data:getCollisionNormal(true)

            --add rotation, which will be used to make the uvec
            local decal_bank
            if rotation < 0 then --random rotation
                decal_bank = ba.rand32f(two_pi) --if 1 arg returns float from 0 to max
            else
                decal_bank = rotation
            end

            --make into orientation
            local decal_ori = ba.createOrientationFromVectors(fvec, ba.createOrientation(0, decal_bank, 0):getUvec(true))

            decal:create(size, size, lifetime, lifetime, ship, collision_data:getCollisionSubmodel(), hull_point, decal_ori)
            --nil create(number width, number height, number minLifetime, number maxLifetime, object host, submodel submodel, [vector local_pos, orientation local_orient])
            --Creates a decal with the specified parameters. A negative value for either lifetime will result in a perpetual decal. 
            --The position and orientation are in the frame-of-reference of the submodel.
        end


    end

    mn.LuaSEXPs["add-decal-to-ship"].Action = function(ship, decal_name, size, lifetime, rotation, pos_x, pos_y, pos_z) 

        if ba.MultiplayerMode then return end

        if type(lifetime) == "number" then
            if lifetime >= 0 then
                lifetime = lifetime/1000
            else
                lifetime = -1
            end
        else
            lifetime = -1
        end
        if type(rotation) == "number" then
            if rotation >= 0 then
                rotation = math.rad(rotation)
            else
                rotation = -1
            end
        else
            rotation = -1 
        end

		DynamicDecals:Add(ship, decal_name, size, lifetime/1000, rotation, {pos_x, pos_y, pos_z})

	end
