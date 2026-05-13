require "DC/Common/Base/DC_Base"

BuildRecipeCode = BuildRecipeCode or {}
BuildRecipeCode.DCColonyBaseHQ = BuildRecipeCode.DCColonyBaseHQ or {}

local Base = DC_Base

local function syncNotice(player, message, severity, popup)
    if DC_Colony and DC_Colony.Network and DC_Colony.Network.Internal and DC_Colony.Network.Internal.syncNotice then
        DC_Colony.Network.Internal.syncNotice(player, message, severity or "info", popup == true)
    end
end

local function getOwnerUsername(character)
    return DC_Colony and DC_Colony.Config and DC_Colony.Config.GetOwnerUsername
        and DC_Colony.Config.GetOwnerUsername(character)
        or (character and character.getUsername and character:getUsername())
        or "local"
end

function BuildRecipeCode.DCColonyBaseHQ.OnIsValid(params)
    params = type(params) == "table" and params or {}
    local square = params.square
    local character = params.character
    if not square or not character then
        return false
    end

    local owner = getOwnerUsername(character)
    local ok = Base and Base.CanFinalizeHeadquarters and Base.CanFinalizeHeadquarters(
        owner,
        square:getX(),
        square:getY(),
        square:getZ()
    )
    return ok == true
end

function BuildRecipeCode.DCColonyBaseHQ.OnCreate(params)
    params = type(params) == "table" and params or {}
    local thumpable = params.thumpable
    local character = params.character
    if not thumpable then
        return nil
    end

    local sprite = thumpable:getSprite() and thumpable:getSprite():getName() or nil
    local square = thumpable:getSquare()
    local hutch = nil
    for _, definition in pairs(HutchDefinitions and HutchDefinitions.hutchs or {}) do
        if sprite == definition.baseSprite then
            hutch = IsoHutch.new(square, thumpable:getNorth(), sprite, definition, nil)
            break
        end
    end

    if not hutch or not square then
        return nil
    end

    local owner = getOwnerUsername(character)
    local ok, reason = Base.FinalizeHeadquarters(owner, {
        entityType = Base.Constants and Base.Constants.HeadquartersEntityType or "Base.DCColonyHQ",
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
    })

    if not ok then
        syncNotice(character, reason or "Unable to finalize headquarters placement.", "error", true)
        return nil
    end

    if thumpable:getSquare() ~= nil then
        thumpable:removeFromWorld()
        thumpable:removeFromSquare()
        thumpable:setSquare(nil)
    end

    syncNotice(character, "Headquarters established. Your colony is now settled.", "info", true)
    return { replaceObject = true, object = hutch }
end
