DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}
DC_Colony.Gatherer = DC_Colony.Gatherer or {}

local Config = DC_Colony.Config
local Gatherer = DC_Colony.Gatherer

Gatherer.Resources = Gatherer.Resources or {}
Gatherer.ResourceOrder = Gatherer.ResourceOrder or {}

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
    if #selected == 1 and selected[1].skillID then
        return selected[1].skillID
    end
    return "Construction"
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

Gatherer.RegisterResource({
    id = "wood",
    label = "Wood",
    description = "Logs, planks, and rough timber for construction work.",
    skillID = "Construction",
    stockpileResource = "materials",
    stockpilePerQty = 1,
    outputRules = {
        { fullTypes = { "Base.Log", "Base.LargePlank", "Base.Twigs" }, minQty = 1, maxQty = 2 }
    }
})

Gatherer.RegisterResource({
    id = "stone",
    label = "Stone",
    description = "Stone, clay, gravel, and mineral chunks for workshop projects.",
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
    description = "Collected clean water for storage, provisions, and greenhouse support.",
    skillID = "Survivalist",
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
Config.JobProfiles.Gatherer = Config.JobProfiles.Gatherer or {
    jobType = Config.JobTypes.Gatherer,
    displayName = "Gatherer",
    siteType = nil,
    requiredToolTags = {},
    cycleHours = 18,
    dailyCaloriesNeed = 2200,
    dailyHydrationNeed = 1800,
    outputRules = {}
}

Config.ArchetypeJobBonuses = Config.ArchetypeJobBonuses or {}
Config.ArchetypeJobBonuses.Scavenger = Config.ArchetypeJobBonuses.Scavenger or {}
Config.ArchetypeJobBonuses.Scavenger[Config.JobTypes.Gatherer] = Config.ArchetypeJobBonuses.Scavenger[Config.JobTypes.Gatherer] or 1.15

Config.ArchetypeCarryWeight = Config.ArchetypeCarryWeight or {}
Config.ArchetypeCarryWeight.Scavenger = Config.ArchetypeCarryWeight.Scavenger or 10

return Gatherer
