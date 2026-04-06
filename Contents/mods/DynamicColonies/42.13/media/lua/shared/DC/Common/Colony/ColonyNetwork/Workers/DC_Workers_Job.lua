DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Network = DC_Colony.Network
local Companion = DC_Colony.Companion
local Shared = (Network.Workers or {}).Shared or {}
local Internal = Network.Internal or {}

Network.Handlers = Network.Handlers or {}

local function debugWorkerJob(message)
    local text = "[DC Job Debug][Server] " .. tostring(message)
    print(text)
    if DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DTCommons", "Colony", "Job", tostring(message))
    end
end

local function canAssignJobType(worker, jobType)
    if Config.CanWorkerTakeJob then
        return Config.CanWorkerTakeJob(worker, jobType)
    end
    return true, nil
end

Network.Handlers.SetWorkerJobEnabled = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then return end
    local normalizedJob = Config.NormalizeJobType and Config.NormalizeJobType(worker.jobType) or tostring(worker.jobType or "")

    debugWorkerJob(
        "SetWorkerJobEnabled owner=" .. tostring(owner)
            .. " workerID=" .. tostring(args.workerID)
            .. " enabled=" .. tostring(args.enabled == true)
            .. " jobType=" .. tostring(normalizedJob)
            .. " presenceState=" .. tostring(worker.presenceState)
            .. " state=" .. tostring(worker.state)
    )

    if args.enabled == true and normalizedJob == ((Config.JobTypes or {}).Unemployed) then
        debugWorkerJob("Blocked start because worker is unemployed workerID=" .. tostring(args.workerID))
        Internal.syncNotice(player, "Assign a job first. Unemployed workers stay idle until you choose a role.", "error")
        Shared.saveAndRefreshBasic(player, worker)
        return
    end

    if args.enabled == true and tostring(worker.state or "") == tostring((Config.States or {}).Incapacitated or "Incapacitated") then
        debugWorkerJob("Blocked start because worker is incapacitated workerID=" .. tostring(args.workerID))
        Registry.SetWorkerJobEnabled(worker, false)
        Internal.syncNotice(player, "That worker is incapacitated and must recover before returning to duty.", "error")
        Shared.saveAndRefreshBasic(player, worker)
        return
    end

    if args.enabled ~= true and normalizedJob == ((Config.JobTypes or {}).TravelCompanion) then
        local homeState = tostring((Config.PresenceStates or {}).Home or "Home")
        if tostring(worker.presenceState or "") ~= homeState then
            debugWorkerJob("Starting companion return workerID=" .. tostring(args.workerID))
            Companion.BeginWorkerCompanionReturn(player, worker, Config.ReturnReasons.Manual)
        else
            debugWorkerJob("Disabling companion duty at home workerID=" .. tostring(args.workerID))
            Registry.SetWorkerJobEnabled(worker, false)
        end
    else
        Registry.SetWorkerJobEnabled(worker, args.enabled == true)
        if args.enabled == true and normalizedJob == ((Config.JobTypes or {}).TravelCompanion) then
            local started, reason = Companion.StartWorkerCompanion(player, worker)
            debugWorkerJob(
                "Companion.StartWorkerCompanion workerID=" .. tostring(args.workerID)
                    .. " started=" .. tostring(started)
                    .. " reason=" .. tostring(reason)
            )
            if not started then
                Registry.SetWorkerJobEnabled(worker, false)
                Internal.syncNotice(player, reason or "Unable to start Travel Companion.", "error")
            end
        end
    end
    debugWorkerJob(
        "Saving worker after SetWorkerJobEnabled workerID=" .. tostring(args.workerID)
            .. " jobEnabled=" .. tostring(worker.jobEnabled)
            .. " presenceState=" .. tostring(worker.presenceState)
            .. " state=" .. tostring(worker.state)
    )
    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.SetWorkerAutoRepeatScavenge = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then return end

    Registry.SetWorkerAutoRepeatScavenge(worker, args.enabled == true)
    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.SetWorkerJobType = function(player, args)
    if not args or not args.workerID or not args.jobType then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then return end

    local canAssign, reason = canAssignJobType(worker, args.jobType)
    if not canAssign then
        Internal.syncNotice(player, reason or "That worker cannot take that job.", "error")
        Shared.saveAndRefreshBasic(player, worker)
        return
    end

    local currentJobType = Config.NormalizeJobType and Config.NormalizeJobType(worker.jobType) or tostring(worker.jobType or "")
    local homeState = tostring((Config.PresenceStates or {}).Home or "Home")
    if currentJobType == ((Config.JobTypes or {}).TravelCompanion) and tostring(worker.presenceState or "") ~= homeState then
        Internal.syncNotice(player, "Send that companion home before changing jobs.", "error")
        Shared.saveAndRefreshBasic(player, worker)
        return
    end

    Registry.SetWorkerJobType(worker, args.jobType)
    if Config.NormalizeJobType(args.jobType) == ((Config.JobTypes or {}).TravelCompanion) then
        local started, startReason = Companion.StartWorkerCompanion(player, worker)
        if not started then
            Registry.SetWorkerJobEnabled(worker, false)
            Internal.syncNotice(player, startReason or "Unable to start Travel Companion.", "error")
        end
    end
    Shared.saveAndRefreshProcessed(player, worker)
end

return Network
