require "DC/Common/Buildings/Core/DC_Buildings"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"

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
        if Internal.syncBuildingState and args.plotX ~= nil and args.plotY ~= nil then
            Internal.syncBuildingState(player, owner, args.plotX, args.plotY, {
                sourcePlayer = player,
            })
        end
        return
    end

    if worker and Shared.saveAndRefreshProcessed then
        Shared.saveAndRefreshProcessed(player, worker, false)
    elseif worker and Shared.saveAndRefreshBasic then
        Shared.saveAndRefreshBasic(player, worker, false)
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
    if Internal.syncBuildingState then
        Internal.syncBuildingState(player, owner, project.plotX, project.plotY, {
            sourcePlayer = player,
        })
    end
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
        if Internal.syncBuildingState and project and project.plotX ~= nil and project.plotY ~= nil then
            Internal.syncBuildingState(player, owner, project.plotX, project.plotY, {
                sourcePlayer = player,
            })
        end
        return
    end

    if currentWorker and tostring(currentWorker.workerID or "") ~= tostring(nextWorker and nextWorker.workerID or "") then
        if Internal.syncWorkerDetail then
            Internal.syncWorkerDetail(player, currentWorker.workerID, false)
        end
    end
    if nextWorker then
        if Internal.syncWorkerDetail then
            Internal.syncWorkerDetail(player, nextWorker.workerID, false)
        end
    end
    if Internal.syncWorkerList then
        Internal.syncWorkerList(player)
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
    if Internal.syncBuildingState then
        Internal.syncBuildingState(player, owner, project.plotX, project.plotY, {
            sourcePlayer = player,
        })
    end
end

return Network
