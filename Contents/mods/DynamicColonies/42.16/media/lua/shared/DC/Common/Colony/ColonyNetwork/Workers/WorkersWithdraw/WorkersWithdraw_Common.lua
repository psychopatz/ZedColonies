DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Network = DC_Colony.Network
local Withdraw = (Network.Workers or {}).Withdraw or {}

Network.Workers = Network.Workers or {}
Network.Workers.Withdraw = Withdraw

function Withdraw.getFirstAddedItem(items)
    if not items then
        return nil
    end

    local ok, size = pcall(function()
        return items:size()
    end)
    if not ok or size <= 0 then
        return nil
    end

    local itemOk, item = pcall(function()
        return items:get(0)
    end)
    return itemOk and item or nil
end

function Withdraw.resolveGlobalFunction(path)
    local current = _G
    for part in string.gmatch(tostring(path or ""), "[^%.]+") do
        if type(current) ~= "table" then
            return nil
        end
        current = current[part]
        if current == nil then
            return nil
        end
    end

    return type(current) == "function" and current or nil
end

function Withdraw.getWorkerContext(player, args)
    if not args or not args.workerID then
        return nil, nil
    end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    return owner, worker
end

function Withdraw.getWorkerInventoryContext(player, args)
    local owner, worker = Withdraw.getWorkerContext(player, args)
    local inventory = player and player:getInventory() or nil
    return owner, worker, inventory
end

return Withdraw