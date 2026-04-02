require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DT/Common/UI/Trading/Provider/DT_TradingProvider_Core"

DynamicTrading = DynamicTrading or {}
DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
local TradingProvider = DynamicTrading.TradingProvider or {}

Internal.Config = (DC_Colony and DC_Colony.Config) or Internal.Config or {}
Internal.MoneyProvider = DC_MainWindow.MoneyProvider or {}

if type(TradingProvider.AttachCore) == "function" then
    TradingProvider.AttachCore(Internal.MoneyProvider)
end

DC_MainWindow.MoneyProvider = Internal.MoneyProvider
