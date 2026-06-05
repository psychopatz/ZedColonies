DC_Colony = DC_Colony or {}
DC_Colony.CorpseFacilities = DC_Colony.CorpseFacilities or {}
DC_Colony.CorpseFacilities.Internal = DC_Colony.CorpseFacilities.Internal or {}

local Registry = DC_Colony.Registry
local Buildings = DC_Buildings
local Facilities = DC_Colony.CorpseFacilities
local Internal = Facilities.Internal

local function getCurrentHour()
    local gt = getGameTime and getGameTime() or nil
    return gt and gt.getWorldAgeHours and gt:getWorldAgeHours() or 0
end

local function getOwnerBuildingsByType(ownerUsername)
    local groups = {
        Cemetery = {},
        MassGrave = {},
        Incinerator = {},
    }
    for _, building in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(ownerUsername) or {}) do
        local buildingType = tostring(building and building.buildingType or "")
        if groups[buildingType] then
            groups[buildingType][#groups[buildingType] + 1] = building
        end
    end
    return groups
end

local function findEmptySlot(slots)
    for index, entry in ipairs(slots or {}) do
        if entry == nil then
            return index
        end
    end
    return nil
end

local function countReadyEntries(slots, currentHour)
    local count = 0
    for _, entry in ipairs(slots or {}) do
        if type(entry) == "table" and (tonumber(entry.readyAtHour) or 0) <= currentHour then
            count = count + 1
        end
    end
    return count
end

local function countUsedSlots(slots)
    local count = 0
    for _, entry in ipairs(slots or {}) do
        if type(entry) == "table" then
            count = count + 1
        end
    end
    return count
end

local function buildBurialEntry(ownerUsername, corpseInfo, corpseClass, readyAtHour, includeName)
    return {
        entryID = Internal.NextEntryID(ownerUsername),
        corpseClass = corpseClass,
        buriedAtHour = getCurrentHour(),
        readyAtHour = readyAtHour,
        name = includeName == true and tostring(corpseInfo and corpseInfo.name or "") or nil,
        uuid = includeName == true and tostring(corpseInfo and corpseInfo.uuid or "") or nil,
    }
end

local function acceptIntoSlots(ownerUsername, ownerData, building, includeName, corpseClass, corpseInfo)
    local buildingID = tostring(building and building.buildingID or "")
    local state = ownerData and ownerData.buildings and ownerData.buildings[buildingID] or nil
    local slotIndex = state and findEmptySlot(state.slots) or nil
    if not state or not slotIndex then
        return false
    end

    local days = Internal.GetBuildingDecomposeDays(tostring(building.buildingType or ""), tonumber(building.level) or 1)
    local nowHour = getCurrentHour()
    state.slots[slotIndex] = buildBurialEntry(ownerUsername, corpseInfo, corpseClass, nowHour + (days * 24), includeName)
    ownerData.summary.buried = math.max(0, tonumber(ownerData.summary.buried) or 0) + 1
    Internal.Touch(ownerUsername)
    return true, tostring(building.buildingType or ""), state.slots[slotIndex]
end

local function queueIncinerator(ownerUsername, ownerData, building, corpseClass, corpseInfo)
    local buildingID = tostring(building and building.buildingID or "")
    local state = ownerData and ownerData.buildings and ownerData.buildings[buildingID] or nil
    if not state then
        return false
    end

    state.queue[#state.queue + 1] = {
        entryID = Internal.NextEntryID(ownerUsername),
        corpseClass = corpseClass,
        queuedAtHour = getCurrentHour(),
        name = tostring(corpseInfo and corpseInfo.name or ""),
        uuid = tostring(corpseInfo and corpseInfo.uuid or ""),
    }
    Internal.Touch(ownerUsername)
    return true, "Incinerator", state.queue[#state.queue]
end

local function incrementBlocked(ownerData, ownerUsername)
    ownerData.summary.blockedCleanups = math.max(0, tonumber(ownerData.summary.blockedCleanups) or 0) + 1
    Internal.Touch(ownerUsername)
end

local function routeOrdinary(ownerUsername, ownerData, groups, corpseClass, corpseInfo)
    local preference = tostring(ownerData.settings and ownerData.settings.generalRoutePreference or "MassGrave")
    local ordered = preference == "Incinerator"
        and { "Incinerator", "MassGrave" }
        or { "MassGrave", "Incinerator" }

    for _, buildingType in ipairs(ordered) do
        for _, building in ipairs(groups[buildingType] or {}) do
            if buildingType == "MassGrave" then
                local accepted = acceptIntoSlots(ownerUsername, ownerData, building, false, corpseClass, corpseInfo)
                if accepted then
                    return true
                end
            elseif buildingType == "Incinerator" then
                local accepted = queueIncinerator(ownerUsername, ownerData, building, corpseClass, corpseInfo)
                if accepted then
                    return true
                end
            end
        end
    end

    incrementBlocked(ownerData, ownerUsername)
    return false, "no_route"
end

function Facilities.CanRouteOrdinaryCorpse(ownerUsername)
    local owner = DC_Colony.Config.GetOwnerUsername and DC_Colony.Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
    local groups = getOwnerBuildingsByType(owner)
    return #(groups.MassGrave or {}) > 0 or #(groups.Incinerator or {}) > 0
end

function Facilities.GetSettings(ownerUsername)
    local ownerData = Facilities.NormalizeOwner(ownerUsername)
    return ownerData and ownerData.settings or {
        generalRoutePreference = "MassGrave",
        teammateOverflowPolicy = "Block",
    }
end

function Facilities.SetGeneralRoutePreference(ownerUsername, route)
    local ownerData = Facilities.NormalizeOwner(ownerUsername)
    if not ownerData then
        return false
    end
    local normalized = tostring(route or "MassGrave")
    if normalized ~= "MassGrave" and normalized ~= "Incinerator" then
        normalized = "MassGrave"
    end
    ownerData.settings.generalRoutePreference = normalized
    Internal.Touch(ownerUsername)
    return true
end

function Facilities.SetTeammateOverflowPolicy(ownerUsername, policy)
    local ownerData = Facilities.NormalizeOwner(ownerUsername)
    if not ownerData then
        return false
    end
    local normalized = tostring(policy or "Block")
    if normalized ~= "Block" and normalized ~= "AllowOverflow" then
        normalized = "Block"
    end
    ownerData.settings.teammateOverflowPolicy = normalized
    Internal.Touch(ownerUsername)
    return true
end

function Facilities.TryAcceptCorpse(ownerUsername, corpseClass, corpseInfo)
    local owner = DC_Colony.Config.GetOwnerUsername and DC_Colony.Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
    local ownerData = Facilities.NormalizeOwner(owner)
    if not ownerData then
        return false, "no_owner"
    end

    local groups = getOwnerBuildingsByType(owner)
    local normalizedClass = tostring(corpseClass or "ordinary")
    if normalizedClass == "colony_teammate" then
        for _, building in ipairs(groups.Cemetery or {}) do
            local accepted = acceptIntoSlots(owner, ownerData, building, true, normalizedClass, corpseInfo)
            if accepted then
                return true, "Cemetery"
            end
        end

        if tostring(ownerData.settings and ownerData.settings.teammateOverflowPolicy or "Block") ~= "AllowOverflow" then
            incrementBlocked(ownerData, owner)
            return false, "cemetery_blocked"
        end
    end

    return routeOrdinary(owner, ownerData, groups, normalizedClass, corpseInfo)
end

function Facilities.ExhumeEntry(ownerUsername, buildingID, slotOrEntryID)
    local owner = DC_Colony.Config.GetOwnerUsername and DC_Colony.Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
    local ownerData = Facilities.NormalizeOwner(owner)
    local state = ownerData and ownerData.buildings and ownerData.buildings[tostring(buildingID or "")] or nil
    if not state or (state.buildingType ~= "Cemetery" and state.buildingType ~= "MassGrave") then
        return false, "invalid_building"
    end

    local currentHour = getCurrentHour()
    for slotIndex, entry in ipairs(state.slots or {}) do
        if type(entry) == "table"
            and (tostring(slotIndex) == tostring(slotOrEntryID or "") or tostring(entry.entryID or "") == tostring(slotOrEntryID or ""))
        then
            if (tonumber(entry.readyAtHour) or 0) > currentHour then
                return false, "not_ready"
            end
            state.slots[slotIndex] = nil
            ownerData.summary.exhumed = math.max(0, tonumber(ownerData.summary.exhumed) or 0) + 1
            Internal.Touch(owner)
            return true
        end
    end

    return false, "not_found"
end

function Facilities.ProcessOwner(ownerUsername, currentHour)
    local owner = DC_Colony.Config.GetOwnerUsername and DC_Colony.Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
    local ownerData = Facilities.NormalizeOwner(owner)
    if not ownerData then
        return 0
    end

    local changed = 0
    local nowHour = tonumber(currentHour) or getCurrentHour()
    for buildingID, state in pairs(ownerData.buildings or {}) do
        if tostring(state and state.buildingType or "") == "Incinerator" then
            if type(state.activeBatch) == "table" and (tonumber(state.activeBatch.readyAtHour) or 0) <= nowHour then
                ownerData.summary.incinerated = math.max(0, tonumber(ownerData.summary.incinerated) or 0)
                    + math.max(0, tonumber(state.activeBatch.count) or 0)
                state.activeBatch = nil
                changed = changed + 1
            end

            if state.activeBatch == nil and #(state.queue or {}) > 0 then
                local building = Buildings.FindBuildingForOwner and Buildings.FindBuildingForOwner(owner, buildingID) or nil
                local batchSize = Internal.GetIncineratorBatchSize(building and building.level or state.level or 1)
                local cooldown = Internal.GetIncineratorCooldownHours(building and building.level or state.level or 1)
                local count = math.min(batchSize, #state.queue)
                for _ = 1, count do
                    table.remove(state.queue, 1)
                end
                state.activeBatch = {
                    count = count,
                    startedAtHour = nowHour,
                    readyAtHour = nowHour + cooldown,
                }
                changed = changed + 1
            end
        end
    end

    if changed > 0 then
        Internal.Touch(owner)
    end
    ownerData.lastProcessedHour = nowHour
    return changed
end

function Facilities.ProcessAllOwners(currentHour)
    local total = 0
    for _, ownerUsername in ipairs(Registry.GetOwnerUsernames and Registry.GetOwnerUsernames() or {}) do
        total = total + Facilities.ProcessOwner(ownerUsername, currentHour)
    end
    return total
end

return Facilities
