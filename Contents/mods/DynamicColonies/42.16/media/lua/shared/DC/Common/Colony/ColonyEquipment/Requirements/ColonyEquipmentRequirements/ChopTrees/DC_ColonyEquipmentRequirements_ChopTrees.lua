DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

Config.EquipmentRequirementDefinitions = Config.EquipmentRequirementDefinitions or {}

local requirementKey = "ChopTrees.Tool.Axe"

Config.EquipmentRequirementDefinitions[requirementKey] = {
    requirementKey = requirementKey,
    label = "Axe",
    hintText = "Required to chop down trees and haul logs home.",
    supportedFullTypes = { "Base.HandAxe", "Base.Axe", "Base.WoodAxe", "Base.AxeStone" },
    requirementTags = { "Weapon.Melee.Axe" },
    iconFullType = "Base.HandAxe",
    jobTypes = { tostring((Config.JobTypes or {}).ChopTrees or "ChopTrees") },
    autoEquip = true,
    sortOrder = 141,
}

return Config
