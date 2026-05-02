local Config = DC_Colony.Config
local Sim = DC_Colony.Sim
local Internal = Sim.Internal
local Energy = DC_Colony.Energy

local function getOwnerKey(ownerUsername)
    return Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

local function getOwnerMedicalPlan(ownerUsername)
    local plans = Internal.ownerMedicalPlans or {}
    return plans[getOwnerKey(ownerUsername)]
end

function Sim.ProcessDoctorJob(worker, ctx)
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
    local supportedHours = ctx.supportedHours
    local deltaHours = ctx.deltaHours
    local lowEnergyReason = ctx.lowEnergyReason

    worker.scavengeBonusRareRolls = nil
    worker.scavengeRareFinds = nil
    worker.scavengeBotchedRolls = nil
    worker.scavengeQualityCounts = nil

    local medicalPlan = getOwnerMedicalPlan(worker.ownerUsername)
    local coveredPatientCount = medicalPlan and math.max(0, tonumber(medicalPlan.coveredPatientCount) or 0) or 0
    local doctorCount = medicalPlan and math.max(1, tonumber(medicalPlan.doctorCount) or 1) or 1
    local hasTreatmentDemand = coveredPatientCount > 0
    local hasTreatmentSupplies = medicalPlan and (tonumber(medicalPlan.initialTreatmentHours) or 0) > 0 or false
    local doctorLoadRatio = hasTreatmentDemand and math.min(1, coveredPatientCount / math.max(1, doctorCount * 5)) or 0
    local doctorWorkHours = supportedHours * doctorLoadRatio
    local didWorkThisTick = false

    if hp <= 0 then
        Internal.markWorkerDead(worker, currentHour, normalizedJobType, Config.PresenceStates.Home, hasCalories, hasHydration)
    elseif worker.jobEnabled and toolsReady and hasHydration and hasCalories and not forcedRest and hasTreatmentDemand and hasTreatmentSupplies then
        worker.state = Config.States.Working
        worker.workProgress = Internal.clampHours(worker.workProgress) + (doctorWorkHours * speedMultiplier)
        while worker.workProgress >= cycleHours do
            worker.workProgress = worker.workProgress - cycleHours
        end
        didWorkThisTick = doctorWorkHours > 0
    end

    if Energy and deltaHours > 0 and hp > 0 then
        if didWorkThisTick and doctorWorkHours > 0 then
            Energy.ApplyWorkDrain(worker, doctorWorkHours, profile)
        else
            Energy.ApplyHomeRecovery(worker, deltaHours, profile)
        end

        forcedRest = Energy.IsForcedRest(worker)
        if forcedRest then
            Energy.CompleteForcedRest(worker, currentHour, "Fully rested again.")
        elseif Energy.IsDepleted(worker) then
            forcedRest = true
            Energy.BeginForcedRest(worker, currentHour, lowEnergyReason, "Too tired to keep treating patients. Resting at home.")
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
    elseif not hasTreatmentDemand then
        worker.state = Config.States.Idle
    elseif not hasTreatmentSupplies then
        worker.state = Config.States.WarehouseShortage
    else
        worker.state = Config.States.Working
    end
end

if DC_Colony.Config.JobProfiles and DC_Colony.Config.JobProfiles.Doctor then
    DC_Colony.Config.JobProfiles.Doctor.processHandler = Sim.ProcessDoctorJob
end
