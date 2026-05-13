BuildRecipeCode = BuildRecipeCode or {}
BuildRecipeCode.DC_Building_HQ = {}

function BuildRecipeCode.DC_Building_HQ.OnCreate(params)
    local thumpable = params.thumpable;
    local square = thumpable:getSquare();
    local north = thumpable:getNorth();
    
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    local cell = getCell()

    -- Remove the generic 1x1 crate placement hologram
    if square ~= nil then
        thumpable:removeFromWorld();
        thumpable:removeFromSquare();
        thumpable:setSquare(nil);
    end

    -- Safely spawn the 4 visual pieces of the base game Chicken Hutch
    local hutchTiles = {
        { sprite = "location_farm_accesories_01_41", offsetX = 0, offsetY = 0 },
        { sprite = "location_farm_accesories_01_43", offsetX = 1, offsetY = 0 },
        { sprite = "location_farm_accesories_01_50", offsetX = 0, offsetY = 1 },
        { sprite = "location_farm_accesories_01_42", offsetX = 1, offsetY = 1 }
    }

    local mainHutch = nil

    for _, config in ipairs(hutchTiles) do
        local targetSq = cell:getGridSquare(x + config.offsetX, y + config.offsetY, z)
        if targetSq then
            local obj = IsoThumpable.new(cell, targetSq, config.sprite, north, {})
            obj:setCanPassThrough(false)
            obj:setCanBarricade(false)
            obj:setThumpDmg(5)
            obj:setMaxHealth(500)
            obj:setHealth(500)

            -- Tag it for Dynamic Colonies so it is extremely easy to setup a context menu!
            obj:getModData()["DynamicColonies"] = true
            obj:getModData()["IsColonyHQ"] = true

            targetSq:AddSpecialObject(obj)
            obj:transmitCompleteItemToClients()
            
            if config.offsetX == 0 and config.offsetY == 0 then
                mainHutch = obj
            end
        end
    end

    print("DynamicColonies: Replaced the blueprint hologram with the true base-game 2x2 building visual.")
    
    return { replaceObject = true, object = mainHutch }
end
