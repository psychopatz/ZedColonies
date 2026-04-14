require "DC/Common/Colony/StarterWorkers/DC_StarterWorkers"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}

Network.Internal = Internal
Network.Handlers = Network.Handlers or {}

function Internal.ensureStarterWorkers(player)
    if not (DC_Colony and DC_Colony.StarterWorkers and DC_Colony.StarterWorkers.EnsureForPlayer) then
        return nil
    end
    return DC_Colony.StarterWorkers.EnsureForPlayer(player)
end

Network.Handlers.EnsureStarterWorkers = function(player, args)
    local result = Internal.ensureStarterWorkers(player)
    if Internal.syncWorkerList then
        Internal.syncWorkerList(player, args and args.knownVersion)
    end
    if Internal.syncOwnedFactionStatus then
        Internal.syncOwnedFactionStatus(player)
    end
    if result and result.created and result.created > 0 and Internal.syncNotice then
        local suffix = result.created == 1 and "" or "s"
        Internal.syncNotice(player, tostring(result.created) .. " starter worker" .. suffix .. " joined your colony.", "info", false)
    end
end

return Network
