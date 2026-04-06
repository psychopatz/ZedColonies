DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

Config.MedicalProvisionUnitValues = Config.MedicalProvisionUnitValues or {
    ["Base.Bandage"] = 1,
    ["Base.BandageBox"] = 4,
    ["Base.AlcoholBandage"] = 1,
    ["Base.RippedSheets"] = 1,
    ["Base.AlcoholRippedSheets"] = 1,
    ["Base.Bandaid"] = 1,
    ["Base.CottonBalls"] = 1,
    ["Base.CottonBallsBox"] = 4,
    ["Base.AlcoholWipes"] = 1,
    ["Base.AlcoholedCottonBalls"] = 1,
    ["Base.Disinfectant"] = 1,
}

function Config.NormalizeUnitValue(value)
    if not value then return 0 end
    value = tonumber(value) or 0
    if math.abs(value) > 1.0 then
        return value / 100.0
    end
    return value
end

function Config.RandomRangeInclusive(minValue, maxValue)
    local minNumber = math.floor(tonumber(minValue) or 0)
    local maxNumber = math.floor(tonumber(maxValue) or minNumber)
    if maxNumber < minNumber then
        minNumber, maxNumber = maxNumber, minNumber
    end

    local span = (maxNumber - minNumber) + 1
    if span <= 1 then
        return minNumber
    end

    return minNumber + ZombRand(span)
end

function Config.TagMatches(itemTag, queryTag)
    if not itemTag or not queryTag then return false end
    if itemTag == queryTag then return true end
    return string.find(itemTag, queryTag .. "%.") == 1
end

function Config.HasMatchingTag(tagList, queryTag)
    if type(tagList) ~= "table" then return false end
    for _, itemTag in ipairs(tagList) do
        if Config.TagMatches(itemTag, queryTag) then
            return true
        end
    end
    return false
end

function Config.FindItemTags(fullType)
    local masterList = DynamicTrading
        and DynamicTrading.Config
        and DynamicTrading.Config.MasterList or nil

    local entry = masterList and masterList[fullType] or nil
    if entry and type(entry.tags) == "table" then
        return entry.tags
    end

    return {}
end

function Config.IsMedicalProvisionFullType(fullType)
    return Config.MedicalProvisionUnitValues[tostring(fullType or "")] ~= nil
end

function Config.GetMedicalProvisionUnits(fullType)
    return math.max(0, tonumber(Config.MedicalProvisionUnitValues[tostring(fullType or "")]) or 0)
end

function Config.IsNutritionProvisionEntry(entry)
    return type(entry) == "table" and tostring(entry.provisionType or "nutrition") == "nutrition"
end

function Config.IsMedicalProvisionEntry(entry)
    return type(entry) == "table" and tostring(entry.provisionType or "") == "medical"
end

return Config
