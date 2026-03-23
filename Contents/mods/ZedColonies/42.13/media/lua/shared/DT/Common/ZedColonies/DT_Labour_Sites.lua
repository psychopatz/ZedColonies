require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry"
require "DT/Common/ZedColonies/LabourInteraction/DT_Labour_Interaction"

DT_Labour = DT_Labour or {}
DT_Labour.Sites = DT_Labour.Sites or {}

local Config = DT_Labour.Config
local Registry = DT_Labour.Registry
local Sites = DT_Labour.Sites
local Interaction = DT_Labour.Interaction

local function getSquare(x, y, z)
    local cell = getCell()
    if not cell then return nil end
    return cell:getGridSquare(x, y, z or 0)
end

local function getZoneType(square)
    if not square then return nil end
    local zone = square.getZone and square:getZone() or nil
    if zone and zone.getType then
        return zone:getType()
    end
    return nil
end

local function normalizeContextValue(value)
    local text = tostring(value or ""):lower()
    text = string.gsub(text, "[^%w]+", " ")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function appendContextValue(values, seen, value)
    local normalized = normalizeContextValue(value)
    if normalized == "" or seen[normalized] then
        return
    end

    seen[normalized] = true
    values[#values + 1] = normalized
end

local function getRoomName(square)
    if not square then
        return nil
    end

    local room = square.getRoom and square:getRoom() or nil
    if not room then
        return nil
    end

    if room.getName then
        local ok, value = pcall(room.getName, room)
        if ok and value ~= nil then
            local text = tostring(value)
            if text ~= "" and not string.find(text, "^table:") and not string.find(text, "^table 0x") then
                return text
            end
        end
    end

    local roomName = room.name
    if type(roomName) == "string" then
        return roomName
    end

    local fallbackText = tostring(roomName or "")
    if fallbackText ~= "" and not string.find(fallbackText, "^table:") and not string.find(fallbackText, "^table 0x") then
        return fallbackText
    end

    return nil
end

local function collectBuildingRoomNames(square, values, seen)
    local building = square and square.getBuilding and square:getBuilding() or nil
    local def = building and building.getDef and building:getDef() or nil
    local rooms = def and def.getRooms and def:getRooms() or nil
    if not rooms or not rooms.size or not rooms.get then
        return
    end

    for index = 0, rooms:size() - 1 do
        local roomDef = rooms:get(index)
        local roomName = roomDef and roomDef.getName and roomDef:getName() or roomDef and roomDef.name or nil
        appendContextValue(values, seen, roomName)
    end
end

local function collectScavengeContext(site)
    local values = {}
    local seen = {}
    local square = getSquare(site and site.x, site and site.y, site and site.z)
    local roomName = getRoomName(square)
    local zoneType = getZoneType(square)

    appendContextValue(values, seen, roomName)
    appendContextValue(values, seen, zoneType)
    collectBuildingRoomNames(square, values, seen)

    return {
        square = square,
        roomName = normalizeContextValue(roomName),
        zoneType = normalizeContextValue(zoneType),
        contextText = table.concat(values, " "),
        values = values
    }
end

local function scoreSiteProfile(contextText, profile)
    local score = 0
    for _, token in ipairs(profile and profile.matchTokens or {}) do
        local normalizedToken = normalizeContextValue(token)
        if normalizedToken ~= "" and string.find(contextText, normalizedToken, 1, true) then
            score = score + 1
        end
    end
    return score
end

local function applyScavengeSiteProfile(site)
    if not site then
        return nil
    end

    local context = collectScavengeContext(site)
    local bestProfile = Config.GetScavengeSiteProfile and Config.GetScavengeSiteProfile("Unknown") or { id = "Unknown", displayName = "Unsorted Location" }
    local bestScore = 0

    for _, profileID in ipairs(Config.ScavengeSiteProfileOrder or {}) do
        local profile = Config.GetScavengeSiteProfile and Config.GetScavengeSiteProfile(profileID) or nil
        local score = scoreSiteProfile(context.contextText or "", profile)
        if score > bestScore then
            bestScore = score
            bestProfile = profile
        end
    end

    site.scavengeProfileID = bestProfile.id or "Unknown"
    if site.scavengeProfileID == "Unknown" and Interaction and Interaction.GetScavengeFallbackProfileLabel then
        site.scavengeProfileLabel = Interaction.GetScavengeFallbackProfileLabel(context.roomName, context.zoneType)
    else
        site.scavengeProfileLabel = bestProfile.displayName or site.scavengeProfileID
    end
    site.scavengeRoomName = (context.roomName and context.roomName ~= "") and context.roomName or nil
    site.scavengeZoneType = (context.zoneType and context.zoneType ~= "") and context.zoneType or nil
    site.scavengeContext = context.contextText or ""
    return bestProfile
end

function Sites.ValidateSite(site, jobType)
    if not site then
        return true, "Workplace validation is deferred for now."
    end

    site.siteType = site.siteType or Config.GetJobProfile(jobType).siteType
    if Config.NormalizeJobType(jobType) == Config.JobTypes.Scavenge then
        applyScavengeSiteProfile(site)
    end
    return true, "Workplace validation is deferred for now."
end

function Sites.AssignSiteForWorker(worker, x, y, z, radius)
    if not worker then
        return nil, "Missing worker."
    end

    local profile = Config.GetJobProfile(worker.jobType)
    local site = {
        ownerUsername = worker.ownerUsername,
        workerID = worker.workerID,
        siteType = profile.siteType,
        x = math.floor(x or 0),
        y = math.floor(y or 0),
        z = math.floor(z or 0),
        radius = math.floor(radius or worker.radius or Config.DEFAULT_SITE_RADIUS),
        lastValidatedHour = Config.GetCurrentHour()
    }

    local isValid, reason = Sites.ValidateSite(site, worker.jobType)
    site.valid = isValid
    site.reason = reason
    Registry.AssignSiteToWorker(worker, site)
    worker.siteState = (Config.NormalizeJobType(worker.jobType) == Config.JobTypes.Scavenge)
        and ("Profiled: " .. tostring(site.scavengeProfileLabel or "Unsorted Location"))
        or "Deferred"
    worker.scavengeSiteProfileID = site.scavengeProfileID
    worker.scavengeSiteProfileLabel = site.scavengeProfileLabel
    worker.scavengeSiteRoomName = site.scavengeRoomName
    worker.scavengeSiteZoneType = site.scavengeZoneType

    return site, reason
end

function Sites.RefreshWorkerSite(worker)
    if not worker then
        return true, "Workplace validation is deferred for now."
    end

    if not worker.assignedSiteID then
        worker.siteState = "Deferred"
        worker.scavengeSiteProfileID = nil
        worker.scavengeSiteProfileLabel = nil
        worker.scavengeSiteRoomName = nil
        worker.scavengeSiteZoneType = nil
        return true, "No workplace required yet."
    end

    local site = Registry.GetSite(worker.assignedSiteID)
    if not site then
        worker.siteState = "Deferred"
        worker.scavengeSiteProfileID = nil
        worker.scavengeSiteProfileLabel = nil
        worker.scavengeSiteRoomName = nil
        worker.scavengeSiteZoneType = nil
        return true, "Missing workplace data is ignored for now."
    end

    local isValid, reason = Sites.ValidateSite(site, worker.jobType)
    site.valid = isValid
    site.reason = reason
    site.lastValidatedHour = Config.GetCurrentHour()
    if Config.NormalizeJobType(worker.jobType) == Config.JobTypes.Scavenge then
        worker.siteState = "Profiled: " .. tostring(site.scavengeProfileLabel or "Unsorted Location")
        worker.scavengeSiteProfileID = site.scavengeProfileID
        worker.scavengeSiteProfileLabel = site.scavengeProfileLabel
        worker.scavengeSiteRoomName = site.scavengeRoomName
        worker.scavengeSiteZoneType = site.scavengeZoneType
    else
        worker.siteState = "Deferred"
    end
    worker.workX = site.x
    worker.workY = site.y
    worker.workZ = site.z or 0
    worker.radius = site.radius or worker.radius
    return true, reason
end

return Sites
