DT_Labour = DT_Labour or {}
DT_Labour.Network = DT_Labour.Network or {}

local Config = DT_Labour.Config
local Registry = DT_Labour.Registry
local Network = DT_Labour.Network
local Internal = Network.Internal or {}
local Shared = (Network.Workers or {}).Shared or {}

Network.Handlers = Network.Handlers or {}

local function canTransferWithWorkerStorage(worker)
    if not worker then
        return false
    end

    local normalizedJob = Config.NormalizeJobType and Config.NormalizeJobType(worker.jobType) or tostring(worker.jobType or "")
    if normalizedJob == ((Config.JobTypes or {}).Scavenge) then
        return tostring(worker.presenceState or (Config.PresenceStates or {}).Home) == tostring((Config.PresenceStates or {}).Home)
    end

    return true
end

Network.Handlers.GiveWorkerMoney = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    local amount = math.max(0, math.floor(tonumber(args.amount) or 0))

    if not worker then
        Internal.syncNotice(player, "That worker could not be found.", "error")
        return
    end

    if not canTransferWithWorkerStorage(worker) then
        Internal.syncNotice(player, tostring(worker.name or worker.workerID) .. " is away from home and cannot receive supplies right now.", "error")
        return
    end

    if amount <= 0 then
        Internal.syncNotice(player, "Enter a valid amount of money to give.", "error")
        return
    end

    if not Internal.removePlayerMoney(player, amount) then
        Internal.syncNotice(player, "You do not have enough money for that transfer.", "error")
        return
    end

    Registry.AddMoney(worker, amount)
    Registry.Save()
    Internal.syncNotice(player, "Gave $" .. tostring(amount) .. " to " .. tostring(worker.name or worker.workerID) .. ".", "success")
    Internal.syncWorkerDetail(player, worker.workerID)
    Internal.syncWorkerList(player)
end

Network.Handlers.WithdrawWorkerMoney = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    local amount = math.max(0, math.floor(tonumber(args.amount) or 0))

    if not worker then
        Internal.syncNotice(player, "That worker could not be found.", "error")
        return
    end

    if not canTransferWithWorkerStorage(worker) then
        Internal.syncNotice(player, tostring(worker.name or worker.workerID) .. " is away from home and cannot hand over supplies right now.", "error")
        return
    end

    if amount <= 0 then
        Internal.syncNotice(player, "Enter a valid amount of money to withdraw.", "error")
        return
    end

    local removed = Registry.RemoveMoney(worker, amount)
    if removed <= 0 then
        Internal.syncNotice(player, tostring(worker.name or worker.workerID) .. " does not have enough stored cash.", "error")
        return
    end

    if not Internal.addPlayerMoney(player, removed) then
        Registry.AddMoney(worker, removed)
        Internal.syncNotice(player, "Unable to return the cash to your inventory.", "error")
        return
    end

    Shared.saveAndRefreshBasic(player, worker)
    Internal.syncNotice(player, "Withdrew $" .. tostring(removed) .. " from " .. tostring(worker.name or worker.workerID) .. ".", "success")
end

return Network
