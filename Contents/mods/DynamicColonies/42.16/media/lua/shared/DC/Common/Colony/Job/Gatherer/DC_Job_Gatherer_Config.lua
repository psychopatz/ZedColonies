DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}
DC_Colony.Gatherer = DC_Colony.Gatherer or {}

local Config = DC_Colony.Config
local Gatherer = DC_Colony.Gatherer

Gatherer.Resources = Gatherer.Resources or {}
Gatherer.ResourceOrder = Gatherer.ResourceOrder or {}
Gatherer.RequirementKeys = Gatherer.RequirementKeys or {
    Axe = "Gatherer.Tool.Axe",
    Pickaxe = "Gatherer.Tool.Pickaxe",
    Sack = "Gatherer.Tool.Sack",
    FluidContainer = "Gatherer.Tool.FluidContainer",
}

Config.GathererDefaults = Config.GathererDefaults or {}
Config.GathererDefaults.woodSlowMultiplier = 0.40
Config.GathererDefaults.stoneSlowMultiplier = 0.30

local EXACT_PICKAXE_TYPES = {
    ["Base.PickAxe"] = true,
    ["Base.PickAxeForged"] = true,
}
local AXE_TAG = "Weapon.Melee.Axe"
local SACK_TAG = "Container.Bag.Sack"
local FLUID_CONTAINER_TAG = "Container.Liquid"

local function getResources()
    return DC_Colony and DC_Colony.Resources or nil
end

local function copyTable(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            copy[key] = copyTable(value)
        else
            copy[key] = value
        end
    end
    return copy
end

local function addResourceOrder(id)
    for _, existing in ipairs(Gatherer.ResourceOrder) do
        if existing == id then
            return
        end
    end
    Gatherer.ResourceOrder[#Gatherer.ResourceOrder + 1] = id
end

function Gatherer.RegisterResource(def)
    if type(def) ~= "table" or not def.id then
        return false
    end

    local id = tostring(def.id)
    if id == "" then
        return false
    end

    local normalized = copyTable(def)
    normalized.id = id
    normalized.label = tostring(normalized.label or id)
    normalized.skillID = tostring(normalized.skillID or "Construction")
    normalized.outputRules = type(normalized.outputRules) == "table" and normalized.outputRules or {}
    normalized.enabled = normalized.enabled ~= false
    normalized.weight = math.max(1, tonumber(normalized.weight) or 1)

    Gatherer.Resources[id] = normalized
    addResourceOrder(id)
    return true
end

function Gatherer.GetResource(id)
    return Gatherer.Resources[tostring(id or "")]
end

function Gatherer.GetResourceList()
    local list = {}
    for _, id in ipairs(Gatherer.ResourceOrder or {}) do
        local def = Gatherer.Resources[id]
        if def and def.enabled ~= false then
            list[#list + 1] = copyTable(def)
        end
    end
    return list
end

local function getConfigSource(workerOrConfig)
    if type(workerOrConfig) ~= "table" then
        return {}
    end
    if type(workerOrConfig.gathererConfig) == "table" then
        return workerOrConfig.gathererConfig
    end
    return workerOrConfig
end

function Gatherer.NormalizeConfig(workerOrConfig)
    local source = getConfigSource(workerOrConfig)
    local selectedSource = type(source.selectedResources) == "table" and source.selectedResources or {}
    local selected = {}
    local selectedCount = 0

    for _, id in ipairs(Gatherer.ResourceOrder or {}) do
        local def = Gatherer.Resources[id]
        if def and def.enabled ~= false and selectedSource[id] == true then
            selected[id] = true
            selectedCount = selectedCount + 1
        end
    end

    if selectedCount <= 0 then
        for _, id in ipairs(Gatherer.ResourceOrder or {}) do
            local def = Gatherer.Resources[id]
            if def and def.enabled ~= false then
                selected[id] = true
                selectedCount = selectedCount + 1
            end
        end
    end

    return {
        selectedResources = selected,
        selectedCount = selectedCount
    }
end

function Gatherer.GetSelectedResourceList(workerOrConfig)
    local normalized = Gatherer.NormalizeConfig(workerOrConfig)
    local list = {}
    for _, id in ipairs(Gatherer.ResourceOrder or {}) do
        if normalized.selectedResources[id] == true then
            local def = Gatherer.Resources[id]
            if def and def.enabled ~= false then
                list[#list + 1] = def
            end
        end
    end
    return list
end

function Gatherer.GetPrimarySkillID(workerOrConfig)
    local selected = Gatherer.GetSelectedResourceList(workerOrConfig)
    if #selected >= 1 and selected[1].skillID then
        return selected[1].skillID
    end
    return "Plants"
end

function Gatherer.GetResourceSkillID(resourceID)
    local def = Gatherer.GetResource(resourceID)
    return tostring(def and def.skillID or "Plants")
end

function Gatherer.GetSelectionLabel(workerOrConfig)
    local labels = {}
    for _, def in ipairs(Gatherer.GetSelectedResourceList(workerOrConfig)) do
        labels[#labels + 1] = tostring(def.label or def.id)
    end
    if #labels <= 0 then
        return "Nothing"
    end
    return table.concat(labels, ", ")
end

local function entryHasTag(entry, tag)
    if type(entry) ~= "table" then
        return false
    end

    local tags = entry.tags
        or (Config.GetItemCombinedTags and Config.GetItemCombinedTags(entry.fullType))
        or {}
    for _, itemTag in ipairs(tags or {}) do
        local itemKey = tostring(itemTag or "")
        if itemKey == tostring(tag or "") then
            return true
        end
        if Config.TagMatches and Config.TagMatches(itemKey, tag) then
            return true
        end
    end

    return false
end

local function getFluidCapacityForFullType(fullType)
    local key = tostring(fullType or "")
    if key == "" or not getScriptManager then
        return 0
    end

    local scriptItem = getScriptManager():getItem(key)
    local fluidContainer = scriptItem and scriptItem.getFluidContainer and scriptItem:getFluidContainer() or nil
    if not fluidContainer or not fluidContainer.getCapacity then
        return 0
    end

    return math.max(0, tonumber(fluidContainer:getCapacity()) or 0)
end

local function getUsableEntry(entry)
    local registryInternal = DC_Colony and DC_Colony.Registry and DC_Colony.Registry.Internal or nil
    if not registryInternal or not registryInternal.NormalizeEquipmentEntry then
        return entry
    end

    local normalized = registryInternal.NormalizeEquipmentEntry(entry)
    if registryInternal.IsEquipmentEntryUsable and not registryInternal.IsEquipmentEntryUsable(normalized) then
        return nil
    end
    return normalized
end

local function buildResourceState(id, label, loadout, selected)
    if selected ~= true then
        return {
            id = id,
            label = label,
            selected = false,
            runnable = false,
            blocked = false,
            slow = false,
            speedMultiplier = 0,
            statusText = "Not selected",
        }
    end

    if id == "wood" then
        local hasTool = loadout.hasAxe == true
        return {
            id = id,
            label = label,
            selected = true,
            runnable = true,
            blocked = false,
            slow = hasTool ~= true,
            speedMultiplier = hasTool and 1 or math.max(0.01, tonumber((Config.GathererDefaults or {}).woodSlowMultiplier) or 0.20),
            statusText = hasTool and "Axe equipped" or "No axe - gathers much slower",
        }
    end

    if id == "stone" then
        local hasFullKit = loadout.hasPickaxe == true and loadout.hasSack == true
        return {
            id = id,
            label = label,
            selected = true,
            runnable = true,
            blocked = false,
            slow = hasFullKit ~= true,
            speedMultiplier = hasFullKit and 1 or math.max(0.01, tonumber((Config.GathererDefaults or {}).stoneSlowMultiplier) or 0.15),
            statusText = hasFullKit and "Pickaxe and sack equipped" or "Missing pickaxe or sack - gathers much slower",
        }
    end

    if id == "water" then
        local containerCount = math.max(0, tonumber(loadout.waterContainerCount) or 0)
        local freeCapacity = math.max(0, tonumber(loadout.waterCollectableCapacity) or 0)
        local storageCapacity = math.max(0, tonumber(loadout.waterStorageCapacity) or 0)
        local storageAvailable = math.max(0, tonumber(loadout.waterStorageAvailable) or 0)
        local blockedReason = nil
        if storageCapacity <= 0 then
            blockedReason = "Needs built water storage"
        elseif storageAvailable <= 0 then
            blockedReason = "Colony water storage is full"
        elseif containerCount <= 0 then
            blockedReason = "Needs at least 1 fluid container"
        elseif freeCapacity <= 0 then
            blockedReason = "Assigned containers are full or already reserved"
        end
        return {
            id = id,
            label = label,
            selected = true,
            runnable = blockedReason == nil,
            blocked = blockedReason ~= nil,
            slow = false,
            speedMultiplier = blockedReason == nil and 1 or 0,
            statusText = blockedReason or ("Water capacity ready: " .. tostring(math.floor(freeCapacity + 0.5))),
        }
    end

    return {
        id = id,
        label = label,
        selected = true,
        runnable = false,
        blocked = true,
        slow = false,
        speedMultiplier = 0,
        statusText = "Unavailable",
    }
end

function Gatherer.GetFluidContainerCapacityForFullType(fullType)
    return getFluidCapacityForFullType(fullType)
end

function Gatherer.GetFluidContainerCapacity(entry)
    if type(entry) ~= "table" then
        return 0
    end

    if tonumber(entry.fluidCapacity) then
        return math.max(0, tonumber(entry.fluidCapacity) or 0)
    end

    return getFluidCapacityForFullType(entry.fullType)
end

function Gatherer.GetWaterStorageState(workerOrOwner)
    local ownerUsername = type(workerOrOwner) == "table" and workerOrOwner.ownerUsername or workerOrOwner
    local resources = getResources()
    if not resources or not resources.GetWaterCapacity or not resources.EnsureOwner then
        return {
            capacity = 0,
            stored = 0,
            available = 0,
        }
    end

    local capacity = math.max(0, tonumber(resources.GetWaterCapacity(ownerUsername)) or 0)
    local ownerData = resources.EnsureOwner(ownerUsername)
    local stored = math.max(0, math.min(capacity, tonumber(ownerData and ownerData.waterStored) or 0))
    return {
        capacity = capacity,
        stored = stored,
        available = math.max(0, capacity - stored),
    }
end

function Gatherer.GetLoadout(worker)
    local normalizedConfig = Gatherer.NormalizeConfig(worker)
    local waterCarryAmount = math.max(0, tonumber(worker and worker.gathererWaterCarryAmount) or 0)
    local waterStorage = Gatherer.GetWaterStorageState(worker)
    local result = {
        hasAxe = false,
        hasPickaxe = false,
        hasSack = false,
        waterContainers = {},
        waterContainerCount = 0,
        waterCapacity = 0,
        waterFreeCapacity = 0,
        waterCarryAmount = waterCarryAmount,
        waterStorageCapacity = math.max(0, tonumber(waterStorage.capacity) or 0),
        waterStorageStored = math.max(0, tonumber(waterStorage.stored) or 0),
        waterStorageAvailable = math.max(0, tonumber(waterStorage.available) or 0),
        waterCollectableCapacity = 0,
        selectedResources = copyTable(normalizedConfig.selectedResources),
        resourceStates = {},
        runnableResourceIDs = {},
        blockedResourceIDs = {},
        slowResourceIDs = {},
    }

    local usableFluidContainers = {}
    for _, rawEntry in ipairs(worker and worker.toolLedger or {}) do
        local entry = getUsableEntry(rawEntry)
        if entry then
            if entryHasTag(entry, AXE_TAG) then
                result.hasAxe = true
            end
            if EXACT_PICKAXE_TYPES[tostring(entry.fullType or "")] == true then
                result.hasPickaxe = true
            end
            if entryHasTag(entry, SACK_TAG) then
                result.hasSack = true
            end
            if entryHasTag(entry, FLUID_CONTAINER_TAG) then
                local fluidCapacity = math.max(0, tonumber(entry.fluidCapacity) or getFluidCapacityForFullType(entry.fullType))
                if fluidCapacity > 0 then
                    local fluidAmount = math.max(0, tonumber(entry.fluidAmount) or 0)
                    usableFluidContainers[#usableFluidContainers + 1] = {
                        entryID = entry.entryID,
                        fullType = entry.fullType,
                        displayName = entry.displayName,
                        fluidAmount = fluidAmount,
                        fluidCapacity = fluidCapacity,
                        freeCapacity = math.max(0, fluidCapacity - fluidAmount),
                    }
                end
            end
        end
    end

    table.sort(usableFluidContainers, function(a, b)
        local freeA = math.max(0, tonumber(a and a.freeCapacity) or 0)
        local freeB = math.max(0, tonumber(b and b.freeCapacity) or 0)
        if freeA == freeB then
            local capA = math.max(0, tonumber(a and a.fluidCapacity) or 0)
            local capB = math.max(0, tonumber(b and b.fluidCapacity) or 0)
            if capA == capB then
                return tostring(a and a.displayName or a and a.fullType or "")
                    < tostring(b and b.displayName or b and b.fullType or "")
            end
            return capA > capB
        end
        return freeA > freeB
    end)

    result.waterContainerCount = #usableFluidContainers
    for index = 1, result.waterContainerCount do
        local entry = usableFluidContainers[index]
        result.waterContainers[#result.waterContainers + 1] = entry
        result.waterCapacity = result.waterCapacity + math.max(0, tonumber(entry.fluidCapacity) or 0)
        result.waterFreeCapacity = result.waterFreeCapacity + math.max(0, tonumber(entry.freeCapacity) or 0)
    end
    result.waterCollectableCapacity = math.max(
        0,
        math.min(
            math.max(0, result.waterFreeCapacity),
            math.max(0, result.waterStorageAvailable - waterCarryAmount)
        )
    )

    for _, def in ipairs(Gatherer.GetResourceList()) do
        local state = buildResourceState(def.id, tostring(def.label or def.id), result, normalizedConfig.selectedResources[def.id] == true)
        result.resourceStates[def.id] = state
        if state.runnable then
            result.runnableResourceIDs[#result.runnableResourceIDs + 1] = def.id
        elseif state.selected == true and state.blocked == true then
            result.blockedResourceIDs[#result.blockedResourceIDs + 1] = def.id
        end
        if state.selected == true and state.slow == true then
            result.slowResourceIDs[#result.slowResourceIDs + 1] = def.id
        end
    end

    return result
end

function Gatherer.GetRequirementStatus(worker, requirementKey)
    local loadout = Gatherer.GetLoadout(worker)
    local selectedResources = loadout.selectedResources or {}
    local targetKey = tostring(requirementKey or "")
    if targetKey == tostring((Gatherer.RequirementKeys or {}).Axe or "") then
        local relevant = selectedResources.wood == true
        return {
            relevant = relevant,
            currentCount = loadout.hasAxe and 1 or 0,
            minimumCount = 0,
            targetCount = relevant and 1 or 0,
            blocking = false,
            statusText = loadout.hasAxe and "Full speed for wood" or "Wood still works without an axe, but much slower.",
        }
    end
    if targetKey == tostring((Gatherer.RequirementKeys or {}).Pickaxe or "") then
        local relevant = selectedResources.stone == true
        return {
            relevant = relevant,
            currentCount = loadout.hasPickaxe and 1 or 0,
            minimumCount = 0,
            targetCount = relevant and 1 or 0,
            blocking = false,
            statusText = loadout.hasPickaxe and "Stone kit partly ready" or "Stone still works without a pickaxe, but much slower.",
        }
    end
    if targetKey == tostring((Gatherer.RequirementKeys or {}).Sack or "") then
        local relevant = selectedResources.stone == true
        return {
            relevant = relevant,
            currentCount = loadout.hasSack and 1 or 0,
            minimumCount = 0,
            targetCount = relevant and 1 or 0,
            blocking = false,
            statusText = loadout.hasSack and "Stone kit partly ready" or "Stone still works without a sack, but much slower.",
        }
    end
    if targetKey == tostring((Gatherer.RequirementKeys or {}).FluidContainer or "") then
        local relevant = selectedResources.water == true
        local currentCount = math.max(0, tonumber(loadout.waterContainerCount) or 0)
        local targetCount = currentCount > 0 and currentCount or 1
        local freeCapacity = math.max(0, tonumber(loadout.waterCollectableCapacity) or 0)
        local storageCapacity = math.max(0, tonumber(loadout.waterStorageCapacity) or 0)
        local storageAvailable = math.max(0, tonumber(loadout.waterStorageAvailable) or 0)
        local statusText = "At least 1 is required for water. All assigned fluid containers can be used."
        if storageCapacity <= 0 then
            statusText = "Needs a built water collector or water tank."
        elseif storageAvailable <= 0 then
            statusText = "Colony water storage is full."
        elseif currentCount > 0 then
            statusText = "Water capacity ready: " .. tostring(math.floor(freeCapacity + 0.5))
        end
        if storageCapacity <= 0 then
            statusText = "Needs a built water collector or water tank."
        elseif storageAvailable <= 0 then
            statusText = "Colony water storage is full."
        elseif currentCount <= 0 then
            statusText = "Needs at least 1 fluid container to gather water."
        elseif freeCapacity <= 0 then
            statusText = "Assigned fluid containers are full or already reserved."
        end
        return {
            relevant = relevant,
            currentCount = currentCount,
            minimumCount = relevant and 1 or 0,
            targetCount = relevant and targetCount or 0,
            blocking = relevant and currentCount <= 0,
            statusText = statusText,
        }
    end

    return {
        relevant = false,
        currentCount = 0,
        minimumCount = 0,
        targetCount = 0,
        blocking = false,
        statusText = "",
    }
end

Gatherer.RegisterResource({
    id = "wood",
    label = "Wood",
    description = "Logs, planks, and rough timber. Faster with an axe, but still possible without one.",
    skillID = "Plants",
    stockpileResource = "materials",
    stockpilePerQty = 1,
    outputRules = {
        { fullTypes = { "Base.Log", "Base.LargePlank", "Base.Twigs" }, minQty = 1, maxQty = 2 }
    }
})

Gatherer.RegisterResource({
    id = "stone",
    label = "Stone",
    description = "Stone, clay, and gravel. Fastest with both a pickaxe and sack, but still possible without them.",
    skillID = "Mining",
    stockpileResource = "materials",
    stockpilePerQty = 1,
    outputRules = {
        { fullTypes = { "Base.LargeStone", "Base.FlatStone", "Base.Clay", "Base.Gravelbag" }, minQty = 1, maxQty = 2 }
    }
})

Gatherer.RegisterResource({
    id = "water",
    label = "Water",
    description = "Collected clean water. Needs fluid containers, built colony water storage, and free storage capacity. Uses all assigned containers the worker can carry.",
    skillID = "Intellectual",
    stockpileResource = "water",
    stockpilePerQty = 1,
    waterPerQty = 120,
    outputRules = {
        { fullTypes = { "Base.WaterBottle", "Base.WaterRationCan", "Base.WaterDispenserBottle" }, minQty = 1, maxQty = 1 }
    }
})

Config.JobTypes = Config.JobTypes or {}
Config.JobTypes.Gatherer = Config.JobTypes.Gatherer or "Gatherer"

Config.JobProfiles = Config.JobProfiles or {}
Config.JobProfiles.Gatherer = Config.JobProfiles.Gatherer or {}
Config.JobProfiles.Gatherer.jobType = Config.JobTypes.Gatherer
Config.JobProfiles.Gatherer.displayName = Config.JobProfiles.Gatherer.displayName or "Gatherer"
Config.JobProfiles.Gatherer.siteType = nil
Config.JobProfiles.Gatherer.requiredToolTags = {}
Config.JobProfiles.Gatherer.cycleHours = 6
Config.JobProfiles.Gatherer.dailyCaloriesNeed = 2200
Config.JobProfiles.Gatherer.dailyHydrationNeed = 1800
Config.JobProfiles.Gatherer.outputRules = Config.JobProfiles.Gatherer.outputRules or {}

Config.ArchetypeJobBonuses = Config.ArchetypeJobBonuses or {}
Config.ArchetypeJobBonuses.Scavenger = Config.ArchetypeJobBonuses.Scavenger or {}
Config.ArchetypeJobBonuses.Scavenger[Config.JobTypes.Gatherer] = Config.ArchetypeJobBonuses.Scavenger[Config.JobTypes.Gatherer] or 1.15

Config.ArchetypeCarryWeight = Config.ArchetypeCarryWeight or {}
Config.ArchetypeCarryWeight.Scavenger = Config.ArchetypeCarryWeight.Scavenger or 10

return Gatherer
