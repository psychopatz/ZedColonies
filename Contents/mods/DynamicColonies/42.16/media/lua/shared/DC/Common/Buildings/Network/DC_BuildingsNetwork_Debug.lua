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

Network.Handlers.DebugGiveProjectMaterials = function(player, args)
    if not player or (Internal.canUseDebug and not Internal.canUseDebug(player)) then
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
            args.installKey,
            player
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
    if not player or (Internal.canUseDebug and not Internal.canUseDebug(player)) then
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
        if Internal.syncBuildingState and args.plotX ~= nil and args.plotY ~= nil then
            Internal.syncBuildingState(player, owner, args.plotX, args.plotY, {
                sourcePlayer = player,
            })
        end
        return
    end

    local registry = DC_Colony and DC_Colony.Registry or nil
    local worker = registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(owner, project.assignedBuilderID) or nil
    local activityLabel = tostring(project.buildingType or "building")
    if tostring(project.mode or "") == "install" then
        local Config = Buildings.Config
        local installDefinition = Config and Config.GetInstallDefinition and Config.GetInstallDefinition(project.buildingType, project.installKey) or nil
        activityLabel = tostring(installDefinition and installDefinition.displayName or project.installKey or "installation") .. " installation"
    else
        activityLabel = activityLabel .. " level " .. tostring(project.targetLevel or 1)
    end

    local _, transition = Buildings.CompleteProject(project)
    if tostring(project.status or "") ~= "Completed" then
        if Internal.syncNotice then
            Internal.syncNotice(player, project.failureReason or "Unable to complete that project.", "error", true)
        end
        if Internal.syncBuildingState then
            Internal.syncBuildingState(player, owner, project.plotX, project.plotY, {
                sourcePlayer = player,
            })
        end
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
        if Internal.syncWorkerList then
            Internal.syncWorkerList(player)
        end
    end

    if Internal.syncNotice then
        Internal.syncNotice(player, "Debug completed " .. activityLabel .. ".", "info", false)
    end
    if transition and transition.realBase and transition.realBase.shouldPromptName == true and Internal.sendResponse then
        Internal.sendResponse(player, ColonyConfig.COMMAND_MODULE or "DColony", "PromptBuildingName", {
            buildingID = project.buildingID,
            buildingType = project.buildingType,
            defaultValue = transition.realBase.defaultName,
        })
    end
    local mapChange = Internal.BuildingMap and Internal.BuildingMap.Touch and Internal.BuildingMap.Touch(owner, {
        plotX = project.plotX,
        plotY = project.plotY,
        projectID = project.projectID,
        transition = transition,
        topologyChanged = transition and transition.safetyChanged == true or false,
    }) or nil
    if Internal.syncBuildingState then
        Internal.syncBuildingState(player, owner, project.plotX, project.plotY, {
            sourcePlayer = player,
            mapChange = mapChange,
        })
    end
    if transition and transition.safetyChanged == true and Internal.syncPlotSafety then
        transition.mapChange = mapChange
        Internal.syncPlotSafety(player, owner, transition)
    end
end

return Network
