local Internal = DC_ResearchStationModalInternal

function Internal.GetCommandModule()
    return (DC_Colony and DC_Colony.Config and DC_Colony.Config.COMMAND_MODULE) or "DColony"
end

function Internal.GetPlayerObject()
    local config = DC_Colony and DC_Colony.Config or nil
    return config and config.GetPlayerObject and config.GetPlayerObject() or nil
end

function Internal.SendColonyCommand(ownerWindow, command, args)
    if ownerWindow and ownerWindow.sendColonyCommand then
        return ownerWindow:sendColonyCommand(command, args or {})
    end

    local player = Internal.GetPlayerObject()
    if not player then
        return false
    end

    if isClient() and not isServer() then
        sendClientCommand(player, Internal.GetCommandModule(), command, args or {})
        return true
    end

    return false
end

function Internal.GetResearchBlueprint(fullType)
    local research = DC_Colony and DC_Colony.Research or nil
    local internal = research and research.Internal or nil
    return internal and internal.BuildBlueprintRecord and internal.BuildBlueprintRecord(fullType) or nil
end

function Internal.GetDisplayNameForFullType(fullType)
    local registry = DC_Colony and DC_Colony.Registry or nil
    local internal = registry and registry.Internal or nil
    return internal and internal.GetDisplayNameForFullType and internal.GetDisplayNameForFullType(fullType) or tostring(fullType or "Unknown")
end

function Internal.FormatInputEntry(input)
    local count = math.max(0, math.floor(tonumber(input and input.count) or 0))
    local label = tostring(input and input.displayName or "")
    if label == "" and tostring(input and input.fullType or "") ~= "" then
        label = Internal.GetDisplayNameForFullType(input.fullType)
    end
    if label == "" then
        label = tostring(input and input.category or input and input.fullType or "Unknown")
    end
    return tostring(count) .. "x " .. label
end

function Internal.FormatQueueLabel(entry)
    local progressRatio = math.max(0, math.min(1, tonumber(entry and entry.progressRatio) or 0))
    return tostring(entry and entry.displayName or entry and entry.fullType or "Research")
        .. " ("
        .. tostring(math.floor((progressRatio * 100) + 0.5))
        .. "%)"
        .. " "
        .. tostring(math.floor((tonumber(entry and entry.progressWork) or 0) + 0.5))
        .. "/"
        .. tostring(math.floor((tonumber(entry and entry.requiredWork) or 0) + 0.5))
        .. " WP"
end

function Internal.CollectInventoryItems(container, grouped)
    if not container or not container.getItems then
        return
    end

    local items = container:getItems()
    if not items then
        return
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item and item.getFullType then
            local fullType = tostring(item:getFullType() or "")
            local converted = DC_Colony and DC_Colony.Config and DC_Colony.Config.GetItemCategoryData
                and DC_Colony.Config.GetItemCategoryData(fullType) or nil
            local blueprint = fullType ~= "" and Internal.GetResearchBlueprint(fullType) or nil
            if fullType ~= "" and blueprint then
                local existing = grouped[fullType]
                local count = math.max(1, math.floor(tonumber(item.getCount and item:getCount() or 1) or 1))
                if not existing then
                    existing = {
                        fullType = fullType,
                        displayName = item.getDisplayName and item:getDisplayName() or fullType,
                        category = tostring(blueprint.category or converted and converted.category or ""),
                        group = tostring(blueprint.group or converted and converted.group or ""),
                        blueprint = blueprint,
                        count = 0,
                        itemRefs = {},
                    }
                    grouped[fullType] = existing
                end
                existing.count = existing.count + count
                existing.itemRefs[#existing.itemRefs + 1] = {
                    itemID = item:getID(),
                    count = count,
                }
            end
        end
    end
end

function Internal.BuildCandidateList()
    local player = Internal.GetPlayerObject()
    local grouped = {}
    if player and player.getInventory then
        Internal.CollectInventoryItems(player:getInventory(), grouped)
    end

    local entries = {}
    for _, entry in pairs(grouped) do
        entries[#entries + 1] = entry
    end

    table.sort(entries, function(a, b)
        local aName = string.lower(tostring(a and a.displayName or a and a.fullType or ""))
        local bName = string.lower(tostring(b and b.displayName or b and b.fullType or ""))
        if aName == bName then
            return tostring(a and a.fullType or "") < tostring(b and b.fullType or "")
        end
        return aName < bName
    end)

    return entries
end
