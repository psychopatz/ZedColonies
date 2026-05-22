DC_Colony = DC_Colony or {}
DC_Colony.Woodcut = DC_Colony.Woodcut or {}

require "DC/Common/Zone/RealBase/DC_ZoneRealBase"
require "DC/Common/Zone/DC_ZoneDataStore"

local Woodcut = DC_Colony.Woodcut

Woodcut.STATE_VERSION = Woodcut.STATE_VERSION or 1
Woodcut.DEFAULT_SCAN_STALE_MS = Woodcut.DEFAULT_SCAN_STALE_MS or 8000
Woodcut.CLAIM_TIMEOUT_MS = Woodcut.CLAIM_TIMEOUT_MS or 25000
Woodcut.COLLECTED_PRUNE_MS = Woodcut.COLLECTED_PRUNE_MS or 300000
Woodcut.MAX_BUCKET_SAMPLES = Woodcut.MAX_BUCKET_SAMPLES or 6

local function floorNumber(value, fallback)
    if tonumber(value) == nil then
        return fallback
    end
    return math.floor(tonumber(value) or 0)
end

local function nowMillis()
    return getTimeInMillis and getTimeInMillis() or 0
end

local function copyArray(values)
    local result = {}
    for index, value in ipairs(values or {}) do
        result[index] = value
    end
    return result
end

local function copyBundle(bundle)
    local result = {}
    for index, entry in ipairs(bundle or {}) do
        if type(entry) == "table" and entry.fullType then
            result[#result + 1] = {
                fullType = tostring(entry.fullType),
                displayName = entry.displayName and tostring(entry.displayName) or nil,
                qty = math.max(1, floorNumber(entry.qty, 1) or 1),
            }
        end
    end
    return result
end

local function buildTreeKey(x, y, z)
    return tostring(floorNumber(x, 0) or 0)
        .. ":"
        .. tostring(floorNumber(y, 0) or 0)
        .. ":"
        .. tostring(floorNumber(z, 0) or 0)
end

local function buildBucketKey(size, logYield)
    return tostring(math.max(1, floorNumber(size, 1) or 1))
        .. "|"
        .. tostring(math.max(1, floorNumber(logYield, 1) or 1))
end

local function hashString(text)
    local value = 0
    local stringValue = tostring(text or "")
    local index = nil
    for index = 1, #stringValue do
        value = ((value * 131) + string.byte(stringValue, index)) % 2147483647
    end
    return value
end

local function hashChance(text)
    return (hashString(text) % 1000) / 1000
end

local function normalizeOwner(ownerUsername)
    local config = DC_Colony and DC_Colony.Config or nil
    if config and config.GetOwnerUsername then
        return tostring(config.GetOwnerUsername(ownerUsername))
    end
    return tostring(ownerUsername or "")
end

local function normalizeZoneState(zone, state)
    local zoneID = tostring(zone and zone.id or "")
    local colonyID = tostring(zone and zone.colonyId or "")
    local ownerUsername = normalizeOwner(zone and zone.ownerUsername or "")
    state = type(state) == "table" and state or {}
    state.version = math.max(1, floorNumber(state.version, Woodcut.STATE_VERSION) or Woodcut.STATE_VERSION)
    state.zoneID = zoneID
    state.colonyID = colonyID
    state.ownerUsername = ownerUsername
    state.lastScanAt = math.max(0, floorNumber(state.lastScanAt, 0) or 0)
    state.lastScanZoneRevision = tostring(state.lastScanZoneRevision or "")
    state.knownTreeCount = math.max(0, floorNumber(state.knownTreeCount, 0) or 0)
    state.remainingKnownTreeCount = math.max(0, floorNumber(state.remainingKnownTreeCount, state.knownTreeCount) or state.knownTreeCount)
    state.unresolvedTileCount = math.max(0, floorNumber(state.unresolvedTileCount, 0) or 0)
    state.isExactCount = state.isExactCount == true
    state.treesByKey = type(state.treesByKey) == "table" and state.treesByKey or {}
    state.dropSamplesByBucket = type(state.dropSamplesByBucket) == "table" and state.dropSamplesByBucket or {}
    state.unresolvedTiles = type(state.unresolvedTiles) == "table" and state.unresolvedTiles or {}
    return state
end

local function getRectRevision(zone)
    local slots = DC_ZoneRealBase and DC_ZoneRealBase.GetAreaSlots and DC_ZoneRealBase.GetAreaSlots(zone) or {}
    local parts = {}
    for _, slot in ipairs(slots or {}) do
        local rect = slot and slot.rect or nil
        if type(rect) == "table" then
            parts[#parts + 1] = table.concat({
                floorNumber(rect[1], 0) or 0,
                floorNumber(rect[2], 0) or 0,
                floorNumber(rect[3], 0) or 0,
                floorNumber(rect[4], 0) or 0,
                floorNumber(rect[5], 0) or 0,
            }, ":")
        end
    end
    return table.concat(parts, "|")
end

local function isWoodcutZone(zone)
    if type(zone) ~= "table" then
        return false
    end
    return tostring(zone.zoneType or "") == "woodcut" or tostring(zone.jobType or "") == "ChopTrees"
end

local function getZoneForWorker(worker)
    if not worker or not DC_ZoneRealBase or not DC_ZoneRealBase.GetZonesForOwner or not DC_ZoneRealBase.FindJobTypeZone then
        return nil
    end
    local owner = normalizeOwner(worker.ownerUsername)
    local zones = DC_ZoneRealBase.GetZonesForOwner(owner) or {}
    return DC_ZoneRealBase.FindJobTypeZone(zones, "ChopTrees")
end

local function findZoneByID(ownerUsername, zoneID)
    if not DC_ZoneRealBase or not DC_ZoneRealBase.GetZonesForOwner then
        return nil
    end
    local zones = DC_ZoneRealBase.GetZonesForOwner(normalizeOwner(ownerUsername)) or {}
    local targetID = tostring(zoneID or "")
    for _, zone in ipairs(zones) do
        if tostring(zone and zone.id or "") == targetID then
            return zone
        end
    end
    return nil
end

local function recountState(zoneState)
    local knownTreeCount = 0
    local remainingKnownTreeCount = 0
    for _, record in pairs(zoneState.treesByKey or {}) do
        if type(record) == "table" and record.synthetic ~= true and record.discovered == true then
            knownTreeCount = knownTreeCount + 1
            if tostring(record.state or "standing") ~= "collected" then
                remainingKnownTreeCount = remainingKnownTreeCount + 1
            end
        end
    end
    zoneState.knownTreeCount = knownTreeCount
    zoneState.remainingKnownTreeCount = remainingKnownTreeCount
end

local function clearExpiredClaims(zoneState, workerID)
    local now = nowMillis()
    for _, record in pairs(zoneState.treesByKey or {}) do
        if type(record) == "table" and tostring(record.state or "") == "claimed" then
            local claimedAt = math.max(0, floorNumber(record.claimedAt, 0) or 0)
            local expired = claimedAt <= 0 or (now - claimedAt) >= Woodcut.CLAIM_TIMEOUT_MS
            if expired or (workerID ~= nil and tostring(record.claimedByWorkerID or "") == tostring(workerID)) then
                record.state = tostring(record.state or "") == "collected" and "collected" or "standing"
                record.claimedByWorkerID = nil
                record.claimedAt = nil
            end
        end
    end
end

local function getCellSquare(x, y, z)
    local cell = getCell and getCell() or nil
    if not cell then
        return nil
    end
    return cell:getGridSquare(floorNumber(x, 0) or 0, floorNumber(y, 0) or 0, floorNumber(z, 0) or 0)
end

local function chooseSyntheticDescriptor(zoneState, treeKey)
    local samples = zoneState.dropSamplesByBucket or {}
    local buckets = {}
    local totalWeight = 0
    local bucketKey = nil
    for bucketKey, entries in pairs(samples) do
        local count = type(entries) == "table" and #entries or 0
        if count > 0 then
            totalWeight = totalWeight + count
            buckets[#buckets + 1] = {
                key = tostring(bucketKey),
                weight = count,
            }
        end
    end

    local roll = hashChance(tostring(zoneState.zoneID or "") .. "|" .. tostring(treeKey))
    local descriptorKey = nil
    if totalWeight > 0 and #buckets > 0 then
        local threshold = roll * totalWeight
        local running = 0
        for _, bucket in ipairs(buckets) do
            running = running + bucket.weight
            if threshold <= running then
                descriptorKey = bucket.key
                break
            end
        end
    end

    if not descriptorKey then
        if roll < 0.25 then
            descriptorKey = "2|1"
        elseif roll < 0.75 then
            descriptorKey = "4|2"
        else
            descriptorKey = "6|3"
        end
    end

    local separator = string.find(descriptorKey, "|", 1, true)
    local size = 2
    local logYield = 1
    if separator then
        size = math.max(1, floorNumber(string.sub(descriptorKey, 1, separator - 1), 2) or 2)
        logYield = math.max(1, floorNumber(string.sub(descriptorKey, separator + 1), 1) or 1)
    end
    return size, logYield
end

local function buildFallbackBundle(treeRecord, seedKey)
    local result = {}
    local size = math.max(1, floorNumber(treeRecord and treeRecord.size, 2) or 2)
    local logYield = math.max(1, floorNumber(treeRecord and treeRecord.logYield, 1) or 1)

    result[#result + 1] = {
        fullType = "Base.Log",
        qty = logYield <= 1 and 1 or logYield,
    }

    if logYield <= 1 then
        result[#result + 1] = {
            fullType = "Base.TreeBranch",
            qty = 1,
        }
    elseif logYield == 2 then
        result[#result + 1] = {
            fullType = "Base.TreeBranch",
            qty = 1,
        }
        result[#result + 1] = {
            fullType = "Base.UnusableWood",
            qty = 1,
        }
    else
        result[#result + 1] = {
            fullType = "Base.TreeBranch",
            qty = 2,
        }
        result[#result + 1] = {
            fullType = "Base.UnusableWood",
            qty = 2,
        }
    end

    if size >= 5 and hashChance(seedKey .. "|branch") < 0.30 then
        result[#result + 1] = {
            fullType = "Base.TreeBranch",
            qty = 1,
        }
    end
    if size >= 6 and hashChance(seedKey .. "|waste") < 0.30 then
        result[#result + 1] = {
            fullType = "Base.UnusableWood",
            qty = 1,
        }
    end

    return result
end

local function mergeBundleEntries(bundle)
    local merged = {}
    local byKey = {}
    for _, entry in ipairs(bundle or {}) do
        if type(entry) == "table" and entry.fullType then
            local fullType = tostring(entry.fullType)
            local key = fullType .. "|" .. tostring(entry.displayName or "")
            local existing = byKey[key]
            if not existing then
                existing = {
                    fullType = fullType,
                    displayName = entry.displayName and tostring(entry.displayName) or nil,
                    qty = 0,
                }
                byKey[key] = existing
                merged[#merged + 1] = existing
            end
            existing.qty = existing.qty + math.max(1, floorNumber(entry.qty, 1) or 1)
        end
    end
    return merged
end

function Woodcut.GetOrCreateZoneState(ownerUsername, zone)
    if not isWoodcutZone(zone) then
        return nil
    end

    if type(zone.woodcutState) ~= "table" then
        zone.woodcutState = {}
    end
    zone.woodcutState.ownerUsername = normalizeOwner(ownerUsername or zone.ownerUsername)
    zone.woodcutState = normalizeZoneState(zone, zone.woodcutState)
    return zone.woodcutState
end

function Woodcut.IsZoneStateStale(zone, zoneState, maxAgeMs)
    if not isWoodcutZone(zone) then
        return false
    end
    local state = normalizeZoneState(zone, zoneState or zone.woodcutState)
    local targetAge = math.max(1000, floorNumber(maxAgeMs, Woodcut.DEFAULT_SCAN_STALE_MS) or Woodcut.DEFAULT_SCAN_STALE_MS)
    if state.lastScanAt <= 0 then
        return true
    end
    if tostring(state.lastScanZoneRevision or "") ~= getRectRevision(zone) then
        return true
    end
    return (nowMillis() - state.lastScanAt) >= targetAge
end

function Woodcut.RefreshLoadedScan(ownerUsername, zone, options)
    if not isWoodcutZone(zone) then
        return nil
    end

    options = type(options) == "table" and options or {}
    local state = Woodcut.GetOrCreateZoneState(ownerUsername, zone)
    if not state then
        return nil
    end

    local force = options.force == true
    if not force and not Woodcut.IsZoneStateStale(zone, state, options.maxAgeMs) then
        return state
    end

    clearExpiredClaims(state)

    local cell = getCell and getCell() or nil
    local unresolvedTiles = {}
    local seenLoaded = {}
    local totalTiles = 0
    local resolvedTiles = 0
    local now = nowMillis()
    local slots = DC_ZoneRealBase and DC_ZoneRealBase.GetAreaSlots and DC_ZoneRealBase.GetAreaSlots(zone) or {}

    for _, slot in ipairs(slots or {}) do
        local rect = slot and slot.rect or nil
        if type(rect) == "table" then
            local z = floorNumber(rect[5], 0) or 0
            local y = nil
            local x = nil
            for y = floorNumber(rect[2], 0) or 0, floorNumber(rect[4], -1) or -1 do
                for x = floorNumber(rect[1], 0) or 0, floorNumber(rect[3], -1) or -1 do
                    totalTiles = totalTiles + 1
                    local key = buildTreeKey(x, y, z)
                    local square = cell and cell:getGridSquare(x, y, z) or nil
                    if square then
                        resolvedTiles = resolvedTiles + 1
                        local tree = square.getTree and square:getTree() or nil
                        if tree then
                            seenLoaded[key] = true
                            local record = state.treesByKey[key]
                            if type(record) ~= "table" then
                                record = {
                                    x = x,
                                    y = y,
                                    z = z,
                                }
                                state.treesByKey[key] = record
                            end
                            record.x = x
                            record.y = y
                            record.z = z
                            record.synthetic = nil
                            record.discovered = true
                            record.lastSeenAt = now
                            record.size = math.max(1, floorNumber(tree.getSize and tree:getSize() or record.size, 2) or 2)
                            record.logYield = math.max(1, floorNumber(tree.getLogYield and tree:getLogYield() or record.logYield, 1) or 1)
                            record.bucketKey = buildBucketKey(record.size, record.logYield)
                            if tostring(record.state or "") ~= "collected" and tostring(record.state or "") ~= "claimed" then
                                record.state = "standing"
                            end
                        else
                            local record = state.treesByKey[key]
                            if type(record) == "table" and tostring(record.state or "") ~= "collected" then
                                record.state = "collected"
                                record.claimedByWorkerID = nil
                                record.claimedAt = nil
                                record.collectedAt = record.collectedAt or now
                            end
                        end
                    else
                        unresolvedTiles[#unresolvedTiles + 1] = {
                            x = x,
                            y = y,
                            z = z,
                            key = key,
                        }
                    end
                end
            end
        end
    end

    local key = nil
    for key, record in pairs(state.treesByKey or {}) do
        if type(record) == "table" then
            local stateName = tostring(record.state or "standing")
            if stateName == "collected" then
                local collectedAt = math.max(0, floorNumber(record.collectedAt, 0) or 0)
                if collectedAt > 0 and (now - collectedAt) > Woodcut.COLLECTED_PRUNE_MS then
                    state.treesByKey[key] = nil
                end
            elseif record.discovered == true and record.synthetic ~= true and seenLoaded[key] ~= true then
                local square = getCellSquare(record.x, record.y, record.z)
                if square then
                    state.treesByKey[key].state = "collected"
                    state.treesByKey[key].claimedByWorkerID = nil
                    state.treesByKey[key].claimedAt = nil
                    state.treesByKey[key].collectedAt = now
                end
            end
        end
    end

    state.unresolvedTiles = unresolvedTiles
    state.unresolvedTileCount = #unresolvedTiles
    state.isExactCount = totalTiles > 0 and resolvedTiles >= totalTiles
    state.lastScanAt = now
    state.lastScanZoneRevision = getRectRevision(zone)
    recountState(state)
    return state
end

function Woodcut.ReleaseClaim(zoneState, treeKey, reason)
    if type(zoneState) ~= "table" then
        return false
    end
    local record = zoneState.treesByKey and zoneState.treesByKey[tostring(treeKey or "")] or nil
    if type(record) ~= "table" then
        return false
    end
    if tostring(record.state or "") ~= "collected" then
        record.state = "standing"
    end
    record.claimedByWorkerID = nil
    record.claimedAt = nil
    record.releaseReason = reason and tostring(reason) or nil
    recountState(zoneState)
    return true
end

function Woodcut.MarkCollected(zoneState, treeKey, bundle, sourceMode)
    if type(zoneState) ~= "table" then
        return nil
    end

    local normalizedKey = tostring(treeKey or "")
    local record = zoneState.treesByKey and zoneState.treesByKey[normalizedKey] or nil
    if type(record) ~= "table" then
        return nil
    end

    record.state = "collected"
    record.claimedByWorkerID = nil
    record.claimedAt = nil
    record.collectedAt = nowMillis()
    record.sourceMode = sourceMode and tostring(sourceMode) or nil

    local normalizedBundle = mergeBundleEntries(copyBundle(bundle))
    local bucketKey = tostring(record.bucketKey or buildBucketKey(record.size, record.logYield))
    record.bucketKey = bucketKey
    if #normalizedBundle > 0 then
        zoneState.dropSamplesByBucket[bucketKey] = zoneState.dropSamplesByBucket[bucketKey] or {}
        local samples = zoneState.dropSamplesByBucket[bucketKey]
        samples[#samples + 1] = {
            bundle = normalizedBundle,
            collectedAt = record.collectedAt,
        }
        while #samples > Woodcut.MAX_BUCKET_SAMPLES do
            table.remove(samples, 1)
        end
    end

    zoneState.lastScanAt = 0
    recountState(zoneState)
    return record
end

function Woodcut.BuildAbstractBundle(zoneState, treeRecord, worker)
    local record = type(treeRecord) == "table" and treeRecord or {}
    local bucketKey = tostring(record.bucketKey or buildBucketKey(record.size, record.logYield))
    local seedKey = tostring(zoneState and zoneState.zoneID or "")
        .. "|"
        .. tostring(worker and worker.workerID or "")
        .. "|"
        .. tostring(record.treeKey or buildTreeKey(record.x, record.y, record.z))

    local samples = zoneState and zoneState.dropSamplesByBucket and zoneState.dropSamplesByBucket[bucketKey] or nil
    if type(samples) == "table" and #samples > 0 then
        local index = (hashString(seedKey) % #samples) + 1
        local sample = samples[index]
        if type(sample) == "table" and type(sample.bundle) == "table" and #sample.bundle > 0 then
            return copyBundle(sample.bundle)
        end
    end

    return mergeBundleEntries(buildFallbackBundle(record, seedKey))
end

function Woodcut.ClaimNextTree(worker, options)
    options = type(options) == "table" and options or {}
    local zone = type(options.zone) == "table" and options.zone or getZoneForWorker(worker)
    if not zone then
        return nil
    end

    local state = Woodcut.GetOrCreateZoneState(worker and worker.ownerUsername or zone.ownerUsername, zone)
    if not state then
        return nil
    end

    if options.forceRefresh == true or Woodcut.IsZoneStateStale(zone, state, options.maxAgeMs) then
        Woodcut.RefreshLoadedScan(worker and worker.ownerUsername or zone.ownerUsername, zone, {
            force = options.forceRefresh == true,
            maxAgeMs = options.maxAgeMs,
        })
    end

    local workerID = worker and worker.workerID or nil
    clearExpiredClaims(state)

    if workerID ~= nil and worker.chopTreesClaimKey then
        local existingKey = tostring(worker.chopTreesClaimKey)
        local existing = state.treesByKey and state.treesByKey[existingKey] or nil
        if type(existing) == "table" and tostring(existing.state or "") == "claimed"
            and tostring(existing.claimedByWorkerID or "") == tostring(workerID) then
            return {
                zone = zone,
                zoneState = state,
                treeKey = existingKey,
                tree = existing,
            }
        end
    end

    local requireLoaded = options.requireLoaded == true
    local anchorX = tonumber(options.anchorX)
    local anchorY = tonumber(options.anchorY)
    local bestKey = nil
    local bestRecord = nil
    local bestScore = nil
    local key = nil

    for key, record in pairs(state.treesByKey or {}) do
        if type(record) == "table" and tostring(record.state or "standing") == "standing" then
            if not requireLoaded or record.synthetic ~= true then
                local score = 0
                if anchorX ~= nil and anchorY ~= nil then
                    local dx = (tonumber(record.x) or anchorX) - anchorX
                    local dy = (tonumber(record.y) or anchorY) - anchorY
                    score = (dx * dx) + (dy * dy)
                elseif record.synthetic == true then
                    score = 1000000
                end
                if bestScore == nil or score < bestScore then
                    bestScore = score
                    bestKey = key
                    bestRecord = record
                end
            end
        end
    end

    if not bestRecord and requireLoaded ~= true then
        for _, tile in ipairs(state.unresolvedTiles or {}) do
            local syntheticKey = tostring(tile and tile.key or "")
            if syntheticKey ~= "" then
                local existing = state.treesByKey[syntheticKey]
                if existing == nil then
                    local size, logYield = chooseSyntheticDescriptor(state, syntheticKey)
                    existing = {
                        x = floorNumber(tile.x, 0) or 0,
                        y = floorNumber(tile.y, 0) or 0,
                        z = floorNumber(tile.z, 0) or 0,
                        synthetic = true,
                        discovered = false,
                        size = size,
                        logYield = logYield,
                        bucketKey = buildBucketKey(size, logYield),
                        state = "standing",
                    }
                    state.treesByKey[syntheticKey] = existing
                end

                if tostring(existing.state or "standing") == "standing" then
                    bestKey = syntheticKey
                    bestRecord = existing
                    break
                end
            end
        end
    end

    if not bestRecord or not bestKey then
        recountState(state)
        return nil
    end

    bestRecord.state = "claimed"
    bestRecord.claimedByWorkerID = workerID
    bestRecord.claimedAt = nowMillis()
    bestRecord.sourceMode = options.sourceMode and tostring(options.sourceMode) or nil
    bestRecord.treeKey = bestKey
    recountState(state)

    if type(worker) == "table" then
        worker.chopTreesClaimKey = bestKey
        worker.chopTreesMode = options.sourceMode and tostring(options.sourceMode) or worker.chopTreesMode
        worker.chopTreesCoverageText = Woodcut.GetCoverageText(state)
    end

    return {
        zone = zone,
        zoneState = state,
        treeKey = bestKey,
        tree = bestRecord,
    }
end

function Woodcut.GetCoverageText(zoneState)
    if type(zoneState) ~= "table" or math.max(0, floorNumber(zoneState.lastScanAt, 0) or 0) <= 0 then
        return "Trees ?"
    end

    local remainingKnown = math.max(0, floorNumber(zoneState.remainingKnownTreeCount, zoneState.knownTreeCount) or 0)
    if zoneState.isExactCount == true then
        return "Trees " .. tostring(remainingKnown)
    end

    if remainingKnown > 0 then
        return "Trees " .. tostring(remainingKnown) .. " + ?"
    end

    return "Trees ?"
end

function Woodcut.FindZoneByID(ownerUsername, zoneID)
    return findZoneByID(ownerUsername, zoneID)
end

return Woodcut
