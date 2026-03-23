require "DT/Common/Buildings/DT_Buildings"

DT_Labour = DT_Labour or {}
DT_Labour.Network = DT_Labour.Network or {}
DT_Labour.Network.Internal = DT_Labour.Network.Internal or {}

local LabourConfig = DT_Labour.Config
local Network = DT_Labour.Network
local Buildings = DT_Buildings
local Config = Buildings.Config
local Shared = (Network.Workers or {}).Shared or {}
local Internal = Network.Internal

Network.Handlers = Network.Handlers or {}

local function sendResponse(player, module, command, args)
    if Internal.sendResponse then
        Internal.sendResponse(player, module, command, args)
        return
    end

    if DynamicTrading and DynamicTrading.ServerHelpers and DynamicTrading.ServerHelpers.SendResponse then
        DynamicTrading.ServerHelpers.SendResponse(player, module, command, args)
        return
    end

    if isServer() then
        sendServerCommand(player, module, command, args)
    else
        triggerEvent("OnServerCommand", module, command, args)
    end
end

local function syncBuildingsSnapshot(player, ownerUsername)
    local owner = LabourConfig.GetOwnerUsername(ownerUsername or player)
    sendResponse(player, LabourConfig.COMMAND_MODULE, "SyncBuildingsSnapshot", {
        snapshot = Buildings.BuildOwnerSnapshot(owner)
    })
end

local function syncProjectPreview(player, ownerUsername, buildingType, mode, plotX, plotY, buildingID, installKey)
    local owner = LabourConfig.GetOwnerUsername(ownerUsername or player)
    sendResponse(player, LabourConfig.COMMAND_MODULE, "SyncBuildingProjectPreview", {
        preview = Buildings.BuildProjectPreview(owner, buildingType, mode, plotX, plotY, buildingID, installKey),
        buildingType = buildingType,
        mode = mode,
        plotX = plotX,
        plotY = plotY,
        buildingID = buildingID,
        installKey = installKey
    })
end

local function syncWorkerList(player)
    if Internal.syncWorkerList then
        Internal.syncWorkerList(player)
    end
end

local function removeInventoryItem(item)
    if Internal.removeInventoryItem then
        Internal.removeInventoryItem(item)
        return
    end

    if not item then
        return
    end

    local container = item:getContainer()
    if container then
        container:DoRemoveItem(item)
    end
end

local function collectInventoryItemsRecursive(container, into)
    if not container or not into then
        return
    end

    local items = container:getItems()
    if not items then
        return
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item then
            into[#into + 1] = item
            if instanceof(item, "InventoryContainer") then
                collectInventoryItemsRecursive(item:getItemContainer(), into)
            end
        end
    end
end

Network.Handlers.RequestOwnerBuildings = function(player, args)
    syncBuildingsSnapshot(player, player)
end

Network.Handlers.RequestBuildingProjectPreview = function(player, args)
    if not args or not args.buildingType then
        return
    end
    syncProjectPreview(player, player, args.buildingType, args.mode, args.plotX, args.plotY, args.buildingID, args.installKey)
end

Network.Handlers.StartBuildingProject = function(player, args)
    if not args or not args.workerID or not args.buildingType then
        return
    end

    local owner = LabourConfig.GetOwnerUsername(player)
    local ok, reason, project = Buildings.StartProject(
        owner,
        args.workerID,
        args.buildingType,
        args.mode,
        args.plotX,
        args.plotY,
        args.buildingID,
        args.installKey
    )
    local registry = DT_Labour and DT_Labour.Registry or nil
    local worker = registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(owner, args.workerID) or nil

    if not ok then
        if Internal.syncNotice then
            Internal.syncNotice(player, reason or "Unable to start building project.", "error", true)
        end
        if worker and Shared.saveAndRefreshBasic then
            Shared.saveAndRefreshBasic(player, worker, false)
        end
        syncBuildingsSnapshot(player, owner)
        return
    end

    if worker and Shared.saveAndRefreshProcessed then
        Shared.saveAndRefreshProcessed(player, worker, false)
    elseif worker and Shared.saveAndRefreshBasic then
        Shared.saveAndRefreshBasic(player, worker, false)
    end
    if Internal.syncOwnedFactionStatus then
        Internal.syncOwnedFactionStatus(player)
    end
    if Internal.syncNotice then
        local activityLabel = tostring(project.buildingType or "building")
        if tostring(project.mode or "") == "install" then
            local installDefinition = Config and Config.GetInstallDefinition and Config.GetInstallDefinition(project.buildingType, project.installKey) or nil
            activityLabel = tostring(installDefinition and installDefinition.displayName or project.installKey or "installation") .. " installation"
        else
            activityLabel = activityLabel .. " level " .. tostring(project.targetLevel or 1)
        end
        Internal.syncNotice(
            player,
            (tostring(project.materialState or "") == "Stalled" and ("Queued " .. activityLabel .. ". Waiting for materials.")
                or ("Started " .. activityLabel .. ".")),
            "info",
            false
        )
    end
    syncBuildingsSnapshot(player, owner)
end

Network.Handlers.SupplyBuildingProjectFromInventory = function(player, args)
    if not args or not args.projectID then
        return
    end

    local owner = LabourConfig.GetOwnerUsername(player)
    local project = Buildings.GetProjectByID and Buildings.GetProjectByID(owner, args.projectID) or nil
    if not project or tostring(project.status or "") ~= "Active" then
        if Internal.syncNotice then
            Internal.syncNotice(player, "That project is no longer active.", "error", true)
        end
        syncBuildingsSnapshot(player, owner)
        return
    end

    local materialStatus = Buildings.GetProjectMaterialStatus and Buildings.GetProjectMaterialStatus(project) or nil
    if materialStatus and materialStatus.hasAll == true then
        if Internal.syncNotice then
            Internal.syncNotice(player, "That project already has all required materials.", "info", false)
        end
        syncBuildingsSnapshot(player, owner)
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
    collectInventoryItemsRecursive(inventory, items)

    local movedCount = 0
    for _, item in ipairs(items) do
        local fullType = item and item.getFullType and item:getFullType() or nil
        local needed = fullType and neededByType[fullType] or 0
        if needed and needed > 0 then
            project.materialCounts = type(project.materialCounts) == "table" and project.materialCounts or {}
            project.materialCounts[fullType] = math.max(0, tonumber(project.materialCounts[fullType]) or 0) + 1
            neededByType[fullType] = needed - 1
            movedCount = movedCount + 1
            removeInventoryItem(item)
        end
    end

    local finalStatus = Buildings.RefreshProjectMaterialState and Buildings.RefreshProjectMaterialState(project) or materialStatus
    local registry = DT_Labour and DT_Labour.Registry or nil
    local worker = registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(owner, project.assignedBuilderID) or nil

    if movedCount > 0 then
        Buildings.Save()
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

    syncBuildingsSnapshot(player, owner)
end

Network.Handlers.DestroyBuilding = function(player, args)
    if not args or args.plotX == nil or args.plotY == nil then
        return
    end

    local owner = LabourConfig.GetOwnerUsername(player)
    local ok, reason, building = Buildings.DestroyBuilding(owner, args.plotX, args.plotY, args.buildingID)

    if not ok then
        if Internal.syncNotice then
            Internal.syncNotice(player, reason or "Unable to destroy building.", "error", true)
        end
        syncBuildingsSnapshot(player, owner)
        return
    end

    syncWorkerList(player)
    if Internal.syncOwnedFactionStatus then
        Internal.syncOwnedFactionStatus(player)
    end
    if Internal.syncNotice then
        Internal.syncNotice(
            player,
            "Destroyed " .. tostring(building and (building.buildingType or building.displayName) or "building") .. ".",
            "info",
            false
        )
    end
    syncBuildingsSnapshot(player, owner)
end

return Network
