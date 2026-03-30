require "DC/Common/Colony/Resources/DC_ColonyResources"

DC_GreenhouseUIUtils = DC_GreenhouseUIUtils or {}

local Utils = DC_GreenhouseUIUtils

local function getLocalPlayer()
    if getSpecificPlayer then
        return getSpecificPlayer(0)
    end
    if getPlayer then
        return getPlayer()
    end
    return nil
end

local function collectInventoryCountsRecursive(container, counts)
    if not container or not counts then
        return
    end

    local items = container:getItems()
    if not items then
        return
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item then
            local fullType = item.getFullType and item:getFullType() or nil
            if fullType then
                local count = item.getCount and item:getCount() or 1
                count = math.max(1, math.floor(tonumber(count) or 1))
                counts[fullType] = (counts[fullType] or 0) + count
            end

            if instanceof(item, "InventoryContainer") then
                collectInventoryCountsRecursive(item:getItemContainer(), counts)
            end
        end
    end
end

function Utils.GetGreenhouses(snapshot)
    return snapshot and snapshot.water and snapshot.water.greenhouses or {}
end

function Utils.FindGreenhouse(snapshot, buildingID)
    local expectedID = tostring(buildingID or "")
    for _, greenhouse in ipairs(Utils.GetGreenhouses(snapshot)) do
        if tostring(greenhouse and greenhouse.buildingID or "") == expectedID then
            return greenhouse
        end
    end
    return nil
end

function Utils.FindSlot(greenhouse, slotIndex)
    local expectedIndex = tonumber(slotIndex) or -1
    for _, slot in ipairs(greenhouse and greenhouse.slots or {}) do
        if tonumber(slot and slot.slotIndex) == expectedIndex then
            return slot
        end
    end
    return nil
end

function Utils.GetGreenhouseDisplayName(greenhouse)
    return "Greenhouse " .. tostring(greenhouse and greenhouse.plotX or 0) .. "," .. tostring(greenhouse and greenhouse.plotY or 0)
end

function Utils.BuildGreenhouseOptionLabel(greenhouse)
    return Utils.GetGreenhouseDisplayName(greenhouse)
        .. " | "
        .. tostring(greenhouse and greenhouse.activeSlotCount or 0)
        .. "/"
        .. tostring(greenhouse and greenhouse.slotCount or 0)
        .. " beds | "
        .. tostring(greenhouse and greenhouse.thermostatC or 20)
        .. " C"
end

function Utils.BuildSlotLabel(slot)
    local label = "Garden Bed " .. tostring(slot and slot.slotIndex or 0)
    if not slot then
        return label
    end

    local state = tostring(slot.state or "Empty")
    if state == "Empty" then
        return label .. " | Empty"
    end
    if state == "Dead" then
        return label .. " | Dead crop | " .. tostring(slot.displayName or "Unknown")
    end

    return label
        .. " | "
        .. tostring(slot.displayName or "Crop")
        .. " | "
        .. tostring(math.floor(((tonumber(slot.growthPercent) or 0) * 100) + 0.5))
        .. "% | "
        .. tostring(slot.health or 0)
        .. " hp | "
        .. state
end

function Utils.BuildDetailText(greenhouse, slot)
    if not greenhouse then
        return " <RGB:1,1,1> <SIZE:Medium> Greenhouse <LINE> "
            .. " <RGB:0.72,0.72,0.72> No greenhouse has been built yet. Construct one from the colony building screen to start indoor farming. <LINE> "
    end

    local text = ""
    text = text .. " <RGB:1,1,1> <SIZE:Medium> " .. tostring(Utils.GetGreenhouseDisplayName(greenhouse)) .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Garden Beds: <RGB:1,1,1> "
        .. tostring(greenhouse and greenhouse.activeSlotCount or 0)
        .. " / "
        .. tostring(greenhouse and greenhouse.slotCount or 0)
        .. " active <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Thermostat: <RGB:1,1,1> "
        .. tostring(greenhouse and greenhouse.thermostatC or 20)
        .. " C <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Water Use: <RGB:1,1,1> "
        .. tostring(greenhouse and greenhouse.dailyWaterUse or 0)
        .. " / day <LINE> "

    if not slot then
        text = text .. " <LINE> <RGB:0.82,0.82,0.82> Select a garden bed to inspect or plant it. <LINE> "
        return text
    end

    text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Selected Bed <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Bed: <RGB:1,1,1> " .. tostring(slot.slotIndex or 0) .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> State: <RGB:1,1,1> " .. tostring(slot.state or "Empty") .. " <LINE> "

    if tostring(slot.state or "Empty") ~= "Empty" and tostring(slot.state or "") ~= "Dead" then
        text = text .. " <RGB:0.72,0.72,0.72> Crop: <RGB:1,1,1> " .. tostring(slot.displayName or "Crop") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Growth: <RGB:1,1,1> "
            .. tostring(math.floor(((tonumber(slot.growthPercent) or 0) * 100) + 0.5))
            .. "% <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Health: <RGB:1,1,1> " .. tostring(slot.health or 0) .. " hp <LINE> "
        if slot.tempMinC ~= nil and slot.tempMaxC ~= nil then
            text = text .. " <RGB:0.72,0.72,0.72> Ideal Temp: <RGB:1,1,1> "
                .. tostring(slot.tempMinC)
                .. " to "
                .. tostring(slot.tempMaxC)
                .. " C <LINE> "
        end
        if slot.produceDisplayName then
            text = text .. " <RGB:0.72,0.72,0.72> Harvest: <RGB:1,1,1> " .. tostring(slot.produceDisplayName) .. " <LINE> "
        end
    else
        text = text .. " <RGB:0.82,0.82,0.82> Choose a seed below to plant this garden bed. <LINE> "
    end

    return text
end

function Utils.CollectSeedOptions(player)
    player = player or getLocalPlayer()
    local counts = {}
    if player and player.getInventory then
        collectInventoryCountsRecursive(player:getInventory(), counts)
    end

    local options = {}
    for _, crop in ipairs((DC_Colony.Resources and DC_Colony.Resources.GetCropCatalog and DC_Colony.Resources.GetCropCatalog()) or {}) do
        local fullType = crop.seedFullTypes and crop.seedFullTypes[1] or nil
        local totalCount = math.max(0, tonumber(fullType and counts[fullType]) or 0)
        if fullType and totalCount > 0 then
            options[#options + 1] = {
                label = tostring(crop.displayName or crop.cropID or "Crop") .. " (" .. tostring(totalCount) .. ")",
                fullType = fullType,
                count = totalCount,
                crop = crop
            }
        end
    end

    table.sort(options, function(a, b)
        return tostring(a.label or "") < tostring(b.label or "")
    end)

    return options
end

return Utils
