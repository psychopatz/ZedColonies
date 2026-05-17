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

local function findPassablePointNear(x, y, z, radius)
    local point = copyPoint(x, y, z)
    local searchRadius = math.max(0, math.floor(tonumber(radius) or 1))
    if not getCell then
        return point
    end

    local cell = getCell()
    if not cell then
        return point
    end

    local baseZ = math.floor(tonumber(z) or 0)
    local square = cell:getGridSquare(point.x, point.y, baseZ)
    if canStandOnSquare(square) then
        return point
    end

    for delta = 1, searchRadius do
        local minX = point.x - delta
        local maxX = point.x + delta
        local minY = point.y - delta
        local maxY = point.y + delta
        local currentX = nil
        local currentY = nil

        currentY = minY
        for currentX = minX, maxX do
            square = cell:getGridSquare(currentX, currentY, baseZ)
            if canStandOnSquare(square) then
                return { x = currentX, y = currentY, z = baseZ }
            end
        end

        currentY = maxY
        for currentX = minX, maxX do
            square = cell:getGridSquare(currentX, currentY, baseZ)
            if canStandOnSquare(square) then
                return { x = currentX, y = currentY, z = baseZ }
            end
        end

        currentX = minX
        for currentY = minY + 1, maxY - 1 do
            square = cell:getGridSquare(currentX, currentY, baseZ)
            if canStandOnSquare(square) then
                return { x = currentX, y = currentY, z = baseZ }
            end
        end

        currentX = maxX
        for currentY = minY + 1, maxY - 1 do
            square = cell:getGridSquare(currentX, currentY, baseZ)
            if canStandOnSquare(square) then
                return { x = currentX, y = currentY, z = baseZ }
            end
        end
    end

    return point
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

local function appendUniquePoint(points, seen, point)
    if type(point) ~= "table" then
        return
    end

    local x = math.floor(tonumber(point.x) or 0)
    local y = math.floor(tonumber(point.y) or 0)
    local z = math.floor(tonumber(point.z) or 0)
    local key = tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
    if seen[key] then
        return
    end

    seen[key] = true
    points[#points + 1] = {
        x = x,
        y = y,
        z = z,
    }
end

local function buildPatrolPointsForRect(rect, options)
    local points = {}
    local seen = {}
    if type(rect) ~= "table" then
        return points
    end

    options = type(options) == "table" and options or {}
    local searchRadius = math.max(0, math.floor(tonumber(options.passableRadius) or 1))
    local edgeInset = math.max(0, math.floor(tonumber(options.edgeInset) or 1))
    local x1 = math.floor(tonumber(rect[1]) or 0)
    local y1 = math.floor(tonumber(rect[2]) or 0)
    local x2 = math.floor(tonumber(rect[3]) or 0)
    local y2 = math.floor(tonumber(rect[4]) or 0)
    local z = math.floor(tonumber(rect[5]) or 0)
    local width = math.max(0, x2 - x1)
    local height = math.max(0, y2 - y1)
    local midX = math.floor((x1 + x2) / 2)
    local midY = math.floor((y1 + y2) / 2)
    local innerX1 = math.min(x2, x1 + edgeInset)
    local innerX2 = math.max(x1, x2 - edgeInset)
    local innerY1 = math.min(y2, y1 + edgeInset)
    local innerY2 = math.max(y1, y2 - edgeInset)

    if width >= height and width >= 2 then
        appendUniquePoint(points, seen, findPassablePointNear(innerX1, midY, z, searchRadius))
        appendUniquePoint(points, seen, findPassablePointNear(innerX2, midY, z, searchRadius))
    elseif height > width and height >= 2 then
        appendUniquePoint(points, seen, findPassablePointNear(midX, innerY1, z, searchRadius))
        appendUniquePoint(points, seen, findPassablePointNear(midX, innerY2, z, searchRadius))
    else
        appendUniquePoint(points, seen, findPassablePointNear(midX, midY, z, searchRadius))
    end

    if #points <= 0 then
        appendUniquePoint(points, seen, findPassablePointInRect(rect))
    end

    return points
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

function RealBase.ResolveSafeFallbackTarget(ownerUsername)
    return RealBase.ResolveBaseTarget(ownerUsername)
end

function RealBase.ResolvePerimeterPosts(ownerUsername, options)
    local zones = RealBase.GetZonesForOwner(ownerUsername)
    local baseZone = RealBase.FindBaseZone(zones)
    local slot = baseZone and RealBase.GetAreaSlots(baseZone)[1] or nil
    local rect = slot and slot.rect or nil
    if type(rect) ~= "table" then
        local fallback = RealBase.ResolveSafeFallbackTarget(ownerUsername)
        return fallback and { fallback } or {}
    end

    options = type(options) == "table" and options or {}
    local spacing = math.max(3, math.floor(tonumber(options.spacing) or 6))
    local edgeInset = math.max(0, math.floor(tonumber(options.edgeInset) or 0))
    local searchRadius = math.max(0, math.floor(tonumber(options.passableRadius) or 1))
    local x1 = math.floor(tonumber(rect[1]) or 0) + edgeInset
    local y1 = math.floor(tonumber(rect[2]) or 0) + edgeInset
    local x2 = math.floor(tonumber(rect[3]) or 0) - edgeInset
    local y2 = math.floor(tonumber(rect[4]) or 0) - edgeInset
    local z = math.floor(tonumber(rect[5]) or 0)
    if x2 < x1 or y2 < y1 then
        local fallback = RealBase.ResolveSafeFallbackTarget(ownerUsername)
        return fallback and { fallback } or {}
    end

    local points = {}
    local seen = {}

    local function addPoint(x, y)
        local key = tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
        if seen[key] then
            return
        end
        seen[key] = true
        local point = findPassablePointNear(x, y, z, searchRadius)
        if point then
            points[#points + 1] = point
        end
    end

    local currentX = nil
    local currentY = nil
    for currentX = x1, x2, spacing do
        addPoint(currentX, y1)
    end
    addPoint(x2, y1)

    for currentY = y1 + spacing, y2, spacing do
        addPoint(x2, currentY)
    end
    addPoint(x2, y2)

    for currentX = x2 - spacing, x1, -spacing do
        addPoint(currentX, y2)
    end
    addPoint(x1, y2)

    for currentY = y2 - spacing, y1 + spacing, -spacing do
        addPoint(x1, currentY)
    end

    if #points <= 0 then
        local fallback = RealBase.ResolveSafeFallbackTarget(ownerUsername)
        return fallback and { fallback } or {}
    end

    return points
end

function RealBase.ResolvePatrolRoutePoints(ownerUsername, options)
    local zones = RealBase.GetZonesForOwner(ownerUsername)
    local zone = RealBase.FindJobTypeZone and RealBase.FindJobTypeZone(zones, "Patrol") or nil
    local routePoints = {}
    local seen = {}
    local slot = nil
    local point = nil

    if zone then
        for _, slot in ipairs(RealBase.GetAreaSlots(zone)) do
            if slot and slot.rect then
                local points = buildPatrolPointsForRect(slot.rect, options)
                for _, point in ipairs(points) do
                    appendUniquePoint(routePoints, seen, point)
                end
            end
        end
    end

    if #routePoints >= 2 then
        return routePoints
    end

    local perimeterPosts = RealBase.ResolvePerimeterPosts(ownerUsername, options)
    if #perimeterPosts > 0 then
        return perimeterPosts
    end

    local fallback = RealBase.ResolveSafeFallbackTarget(ownerUsername)
    return fallback and { fallback } or {}
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

function RealBase.ResolvePatrolAnchorTarget(worker)
    if not worker then
        return nil
    end

    local points = RealBase.ResolvePatrolRoutePoints(worker.ownerUsername, {
        passableRadius = 1,
        edgeInset = 1,
    })
    if #points > 0 then
        return copyPoint(nil, nil, nil, points[1])
    end

    return RealBase.ResolveSafeFallbackTarget(worker.ownerUsername)
end

return RealBase
