DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.IsV2Active()
    local activated = getActivatedMods and getActivatedMods() or nil
    return activated and activated.contains and activated:contains("DynamicTradingV2") or false
end

function Internal.IsTravelCompanionWorker(worker)
    return Config.NormalizeJobType and Config.NormalizeJobType(worker and worker.jobType) == ((Config.JobTypes or {}).TravelCompanion)
end

function Internal.CanWorkerBeCompanion(worker)
    if not Internal.IsV2Active() then
        return false, "Travel Companion needs V2."
    end

    local melee = Internal.GetWorkerSkillLevel(worker, "Melee")
    local shooting = Internal.GetWorkerSkillLevel(worker, "Shooting")
    if melee <= 0 and shooting <= 0 then
        return false, "Travel Companion requires Melee or Shooting skill."
    end

    return true, nil
end

function Internal.CanWorkerStartCompanionNow(worker)
    if not worker then
        return false, "Companion start is unavailable."
    end

    local homeState = tostring((Config.PresenceStates or {}).Home or "Home")
    if tostring(worker.presenceState or "") ~= homeState then
        return false, "Travel Companion can only start when the worker is at home."
    end

    local states = Config.States or {}
    local currentState = tostring(worker.state or "")
    if currentState == tostring(states.Incapacitated or "Incapacitated") then
        return false, "Worker is incapacitated and must recover first."
    end
    if currentState == tostring(states.Dead or "Dead") then
        return false, "Worker is dead and cannot start companion duty."
    end
    if currentState == tostring(states.Starving or "Starving") then
        return false, "Worker is hungry and must eat before companion duty."
    end
    if currentState == tostring(states.Dehydrated or "Dehydrated") then
        return false, "Worker is thirsty and must drink before companion duty."
    end

    local returnReason = tostring(worker.returnReason or "")
    local returnReasons = Config.ReturnReasons or {}
    if returnReason == tostring(returnReasons.LowFood or "LowFood") then
        return false, "Worker is hungry and must eat before companion duty."
    end
    if returnReason == tostring(returnReasons.LowDrink or "LowDrink") then
        return false, "Worker is thirsty and must drink before companion duty."
    end

    local energy = DC_Colony and DC_Colony.Energy or nil
    if energy and ((energy.IsForcedRest and energy.IsForcedRest(worker)) or (energy.IsDepleted and energy.IsDepleted(worker))) then
        return false, "Worker is too tired and must rest before companion duty."
    end

    local nutrition = DC_Colony and DC_Colony.Nutrition or nil
    if nutrition and nutrition.GetOnBodyTotals then
        local calories, hydration = nutrition.GetOnBodyTotals(worker)
        if (tonumber(calories) or 0) <= 0 then
            return false, "Worker is hungry and must eat before companion duty."
        end
        if (tonumber(hydration) or 0) <= 0 then
            return false, "Worker is thirsty and must drink before companion duty."
        end
    end

    return true, nil
end

function Internal.GetWorkerTravelHours(worker)
    return Internal.GetTravelHours()
end

function Internal.GetHealthSeed(worker)
    if type(worker) ~= "table" then
        return nil
    end

    return {
        hp = math.max(0, tonumber(worker.hp) or tonumber(worker.health) or 0),
        maxHp = math.max(1, tonumber(worker.maxHp) or tonumber(worker.healthMax) or tonumber(Config.DEFAULT_WORKER_MAX_HP) or 100),
    }
end