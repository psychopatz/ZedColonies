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
        DynamicTrading.Log("DTCommons", "DynamicColonies", "Job", tostring(message))
    end
end

local function canAssignJobType(worker, jobType)
    if Config.CanWorkerTakeJob then
        return Config.CanWorkerTakeJob(worker, jobType)
    end
    return true, nil
end

local function isTravelCompanionSupported()
    if Config.IsTravelCompanionSupported then
        return Config.IsTravelCompanionSupported() == true
    end
    local activated = getActivatedMods and getActivatedMods() or nil
    return activated and activated.contains and activated:contains("DynamicTradingV2") or false
end

local function getCompanionCommandStrings()
    if DynamicTrading and DynamicTrading.GetInteractionStrings then
        local registry = DynamicTrading.GetInteractionStrings("DynamicColonies", "Command")
        return registry and registry.Companion or {}
    end
    return {}
end

local function getOrderMeta(order)
    local companionStrings = getCompanionCommandStrings()
    local orderMeta = companionStrings.OrderMeta and companionStrings.OrderMeta[order] or nil
    if type(orderMeta) == "table" then
        return orderMeta
    end
    return {
        label = tostring(order or "Command"),
        activityText = "Received a new companion command.",
        summarySingle = "{name} acknowledged your order.",
        summaryPlural = "{count} companions acknowledged your order.",
        emptyText = "No commanded companions answered that order.",
    }
end

local function chooseRandomLine(lines, fallback)
    if type(lines) == "table" and #lines > 0 then
        return tostring(lines[ZombRand(#lines) + 1])
    end
    return tostring(fallback or "")
end

local function formatTemplate(template, replacements)
    local text = tostring(template or "")
    for key, value in pairs(replacements or {}) do
        text = string.gsub(text, "{" .. tostring(key) .. "}", tostring(value or ""))
    end
    return text
end

local function findLiveCompanion(uuid)
    if not uuid or not DTNPCServerCore then
        return nil
    end
    if DTNPCServerCore.FindZombieByUUID then
        local zombie = DTNPCServerCore.FindZombieByUUID(uuid)
        if zombie then
            return zombie
        end
    end
    if DTNPCServerCore.GetNPCDataByUUID then
        return DTNPCServerCore.GetNPCDataByUUID(uuid)
    end
    return nil
end

local function appendCompanionCommandLog(worker, player, order)
    local registryInternal = Registry and Registry.Internal or nil
    if not (registryInternal and registryInternal.AppendActivityLog) then
        return
    end

    local commanderName = tostring(player and player.getUsername and player:getUsername() or "You")
    local meta = getOrderMeta(order)
    local message = commanderName .. " ordered companion duty: " .. tostring(meta.activityText or meta.label or order or "commanded")
    registryInternal.AppendActivityLog(worker, message, Shared.getCurrentWorldHours(), "travel")
end

local function buildCompanionCommandSummary(order, affectedWorkers)
    local meta = getOrderMeta(order)
    if #affectedWorkers == 1 then
        return formatTemplate(meta.summarySingle or "{name} acknowledged your order.", {
            name = tostring(affectedWorkers[1].name or affectedWorkers[1].workerID or "Companion"),
            count = 1,
        })
    end

    return formatTemplate(meta.summaryPlural or "{count} companions acknowledged your order.", {
        count = #affectedWorkers,
    })
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

    if normalizedJob == ((Config.JobTypes or {}).TravelCompanion) and not isTravelCompanionSupported() then
        debugWorkerJob("Blocked Travel Companion because V2 is inactive workerID=" .. tostring(args.workerID))
        Registry.SetWorkerJobEnabled(worker, false)
        Internal.syncNotice(player, "Travel Companion requires Dynamic Trading V2.", "error")
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

    local requestedJobType = Config.NormalizeJobType and Config.NormalizeJobType(args.jobType) or tostring(args.jobType or "")
    if requestedJobType == ((Config.JobTypes or {}).TravelCompanion) and not isTravelCompanionSupported() then
        debugWorkerJob("Blocked Travel Companion assignment because V2 is inactive workerID=" .. tostring(args.workerID))
        Internal.syncNotice(player, "Travel Companion requires Dynamic Trading V2.", "error")
        Shared.saveAndRefreshBasic(player, worker)
        return
    end

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

Network.Handlers.SetWorkerCompanionLootConfig = function(player, args)
    if not args or not args.workerID then
        return
    end

    if not isTravelCompanionSupported() then
        Internal.syncNotice(player, "Travel Companion requires Dynamic Trading V2.", "error", true)
        Internal.syncWorkerList(player)
        return
    end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then
        return
    end

    local normalizedJob = Config.NormalizeJobType and Config.NormalizeJobType(worker.jobType) or tostring(worker.jobType or "")
    if normalizedJob ~= tostring((Config.JobTypes or {}).TravelCompanion or "TravelCompanion") then
        Internal.syncNotice(player, "Loot setup is only available for Travel Companion workers.", "error")
        Shared.saveAndRefreshBasic(player, worker)
        return
    end

    local companionInternal = Companion and Companion.Internal or nil
    local companionData = companionInternal and companionInternal.GetCompanionData and companionInternal.GetCompanionData(worker) or nil
    if not companionData then
        Internal.syncNotice(player, "Unable to update that companion right now.", "error")
        Shared.saveAndRefreshBasic(player, worker)
        return
    end

    local lootConfig = companionInternal and companionInternal.NormalizeCompanionLootConfig
        and companionInternal.NormalizeCompanionLootConfig(args.lootConfig or args.config or {})
        or (args.lootConfig or args.config or {})

    companionData.lootConfig = lootConfig

    local profile = Config.GetScavengeSiteProfile and Config.GetScavengeSiteProfile(lootConfig.profileID) or nil
    local profileLabel = lootConfig.profileID and tostring(profile and profile.displayName or lootConfig.profileID) or "no preset"
    local tagCount = #(lootConfig.rawTags or {})

    Internal.syncNotice(
        player,
        "Saved companion loot setup: " .. profileLabel .. ", " .. tostring(tagCount) .. " tag queries.",
        "info",
        false
    )
    Shared.saveAndRefreshBasic(player, worker)
end

Network.Handlers.ClaimCompanionCommand = function(player, args)
    if not args or not args.workerID then return end
    if not isTravelCompanionSupported() then
        Internal.syncNotice(player, "Travel Companion requires Dynamic Trading V2.", "error", true)
        Internal.syncWorkerList(player)
        return
    end
    local ok, reason, worker = Companion.ClaimWorkerCompanionCommand(player, args.workerID)
    if not ok then
        Internal.syncNotice(player, reason or "Unable to claim companion command.", "error", true)
    else
        Internal.syncNotice(player, reason or "Companion command claimed.", "info", false)
    end
    if worker then
        Shared.saveAndRefreshBasic(player, worker)
    else
        Internal.syncWorkerList(player)
    end
end

Network.Handlers.TransferCompanionCommand = function(player, args)
    if not args or not args.workerID then return end
    if not isTravelCompanionSupported() then
        Internal.syncNotice(player, "Travel Companion requires Dynamic Trading V2.", "error", true)
        Internal.syncWorkerList(player)
        return
    end
    local ok, reason, worker = Companion.TransferWorkerCompanionCommand(player, args.workerID, args.username)
    if not ok then
        Internal.syncNotice(player, reason or "Unable to transfer companion command.", "error", true)
    else
        Internal.syncNotice(player, reason or "Companion command transferred.", "info", false)
    end
    if worker then
        Shared.saveAndRefreshBasic(player, worker)
    else
        Internal.syncWorkerList(player)
    end
end

Network.Handlers.RequestCompanionCommandStatus = function(player, args)
    if not args or not args.workerID then return end
    if not isTravelCompanionSupported() then
        Internal.syncNotice(player, "Travel Companion requires Dynamic Trading V2.", "error", true)
        Internal.syncWorkerList(player)
        return
    end
    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if worker and Companion.RefreshCompanionCommanderValidity then
        Companion.RefreshCompanionCommanderValidity(worker)
        Shared.saveAndRefreshBasic(player, worker)
    else
        Internal.syncWorkerDetail(player, args.workerID, nil, true)
    end
end

Network.Handlers.IssueCompanionOrderToAllNearby = function(player, args)
    if not args or not args.order then
        return
    end

    if not isTravelCompanionSupported() then
        Internal.sendResponse(player, Config.COMMAND_MODULE, "CompanionCommandResult", {
            order = tostring(args and args.order or ""),
            affectedCount = 0,
            results = {},
            message = tostring((getCompanionCommandStrings().Notices or {}).Unsupported or "Travel Companion requires Dynamic Trading V2."),
            popup = false,
        })
        return
    end

    local owner = Config.GetOwnerUsername(player)
    local workers = Registry.GetWorkersForOwner(owner)
    local radius = math.max(1, tonumber(args.radius) or tonumber(Config.GetCompanionCommandRadius and Config.GetCompanionCommandRadius()) or 20)
    local order = tostring(args.order)
    local orderArgs = type(args.args) == "table" and args.args or {}
    local px = player:getX()
    local py = player:getY()
    local companionJob = (Config.JobTypes or {}).TravelCompanion
    local activePresence = tostring((Config.PresenceStates or {}).CompanionActive or "CompanionActive")
    local toPlayerPresence = tostring((Config.PresenceStates or {}).CompanionToPlayer or "CompanionToPlayer")
    local companionInternal = Companion and Companion.Internal or nil
    local companionStrings = getCompanionCommandStrings()
    local ackLines = companionStrings.CompanionAck and companionStrings.CompanionAck[order] or nil
    local results = {}
    local affectedWorkers = {}

    debugWorkerJob("IssueCompanionOrderToAllNearby owner=" .. tostring(owner) .. " order=" .. order .. " radius=" .. tostring(radius))

    for _, worker in ipairs(workers or {}) do
        local isCompanion = Config.NormalizeJobType(worker.jobType) == companionJob
        local presenceState = tostring(worker.presenceState or "")
        local isActive = presenceState == activePresence or presenceState == toPlayerPresence

        if isCompanion and isActive then
            local uuid = companionInternal and companionInternal.GetCompanionUUID and companionInternal.GetCompanionUUID(worker) or nil
            local zombie = uuid and findLiveCompanion(uuid) or nil
            if zombie then
                local dist = IsoUtils.DistanceTo(px, py, zombie:getX(), zombie:getY())
                if dist <= radius then
                    local canCommand, reason = Companion.CanPlayerCommandCompanion(player, worker)
                    if canCommand then
                        local changed = false
                        if order == "Dismiss" then
                            Companion.BeginWorkerCompanionReturn(player, worker, Config.ReturnReasons.Manual)
                            changed = true
                        else
                            changed = Companion.IssueWorkerCompanionOrder(player, worker.workerID, order, orderArgs) == true
                        end

                        if changed then
                            appendCompanionCommandLog(worker, player, order)
                            Shared.saveAndRefreshBasic(player, worker)
                            affectedWorkers[#affectedWorkers + 1] = worker
                            results[#results + 1] = {
                                workerID = worker.workerID,
                                uuid = uuid,
                                name = tostring(worker.name or worker.workerID or "Companion"),
                                ackText = chooseRandomLine(ackLines, getOrderMeta(order).label),
                            }
                        end
                    else
                        debugWorkerJob("Cannot command companion " .. tostring(worker.workerID) .. ": " .. tostring(reason))
                    end
                end
            else
                debugWorkerJob(
                    "Skipping companion workerID=" .. tostring(worker.workerID)
                        .. " presenceState=" .. tostring(presenceState)
                        .. " uuid=" .. tostring(uuid)
                        .. " because no live NPC was found."
                )
            end
        end
    end

    local meta = getOrderMeta(order)
    local message = #affectedWorkers > 0
        and buildCompanionCommandSummary(order, affectedWorkers)
        or tostring(meta.emptyText or (companionStrings.Notices and companionStrings.Notices.NoTargets) or "No commanded companions answered that order.")

    Internal.sendResponse(player, Config.COMMAND_MODULE, "CompanionCommandResult", {
        order = order,
        radius = radius,
        affectedCount = #affectedWorkers,
        results = results,
        message = message,
        popup = false,
    })
end

return Network
