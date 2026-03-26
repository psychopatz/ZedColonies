local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Interaction = DC_Colony.Interaction
local Warehouse = DC_Colony.Warehouse
local Output = DC_Colony.Output
local Sim = DC_Colony.Sim
local Internal = Sim.Internal
local Energy = DC_Colony.Energy

function Sim.ProcessGenericJob(worker, ctx)
    local currentHour = ctx.currentHour
    local profile = ctx.profile
    local normalizedJobType = ctx.normalizedJobType
    local speedMultiplier = ctx.speedMultiplier
    local cycleHours = ctx.cycleHours
    local toolsReady = ctx.toolsReady
    local hp = ctx.hp
    local hasCalories = ctx.hasCalories
    local hasHydration = ctx.hasHydration
    local forcedRest = ctx.forcedRest
    local workableHours = ctx.workableHours
    local deltaHours = ctx.deltaHours
    local lowEnergyReason = ctx.lowEnergyReason
    local jobSkillEffects = ctx.jobSkillEffects

    worker.scavengeBonusRareRolls = nil
    worker.scavengeRareFinds = nil
    worker.scavengeBotchedRolls = nil
    worker.scavengeQualityCounts = nil
    local didWorkThisTick = false

    if hp <= 0 then
        Internal.markWorkerDead(worker, currentHour, normalizedJobType, Config.PresenceStates.Home, hasCalories, hasHydration)
    elseif worker.jobEnabled and toolsReady and hasHydration and hasCalories and not forcedRest then
        worker.state = Config.States.Working
        worker.workProgress = Internal.clampHours(worker.workProgress) + (workableHours * speedMultiplier)
        didWorkThisTick = workableHours > 0
        while worker.workProgress >= cycleHours do
            worker.workProgress = worker.workProgress - cycleHours
            local jobResult = Output.GenerateForJob(profile, worker)
            Sim.ApplyWearForRequiredTools(worker, profile, currentHour, 1)
            local warehouseBlocked = 0
            for _, entry in ipairs(jobResult.entries or {}) do
                local movedQty, leftoverQty = Warehouse.DepositHaulEntry(worker.ownerUsername, entry)
                warehouseBlocked = warehouseBlocked + leftoverQty
                if leftoverQty > 0 then
                    Registry.AddOutputEntry(worker, {
                        fullType = entry.fullType,
                        qty = leftoverQty
                    })
                end
            end
            Internal.logJobCycleOutcome(worker, currentHour, jobResult.totalQuantity, Interaction.GetPlaceLabel(worker), jobResult.entries)
            if jobResult.success then
                Sim.grantWorkerJobXP(worker, currentHour, jobResult.skillEffects or jobSkillEffects, jobResult.totalQuantity)
            elseif jobResult.failed and jobResult.failureReason then
                Internal.appendWorkerLog(worker, tostring(jobResult.failureReason), currentHour, "output")
            end
            if warehouseBlocked > 0 then
                Internal.appendWorkerLog(
                    worker,
                    "Warehouse is full. " .. tostring(warehouseBlocked) .. " produced item" .. (warehouseBlocked == 1 and "" or "s") .. " could not be stored.",
                    currentHour,
                    "warehouse"
                )
                worker.state = Config.States.StorageFull
                break
            end
        end
    end

    if Energy and deltaHours > 0 and hp > 0 then
        if didWorkThisTick and workableHours > 0 then
            Energy.ApplyWorkDrain(worker, workableHours, profile)
        else
            Energy.ApplyHomeRecovery(worker, deltaHours, profile)
        end

        forcedRest = Energy.IsForcedRest(worker)
        if forcedRest then
            Energy.CompleteForcedRest(worker, currentHour, "Fully rested again.")
        elseif Energy.IsDepleted(worker) then
            forcedRest = true
            Energy.BeginForcedRest(worker, currentHour, lowEnergyReason, "Too tired to keep working. Resting at home.")
        end
        forcedRest = Energy.IsForcedRest(worker)
    end

    if hp <= 0 then
        Internal.markWorkerDead(worker, currentHour, normalizedJobType, Config.PresenceStates.Home, hasCalories, hasHydration)
    elseif not worker.jobEnabled then
        worker.state = Config.States.Idle
    elseif not toolsReady then
        worker.state = Config.States.MissingTool
    elseif not hasHydration then
        worker.state = Config.States.Dehydrated
    elseif not hasCalories then
        worker.state = Config.States.Starving
    elseif forcedRest then
        worker.state = Config.States.Resting
    elseif worker.state ~= Config.States.StorageFull then
        worker.state = Config.States.Working
    end
end
