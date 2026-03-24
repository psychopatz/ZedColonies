require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonySkills/DC_ColonySkills"
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition"
require "DC/Common/Colony/ColonyEnergy/DC_ColonyEnergy"

DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

-- Keep explicit load order so registry foundations are available before higher-level APIs.
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_Internal"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_Data"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_WorkerState"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_Workers"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_Recruitment"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_Presentation"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_Ledgers"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_WorkerCommands"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_Sites"
require "DC/Common/Colony/Warehouse/DC_ColonyWarehouse"

DC_Colony.NeedProviders = {
    {
        label = "Health",
        color = DC_Colony.Health and DC_Colony.Health.GetBarColor and DC_Colony.Health.GetBarColor() or { r = 0.86, g = 0.33, b = 0.33 },
        GetBarData = function(worker) return DC_Colony.Health and DC_Colony.Health.GetBarData(worker) end
    },
    {
        label = "Energy",
        color = DC_Colony.Energy and DC_Colony.Energy.GetBarColor and DC_Colony.Energy.GetBarColor() or { r = 0.69, g = 0.33, b = 0.86 },
        GetBarData = function(worker) return DC_Colony.Energy and DC_Colony.Energy.GetBarData(worker) end
    },
    {
        label = "Food",
        color = DC_Colony.Nutrition and DC_Colony.Nutrition.GetCaloriesBarColor and DC_Colony.Nutrition.GetCaloriesBarColor() or { r = 0.84, g = 0.68, b = 0.24 },
        GetBarData = function(worker) return DC_Colony.Nutrition and DC_Colony.Nutrition.GetCaloriesBarData(worker) end
    },
    {
        label = "Water",
        color = DC_Colony.Nutrition and DC_Colony.Nutrition.GetHydrationBarColor and DC_Colony.Nutrition.GetHydrationBarColor() or { r = 0.28, g = 0.66, b = 0.58 },
        GetBarData = function(worker) return DC_Colony.Nutrition and DC_Colony.Nutrition.GetHydrationBarData(worker) end
    }
}

return DC_Colony.Registry
