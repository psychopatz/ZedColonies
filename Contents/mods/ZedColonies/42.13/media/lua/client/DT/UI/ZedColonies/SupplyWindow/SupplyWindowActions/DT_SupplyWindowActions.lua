DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

require "DT/UI/ZedColonies/DT_LabourQuantityModal"

-- Keep explicit load order so shared action helpers exist before dependent handlers.
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowActions/DT_SupplyWindowActions_WorkerSync"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowActions/DT_SupplyWindowActions_TransferState"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowActions/DT_SupplyWindowActions_Money"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowActions/DT_SupplyWindowActions_Deposit"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowActions/DT_SupplyWindowActions_Withdraw"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowActions/DT_SupplyWindowActions_Drop"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowActions/DT_SupplyWindowActions_Selection"

return DT_SupplyWindow
