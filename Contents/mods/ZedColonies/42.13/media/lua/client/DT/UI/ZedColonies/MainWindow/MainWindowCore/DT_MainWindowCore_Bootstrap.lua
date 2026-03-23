require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"
require "DT/Common/UI/Trading/Provider/DT_TradingProvider_Core"

DynamicTrading = DynamicTrading or {}
DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

local Internal = DT_MainWindow.Internal
local TradingProvider = DynamicTrading.TradingProvider or {}

Internal.Config = (DT_Labour and DT_Labour.Config) or Internal.Config or {}
Internal.MoneyProvider = DT_MainWindow.MoneyProvider or {}

if type(TradingProvider.AttachCore) == "function" then
    TradingProvider.AttachCore(Internal.MoneyProvider)
end

DT_MainWindow.MoneyProvider = Internal.MoneyProvider
