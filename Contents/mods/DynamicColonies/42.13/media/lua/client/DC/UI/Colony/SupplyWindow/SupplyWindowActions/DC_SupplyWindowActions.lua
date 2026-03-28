DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

require "DC/UI/Colony/DC_ColonyQuantityModal"
require "DC/UI/Colony/DC_EquipmentPickerModal"

-- Keep explicit load order so shared action helpers exist before dependent handlers.
require "DC/UI/Colony/SupplyWindow/SupplyWindowActions/DC_SupplyWindowActions_WorkerSync"
require "DC/UI/Colony/SupplyWindow/SupplyWindowActions/DC_SupplyWindowActions_TransferState"
require "DC/UI/Colony/SupplyWindow/SupplyWindowActions/DC_SupplyWindowActions_Money"
require "DC/UI/Colony/SupplyWindow/SupplyWindowActions/DC_SupplyWindowActions_Deposit"
require "DC/UI/Colony/SupplyWindow/SupplyWindowActions/DC_SupplyWindowActions_Withdraw"
require "DC/UI/Colony/SupplyWindow/SupplyWindowActions/DC_SupplyWindowActions_Drop"
require "DC/UI/Colony/SupplyWindow/SupplyWindowActions/DC_SupplyWindowActions_EquipmentPicker"
require "DC/UI/Colony/SupplyWindow/SupplyWindowActions/DC_SupplyWindowActions_Selection"

return DC_SupplyWindow
