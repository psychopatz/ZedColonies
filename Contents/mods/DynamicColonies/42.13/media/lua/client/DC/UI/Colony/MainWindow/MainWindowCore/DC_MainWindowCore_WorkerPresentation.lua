DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

require "DC/Common/Colony/ColonyInteraction/DC_Colony_Interaction"

local Internal = DC_MainWindow.Internal

function Internal.getWorkerGender(worker)
    return worker and worker.isFemale and "Female" or "Male"
end

function Internal.getWorkerPortraitTexture(worker)
    if not worker then
        return nil
    end

    local archetype = tostring(worker.archetypeID or "General")
    local gender = Internal.getWorkerGender(worker)
    local seed = tonumber(worker.identitySeed) or 1
    local portraitID = 1
    local pathFolder = "media/ui/Portraits/" .. archetype .. "/" .. gender .. "/"

    if DynamicTrading and DynamicTrading.Portraits then
        if DynamicTrading.Portraits.GetMappedID then
            portraitID = DynamicTrading.Portraits.GetMappedID(archetype, gender, seed)
        end
        if DynamicTrading.Portraits.GetPathFolder then
            pathFolder = DynamicTrading.Portraits.GetPathFolder(archetype, gender)
        end
    end

    local tex = getTexture(pathFolder .. tostring(portraitID) .. ".png")
    if tex then
        return tex
    end

    return getTexture("media/ui/Portraits/General/" .. gender .. "/1.png")
end

function Internal.getJobDisplayName(worker, profile)
    local sourceProfile = profile or (Internal.Config.GetJobProfile and Internal.Config.GetJobProfile(worker and worker.jobType)) or {}
    return tostring(sourceProfile.displayName or worker.jobType or worker.profession or "Unknown")
end

function Internal.getJobColor(jobType)
    local config = Internal.Config or {}
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(jobType) or tostring(jobType or "")
    local jobTypes = config.JobTypes or {}

    if normalizedJob == tostring(jobTypes.Builder or "Builder") then
        return { r = 0.48, g = 0.9, b = 0.48, a = 1 }
    end
    if normalizedJob == tostring(jobTypes.Scavenge or "Scavenge") then
        return { r = 0.95, g = 0.78, b = 0.36, a = 1 }
    end
    if normalizedJob == tostring(jobTypes.Farm or "Farm") then
        return { r = 0.62, g = 0.88, b = 0.42, a = 1 }
    end
    if normalizedJob == tostring(jobTypes.Fish or "Fish") then
        return { r = 0.48, g = 0.78, b = 0.98, a = 1 }
    end
    if normalizedJob == tostring(jobTypes.Doctor or "Doctor") then
        return { r = 0.95, g = 0.52, b = 0.52, a = 1 }
    end
    if normalizedJob == tostring(jobTypes.Unemployed or "Unemployed") then
        return { r = 0.7, g = 0.7, b = 0.7, a = 1 }
    end

    return { r = 0.82, g = 0.82, b = 0.82, a = 1 }
end

function Internal.getWorkerJobColor(worker, profile)
    local sourceProfile = profile or (Internal.Config.GetJobProfile and Internal.Config.GetJobProfile(worker and worker.jobType)) or {}
    return Internal.getJobColor(sourceProfile.jobType or worker and worker.jobType)
end

function Internal.getWorkerSkillLevel(worker, skillID)
    local skills = DC_Colony and DC_Colony.Skills or nil
    local entry = skills and skills.GetSkillEntry and skills.GetSkillEntry(worker, skillID) or nil
    return math.max(0, math.floor(tonumber(entry and entry.level) or 0))
end

function Internal.canWorkerTakeJob(worker, jobType)
    local config = Internal.Config or {}
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(jobType) or tostring(jobType or "")
    if normalizedJob == tostring((config.JobTypes or {}).Builder or "Builder") then
        return Internal.getWorkerSkillLevel(worker, "Construction") > 0
    end
    return true
end

function Internal.getNpcConditionLabel(worker)
    local state = tostring(worker and worker.state or "Idle")
    if state == "Resting" then
        return "Resting"
    end
    if state == "Dehydrated" then
        return "Dehydrated"
    end
    if state == "Starving" then
        return "Starving"
    end
    if state == "Dead" then
        return "Dead"
    end
    return "Stable"
end

function Internal.getWorkerPresenceLabel(worker)
    local config = Internal.Config or {}
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")
    local presenceState = tostring(worker and worker.presenceState or (config.PresenceStates and config.PresenceStates.Home) or "Home")
    local states = config.PresenceStates or {}

    if presenceState == states.AwayToHome then
        return "Walking Home"
    end

    if normalizedJob ~= ((config.JobTypes or {}).Scavenge) then
        return tostring(worker and worker.state or "Idle")
    end

    if presenceState == states.Scavenging then
        return "Scavenging"
    end
    if presenceState == states.AwayToSite or presenceState == states.AwayToHome then
        return "Walking"
    end
    return "Home"
end

function Internal.getWorkerStateLabel(worker)
    local interaction = DC_Colony and DC_Colony.Interaction or nil
    if interaction and interaction.GetDisplayStateLabel then
        return tostring(interaction.GetDisplayStateLabel(worker))
    end
    return tostring(worker and worker.state or "Idle")
end

function Internal.formatWorkerListSubtitle(worker)
    local npcCondition = Internal.getNpcConditionLabel(worker)
    local jobType = Internal.getJobDisplayName(worker)
    local presenceLabel = Internal.getWorkerPresenceLabel(worker)
    return npcCondition .. " | " .. jobType .. " | " .. presenceLabel
end

function Internal.buildToolInputText(worker)
    local parts = {}
    for _, entry in ipairs(worker.toolLedger or {}) do
        parts[#parts + 1] = tostring(entry.displayName or entry.fullType or "Unknown Tool")
    end

    if #parts == 0 then
        return "None assigned yet."
    end

    return table.concat(parts, ", ")
end

function Internal.buildSupplyInputText(worker)
    local parts = {}
    for _, entry in ipairs(worker.nutritionLedger or {}) do
        local name = tostring(entry.displayName or entry.fullType or "Supply")
        local calories = Internal.formatReserveValue(entry.caloriesRemaining)
        local hydration = Internal.formatReserveValue(entry.hydrationRemaining)
        parts[#parts + 1] = name .. " [" .. calories .. " cal, " .. hydration .. " hyd]"
    end

    if #parts == 0 then
        return "None stored yet."
    end

    return table.concat(parts, ", ")
end
