DC_ZoneRealBase = DC_ZoneRealBase or {}

local RealBase = DC_ZoneRealBase

local function copyPoint(x, y, z, source)
    if type(source) == "table" then
        return {
            x = math.floor(tonumber(source.x) or 0),
            y = math.floor(tonumber(source.y) or 0),
            z = math.floor(tonumber(source.z) or 0)
        }
    end

    return {
        x = math.floor(tonumber(x) or 0),
        y = math.floor(tonumber(y) or 0),
        z = math.floor(tonumber(z) or 0)
    }
end

local function getRectCenter(rect)
    if type(rect) ~= "table" then
        return nil
    end

    return {
        x = math.floor(((rect[1] or 0) + (rect[3] or 0)) / 2),
        y = math.floor(((rect[2] or 0) + (rect[4] or 0)) / 2),
        z = math.floor(tonumber(rect[5]) or 0)
    }
end

local function canStandOnSquare(square)
    if not square then
        return false
    end

    if square.isSolid and square:isSolid() then
        return false
    end

    if square.isBlockedTo and square:isBlockedTo(square) then
        return false
    end

    return true
end

local function findPassablePointInRect(rect)
    local center = getRectCenter(rect)
    if not center then
        return nil
    end

    if not getCell then
        return center
    end

    local cell = getCell()
    if not cell then
        return center
    end

    local square = cell:getGridSquare(center.x, center.y, center.z or 0)
    if canStandOnSquare(square) then
        return center
    end

    for y = rect[2], rect[4] do
        for x = rect[1], rect[3] do
            square = cell:getGridSquare(x, y, rect[5] or 0)
            if canStandOnSquare(square) then
                return {
                    x = x,
                    y = y,
                    z = math.floor(tonumber(rect[5]) or 0)
                }
            end
        end
    end

    return center
end

local function buildCandidate(slot, buildingType)
    local point = findPassablePointInRect(slot and slot.rect)
    if not point then
        return nil
    end

    return {
        point = point,
        slot = slot,
        buildingType = buildingType
    }
end

local function scoreCandidate(candidate, anchorX, anchorY, preferredBuildingID)
    if not candidate or not candidate.point then
        return nil
    end

    local preferred = tostring(preferredBuildingID or "")
    if preferred ~= "" and tostring(candidate.slot and candidate.slot.sourceBuildingID or "") == preferred then
        return -1
    end

    local dx = (tonumber(anchorX) or candidate.point.x) - candidate.point.x
    local dy = (tonumber(anchorY) or candidate.point.y) - candidate.point.y
    return (dx * dx) + (dy * dy)
end

function RealBase.ResolveBaseTarget(ownerUsername)
    local zones = RealBase.GetZonesForOwner(ownerUsername)
    local baseZone = RealBase.FindBaseZone(zones)
    if not baseZone then
        return nil
    end

    local slot = RealBase.GetAreaSlots(baseZone)[1]
    if not slot or not slot.rect then
        return nil
    end

    local point = findPassablePointInRect(slot.rect)
    if not point then
        return nil
    end

    return copyPoint(nil, nil, nil, point)
end

function RealBase.ResolveNearestBuildingTarget(ownerUsername, buildingType, anchorX, anchorY, preferredBuildingID)
    local zones = RealBase.GetZonesForOwner(ownerUsername)
    local zone = RealBase.FindBuildingTypeZone(zones, buildingType)
    if not zone then
        return nil
    end

    local bestCandidate = nil
    local bestScore = nil

    for _, slot in ipairs(RealBase.GetAreaSlots(zone)) do
        if slot and slot.rect then
            local candidate = buildCandidate(slot, buildingType)
            local candidateScore = scoreCandidate(candidate, anchorX, anchorY, preferredBuildingID)
            if candidate and candidateScore ~= nil and (bestScore == nil or candidateScore < bestScore) then
                bestCandidate = candidate
                bestScore = candidateScore
            end
        end
    end

    if not bestCandidate then
        return nil
    end

    return copyPoint(nil, nil, nil, bestCandidate.point)
end

function RealBase.ResolveJobTypeTarget(ownerUsername, jobType, anchorX, anchorY)
    local zones = RealBase.GetZonesForOwner(ownerUsername)
    local zone = RealBase.FindJobTypeZone and RealBase.FindJobTypeZone(zones, jobType) or nil
    if not zone then
        return nil
    end

    local bestCandidate = nil
    local bestScore = nil

    for _, slot in ipairs(RealBase.GetAreaSlots(zone)) do
        if slot and slot.rect then
            local candidate = buildCandidate(slot, jobType)
            local candidateScore = scoreCandidate(candidate, anchorX, anchorY, nil)
            if candidate and candidateScore ~= nil and (bestScore == nil or candidateScore < bestScore) then
                bestCandidate = candidate
                bestScore = candidateScore
            end
        end
    end

    if not bestCandidate then
        return nil
    end

    return copyPoint(nil, nil, nil, bestCandidate.point)
end

function RealBase.ResolveInfirmaryTarget(worker)
    if not worker then
        return nil
    end

    return RealBase.ResolveNearestBuildingTarget(
        worker.ownerUsername,
        "Infirmary",
        worker.homeX or worker.workX,
        worker.homeY or worker.workY,
        worker.infirmaryBuildingID
    )
end

function RealBase.ResolveGreenhouseTarget(worker)
    if not worker then
        return nil
    end

    return RealBase.ResolveNearestBuildingTarget(
        worker.ownerUsername,
        "Greenhouse",
        worker.homeX or worker.workX,
        worker.homeY or worker.workY,
        nil
    )
end

function RealBase.ResolveHousingTarget(worker)
    if not worker then
        return nil
    end

    return RealBase.ResolveNearestBuildingTarget(
        worker.ownerUsername,
        "Barracks",
        worker.homeX or worker.workX,
        worker.homeY or worker.workY,
        worker.housingBuildingID
    )
end

function RealBase.ResolveGathererTarget(worker)
    if not worker then
        return nil
    end

    return RealBase.ResolveJobTypeTarget(
        worker.ownerUsername,
        "Gatherer",
        worker.homeX or worker.workX,
        worker.homeY or worker.workY
    )
end

return RealBase
