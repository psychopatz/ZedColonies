require "DC/Common/Buildings/DC_Buildings"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local ColonyConfig = DC_Colony.Config
local Network = DC_Colony.Network
local Buildings = DC_Buildings
local Config = Buildings.Config
local Shared = (Network.Workers or {}).Shared or {}
local Internal = Network.Internal

Network.Handlers = Network.Handlers or {}

local function canUseDebug(player)
    if DynamicTrading and DynamicTrading.Debug then
        return true
    end

    if isDebugEnabled and isDebugEnabled() then
        return true
    end

    if player and player.getAccessLevel then
        local accessLevel = player:getAccessLevel()
        if accessLevel and accessLevel ~= "" and accessLevel ~= "None" then
            return true
        end
    end

    return false
end

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
    local owner = ColonyConfig.GetOwnerUsername(ownerUsername or player)
    if Buildings.EnsureInitialHeadquartersProject then
        Buildings.EnsureInitialHeadquartersProject(owner)
    end
    sendResponse(player, ColonyConfig.COMMAND_MODULE, "SyncBuildingsSnapshot", {
        snapshot = Buildings.BuildOwnerSnapshot(owner, player)
    })
end

local function syncProjectPreview(player, ownerUsername, buildingType, mode, plotX, plotY, buildingID, installKey)
    local owner = ColonyConfig.GetOwnerUsername(ownerUsername or player)
    sendResponse(player, ColonyConfig.COMMAND_MODULE, "SyncBuildingProjectPreview", {
        preview = Buildings.BuildProjectPreview(owner, buildingType, mode, plotX, plotY, buildingID, installKey, player),
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

local function addInventoryItem(container, fullType, count)
    if not container or not fullType then
        return nil
    end

    if Internal.addInventoryItem then
        return Internal.addInventoryItem(container, fullType, count)
    end

    return container:AddItems(fullType, count or 1)
end

local function getInventoryItemQuantity(item)
    if not item then
        return 0
    end

    local count = item.getCount and item:getCount() or nil
    count = math.floor(tonumber(count) or 0)
    if count > 0 then
        return count
    end

    return 1
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
    if not args or not args.buildingType then
        return
    end

    local owner = ColonyConfig.GetOwnerUsername(player)
    local workerID = tostring(args.workerID or "")
    if workerID == "" then
        workerID = nil
    end

    local ok, reason, project
    if workerID then
        ok, reason, project = Buildings.StartProject(
            owner,
            workerID,
            args.buildingType,
            args.mode,
            args.plotX,
            args.plotY,
            args.buildingID,
            args.installKey
        )
    else
        ok, reason, project = Buildings.QueueProject(
            owner,
            args.buildingType,
            args.mode,
            args.plotX,
            args.plotY,
            args.buildingID,
            args.installKey
        )
    end
    local registry = DC_Colony and DC_Colony.Registry or nil
    local worker = workerID and registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(owner, workerID) or nil

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
        local materialReady = tostring(project.materialState or "") ~= "Stalled"
        local hasBuilder = tostring(project.assignedBuilderID or "") ~= ""
        local noticeText = nil
        if hasBuilder and materialReady then
            noticeText = "Started " .. activityLabel .. "."
        elseif hasBuilder then
            noticeText = "Queued " .. activityLabel .. ". Waiting for materials."
        elseif materialReady then
            noticeText = "Queued " .. activityLabel .. ". Waiting for a builder assignment."
        else
            noticeText = "Queued " .. activityLabel .. ". Waiting for materials and a builder assignment."
        end
        Internal.syncNotice(
            player,
            noticeText,
            "info",
            false
        )
    end
    syncBuildingsSnapshot(player, owner)
end

Network.Handlers.ReassignBuildingProject = function(player, args)
    if not args or not args.projectID or not args.workerID then
        return
    end

    local owner = ColonyConfig.GetOwnerUsername(player)
    local ok, reason, project, currentWorker, nextWorker = Buildings.ReassignProjectBuilder(
        owner,
        args.projectID,
        args.workerID
    )

    if not ok then
        if Internal.syncNotice then
            Internal.syncNotice(player, reason or "Unable to reassign the builder for that project.", "error", true)
        end
        syncBuildingsSnapshot(player, owner)
        return
    end

    if currentWorker and tostring(currentWorker.workerID or "") ~= tostring(nextWorker and nextWorker.workerID or "") then
        Internal.syncWorkerDetail(player, currentWorker.workerID, false)
    end
    if nextWorker then
        Internal.syncWorkerDetail(player, nextWorker.workerID, false)
    end
    syncWorkerList(player)

    if Internal.syncOwnedFactionStatus then
        Internal.syncOwnedFactionStatus(player)
    end
    if Internal.syncNotice then
        if currentWorker and tostring(currentWorker.workerID or "") == tostring(nextWorker and nextWorker.workerID or "") then
            Internal.syncNotice(
                player,
                tostring(nextWorker and (nextWorker.name or nextWorker.workerID) or "That builder") .. " is already assigned to this project.",
                "info",
                false
            )
        else
            Internal.syncNotice(
                player,
                "Reassigned project builder to " .. tostring(nextWorker and (nextWorker.name or nextWorker.workerID) or "the selected worker") .. ".",
                "info",
                false
            )
        end
    end
    syncBuildingsSnapshot(player, owner)
end

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
            local available = getInventoryItemQuantity(item)
            local movedUnits = math.min(available, needed)
            local container = item:getContainer()
            project.materialCounts = type(project.materialCounts) == "table" and project.materialCounts or {}
            project.materialCounts[fullType] = math.max(0, tonumber(project.materialCounts[fullType]) or 0) + movedUnits
            neededByType[fullType] = needed - movedUnits
            movedCount = movedCount + movedUnits
            removeInventoryItem(item)
            if available > movedUnits and container then
                addInventoryItem(container, fullType, available - movedUnits)
            end
        end
    end

    local finalStatus = Buildings.RefreshProjectMaterialState and Buildings.RefreshProjectMaterialState(project) or materialStatus
    local registry = DC_Colony and DC_Colony.Registry or nil
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

Network.Handlers.DebugGiveProjectMaterials = function(player, args)
    if not player or not canUseDebug(player) then
        return
    end

    args = args or {}
    if not args.buildingType then
        return
    end

    local owner = ColonyConfig.GetOwnerUsername(player)
    local inventory = player:getInventory()
    if not inventory then
        if Internal.syncNotice then
            Internal.syncNotice(player, "No player inventory found.", "error", true)
        end
        return
    end

    local addedCount = 0
    local recipeEntries = nil
    if args.projectID and Buildings.GetProjectByID then
        local project = Buildings.GetProjectByID(owner, args.projectID)
        if project and tostring(project.status or "") == "Active" then
            recipeEntries = project.recipe or {}
        end
    end
    if not recipeEntries then
        local preview = Buildings.BuildProjectPreview(
            owner,
            args.buildingType,
            args.mode,
            args.plotX,
            args.plotY,
            args.buildingID,
            args.installKey
        )
        recipeEntries = preview and preview.recipeAvailability and preview.recipeAvailability.entries or {}
    end

    local addInventoryItem = Internal.addInventoryItem
    for _, entry in ipairs(recipeEntries or {}) do
        local fullType = tostring(entry and entry.fullType or "")
        local count = math.max(0, math.floor(tonumber(entry and entry.count) or 0))
        if fullType ~= "" and count > 0 then
            if addInventoryItem then
                addInventoryItem(inventory, fullType, count)
            else
                inventory:AddItems(fullType, count)
            end
            addedCount = addedCount + count
        end
    end

    if Internal.syncNotice then
        if addedCount > 0 then
            Internal.syncNotice(
                player,
                "Debug added " .. tostring(addedCount) .. " building material item" .. (addedCount == 1 and "" or "s") .. ".",
                "info",
                false
            )
        else
            Internal.syncNotice(player, "No materials were defined for that project preview.", "error", true)
        end
    end
end

Network.Handlers.DebugCompleteBuildingProject = function(player, args)
    if not player or not canUseDebug(player) then
        return
    end

    if not args or not args.projectID then
        return
    end

    local owner = ColonyConfig.GetOwnerUsername(player)
    local project = Buildings.GetProjectByID and Buildings.GetProjectByID(owner, args.projectID) or nil
    if not project or tostring(project.status or "") ~= "Active" then
        if Internal.syncNotice then
            Internal.syncNotice(player, "That project is no longer active.", "error", true)
        end
        syncBuildingsSnapshot(player, owner)
        return
    end

    local registry = DC_Colony and DC_Colony.Registry or nil
    local worker = registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(owner, project.assignedBuilderID) or nil
    local activityLabel = tostring(project.buildingType or "building")
    if tostring(project.mode or "") == "install" then
        local installDefinition = Config and Config.GetInstallDefinition and Config.GetInstallDefinition(project.buildingType, project.installKey) or nil
        activityLabel = tostring(installDefinition and installDefinition.displayName or project.installKey or "installation") .. " installation"
    else
        activityLabel = activityLabel .. " level " .. tostring(project.targetLevel or 1)
    end

    Buildings.CompleteProject(project)
    if tostring(project.status or "") ~= "Completed" then
        if Internal.syncNotice then
            Internal.syncNotice(player, project.failureReason or "Unable to complete that project.", "error", true)
        end
        syncBuildingsSnapshot(player, owner)
        return
    end

    if worker and Buildings.AssignNextReadyProjectToWorker then
        Buildings.AssignNextReadyProjectToWorker(worker)
    end

    if worker and Shared.saveAndRefreshProcessed then
        Shared.saveAndRefreshProcessed(player, worker, false)
    elseif worker and Shared.saveAndRefreshBasic then
        Shared.saveAndRefreshBasic(player, worker, false)
    else
        syncWorkerList(player)
    end

    if Internal.syncOwnedFactionStatus then
        Internal.syncOwnedFactionStatus(player)
    end
    if Internal.syncNotice then
        Internal.syncNotice(player, "Debug completed " .. activityLabel .. ".", "info", false)
    end
    syncBuildingsSnapshot(player, owner)
end

Network.Handlers.DestroyBuilding = function(player, args)
    if not args or args.plotX == nil or args.plotY == nil then
        return
    end

    local owner = ColonyConfig.GetOwnerUsername(player)
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
