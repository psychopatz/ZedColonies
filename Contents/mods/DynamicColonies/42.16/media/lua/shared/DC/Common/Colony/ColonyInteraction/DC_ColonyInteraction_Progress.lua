DC_Colony = DC_Colony or {}
DC_Colony.Interaction = DC_Colony.Interaction or {}

local Config = DC_Colony.Config
local Interaction = DC_Colony.Interaction
local Energy = DC_Colony.Energy

function Interaction.GetProgressDescriptor(worker, profile)
    if not worker then
        return nil
    end

    local energySystem = DC_Colony and DC_Colony.Energy or Energy
    local restingState = tostring((Config.States or {}).Resting or "Resting")
    if tostring(worker.state or "") == restingState and energySystem and energySystem.GetRestingProgressDescriptor then
        local descriptor = energySystem.GetRestingProgressDescriptor(worker)
        if descriptor then
            local template = Interaction.getInteractionEntry("Progress", "Common.Resting")
            if type(template) == "table" then
                descriptor.label = tostring(template.activeText or descriptor.label or "Resting")
                descriptor.displayText = tostring(template.activeText or descriptor.displayText or "Resting")
                descriptor.color = template.color or descriptor.color
            end
            return descriptor
        end
    end

    local jobKey = Interaction.getJobKey(worker)

    if jobKey == tostring((Config.JobTypes or {}).TravelCompanion or "TravelCompanion") then
        local presenceState = tostring(worker.presenceState or "")
        local states = Config.PresenceStates or {}
        local activeText = nil
        local captionText = nil
        if presenceState == tostring(states.CompanionToPlayer or "CompanionToPlayer") then
            activeText = "Heading to your location"
            captionText = "Reaches you in {eta}"
        elseif presenceState == tostring(states.CompanionReturning or "CompanionReturning") then
            activeText = "Heading back home"
            captionText = "Home in {eta}"
        end
        if activeText then
            local totalHours = Interaction.getTravelTotalHours()
            local remainingWorldHours = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
            local progressHours = math.max(0, totalHours - remainingWorldHours)
            local tokens = Interaction.buildProgressTokens(worker, progressHours, totalHours, remainingWorldHours)
            return {
                label = DynamicTrading.FormatInteractionString(activeText, tokens),
                displayText = DynamicTrading.FormatInteractionString(activeText, tokens),
                fillRatio = math.max(0, math.min(1, progressHours / totalHours)),
                captionText = DynamicTrading.FormatInteractionString(captionText, tokens),
                summaryText = Interaction.formatDecimal(progressHours, 1) .. " / " .. Interaction.formatDecimal(totalHours, 1) .. "h",
                progressHours = progressHours,
                cycleHours = totalHours,
                remainingWorldHours = remainingWorldHours,
                color = { r = 0.52, g = 0.78, b = 0.96, a = 1 }
            }
        end
    end

    local activeProfile = profile or (DC_Colony.Config and DC_Colony.Config.JobProfiles and DC_Colony.Config.JobProfiles[jobKey])
    if activeProfile and activeProfile.hooks and type(activeProfile.hooks.getProgressDescriptor) == "function" then
        return activeProfile.hooks.getProgressDescriptor(worker, activeProfile)
    end

    local workingState = tostring((Config.States or {}).Working or "Working")
    if tostring(worker.state or "") ~= workingState or worker.jobEnabled ~= true then
        return nil
    end

    local template = Interaction.getInteractionEntry("Progress", jobKey .. ".Active")
    if type(template) ~= "table" then
        return nil
    end

    local Skills = DC_Colony.Skills
    local cycleHours = math.max(
        0.01,
        tonumber(worker.workCycleHours)
            or tonumber(Config.GetEffectiveCycleHours and Config.GetEffectiveCycleHours(worker, activeProfile))
            or tonumber(activeProfile and activeProfile.cycleHours)
            or 24
    )
    local progressHours = math.max(0, tonumber(worker.workProgress) or 0)
    if progressHours > cycleHours then
        progressHours = progressHours % cycleHours
    end

    local baseSpeed = math.max(
        0.01,
        tonumber(worker.baseWorkSpeedMultiplier)
            or tonumber(Config.GetBaseWorkSpeedMultiplier and Config.GetBaseWorkSpeedMultiplier(worker, activeProfile))
            or 1
    )
    local skillEffects = Skills and Skills.GetWorkerJobEffects and Skills.GetWorkerJobEffects(worker, activeProfile) or nil
    local skillSpeed = math.max(0.01, tonumber(skillEffects and skillEffects.speedMultiplier or worker.jobSkillSpeedMultiplier or 1) or 1)
    local effectiveSpeed = baseSpeed * skillSpeed
    local remainingProgressHours = math.max(0, cycleHours - progressHours)
    local remainingWorldHours = effectiveSpeed > 0 and (remainingProgressHours / effectiveSpeed) or nil
    local tokens = Interaction.buildProgressTokens(worker, progressHours, cycleHours, remainingWorldHours)

    return {
        label = DynamicTrading.FormatInteractionString(template.activeText, tokens),
        displayText = DynamicTrading.FormatInteractionString(template.activeText, tokens),
        fillRatio = math.max(0, math.min(1, progressHours / cycleHours)),
        captionText = DynamicTrading.FormatInteractionString(template.captionText, tokens),
        summaryText = Interaction.formatDecimal(progressHours, 1)
            .. " / "
            .. Interaction.formatDecimal(cycleHours, 1)
            .. "h | Speed x"
            .. Interaction.formatDecimal(effectiveSpeed, 2),
        progressHours = progressHours,
        cycleHours = cycleHours,
        remainingWorldHours = remainingWorldHours,
        baseSpeedMultiplier = baseSpeed,
        skillSpeedMultiplier = skillSpeed,
        equipmentSpeedMultiplier = 1,
        effectiveSpeedMultiplier = effectiveSpeed,
        color = template.color
    }
end

return DC_Colony.Interaction
