DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config
local Gatherer = DC_Colony.Gatherer or {}

Config.EquipmentRequirementDefinitions = Config.EquipmentRequirementDefinitions or {}

local Definitions = {
    [tostring((Gatherer.RequirementKeys or {}).Axe or "Gatherer.Tool.Axe")] = {
        label = "Axe",
        hintText = "Any axe for faster wood gathering",
        reasonText = "Wood can still be gathered without an axe, but the worker will do it much more slowly.",
        searchText = "axe hand axe wood axe hatchet stone axe",
        supportedFullTypes = { "Base.HandAxe", "Base.Axe", "Base.WoodAxe", "Base.AxeStone" },
        requirementTags = { "Weapon.Melee.Axe" },
        iconFullType = "Base.HandAxe",
        jobTypes = { "Gatherer" },
        autoEquip = false,
        sortOrder = 124,
    },
    [tostring((Gatherer.RequirementKeys or {}).Pickaxe or "Gatherer.Tool.Pickaxe")] = {
        label = "Pickaxe",
        hintText = "Pickaxe for faster stone gathering",
        reasonText = "Stone can still be gathered without a pickaxe, but the worker will do it much more slowly.",
        searchText = "pickaxe forged pickaxe",
        supportedFullTypes = { "Base.PickAxe", "Base.PickAxeForged" },
        iconFullType = "Base.PickAxe",
        jobTypes = { "Gatherer" },
        autoEquip = false,
        sortOrder = 125,
    },
    [tostring((Gatherer.RequirementKeys or {}).Sack or "Gatherer.Tool.Sack")] = {
        label = "Sack",
        hintText = "Any sack for faster stone hauling",
        reasonText = "Stone can still be gathered without a sack, but the worker will do it much more slowly.",
        searchText = "sack sandbag wheat sack hide sack tarp sack",
        supportedFullTypes = { "Base.EmptySandbag", "Base.WheatSack", "Base.Bag_HideSack", "Base.Bag_TarpSack" },
        requirementTags = { "Container.Bag.Sack" },
        iconFullType = "Base.EmptySandbag",
        jobTypes = { "Gatherer" },
        autoEquip = false,
        sortOrder = 126,
    },
    [tostring((Gatherer.RequirementKeys or {}).FluidContainer or "Gatherer.Tool.FluidContainer")] = {
        label = "Fluid Container",
        hintText = "At least 1 fluid container, all assigned ones can be used",
        reasonText = "Water gathering needs fluid containers. The worker can use all assigned containers they can carry, and gathered water depends on their capacity.",
        searchText = "canteen bottle jug jar waterskin hydration backpack fluid container",
        supportedFullTypes = { "Base.WaterBottle", "Base.WaterRationCan", "Base.WaterDispenserBottle", "Base.CanteenCowboy" },
        requirementTags = { "Container.Liquid" },
        iconFullType = "Base.WaterBottle",
        jobTypes = { "Gatherer" },
        autoEquip = false,
        sortOrder = 127,
    },
}

for key, definition in pairs(Definitions) do
    Config.EquipmentRequirementDefinitions[key] = definition
end

return Config
