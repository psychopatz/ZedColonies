require "DC/UI/Colony/Utils/DC_UIStringUtils"

DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}
DC_Colony = DC_Colony or {}
DC_Colony.UI = DC_Colony.UI or {}

local Internal = DC_SupplyWindow.Internal

local function onServerCommand(module, command, args)
    if module ~= Internal.getCommandModule() then
        return
    end
    if not DC_SupplyWindow.instance or not DC_SupplyWindow.instance:getIsVisible() then
        return
    end
    if command == "SyncWorkerDetails" then
        if Internal.handleCompanionSync then
            if Internal.handleCompanionSync(DC_SupplyWindow.instance, args) == true then
                return
            end
        end
    elseif command == "SyncWarehouse" then
        if Internal.handleWarehouseSync then
            if Internal.handleWarehouseSync(DC_SupplyWindow.instance, args) == true then
                return
            end
        end
    elseif command == "SyncWarehouseInventoryFeed" then
        if Internal.handleWarehouseInventoryFeedSync then
            if Internal.handleWarehouseInventoryFeedSync(DC_SupplyWindow.instance, args) == true then
                return
            end
        end
    elseif command == "ColonyNotice" then
        if args and args.message then
            DC_SupplyWindow.instance:updateStatus(args.message)
        end
        if args and args.popup == true and DC_Colony.UI and DC_Colony.UI.ShowNoticeModal then
            DC_Colony.UI.ShowNoticeModal(args.message)
        end
    elseif command == "SupplyTransferResult" then
        if DC_SupplyWindow.instance.onSupplyTransferResult then
            DC_SupplyWindow.instance:onSupplyTransferResult(args)
        end
    end
end

if not DC_SupplyWindow.EventsAdded then
    Events.OnServerCommand.Add(onServerCommand)
    DC_SupplyWindow.EventsAdded = true
end
