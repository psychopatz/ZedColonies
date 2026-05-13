DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Config = Buildings.Config
local Internal = Buildings.Internal

function Buildings.GetBuildingInstallCount(instance, installKey)
    if type(instance) ~= "table" then
        return 0
    end
    Internal.NormalizeInstallCounts(instance)
    return math.max(0, math.floor(tonumber(instance.installs[tostring(installKey or "")]) or 0))
end

function Buildings.SetBuildingInstallCount(instance, installKey, count)
    if type(instance) ~= "table" then
        return 0
    end
    Internal.NormalizeInstallCounts(instance)
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
    Internal.NormalizeInstallCounts(instance)
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