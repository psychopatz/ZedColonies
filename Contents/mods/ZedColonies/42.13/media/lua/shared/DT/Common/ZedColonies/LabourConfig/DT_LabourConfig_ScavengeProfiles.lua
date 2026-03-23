DT_Labour = DT_Labour or {}
DT_Labour.Config = DT_Labour.Config or {}
DT_Labour.Config.Internal = DT_Labour.Config.Internal or {}

local Config = DT_Labour.Config
local Internal = Config.Internal

function Config.GetScavengeItemProfile(fullType)
    if not fullType or fullType == "" then
        return nil
    end

    local profile = Internal.CloneProfileTable(Config.ScavengeItemProfiles[fullType] or {})
    local tags = Config.FindItemTags(fullType)
    local defaults = Config.ScavengeLootDefaults or {}

    if Config.HasMatchingTag(tags, "Container.Bag.Backpack") then
        Internal.ExtendScavengeProfile(profile, {
            labourTags = { "Labour.Tool.Scavenge", "Scavenge.Haul.Bag" },
            capabilities = { "Scavenge.Haul.Bag" },
            haulBonus = Config.HasMatchingTag(tags, "Container.WeightReduction.High") and 2 or 1
        })
    elseif Config.HasMatchingTag(tags, "Container.Bag.Duffel") then
        Internal.ExtendScavengeProfile(profile, {
            labourTags = { "Labour.Tool.Scavenge", "Scavenge.Haul.Bag" },
            capabilities = { "Scavenge.Haul.Bag" },
            haulBonus = 1
        })
    end

    if Config.HasMatchingTag(tags, "Electronics.Light") or Config.HasMatchingTag(tags, "Electronics.LightSource") then
        Internal.ExtendScavengeProfile(profile, {
            labourTags = { "Labour.Tool.Scavenge", "Scavenge.Utility.Light" },
            capabilities = { "Scavenge.Utility.Light" },
            searchSpeedMultiplier = defaults.litSearchSpeedMultiplier or 1.0
        })
    end

    if Config.HasMatchingTag(tags, "Literature.Media") then
        Internal.ExtendScavengeProfile(profile, {
            labourTags = { "Labour.Tool.Scavenge", "Scavenge.Utility.Map" },
            capabilities = { "Scavenge.Utility.Map" },
            routePlanning = 1
        })
    end

    if not Internal.HasTableEntries(profile) then
        return nil
    end

    return profile
end

function Config.GetItemCombinedTags(fullType)
    local tags = Internal.AppendUniqueValues({}, Config.FindItemTags(fullType))
    local scavengeProfile = Config.GetScavengeItemProfile(fullType)
    if scavengeProfile and scavengeProfile.labourTags then
        Internal.AppendUniqueValues(tags, scavengeProfile.labourTags)
    end
    if DT_Buildings and DT_Buildings.Config and DT_Buildings.Config.GetBuilderToolTags then
        Internal.AppendUniqueValues(tags, DT_Buildings.Config.GetBuilderToolTags(fullType))
    end
    return tags
end

function Config.IsLabourToolFullType(fullType)
    if not fullType or fullType == "" then
        return false
    end

    local tags = Config.FindItemTags(fullType)
    if Config.HasMatchingTag(tags, "Tool") then
        return true
    end
    if DT_Buildings and DT_Buildings.Config and DT_Buildings.Config.IsBuilderToolFullType
        and DT_Buildings.Config.IsBuilderToolFullType(fullType) then
        return true
    end

    return Config.GetScavengeItemProfile(fullType) ~= nil
end

return Config
