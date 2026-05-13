require "DC/Common/Buildings/Core/DC_Buildings"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local ColonyConfig = DC_Colony.Config
local Network = DC_Colony.Network
local Buildings = DC_Buildings
local Shared = (Network.Workers or {}).Shared or {}
local Internal = Network.Internal

Network.Handlers = Network.Handlers or {}

Network.Handlers.SupplyBuildingProjectFromInventory = function(player, args)
    if not args or not args.projectID then
        return
    end

    local owner = ColonyConfig.GetOwnerUsername(player)
    local project = Buildings.GetProjectByID and Buildings.GetProjectByID(owner, args.projectID) or nil
    if not project or tostring(project.status or "") ~= "Active" then
        if Internal.syncNotice then
            Internal.syncNotice(player, "That project is no longer active.", "error", true)
        end
        if Internal.syncBuildingState and args.plotX ~= nil and args.plotY ~= nil then
            Internal.syncBuildingState(player, owner, args.plotX, args.plotY, {
                sourcePlayer = player,
            })
        end
        return
    end

    local materialStatus = Buildings.GetProjectMaterialStatus and Buildings.GetProjectMaterialStatus(project) or nil
    if materialStatus and materialStatus.hasAll == true then
        if Internal.syncNotice then
            Internal.syncNotice(player, "That project already has all required materials.", "info", false)
        end
        if Internal.syncBuildingState then
            Internal.syncBuildingState(player, owner, project.plotX, project.plotY, {
                sourcePlayer = player,
            })
        end
        return
    end

    local inventory = player and player:getInventory() or nil
    if not inventory then
        if Internal.syncNotice then
            Internal.syncNotice(player, "No player inventory found.", "error", true)
        end
        return
    end

    local neededByType = {}
    for _, entry in ipairs(materialStatus and materialStatus.entries or {}) do
        local fullType = tostring(entry and entry.fullType or "")
        local remaining = math.max(0, tonumber(entry and entry.remaining) or 0)
        if fullType ~= "" and remaining > 0 then
            neededByType[fullType] = remaining
        end
    end

    local items = {}
    if Internal.collectInventoryItemsRecursive then
        Internal.collectInventoryItemsRecursive(inventory, items)
    end

    local movedCount = 0
    local removeInventoryItem = Internal.removeInventoryItem
    local addInventoryItem = Internal.addInventoryItem
    local getInventoryItemQuantity = Internal.getInventoryItemQuantity

    for _, item in ipairs(items) do
        local fullType = item and item.getFullType and item:getFullType() or nil
        local needed = fullType and neededByType[fullType] or 0
        if needed and needed > 0 then
            local available = getInventoryItemQuantity and getInventoryItemQuantity(item) or 1
            local movedUnits = math.min(available, needed)
            local container = item:getContainer()
            project.materialCounts = type(project.materialCounts) == "table" and project.materialCounts or {}
            project.materialCounts[fullType] = math.max(0, tonumber(project.materialCounts[fullType]) or 0) + movedUnits
            neededByType[fullType] = needed - movedUnits
            movedCount = movedCount + movedUnits
            if removeInventoryItem then
                removeInventoryItem(item)
            end
            if available > movedUnits and container and addInventoryItem then
                addInventoryItem(container, fullType, available - movedUnits)
            end
        end
    end

    local finalStatus = Buildings.RefreshProjectMaterialState and Buildings.RefreshProjectMaterialState(project) or materialStatus
    local registry = DC_Colony and DC_Colony.Registry or nil
    local worker = registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(owner, project.assignedBuilderID) or nil

    if movedCount > 0 then
        if Buildings.Save then
            Buildings.Save()
        end
    end

    if worker and Shared.saveAndRefreshProcessed then
        Shared.saveAndRefreshProcessed(player, worker, false)
    elseif worker and Shared.saveAndRefreshBasic then
        Shared.saveAndRefreshBasic(player, worker, false)
    end

    if Internal.syncNotice then
        if movedCount <= 0 then
            Internal.syncNotice(player, "No matching inventory materials were found for that project.", "error", true)
        elseif finalStatus and finalStatus.hasAll == true then
            Internal.syncNotice(player, "Project fully supplied from inventory and warehouse. Construction can begin.", "info", false)
        else
            Internal.syncNotice(
                player,
                "Added " .. tostring(movedCount) .. " material item" .. (movedCount == 1 and "" or "s") .. " from inventory.",
                "info",
                false
            )
        end
    end

    if Internal.syncBuildingState then
        Internal.syncBuildingState(player, owner, project.plotX, project.plotY, {
            sourcePlayer = player,
        })
    end
end

return Network
