require "DC/Common/Zone/DC_ZoneDataStore"

DC_ZoneRealBase = DC_ZoneRealBase or {}

local RealBase = DC_ZoneRealBase

local function getStore()
    return DC_ZoneDataStore
end

local function copyDeep(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, entry in pairs(value) do
        copy[key] = copyDeep(entry)
    end
    return copy
end

local function getConfig()
    return DC_Colony and DC_Colony.Config or nil
end

local function normalizeOwner(ownerUsername)
    local config = getConfig()
    if config and config.GetOwnerUsername then
        return config.GetOwnerUsername(ownerUsername)
    end
    return tostring(ownerUsername or "local")
end

local function getOwnerColonyID(ownerUsername)
    local owner = normalizeOwner(ownerUsername)
    local ownerData = DC_Buildings and DC_Buildings.Internal and DC_Buildings.Internal.GetExistingOwnerData
        and DC_Buildings.Internal.GetExistingOwnerData(owner)
        or DC_Buildings and DC_Buildings.EnsureOwner and DC_Buildings.EnsureOwner(owner)
        or nil
    return tostring(ownerData and ownerData.colonyID or owner or "local")
end

local function getDefinitionLabel(buildingType)
    local definition = DC_Buildings and DC_Buildings.Config and DC_Buildings.Config.GetDefinition
        and DC_Buildings.Config.GetDefinition(buildingType)
        or nil
    return tostring(definition and definition.displayName or buildingType or "Building")
end

local function getDefaultZoneType(buildingType)
    local normalized = tostring(buildingType or "")
    if normalized == "Greenhouse" then
        return "farming"
    end
    if normalized == "Warehouse" then
        return "storage"
    end
    return "roaming"
end

local function findZoneByPredicate(zones, predicate)
    for _, zone in ipairs(zones or {}) do
        if predicate(zone) then
            return zone
        end
    end
    return nil
end

local function findIncomingZone(incomingZones, zone)
    local zoneID = tostring(zone and zone.id or "")
    for _, incomingZone in ipairs(incomingZones or {}) do
        if zoneID ~= "" and tostring(incomingZone and incomingZone.id or "") == zoneID then
            return incomingZone
        end
    end

    if zone and tostring(zone.zoneKind or "") == "base" then
        return findZoneByPredicate(incomingZones, function(entry)
            return tostring(entry and entry.zoneKind or "") == "base"
        end)
    end

    if zone and tostring(zone.zoneKind or "") == "buildingType" then
        local buildingType = tostring(zone.sourceBuildingType or "")
        return findZoneByPredicate(incomingZones, function(entry)
            return tostring(entry and entry.zoneKind or "") == "buildingType"
                and tostring(entry and entry.sourceBuildingType or "") == buildingType
        end)
    end

    if zone and tostring(zone.zoneKind or "") == "jobType" then
        local jobType = tostring(zone.sourceJobType or "")
        return findZoneByPredicate(incomingZones, function(entry)
            return tostring(entry and entry.zoneKind or "") == "jobType"
                and tostring(entry and entry.sourceJobType or "") == jobType
        end)
    end

    return nil
end

local function isManagedZone(zone)
    local zoneKind = tostring(zone and zone.zoneKind or "")
    return zoneKind == "base" or zoneKind == "buildingType" or zoneKind == "jobType"
end

local function findIncomingSlot(incomingZone, expectedSlot)
    local expectedAreaID = tostring(expectedSlot and expectedSlot.areaID or "")
    local expectedBuildingID = tostring(expectedSlot and expectedSlot.sourceBuildingID or "")

    for _, incomingSlot in ipairs(RealBase.GetAreaSlots(incomingZone)) do
        if expectedAreaID ~= "" and tostring(incomingSlot and incomingSlot.areaID or "") == expectedAreaID then
            return incomingSlot
        end
    end

    if expectedBuildingID ~= "" then
        for _, incomingSlot in ipairs(RealBase.GetAreaSlots(incomingZone)) do
            if tostring(incomingSlot and incomingSlot.sourceBuildingID or "") == expectedBuildingID then
                return incomingSlot
            end
        end
    end

    return nil
end

function RealBase.GetZonesForOwner(ownerUsername)
    local store = getStore()
    if not (store and store.GetZones) then
        return {}
    end
    return store.GetZones(getOwnerColonyID(ownerUsername))
end

function RealBase.FindBaseZone(zones)
    return findZoneByPredicate(zones, function(zone)
        return tostring(zone and zone.zoneKind or "") == "base"
    end)
end

function RealBase.FindBuildingTypeZone(zones, buildingType)
    local wantedType = tostring(buildingType or "")
    return findZoneByPredicate(zones, function(zone)
        return tostring(zone and zone.zoneKind or "") == "buildingType"
            and tostring(zone and zone.sourceBuildingType or "") == wantedType
    end)
end

function RealBase.FindJobTypeZone(zones, jobType)
    local wantedType = tostring(jobType or "")
    return findZoneByPredicate(zones, function(zone)
        return tostring(zone and zone.zoneKind or "") == "jobType"
            and tostring(zone and zone.sourceJobType or "") == wantedType
    end)
end

function RealBase.FindBuildingSlot(zones, buildingID)
    local wantedID = tostring(buildingID or "")
    if wantedID == "" then
        return nil, nil, nil
    end

    for _, zone in ipairs(zones or {}) do
        for index, slot in ipairs(RealBase.GetAreaSlots(zone)) do
            if tostring(slot and slot.sourceBuildingID or "") == wantedID then
                return zone, slot, index
            end
        end
    end

    return nil, nil, nil
end

function RealBase.ShouldCreateBuildingSlot(buildingType)
    local normalized = tostring(buildingType or "")
    if normalized == "" or normalized == "Headquarters" or normalized == "Barricade" then
        return false
    end
    return true
end

function RealBase.ShouldCreateJobZone(jobType)
    local normalized = tostring(jobType or "")
    return normalized == "Gatherer"
end

function RealBase.BuildBaseZone(colonyId)
    local zone = DC_ZoneData.createZone("Base Zone", "roaming", colonyId)
    zone.zoneKind = "base"
    zone.areaSlots = {
        RealBase.BuildAreaSlot({
            areaID = "dcbase_" .. tostring(colonyId or "local"),
            label = "Base Area",
            sourceKind = "base",
            rect = nil
        })
    }
    RealBase.NormalizeZoneShape(zone)
    return zone
end

function RealBase.EnsureBaseZoneForOwner(ownerUsername, colonyId)
    local owner = normalizeOwner(ownerUsername)
    local resolvedColonyId = tostring(colonyId or getOwnerColonyID(owner))
    if not (DC_Buildings and DC_Buildings.OwnerHasHeadquarters and DC_Buildings.OwnerHasHeadquarters(owner)) then
        return nil, false
    end

    local store = getStore()
    if not (store and store.GetZones and store.Commit) then
        return nil, false
    end

    local zones = store.GetZones(resolvedColonyId)
    local baseZone = RealBase.FindBaseZone(zones)
    if baseZone then
        RealBase.NormalizeZoneShape(baseZone)
        return baseZone, false
    end

    baseZone = RealBase.BuildBaseZone(resolvedColonyId)
    zones[#zones + 1] = baseZone
    store.Commit(resolvedColonyId)
    return baseZone, true
end

function RealBase.BuildJobTypeZone(colonyId, jobType)
    local zone = DC_ZoneData.createZone(tostring(jobType or "Job") .. " Zone", "roaming", colonyId)
    zone.zoneKind = "jobType"
    zone.sourceJobType = tostring(jobType or "")
    zone.areaSlots = {
        RealBase.BuildAreaSlot({
            areaID = "dcjob_" .. tostring(colonyId or "local") .. "_" .. tostring(jobType or "Job"),
            label = tostring(jobType or "Job") .. " Area",
            sourceKind = "job",
            sourceJobType = tostring(jobType or ""),
            rect = nil
        })
    }
    RealBase.NormalizeZoneShape(zone)
    return zone
end

function RealBase.EnsureJobTypeZone(zones, colonyId, jobType)
    local zone = RealBase.FindJobTypeZone(zones, jobType)
    if zone then
        RealBase.NormalizeZoneShape(zone)
        return zone
    end

    zone = RealBase.BuildJobTypeZone(colonyId, jobType)
    zones[#zones + 1] = zone
    return zone
end

function RealBase.EnsureSystemZonesForOwner(ownerUsername, colonyId)
    local baseZone, createdBase = RealBase.EnsureBaseZoneForOwner(ownerUsername, colonyId)
    if not baseZone then
        return nil, false
    end

    local owner = normalizeOwner(ownerUsername)
    local resolvedColonyId = tostring(colonyId or getOwnerColonyID(owner))
    local store = getStore()
    if not (store and store.GetZones and store.Commit) then
        return baseZone, createdBase
    end

    local zones = store.GetZones(resolvedColonyId)
    local createdAny = createdBase == true

    if RealBase.ShouldCreateJobZone("Gatherer") then
        local zone = RealBase.FindJobTypeZone(zones, "Gatherer")
        if not zone then
            RealBase.EnsureJobTypeZone(zones, resolvedColonyId, "Gatherer")
            createdAny = true
        end
    end

    if createdAny then
        store.Commit(resolvedColonyId)
    end

    return baseZone, createdAny
end

function RealBase.EnsureBuildingTypeZone(zones, colonyId, buildingType)
    local zone = RealBase.FindBuildingTypeZone(zones, buildingType)
    if zone then
        RealBase.NormalizeZoneShape(zone)
        return zone
    end

    zone = DC_ZoneData.createZone(getDefinitionLabel(buildingType), getDefaultZoneType(buildingType), colonyId)
    zone.zoneKind = "buildingType"
    zone.sourceBuildingType = tostring(buildingType or "")
    zone.areaSlots = {}
    RealBase.NormalizeZoneShape(zone)
    zones[#zones + 1] = zone
    return zone
end

function RealBase.CreateBuildingSlotForInstance(ownerUsername, instance)
    if not instance or not RealBase.ShouldCreateBuildingSlot(instance.buildingType) then
        return nil, false
    end

    local owner = normalizeOwner(ownerUsername)
    local colonyId = getOwnerColonyID(owner)
    local store = getStore()
    if not (store and store.GetZones and store.Commit) then
        return nil, false
    end

    local zones = store.GetZones(colonyId)
    local existingZone, existingSlot = RealBase.FindBuildingSlot(zones, instance.buildingID)
    if existingZone and existingSlot then
        return existingSlot, false
    end

    local zone = RealBase.EnsureBuildingTypeZone(zones, colonyId, instance.buildingType)
    local label = instance.customName or getDefinitionLabel(instance.buildingType)
    local slot = RealBase.BuildAreaSlot({
        areaID = "dcslot_" .. tostring(instance.buildingID or ""),
        label = tostring(label or getDefinitionLabel(instance.buildingType)),
        sourceKind = "building",
        sourceBuildingID = tostring(instance.buildingID or ""),
        sourceBuildingType = tostring(instance.buildingType or ""),
        rect = nil
    })
    zone.areaSlots[#zone.areaSlots + 1] = slot
    RealBase.NormalizeZoneShape(zone)
    store.Commit(colonyId)
    return slot, true
end

function RealBase.RemoveBuildingSlot(ownerUsername, buildingID)
    local owner = normalizeOwner(ownerUsername)
    local colonyId = getOwnerColonyID(owner)
    local store = getStore()
    if not (store and store.GetZones and store.Commit) then
        return false
    end

    local zones = store.GetZones(colonyId)
    local zone, _, slotIndex = RealBase.FindBuildingSlot(zones, buildingID)
    if not zone or not slotIndex then
        return false
    end

    table.remove(zone.areaSlots, slotIndex)
    RealBase.NormalizeZoneShape(zone)

    if tostring(zone.zoneKind or "") == "buildingType" and #RealBase.GetAreaSlots(zone) <= 0 then
        for zoneIndex = #zones, 1, -1 do
            if zones[zoneIndex] == zone then
                table.remove(zones, zoneIndex)
                break
            end
        end
    end

    store.Commit(colonyId)
    return true
end

function RealBase.RefreshBuildingSlotLabel(ownerUsername, buildingID, label)
    local owner = normalizeOwner(ownerUsername)
    local colonyId = getOwnerColonyID(owner)
    local store = getStore()
    if not (store and store.GetZones and store.Commit) then
        return false
    end

    local zones = store.GetZones(colonyId)
    local _, slot = RealBase.FindBuildingSlot(zones, buildingID)
    if not slot then
        return false
    end

    slot.label = tostring(label or slot.label or "Area")
    store.Commit(colonyId)
    return true
end

function RealBase.BuildMergedZonesForSave(ownerUsername, colonyId, incomingZones)
    local owner = normalizeOwner(ownerUsername)
    local resolvedColonyId = tostring(colonyId or getOwnerColonyID(owner))
    local store = getStore()
    local currentZones = {}
    if store and store.GetZones then
        currentZones = DC_ZoneData.normalizeZones(copyDeep(store.GetZones(resolvedColonyId)), resolvedColonyId)
    end
    local normalizedIncomingZones = DC_ZoneData.normalizeZones(copyDeep(incomingZones or {}), resolvedColonyId)
    local mergedZones = {}
    local usedZoneIDs = {}

    for _, zone in ipairs(currentZones) do
        RealBase.NormalizeZoneShape(zone)
        local mergedZone = copyDeep(zone)
        local incomingZone = findIncomingZone(normalizedIncomingZones, zone)

        if incomingZone then
            local incomingSlots = RealBase.GetAreaSlots(incomingZone)
            if tostring(mergedZone.zoneKind or "") == "base" then
                local expectedSlot = mergedZone.areaSlots[1]
                local incomingSlot = findIncomingSlot(incomingZone, expectedSlot) or incomingSlots[1]
                expectedSlot.rect = incomingSlot and copyDeep(incomingSlot.rect) or nil
            elseif tostring(mergedZone.zoneKind or "") == "buildingType"
                or tostring(mergedZone.zoneKind or "") == "jobType" then
                for _, expectedSlot in ipairs(mergedZone.areaSlots or {}) do
                    local incomingSlot = findIncomingSlot(incomingZone, expectedSlot)
                    expectedSlot.rect = incomingSlot and copyDeep(incomingSlot.rect) or nil
                end
            else
                mergedZone = DC_ZoneData.normalizeZone(copyDeep(incomingZone), resolvedColonyId, #mergedZones + 1, usedZoneIDs)
            end
        elseif not isManagedZone(mergedZone) then
            mergedZone = nil
        end

        if mergedZone then
            RealBase.NormalizeZoneShape(mergedZone)
            usedZoneIDs[tostring(mergedZone.id or "")] = true
            mergedZones[#mergedZones + 1] = mergedZone
        end
    end

    for index, incomingZone in ipairs(normalizedIncomingZones) do
        if not isManagedZone(incomingZone) and not usedZoneIDs[tostring(incomingZone.id or "")] then
            local mergedZone = DC_ZoneData.normalizeZone(copyDeep(incomingZone), resolvedColonyId, #mergedZones + index, usedZoneIDs)
            if mergedZone then
                RealBase.NormalizeZoneShape(mergedZone)
                usedZoneIDs[tostring(mergedZone.id or "")] = true
                mergedZones[#mergedZones + 1] = mergedZone
            end
        end
    end

    return mergedZones
end

return RealBase
