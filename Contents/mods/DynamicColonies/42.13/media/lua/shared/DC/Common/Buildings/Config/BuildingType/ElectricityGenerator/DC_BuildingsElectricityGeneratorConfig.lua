DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

Config.Definitions.ElectricityGenerator = {
    buildingType = "ElectricityGenerator",
    displayName = "Electricity Generator",
    iconPath = "media/ui/Buildings/DT_PowerGenerator.png",
    enabled = false,
    uniquePerColony = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {}
}
