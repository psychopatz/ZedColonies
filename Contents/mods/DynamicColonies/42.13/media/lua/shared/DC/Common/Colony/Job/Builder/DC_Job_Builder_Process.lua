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
            local xpResult = buildResult.xpResult or nil
            local xpText = ""
            if xpResult and (tonumber(xpResult.granted) or 0) > 0 then
                xpText = " Earned "
                    .. tostring(math.floor((tonumber(xpResult.granted) or 0) + 0.5))
                    .. " Construction XP."
                if (tonumber(xpResult.leveledUp) or 0) > 0 then
                    xpText = xpText
                        .. " Construction increased to level "
                        .. tostring(xpResult.newLevel or 0)
                        .. "."
                end
            end
            Internal.appendWorkerLog(
                worker,
                tostring(buildResult.project.buildingType or "Building")
                    .. " reached level "
                    .. tostring(buildResult.project.targetLevel or 1)
                    .. "."
                    .. xpText,
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
