DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network

function Network.HandleCommand(player, command, args)
    local handler = Network.Handlers[command]
    if handler then
        return handler(player, args or {})
    end
end

return Network