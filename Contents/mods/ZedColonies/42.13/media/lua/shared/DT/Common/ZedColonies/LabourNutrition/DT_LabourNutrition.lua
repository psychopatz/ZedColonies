require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"
require "DT/Common/Trading/EconomyCommon/DT_EconomyCommon"

DT_Labour = DT_Labour or {}
DT_Labour.Nutrition = DT_Labour.Nutrition or {}
DT_Labour.Nutrition.Internal = DT_Labour.Nutrition.Internal or {}

local Nutrition = DT_Labour.Nutrition

-- Keep explicit load order so shared helpers exist before dependent nutrition modules.
require "DT/Common/ZedColonies/LabourNutrition/DT_LabourNutrition_Shared"
require "DT/Common/ZedColonies/LabourNutrition/DT_LabourNutrition_ItemAnalysis"
require "DT/Common/ZedColonies/LabourNutrition/DT_LabourNutrition_Reserve"
require "DT/Common/ZedColonies/LabourNutrition/DT_LabourNutrition_Ledger"
require "DT/Common/ZedColonies/LabourNutrition/DT_LabourNutrition_Provisioning"

return Nutrition
