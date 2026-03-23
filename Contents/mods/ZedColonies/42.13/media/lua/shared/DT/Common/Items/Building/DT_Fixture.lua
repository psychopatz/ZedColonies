-- ============================================================================
-- Building Items Registry for Dynamic Trading
-- If you want some suggestions or have balancing issues, please report them to
-- my discussion page. Happy to adjust prices and stock based on your feedback! :)
-- https://steamcommunity.com/sharedfiles/filedetails/?id=3635333613
-- ============================================================================

require "DT/Common/Config"
if not DynamicTrading then return end

DynamicTrading.RegisterBatch({
    -- The items are grouped by Primary tag and Rarity

    -- [Building.Fixture.Appliance] [Rarity.Common] (27 items)
    { item="Base.Mov_AntiqueStove", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_BlueComboWasherDryer", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_BlueFridge", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_ChestFreezer", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_FridgeMini", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_GreenFridge", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_GreenOven", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_GreyOven", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_IndustrialDishwasher", basePrice=79, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla", "Theme.Industrial"}, stockRange={min=1, max=11} },
    { item="Base.Mov_IndustrialFridge", basePrice=79, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla", "Theme.Industrial"}, stockRange={min=1, max=11} },
    { item="Base.Mov_IndustrialOven", basePrice=79, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla", "Theme.Industrial"}, stockRange={min=1, max=11} },
    { item="Base.Mov_Microwave", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_Microwave2", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_ModernOven", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_PlainFridge", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_PopsicleFreezer", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_RedFridge", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_RedOven", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_SnackVendingMachine", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_SodaMachine", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_SodaMachineLarge", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_SodaVendingMachine", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_SteelFridge", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_Toaster", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_TrailerFridge", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_WhiteFridge", basePrice=60, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_WhiteIndustrialFridge", basePrice=79, tags={"Building.Fixture.Appliance", "Rarity.Common", "Origin.Vanilla", "Theme.Industrial"}, stockRange={min=1, max=11} },

    -- [Building.Fixture.Communication] [Rarity.Common] (7 items)
    { item="Base.Mov_BeigeRotaryPhone", basePrice=44, tags={"Building.Fixture.Communication", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_BlackModernPhone", basePrice=44, tags={"Building.Fixture.Communication", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_BlackRotaryPhone", basePrice=44, tags={"Building.Fixture.Communication", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_PayPhones", basePrice=44, tags={"Building.Fixture.Communication", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_RedRotaryPhone", basePrice=44, tags={"Building.Fixture.Communication", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_WhiteModernPhone", basePrice=44, tags={"Building.Fixture.Communication", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_WhiteRotaryPhone", basePrice=44, tags={"Building.Fixture.Communication", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },

    -- [Building.Fixture.General] [Rarity.Rare] (22 items)
    { item="Base.AlarmClock2", basePrice=79, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=4} },
    { item="Base.BathTowelWet", basePrice=68, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=7} },
    { item="Base.Calculator", basePrice=68, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=7} },
    { item="Base.Clipboard", basePrice=68, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=4} },
    { item="Base.DishClothWet", basePrice=68, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=7} },
    { item="Base.Doily", basePrice=64, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=12} },
    { item="Base.Eraser", basePrice=68, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=12} },
    { item="Base.MagnifyingGlass", basePrice=68, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=7} },
    { item="Base.MarkerBlack", basePrice=68, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=12} },
    { item="Base.MarkerBlue", basePrice=68, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=12} },
    { item="Base.MarkerGreen", basePrice=68, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=12} },
    { item="Base.MarkerRed", basePrice=68, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=12} },
    { item="Base.RippedSheets", basePrice=68, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=12} },
    { item="Base.RippedSheetsDirty", basePrice=20, tags={"Building.Fixture.General", "Rarity.Rare", "Quality.Waste", "Origin.Vanilla", "Quality.Waste"}, stockRange={min=0, max=14} },
    { item="Base.ScissorsBlunt", basePrice=69, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=12} },
    { item="Base.Sponge", basePrice=68, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=12} },
    { item="Base.StraightRazor", basePrice=68, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=7} },
    { item="Base.UmbrellaBlack", basePrice=69, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=4} },
    { item="Base.UmbrellaBlue", basePrice=69, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=4} },
    { item="Base.UmbrellaRed", basePrice=69, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=4} },
    { item="Base.UmbrellaTINTED", basePrice=69, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=4} },
    { item="Base.UmbrellaWhite", basePrice=69, tags={"Building.Fixture.General", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=4} },

    -- [Building.Fixture.Hardware] [Rarity.Rare] (2 items)
    { item="Base.CombinationPadlock", basePrice=75, tags={"Building.Fixture.Hardware", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=7} },
    { item="Base.Padlock", basePrice=75, tags={"Building.Fixture.Hardware", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=7} },

    -- [Building.Fixture.Plumbing] [Rarity.Common] (13 items)
    { item="Base.Mov_ChemicalToilet", basePrice=57, tags={"Building.Fixture.Plumbing", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_ChromeSink", basePrice=57, tags={"Building.Fixture.Plumbing", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_DarkIndustrialSink", basePrice=76, tags={"Building.Fixture.Plumbing", "Rarity.Common", "Origin.Vanilla", "Theme.Industrial"}, stockRange={min=1, max=11} },
    { item="Base.Mov_FancyHangingSink", basePrice=57, tags={"Building.Fixture.Plumbing", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_FancyToilet", basePrice=57, tags={"Building.Fixture.Plumbing", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_IndustrialSink", basePrice=76, tags={"Building.Fixture.Plumbing", "Rarity.Common", "Origin.Vanilla", "Theme.Industrial"}, stockRange={min=1, max=11} },
    { item="Base.Mov_LargeIndustrialSink", basePrice=76, tags={"Building.Fixture.Plumbing", "Rarity.Common", "Origin.Vanilla", "Theme.Industrial"}, stockRange={min=1, max=11} },
    { item="Base.Mov_LowToilet", basePrice=57, tags={"Building.Fixture.Plumbing", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_Urinal", basePrice=57, tags={"Building.Fixture.Plumbing", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_WallShower", basePrice=57, tags={"Building.Fixture.Plumbing", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_WaterDispenser", basePrice=57, tags={"Building.Fixture.Plumbing", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_WhiteHangingSink", basePrice=57, tags={"Building.Fixture.Plumbing", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_WhiteSink", basePrice=57, tags={"Building.Fixture.Plumbing", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },

    -- [Building.Fixture.Plumbing] [Rarity.Rare] (3 items)
    { item="Base.CanPipe", basePrice=101, tags={"Building.Fixture.Plumbing", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=7} },
    { item="Base.Pipe", basePrice=101, tags={"Building.Fixture.Plumbing", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=4} },
    { item="Base.ToiletBrush", basePrice=91, tags={"Building.Fixture.Plumbing", "Rarity.Rare", "Origin.Vanilla"}, stockRange={min=0, max=4} },

    -- [Building.Fixture.Storage] [Rarity.Common] (4 items)
    { item="Base.Mov_BlueWallLocker", basePrice=54, tags={"Building.Fixture.Storage", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_GreenWallLocker", basePrice=54, tags={"Building.Fixture.Storage", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_MetalLocker", basePrice=54, tags={"Building.Fixture.Storage", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_YellowWallLocker", basePrice=54, tags={"Building.Fixture.Storage", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },

    -- [Building.Fixture.Storage] [Rarity.Uncommon] (1 item)
    { item="Base.Mov_MilitaryLocker", basePrice=104, tags={"Building.Fixture.Storage", "Rarity.Uncommon", "Origin.Vanilla", "Theme.Militia"}, stockRange={min=0, max=8} },

    -- [Building.Fixture.Utility] [Rarity.Common] (2 items)
    { item="Base.Mov_NapkinDispenser", basePrice=53, tags={"Building.Fixture.Utility", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
    { item="Base.Mov_TowelDispenser", basePrice=53, tags={"Building.Fixture.Utility", "Rarity.Common", "Origin.Vanilla"}, stockRange={min=1, max=13} },
})

print("[DynamicTrading] Fixture Registry Complete")
