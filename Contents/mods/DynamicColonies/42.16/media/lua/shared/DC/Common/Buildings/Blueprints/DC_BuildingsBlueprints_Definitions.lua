DC_Buildings = DC_Buildings or {}
DC_Buildings.Blueprints = DC_Buildings.Blueprints or {}
DC_Buildings.Blueprints.Internal = DC_Buildings.Blueprints.Internal or {}

local Buildings = DC_Buildings
local Blueprints = Buildings.Blueprints
local Internal = Blueprints.Internal

Internal.Definitions = Internal.Definitions or {}

local function buildKey(buildingType, mode)
    return table.concat({
        tostring(buildingType or ""),
        tostring(mode or "build"),
    }, ":")
end

local function shallowCopy(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

local function registerDefinition(definition)
    if type(definition) ~= "table" then
        return
    end

    local buildingType = tostring(definition.buildingType or "")
    local mode = tostring(definition.mode or "build")
    if buildingType == "" then
        return
    end

    Internal.Definitions[buildKey(buildingType, mode)] = shallowCopy(definition)
end

function Blueprints.GetDefinition(buildingType, mode)
    return Internal.Definitions[buildKey(buildingType, mode)]
end

function Blueprints.IsBlueprintAction(buildingType, mode)
    return Blueprints.GetDefinition(buildingType, mode) ~= nil
end

Buildings.GetBlueprintDefinition = Blueprints.GetDefinition
Buildings.IsBlueprintAction = Blueprints.IsBlueprintAction

return Blueprints
