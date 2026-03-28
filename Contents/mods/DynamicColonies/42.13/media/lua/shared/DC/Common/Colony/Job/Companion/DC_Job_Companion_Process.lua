local Config = DC_Colony.Config
local Sim = DC_Colony.Sim
local Internal = Sim.Internal
local Energy = DC_Colony.Energy

local function getLiveCompanionData(worker)
    if not worker or not Config or not Config.ResolveWorkerCompanionUUID then
        return nil
    end

    local uuid = Config.ResolveWorkerCompanionUUID(worker)
    if not uuid then
        return nil
    end

    return DTNPCManager and DTNPCManager.Data and DTNPCManager.Data[uuid] or nil
end

local function isCompanionActivelyFighting(npcData)
    if not npcData then
        return false
    end

    if npcData.combatTargetID ~= nil then
        return true
    end

    local state = tostring(npcData.state or "")
    return state == "Attack"
        or state == "AttackRange"
        or state == "TradingDefenseRanged"
        or state == "TradingDefenseMelee"
end

local function invalidateFollowJob(worker, currentHour, reason)
    if worker.jobEnabled == true or worker.state ~= Config.States.Idle then
        Internal.appendWorkerLog(
            worker,
            tostring(reason or "Follow Player stopped because the recruited companion link is no longer available."),
            currentHour,
            "jobs"
        )
    end

    if Config.ReleaseWorkerCompanionControl then
        Config.ReleaseWorkerCompanionControl(worker)
    end

    worker.jobEnabled = false
    worker.state = Config.States.Idle
    worker.workProgress = 0
    worker.presenceState = Config.PresenceStates.Home
end

function Sim.ProcessCompanionJob(worker, ctx)
    local currentHour = ctx.currentHour
    local profile = ctx.profile
    local hp = ctx.hp
    local hasCalories = ctx.hasCalories
    local hasHydration = ctx.hasHydration
    local forcedRest = ctx.forcedRest
    local workableHours = ctx.workableHours
    local deltaHours = ctx.deltaHours
    local lowEnergyReason = ctx.lowEnergyReason

    worker.scavengeTier = nil
    worker.scavengeTierLabel = nil
    worker.scavengePoolRolls = nil
    worker.scavengeFailureWeight = nil
    worker.scavengeSearchSpeedMultiplier = nil
    worker.scavengeCapabilities = nil
    worker.fishingTier = nil
    worker.fishingTierLabel = nil
    worker.fishingCapabilities = nil
    worker.fishingBaitActive = nil
    worker.fishingHasBackpack = nil
    worker.presenceState = Config.PresenceStates.Home
    worker.workProgress = 0
    worker.workTarget = nil
    worker.workCycleHours = nil

    if hp <= 0 then
        worker.state = Config.States.Dead
        return
    end

    if not worker.jobEnabled then
        if Config.UpdateWorkerCompanionReturnState then
            Config.UpdateWorkerCompanionReturnState(worker)
        end
        if worker.companionReturnPending == true then
            return
        end
        if Energy and forcedRest and deltaHours > 0 and hp > 0 then
            Energy.ApplyHomeRecovery(worker, deltaHours, profile)
            Energy.CompleteForcedRest(worker, currentHour, "Fully rested again.")
            if Energy.IsForcedRest(worker) then
                worker.state = Config.States.Resting
            else
                worker.state = Config.States.Idle
            end
            return
        end
        if Config.ReleaseWorkerCompanionControl then
            Config.ReleaseWorkerCompanionControl(worker)
        end
        if Config.UpdateWorkerCompanionReturnState then
            Config.UpdateWorkerCompanionReturnState(worker)
        end
        if worker.companionReturnPending ~= true then
            worker.state = Config.States.Idle
        end
        return
    end

    if not hasHydration then
        if Config.ReleaseWorkerCompanionControl then
            Config.ReleaseWorkerCompanionControl(worker)
        end
        worker.state = Config.States.Dehydrated
        return
    end

    if not hasCalories then
        if Config.ReleaseWorkerCompanionControl then
            Config.ReleaseWorkerCompanionControl(worker)
        end
        worker.state = Config.States.Starving
        return
    end

    if forcedRest then
        worker.jobEnabled = false
        if Config.ReleaseWorkerCompanionControl then
            Config.ReleaseWorkerCompanionControl(worker, lowEnergyReason, "I need to rest. Heading home.", "warning")
        end
        if Config.UpdateWorkerCompanionReturnState then
            Config.UpdateWorkerCompanionReturnState(worker)
        end
        if worker.companionReturnPending == true then
            return
        end
        worker.state = Config.States.Resting
        return
    end

    local followed = false
    local reason = "MissingCompanionBridge"
    if Config.SyncWorkerCompanionFollow then
        followed, reason = Config.SyncWorkerCompanionFollow(worker)
    end
    if followed then
        if Energy and deltaHours > 0 and hp > 0 then
            local companionData = getLiveCompanionData(worker)
            local foughtThisTick = isCompanionActivelyFighting(companionData)

            if foughtThisTick and workableHours > 0 then
                Energy.ApplyWorkDrain(worker, workableHours, profile)
            end

            forcedRest = Energy.IsForcedRest(worker)
            if forcedRest then
                Energy.CompleteForcedRest(worker, currentHour, "Fully rested again.")
            elseif foughtThisTick and Energy.IsDepleted(worker) then
                forcedRest = true
                Energy.BeginForcedRest(worker, currentHour, lowEnergyReason, "Too tired to keep fighting. Resting at home.")
            end
            forcedRest = Energy.IsForcedRest(worker)

            if forcedRest then
                worker.jobEnabled = false
                if Config.ReleaseWorkerCompanionControl then
                    Config.ReleaseWorkerCompanionControl(worker, lowEnergyReason, "I need to rest. Heading home.", "warning")
                end
                if Config.UpdateWorkerCompanionReturnState then
                    Config.UpdateWorkerCompanionReturnState(worker)
                end
                if worker.companionReturnPending == true then
                    return
                end
                worker.state = Config.States.Resting
                return
            end
        end

        worker.state = Config.States.Working
        return
    end

    if reason == "OwnerOffline" then
        worker.state = Config.States.Idle
        return
    end

    if reason == "SpawnFailed" then
        worker.state = Config.States.Idle
        return
    end

    invalidateFollowJob(
        worker,
        currentHour,
        reason == "MissingCompanionUUID" and "Follow Player stopped because the worker is no longer linked to a recruited V2 NPC."
            or "Follow Player stopped because the recruited V2 companion could not be controlled."
    )
end

return Sim
