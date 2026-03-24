require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Trading/EconomyCommon/DC_EconomyCommon"

DC_Colony = DC_Colony or {}
DC_Colony.Nutrition = DC_Colony.Nutrition or {}
DC_Colony.Nutrition.Internal = DC_Colony.Nutrition.Internal or {}

local Nutrition = DC_Colony.Nutrition

-- Keep explicit load order so shared helpers exist before dependent nutrition modules.
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition_Shared"
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition_ItemAnalysis"
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition_Reserve"
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition_Ledger"
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition_Provisioning"
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition_Process"
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition_Presentation"

return Nutrition
