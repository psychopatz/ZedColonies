DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

local REQUIRED_TOOL_DEFINITIONS = {
    ["Tool.Farming"] = {
        label = "Farming Tool",
        hint = "Hoe, trowel, or other farming tool",
        reasonText = "Needed so the worker can tend plots and complete farming cycles.",
    },
    ["Tool.Fishing"] = {
        label = "Fishing Tool",
        hint = "Fishing rod, spear, or other fishing tool",
        reasonText = "Needed so the worker can catch fish instead of idling at the site.",
    },
}

local SCAVENGE_PLACEHOLDER_DEFINITIONS = {
    {
        capability = "Scavenge.Access.LockedHome",
        label = "Prying Item",
        hint = "Crowbar or screwdriver",
        reasonText = "Lets the scavenger force entry into locked homes and other basic closed locations.",
        searchText = "crowbar screwdriver pry prying locked home",
        iconFullType = "Base.Crowbar",
        supportedFullTypes = { "Base.Crowbar", "Base.CrowbarForged", "Base.Screwdriver" },
    },
    {
        capability = "Scavenge.Utility.Light",
        label = "Lightsource",
        hint = "Flashlight or other light source",
        reasonText = "Reduces dark-area penalties so the scavenger can search interiors more effectively.",
        searchText = "flashlight lightsource light torch lamp",
        iconFullType = "Base.HandTorch",
        supportedFullTypes = { "Base.HandTorch", "Base.FlashLight_AngleHead", "Base.PenLight" },
    },
    {
        capability = "Scavenge.Haul.Bag",
        label = "Backpack",
        hint = "Backpack or duffel bag",
        reasonText = "Adds a carry container so the scavenger can haul more loot before needing to come home.",
        searchText = "backpack duffel bag hauling",
        iconFullType = "Base.Bag_Schoolbag",
        supportedFullTypes = { "Base.Bag_Schoolbag", "Base.Bag_DuffelBag", "Base.Bag_ToolBag" },
    },
    {
        capability = "Scavenge.Utility.Map",
        label = "Map",
        hint = "Map or route-planning literature",
        reasonText = "Helps plan routes and supports faster, more efficient scavenging runs.",
        searchText = "map route plan literature",
        iconFullType = "Base.Map",
        supportedFullTypes = { "Base.Map", "Base.MuldraughMap", "Base.WestpointMap" },
    },
    {
        capability = "Scavenge.Utility.Pen",
        label = "Pen",
        hint = "Any pen for route notes",
        reasonText = "Works with maps for route notes, improving the scavenger's planning loadout.",
        searchText = "pen route notes",
        iconFullType = "Base.Pen",
        supportedFullTypes = { "Base.Pen", "Base.BluePen", "Base.RedPen" },
    },
    {
        capability = "Scavenge.Access.ElectronicStore",
        label = "Electronics Access Tool",
        hint = "Screwdriver",
        reasonText = "Needed to open electronics-heavy locations and unlock electronics store scavenging pools.",
        searchText = "electronics access screwdriver store",
        iconFullType = "Base.Screwdriver",
        supportedFullTypes = { "Base.Screwdriver", "Base.Screwdriver_Old", "Base.Screwdriver_Improvised" },
    },
    {
        capability = "Scavenge.Extraction.CarpentryHammer",
        label = "Hammer",
        hint = "Hammer or ball-peen hammer",
        reasonText = "Allows carpentry extraction and stripping when salvaging wooden fixtures and furniture.",
        searchText = "hammer ball peen carpentry",
        iconFullType = "Base.Hammer",
        supportedFullTypes = { "Base.Hammer", "Base.BallPeenHammer", "Base.ClubHammer" },
    },
    {
        capability = "Scavenge.Extraction.CarpentrySaw",
        label = "Saw",
        hint = "Saw or garden saw",
        reasonText = "Pairs with a hammer for carpentry stripping and salvage-focused scavenging.",
        searchText = "saw garden saw carpentry",
        iconFullType = "Base.Saw",
        supportedFullTypes = { "Base.Saw", "Base.SmallSaw", "Base.GardenSaw" },
    },
    {
        capability = "Scavenge.Extraction.Plumbing",
        label = "Pipe Wrench",
        hint = "Pipe wrench",
        reasonText = "Required to extract plumbing-related loot and salvage plumbing fixtures.",
        searchText = "pipe wrench plumbing",
        iconFullType = "Base.PipeWrench",
        supportedFullTypes = { "Base.PipeWrench" },
    },
    {
        capability = "Scavenge.Extraction.MetalTorch",
        label = "Metal Torch",
        hint = "Blow torch",
        reasonText = "Needed for metal salvage jobs and advanced industrial stripping.",
        searchText = "blow torch metal torch welding",
        iconFullType = "Base.BlowTorch",
        supportedFullTypes = { "Base.BlowTorch" },
    },
    {
        capability = "Scavenge.Extraction.MetalMask",
        label = "Welding Mask",
        hint = "Welding mask",
        reasonText = "Needed with a blow torch so the scavenger can safely perform metal salvage work.",
        searchText = "welding mask metal",
        iconFullType = "Base.WeldingMask",
        supportedFullTypes = { "Base.WeldingMask" },
    },
    {
        capability = "Scavenge.Access.HeavyEntry",
        label = "Heavy Entry Tool",
        hint = "Sledgehammer",
        reasonText = "Breaks secure shutters and heavy barriers, unlocking the toughest scavenging entries.",
        searchText = "sledgehammer heavy entry secure shutters vaults",
        iconFullType = "Base.Sledgehammer",
        supportedFullTypes = { "Base.Sledgehammer", "Base.Sledgehammer2", "Base.SledgehammerForged" },
    },
    {
        capability = "Scavenge.Haul.Bulk",
        label = "Bulk Sack",
        hint = "Garbage bag or sandbag",
        reasonText = "Supports carrying bulky loose loot that otherwise gets left behind.",
        searchText = "garbage bag sandbag bulk sack",
        iconFullType = "Base.Garbagebag",
        supportedFullTypes = { "Base.Garbagebag", "Base.EmptySandbag" },
    },
    {
        capability = "Scavenge.Haul.Bundle",
        label = "Bundle Rope",
        hint = "Sheet rope",
        reasonText = "Lets the scavenger bundle heavy items together for transport.",
        searchText = "sheet rope bundle heavy",
        iconFullType = "Base.SheetRope",
        supportedFullTypes = { "Base.SheetRope", "Base.SheetRopeBundle" },
    },
}

local function getToolRequirementDefinition(requiredTag)
    local definition = REQUIRED_TOOL_DEFINITIONS[tostring(requiredTag or "")]
    if definition then
        return definition
    end

    return {
        label = tostring(requiredTag or "Any labour tool"),
        hint = tostring(requiredTag or "Any labour tool"),
    }
end

local function getWorkerToolTagMap(worker)
    local tagMap = {}
    local config = Internal.Config or {}

    for _, ledgerEntry in ipairs(worker and worker.toolLedger or {}) do
        local tags = ledgerEntry and ledgerEntry.tags or {}
        if config.GetItemCombinedTags and ledgerEntry and ledgerEntry.fullType then
            tags = config.GetItemCombinedTags(ledgerEntry.fullType)
        end

        for _, tag in ipairs(tags or {}) do
            tagMap[tostring(tag)] = true
        end
    end

    return tagMap
end

local function workerHasToolRequirement(worker, requiredTag)
    local config = Internal.Config or {}
    local tagMap = getWorkerToolTagMap(worker)

    for itemTag, enabled in pairs(tagMap) do
        if enabled and config.TagMatches and config.TagMatches(itemTag, requiredTag) then
            return true
        end
    end

    return false
end

local function getWorkerScavengeCapabilityMap(worker)
    local capabilityMap = {}
    local capabilityCount = 0
    local config = Internal.Config or {}

    for _, capability in ipairs(worker and worker.scavengeCapabilities or {}) do
        local key = tostring(capability)
        if not capabilityMap[key] then
            capabilityMap[key] = true
            capabilityCount = capabilityCount + 1
        end
    end

    if capabilityCount > 0 then
        return capabilityMap
    end

    for _, ledgerEntry in ipairs(worker and worker.toolLedger or {}) do
        local profile = config.GetScavengeItemProfile
            and config.GetScavengeItemProfile(ledgerEntry and ledgerEntry.fullType or nil)
            or nil

        for _, capability in ipairs(profile and profile.capabilities or {}) do
            local key = tostring(capability)
            if not capabilityMap[key] then
                capabilityMap[key] = true
                capabilityCount = capabilityCount + 1
            end
        end
    end

    return capabilityMap
end

function Internal.getMissingEquipmentPlaceholderEntries(worker)
    local entries = {}
    local config = Internal.Config or {}
    local profile = config.GetJobProfile and config.GetJobProfile(worker and worker.jobType) or {}
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")
    local jobTypes = config.JobTypes or {}

    for _, requiredTag in ipairs(profile and profile.requiredToolTags or {}) do
        if not workerHasToolRequirement(worker, requiredTag) then
            local definition = getToolRequirementDefinition(requiredTag)
            entries[#entries + 1] = Internal.buildWorkerToolPlaceholderEntry({
                requirementKey = tostring(requiredTag),
                displayName = definition.label,
                hintText = definition.hint,
                reasonText = definition.reasonText,
                searchText = tostring(requiredTag),
                requirementTags = { tostring(requiredTag) },
                supportedFullTypes = definition.supportedFullTypes,
                iconFullType = definition.iconFullType,
            })
        end
    end

    if normalizedJob == jobTypes.Scavenge then
        local capabilityMap = getWorkerScavengeCapabilityMap(worker)
        for _, definition in ipairs(SCAVENGE_PLACEHOLDER_DEFINITIONS) do
            if not capabilityMap[definition.capability] then
                entries[#entries + 1] = Internal.buildWorkerToolPlaceholderEntry({
                    requirementKey = definition.capability,
                    displayName = definition.label,
                    hintText = definition.hint,
                    reasonText = definition.reasonText,
                    searchText = definition.searchText or definition.capability,
                    requirementTags = { definition.capability },
                    supportedFullTypes = definition.supportedFullTypes,
                    iconFullType = definition.iconFullType,
                })
            end
        end
    end

    return entries
end

function Internal.getMissingEquipmentSummary(worker, maxCount)
    local placeholders = Internal.getMissingEquipmentPlaceholderEntries(worker)
    if #placeholders <= 0 then
        local config = Internal.Config or {}
        local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")
        if normalizedJob == ((config.JobTypes or {}).Scavenge) then
            return "Scavenger loadout ready"
        end
        return "Required tools already equipped"
    end

    local limit = math.max(1, math.floor(tonumber(maxCount) or 3))
    local labels = {}
    for index = 1, math.min(limit, #placeholders) do
        labels[#labels + 1] = tostring(placeholders[index].displayName or "Tool")
    end

    local summary = "Needs: " .. table.concat(labels, ", ")
    if #placeholders > limit then
        summary = summary .. " +" .. tostring(#placeholders - limit) .. " more"
    end

    return summary
end

function Internal.getRequiredToolSummary(worker)
    local config = Internal.Config or {}
    local profile = config.GetJobProfile and config.GetJobProfile(worker and worker.jobType) or {}
    local requiredTags = profile and profile.requiredToolTags or {}
    if not requiredTags or #requiredTags <= 0 then
        local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")
        local jobTypes = config.JobTypes or {}
        if normalizedJob == jobTypes.Scavenge then
            return Internal.getMissingEquipmentSummary(worker, 3)
        end
        return "Any labour tool"
    end

    local labels = {}
    for _, requiredTag in ipairs(requiredTags) do
        local definition = getToolRequirementDefinition(requiredTag)
        labels[#labels + 1] = definition.label
    end

    return table.concat(labels, ", ")
end
