DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = Internal.ColonyNetShared or {}

Network.Internal = Internal
Network.Handlers = Network.Handlers or {}
Internal.ColonyNetShared = Shared

Shared.Config = Config
Shared.Registry = Registry
Shared.Network = Network
Shared.Internal = Internal

return Shared