DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Recycler = DC_Colony.Recycler or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Recycler = DC_Colony.Recycler
local Config = DC_Colony.Config

Network.Internal = Internal
Network.Handlers = Network.Handlers or {}

local function getAuthorityOwner(player)
    return Config and Config.GetOwnerUsername and Config.GetOwnerUsername(player) or tostring(player or "local")
end

local function hasRecycler(ownerUsername, buildingID)
    local buildings = DC_Buildings
    local wantedID = tostring(buildingID or "")
    for _, instance in ipairs(buildings and buildings.GetBuildingsForOwner and buildings.GetBuildingsForOwner(ownerUsername) or {}) do
        if tostring(instance and instance.buildingType or "") == "Recycler"
            and math.floor(tonumber(instance and instance.level) or 0) > 0
            and (wantedID == "" or tostring(instance and instance.buildingID or "") == wantedID) then
            return true
        end
    end
    return false
end

Network.Handlers.RecycleInventoryItem = function(player, args)
    if not args or not args.itemID then
        if Internal.syncNotice then
            Internal.syncNotice(player, "Choose an item to recycle.", "error", true)
        end
        return
    end

    local owner = getAuthorityOwner(player)
    if not hasRecycler(owner, args.buildingID) then
        if Internal.syncNotice then
            Internal.syncNotice(player, "A working Recycler is required first.", "error", true)
        end
        return
    end

    local item = Internal.getInventoryItemByID and Internal.getInventoryItemByID(player, tonumber(args.itemID) or args.itemID) or nil
    if not item or not item.getFullType then
        if Internal.syncNotice then
            Internal.syncNotice(player, "That recycling item is no longer in your inventory.", "error", true)
        end
        return
    end

    if not (Recycler and Recycler.CanRecycleItem and Recycler.CanRecycleItem(tostring(item:getFullType() or ""))) then
        if Internal.syncNotice then
            Internal.syncNotice(player, "That item cannot be recycled here.", "error", true)
        end
        return
    end

    local removed = Internal.removeInventoryItemUnits and Internal.removeInventoryItemUnits(item, 1) or 0
    if removed <= 0 then
        if Internal.syncNotice then
            Internal.syncNotice(player, "The recycling specimen could not be removed from your inventory.", "error", true)
        end
        return
    end

    local ok = false
    local reason = "Unable to recycle that item."
    local result = nil
    if Recycler and Recycler.RecycleItem then
        ok, reason, result = Recycler.RecycleItem(owner, tostring(item:getFullType() or ""))
    end
    if ok ~= true then
        if Internal.syncNotice then
            Internal.syncNotice(player, reason or "Unable to recycle that item.", "error", true)
        end
    else
        local recoveredCount = 0
        for _, entry in ipairs(result and result.recoveredEntries or {}) do
            recoveredCount = recoveredCount + math.max(0, math.floor(tonumber(entry and entry.count) or 0))
        end
        if Internal.syncNotice then
            Internal.syncNotice(
                player,
                "Recycler reclaimed " .. tostring(recoveredCount) .. " material unit(s) from " .. tostring(result and result.displayName or "the item") .. ".",
                "info",
                false
            )
        end
    end

    if Internal.syncWarehouse then
        Internal.syncWarehouse(player, nil, true, { output = true })
    end
end

return Network
