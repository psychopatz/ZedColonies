local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Output = DC_Colony.Output
local Sim = DC_Colony.Sim
local Internal = Sim.Internal
local Energy = DC_Colony.Energy
local Resources = DC_Colony.Resources
local Gatherer = DC_Colony.Gatherer

local function randomRange(minValue, maxValue)
    if Config.RandomRangeInclusive then
        return Config.RandomRangeInclusive(minValue, maxValue)
    end

    local minNumber = math.floor(tonumber(minValue) or 1)
    local maxNumber = math.floor(tonumber(maxValue) or minNumber)
    if maxNumber < minNumber then
        minNumber, maxNumber = maxNumber, minNumber
    end
    return minNumber + ZombRand((maxNumber - minNumber) + 1)
end

local function chooseFullType(rule)
    local fullTypes = rule and rule.fullTypes or nil
    if type(fullTypes) == "table" and #fullTypes > 0 then
        return tostring(fullTypes[ZombRand(#fullTypes) + 1])
    end
    if rule and rule.fullType then
        return tostring(rule.fullType)
    end
    return nil
end

local function scaledQuantity(rule, selectedCount, skillEffects)
    local qty = randomRange(rule and rule.minQty or 1, rule and rule.maxQty or 1)
    if Output and Output.applyQuantityMultiplier then
        qty = Output.applyQuantityMultiplier(qty, skillEffects and skillEffects.yieldMultiplier or 1)
    end

    selectedCount = math.max(1, tonumber(selectedCount) or 1)
    if selectedCount <= 1 then
        return math.max(1, qty)
    end

    local scaled = qty / selectedCount
    local guaranteed = math.floor(scaled)
    local remainder = scaled - guaranteed
    if remainder > 0 and Output and Output.rollChance and Output.rollChance(remainder) then
        guaranteed = guaranteed + 1
    end
    return math.max(0, guaranteed)
end

local function addWaterStorage(ownerUsername, def, qty)
    local perQty = math.max(0, tonumber(def and def.waterPerQty) or 0)
    if perQty <= 0 or not Resources or not Resources.EnsureOwner then
        return 0
    end

    local ownerOk, ownerData = pcall(Resources.EnsureOwner, ownerUsername)
    if not ownerOk or type(ownerData) ~= "table" then
        return 0
    end

    local capacity = 0
    if Resources.GetWaterCapacity then
        local capacityOk, capacityResult = pcall(Resources.GetWaterCapacity, ownerUsername)
        if capacityOk then
            capacity = tonumber(capacityResult) or 0
        end
    end

    local current = math.max(0, tonumber(ownerData and ownerData.waterStored) or 0)
    local amount = perQty * math.max(0, tonumber(qty) or 0)
    local accepted = math.max(0, math.min(amount, math.max(0, capacity - current)))
    if accepted <= 0 then
        return 0
    end

    ownerData.waterStored = current + accepted
    if Resources.Save then
        pcall(Resources.Save, ownerUsername)
    end
    return accepted
end

local function mirrorDynamicTradingStockpile(ownerUsername, def, qty)
    local resource = def and def.stockpileResource
    local perQty = math.max(0, tonumber(def and def.stockpilePerQty) or 0)
    if not resource or perQty <= 0 or qty <= 0 then
        return false
    end

    local factions = rawget(_G, "DynamicTrading_Factions")
    if not factions or not factions.GetPlayerFaction or not factions.ModifyStockpile then
        return false
    end

    local ok, faction = pcall(factions.GetPlayerFaction, ownerUsername)
    if not ok or type(faction) ~= "table" or not faction.id then
        return false
    end

    local modifyOk, modified = pcall(factions.ModifyStockpile, faction.id, resource, perQty * qty)
    return modifyOk and modified == true
end

local function finalizeWorkerState(worker, ctx, didWorkThisTick)
    local currentHour = ctx.currentHour
    local normalizedJobType = ctx.normalizedJobType
    local profile = ctx.profile
    local hp = ctx.hp
    local hasCalories = ctx.hasCalories
    local hasHydration = ctx.hasHydration
    local forcedRest = ctx.forcedRest
    local deltaHours = ctx.deltaHours
    local lowEnergyReason = ctx.lowEnergyReason
    local workableHours = ctx.workableHours

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
            Energy.BeginForcedRest(worker, currentHour, lowEnergyReason, "Too tired to keep gathering. Resting at home.")
        end
        forcedRest = Energy.IsForcedRest(worker)
    end

    if hp <= 0 then
        Internal.markWorkerDead(worker, currentHour, normalizedJobType, Config.PresenceStates.Home, hasCalories, hasHydration)
    elseif not worker.jobEnabled then
        worker.state = Config.States.Idle
    elseif not ctx.toolsReady then
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

local function buildGathererEntries(worker, ctx)
    local entries = {}
    local selected = Gatherer.GetSelectedResourceList(worker)
    local selectedCount = math.max(1, #selected)

    for _, def in ipairs(selected) do
        for _, rule in ipairs(def.outputRules or {}) do
            local fullType = chooseFullType(rule)
            if fullType then
                local qty = scaledQuantity(rule, selectedCount, ctx.jobSkillEffects)
                if qty > 0 then
                    entries[#entries + 1] = {
                        fullType = fullType,
                        qty = qty,
                        gathererResourceID = def.id,
                        gathererResourceLabel = def.label
                    }
                end
            end
        end
    end

    return entries
end

function Sim.ProcessGathererJob(worker, ctx)
    local currentHour = ctx.currentHour
    local normalizedJobType = ctx.normalizedJobType
    local speedMultiplier = ctx.speedMultiplier
    local cycleHours = ctx.cycleHours
    local toolsReady = ctx.toolsReady
    local hp = ctx.hp
    local hasCalories = ctx.hasCalories
    local hasHydration = ctx.hasHydration
    local forcedRest = ctx.forcedRest
    local workableHours = ctx.workableHours

    local didWorkThisTick = false
    local totalQuantity = 0

    worker.gathererConfig = Gatherer.NormalizeConfig(worker)
    worker.gathererSelectionLabel = Gatherer.GetSelectionLabel(worker)
    worker.siteState = worker.gathererSelectionLabel

    if hp <= 0 then
        Internal.markWorkerDead(worker, currentHour, normalizedJobType, Config.PresenceStates.Home, hasCalories, hasHydration)
    elseif worker.jobEnabled and toolsReady and hasHydration and hasCalories and not forcedRest then
        worker.state = Config.States.Working
        worker.workProgress = Internal.clampHours(worker.workProgress) + (workableHours * speedMultiplier)
        didWorkThisTick = workableHours > 0

        while worker.workProgress >= cycleHours do
            worker.workProgress = worker.workProgress - cycleHours

            local entries = buildGathererEntries(worker, ctx)
            local warehouseBlocked = 0
            local movedByResource = {}
            local cycleQuantity = 0

            for _, entry in ipairs(entries) do
                local movedQty, leftoverQty = Warehouse.DepositHaulEntry(worker.ownerUsername, entry)
                movedQty = math.max(0, tonumber(movedQty) or 0)
                leftoverQty = math.max(0, tonumber(leftoverQty) or 0)
                warehouseBlocked = warehouseBlocked + leftoverQty
                cycleQuantity = cycleQuantity + movedQty
                totalQuantity = totalQuantity + movedQty

                if movedQty > 0 and entry.gathererResourceID then
                    movedByResource[entry.gathererResourceID] = (movedByResource[entry.gathererResourceID] or 0) + movedQty
                end

                if leftoverQty > 0 then
                    Registry.AddOutputEntry(worker, {
                        fullType = entry.fullType,
                        qty = leftoverQty
                    })
                end
            end

            for resourceID, qty in pairs(movedByResource) do
                local def = Gatherer.GetResource(resourceID)
                addWaterStorage(worker.ownerUsername, def, qty)
                mirrorDynamicTradingStockpile(worker.ownerUsername, def, qty)
            end

            Internal.logJobCycleOutcome(worker, currentHour, cycleQuantity, "nearby resources", entries)
            if cycleQuantity > 0 then
                Sim.grantWorkerJobXP(worker, currentHour, ctx.jobSkillEffects, cycleQuantity)
            end

            if warehouseBlocked > 0 then
                Internal.appendWorkerLog(
                    worker,
                    "Warehouse is full. " .. tostring(warehouseBlocked) .. " gathered item" .. (warehouseBlocked == 1 and "" or "s") .. " could not be stored.",
                    currentHour,
                    "warehouse"
                )
                worker.state = Config.States.StorageFull
                break
            end
        end
    end

    worker.gathererLastQuantity = totalQuantity
    finalizeWorkerState(worker, ctx, didWorkThisTick)
end

return Sim
