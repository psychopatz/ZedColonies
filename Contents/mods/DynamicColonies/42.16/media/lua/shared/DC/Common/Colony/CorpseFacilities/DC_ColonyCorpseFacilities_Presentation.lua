DC_Colony = DC_Colony or {}
DC_Colony.CorpseFacilities = DC_Colony.CorpseFacilities or {}
DC_Colony.CorpseFacilities.Internal = DC_Colony.CorpseFacilities.Internal or {}

local Facilities = DC_Colony.CorpseFacilities
local Internal = Facilities.Internal

local function countUsedSlots(slots)
    local count = 0
    for _, entry in ipairs(slots or {}) do
        if type(entry) == "table" then
            count = count + 1
        end
    end
    return count
end

local function hasAnyEntries(tbl)
    if type(tbl) ~= "table" then
        return false
    end

    for _, _ in pairs(tbl) do
        return true
    end

    return false
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

local function buildEntryPreview(entries, currentHour, anonymous)
    local preview = {}
    for slotIndex, entry in ipairs(entries or {}) do
        if type(entry) == "table" then
            preview[#preview + 1] = {
                slotIndex = slotIndex,
                entryID = entry.entryID,
                label = anonymous == true and ("Unknown Remains #" .. tostring(slotIndex))
                    or tostring(entry.name or "Unnamed"),
                ready = (tonumber(entry.readyAtHour) or 0) <= currentHour,
                readyAtHour = tonumber(entry.readyAtHour) or 0,
            }
        end
    end
    return preview
end

function Facilities.GetBuildingMetrics(ownerUsername, building, currentHour)
    local ownerData = Facilities.NormalizeOwner(ownerUsername)
    local state = ownerData and ownerData.buildings and ownerData.buildings[tostring(building and building.buildingID or "")] or nil
    local current = tonumber(currentHour) or ((getGameTime and getGameTime() and getGameTime():getWorldAgeHours()) or 0)
    local settings = ownerData and ownerData.settings or {}
    if not state then
        return {}
    end

    if state.buildingType == "Cemetery" or state.buildingType == "MassGrave" then
        local capacity = Internal.GetBuildingSlotCapacity(state.buildingType, state.level or 1)
        local anonymous = state.buildingType == "MassGrave"
        return {
            corpseCanManage = true,
            corpseFacilityType = state.buildingType,
            corpseSlotCapacity = capacity,
            corpseUsedSlots = countUsedSlots(state.slots),
            corpseReadyToExhumeCount = countReadyEntries(state.slots, current),
            corpseEntriesPreview = buildEntryPreview(state.slots, current, anonymous),
            corpseGeneralRoutePreference = tostring(settings.generalRoutePreference or "MassGrave"),
            corpseTeammateOverflowPolicy = tostring(settings.teammateOverflowPolicy or "Block"),
        }
    end

    if state.buildingType == "Incinerator" then
        local activeBatch = state.activeBatch or nil
        local remaining = activeBatch and math.max(0, (tonumber(activeBatch.readyAtHour) or 0) - current) or 0
        return {
            corpseCanManage = true,
            corpseFacilityType = "Incinerator",
            corpseQueueSize = #(state.queue or {}),
            corpseIncineratorActiveBatchSize = math.max(0, tonumber(activeBatch and activeBatch.count) or 0),
            corpseIncineratorCooldownRemainingHours = remaining,
            corpseGeneralRoutePreference = tostring(settings.generalRoutePreference or "MassGrave"),
            corpseTeammateOverflowPolicy = tostring(settings.teammateOverflowPolicy or "Block"),
        }
    end

    return {}
end

function Facilities.GetOwnerSnapshot(ownerUsername, currentHour)
    local ownerData = Facilities.NormalizeOwner(ownerUsername)
    if not ownerData then
        return nil
    end

    local current = tonumber(currentHour) or ((getGameTime and getGameTime() and getGameTime():getWorldAgeHours()) or 0)
    local snapshot = {
        settings = {
            generalRoutePreference = tostring(ownerData.settings and ownerData.settings.generalRoutePreference or "MassGrave"),
            teammateOverflowPolicy = tostring(ownerData.settings and ownerData.settings.teammateOverflowPolicy or "Block"),
        },
        summary = {
            buried = math.max(0, tonumber(ownerData.summary and ownerData.summary.buried) or 0),
            incinerated = math.max(0, tonumber(ownerData.summary and ownerData.summary.incinerated) or 0),
            exhumed = math.max(0, tonumber(ownerData.summary and ownerData.summary.exhumed) or 0),
            blockedCleanups = math.max(0, tonumber(ownerData.summary and ownerData.summary.blockedCleanups) or 0),
        },
        buildings = {},
    }

    for _, building in ipairs(DC_Buildings.GetBuildingsForOwner and DC_Buildings.GetBuildingsForOwner(ownerData.ownerUsername) or {}) do
        local metrics = Facilities.GetBuildingMetrics(ownerData.ownerUsername, building, current)
        if hasAnyEntries(metrics) then
            snapshot.buildings[tostring(building.buildingID or "")] = metrics
        end
    end

    return snapshot
end

return Facilities
