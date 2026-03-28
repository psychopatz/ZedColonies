DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config
Config.__equipmentRequirementCache = Config.__equipmentRequirementCache or {}

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

local UNIVERSAL_JOB_TYPES = {
    "Unemployed",
    "Builder",
    "Doctor",
    "FollowPlayer",
    "Farm",
    "Fish",
    "Scavenge",
}

local function getEquipmentRequirementCache()
    local cache = Config.__equipmentRequirementCache or {}
    cache.definitionByKey = cache.definitionByKey or {}
    cache.definitionsByJob = cache.definitionsByJob or {}
    cache.autoEquipByJob = cache.autoEquipByJob or {}
    cache.matchesByJobAndType = cache.matchesByJobAndType or {}
    cache.knownEquipmentFullTypes = cache.knownEquipmentFullTypes or nil
    Config.__equipmentRequirementCache = cache
    return cache
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
    ["Fish.Tool.Basic"] = {
        label = "Fishing Tool",
        hintText = "Fishing spear or fishing rod",
        reasonText = "Needed so the worker can fish, with the spear serving as the renewable starter tool.",
        searchText = "crafted spear fire hardened spear crude spear stone spear fishing rod",
        supportedFullTypes = {
            "Base.SpearCrafted",
            "Base.SpearCraftedFireHardened",
            "Base.SpearCrude",
            "Base.SpearCrudeLong",
            "Base.SpearStone",
            "Base.SpearStoneLong",
            "Base.CraftedFishingRod",
            "Base.FishingRod"
        },
        iconFullType = "Base.SpearCrafted",
        jobTypes = { "Fish" },
        autoEquip = true,
        sortOrder = 130,
    },
    ["Fish.Upgrade.Rod"] = {
        label = "Fishing Rod",
        hintText = "Crafted fishing rod or fishing rod",
        reasonText = "A rod setup unlocks better fish and supports baited fishing.",
        searchText = "crafted fishing rod fishing rod",
        supportedFullTypes = { "Base.CraftedFishingRod", "Base.FishingRod" },
        iconFullType = "Base.FishingRod",
        jobTypes = { "Fish" },
        autoEquip = false,
        sortOrder = 131,
    },
    ["Fish.Upgrade.Line"] = {
        label = "Fishing Line",
        hintText = "Fishing line or premium fishing line",
        reasonText = "A proper line is required before rod-based fishing can land larger catches.",
        searchText = "fishing line premium fishing line",
        supportedFullTypes = { "Base.FishingLine", "Base.PremiumFishingLine" },
        iconFullType = "Base.FishingLine",
        jobTypes = { "Fish" },
        autoEquip = false,
        sortOrder = 132,
    },
    ["Fish.Upgrade.Tackle"] = {
        label = "Fishing Tackle",
        hintText = "Hook, lure, bobber, or gaff",
        reasonText = "Tackle improves the rod setup enough to target the biggest fish.",
        searchText = "fishing hook lure bobber gaff tackle",
        supportedFullTypes = {
            "Base.FishingHook",
            "Base.FishingHook_Bone",
            "Base.FishingHook_Forged",
            "Base.FishingHookBox",
            "Base.Bobber",
            "Base.JigLure",
            "Base.MinnowLure",
            "Base.Gaffhook"
        },
        iconFullType = "Base.FishingHook",
        jobTypes = { "Fish" },
        autoEquip = false,
        sortOrder = 133,
    },
    ["Fish.Upgrade.Bait"] = {
        label = "Fishing Bait",
        hintText = "Worms, maggots, insects, leeches, or chum",
        reasonText = "Bait speeds up rod fishing and improves bite consistency, but it can be consumed.",
        searchText = "worm maggots cricket grasshopper leech tadpole bait fish chum",
        supportedFullTypes = {
            "Base.Worm",
            "Base.Maggots",
            "Base.Cricket",
            "Base.Grasshopper",
            "Base.Leech",
            "Base.Tadpole",
            "Base.BaitFish",
            "Base.Chum"
        },
        iconFullType = "Base.Worm",
        jobTypes = { "Fish" },
        autoEquip = false,
        sortOrder = 134,
    },
    ["Colony.Carry.Backpack"] = {
        label = "Backpack",
        hintText = "Any wearable bag with capacity and weight reduction",
        reasonText = "A wearable backpack expands worker inventory capacity across every job.",
        searchText = "wearable backpack duffel satchel hiking bag schoolbag",
        supportedFullTypes = {},
        iconFullType = "Base.Bag_Schoolbag",
        jobTypes = UNIVERSAL_JOB_TYPES,
        autoEquip = false,
        sortOrder = 135,
    },
    ["Colony.Combat.Weapon.Melee"] = {
        label = "Melee Weapon",
        hintText = "Any usable melee weapon",
        reasonText = "Close-quarters weapon slot for workers that are capable of fighting in melee.",
        searchText = "melee weapon bat axe crowbar machete pipe spear hammer knife",
        supportedFullTypes = {
            "Base.BaseballBat",
            "Base.Crowbar",
            "Base.Axe",
        },
        requirementTags = { "Weapon.Melee" },
        iconFullType = "Base.BaseballBat",
        jobTypes = UNIVERSAL_JOB_TYPES,
        autoEquip = true,
        sortOrder = 136,
    },
    ["Colony.Combat.Weapon.Ranged"] = {
        label = "Ranged Weapon",
        hintText = "Any firearm with matching loose ammo",
        reasonText = "Firearm slot for workers that are capable of using ranged weapons.",
        searchText = "ranged weapon firearm pistol revolver rifle shotgun smg gun",
        supportedFullTypes = {
            "Base.Pistol",
            "Base.Revolver_Short",
            "Base.DoubleBarrelShotgun",
            "Base.Shotgun",
        },
        requirementTags = { "Weapon.Ranged.Firearm" },
        iconFullType = "Base.Pistol",
        jobTypes = UNIVERSAL_JOB_TYPES,
        autoEquip = true,
        sortOrder = 137,
    },
    ["Colony.Combat.Ammo"] = {
        label = "Ammo",
        hintText = "Loose bullets or shells",
        reasonText = "Loose rounds support ranged-capable workers that have firearm access.",
        searchText = "ammo bullets shells rounds 9mm 45 38 357 shotgun shells 556 308 3030",
        supportedFullTypes = {
            "Base.Bullets9mm",
            "Base.Bullets45",
            "Base.Bullets38",
            "Base.ShotgunShells",
        },
        requirementTags = { "Weapon.Ranged.Ammo" },
        iconFullType = "Base.Bullets9mm",
        jobTypes = UNIVERSAL_JOB_TYPES,
        autoEquip = true,
        autoEquipTransfer = "full_stack",
        sortOrder = 138,
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
        jobTypes = {},
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
    local cache = getEquipmentRequirementCache()
    if cache.knownEquipmentFullTypes then
        return cache.knownEquipmentFullTypes
    end

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

    for fullType, _ in pairs(Config.FishingItemProfiles or {}) do
        appendUniqueStrings(fullTypes, { fullType })
    end

    appendUniqueStrings(fullTypes, Config.GetKnownBackpackFullTypes and Config.GetKnownBackpackFullTypes() or nil)

    local builderToolFullTypes = DC_Buildings and DC_Buildings.Config and DC_Buildings.Config.BuilderToolFullTypes or nil
    for fullType, _ in pairs(builderToolFullTypes or {}) do
        appendUniqueStrings(fullTypes, { fullType })
    end

    cache.knownEquipmentFullTypes = fullTypes
    return fullTypes
end

local function getWorkerSkillLevel(worker, skillID)
    local skills = DC_Colony and DC_Colony.Skills or nil
    local entry = skills and skills.GetSkillEntry and skills.GetSkillEntry(worker, skillID) or nil
    return math.max(0, math.floor(tonumber(entry and entry.level) or 0))
end

local function normalizeRequirementDefinition(definitionOrKey)
    if type(definitionOrKey) == "table" then
        return definitionOrKey
    end

    if Config.GetEquipmentRequirementDefinition then
        return Config.GetEquipmentRequirementDefinition(definitionOrKey)
    end

    return nil
end

function Config.GetWorkerCombatCapability(worker)
    local meleeLevel = getWorkerSkillLevel(worker, "Melee")
    local shootingLevel = getWorkerSkillLevel(worker, "Shooting")

    return {
        meleeLevel = meleeLevel,
        shootingLevel = shootingLevel,
        canUseMelee = meleeLevel > 0,
        canUseRanged = shootingLevel > 0,
        canFight = meleeLevel > 0 or shootingLevel > 0,
    }
end

function Config.IsEquipmentRequirementAvailableForWorker(definitionOrKey, worker)
    local definition = normalizeRequirementDefinition(definitionOrKey)
    if not definition or not worker then
        return definition ~= nil
    end

    local requirementKey = tostring(definition.requirementKey or "")
    if requirementKey == "Colony.Combat.Weapon.Melee" then
        local capability = Config.GetWorkerCombatCapability and Config.GetWorkerCombatCapability(worker) or {}
        return capability.canUseMelee == true
    end

    if requirementKey == "Colony.Combat.Weapon.Ranged" or requirementKey == "Colony.Combat.Ammo" then
        local capability = Config.GetWorkerCombatCapability and Config.GetWorkerCombatCapability(worker) or {}
        return capability.canUseRanged == true
    end

    return true
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

    local cache = getEquipmentRequirementCache()
    if cache.definitionByKey[key] then
        return cache.definitionByKey[key]
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
        autoEquipTransfer = tostring(source.autoEquipTransfer or "single"),
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

    cache.definitionByKey[key] = definition
    return definition
end

function Config.GetEquipmentRequirementDefinitions(jobType)
    local normalizedJobType = jobType and Config.NormalizeJobType(jobType) or nil
    local cacheKey = normalizedJobType or "__all"
    local cache = getEquipmentRequirementCache()
    if cache.definitionsByJob[cacheKey] then
        return cache.definitionsByJob[cacheKey]
    end

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

    cache.definitionsByJob[cacheKey] = definitions
    return definitions
end

function Config.GetAutoEquipRequirementDefinitions(jobType)
    local normalizedJobType = jobType and Config.NormalizeJobType(jobType) or nil
    local cacheKey = normalizedJobType or "__all"
    local cache = getEquipmentRequirementCache()
    if cache.autoEquipByJob[cacheKey] then
        return cache.autoEquipByJob[cacheKey]
    end

    local definitions = {}
    for _, definition in ipairs(Config.GetEquipmentRequirementDefinitions(jobType)) do
        if definition.autoEquip == true then
            definitions[#definitions + 1] = definition
        end
    end

    cache.autoEquipByJob[cacheKey] = definitions
    return definitions
end

function Config.GetEquipmentRequirementDefinitionsForWorker(worker)
    local definitions = Config.GetEquipmentRequirementDefinitions(worker and worker.jobType) or {}
    if not worker then
        return definitions
    end

    local filtered = {}
    for _, definition in ipairs(definitions) do
        if Config.IsEquipmentRequirementAvailableForWorker(definition, worker) then
            filtered[#filtered + 1] = definition
        end
    end

    return filtered
end

function Config.GetAutoEquipRequirementDefinitionsForWorker(worker)
    local definitions = Config.GetEquipmentRequirementDefinitionsForWorker(worker)
    local filtered = {}

    for _, definition in ipairs(definitions or {}) do
        if definition.autoEquip == true then
            filtered[#filtered + 1] = definition
        end
    end

    return filtered
end

function Config.GetMatchingEquipmentRequirementDefinitions(fullType, jobType)
    local itemType = tostring(fullType or "")
    if itemType == "" then
        return {}
    end

    local normalizedJobType = jobType and Config.NormalizeJobType(jobType) or nil
    local cacheKey = (normalizedJobType or "__all") .. "|" .. itemType
    local cache = getEquipmentRequirementCache()
    if cache.matchesByJobAndType[cacheKey] then
        return cache.matchesByJobAndType[cacheKey]
    end

    local matches = {}
    for _, definition in ipairs(Config.GetEquipmentRequirementDefinitions(normalizedJobType)) do
        for _, requirementTag in ipairs(definition.requirementTags or {}) do
            if Config.ItemMatchesEquipmentRequirement(itemType, requirementTag) then
                matches[#matches + 1] = definition
                break
            end
        end
    end

    cache.matchesByJobAndType[cacheKey] = matches
    return matches
end

function Config.GetMatchingEquipmentRequirementDefinitionsForWorker(fullType, worker)
    local itemType = tostring(fullType or "")
    if itemType == "" then
        return {}
    end

    local matches = {}
    for _, definition in ipairs(Config.GetEquipmentRequirementDefinitionsForWorker(worker)) do
        for _, requirementTag in ipairs(definition.requirementTags or {}) do
            if Config.ItemMatchesEquipmentRequirement(itemType, requirementTag) then
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

function Config.IsRequiredEquipmentFullTypeForWorker(fullType, worker)
    return #(Config.GetMatchingEquipmentRequirementDefinitionsForWorker(fullType, worker) or {}) > 0
end

return Config
