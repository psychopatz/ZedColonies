DC_Buildings = DC_Buildings or {}
DC_Buildings.RealBase = DC_Buildings.RealBase or {}

local Buildings = DC_Buildings
local RealBase = Buildings.RealBase

local function copyTargetToHome(worker, target)
    if not worker or not target then
        return
    end

    worker.homeX = math.floor(tonumber(target.x) or tonumber(worker.homeX) or 0)
    worker.homeY = math.floor(tonumber(target.y) or tonumber(worker.homeY) or 0)
    worker.homeZ = math.floor(tonumber(target.z) or tonumber(worker.homeZ) or 0)
end

local function copyTargetToWork(worker, target)
    if not worker or not target then
        return
    end

    worker.workX = math.floor(tonumber(target.x) or tonumber(worker.workX) or 0)
    worker.workY = math.floor(tonumber(target.y) or tonumber(worker.workY) or 0)
    worker.workZ = math.floor(tonumber(target.z) or tonumber(worker.workZ) or 0)
end

function RealBase.ApplyWorkerAnchors(worker)
    if not worker or not DC_ZoneRealBase then
        return
    end

    local config = DC_Colony and DC_Colony.Config or nil
    local normalizedJob = config and config.NormalizeJobType and config.NormalizeJobType(worker.jobType) or tostring(worker.jobType or "")
    local jobTypes = config and config.JobTypes or {}

    local homeTarget = nil
    if tostring(worker.housingBuildingType or "") == "Barracks" and worker.housingBuildingID then
        homeTarget = DC_ZoneRealBase.ResolveHousingTarget and DC_ZoneRealBase.ResolveHousingTarget(worker) or nil
    end
    if not homeTarget then
        homeTarget = DC_ZoneRealBase.ResolveBaseTarget and DC_ZoneRealBase.ResolveBaseTarget(worker.ownerUsername) or nil
    end
    if homeTarget then
        copyTargetToHome(worker, homeTarget)
    end

    local assignedProjectBuildingType = worker.assignedProjectBuildingType
    local assignedProjectBuildingID = worker.assignedProjectBuildingID
    if (not assignedProjectBuildingType or not assignedProjectBuildingID) and Buildings.GetProjectForWorker then
        local project = Buildings.GetProjectForWorker(worker)
        if project then
            assignedProjectBuildingType = project.buildingType
            assignedProjectBuildingID = project.buildingID
        end
    end

    local workTarget = nil
    if normalizedJob == tostring(jobTypes.Doctor or "Doctor") then
        workTarget = DC_ZoneRealBase.ResolveInfirmaryTarget and DC_ZoneRealBase.ResolveInfirmaryTarget(worker) or nil
    elseif normalizedJob == tostring(jobTypes.Guard or "Guard") then
        workTarget = DC_ZoneRealBase.ResolveSafeFallbackTarget and DC_ZoneRealBase.ResolveSafeFallbackTarget(worker.ownerUsername) or nil
    elseif normalizedJob == tostring(jobTypes.Farm or "Farm") then
        workTarget = DC_ZoneRealBase.ResolveGreenhouseTarget and DC_ZoneRealBase.ResolveGreenhouseTarget(worker) or nil
    elseif normalizedJob == tostring(jobTypes.Gatherer or "Gatherer") then
        workTarget = DC_ZoneRealBase.ResolveGathererTarget and DC_ZoneRealBase.ResolveGathererTarget(worker) or nil
    elseif normalizedJob == tostring(jobTypes.Builder or "Builder")
        and assignedProjectBuildingType and assignedProjectBuildingID then
        workTarget = DC_ZoneRealBase.ResolveNearestBuildingTarget and DC_ZoneRealBase.ResolveNearestBuildingTarget(
            worker.ownerUsername,
            assignedProjectBuildingType,
            worker.homeX,
            worker.homeY,
            assignedProjectBuildingID
        ) or nil
    end

    if not workTarget
        and worker.infirmaryBedAssigned == true
        and (tonumber(worker.hp) or 0) < (tonumber(worker.maxHp) or 0) then
        workTarget = DC_ZoneRealBase.ResolveInfirmaryTarget and DC_ZoneRealBase.ResolveInfirmaryTarget(worker) or nil
    end

    if workTarget then
        copyTargetToWork(worker, workTarget)
    elseif homeTarget and tostring(worker.state or "") == tostring((config and config.States and config.States.Resting) or "Resting") then
        copyTargetToWork(worker, homeTarget)
    end
end

return RealBase
