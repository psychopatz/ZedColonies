DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

local function appendUniqueStrings(target, values)
    target = type(target) == "table" and target or {}

    local seen = {}
    for _, existing in ipairs(target) do
        local key = tostring(existing or "")
        if key ~= "" then
            seen[key] = true
        end
    end

    for _, value in ipairs(values or {}) do
        local key = tostring(value or "")
        if key ~= "" and not seen[key] then
            target[#target + 1] = key
            seen[key] = true
        end
    end

    return target
end

local function cloneStringArray(values)
    return appendUniqueStrings({}, values)
end

Config.EquipmentRequirementDefinitions = Config.EquipmentRequirementDefinitions or {
    ["Builder.Tool.Hammer"] = {
        label = "Hammer",
        hintText = "Hammer or ball-peen hammer",
        reasonText = "Needed so the builder can make progress on hammer-based construction work.",
        searchText = "builder hammer ball peen club hammer",
        supportedFullTypes = { "Base.Hammer", "Base.BallPeenHammer", "Base.ClubHammer" },
        iconFullType = "Base.Hammer",
        jobTypes = { "Builder" },
        autoEquip = true,
        sortOrder = 100,
    },
    ["Builder.Tool.Saw"] = {
        label = "Saw",
        hintText = "Saw or garden saw",
        reasonText = "Needed so the builder can cut lumber and complete wood construction tasks.",
        searchText = "builder saw garden saw small saw crude saw",
        supportedFullTypes = { "Base.Saw", "Base.GardenSaw", "Base.SmallSaw", "Base.CrudeSaw" },
        iconFullType = "Base.Saw",
        jobTypes = { "Builder" },
        autoEquip = true,
        sortOrder = 110,
    },
    ["Tool.Farming"] = {
        label = "Farming Tool",
        hintText = "Hoe, trowel, or hand fork",
        reasonText = "Needed so the worker can tend plots and complete farming cycles.",
        searchText = "farming hoe trowel hand fork hand shovel",
        supportedFullTypes = { "Base.GardenHoe", "Base.Trowel", "Base.HandFork", "Base.HandShovel" },
        iconFullType = "Base.Trowel",
        jobTypes = { "Farm" },
        autoEquip = true,
        sortOrder = 120,
    },
    ["Tool.Fishing"] = {
        label = "Fishing Gear",
        hintText = "Fishing rod or spear",
        reasonText = "Needed so the worker can fish instead of idling at the site.",
        searchText = "fishing rod spear tackle",
        supportedFullTypes = { "Base.FishingRod", "Base.CraftedFishingRod", "Base.FishingSpear" },
        iconFullType = "Base.FishingRod",
        jobTypes = { "Fish" },
        autoEquip = true,
        sortOrder = 130,
    },
    ["Colony.Tool.Scavenge"] = {
        label = "Scavenging Tool",
        hintText = "Any scavenging loadout item",
        reasonText = "Baseline loadout item used to unlock scavenging work and scavenger-specific upgrades.",
        searchText = "scavenge scavenging tool loadout",
        supportedFullTypes = {},
        iconFullType = "Base.Crowbar",
        jobTypes = { "Scavenge" },
        autoEquip = true,
        sortOrder = 200,
    },
    ["Scavenge.Access.LockedHome"] = {
        label = "Prying Item",
        hintText = "Crowbar or screwdriver",
        reasonText = "Lets the scavenger force entry into locked homes and other basic closed locations.",
        searchText = "crowbar screwdriver pry prying locked home",
        supportedFullTypes = { "Base.Crowbar", "Base.CrowbarForged", "Base.Screwdriver" },
        iconFullType = "Base.Crowbar",
        jobTypes = { "Scavenge" },
        autoEquip = false,
        sortOrder = 210,
    },
    ["Scavenge.Haul.Bag"] = {
        label = "Backpack",
        hintText = "Backpack or duffel bag",
        reasonText = "Adds a carry container so the scavenger can haul more loot before needing to come home.",
        searchText = "backpack duffel bag hauling",
        supportedFullTypes = { "Base.Bag_Schoolbag", "Base.Bag_DuffelBag", "Base.Bag_ToolBag" },
        iconFullType = "Base.Bag_Schoolbag",
        jobTypes = { "Scavenge" },
        autoEquip = true,
        sortOrder = 220,
    },
    ["Scavenge.Utility.Light"] = {
        label = "Lightsource",
        hintText = "Flashlight or other light source",
        reasonText = "Reduces dark-area penalties so the scavenger can search interiors more effectively.",
        searchText = "flashlight lightsource light torch lamp",
        supportedFullTypes = { "Base.HandTorch", "Base.FlashLight_AngleHead", "Base.PenLight" },
        iconFullType = "Base.HandTorch",
        jobTypes = { "Scavenge" },
        autoEquip = false,
        sortOrder = 230,
    },
    ["Scavenge.Utility.Map"] = {
        label = "Map",
        hintText = "Map or route-planning literature",
        reasonText = "Helps plan routes and supports faster, more efficient scavenging runs.",
        searchText = "map route plan literature",
        supportedFullTypes = { "Base.Map", "Base.MuldraughMap", "Base.WestpointMap" },
        iconFullType = "Base.Map",
        jobTypes = { "Scavenge" },
        autoEquip = false,
        sortOrder = 240,
    },
    ["Scavenge.Utility.Pen"] = {
        label = "Pen",
        hintText = "Any pen for route notes",
        reasonText = "Works with maps for route notes, improving the scavenger's planning loadout.",
        searchText = "pen route notes",
        supportedFullTypes = { "Base.Pen", "Base.BluePen", "Base.RedPen" },
        iconFullType = "Base.Pen",
        jobTypes = { "Scavenge" },
        autoEquip = false,
        sortOrder = 250,
    },
    ["Scavenge.Access.ElectronicStore"] = {
        label = "Electronics Access Tool",
        hintText = "Screwdriver",
        reasonText = "Needed to open electronics-heavy locations and unlock electronics store scavenging pools.",
        searchText = "electronics access screwdriver store",
        supportedFullTypes = { "Base.Screwdriver", "Base.Screwdriver_Old", "Base.Screwdriver_Improvised" },
        iconFullType = "Base.Screwdriver",
        jobTypes = { "Scavenge" },
        autoEquip = false,
        sortOrder = 260,
    },
    ["Scavenge.Extraction.CarpentryHammer"] = {
        label = "Hammer",
        hintText = "Hammer or ball-peen hammer",
        reasonText = "Allows carpentry extraction and stripping when salvaging wooden fixtures and furniture.",
        searchText = "hammer ball peen carpentry",
        supportedFullTypes = { "Base.Hammer", "Base.BallPeenHammer", "Base.ClubHammer" },
        iconFullType = "Base.Hammer",
        jobTypes = { "Scavenge" },
        autoEquip = false,
        sortOrder = 270,
    },
    ["Scavenge.Extraction.CarpentrySaw"] = {
        label = "Saw",
        hintText = "Saw or garden saw",
        reasonText = "Pairs with a hammer for carpentry stripping and salvage-focused scavenging.",
        searchText = "saw garden saw carpentry",
        supportedFullTypes = { "Base.Saw", "Base.SmallSaw", "Base.GardenSaw", "Base.CrudeSaw" },
        iconFullType = "Base.Saw",
        jobTypes = { "Scavenge" },
        autoEquip = false,
        sortOrder = 280,
    },
    ["Scavenge.Extraction.Plumbing"] = {
        label = "Pipe Wrench",
        hintText = "Pipe wrench",
        reasonText = "Required to extract plumbing-related loot and salvage plumbing fixtures.",
        searchText = "pipe wrench plumbing",
        supportedFullTypes = { "Base.PipeWrench" },
        iconFullType = "Base.PipeWrench",
        jobTypes = { "Scavenge" },
        autoEquip = false,
        sortOrder = 290,
    },
    ["Scavenge.Extraction.MetalTorch"] = {
        label = "Metal Torch",
        hintText = "Blow torch",
        reasonText = "Needed for metal salvage jobs and advanced industrial stripping.",
        searchText = "blow torch metal torch welding",
        supportedFullTypes = { "Base.BlowTorch" },
        iconFullType = "Base.BlowTorch",
        jobTypes = { "Scavenge" },
        autoEquip = false,
        sortOrder = 300,
    },
    ["Scavenge.Extraction.MetalMask"] = {
        label = "Welding Mask",
        hintText = "Welding mask",
        reasonText = "Needed with a blow torch so the scavenger can safely perform metal salvage work.",
        searchText = "welding mask metal",
        supportedFullTypes = { "Base.WeldingMask" },
        iconFullType = "Base.WeldingMask",
        jobTypes = { "Scavenge" },
        autoEquip = false,
        sortOrder = 310,
    },
    ["Scavenge.Access.HeavyEntry"] = {
        label = "Heavy Entry Tool",
        hintText = "Sledgehammer",
        reasonText = "Breaks secure shutters and heavy barriers, unlocking the toughest scavenging entries.",
        searchText = "sledgehammer heavy entry secure shutters vaults",
        supportedFullTypes = { "Base.Sledgehammer", "Base.Sledgehammer2", "Base.SledgehammerForged" },
        iconFullType = "Base.Sledgehammer",
        jobTypes = { "Scavenge" },
        autoEquip = false,
        sortOrder = 320,
    },
    ["Scavenge.Haul.Bulk"] = {
        label = "Bulk Sack",
        hintText = "Garbage bag or sandbag",
        reasonText = "Supports carrying bulky loose loot that otherwise gets left behind.",
        searchText = "garbage bag sandbag bulk sack",
        supportedFullTypes = { "Base.Garbagebag", "Base.EmptySandbag" },
        iconFullType = "Base.Garbagebag",
        jobTypes = { "Scavenge" },
        autoEquip = false,
        sortOrder = 330,
    },
    ["Scavenge.Haul.Bundle"] = {
        label = "Bundle Rope",
        hintText = "Sheet rope",
        reasonText = "Lets the scavenger bundle heavy items together for transport.",
        searchText = "sheet rope bundle heavy",
        supportedFullTypes = { "Base.SheetRope", "Base.SheetRopeBundle" },
        iconFullType = "Base.SheetRope",
        jobTypes = { "Scavenge" },
        autoEquip = false,
        sortOrder = 340,
    },
}

local function isDefinitionRelevantToJob(definition, normalizedJobType)
    if not normalizedJobType then
        return true
    end

    local jobTypes = type(definition) == "table" and definition.jobTypes or nil
    if type(jobTypes) ~= "table" or #jobTypes <= 0 then
        return false
    end

    for _, jobType in ipairs(jobTypes) do
        if Config.NormalizeJobType(jobType) == normalizedJobType then
            return true
        end
    end

    return false
end

local function collectKnownEquipmentFullTypes()
    local fullTypes = {}

    for _, definition in pairs(Config.EquipmentRequirementDefinitions or {}) do
        appendUniqueStrings(fullTypes, definition and definition.supportedFullTypes or nil)
        if definition and definition.iconFullType then
            appendUniqueStrings(fullTypes, { definition.iconFullType })
        end
    end

    for fullType, _ in pairs(Config.ScavengeItemProfiles or {}) do
        appendUniqueStrings(fullTypes, { fullType })
    end

    local builderToolFullTypes = DC_Buildings and DC_Buildings.Config and DC_Buildings.Config.BuilderToolFullTypes or nil
    for fullType, _ in pairs(builderToolFullTypes or {}) do
        appendUniqueStrings(fullTypes, { fullType })
    end

    return fullTypes
end

function Config.NormalizeArchetypeID(archetypeID)
    local value = tostring(archetypeID or "")
    if value == "" then
        return "General"
    end

    if Config.JobProfiles[value] then
        return "General"
    end

    return value
end

function Config.NormalizeJobType(jobType)
    if Config.JobProfiles[jobType] then
        return jobType
    end

    local mapped = Config.LegacyProfessionToJob[jobType]
    if mapped then
        return mapped
    end

    return Config.JobTypes.Scavenge
end

function Config.GetJobProfile(jobType)
    return Config.JobProfiles[Config.NormalizeJobType(jobType)] or Config.JobProfiles.Scavenge
end

function Config.ItemMatchesEquipmentRequirement(fullType, requirementKey)
    local itemType = tostring(fullType or "")
    local key = tostring(requirementKey or "")
    if itemType == "" or key == "" then
        return false
    end

    local tags = (Config.GetItemCombinedTags and Config.GetItemCombinedTags(itemType))
        or (Config.FindItemTags and Config.FindItemTags(itemType))
        or {}

    for _, itemTag in ipairs(tags or {}) do
        if tostring(itemTag or "") == key then
            return true
        end
        if Config.TagMatches and Config.TagMatches(itemTag, key) then
            return true
        end
    end

    return false
end

function Config.GetEquipmentRequirementDefinition(requirementKey)
    local key = tostring(requirementKey or "")
    if key == "" then
        return nil
    end

    local source = Config.EquipmentRequirementDefinitions[key] or {}
    local definition = {
        requirementKey = key,
        label = tostring(source.label or key),
        hintText = tostring(source.hintText or source.hint or key),
        reasonText = source.reasonText,
        searchText = tostring(source.searchText or key),
        iconFullType = source.iconFullType,
        supportedFullTypes = cloneStringArray(source.supportedFullTypes),
        requirementTags = cloneStringArray(source.requirementTags),
        jobTypes = cloneStringArray(source.jobTypes),
        autoEquip = source.autoEquip == true,
        sortOrder = tonumber(source.sortOrder) or 1000,
    }

    appendUniqueStrings(definition.requirementTags, { key })

    for _, fullType in ipairs(collectKnownEquipmentFullTypes()) do
        if Config.ItemMatchesEquipmentRequirement(fullType, key) then
            appendUniqueStrings(definition.supportedFullTypes, { fullType })
            if not definition.iconFullType then
                definition.iconFullType = fullType
            end
        end
    end

    return definition
end

function Config.GetEquipmentRequirementDefinitions(jobType)
    local normalizedJobType = jobType and Config.NormalizeJobType(jobType) or nil
    local definitions = {}
    local seen = {}
    local profile = normalizedJobType and Config.GetJobProfile(normalizedJobType) or nil

    for _, requiredTag in ipairs(profile and profile.requiredToolTags or {}) do
        local key = tostring(requiredTag or "")
        if key ~= "" and not seen[key] then
            local definition = Config.GetEquipmentRequirementDefinition(key)
            if definition then
                definitions[#definitions + 1] = definition
                seen[key] = true
            end
        end
    end

    for requirementKey, rawDefinition in pairs(Config.EquipmentRequirementDefinitions or {}) do
        local key = tostring(requirementKey or "")
        if key ~= "" and not seen[key] and isDefinitionRelevantToJob(rawDefinition, normalizedJobType) then
            local definition = Config.GetEquipmentRequirementDefinition(key)
            if definition then
                definitions[#definitions + 1] = definition
                seen[key] = true
            end
        end
    end

    table.sort(definitions, function(a, b)
        local orderA = tonumber(a and a.sortOrder) or 1000
        local orderB = tonumber(b and b.sortOrder) or 1000
        if orderA == orderB then
            return tostring(a and a.label or a and a.requirementKey or "")
                < tostring(b and b.label or b and b.requirementKey or "")
        end
        return orderA < orderB
    end)

    return definitions
end

function Config.GetAutoEquipRequirementDefinitions(jobType)
    local definitions = {}
    for _, definition in ipairs(Config.GetEquipmentRequirementDefinitions(jobType)) do
        if definition.autoEquip == true then
            definitions[#definitions + 1] = definition
        end
    end
    return definitions
end

function Config.GetMatchingEquipmentRequirementDefinitions(fullType, jobType)
    local matches = {}
    for _, definition in ipairs(Config.GetEquipmentRequirementDefinitions(jobType)) do
        for _, requirementTag in ipairs(definition.requirementTags or {}) do
            if Config.ItemMatchesEquipmentRequirement(fullType, requirementTag) then
                matches[#matches + 1] = definition
                break
            end
        end
    end
    return matches
end

function Config.IsRequiredEquipmentFullType(fullType, jobType)
    return #(Config.GetMatchingEquipmentRequirementDefinitions(fullType, jobType) or {}) > 0
end

function Config.GetProfile(profession)
    return Config.GetJobProfile(profession)
end

function Config.GetDefaultJobForArchetype(archetypeID)
    local archetype = Config.NormalizeArchetypeID(archetypeID)
    if archetype == "Doctor" then
        return Config.JobTypes.Doctor
    end
    if archetype == "Farmer" then
        return Config.JobTypes.Farm
    end
    if archetype == "Angler" then
        return Config.JobTypes.Fish
    end
    return Config.JobTypes.Scavenge
end

function Config.GetJobSpeedMultiplier(archetypeID, jobType)
    local normalizedJobType = Config.NormalizeJobType(jobType)
    local bonuses = Config.ArchetypeJobBonuses[tostring(archetypeID or "")]
    if bonuses and bonuses[normalizedJobType] then
        return bonuses[normalizedJobType]
    end
    return 1.0
end

function Config.GetWorkerBaseCarryWeight(worker)
    local explicitCarryWeight = tonumber(worker and worker.baseCarryWeightOverride)
    if explicitCarryWeight and explicitCarryWeight > 0 then
        return explicitCarryWeight
    end

    local archetypeID = Config.NormalizeArchetypeID(worker and worker.archetypeID)
    local archetypeCarryWeight = tonumber(Config.ArchetypeCarryWeight and Config.ArchetypeCarryWeight[archetypeID])
    if archetypeCarryWeight and archetypeCarryWeight > 0 then
        return archetypeCarryWeight
    end

    return Config.GetDefaultWorkerCarryWeight and Config.GetDefaultWorkerCarryWeight()
        or math.max(0, tonumber(Config.DEFAULT_WORKER_CARRY_WEIGHT) or 8)
end

function Config.GetNextJobType(jobType)
    local order = {
        Config.JobTypes.Builder,
        Config.JobTypes.Doctor,
        Config.JobTypes.Scavenge,
        Config.JobTypes.Farm,
        Config.JobTypes.Fish
    }
    local normalized = Config.NormalizeJobType(jobType)
    for index, value in ipairs(order) do
        if value == normalized then
            return order[(index % #order) + 1]
        end
    end
    return order[1]
end

function Config.GetProjectionUUID(workerID)
    return Config.PROJECTION_PREFIX .. tostring(workerID or "unknown")
end

function Config.GetOwnerUsername(playerOrUsername)
    if type(playerOrUsername) == "string" then
        return playerOrUsername
    end

    local player = playerOrUsername
    if player and player.getUsername then
        local username = player:getUsername()
        if username and username ~= "" then
            return username
        end
    end

    return "local"
end

return Config
