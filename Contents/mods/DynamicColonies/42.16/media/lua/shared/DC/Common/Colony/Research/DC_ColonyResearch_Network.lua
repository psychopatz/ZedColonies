DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Config = DC_Colony.Config
local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Research = DC_Colony.Research

Network.Internal = Internal
Network.Handlers = Network.Handlers or {}

local function getAuthorityOwner(player)
    return Config and Config.GetOwnerUsername and Config.GetOwnerUsername(player) or tostring(player or "local")
end

local function hasResearchStation(ownerUsername, buildingID)
    local buildings = DC_Buildings
    local wantedID = tostring(buildingID or "")
    for _, instance in ipairs(buildings and buildings.GetBuildingsForOwner and buildings.GetBuildingsForOwner(ownerUsername) or {}) do
        if tostring(instance and instance.buildingType or "") == "ResearchStation"
            and math.floor(tonumber(instance and instance.level) or 0) > 0
            and (wantedID == "" or tostring(instance.buildingID or "") == wantedID) then
            return true
        end
    end
    return false
end

Network.Handlers.RequestResearchSnapshot = function(player, args)
    if Internal.syncResearchSnapshot then
        Internal.syncResearchSnapshot(player, args and args.knownVersion)
    end
end

Network.Handlers.SubmitResearchSpecimen = function(player, args)
    if not args or not args.itemID then
        if Internal.syncNotice then
            Internal.syncNotice(player, "Choose an item to research.", "error", true)
        end
        return
    end

    local owner = getAuthorityOwner(player)
    if not hasResearchStation(owner, args.buildingID) then
        if Internal.syncNotice then
            Internal.syncNotice(player, "A working Research Station is required first.", "error", true)
        end
        if Internal.syncResearchSnapshot then
            Internal.syncResearchSnapshot(player)
        end
        return
    end

    local item = Internal.getInventoryItemByID and Internal.getInventoryItemByID(player, tonumber(args.itemID) or args.itemID) or nil
    if not item or not item.getFullType then
        if Internal.syncNotice then
            Internal.syncNotice(player, "That research specimen is no longer in your inventory.", "error", true)
        end
        if Internal.syncResearchSnapshot then
            Internal.syncResearchSnapshot(player)
        end
        return
    end

    local fullType = tostring(item:getFullType() or "")
    if fullType == "" then
        if Internal.syncNotice then
            Internal.syncNotice(player, "That item cannot be researched.", "error", true)
        end
        return
    end

    local ok, reason = false, "Research is unavailable."
    if Research and Research.SubmitResearchItem then
        ok, reason = Research.SubmitResearchItem(owner, fullType, {
            submittedAt = getTimestampMs and getTimestampMs() or 0,
            storeSpecimen = true,
        })
    end

    if ok ~= true then
        if Internal.syncNotice then
            Internal.syncNotice(player, reason or "Unable to queue that research item.", "error", true)
        end
        if Internal.syncResearchSnapshot then
            Internal.syncResearchSnapshot(player)
        end
        return
    end

    local removed = Internal.removeInventoryItemUnits and Internal.removeInventoryItemUnits(item, 1) or 0
    if removed <= 0 then
        if Internal.syncNotice then
            Internal.syncNotice(player, "The research specimen could not be removed from your inventory.", "error", true)
        end
        if Internal.syncResearchSnapshot then
            Internal.syncResearchSnapshot(player)
        end
        return
    end

    if Internal.syncNotice then
        Internal.syncNotice(player, "Research started for " .. tostring(item:getDisplayName() or fullType) .. ".", "info", false)
    end
    if Internal.syncResearchSnapshot then
        Internal.syncResearchSnapshot(player)
    end
    if Internal.syncWarehouse then
        Internal.syncWarehouse(player, nil, true, { output = true })
    end
end

return Network
