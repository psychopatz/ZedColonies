DC_Colony = DC_Colony or {}
DC_Colony.Interaction = DC_Colony.Interaction or {}

local Config = DC_Colony.Config
local Interaction = DC_Colony.Interaction
local Energy = DC_Colony.Energy
local Skills = DC_Colony.Skills

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
    local presenceState = tostring(worker.presenceState or "")
    local states = Config.PresenceStates or {}
    local tokens = nil

    if jobKey == tostring((Config.JobTypes or {}).Scavenge or "Scavenge") then
        local travelTemplate = nil
        if presenceState == tostring(states.AwayToSite or "AwayToSite") then
            travelTemplate = Interaction.getInteractionEntry("Progress", "Common.TravelToSite")
        elseif presenceState == tostring(states.AwayToHome or "AwayToHome") then
            travelTemplate = Interaction.getInteractionEntry("Progress", "Common.TravelToHome")
        end

        if type(travelTemplate) == "table" then
            local totalHours = Interaction.getTravelTotalHours()
            local remainingWorldHours = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
            local progressHours = math.max(0, totalHours - remainingWorldHours)
            tokens = Interaction.buildProgressTokens(worker, progressHours, totalHours, remainingWorldHours)
            return {
                label = DynamicTrading.FormatInteractionString(travelTemplate.activeText, tokens),
                displayText = DynamicTrading.FormatInteractionString(travelTemplate.activeText, tokens),
                fillRatio = math.max(0, math.min(1, progressHours / totalHours)),
                captionText = DynamicTrading.FormatInteractionString(travelTemplate.captionText, tokens),
                summaryText = Interaction.formatDecimal(progressHours, 1) .. " / " .. Interaction.formatDecimal(totalHours, 1) .. "h",
                progressHours = progressHours,
                cycleHours = totalHours,
                remainingWorldHours = remainingWorldHours,
                color = travelTemplate.color
            }
        end
    end

    local workingState = tostring((Config.States or {}).Working or "Working")
    if tostring(worker.state or "") ~= workingState or worker.jobEnabled ~= true then
        return nil
    end

    local template = Interaction.getInteractionEntry("Progress", jobKey .. ".Active")
    if type(template) ~= "table" then
        return nil
    end

    if jobKey == tostring((Config.JobTypes or {}).Scavenge or "Scavenge") then
        local workTarget = math.max(
            1,
            tonumber(worker.workTarget)
                or tonumber(Config.GetEffectiveWorkTarget and Config.GetEffectiveWorkTarget(worker, profile))
                or tonumber(Config.GetEffectiveCycleHours and Config.GetEffectiveCycleHours(worker, profile))
                or tonumber(profile and profile.cycleHours)
                or 1
        )
        local progressAmount = math.max(0, tonumber(worker.workProgress) or 0)
        if progressAmount > workTarget then
            progressAmount = progressAmount % workTarget
        end

        local baseSpeed = math.max(
            0.01,
            tonumber(worker.baseWorkSpeedMultiplier)
                or tonumber(Config.GetBaseWorkSpeedMultiplier and Config.GetBaseWorkSpeedMultiplier(worker, profile))
                or 1
        )
        local skillEffects = Skills and Skills.GetWorkerJobEffects and Skills.GetWorkerJobEffects(worker, profile) or nil
        local skillSpeed = math.max(0.01, tonumber(skillEffects and skillEffects.speedMultiplier or worker.jobSkillSpeedMultiplier or 1) or 1)
        local equipmentSpeed = math.max(0.01, tonumber(worker.scavengeSearchSpeedMultiplier) or 1)
        local effectiveSpeed = baseSpeed * skillSpeed * equipmentSpeed
        local baseWorkPerHour = math.max(
            0.01,
            tonumber(Config.GetScavengeBaseWorkPerHour and Config.GetScavengeBaseWorkPerHour())
                or 1
        )
        local effectiveWorkPerHour = baseWorkPerHour * effectiveSpeed
        local remainingWorkAmount = math.max(0, workTarget - progressAmount)
        local remainingWorldHours = effectiveWorkPerHour > 0 and (remainingWorkAmount / effectiveWorkPerHour) or nil

        return {
            label = DynamicTrading.FormatInteractionString(template.activeText, {
                place = Interaction.GetPlaceLabel(worker),
                count = tostring(math.max(0, tonumber(worker and worker.outputCount) or 0)),
                eta = Interaction.formatDurationHours(remainingWorldHours),
                progress = Interaction.formatWholeAmount(progressAmount),
                total = Interaction.formatWholeAmount(workTarget)
            }),
            displayText = DynamicTrading.FormatInteractionString(template.activeText, {
                place = Interaction.GetPlaceLabel(worker),
                count = tostring(math.max(0, tonumber(worker and worker.outputCount) or 0)),
                eta = Interaction.formatDurationHours(remainingWorldHours),
                progress = Interaction.formatWholeAmount(progressAmount),
                total = Interaction.formatWholeAmount(workTarget)
            }),
            fillRatio = math.max(0, math.min(1, progressAmount / workTarget)),
            captionText = DynamicTrading.FormatInteractionString(template.captionText, {
                place = Interaction.GetPlaceLabel(worker),
                count = tostring(math.max(0, tonumber(worker and worker.outputCount) or 0)),
                eta = Interaction.formatDurationHours(remainingWorldHours),
                progress = Interaction.formatWholeAmount(progressAmount),
                total = Interaction.formatWholeAmount(workTarget)
            }),
            summaryText = Interaction.formatWholeAmount(progressAmount)
                .. " / "
                .. Interaction.formatWholeAmount(workTarget)
                .. " work | Speed x"
                .. Interaction.formatDecimal(effectiveSpeed, 2),
            progressAmount = progressAmount,
            workTarget = workTarget,
            progressHours = progressAmount,
            cycleHours = workTarget,
            remainingWorldHours = remainingWorldHours,
            baseSpeedMultiplier = baseSpeed,
            skillSpeedMultiplier = skillSpeed,
            equipmentSpeedMultiplier = equipmentSpeed,
            effectiveSpeedMultiplier = effectiveSpeed,
            effectiveWorkPerHour = effectiveWorkPerHour,
            color = template.color
        }
    end

    if jobKey == tostring((Config.JobTypes or {}).Builder or "Builder") then
        local workTarget = math.max(
            1,
            tonumber(worker.assignedProjectRequired)
                or tonumber(worker.workTarget)
                or tonumber(worker.workCycleHours)
                or 1
        )
        local progressAmount = math.max(
            0,
            tonumber(worker.assignedProjectProgress)
                or tonumber(worker.workProgress)
                or 0
        )
        if progressAmount > workTarget then
            progressAmount = workTarget
        end

        local baseSpeed = math.max(
            0.01,
            tonumber(worker.baseWorkSpeedMultiplier)
                or tonumber(Config.GetBaseWorkSpeedMultiplier and Config.GetBaseWorkSpeedMultiplier(worker, profile))
                or 1
        )
        local skillEffects = Skills and Skills.GetWorkerJobEffects and Skills.GetWorkerJobEffects(worker, profile) or nil
        local skillSpeed = math.max(0.01, tonumber(skillEffects and skillEffects.speedMultiplier or worker.jobSkillSpeedMultiplier or 1) or 1)
        local effectiveSpeed = baseSpeed * skillSpeed
        local baseWorkPerHour = math.max(
            0.01,
            tonumber(DC_Buildings and DC_Buildings.Config and DC_Buildings.Config.GetBuilderBaseWorkPointsPerHour
                and DC_Buildings.Config.GetBuilderBaseWorkPointsPerHour())
                or 1
        )
        local effectiveWorkPerHour = baseWorkPerHour * effectiveSpeed
        local remainingWorkAmount = math.max(0, workTarget - progressAmount)
        local remainingWorldHours = effectiveWorkPerHour > 0 and (remainingWorkAmount / effectiveWorkPerHour) or nil
        local tokens = Interaction.buildProgressTokens(worker, progressAmount, workTarget, remainingWorldHours)
        tokens.progress = Interaction.formatWholeAmount(progressAmount)
        tokens.total = Interaction.formatWholeAmount(workTarget)

        return {
            label = DynamicTrading.FormatInteractionString(template.activeText, tokens),
            displayText = DynamicTrading.FormatInteractionString(template.activeText, tokens),
            fillRatio = math.max(0, math.min(1, progressAmount / workTarget)),
            captionText = DynamicTrading.FormatInteractionString(template.captionText, tokens),
            summaryText = Interaction.formatWholeAmount(progressAmount)
                .. " / "
                .. Interaction.formatWholeAmount(workTarget)
                .. " WP | Speed x"
                .. Interaction.formatDecimal(effectiveSpeed, 2),
            progressAmount = progressAmount,
            workTarget = workTarget,
            progressHours = progressAmount,
            cycleHours = workTarget,
            remainingWorldHours = remainingWorldHours,
            baseSpeedMultiplier = baseSpeed,
            skillSpeedMultiplier = skillSpeed,
            equipmentSpeedMultiplier = 1,
            effectiveSpeedMultiplier = effectiveSpeed,
            effectiveWorkPerHour = effectiveWorkPerHour,
            color = template.color
        }
    end

    local cycleHours = math.max(
        0.01,
        tonumber(worker.workCycleHours)
            or tonumber(Config.GetEffectiveCycleHours and Config.GetEffectiveCycleHours(worker, profile))
            or tonumber(profile and profile.cycleHours)
            or 24
    )
    local progressHours = math.max(0, tonumber(worker.workProgress) or 0)
    if progressHours > cycleHours then
        progressHours = progressHours % cycleHours
    end

    local baseSpeed = math.max(
        0.01,
        tonumber(worker.baseWorkSpeedMultiplier)
            or tonumber(Config.GetBaseWorkSpeedMultiplier and Config.GetBaseWorkSpeedMultiplier(worker, profile))
            or 1
    )
    local skillEffects = Skills and Skills.GetWorkerJobEffects and Skills.GetWorkerJobEffects(worker, profile) or nil
    local skillSpeed = math.max(0.01, tonumber(skillEffects and skillEffects.speedMultiplier or worker.jobSkillSpeedMultiplier or 1) or 1)
    local equipmentSpeed = math.max(0.01, tonumber(worker.scavengeSearchSpeedMultiplier) or 1)
    if jobKey ~= tostring((Config.JobTypes or {}).Scavenge or "Scavenge") then
        equipmentSpeed = 1
    end

    local effectiveSpeed = baseSpeed * skillSpeed * equipmentSpeed
    local remainingProgressHours = math.max(0, cycleHours - progressHours)
    local remainingWorldHours = effectiveSpeed > 0 and (remainingProgressHours / effectiveSpeed) or nil

    tokens = Interaction.buildProgressTokens(worker, progressHours, cycleHours, remainingWorldHours)

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
        equipmentSpeedMultiplier = equipmentSpeed,
        effectiveSpeedMultiplier = effectiveSpeed,
        color = template.color
    }
end

return DC_Colony.Interaction
