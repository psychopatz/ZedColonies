DT_Labour = DT_Labour or {}
DT_Labour.Config = DT_Labour.Config or {}
DT_Labour.Config.Internal = DT_Labour.Config.Internal or {}

local Config = DT_Labour.Config
local Internal = Config.Internal

function Internal.AppendUniqueValues(target, values)
    target = type(target) == "table" and target or {}
    local seen = {}
    for _, existing in ipairs(target) do
        seen[existing] = true
    end

    for _, value in ipairs(values or {}) do
        if value and not seen[value] then
            target[#target + 1] = value
            seen[value] = true
        end
    end

    return target
end

function Internal.CloneProfileTable(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            local child = {}
            for index, childValue in ipairs(value) do
                child[index] = childValue
            end
            copy[key] = child
        else
            copy[key] = value
        end
    end
    return copy
end

function Internal.ExtendScavengeProfile(profile, values)
    if not values then
        return profile
    end

    profile.labourTags = Internal.AppendUniqueValues(profile.labourTags, values.labourTags)
    profile.capabilities = Internal.AppendUniqueValues(profile.capabilities, values.capabilities)
    profile.tier = math.max(tonumber(profile.tier) or 0, tonumber(values.tier) or 0)
    profile.haulBonus = math.max(tonumber(profile.haulBonus) or 0, tonumber(values.haulBonus) or 0)
    profile.routePlanning = math.max(tonumber(profile.routePlanning) or 0, tonumber(values.routePlanning) or 0)

    local speed = tonumber(values.searchSpeedMultiplier)
    if speed and speed > 0 then
        profile.searchSpeedMultiplier = math.max(tonumber(profile.searchSpeedMultiplier) or 0, speed)
    end

    return profile
end

function Internal.HasTableEntries(value)
    if type(value) ~= "table" then
        return false
    end

    for _, _ in pairs(value) do
        return true
    end

    return false
end

return Config
