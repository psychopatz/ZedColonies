DT_Buildings = DT_Buildings or {}
DT_Buildings.Internal = DT_Buildings.Internal or {}

local Config = DT_Buildings.Config
local Buildings = DT_Buildings
local Internal = Buildings.Internal

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

local function ensureArray(value)
    return type(value) == "table" and value or {}
end

local function normalizeInstallCounts(instance)
    instance.installs = type(instance.installs) == "table" and instance.installs or {}
    for _, definition in ipairs(Config.GetInstallDefinitionList and Config.GetInstallDefinitionList(instance.buildingType) or {}) do
        local installKey = tostring(definition and definition.installKey or "")
        if installKey ~= "" then
            local maxCount = Config.GetInstallMaxCount and Config.GetInstallMaxCount(instance.buildingType, installKey, instance.level)
                or math.floor(tonumber(definition and definition.maxCount) or 0)
            instance.installs[installKey] = math.min(
                math.max(0, math.floor(tonumber(instance.installs[installKey]) or 0)),
                math.max(0, math.floor(tonumber(maxCount) or 0))
            )
        end
    end
end

local function normalizeBuildingInstance(instance)
    if type(instance) ~= "table" then
        return instance
    end

    instance.buildingType = tostring(instance.buildingType or "")
    instance.level = math.max(0, math.floor(tonumber(instance.level) or 0))
    instance.plotX = math.floor(tonumber(instance.plotX) or 0)
    instance.plotY = math.floor(tonumber(instance.plotY) or 0)
    normalizeInstallCounts(instance)
    return instance
end

local function findUsedPlotKeys(ownerData)
    local used = {}
    for _, instance in ipairs(ownerData.buildings or {}) do
        if instance.plotX ~= nil and instance.plotY ~= nil then
            used[Buildings.GetPlotKey(instance.plotX, instance.plotY)] = true
        end
    end
    return used
end

local function migrateLegacyPlots(ownerData)
    local mapData = Buildings.EnsureMapData(ownerData)
    local used = findUsedPlotKeys(ownerData)
    local standardCandidates = {}
    local maxLegacyRing = 0

    for ring = 1, 6 do
        for _, cell in ipairs(Buildings.GetRingCoordinates(ring)) do
            standardCandidates[#standardCandidates + 1] = cell
        end
    end

    local candidateIndex = 1
    local function nextStandardCell()
        while standardCandidates[candidateIndex] do
            local cell = standardCandidates[candidateIndex]
            candidateIndex = candidateIndex + 1
            local key = Buildings.GetPlotKey(cell.x, cell.y)
            if not used[key] then
                used[key] = true
                return cell
            end
        end
        return nil
    end

    for _, instance in ipairs(ownerData.buildings or {}) do
        local hasCoords = instance.plotX ~= nil and instance.plotY ~= nil
        if hasCoords then
            local px = math.floor(tonumber(instance.plotX) or 0)
            local py = math.floor(tonumber(instance.plotY) or 0)
            instance.plotX = px
            instance.plotY = py
            local kind = (px == 0 and py == 0) and Buildings.MapConstants.PlotKinds.HQOnly or Buildings.MapConstants.PlotKinds.Standard
            Internal.UnlockPlotInMap(mapData, px, py, kind)
            maxLegacyRing = math.max(maxLegacyRing, math.max(math.abs(px), math.abs(py)))
        elseif tostring(instance.buildingType or "") == "Headquarters" then
            instance.plotX = 0
            instance.plotY = 0
            Internal.UnlockPlotInMap(mapData, 0, 0, Buildings.MapConstants.PlotKinds.HQOnly)
        else
            local cell = nextStandardCell()
            if cell then
                instance.plotX = cell.x
                instance.plotY = cell.y
                maxLegacyRing = math.max(maxLegacyRing, math.max(math.abs(cell.x), math.abs(cell.y)))
                Internal.UnlockPlotInMap(mapData, cell.x, cell.y, Buildings.MapConstants.PlotKinds.Standard)
            end
        end
    end

    if maxLegacyRing > 0 then
        for ring = 1, maxLegacyRing do
            for _, cell in ipairs(Buildings.GetRingCoordinates(ring)) do
                Internal.UnlockPlotInMap(mapData, cell.x, cell.y, Buildings.MapConstants.PlotKinds.Standard)
            end
        end
        mapData.currentRing = math.max(mapData.currentRing, maxLegacyRing + 1)
        mapData.nextUnlockDirection = "Left"
    end
end

Internal.CopyDeep = copyDeep
Internal.EnsureArray = ensureArray
Internal.NormalizeBuildingInstance = normalizeBuildingInstance

function Buildings.Init()
    if not ModData.exists(Config.MOD_DATA_KEY) then
        ModData.add(Config.MOD_DATA_KEY, {
            Owners = {},
            Counters = { building = 0, project = 0 }
        })
    end

    local data = ModData.get(Config.MOD_DATA_KEY)
    data.Owners = data.Owners or {}
    data.Counters = data.Counters or { building = 0, project = 0 }
end

Events.OnInitGlobalModData.Add(Buildings.Init)

function Buildings.GetData()
    if not ModData.exists(Config.MOD_DATA_KEY) then
        Buildings.Init()
    end
    return ModData.get(Config.MOD_DATA_KEY)
end

function Buildings.Save()
    if GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
end

function Buildings.NextID(kind)
    local data = Buildings.GetData()
    local key = kind == "building" and "building" or "project"
    data.Counters[key] = (data.Counters[key] or 0) + 1
    return data.Counters[key]
end

function Buildings.EnsureOwner(ownerUsername)
    local owner = DT_Labour and DT_Labour.Config and DT_Labour.Config.GetOwnerUsername
        and DT_Labour.Config.GetOwnerUsername(ownerUsername)
        or tostring(ownerUsername or "local")
    local data = Buildings.GetData()
    if not data.Owners[owner] then
        data.Owners[owner] = {
            ownerUsername = owner,
            buildings = {},
            projects = {},
            map = nil
        }
    end

    local ownerData = data.Owners[owner]
    ownerData.ownerUsername = owner
    ownerData.buildings = ensureArray(ownerData.buildings)
    for _, instance in ipairs(ownerData.buildings) do
        normalizeBuildingInstance(instance)
    end
    ownerData.projects = type(ownerData.projects) == "table" and ownerData.projects or {}
    Buildings.EnsureMapData(ownerData)
    migrateLegacyPlots(ownerData)
    return ownerData
end

function Buildings.GetBuildingsForOwner(ownerUsername)
    return Buildings.EnsureOwner(ownerUsername).buildings
end

function Buildings.GetProjectsForOwner(ownerUsername)
    return Buildings.EnsureOwner(ownerUsername).projects
end

function Buildings.CreateBuildingInstance(ownerUsername, buildingType, level, plotX, plotY)
    local ownerData = Buildings.EnsureOwner(ownerUsername)
    local instance = {
        buildingID = "building_" .. tostring(Buildings.NextID("building")),
        buildingType = tostring(buildingType or ""),
        level = math.max(0, math.floor(tonumber(level) or 0)),
        plotX = math.floor(tonumber(plotX) or 0),
        plotY = math.floor(tonumber(plotY) or 0),
        installs = {}
    }
    normalizeBuildingInstance(instance)
    ownerData.buildings[#ownerData.buildings + 1] = instance
    return instance
end

function Buildings.FindBuildingForOwner(ownerUsername, buildingID)
    for _, instance in ipairs(Buildings.GetBuildingsForOwner(ownerUsername)) do
        if instance.buildingID == buildingID then
            return instance
        end
    end
    return nil
end

function Buildings.FindBuildingAtPlot(ownerUsername, plotX, plotY)
    local wantedX = math.floor(tonumber(plotX) or 0)
    local wantedY = math.floor(tonumber(plotY) or 0)
    for _, instance in ipairs(Buildings.GetBuildingsForOwner(ownerUsername)) do
        if math.floor(tonumber(instance.plotX) or 0) == wantedX and math.floor(tonumber(instance.plotY) or 0) == wantedY then
            return instance
        end
    end
    return nil
end

function Buildings.CopyOwnerData(ownerUsername)
    return copyDeep(Buildings.EnsureOwner(ownerUsername))
end

function Buildings.GetPlotRing(plotX, plotY)
    local x = math.abs(math.floor(tonumber(plotX) or 0))
    local y = math.abs(math.floor(tonumber(plotY) or 0))
    return math.max(x, y)
end

function Buildings.GetBuildingInstallCount(instance, installKey)
    if type(instance) ~= "table" then
        return 0
    end
    normalizeInstallCounts(instance)
    return math.max(0, math.floor(tonumber(instance.installs[tostring(installKey or "")]) or 0))
end

function Buildings.SetBuildingInstallCount(instance, installKey, count)
    if type(instance) ~= "table" then
        return 0
    end
    normalizeInstallCounts(instance)
    local normalizedKey = tostring(installKey or "")
    local safeCount = math.max(0, math.floor(tonumber(count) or 0))
    local maxCount = Config.GetInstallMaxCount and Config.GetInstallMaxCount(instance.buildingType, normalizedKey, instance.level) or nil
    if maxCount ~= nil then
        safeCount = math.min(safeCount, math.max(0, math.floor(tonumber(maxCount) or 0)))
    end
    instance.installs[normalizedKey] = safeCount
    return instance.installs[normalizedKey]
end

function Buildings.GetBuildingInstallCounts(instance)
    local counts = {}
    if type(instance) ~= "table" then
        return counts
    end
    normalizeInstallCounts(instance)
    for _, definition in ipairs(Config.GetInstallDefinitionList and Config.GetInstallDefinitionList(instance.buildingType) or {}) do
        local installKey = tostring(definition and definition.installKey or "")
        if installKey ~= "" then
            counts[installKey] = Buildings.GetBuildingInstallCount(instance, installKey)
        end
    end
    return counts
end

function Buildings.GetWarehouseBuildingCapacityContribution(instance)
    if not instance or tostring(instance.buildingType or "") ~= "Warehouse" then
        return 0
    end

    local total = 0
    local levelDefinition = Config.GetLevelDefinition("Warehouse", instance.level)
    total = total + math.max(0, math.floor(tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.warehouseBaseBonus) or 0))

    for _, definition in ipairs(Config.GetInstallDefinitionList and Config.GetInstallDefinitionList("Warehouse") or {}) do
        local count = Buildings.GetBuildingInstallCount(instance, definition.installKey)
        local perInstall = math.max(0, math.floor(tonumber(definition and definition.effects and definition.effects.warehouseCapacityBonus) or 0))
        total = total + (count * perInstall)
    end

    return total
end

return Buildings
