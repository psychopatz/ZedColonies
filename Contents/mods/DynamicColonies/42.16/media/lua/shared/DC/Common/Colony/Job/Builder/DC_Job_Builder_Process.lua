local Config = DC_Colony.Config
local Sim = DC_Colony.Sim
local Internal = Sim.Internal
local Energy = DC_Colony.Energy

function Sim.ProcessBuilderJob(worker, ctx)
    local currentHour = ctx.currentHour
    local profile = ctx.profile
    local normalizedJobType = ctx.normalizedJobType
    local speedMultiplier = ctx.speedMultiplier
    local toolsReady = ctx.toolsReady
    local hp = ctx.hp
    local hasCalories = ctx.hasCalories
    local hasHydration = ctx.hasHydration
    local forcedRest = ctx.forcedRest
    local workableHours = ctx.workableHours
    local deltaHours = ctx.deltaHours
    local lowEnergyReason = ctx.lowEnergyReason

    worker.scavengeBonusRareRolls = nil
    worker.scavengeRareFinds = nil
    worker.scavengeBotchedRolls = nil
    worker.scavengeQualityCounts = nil

    local projectState = DC_Buildings and DC_Buildings.GetProjectDisplayState and DC_Buildings.GetProjectDisplayState(worker.ownerUsername, worker.workerID) or {
        hasProject = false,
        label = "No Project"
    }
    if projectState.hasProject and DC_Buildings and DC_Buildings.RefreshOwnerProjectMaterials then
        DC_Buildings.RefreshOwnerProjectMaterials(worker.ownerUsername)
        projectState = DC_Buildings.GetProjectDisplayState(worker.ownerUsername, worker.workerID) or projectState
    end
    local didWorkThisTick = false
    local buildResult = nil
    local waitingForProjectMaterials = false
    local autoAssignedProject = nil

    if hp > 0 and worker.jobEnabled and toolsReady and hasHydration and hasCalories and not forcedRest and not projectState.hasProject then
        autoAssignedProject = DC_Buildings
            and DC_Buildings.AssignNextReadyProjectToWorker
            and DC_Buildings.AssignNextReadyProjectToWorker(worker)
            or nil
        if autoAssignedProject then
            Internal.appendWorkerLog(
                worker,
                "Automatically moved to "
                    .. tostring(autoAssignedProject.buildingType or "Project")
                    .. " L"
                    .. tostring(autoAssignedProject.targetLevel or 1)
                    .. ".",
                currentHour,
                "buildings"
            )
            projectState = DC_Buildings.GetProjectDisplayState(worker.ownerUsername, worker.workerID) or {
                hasProject = true,
                label = tostring(autoAssignedProject.buildingType or "Project")
            }
        end
    end

    if hp <= 0 then
        Internal.markWorkerDead(worker, currentHour, normalizedJobType, Config.PresenceStates.Home, hasCalories, hasHydration)
    elseif worker.jobEnabled and toolsReady and hasHydration and hasCalories and not forcedRest and projectState.hasProject then
        worker.state = Config.States.Working
        buildResult = DC_Buildings
            and DC_Buildings.ProcessWorkerProject
            and DC_Buildings.ProcessWorkerProject(worker, currentHour, workableHours, speedMultiplier)
            or nil
        didWorkThisTick = buildResult and buildResult.didWork == true or false
        if didWorkThisTick then
            Sim.ApplyWearForRequiredTools(worker, profile, currentHour, 1)
        end
        waitingForProjectMaterials = buildResult and buildResult.waitingForMaterials == true or false
        if buildResult and buildResult.completed and buildResult.project then
            if buildResult.xpResult and (tonumber(buildResult.xpResult.granted) or 0) > 0 then
                Sim.grantWorkerJobXP(worker, currentHour, {
                    skillID = "Construction",
                    skillLabel = "Construction",
                    granted = buildResult.xpResult.granted,
                    leveledUp = buildResult.xpResult.leveledUp,
                    newLevel = buildResult.xpResult.newLevel
                }, 0)
            end
            Internal.appendWorkerLog(
                worker,
                tostring(buildResult.project.buildingType or "Building")
                    .. " reached level "
                    .. tostring(buildResult.project.targetLevel or 1)
                    .. ".",
                currentHour,
                "buildings"
            )
            projectState = DC_Buildings.GetProjectDisplayState(worker.ownerUsername, worker.workerID) or {
                hasProject = false,
                label = "No Project"
            }
            if buildResult.nextProject then
                Internal.appendWorkerLog(
                    worker,
                    "Automatically moved to "
                        .. tostring(buildResult.nextProject.buildingType or "Project")
                        .. " L"
                        .. tostring(buildResult.nextProject.targetLevel or 1)
                        .. ".",
                    currentHour,
                    "buildings"
                )
            end

            local networkInternal = DC_Colony and DC_Colony.Network and DC_Colony.Network.Internal or nil
            if networkInternal and networkInternal.pushOwnerBuildingMutation then
                local additionalPlots = nil
                if buildResult.nextProject and buildResult.nextProject.plotX ~= nil and buildResult.nextProject.plotY ~= nil then
                    additionalPlots = {
                        {
                            x = buildResult.nextProject.plotX,
                            y = buildResult.nextProject.plotY,
                        }
                    }
                end
                networkInternal.pushOwnerBuildingMutation(worker.ownerUsername, {
                    workerID = worker.workerID,
                    plotX = buildResult.project.plotX,
                    plotY = buildResult.project.plotY,
                    additionalPlots = additionalPlots,
                    transition = buildResult.transition,
                    promptBuildingName = buildResult.transition
                        and buildResult.transition.realBase
                        and buildResult.transition.realBase.shouldPromptName == true
                        and {
                            buildingID = buildResult.instance and buildResult.instance.buildingID or buildResult.project.buildingID,
                            buildingType = buildResult.instance and buildResult.instance.buildingType or buildResult.project.buildingType,
                            defaultValue = buildResult.transition.realBase.defaultName,
                        } or nil,
                    promptOwnedFactionRename = buildResult.transition
                        and buildResult.transition.realBase
                        and buildResult.transition.realBase.promptOwnedFactionRename
                        or nil,
                    sendFactionStatus = buildResult.transition
                        and buildResult.transition.realBase
                        and buildResult.transition.realBase.sendFactionStatus == true
                        or false,
                    notice = {
                        message = tostring(buildResult.project.buildingType or "Building")
                            .. " reached level "
                            .. tostring(buildResult.project.targetLevel or 1)
                            .. ".",
                        severity = "info",
                        popup = false,
                    }
                })
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
            Energy.BeginForcedRest(worker, currentHour, lowEnergyReason, "Too tired to keep building. Resting at home.")
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
    elseif waitingForProjectMaterials then
        worker.state = Config.States.WarehouseShortage
    elseif projectState.hasProject then
        worker.state = Config.States.Working
    else
        worker.state = Config.States.Idle
    end
end

if DC_Colony.Config.JobProfiles and DC_Colony.Config.JobProfiles.Builder then
    DC_Colony.Config.JobProfiles.Builder.processHandler = Sim.ProcessBuilderJob
    DC_Colony.Config.JobProfiles.Builder.hooks.getCycleHours = function(worker, defaultCycleHours)
        local buildings = DC_Buildings or nil
        if buildings and buildings.GetProjectForWorker then
            local project = buildings.GetProjectForWorker(worker)
            if project then
                return math.max(1, tonumber(project.requiredWorkPoints) or defaultCycleHours)
            end
        end
        return defaultCycleHours
    end
    DC_Colony.Config.JobProfiles.Builder.hooks.getProgressDescriptor = function(worker, profile)
        local Cfg = DC_Colony.Config
        local Inter = DC_Colony.Interaction
        local Skills = DC_Colony.Skills

        local workingState = tostring((Cfg.States or {}).Working or "Working")
        if tostring(worker.state or "") ~= workingState or worker.jobEnabled ~= true then
            return nil
        end

        local template = Inter.getInteractionEntry("Progress", "Builder.Active")
        if type(template) ~= "table" then return nil end

        local workTarget = math.max(1,
            tonumber(worker.assignedProjectRequired)
                or tonumber(worker.workTarget)
                or tonumber(worker.workCycleHours) or 1
        )
        local progressAmount = math.max(0,
            tonumber(worker.assignedProjectProgress)
                or tonumber(worker.workProgress) or 0
        )
        if progressAmount > workTarget then progressAmount = workTarget end

        local baseSpeed = math.max(0.01,
            tonumber(worker.baseWorkSpeedMultiplier)
                or tonumber(Cfg.GetBaseWorkSpeedMultiplier and Cfg.GetBaseWorkSpeedMultiplier(worker, profile))
                or 1
        )
        local skillEffects = Skills and Skills.GetWorkerJobEffects and Skills.GetWorkerJobEffects(worker, profile) or nil
        local skillSpeed = math.max(0.01, tonumber(skillEffects and skillEffects.speedMultiplier or worker.jobSkillSpeedMultiplier or 1) or 1)
        local effectiveSpeed = baseSpeed * skillSpeed
        local baseWorkPerHour = math.max(0.01,
            tonumber(DC_Buildings and DC_Buildings.Config and DC_Buildings.Config.GetBuilderBaseWorkPointsPerHour
                and DC_Buildings.Config.GetBuilderBaseWorkPointsPerHour()) or 1
        )
        local effectiveWorkPerHour = baseWorkPerHour * effectiveSpeed
        local remainingWorkAmount = math.max(0, workTarget - progressAmount)
        local remainingWorldHours = effectiveWorkPerHour > 0 and (remainingWorkAmount / effectiveWorkPerHour) or nil
        local tokens = Inter.buildProgressTokens(worker, progressAmount, workTarget, remainingWorldHours)
        tokens.progress = Inter.formatWholeAmount(progressAmount)
        tokens.total = Inter.formatWholeAmount(workTarget)
        return {
            label = DynamicTrading.FormatInteractionString(template.activeText, tokens),
            displayText = DynamicTrading.FormatInteractionString(template.activeText, tokens),
            fillRatio = math.max(0, math.min(1, progressAmount / workTarget)),
            captionText = DynamicTrading.FormatInteractionString(template.captionText, tokens),
            summaryText = Inter.formatWholeAmount(progressAmount)
                .. " / " .. Inter.formatWholeAmount(workTarget)
                .. " WP | Speed x" .. Inter.formatDecimal(effectiveSpeed, 2),
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
end
