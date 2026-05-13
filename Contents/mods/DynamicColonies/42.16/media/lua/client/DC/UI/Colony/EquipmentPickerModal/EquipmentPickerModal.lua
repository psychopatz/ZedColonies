require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISButton"
require "ISUI/ISComboBox"
require "ISUI/ISLabel"
require "DC/Common/Colony/ColonyEquipment/Common/DC_ColonyEquipment_EquipmentPickerModal_FlavorText"

local FlavorText = DC_Colony and DC_Colony.Equipment and DC_Colony.Equipment.EquipmentPickerModalFlavorText or {}

DC_EquipmentPickerModal = ISCollapsableWindow:derive("DC_EquipmentPickerModal")
DC_EquipmentPickerModal.instance = DC_EquipmentPickerModal.instance or nil
DC_EquipmentPickerModal.Internal = DC_EquipmentPickerModal.Internal or {}
DC_EquipmentPickerModal.Internal.FlavorText = FlavorText

require "DC/UI/Colony/EquipmentPickerModal/EquipmentPickerModal_SourceOptions"
require "DC/UI/Colony/EquipmentPickerModal/EquipmentPickerModal_List"
require "DC/UI/Colony/EquipmentPickerModal/EquipmentPickerModal_State"
require "DC/UI/Colony/EquipmentPickerModal/EquipmentPickerModal_Layout"
require "DC/UI/Colony/EquipmentPickerModal/EquipmentPickerModal_Actions"
require "DC/UI/Colony/EquipmentPickerModal/EquipmentPickerModal_Lifecycle"

return DC_EquipmentPickerModal