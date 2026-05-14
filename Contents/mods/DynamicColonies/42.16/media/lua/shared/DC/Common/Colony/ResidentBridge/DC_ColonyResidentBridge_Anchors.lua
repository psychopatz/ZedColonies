DC_Colony = DC_Colony or {}
DC_Colony.ResidentBridge = DC_Colony.ResidentBridge or {}

local Bridge = DC_Colony.ResidentBridge
local Internal = Bridge.Internal or {}

local function buildPoint(x, y, z)
    if tonumber(x) == nil or tonumber(y) == nil then
        return nil
    end

    return {
        x = math.floor(tonumber(x) or 0),
        y = math.floor(tonumber(y) or 0),
        z = math.floor(tonumber(z) or 0)
    }
end

local function resolveExistingHome(worker)
    return buildPoint(worker and worker.homeX, worker and worker.homeY, worker and worker.homeZ)
end

local function resolveExistingWork(worker)
    return buildPoint(worker and worker.workX, worker and worker.workY, worker and worker.workZ)
end

function Bridge.ResolveHomeAnchor(worker)
    local target = nil
    local homeMode = "fallback"

    if type(worker) ~= "table" then
        return nil, homeMode
    end

    if DC_ZoneRealBase and worker.housingBuildingID and worker.housingBuildingType then
        if DC_ZoneRealBase.ResolveHousingTarget then
            target = DC_ZoneRealBase.ResolveHousingTarget(worker)
            if Internal.HasPoint(target) then
                homeMode = "housing"
            end
        end

        if not Internal.HasPoint(target) and DC_ZoneRealBase.ResolveNearestBuildingTarget then
            target = DC_ZoneRealBase.ResolveNearestBuildingTarget(
                worker.ownerUsername,
                worker.housingBuildingType,
                worker.homeX or worker.workX,
                worker.homeY or worker.workY,
                worker.housingBuildingID
            )
            if Internal.HasPoint(target) then
                homeMode = "building"
            end
        end
    end

    if not Internal.HasPoint(target) and DC_ZoneRealBase and DC_ZoneRealBase.ResolveBaseTarget then
        target = DC_ZoneRealBase.ResolveBaseTarget(worker.ownerUsername)
        if Internal.HasPoint(target) then
            homeMode = "base"
        end
    end

    if not Internal.HasPoint(target) then
        target = resolveExistingHome(worker)
    end

    return Internal.CopyPoint(target), homeMode
end

function Bridge.ResolveWorkAnchor(worker, homeTarget)
    if type(worker) ~= "table" then
        return nil, "fallback"
    end

    local config = Internal.GetConfig()
    local jobTypes = config and config.JobTypes or {}
    local normalizedJob = config and config.NormalizeJobType
        and config.NormalizeJobType(worker.jobType)
        or tostring(worker.jobType or "")
    local target = nil
    local workMode = "fallback"

    if normalizedJob == tostring(jobTypes.Doctor or "Doctor") and DC_ZoneRealBase and DC_ZoneRealBase.ResolveInfirmaryTarget then
        target = DC_ZoneRealBase.ResolveInfirmaryTarget(worker)
        workMode = "building"
    elseif normalizedJob == tostring(jobTypes.Farm or "Farm") and DC_ZoneRealBase and DC_ZoneRealBase.ResolveGreenhouseTarget then
        target = DC_ZoneRealBase.ResolveGreenhouseTarget(worker)
        workMode = "building"
    elseif normalizedJob == tostring(jobTypes.Gatherer or "Gatherer") and DC_ZoneRealBase and DC_ZoneRealBase.ResolveGathererTarget then
        target = DC_ZoneRealBase.ResolveGathererTarget(worker)
        workMode = "job"
    elseif normalizedJob == tostring(jobTypes.Builder or "Builder")
        and worker.assignedProjectBuildingType
        and worker.assignedProjectBuildingID
        and DC_ZoneRealBase
        and DC_ZoneRealBase.ResolveNearestBuildingTarget then
        target = DC_ZoneRealBase.ResolveNearestBuildingTarget(
            worker.ownerUsername,
            worker.assignedProjectBuildingType,
            worker.homeX or worker.workX,
            worker.homeY or worker.workY,
            worker.assignedProjectBuildingID
        )
        workMode = "building"
    end

    if not Internal.HasPoint(target) then
        target = homeTarget or resolveExistingHome(worker)
        workMode = "base"
    end

    if not Internal.HasPoint(target) then
        target = resolveExistingWork(worker)
    end

    return Internal.CopyPoint(target), workMode
end

function Bridge.BuildAnchorSnapshot(worker)
    local homeTarget, homeMode = Bridge.ResolveHomeAnchor(worker)
    local workTarget, workMode = Bridge.ResolveWorkAnchor(worker, homeTarget)
    return {
        home = homeTarget,
        work = workTarget,
        homeMode = tostring(homeMode or "fallback"),
        workMode = tostring(workMode or "fallback")
    }
end

return Bridge
