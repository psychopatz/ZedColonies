DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = (Network.Workers or {}).Shared or {}

Network.Handlers = Network.Handlers or {}

Network.Handlers.SetWarehouseAutoEquipEnabled = function(player, args)
    local owner = Config.GetOwnerUsername(player)
    local enabled = args and args.enabled == true or false
    Warehouse.SetAutoEquipEnabled(owner, enabled)
    if Registry.Save then
        Registry.Save()
    end
    Internal.syncWarehouse(player, nil, true)
end

Network.Handlers.AutoEquipWorkerFromWarehouse = function(player, args)
    if not args or not args.workerID then
        return
    end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then
        return
    end

    local added = Warehouse.RestockWorkerEquipment and Warehouse.RestockWorkerEquipment(worker, {
        includeOptional = true
    }) or 0
    Registry.RecalculateWorker(worker)
    Shared.saveAndRefreshBasic(player, worker, true)

    if added > 0 then
        Internal.syncNotice(
            player,
            string.format(
                tostring(DC_Colony.Network.WorkersEquipmentFlavorText.autoEquipped or "Auto-equipped %s warehouse item%s."),
                tostring(added),
                added == 1 and "" or "s"
            ),
            "info",
            false
        )
    else
        Internal.syncNotice(
            player,
            tostring(DC_Colony.Network.WorkersEquipmentFlavorText.noMatchingAutoEquip or "No matching warehouse equipment was available for this worker."),
            "info",
            false
        )
    end
end

return Network